module traffic_light_tb;

reg clk;
reg reset; 

wire north_red;
wire north_yellow;
wire north_green;
wire east_red;
wire east_yellow;
wire east_green;

traffic_light uut(
.clk(clk),
.reset(reset),
.north_red(north_red),
.north_yellow(north_yellow),
.north_green(north_green),
.east_red(east_red),
.east_yellow(east_yellow),
.east_green(east_green)
);

always #5 clk = ~clk;

initial begin
    clk = 0;
    reset = 1;
    #10;
    reset = 0;
    #100;
    $finish;
end

initial begin
    $monitor("Time=%0t clk=%b reset=%b State=%b Next=%b NR=%b NY=%b NG=%b ER=%b EY=%b EG=%b",           
              $time, clk, reset, uut.current_state,uut.next_state,
              north_red, north_yellow, north_green,
              east_red, east_yellow, east_green);
end

endmodule