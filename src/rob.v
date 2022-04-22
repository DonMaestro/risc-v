module rob(output [NBANK-1:0] o_tag,
           input  [27:0]      i_dis_uops4,
           input  [ 7:0]      i_dis_mask4,
           input  [31:0]      i_pc,
           input              i_we,
	   input              i_rst_n,
	   input              i_clk);

localparam NBANK = 4;

localparam WIDTH = 20;
localparam SIZE = 2^WIDTH;

reg [31:0] pc[0:SIZE-1];
reg [WIDTH-1:0] data[0:NBANK-1];

wire [6:0] dis_uops[0:NBANK-1]
wire [1:0] dis_mask[0:NBANK-1]

assign { dis_uops[3], dis_uops[2], dis_uops[1], dis_uops[0] } = i_dis_uops4;
assign { dis_mask[3], dis_mask[2], dis_mask[1], dis_mask[0] } = i_dis_mask4;

inst_bank m_pc_b(.o_data(commit[i]),
                 .i_data(i_pc[31:2]),
                 .i_re(commit_en),
                 .i_we(we),
                 .i_rst_n(i_rst_n),
                 .i_clk(i_clk));
defparam m_pc_b.WIDTH = 32 - 2;
defparam m_pc_b.SIZE = SIZE;

generate
	genvar i;
	for (i = 0; i < NBANK; i = i + 1) begin
		// val busy exc uopc brmask
		assign data[i] = { 1'b1, 1'b1, 1'b0, dis_uopc[i], dis_mask[i] };

		inst_bank m_inst_b(.o_data(commit[i]),
		                   .i_data(data[i]),
		                   .i_re(commit_en),
		                   .i_we(we),
		                   .i_rst_n(i_rst_n),
		                   .i_clk(i_clk));
		defparam m_inst_b[i].WIDTH = WIDTH;
		defparam m_inst_b[i].SIZE = SIZE;
	end
endgenerate

endmodule

// Ring Buffer
module inst_bank #(parameter WIDTH = 4, SIZE = 20)
                 (output [WIDTH-1:0]      o_data,
                  output [WIDTH_BANK-1:0] o_tag,
                  input  [WIDTH-1:0]      i_data,
                  input  i_rst_val, i_rst_busy, i_set_exc);
                  input  i_we, i_rst_n, i_clk);

localparam WIDTH_BANK = $clog2(SIZE);
integer i;

wire [SIZE-1:0] head, head_shift, tail, tail_shift;
wire [SIZE-1:0] commit, we_dat;
reg [WIDTH-1:0] data[0:SIZE-1];

assign head_shift = head <<< 1;
assign tail_shift = tail <<< 1;

assign we_dat = tail & { SIZE{i_we} };
assign commit = head & busy;

generate
	genvar i;
	for (i = 0; i < SIZE; i = i + 1) begin
		register #(1) r_head(.o_q(head[i]),
		                     .i_d(head_shift[i]),
		                     .i_en(i_re),
		                     .i_rst_n(i_rst_n),
		                     .i_clk(clk));

		register #(1) r_tail(.o_q(tail[i]),
		                     .i_d(tail_shift[i]),
		                     .i_en(i_we),
		                     .i_rst_n(i_rst_n),
		                     .i_clk(clk));

		reg_srst r_val(.o_q(val[i]),
		               .i_d(i_data[WIDTH-1]),
		               .i_en(we_dat[i]),
		               .i_srst(commit[i]),
		               .i_clk(clk));

		reg_srst r_data(.o_q(data[i]),
		                .i_d(i_data),
		                .i_en(we_dat[i]),
		                .i_srst(commit[i]),
		                .i_clk(clk));
		defparam r_data.WIDTH = WIDTH;
	end
endgenerate

encoder m_encoder(.o_q(o_tag),
                  .i_d(tail));
defparam m_encoder.SIZE = SIZE;

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

