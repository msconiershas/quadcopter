       /////////////////////////////////////////////////////
	  // TEAM: vwls_n                                    //
     //  MEMBERS:                                       //
    //	 DVN LFFRD - Devin Lafford                     //
   //	 JSPH KRD - Joseph Kardia                     //
  //     MCKNLY SCNRS-HSN - McKinley Sconiers-Hasan  //
 //	     JHN RMR - John Reimer                      //
/////////////////////////////////////////////////////
module cmd_cfg(clk, rst_n, cmd_rdy, cmd, data, clr_cmd_rdy, resp, send_resp, 
	d_ptch, d_roll, d_yaw, thrst, batt, strt_cal, inertial_cal, cal_done, motors_off, strt_cnv, cnv_cmplt);

input clk, rst_n;	//Clock and reset
input cmd_rdy;		//New command walid from UART_wrapper
input [7:0] cmd;	//Command opcode
input [15:0] data;	//Data to accompany command
input [7:0] batt; 	//Battery measurement. Essentially the upper 8 bits of the result from A2D_intf.
input cal_done;		//From inertial_integrator. Indicates calibration is complete.
input cnv_cmplt;	//Signal from A2D_Intf indicating conversion bomplete.

output logic clr_cmd_rdy;	//Knocks down cmd_rdy after cmd_cfg has digested command
output logic [7:0] resp;	//Respose back to remote. Typically pos_ack(0xA5) except when batt
output logic send_resp; 	//Indicates UART_wrapper should send response.
output logic [15:0] d_ptch, d_roll, d_yaw;	//Desired pitch, roll, yaw as 16-bit signed numbers
output logic [8:0] thrst;	//9-bit unsigned thrust level. Goes to flght_ctrl.
output logic strt_cal;	//Indicates to  to start calibration procedure. Only 1 clock wide pulse
						//at end of 1.34s motor spinup period
output logic inertial_cal;	//To flght_ctrl units. Held high during duration of calibration (including motor spinup).
output logic motors_off;	//Goes to flght_ctrl, shuts off motors.
output logic strt_cnv;	//Signal to A2D_Intf to start conversion of battery voltage.

reg wptch, wroll, wyaw, wthrst;
reg mtrs_off, en_mtrs;
reg clr_tmr, tmr_full;

localparam TIMER_WIDTH = 9;
reg [TIMER_WIDTH-1 : 0] mtr_ramp_tmr;

assign tmr_full = &mtr_ramp_tmr;


//SM Flops
typedef enum reg [3:0] {CMD_DSPTCH, SEND_BATT, POS_ACK, WAIT_TMR, WAIT_CAL} state_t;
state_t state, nxt_state;

//Commands//
localparam REQ_BATT = 8'h01;
localparam SET_PTCH = 8'h02;
localparam SET_ROLL = 8'h03;
localparam SET_YAW = 8'h04;
localparam SET_THRST = 8'h05;
localparam CALIBRATE = 8'h06;
localparam MTRS_OFF = 8'h08;

//Pitch FF
always_ff @(posedge clk, negedge rst_n)
	if (!rst_n) d_ptch <= 16'h0000;
	else if (wptch) d_ptch <= data;

//Roll FF
always_ff @(posedge clk, negedge rst_n)
	if (!rst_n) d_roll <= 16'h0000;
	else if (wroll) d_roll <= data;

//Yaw FF
always_ff @(posedge clk, negedge rst_n)
	if (!rst_n) d_yaw <= 16'h0000;
	else if (wyaw) d_yaw <= data;

//Thrust FF
always_ff @(posedge clk, negedge rst_n)
	if (!rst_n) thrst <= 9'h000;
	else if (wthrst) thrst <= data;

//Timer FF
always_ff @(posedge clk, negedge rst_n)
	if (!rst_n) mtr_ramp_tmr <= 0;
	else if (clr_tmr) mtr_ramp_tmr <= 0;
	else mtr_ramp_tmr <= mtr_ramp_tmr + 1;

//FSM//
always_ff @(posedge clk, negedge rst_n)
	if (!rst_n) state <= CMD_DSPTCH;
	else state <= nxt_state;
always_comb begin
	wptch = 0;
	wroll = 0;
	wyaw = 0;
	wthrst = 0;
	clr_tmr = 0;
	mtrs_off = 0;
	en_mtrs = 0;
	strt_cnv = 0;
	inertial_cal = 0;
	send_resp = 0;
	resp = 8'h00;
	clr_cmd_rdy = 0;
	nxt_state = CMD_DSPTCH;
	
	case(state)
		CMD_DSPTCH: 
			if (cmd_rdy) begin
				case(cmd)
					REQ_BATT: begin
						strt_cnv = 1;
						nxt_state = SEND_BATT;
					end
					
					SET_PTCH: begin
						wptch = 1;
						nxt_state = POS_ACK;
					end
					
					SET_ROLL: begin
						wroll = 1;
						nxt_state = POS_ACK;
					end
					
					SET_YAW: begin
						wyaw = 1;
						nxt_state = POS_ACK;
					end
					
					SET_THRST: begin
						wthrst = 1;
						nxt_state = POS_ACK;
					end
					
					CALIBRATE: begin
						clr_tmr = 1;
						en_mtrs = 1;
						nxt_state = WAIT_TMR;
					end
					
					MTRS_OFF: begin
						mtrs_off = 1;
						nxt_state = POS_ACK;
					end
					
					default: begin // Emergency land if garbage command
						wptch = 1;
						wroll = 1;
						wyaw = 1;
						wthrst = 1;
						nxt_state = POS_ACK;
					end
					
					
				endcase
			end
			
		SEND_BATT: 
			if (cnv_cmplt) begin 
				resp = batt;
				send_resp = 1;
				clr_cmd_rdy = 1;
			end
			else nxt_state = SEND_BATT;
			
		POS_ACK: begin
			resp = 8'hA5;
			send_resp = 1;
			clr_cmd_rdy = 1;
		end
			
		WAIT_TMR: 
			if (tmr_full) begin
				strt_cal = 1;
				nxt_state = WAIT_CAL;
			end
			else nxt_state = WAIT_TMR;
				
		WAIT_CAL: begin
			inertial_cal = 1;
			if (cal_done) nxt_state = POS_ACK;
			else nxt_state = WAIT_CAL;
		end
		
		default: nxt_state = CMD_DSPTCH;
			
		
	endcase
end

//Motors_Off FF
always_ff @(posedge clk, negedge rst_n)
	if (!rst_n) motors_off <= 1;
	else if (mtrs_off) motors_off <= 1;
	else if (en_mtrs) motors_off <= 0;


endmodule	




