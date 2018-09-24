module flght_cntrl(clk,rst_n,vld,inertial_cal,d_ptch,d_roll,d_yaw,ptch,
					roll,yaw,thrst,frnt_spd,bck_spd,lft_spd,rght_spd);



input clk,rst_n;
input vld;									// tells when a new valid inertial reading ready
														// only update D_QUEUE on vld readings
input inertial_cal;					// need to run motors at CAL_SPEED during inertial calibration
input signed [15:0] d_ptch,d_roll,d_yaw;	// desired pitch roll and yaw (from cmd_cfg)
input signed [15:0] ptch,roll,yaw;				// actual pitch roll and yaw (from inertial interface)
input [8:0] thrst;								// thrust level from slider
output [10:0] frnt_spd;						// 11-bit unsigned speed at which to run front motor
output [10:0] bck_spd;						// 11-bit unsigned speed at which to back front motor
output [10:0] lft_spd;						// 11-bit unsigned speed at which to left front motor
output [10:0] rght_spd;						// 11-bit unsigned speed at which to right front motor


//////////////////////////////////////////////////////
// You will need a bunch of internal wires declared /
// for intermediate math results...do that here   //
///////////////////////////////////////////////////
reg signed [12:0] frnt_sum;
reg signed [10:0] frnt_sum_sat;
reg signed [12:0] bck_sum;
reg signed [10:0] bck_sum_sat;
reg signed [12:0] lft_sum;
reg signed [10:0] lft_sum_sat;
reg signed [12:0] rght_sum;
reg signed [10:0] rght_sum_sat;
reg signed [9:0] ptch_pterm, roll_pterm, yaw_pterm;
reg signed [11:0] ptch_dterm, roll_dterm, yaw_dterm;

///////////////////////////////////////////////////////////////
// some Parameters to keep things more generic and flexible //
/////////////////////////////////////////////////////////////
localparam CAL_SPEED = 11'h1B0;		// speed to run motors at during inertial calibration
localparam MIN_RUN_SPEED = 13'h200;	// minimum speed while running
localparam D_COEFF = 6'b00111;			// D coefficient in PID control = +14

//Use module to compute p and d terms.
get_terms get_ptch(.clk(clk), .rst_n(rst_n), .vld(vld), .actual(ptch), .desired(d_ptch),
	.pterm(ptch_pterm), .dterm(ptch_dterm));
get_terms get_roll(.clk(clk), .rst_n(rst_n), .vld(vld), .actual(roll), .desired(d_roll),
	.pterm(roll_pterm), .dterm(roll_dterm));
get_terms get_yaw(.clk(clk), .rst_n(rst_n), .vld(vld), .actual(yaw), .desired(d_yaw),
	.pterm(yaw_pterm), .dterm(yaw_dterm));

//// non-pipelined big sigmas
//assign frnt_sum = MIN_RUN_SPEED 
//+ {4'b0000, thrst} 
//- {{3{ptch_pterm[9]}}, ptch_pterm} 
//- {{1{ptch_dterm[11]}}, ptch_dterm} 
//- {{3{yaw_pterm[9]}}, yaw_pterm} 
//- {{1{yaw_dterm[11]}}, yaw_dterm};

//assign bck_sum = MIN_RUN_SPEED 
//+ {4'b0000, thrst}  
//+ {{3{ptch_pterm[9]}}, ptch_pterm} 
//+ {{1{ptch_dterm[11]}}, ptch_dterm} 
//- {{3{yaw_pterm[9]}}, yaw_pterm} 
//- {{1{yaw_dterm[11]}}, yaw_dterm};

//assign lft_sum = MIN_RUN_SPEED 
//+ {4'b0000, thrst}  
//- {{3{roll_pterm[9]}}, roll_pterm} 
//- {{1{roll_dterm[11]}}, roll_dterm} 
//+ {{3{yaw_pterm[9]}}, yaw_pterm} 
//+ {{1{yaw_dterm[11]}}, yaw_dterm};

//assign rght_sum = MIN_RUN_SPEED 
//+ {4'b0000, thrst}  
//+ {{3{roll_pterm[9]}}, roll_pterm} 
//+ {{1{roll_dterm[11]}}, roll_dterm} 
//+ {{3{yaw_pterm[9]}}, yaw_pterm} 
//+ {{1{yaw_dterm[11]}}, yaw_dterm};

// Pipelined big sigmas
always_ff @(posedge clk) begin
	frnt_sum <= MIN_RUN_SPEED 
	+ {4'b0000, thrst} 
	- {{3{ptch_pterm[9]}}, ptch_pterm} 
	- {{1{ptch_dterm[11]}}, ptch_dterm} 
	- {{3{yaw_pterm[9]}}, yaw_pterm} 
	- {{1{yaw_dterm[11]}}, yaw_dterm};
end

always_ff @(posedge clk) begin
	bck_sum <= MIN_RUN_SPEED 
	+ {4'b0000, thrst}  
	+ {{3{ptch_pterm[9]}}, ptch_pterm} 
	+ {{1{ptch_dterm[11]}}, ptch_dterm} 
	- {{3{yaw_pterm[9]}}, yaw_pterm} 
	- {{1{yaw_dterm[11]}}, yaw_dterm};
end

always_ff @(posedge clk) begin
	lft_sum <= MIN_RUN_SPEED 
	+ {4'b0000, thrst}  
	- {{3{roll_pterm[9]}}, roll_pterm} 
	- {{1{roll_dterm[11]}}, roll_dterm} 
	+ {{3{yaw_pterm[9]}}, yaw_pterm} 
	+ {{1{yaw_dterm[11]}}, yaw_dterm};
end

always_ff @(posedge clk) begin
	rght_sum <= MIN_RUN_SPEED 
	+ {4'b0000, thrst}  
	+ {{3{roll_pterm[9]}}, roll_pterm} 
	+ {{1{roll_dterm[11]}}, roll_dterm} 
	+ {{3{yaw_pterm[9]}}, yaw_pterm} 
	+ {{1{yaw_dterm[11]}}, yaw_dterm};
end

//Unsigned saturation
//assign sum_sat = |sum[12:10] ? 11'h7FF : sum[10:0];
assign frnt_sum_sat = frnt_sum[12] ? 11'h000 : 
					  |frnt_sum[12:11] ? 11'h7FF : 
					  frnt_sum[10:0];

assign bck_sum_sat = bck_sum[12] ? 11'h000 : 
					  |bck_sum[12:11] ? 11'h7FF : 
					  bck_sum[10:0];
					  
assign lft_sum_sat = lft_sum[12] ? 11'h000 : 
					  |lft_sum[12:11] ? 11'h7FF : 
					  lft_sum[10:0];

assign rght_sum_sat = rght_sum[12] ? 11'h000 : 
					  |rght_sum[12:11] ? 11'h7FF : 
					  rght_sum[10:0];

assign frnt_spd = inertial_cal ? CAL_SPEED : frnt_sum_sat;
assign bck_spd = inertial_cal ? CAL_SPEED : bck_sum_sat;
assign lft_spd = inertial_cal ? CAL_SPEED : lft_sum_sat;
assign rght_spd = inertial_cal ? CAL_SPEED : rght_sum_sat;

endmodule


//Calculate p and d terms//
module get_terms(clk, rst_n, vld, actual, desired, pterm, dterm);
	input clk, rst_n, vld;
	input signed [15:0] actual, desired;
	
	output reg [9:0]  pterm;
	output reg signed [11:0] dterm;
	
	wire signed [16:0] error;
	reg signed [9:0]  err_sat;
	wire signed [9:0]  D_diff;
	wire signed [5:0]  D_diff_sat;
	
	integer x;
	
	// Error queue
	parameter D_QUEUE_DEPTH = 14; // delay for derivative term
	parameter signed D_COEFF = 6'b00111;
	reg signed [9:0]  prev_err[0:D_QUEUE_DEPTH-1];
	
	// D-Queue
	always_ff @(posedge clk, negedge rst_n) begin
		if (!rst_n) begin
			for (x = 0; x < D_QUEUE_DEPTH; x++) begin
				prev_err[x] <= 0;
			end
		end
		else if (vld) begin
			for (x = 1; x < D_QUEUE_DEPTH; x++) begin
				prev_err[x] <= prev_err[x-1];
			end
			prev_err[0] <= err_sat;
		end
	end
	
	
	assign error = actual - desired;
					 
//	// Non-pipelined err_sat
//	assign err_sat = !error[16] &&  |error[16:9] ? 10'h1FF : // positive and needs sat
//					  error[16] && ~&error[16:9] ? 10'h200 : // negative and needs sat
//					  error[9:0]; // doesn't need saturation
		  
	//Pipelined err_sat
	always_ff @(posedge clk) begin
		if (!error[16] &&  |error[16:9]) 
			err_sat <= 10'h1FF; // positive and needs sat
		else if (error[16] && ~&error[16:9]) 
			err_sat <= 10'h200; // negative and needs sat
		else 
			err_sat <= error[9:0]; // doesn't need saturation
	end

	
	// Calculate 5/8 of raw_err_sat
	assign pterm = (err_sat >>> 1) + (err_sat >>> 3);

	
	assign D_diff = err_sat - prev_err[D_QUEUE_DEPTH-1];			
	assign D_diff_sat = !D_diff[9] &&  |D_diff[9:5] ? 6'h1F : // positive and needs sat
						 D_diff[9] && ~&D_diff[9:5] ? 6'h20 : // negative and needs sat
						 D_diff[5:0]; // doesn't need saturation
						
	
	assign dterm = D_diff_sat * D_COEFF;
endmodule 
