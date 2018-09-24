module PB_release(clk, rst_n, PB, released);

input clk, rst_n, PB;
output reg released;

reg f1, f2, f3;

always @(posedge clk, negedge rst_n) begin

	if(!rst_n) begin // preset all flops

		f1 <= 1; // first
		f2 <= 1; // second
		f3 <= 1; // third

	end

	else begin // propagate

		f1 <= PB;
		f2 <= f1;
		f3 <= f2;
		
		released = f3 && ~f2;

	end

end // end always
endmodule
