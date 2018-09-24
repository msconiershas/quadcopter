module reset_synch(RST_n, clk, rst_n);

input RST_n, clk;
output reg rst_n;
reg btwn_ffs;

always @(posedge clk, negedge RST_n) begin
//Push of the button will asynch reset the two flops
	if (!RST_n) begin
		btwn_ffs <= 1'b0;
		rst_n <= 1'b0;
	end
	
	else begin
		btwn_ffs <= 1'b1;
		rst_n <= btwn_ffs;
	end
end

endmodule

