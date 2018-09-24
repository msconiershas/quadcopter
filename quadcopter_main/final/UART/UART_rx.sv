module UART_rx(clk, rst_n, clr_rdy, RX, rx_data, rdy);
input clk, rst_n, clr_rdy, RX;

output [7:0] rx_data;
output reg rdy;

reg start, receiving, set_rdy;
reg [3:0] bit_cnt;
reg [11:0] baud_cnt;
reg [8:0] rx_shift_reg;
reg rx_flopped, rx_stable;

typedef enum reg {IDLE, RECEIVE} state_t;
state_t state, nxt_state;

wire shift;

assign shift = ~|baud_cnt;
assign rx_data = rx_shift_reg[7:0];


//Double flop RX for metastability
always_ff @(posedge clk, negedge rst_n) begin
	if (!rst_n) begin
		rx_flopped <= 1;
		rx_stable <= 1;
	end
	else begin
		rx_flopped <= RX;
		rx_stable <= rx_flopped;
	end
end

//Bit counter
always_ff @(posedge clk, negedge rst_n) begin
	if (!rst_n) bit_cnt <= 0;
	else if (start) bit_cnt <= 0;
	else if (shift) bit_cnt <= bit_cnt + 1;
end

//Baud counter
always_ff @(posedge clk, negedge rst_n) begin
  if (!rst_n) baud_cnt <= 1302;
  else if (start) baud_cnt <= 1302;
  else if (shift) baud_cnt <= 2604;
  else if (receiving) baud_cnt <= baud_cnt - 1;
end
	

//Shift Register
always_ff @(posedge clk)
	if (shift) rx_shift_reg <= {rx_stable, rx_shift_reg[8:1]};

//FSM
always_ff @(posedge clk, negedge rst_n) begin
	if (!rst_n) state <= IDLE;
	else state <= nxt_state;
end
always_comb begin
	nxt_state = IDLE;
	start = 0;
	receiving = 0;
	set_rdy = 0;
	
	case(state)
		IDLE: if (!rx_stable) begin //wait for fall of start bit
			nxt_state = RECEIVE;
			start = 1;
		end
		else nxt_state = IDLE;
		
		default: begin  //RECEIVE state
			if (bit_cnt == 10) begin
				nxt_state = IDLE;
				set_rdy = 1;
			end
			else nxt_state = RECEIVE;
			receiving = 1;
		end
	endcase
end

//Rdy FF
always_ff @(posedge clk, negedge rst_n) begin
	if (!rst_n) rdy <= 1'b0;
	else if (start || clr_rdy) rdy <= 1'b0;
	else if (set_rdy) rdy <= 1'b1;
end		

endmodule
			

		
