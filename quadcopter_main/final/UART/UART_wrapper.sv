module UART_wrapper(clk, rst_n, clr_cmd_rdy, cmd_rdy, 
	cmd, data, RX, TX,
	resp, send_resp, resp_sent);
	
// I/O Directly into UART //
input send_resp;
input [7:0] resp;
output resp_sent;

input clk, rst_n, clr_cmd_rdy; //External resets and clock
input  RX;					//Communication signals
output TX;
output reg cmd_rdy;			//For when wrapping to 3 bytes is done
output reg [7:0] cmd;  		//First of 3 bytes, contains command
output reg [15:0] data;		//Second and third of 3 bytes, contains data

reg rdy, clr_rdy;			//When UART has finished sending a byte 
reg cmd_mux, data_mux;		//Selection for sending current byte to cmd or data
reg [7:0] rx_data;			//Current byte
reg set_cmd_rdy, clr_cmd_rdy_i;		//Output control signals
typedef enum reg [1:0] {CMD, DATA_HI, DATA_LO} state_t;
state_t state, nxt_state;

UART iUART(.clk(clk), .rst_n(rst_n), .rx_rdy(rdy), .rx_data(rx_data), .clr_rx_rdy(clr_rdy), 
	.trmt(send_resp), .tx_done(resp_sent), .tx_data(resp), .RX(RX), .TX(TX));

assign data[7:0] = rx_data;
	
	
//Command Byte FF/Mux
always_ff @(posedge clk)
	if (cmd_mux) cmd <= rx_data;
	
//First Data byte FF/Mux
always_ff @(posedge clk)
	if (data_mux) data[15:8] <= rx_data;
	
//FSM
always_ff @(posedge clk, negedge rst_n) begin
	if (!rst_n) state <= CMD;
	else state <= nxt_state;
end

always_comb begin
	cmd_mux = 0;
	data_mux = 0;
	clr_rdy = 0;
	set_cmd_rdy = 0;
	clr_cmd_rdy_i = 0;
	nxt_state = CMD;
	
	case(state)
		//Waiting to send 3 bytes
		CMD: if (rdy) begin
			cmd_mux = 1;
			clr_rdy = 1;
			clr_cmd_rdy_i = 1;
			nxt_state = DATA_HI;
		end
		
		//Have first byte, put in cmd.
		DATA_HI: if (rdy) begin
			data_mux = 1;
			clr_rdy = 1;
			nxt_state = DATA_LO;
		end
		else nxt_state = DATA_HI;
	
		//Have 2nd byte, put in 1st half of data.
		DATA_LO: if (rdy) begin
			clr_rdy = 1;
			set_cmd_rdy = 1;
			nxt_state = CMD;
		end
		else nxt_state = DATA_LO;
	
		default: nxt_state = CMD;
	endcase
end

//cmd_rdy FF
always_ff @(posedge clk, negedge rst_n) begin
	if (!rst_n) cmd_rdy <= 0;
	else if (clr_cmd_rdy || clr_cmd_rdy_i) cmd_rdy <= 0;
	else if (set_cmd_rdy) cmd_rdy <= 1;
end

endmodule
