
module SAQ #(parameter WIDTH_TAG = 5,
                       WIDTH_ADDR = 32,
                       WIDTH = 4, SIZE = 2 ** WIDTH,
                       WIDTH_DATA = 4 + WIDTH_ADDR + WIDTH_TAG)
           (output [WIDTH_DATA * SIZE - 1:0] o_cells,
            output [WIDTH_DATA - 1:0]        o_entry,
            // ring buffer
            output                 o_empty, o_overflow,
            input                  i_re,
            input                  i_we,
            // input
            // new entry
            input                  i_val,
            input [WIDTH_TAG-1:0]  i_tag,
            // addr
            input                  i_weV,
            input [WIDTH-1:0]      i_waddrV,
            input [WIDTH_ADDR-1:0] i_addr,
            input                  i_V,
            // data availability
            input                  i_setD,
            input [WIDTH-1:0]      i_waddrD,
            input                  i_rst_n, i_clk);

integer j;

reg [WIDTH-1:0] head, tail;

wire comp, overr;
reg  over;

reg                  A   [0:SIZE-1];
reg                  val [0:SIZE-1];
reg [WIDTH_ADDR-1:0] addr[0:SIZE-1];
reg                  V   [0:SIZE-1];
reg                  D   [0:SIZE-1];
reg [WIDTH_TAG-1:0]  tag [0:SIZE-1];

// output
assign o_empty    = comp & ~overr;
assign o_overflow = comp & overr;

assign comp = head == tail;

always @(overr, i_re, i_we)
begin
	case({overr, i_re, i_we})
	3'b001 : over = 1'b1;
	3'b100 : over = 1'b1;
	3'b101 : over = 1'b1;
	3'b111 : over = 1'b1;
	default: over = 1'b0;
	endcase
end

register #(1) r_we(overr, 1'b1, over, i_rst_n, i_clk);

always @(posedge i_clk, negedge i_rst_n)
begin
	// counters
	if (!i_rst_n) begin
		head <= {WIDTH{1'b0}};
		tail <= {WIDTH{1'b0}};
	end else begin
		if (i_re)
			head <= head == SIZE-1 ? {WIDTH{1'b0}} : head + 1;
			//head <= head + { { (WIDTH-1){1'b0} }, 1'b1 };
		if (i_we)
			tail <= tail == SIZE-1 ? {WIDTH{1'b0}} : tail + 1;
	end

	// data
	if (!i_rst_n) begin
		for (j = 0; j < SIZE; j = j + 1) begin
			A  [j] <= 1'b0;
			val[j] <= 1'b0;
		end
	end else begin
		if (i_we) begin
			A   [tail] <= 1'b1;
			val [tail] <= i_val;
			addr[tail] <= i_addr;
			V   [tail] <= i_V;
			D   [tail] <= 1'b0;
			tag [tail] <= i_tag;
		end

		if (i_weV) begin
			addr[i_waddrV] <= i_addr;
			V   [i_waddrV] <= i_V;
		end

		if (i_setD) begin
			D   [i_waddrD] <= 1'b1;
		end

		//if (i_we2) begin
		//	D[i_Da] =
		//end
	end
end

assign o_entry = { A   [head],
                   val [head],
                   addr[head],
                   V   [head],
                   D   [head],
                   tag [head]
};

generate
	genvar i;

	for (i = 0; i < SIZE; i = i + 1) begin
		assign o_cells[(i+1)*WIDTH_DATA-1:i*WIDTH_DATA] = {
			A   [i],
			val [i],
			addr[i],
			V   [i],
			D   [i],
			tag [i]
		};
	end
endgenerate

endmodule

