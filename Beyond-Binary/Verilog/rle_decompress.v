`timescale 1ns/1ps

module rle_decompress (
    input  wire       clk,
    input  wire       rst,
    input  wire       in_valid,
    input  wire [7:0] in_byte,
    output wire       in_ready,
    output reg        out_valid,
    output reg  [7:0] out_byte,
    output reg        done
);
    localparam S_WAIT_FF = 3'd0;
    localparam S_GET_CNT = 3'd1;
    localparam S_GET_DAT = 3'd2;
    localparam S_EMIT    = 3'd3;
    localparam S_FINISH  = 3'd4;

    reg [2:0] state;
    reg [7:0] run_len;
    reg [7:0] run_byte;
    reg [7:0] emit_left;

    // New input bytes can only be accepted while we are looking for the
    // FF marker, the run-count byte, or the run-data byte. While S_EMIT
    // is replaying a run (emit_left != 0) or we are in S_FINISH, no new
    // input byte should be consumed.
    assign in_ready = (state == S_WAIT_FF) ||
                       (state == S_GET_CNT) ||
                       (state == S_GET_DAT);

    always @(posedge clk) begin
        if (rst) begin
            state     <= S_WAIT_FF;
            out_valid <= 1'b0;
            out_byte  <= 8'h00;
            done      <= 1'b0;
            run_len   <= 8'd0;
            run_byte  <= 8'd0;
            emit_left <= 8'd0;
        end else begin
            out_valid <= 1'b0;
            case (state)
                S_WAIT_FF: begin
                    done <= 1'b0;
                    if (in_valid && in_byte == 8'hFF)
                        state <= S_GET_CNT;
                end
                S_GET_CNT: begin
                    if (in_valid) begin
                        if (in_byte == 8'hFE) begin
                            state <= S_FINISH;
                        end else begin
                            run_len <= in_byte;
                            state   <= S_GET_DAT;
                        end
                    end
                end
                S_GET_DAT: begin
                    if (in_valid) begin
                        run_byte  <= in_byte;
                        emit_left <= run_len;
                        state     <= S_EMIT;
                    end
                end
                S_EMIT: begin
                    if (emit_left != 8'd0) begin
                        out_valid <= 1'b1;
                        out_byte  <= run_byte;
                        emit_left <= emit_left - 8'd1;
                        if (emit_left == 8'd1)
                            state <= S_GET_CNT;
                    end
                end
                S_FINISH: begin
                    done <= 1'b1;
                end
                default: state <= S_WAIT_FF;
            endcase
        end
    end
endmodule
