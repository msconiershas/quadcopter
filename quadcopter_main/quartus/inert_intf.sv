module inert_intf(clk, rst_n, SS_n, SCLK, MOSI, MISO, INT, strt_cal, ptch, roll, yaw, cal_done, vld);
input clk, rst_n;

parameter COUNT_WIDTH = 3;

//SPI interface
input MISO;
output SS_n, SCLK, MOSI; 
wire [15:0] rd_data_all;
wire [7:0] rd_data;
wire done;
reg wrt;
reg [15:0] cmd;

assign rd_data = rd_data_all[7:0];

//Integrator interface
output [15:0] ptch, roll, yaw;
output cal_done;
reg [15:0] ptch_rt, roll_rt, yaw_rt, ax, ay;

//SM interface
input INT, strt_cal;
output reg vld;
reg INT_ff1, INT_ff2;
reg CPH, CPL, CRH, CRL, CYH, CYL, CAXH, CAXL, CAYH, CAYL;
typedef enum reg [4:0] {INIT1, INIT2, INIT3, INIT4, WAIT, 
	PITCH_L, PITCH_H, ROLL_L, ROLL_H, YAW_L, YAW_H, AX_L, AX_H, AY_L, AY_H} state_t;
state_t state, nxt_state;

//timer
reg [15:0] timer;

//Instantiations//
SPI_mstr16 iSPI(	.clk(clk), .rst_n(rst_n), 
					.wrt(wrt), .done(done),
					.cmd(cmd), .rd_data(rd_data_all), 
					.SS_n(SS_n), .MISO(MISO), .MOSI(MOSI), .SCLK(SCLK));

inertial_integrator #(COUNT_WIDTH) iII(.clk(clk), .rst_n(rst_n), .strt_cal(strt_cal), .vld(vld),
	.ptch_rt(ptch_rt), .roll_rt(roll_rt), .yaw_rt(yaw_rt), .ax(ax), .ay(ay),
	.cal_done(cal_done), .ptch(ptch), .roll(roll), .yaw(yaw));
	

//Double flop INT
always_ff @(posedge clk, negedge rst_n)
	if (!rst_n) begin
		INT_ff1 <= 0;
		INT_ff2 <= 0;
	end
	else begin
		INT_ff1 <= INT;
		INT_ff2 <= INT_ff1;
	end
	
//Timer
//TODO: idk about this timer. Devin was the one listening
always_ff @(posedge clk, negedge rst_n)
	if (!rst_n) timer <= 16'h0000;
	else if (state == INIT1) timer <= timer + 1;
	
//REGISTERS//
//PDF had 10 8bit registers with the halves combined in assign statements at the end.
//Test to see which is smaller.
always_ff @(posedge clk, negedge rst_n)
	if (!rst_n) ptch_rt <= 16'h0000;
	else if (CPL) ptch_rt [7:0] <= rd_data;
	else if (CPH) ptch_rt [15:8] <= rd_data;

always_ff @(posedge clk, negedge rst_n)
	if (!rst_n) roll_rt <= 16'h0000;
	else if (CRL) roll_rt [7:0] <= rd_data;
	else if (CRH) roll_rt [15:8] <= rd_data;

always_ff @(posedge clk, negedge rst_n)
	if (!rst_n) yaw_rt <= 16'h0000;
	else if (CYL) yaw_rt [7:0] <= rd_data;
	else if (CYH) yaw_rt [15:8] <= rd_data;
	
always_ff @(posedge clk, negedge rst_n)
	if (!rst_n) ax <= 16'h0000;
	else if (CAXL) ax [7:0] <= rd_data;
	else if (CAXH) ax [15:8] <= rd_data;
	
always_ff @(posedge clk, negedge rst_n)
	if (!rst_n) ay <= 16'h0000;
	else if (CAYL) ay [7:0] <= rd_data;
	else if (CAYH) ay [15:8] <= rd_data;

//FSM//	
always_ff @(posedge clk, negedge rst_n)
	if (!rst_n) state <= INIT1;
	else state <= nxt_state;
	
always_comb begin
	nxt_state = WAIT;
	CPH = 0;
	CPL = 0;
	CRH = 0;
	CRL = 0;
	CYH = 0;
	CYL = 0;
	CAXH = 0;
	CAXL = 0;
	CAYH = 0;
	CAYL = 0;
	wrt = 0;
	cmd = 16'h0000;
	vld = 0;
	
	case(state)
		//TODO: need to wait for done in INIT states?
		INIT1: begin
			cmd = 16'h0D02;
			if (&timer) begin
				wrt = 1;
				nxt_state = INIT2;
			end
			else nxt_state = INIT1;
		end
		
		INIT2: begin
			cmd = 16'h1062;
			if (done) begin
				wrt = 1;
				nxt_state = INIT3;
			end
			else nxt_state = INIT2;
		end
		
		INIT3: begin
			cmd = 16'h1162;
			if (done) begin
				wrt = 1;
				nxt_state = INIT4;
			end
			else nxt_state = INIT3;
		end
		
		INIT4: begin
			cmd = 16'h1460;
			if (done) begin
				wrt = 1;
				nxt_state = WAIT;
			end
			else nxt_state = INIT4;
		end
		
		WAIT:
			if (INT_ff2) begin 
				nxt_state = PITCH_L;
				cmd = 16'hA2xx; //Request pitch_L
				wrt = 1;				
			end
			else nxt_state = WAIT;
		
		//These wait for their requested data and request the next state's data
		PITCH_L: begin
			if (done) begin
				CPL = 1;
				nxt_state = PITCH_H;
				cmd = 16'hA3xx;
				wrt = 1;
			end
			else nxt_state = PITCH_L;
		end
		
		PITCH_H: begin
			if (done) begin
				CPH = 1;
				nxt_state = ROLL_L;
				cmd = 16'hA4xx;
				wrt = 1;
			end
			else nxt_state = PITCH_H;
		end
		
		ROLL_L: begin
			if (done) begin
				CRL = 1;
				nxt_state = ROLL_H;
				cmd = 16'hA5xx;
				wrt = 1;
			end
			else nxt_state = ROLL_L;
		end
		
		ROLL_H: begin
			if (done) begin
				CRH = 1;
				nxt_state = YAW_L;
				cmd = 16'hA6xx;
				wrt = 1;				
			end
			else nxt_state = ROLL_H;
		end
			
		YAW_L: begin
			if (done) begin
				CYL = 1;
				nxt_state = YAW_H;
				cmd = 16'hA7xx;
				wrt = 1;
			end
			else nxt_state = YAW_L;
		end
				
		YAW_H: begin
			if (done) begin
				CYH = 1;
				nxt_state = AX_L;
				cmd = 16'hA8xx;
				wrt = 1;
			end
			else nxt_state = YAW_H;
		end	
		
		AX_L: begin
			if (done) begin
				CAXL = 1;
				nxt_state = AX_H;
				cmd = 16'hA9xx;
				wrt = 1;
			end
			else nxt_state = AX_L;
		end
		
		AX_H: begin
			if (done) begin
				CAXH = 1;
				nxt_state = AY_L;
				cmd = 16'hAAxx;
				wrt = 1;
			end
			else nxt_state = AX_H;
		end
		
		AY_L: begin
			if (done) begin
				CAYL = 1;
				nxt_state = AY_H;
				cmd = 16'hABxx;
				wrt = 1;
			end
			else nxt_state = AY_L;
		end
		
		AY_H: begin
			if (done) begin
				vld = 1; //Separate state?
				CAYH = 1;
				nxt_state = WAIT;
			end
			else nxt_state = AY_H;
		end	
		
		default: nxt_state = WAIT;
	endcase
end
	
endmodule
