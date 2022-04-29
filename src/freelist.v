module freelist #(parameter WIDTH = 5, SIZE = $pow(2, WIDTH), STNUM = 0)
                (output [WIDTH-1:0] o_data,
                 input  [WIDTH-1:0] i_data,
                 input              i_re,
                 input              i_we,
                 input              i_rst_n,
                 input              i_clk);
integer i;

reg [WIDTH-1:0] head, tail;
reg [WIDTH-1:0] data[0:SIZE-1]; 

always @(posedge i_clk, negedge i_rst_n)
begin
	if (!i_rst_n) begin
		head <= { WIDTH{1'b0} };
		tail <= { WIDTH{1'b0} };
		for (i = 0; i < SIZE; i = i + 1) begin
			data[i] = i + STNUM;
		end
	end else begin
		if (i_re) begin
			if (head >= SIZE - 1)
				head <= { WIDTH{1'b0} };
			else
				head <= head + 1;
		end

		if (i_we) begin
			if (tail >= SIZE - 1)
				tail <= { WIDTH{1'b0} };
			else
				tail <= tail + 1;

			data[tail] <= i_data;
		end
	end
end

assign o_data = data[head];

endmodule

