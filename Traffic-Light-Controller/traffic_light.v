module traffic_light(
    input clk,
    input reset,

    output reg north_red,
    output reg north_yellow,
    output reg north_green,

    output reg east_red,
    output reg east_yellow,
    output reg east_green
);

localparam S0 = 3'b000;
localparam S1 = 3'b001;
localparam S2 = 3'b010;
localparam S3 = 3'b011;
localparam S4 = 3'b100;
localparam S5 = 3'b101;

reg [2:0] current_state;
reg [2:0] next_state;

always @(posedge clk or posedge reset) begin
  if(reset) begin
     current_state <= S0;
   end
  else begin
     current_state <= next_state;
   end
end

always @(*) begin
    case (current_state)
        S0: next_state = S1;
        S1: next_state = S2;
        S2: next_state = S3;
        S3: next_state = S4;
        S4: next_state = S5;
        S5: next_state = S0;
        default: next_state = S0;
    endcase
end

always @(*) begin

 north_red = 0;
 north_yellow = 0;
 north_green = 0;

 east_red = 0;
 east_yellow = 0;
 east_green = 0;

case(current_state) 

S0 : begin
  	north_green = 1;
	east_red = 1;
     end

S1 : begin
	north_yellow = 1;
	east_red = 1;
     end

S2 : begin
	north_red = 1;
	east_red = 1;
     end

S3 : begin
	north_red = 1;
	east_green = 1;
     end

S4 : begin
	north_red = 1;
	east_yellow = 1;
     end	


S5 : begin
	north_red = 1;
	east_red = 1;
     end

default: begin
    north_green = 1;
    east_red = 1;
   end
endcase
end

endmodule
