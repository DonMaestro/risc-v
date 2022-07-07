
module SAQ #(parameter WIDTH = 5)
           (output reg        o_match, 
            input [31:0]      i_addr,
            input [WIDTH-1:0] i_tag,
            input             i_en,
            input [31:0]      i_addrmatch,
            input             i_rst_n, i_clk);

localparam SIZE = 2 ** WIDTH;
integer i, j;

reg [31:0] addr[0:SIZE-1]; 
reg        val [0:SIZE-1]; 

always @(posedge i_clk, negedge i_rst_n)
begin
	if (!i_rst_n) begin
		for (j = 0; j < SIZE; j = j + 1) begin
			addr[j] <= 32'b0;
			val [j] <=  1'b0;
		end
	end else begin
		if (i_en) begin
			addr[i_tag] <= i_addr;
			val [i_tag] <= 1'b1;
		end
	end
end

// matching
always @(*)
begin
	o_match = 1'b0;
	for (i = 0; i < SIZE; i = i + 1) begin
		if (val[i] && (addr[i] & i_addrmatch)) begin
			o_match     = 1'b1;
			val[i_tag] <= 1'b0;
		end
	end
end

endmodule

