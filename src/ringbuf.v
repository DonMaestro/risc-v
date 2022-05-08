
//
// Ring Buffer
//
module ringbuf #(parameter WIDTH = 4, SIZE = 20)
               (output [WIDTH-1:0] o_data,
                input  [WIDTH-1:0] i_data,
                //input  i_rst_val, i_rst_busy, i_set_exc,
                input  i_re, i_we, i_rst_n, i_clk);

wire [SIZE:0] head, tail;
wire [SIZE-1:0] commit, we_data;

wire [WIDTH-1:0] data[0:SIZE-1];

assign head[0] = head[SIZE];
assign tail[0] = tail[SIZE];
assign we_data = tail & { SIZE{i_we} };
assign commit  = head;

generate
	genvar i;
	for (i = 0; i < SIZE; i = i + 1) begin
		register #(1) r_head(.o_q(head[i+1]),
		                     .i_d(head[i]),
		                     .i_en(i_re),
		                     .i_rst_n(i_rst_n),
		                     .i_clk(i_clk));
		defparam r_head.RST_VALUE = !i;

		register #(1) r_tail(.o_q(tail[i+1]),
		                     .i_d(tail[i]),
		                     .i_en(i_we),
		                     .i_rst_n(i_rst_n),
		                     .i_clk(i_clk));
		defparam r_tail.RST_VALUE = !i;

		reg_srst r_data(.o_q(data[i]),
		                .i_d(i_data),
		                .i_en(we_data[i]),
		                .i_srst(commit[i]),
		                .i_clk(i_clk));
		defparam r_data.WIDTH = WIDTH;
	end
endgenerate

assign o_data = data[head];

endmodule

module reg_srst #(parameter WIDTH = 32)
                (output reg [WIDTH-1:0] o_q,
                 input wire [WIDTH-1:0] i_d,
                 input wire i_en, i_srst, i_clk);

always @(posedge i_clk)
begin
	if (i_srst)
		o_q <= { WIDTH{1'b0} };
	else if (i_en)
		o_q <= i_d;
end

endmodule

