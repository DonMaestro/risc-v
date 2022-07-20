module encoder #(parameter WIDTH = 2, SIZE = 2 ** WIDTH)
               (output reg [WIDTH-1:0] o_q,
                input wire             i_en,
                input wire [SIZE-1:0]  i_d);

integer i;

always @(*)
begin
	if (i_en) begin
		o_q = { WIDTH{1'b0} };
		for (i = 0; i < SIZE; i = i + 1)
			if (i_d[i])
				o_q = i[WIDTH-1:0];
	end
end

endmodule

