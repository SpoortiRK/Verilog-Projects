module seq_detector_1011_tb;

reg clk;
reg reset;
reg din;

wire dout;

// Instantiate DUT
seq_detector_1011 uut (
    .clk(clk),
    .reset(reset),
    .din(din),
    .dout(dout)
);

// Clock generation (10 ns period)
always #5 clk = ~clk;

// Stimulus
initial begin
    clk = 0;
    reset = 1;
    din = 0;

    #10;
    reset = 0;

    // Input sequence: 1011 (Detected)
    din = 1; #10;
    din = 0; #10;
    din = 1; #10;
    din = 1; #10;

    // Input sequence: 1010 (Not detected)
    din = 1; #10;
    din = 0; #10;
    din = 1; #10;
    din = 0; #10;

    // Input sequence: 1011 (Detected)
    din = 1; #10;
    din = 0; #10;
    din = 1; #10;
    din = 1; #10;

    // Overlapping sequence: 1011011
    din = 0; #10;
    din = 1; #10;
    din = 0; #10;
    din = 1; #10;
    din = 1; #10;

    #20;
    $finish;
end

// Monitor
initial begin
    $monitor("Time=%0t clk=%b reset=%b din=%b state=%b next=%b dout=%b",
             $time,
             clk,
             reset,
             din,
             uut.state,
             uut.next_state,
             dout);
end

endmodule
