module seq_detector_1011 (
    input clk,
    input reset,
    input din,
    output reg dout
);

    // State Encoding
    localparam S0 = 2'b00;
    localparam S1 = 2'b01;
    localparam S2 = 2'b10;
    localparam S3 = 2'b11;

    reg [1:0] state;
    reg [1:0] next_state;

    // State Register
    always @(posedge clk or posedge reset) begin
        if (reset)
            state <= S0;
        else
            state <= next_state;
    end

    // Next State Logic & Output Logic
    always @(*) begin

        // Default assignments
        next_state = state;
        dout = 1'b0;

        case (state)

            // No match
            S0: begin
                if (din)
                    next_state = S1;
                else
                    next_state = S0;
            end

            // Matched '1'
            S1: begin
                if (din)
                    next_state = S1;
                else
                    next_state = S2;
            end

            // Matched '10'
            S2: begin
                if (din)
                    next_state = S3;
                else
                    next_state = S0;
            end

            // Matched '101'
            S3: begin
                if (din) begin
                    next_state = S1;   // Overlapping detection
                    dout = 1'b1;       // Sequence 1011 detected
                end
                else
                    next_state = S2;
            end

            default: begin
                next_state = S0;
                dout = 1'b0;
            end

        endcase
    end

endmodule
