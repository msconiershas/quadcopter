module A2D_intf(clk, rst_n, strt_cnv, chnnl, cnv_cmplt, res, SS_n, SCLK, MOSI, MISO);
input clk, rst_n;
input strt_cnv;
input [2:0] chnnl;
output reg cnv_cmplt;
output [11:0]res;

//SPI_mstr16 interface
reg [15:0] cmd, rd_data;
reg wrt, done, set_cnv_cmplt;
output SS_n, SCLK, MOSI, MISO;

//State Regs
typedef enum reg [1:0] {IDLE, FIRST, WAIT, SECOND} state_t;
state_t state, nxt_state;

SPI_mstr16 iSPI(.clk(clk), .rst_n(rst_n), 
	.wrt(wrt), .cmd(cmd), .done(done), .rd_data(rd_data),
	.SCLK(SCLK), .MOSI(MOSI), .MISO(MISO), .SS_n(SS_n));

assign cmd = {2'b00, chnnl, 11'h000};
assign res = rd_data[11:0];

always_ff @(posedge clk, negedge rst_n) begin
	if (!rst_n) state <= IDLE;
	else state <= nxt_state;
end

always_comb begin
	wrt = 0;
	set_cnv_cmplt = 0;
	nxt_state = IDLE;

	case(state)
		IDLE:
			if (strt_cnv) begin
				wrt = 1;
				nxt_state = FIRST;
			end

		FIRST: 
			if (done) nxt_state = WAIT;
			else nxt_state = FIRST;

		WAIT: 
			begin
				nxt_state = SECOND;
				wrt = 1;
			end

		SECOND:
			if (done) set_cnv_cmplt = 1;
			else nxt_state <= SECOND;
	endcase
end

//Done SRFF
always_ff @(posedge clk, negedge rst_n) begin
	if (!rst_n) cnv_cmplt <= 0;
	else if (strt_cnv) cnv_cmplt <= 0;
	else if (set_cnv_cmplt) cnv_cmplt <= 1;
end

endmodule
