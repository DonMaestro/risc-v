// register with synchronous reset
module sreg #(parameter WIDTH=32)
            (output reg [WIDTH-1:0] o_q,
             input                  i_en,
             input wire [WIDTH-1:0] i_d,
             input i_srsh, i_rst_n, i_clk);

always @(posedge i_clk, negedge i_rst_n)
begin
	if (!i_rst_n)
		o_q <= { WIDTH{1'b0} };
	else if (i_srsh) begin
		o_q <= { WIDTH{1'b0} };
	end else begin
		if (i_en)
			o_q <= i_d;
	end
end

endmodule

