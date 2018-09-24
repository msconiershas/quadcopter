module ESCs(clk, rst_n, frnt_spd, bck_spd, lft_spd, rght_spd, motors_off, frnt, bck, lft, rght);

localparam FRNT_OFF = 9'h0;
localparam BCK_OFF = 9'h0;
localparam LFT_OFF = 9'h0;
localparam RGHT_OFF = 9'h0;

input clk, rst_n;
input [10:0] frnt_spd, bck_spd, lft_spd, rght_spd; 
input motors_off;
output frnt, bck, rght, lft;

wire [10:0] frnt_SPEED, bck_SPEED, lft_SPEED, rght_SPEED;
wire [9:0] frnt_OFF, bck_OFF, lft_OFF, rght_OFF;

// instantiate four ESCs
ESC_interface frnt_ESC( .clk(clk), .rst_n(rst_n), 
						.SPEED(frnt_SPEED), .OFF(frnt_OFF), .PWM(frnt));

ESC_interface bck_ESC( 	.clk(clk), .rst_n(rst_n), 
						.SPEED(bck_SPEED), .OFF(bck_OFF), .PWM(bck));
						
ESC_interface lft_ESC( 	.clk(clk), .rst_n(rst_n), 
						.SPEED(lft_SPEED), .OFF(lft_OFF), .PWM(lft));

ESC_interface rght_ESC( .clk(clk), .rst_n(rst_n), 
						.SPEED(rght_SPEED), .OFF(rght_OFF), .PWM(rght));

// wires and assigns going into the ESC_interfaces


assign frnt_SPEED = (frnt_spd & ~motors_off);
assign bck_SPEED = (bck_spd & ~motors_off);
assign lft_SPEED = (lft_spd & ~motors_off);
assign rght_SPEED = (rght_spd & ~motors_off);
assign frnt_OFF = (FRNT_OFF & ~motors_off);
assign bck_OFF = (BCK_OFF & ~motors_off);
assign lft_OFF = (LFT_OFF & ~motors_off);
assign rght_OFF = (RGHT_OFF & ~motors_off);

endmodule
