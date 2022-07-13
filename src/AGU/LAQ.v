module LAQ #(parameter WIDTH_REG = 5, WIDTH_TAG = 5,
                       WIDTH_ADDR = 32,
                       WIDTH = 4, SIZE = 2 ** WIDTH,
                       WIDTH_DATA = 5 + WIDTH_ADDR + WIDTH_REG + WIDTH_TAG)
           (output [WIDTH_DATA * SIZE - 1:0] o_entries,
            output [WIDTH_DATA - 1:0]        o_entry,
            output reg [WIDTH_ADDR - 1:0]    o_wkup_addr,
            output reg                       o_wkup_val,
            // ring buffer
            output                 o_empty, o_overflow,
            output [WIDTH-1:0]     o_tail,
            input                  i_re,
            input                  i_we,
            // input
            // new entry
            input                  i_val,
            input [WIDTH_REG-1:0]  i_rd,
            input [WIDTH_TAG-1:0]  i_tag,
            // addr
            input                  i_weV,
            input [WIDTH-1:0]      i_waddrV,
            input [WIDTH_ADDR-1:0] i_addr,
            input                  i_V,
            // data availability
            input                  i_weS,
            input [WIDTH-1:0]      i_waddrS,
            //
            input                  i_weM,
            input [WIDTH-1:0]      i_waddrM,
            // clk
            input                  i_rst_n,
            input                  i_clk);

integer j;

reg [WIDTH-1:0] head, tail;

wire comp, overr;
reg  over;

reg                  A   [0:SIZE-1];
reg                  val [0:SIZE-1];
reg [WIDTH_ADDR-1:0] addr[0:SIZE-1];
reg                  V   [0:SIZE-1];
reg                  S   [0:SIZE-1];
reg                  M   [0:SIZE-1];
reg [WIDTH_REG-1:0]  rd  [0:SIZE-1];
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
			A[j]    <= 1'b0;
			val[j]  <= 1'b0;
		end
	end else begin
		if (i_we) begin
			A   [tail] <= 1'b1;
			val [tail] <= i_val;
			S   [tail] <= 1'b0;
			M   [tail] <= 1'b0;
			rd  [tail] <= i_rd;
			tag [tail] <= i_tag;
		end

		if (i_weV) begin
			addr[i_waddrV] <= i_addr;
			V   [i_waddrV] <= i_V;
		end

		if (i_weS) begin
			S   [i_waddrS] <= 1'b1;
		end

		if (i_weM)
			M   [i_waddrM] <= 1'b1;
	end
end

assign o_entry = {
	A   [head],
	val [head],
	addr[head],
	V   [head],
	S   [head],
	M   [head],
	rd  [head],
	tag [head]
};

generate
	genvar i;

	for (i = 0; i < SIZE; i = i + 1) begin
		assign o_entries[(i+1)*WIDTH_DATA-1:i*WIDTH_DATA] = {
			A   [i],
			val [i],
			addr[i],
			V   [i],
			S   [i],
			M   [i],
			rd  [i],
			tag [i]
		};
	end
endgenerate

integer g;
always @(*)
begin
	o_wkup_val = 1'b0;
	for (g = 0; g < SIZE; g = g + 1) begin
		o_wkup_val = o_wkup_val | A[g] & val[g];
		if (A[g] && (val[g] || V[g] || M[g])) begin
			o_wkup_addr = g[WIDTH-1:0];
		end
	end
end

endmodule

