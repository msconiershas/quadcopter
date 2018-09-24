module inert_intf_tb();

reg clk, rst_n;

// IO to inert_intf
reg strt_cal;
wire vld, cal_done;
wire [15:0] ptch, roll, yaw;

// motor speed inputs
reg [10:0] frnt_spd, bck_spd, lft_spd, rght_spd;
reg motors_off;

// wires between inert_intf and CycloneIV
wire INT, SS_n, SCLK, MOSI, MISO;

// wires between ESCs and CycloneIV
wire frnt, bck, lft, rght;

// instantiate ESCs
ESCs escs(	.clk(clk), .rst_n(rst_n), .motors_off(motors_off),
			.frnt_spd(frnt_spd), .bck_spd(bck_spd), .lft_spd(lft_spd), .rght_spd(rght_spd),
			.frnt(frnt), .bck(bck), .lft(lft), .rght(rght));

// instantiate quadcopter model
CycloneIV model(	.SS_n(SS_n), .INT(INT), .SCLK(SCLK), .MOSI(MOSI), .MISO(MISO), 
					.frnt_ESC(frnt), .back_ESC(bck), .left_ESC(lft), .rght_ESC(rght));

// instantiate DUT
inert_intf #(3) iDUT(	.clk(clk), .rst_n(rst_n),
					.SS_n(SS_n), .INT(INT), .SCLK(SCLK), .MOSI(MOSI), .MISO(MISO), 
					.strt_cal(strt_cal), .vld(vld), .cal_done(cal_done), 
					.ptch(ptch), .roll(roll), .yaw(yaw));



always begin

	#5 clk = ~clk;

end

//time out 
initial begin

	repeat (1000000000) @(negedge clk);
	$display("Timed out.");
	$stop();

end


initial begin

	// default all signals and reset
	clk = 0;
	rst_n = 0;
	strt_cal = 0;
	frnt_spd = 0;
	bck_spd = 0;
	lft_spd = 0;
	rght_spd = 0;
	motors_off = 0;
	
	@(negedge clk);
	@(negedge clk);
	rst_n = 1;
	
	strt_cal = 1;
	@(negedge clk);
	strt_cal = 0;
	@(posedge cal_done); // wait for calibration
	
	// wait for vld to go high for SPI done
	repeat (4) @(posedge vld);
	
	
	// print out the values of pitch roll and yaw
	$display("ptch: %x", ptch);
	$display("roll: %x", roll);
	$display("yaw: %x", yaw);

	$stop();
	
end










endmodule
