module SPI_mstr16(clk, rst_n, wrt, cmd, MISO, rd_data, SS_n, SCLK, MOSI, done);
input clk, rst_n, wrt, MISO;
input [15:0] cmd;
output reg done, SS_n, SCLK, MOSI;
output reg [15:0] rd_data;

reg [4:0] bitcnt;
reg [4:0] sclk_div;
reg [15:0] shift_reg;
reg rst_cnt, shft, smpl, MISO_smpl, set_done, clr_done;
typedef enum reg [1:0] {IDLE, FRT_PCH, ACTIVE, BCK_PCH} state_t;
state_t state, nxt_state;

assign SCLK = !SS_n ? sclk_div[4] : 1'b1;
assign MOSI = shift_reg[15];
assign rd_data = shift_reg;

//SCLK counter
always_ff @(posedge clk) begin
	if (rst_cnt) sclk_div <= 5'b10111;
	else sclk_div <= sclk_div + 1'b1;
end

//Shift Register
always_ff @(posedge clk)
	if (smpl) MISO_smpl <= MISO;
always_ff @(posedge clk) begin
	if (wrt) shift_reg <= cmd;
	else if (shft) shift_reg <= {shift_reg[14:0], MISO_smpl};
end

//Bit counter
always_ff@(posedge clk, negedge rst_n) begin
	if (!rst_n) bitcnt <= 5'h00;
	else if (rst_cnt) bitcnt <= 5'h00;
	else if (smpl) bitcnt <= bitcnt + 1'b1;
end

//SM
always_ff @(posedge clk, negedge rst_n) begin
	if (!rst_n) state <= IDLE;
	else state <= nxt_state;
end
always_comb begin
	nxt_state = IDLE;
	rst_cnt = 0;
	set_done = 0;
	clr_done = 0;
	SS_n = 0;
	smpl = 0;
	shft = 0;
	
	case(state)
		IDLE: begin
			SS_n = 1;
			if (wrt) begin
				nxt_state = FRT_PCH;
				rst_cnt = 1;
				clr_done = 1;
			end
		end
		
		FRT_PCH: 
			if (sclk_div == 5'b01111) begin
				nxt_state = ACTIVE;
				smpl = 1;
				end
			else nxt_state = FRT_PCH;
			
		ACTIVE: begin
			if (bitcnt == 5'h10) begin
				nxt_state = BCK_PCH;
				
			end
			else nxt_state = ACTIVE;
			
			if (sclk_div == 5'b01111) smpl = 1;
			if (sclk_div == 5'b11111) shft = 1;
		end
		
		BCK_PCH:
			if (sclk_div == 5'b11111) begin
				nxt_state = IDLE;
				set_done = 1;
				shft = 1;
				rst_cnt = 1;
			end
			else nxt_state = BCK_PCH;
	endcase
end

//Done FF
always_ff @(posedge clk, negedge rst_n) begin
	if (!rst_n) done <= 1'b0;
	else if (set_done) done <= 1'b1;
	else if (clr_done) done <= 1'b0;
end

endmodule				
