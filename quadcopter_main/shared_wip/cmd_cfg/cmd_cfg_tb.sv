       /////////////////////////////////////////////////////
	  // TEAM: vwls_n                                    //
     //  MEMBERS:                                       //
    //	 DVN LFFRD - Devin Lafford                     //
   //	 JSPH KRD - Joseph Kardia                     //
  //     MCKNLY SCNRS-HSN - McKinley Sconiers-Hasan  //
 //	     JHN RMR - John Reimer                      //
/////////////////////////////////////////////////////


module cmd_cfg_tb();

reg clk, rst_n;
reg cmd_rdy;
reg [7:0] cmd;
reg [15:0] data;
reg [7:0] batt;
reg inertial_cal;
reg cal_done;
reg cnv_cmplt;

wire clr_cmd_rdy;

cmd_cfg modernity(	.clk(clk), .rst_n(rst_n), 
					.cmd_rdy(cmd_rdy), .cmd(cmd), .data(data), .clr_cmd_rdy(clr_cmd_rdy), 
					.resp(resp), .send_resp(send_resp),
 					.d_ptch(d_ptch), .d_roll(d_roll), .d_yaw(d_yaw), .thrst(thrst), .batt(batt), 
 					.strt_cal(strt_cal), .inertial_cal(inertial_cal), .cal_done(cal_done),
  					.motors_off(motors_off), .strt_cnv(strt_cnv), .cnv_cmplt(cnv_cmplt));

// time out
initial begin 

	#1000000;
	$display("TOOK TOO LONG BUCKO.");
	$stop();

end

// test
initial begin 

	clk = 0;
	rst_n = 0;
	cmd_rdy = 0;
	batt = 8'hfc;
	cnv_cmplt = 1;
	cal_done = 1;

	@(negedge clk);
	rst_n = 1;

	//COMMAND 1
	data = 16'hff0f;
	cmd = 8'h01;
	
	@(negedge clk);
	cmd_rdy = 1;

	@(posedge clr_cmd_rdy);
	cmd_rdy = 0;
	if (!send_resp) begin
		$display("send_resp should be high");
		$stop;	
	end
	if(resp == 8'hfc) begin
		$display("bad batt %b",resp);
		$stop;
	end

	//COMMAND 2
	data = 16'hff0f;
	cmd = 8'h02;
	
	@(negedge clk);
	cmd_rdy = 1;

	@(posedge clr_cmd_rdy);
	cmd_rdy = 0;
	if (!send_resp) begin
		$display("send_resp should be high");
		$stop;	
	end
	if(resp == 8'ha5) begin
		$display("bad pos_ack %b",resp);
		$stop;
	end
	
	//COMMAND 3
	data = 16'hff0f;
	cmd = 8'h03;
	
	@(negedge clk);
	cmd_rdy = 1;

	@(posedge clr_cmd_rdy);
	cmd_rdy = 0;
	if (!send_resp) begin
		$display("send_resp should be high");
		$stop;	
	end
	if(resp == 8'ha5) begin
		$display("bad pos_ack %b",resp);
		$stop;
	end

	//COMMAND 4
	data = 16'hff0f;
	cmd = 8'h04;
	
	@(negedge clk);
	cmd_rdy = 1;

	@(posedge clr_cmd_rdy);
	cmd_rdy = 0;
	if (!send_resp) begin
		$display("send_resp should be high");
		$stop;	
	end
	if(resp == 8'ha5) begin
		$display("bad pos_ack %b",resp);
		$stop;
	end
	
	//COMMAND 5
	data = 16'h017F;
	cmd = 8'h05;
	
	@(negedge clk);
	cmd_rdy = 1;

	@(posedge clr_cmd_rdy);
	cmd_rdy = 0;
	if (!send_resp) begin
		$display("send_resp should be high");
		$stop;	
	end
	if(resp == 8'ha5) begin
		$display("bad pos_ack %b",resp);
		$stop;
	end
	
	//COMMAND 6
	data = 16'hff0f;
	cmd = 8'h06;
	
	@(negedge clk);
	cmd_rdy = 1;

	@(posedge clr_cmd_rdy);
	cmd_rdy = 0;
	if (!send_resp) begin
		$display("send_resp should be high");
		$stop;	
	end
	if(resp == 8'ha5) begin
		$display("bad pos_ack %b",resp);
		$stop;
	end
	
	//COMMAND 7
	data = 16'h0000;
	cmd = 8'h07;
	
	@(negedge clk);
	cmd_rdy = 1;

	@(posedge clr_cmd_rdy);
	cmd_rdy = 0;
	if (!send_resp) begin
		$display("send_resp should be high");
		$stop;	
	end
	if(resp == 8'ha5) begin
		$display("bad pos_ack %b",resp);
		$stop;
	end
	
	//COMMAND 8
	cmd = 8'h08;
	
	@(negedge clk);
	cmd_rdy = 1;

	@(posedge clr_cmd_rdy);
	cmd_rdy = 0;
	if (!send_resp) begin
		$display("send_resp should be high");
		$stop;	
	end
	if(resp == 8'ha5) begin
		$display("bad pos_ack %b",resp);
		$stop;
	end
	
	$display("wooho we dun it!!11");
	$stop();

end



always
	#1 clk <= ~clk;

endmodule

