module register #(parameter WIDTH=32, RST_VALUE = 32'b0)
                (output reg [WIDTH-1:0] o_q,
                 input wire             i_en,
                 input wire [WIDTH-1:0] i_d,
                 input wire             i_rst_n, i_clk);

always @(posedge i_clk, negedge i_rst_n)
begin
	if (!i_rst_n)
		o_q <= RST_VALUE;
	else begin
		if (i_en)
			o_q <= i_d;
	end
end

endmodule

