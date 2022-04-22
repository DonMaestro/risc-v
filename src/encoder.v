module encoder #(parameter SIZE = 20)
               (output reg [WIDTH-1:0] o_q,
                input wire [SIZE-1 :0] i_d);

localparam WIDTH = $clog2(SIZE);

integer i, j;

always @(*)
begin
	o_q = { WIDTH{1'b0} };
	for (i = 1; i < SIZE; i = i + 1) begin
		for (j = 0; j < WIDTH; j = j + 1) begin
			if (i[j]) begin
				o_q[j] = o_q[j] | i_d[i-1];
			end
		end
	end
end

endmodule

