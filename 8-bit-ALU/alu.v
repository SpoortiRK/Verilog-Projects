module alu(
input [7:0] A,
input [7:0] B,
input [2:0] op,
output reg [7:0] C,
output reg carry,
output reg zero,
output reg overflow
);
reg [8:0] temp;
always@(*) begin
C = 8'b0;
carry = 1'b0;
zero = 1'b0;
overflow = 1'b0;
case(op)
 3'b000: begin
            temp = A + B;
            C = temp[7:0];
            carry = temp[8];

            if ((A[7] == B[7]) && (C[7] != A[7]))
                overflow = 1'b1;
        end

        // SUBTRACT
        3'b001: begin
            temp = A - B;
            C = temp[7:0];

            // Overflow for subtraction
            if ((A[7] != B[7]) && (C[7] != A[7]))
                overflow = 1'b1;
        end

        // AND
        3'b010: begin
            C = A & B;
        end

        // OR
        3'b011: begin
            C = A | B;
        end

        // XOR
        3'b100: begin
            C = A ^ B;
        end

        // NOT
        3'b101: begin
            C = ~A;
        end

        // LEFT SHIFT
        3'b110: begin
            C = A << 1;
        end

        // RIGHT SHIFT
        3'b111: begin
            C = A >> 1;
        end

        default: begin
            C = 8'b00000000;
        end

    endcase

    // Zero flag (common for all operations)
    if (C == 8'b00000000)
        zero = 1'b1;



end
endmodule

