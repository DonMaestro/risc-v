
//
// Ring Buffer
//
module ringbuf #(parameter WIDTH = 4, SIZE = 20)
               (output wor [WIDTH-1:0] o_data,
                output                 o_empty, o_overflow,
                input      [WIDTH-1:0] i_data,
                input      i_re, i_we, i_rst_n, i_clk);

localparam [SIZE-1:0] RST = { {(SIZE-1){1'b0}}, 1'b1 };
//localparam RST = 1;

wire [SIZE:0] head, tail;
wire [SIZE-1:0] commit, we_data;

wire comp;
reg  over;
wire overr;

wire [WIDTH-1:0] data[0:SIZE-1];

// output
assign o_empty    = comp & ~overr;
assign o_overflow = comp & overr;
//assign overflow_before = |(head & (tail << 1));

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
assign we_data = tail[SIZE-1:0] & { SIZE{i_we} };
assign commit  = head[SIZE-1:0] & { SIZE{i_re} };

generate
	genvar i;
	for (i = 0; i < SIZE; i = i + 1) begin: slot
		register #(1) r_head(.o_q(head[i+1]),
		                     .i_d(head[i]),
		                     .i_en(i_re),
		                     .i_rst_n(i_rst_n),
		                     .i_clk(i_clk));
		defparam r_head.RST_VALUE = RST[i];

		register #(1) r_tail(.o_q(tail[i+1]),
		                     .i_d(tail[i]),
		                     .i_en(i_we),
		                     .i_rst_n(i_rst_n),
		                     .i_clk(i_clk));
		defparam r_tail.RST_VALUE = RST[i];

		slot r_data(.o_q(o_data),
		            .i_d(i_data),
		            .i_re(head[i]),
		            .i_we(we_data[i]),
		            .i_srst(commit[i]),
		            .i_clk(i_clk));
		defparam r_data.WIDTH = WIDTH;

	end
endgenerate

endmodule

/**
 * slote
 */
module slot #(parameter WIDTH = 32)
            (output [WIDTH-1:0] o_q,
             input  [WIDTH-1:0] i_d,
             input  i_re, i_we, i_srst, i_clk);

reg [WIDTH-1:0] data;

// read
assign o_q = i_re ? data : { WIDTH{1'b0} };

// write
always @(posedge i_clk)
begin
	if (i_srst)
		data <= { WIDTH{1'b0} };
	else if (i_we)
		data <= i_d;
end
endmodule

