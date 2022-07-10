module LAQ #(parameter WIDTH = 4,
                       WIDTH_REG = 5, WIDTH_TAG = 5,
                       SIZE = 20)
           (output                  o_entries
            output                  o_entry
            // ring buffer
            output                  o_empty, o_overflow,
            input                   i_re, i_we,
            // input data for the table
            input                   i_A,
            input  [WIDTH_ADDR-1:0] i_addr,
            input                   i_V,
            input                   i_M,
            input   [WIDTH_REG-1:0] i_rd,
            input   [WIDTH_TAG-1:0] i_tag,
            input                   i_setM,
            input                   i_rst_n,
            input                   i_clk);

localparam [SIZE-1:0] RST = { {(SIZE-1){1'b0}}, 1'b1 };

integer j;

wire [SIZE:0] head, tail;
wire [SIZE-1:0] re, we;

wire comp;
reg  over;
wire overr;

reg                 A   [0:SIZE-1];
reg                 val [0:SIZE-1];
reg        [32-1:0] addr[0:SIZE-1];
reg                 V   [0:SIZE-1];
reg                 M   [0:SIZE-1];
reg [WIDTH_REG-1:0] rd  [0:SIZE-1];

// output
assign o_empty    = comp & ~overr;
assign o_overflow = comp & overr;

assign comp = |(head & tail);

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

assign head[0] = head[SIZE];
assign tail[0] = tail[SIZE];
assign we = tail[SIZE-1:0] & { SIZE{i_we} };
assign re = head[SIZE-1:0] & { SIZE{i_re} };

generate
	genvar i;
	for (i = 0; i < SIZE; i = i + 1) begin: slot
		register #(1) r_head(.o_q    (head[i+1]),
		                     .i_d    (head[i]),
		                     .i_en   (i_re),
		                     .i_rst_n(i_rst_n),
		                     .i_clk  (i_clk));
		defparam r_head.RST_VALUE = RST[i];

		register #(1) r_tail(.o_q    (tail[i+1]),
		                     .i_d    (tail[i]),
		                     .i_en   (i_we),
		                     .i_rst_n(i_rst_n),
		                     .i_clk  (i_clk));
		defparam r_tail.RST_VALUE = RST[i];
	end
endgenerate

always @(posedge i_clk, negedge i_rst_n)
begin
	for (j = 0; j < SIZE; j = j + 1) begin
		if (!i_rst_n) begin
			A[j]    <= 1'b0;
			val[j]  <= 1'b0;
			addr[j] <= {WIDTH_REG{1'b0}};
			V[j]    <= 1'b0;
			M[j]    <= 1'b0;
		end else begin
			if (we[j]) begin
				A[j]    <= i_A;
				val[j]  <= i_val;
				addr[j] <= i_addr;
				V[j]    <= i_V;
				M[j]    <= i_M;
		end
	end
end

endmodule

