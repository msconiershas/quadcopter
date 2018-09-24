module ESC_interface(clk, rst_n, SPEED, OFF, PWM);
//Test at 18, run at 20
localparam PERIOD_WIDTH = 18;

input clk, rst_n;
input [10:0] SPEED;
input [9:0] OFF;
output reg PWM;
wire [11:0] compensated_speed;
reg [16:0] setting;
reg  [PERIOD_WIDTH-1:0] counter;
wire Rst, Set;

///Main Comb_logic path///
//First adder block, compensated_speed = SPEED + OFF
assign compensated_speed = SPEED + OFF;
//Promote 4 bits, then Second adder, + 16'd50000;
always_ff @(posedge clk) begin
	setting <= {compensated_speed, 4'b0000} + 16'd50000;
end

//assign setting = {compensated_speed, 4'b0000} + 16'd50000; // non-pipelined

//Comparator block, calculate Rst
assign Rst = (counter[16:0] >= setting) ? 1'b1 : 1'b0;
//&all bits set, calculate Set
assign Set = &counter ? 1'b1 : 1'b0;

//Counter FF
//Accumulate counter every clock
always_ff @(posedge clk, negedge rst_n)
    if (!rst_n) counter <= 20'h00000;
    else counter <= counter + 1'b1;

//Output FF
//If Rst is 1, PWM is 0
//If Set is 1, PWM is 1
//Else maintain
always_ff @(posedge clk, negedge rst_n)
 if (!rst_n) PWM <= 1'b0;
 else if (Set) PWM <= 1'b1;
 else if (Rst) PWM <= 1'b0;
	

endmodule
