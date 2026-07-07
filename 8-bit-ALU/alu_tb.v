module alu_tb;
reg [7:0] A;
reg [7:0] B;
reg [2:0] op;
wire [7:0] C;
wire carry;
wire overflow;
wire zero;

alu uut(
    .A(A),
    .B(B),
    .op(op),
    .C(C),
    .carry(carry),
    .zero(zero),
    .overflow(overflow)
);

initial begin

    A = 8'd10;
    B = 8'd5;
    op = 3'b000;
    #10;

    A = 8'd20;
    B = 8'd8;
    op = 3'b001;
    #10;

  // Addition with carry
    A = 8'd255;
    B = 8'd1;
    op = 3'b000;
    #10;

    // Addition with overflow
    A = 8'd127;
    B = 8'd1;
    op = 3'b000;
    #10;

    // Subtraction
    A = 8'd20;
    B = 8'd8;
    op = 3'b001;
    #10;

    // Zero result
    A = 8'd5;
    B = 8'd5;
    op = 3'b001;
    #10;

	A = 8'b11001100;
    B = 8'b10101010;
    op = 3'b010;
    #10;

    // OR
    op = 3'b011;
    #10;

    // XOR
    op = 3'b100;
    #10;

    // NOT
    op = 3'b101;
    #10;

    // LEFT SHIFT
    A = 8'b00001111;
    op = 3'b110;
    #10;

    // RIGHT SHIFT
    op = 3'b111;
    #10;


    // More test cases...

    $finish;
end

initial begin
    $monitor("Time=%0t A=%d B=%d op=%b C=%d carry=%b zero=%b overflow=%b",
              $time, A, B, op, C, carry, zero, overflow);
	$finish;
end
endmodule
