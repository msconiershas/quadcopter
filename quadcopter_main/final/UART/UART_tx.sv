module UART_tx(clk, rst_n, trmt, tx_data, TX, tx_done);
input clk, rst_n, trmt;
input [7:0] tx_data;

output TX; 
output reg tx_done;

reg load, shift, transmitting;
reg [8:0] tx_shift_reg;
reg [11:0] baud_cnt;
reg [3:0] bit_cnt;

typedef enum reg {IDLE, TRANSMIT} state_t;
state_t state, nxt_state;

assign TX = tx_shift_reg[0];
assign shift = ~|baud_cnt;

//Bit Counter
always_ff @(posedge clk, negedge rst_n) begin
	if (!rst_n) bit_cnt <= 0;
	else if (load) bit_cnt <= 0;
	else if (shift) bit_cnt <= bit_cnt + 1;
end

//Baud Counter
always_ff @(posedge clk, negedge rst_n) begin
	if (!rst_n) baud_cnt <= 2604;
	else if (load || shift) baud_cnt <= 2604;
	else if (transmitting) baud_cnt <= baud_cnt - 1;
end
	

//Shift Register
always_ff @(posedge clk, negedge rst_n) begin
	if (!rst_n) tx_shift_reg <= 9'h1FF;
	else if (load) tx_shift_reg <= {tx_data, 1'b0};
	else if (shift) tx_shift_reg <= {1'b1, tx_shift_reg[8:1]};
end

//State Flop//
always_ff @(posedge clk, negedge rst_n) begin
	if (!rst_n) state <= IDLE;
	else state <= nxt_state;
end

//FSM//
always_comb begin
	nxt_state = IDLE;
	load = 0;
	transmitting = 0;

	case(state)
		IDLE: if (trmt) begin
			nxt_state = TRANSMIT;
			load = 1;
		end
		else nxt_state = IDLE;
			
		default: begin
			if (bit_cnt == 10) nxt_state = IDLE;
			else nxt_state = TRANSMIT;
			transmitting = 1;
		end
	endcase
end

//Done FF
always_ff @(posedge clk, negedge rst_n) begin
	if (!rst_n) tx_done <= 1'b0;
	else if (bit_cnt == 10) tx_done <= 1'b1;
	else if (trmt) tx_done <= 1'b0;
end

endmodule


	