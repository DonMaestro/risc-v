
module SAQ #(parameter WIDTH_TAG = 5,
                       WIDTH_ADDR = 32,
                       WIDTH = 4, SIZE = 2 ** WIDTH,
                       WIDTH_DATA = 4 + WIDTH_ADDR + WIDTH_TAG)
           (output [WIDTH_DATA * SIZE - 1:0] o_entries,
            output [WIDTH_DATA - 1:0]        o_entry,
            // ring buffer
            output                 o_empty, o_overflow,
            input                  i_re, i_we,
            // input                
            input                  i_val,
            input [WIDTH_ADDR-1:0] i_addr,
            input                  i_V,
            input [WIDTH_TAG-1:0]  i_tag,
            input                  i_aval,
            // set/reset flags
            input [WIDTH-1:0]      i_set_aval,
            input                  i_rst_n, i_clk);

integer j;

reg [WIDTH-1:0] head, tail;

wire comp, overr;
reg  over;

reg                  A   [0:SIZE-1];
reg                  val [0:SIZE-1];
reg [WIDTH_ADDR-1:0] addr[0:SIZE-1];
reg                  V   [0:SIZE-1];
reg [WIDTH_TAG-1:0]  tag [0:SIZE-1];
reg                  aval[0:SIZE-1];

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
			tag [tail] <= i_tag;
			aval[tail] <= i_aval;
		end
	end
end

assign o_entry = { A   [head],
                   val [head],
                   addr[head],
                   V   [head],
                   tag [head],
                   aval[head]
};

generate
	genvar i;

	for (i = 0; i < SIZE; i = i + 1) begin
		assign o_entries[(i+1)*WIDTH_DATA-1:i*WIDTH_DATA] = {
			A   [i],
			val [i],
			addr[i],
			V   [i],
			tag [i],
			aval[i]
		};
	end
endgenerate

endmodule

