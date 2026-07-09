`timescale 1ns/1ps

module rle_compress (
    input  wire       clk,
    input  wire       rst,
    input  wire       in_valid,
    input  wire [7:0] in_byte,
    input  wire       in_last,
    output wire       in_ready,
    output reg        out_valid,
    output reg  [7:0] out_byte,
    output reg        done
);

    localparam S_IDLE   = 3'd0;
    localparam S_ACCUM  = 3'd1;
    localparam S_OUT_FF = 3'd2;
    localparam S_OUT_CNT= 3'd3;
    localparam S_OUT_DAT= 3'd4;
    localparam S_OUT_FE = 3'd5;
    localparam S_FINISH = 3'd6;

    reg [2:0] state;

    reg [7:0] cur_byte;
    reg [7:0] run_len;
    reg       ff_sent;

    reg [7:0] pending_byte;
    reg       have_pending;
    reg       input_done;
    reg       same_continue;

    // The compressor can only accept a new input byte while it is in
    // S_IDLE (first byte of stream) or S_ACCUM (accumulating a run).
    // While it is busy flushing out FF/COUNT/DATA/FE bytes it must NOT
    // accept (or silently drop) new input.
    assign in_ready = (state == S_IDLE) || (state == S_ACCUM);

    always @(posedge clk) begin
        if (rst) begin
            state         <= S_IDLE;
            out_valid     <= 1'b0;
            out_byte      <= 8'h00;
            done          <= 1'b0;
            run_len       <= 8'd0;
            cur_byte      <= 8'd0;
            ff_sent       <= 1'b0;
            have_pending  <= 1'b0;
            input_done    <= 1'b0;
            same_continue <= 1'b0;
        end else begin
            out_valid <= 1'b0;

            case (state)
                S_IDLE: begin
                    done <= 1'b0;
                    if (in_valid) begin
                        cur_byte      <= in_byte;
                        run_len       <= 8'd1;
                        ff_sent       <= 1'b0;
                        have_pending  <= 1'b0;
                        input_done    <= in_last;
                        same_continue <= 1'b0;

                        if (in_last)
                            state <= S_OUT_FF;
                        else
                            state <= S_ACCUM;
                    end
                end

                S_ACCUM: begin
                    if (in_valid) begin
                        if (in_byte == cur_byte && run_len < 8'd255) begin
                            run_len    <= run_len + 8'd1;
                            input_done <= in_last;

                            if (in_last)
                                state <= (ff_sent ? S_OUT_CNT : S_OUT_FF);

                        end else if (in_byte == cur_byte && run_len == 8'd255) begin
                            input_done    <= in_last;
                            have_pending  <= 1'b0;
                            same_continue <= 1'b1;
                            state         <= (ff_sent ? S_OUT_CNT : S_OUT_FF);

                        end else begin
                            pending_byte  <= in_byte;
                            have_pending  <= 1'b1;
                            input_done    <= in_last;
                            same_continue <= 1'b0;
                            state         <= (ff_sent ? S_OUT_CNT : S_OUT_FF);
                        end
                    end
                end

                S_OUT_FF: begin
                    out_valid <= 1'b1;
                    out_byte  <= 8'hFF;
                    ff_sent   <= 1'b1;
                    state     <= S_OUT_CNT;
                end

                S_OUT_CNT: begin
                    out_valid <= 1'b1;
                    out_byte  <= run_len;
                    state     <= S_OUT_DAT;
                end

                S_OUT_DAT: begin
                    out_valid <= 1'b1;
                    out_byte  <= cur_byte;

                    if (have_pending) begin
                        cur_byte      <= pending_byte;
                        run_len       <= 8'd1;
                        have_pending  <= 1'b0;
                        same_continue <= 1'b0;

                        if (input_done)
                            state <= S_OUT_CNT;
                        else
                            state <= S_ACCUM;

                    end else if (same_continue) begin
                        run_len       <= 8'd1;
                        same_continue <= 1'b0;

                        if (input_done)
                            state <= S_OUT_CNT;
                        else
                            state <= S_ACCUM;

                    end else if (input_done) begin
                        state <= S_OUT_FE;
                    end else begin
                        state <= S_ACCUM;
                    end
                end

                S_OUT_FE: begin
                    out_valid <= 1'b1;
                    out_byte  <= 8'hFE;
                    state     <= S_FINISH;
                end

                S_FINISH: begin
                    done <= 1'b1;
                end

                default: state <= S_IDLE;
            endcase
        end
    end

endmodule