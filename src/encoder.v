module encoder #(parameter SIZE = 20, WIDTH = $clog2(SIZE))
               (output reg [WIDTH-1:0] o_q,
                input wire             i_en,
                input wire [SIZE-1:0]  i_d);

//integer i, j;
integer i;

always @(*)
begin
	/*
	o_q = { WIDTH{1'b0} };
	for (i = 1; i < SIZE; i = i + 1) begin
		for (j = 0; j < WIDTH; j = j + 1) begin
			if (i[j]) begin
				o_q[j] = o_q[j] | i_d[i-1];
			end
		end
	end
	*/

	if (i_en) begin
		for (i = 0; i < SIZE; i = i + 1) begin
			o_q = i_d[i] ? i[WIDTH-1:0] : o_q;
		end
	end
end

endmodule

