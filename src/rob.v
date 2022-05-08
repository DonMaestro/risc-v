module rob #(parameter WIDTH_REG = 7, WIDTH_BRM = 4)
           (output [2:0]             o_dis_tag,
            output [4*WIDTH_REG-1:0] o_com_prd4x,
            output                   o_com_en,
            input  [31:0]            i_dis_pc,
            input  [27:0]            i_dis_uops4x,
            input  [4*WIDTH_BRM-1:0] i_dis_mask4x,
            input  [4*WIDTH_REG-1:0] i_dis_prd4x,
            input  [4*32-1:0]        i_dis_imm,
            input                    i_dis_we,
            input  [3:0]             i_rst4x_valtg,
            input  [3:0]             i_rst4x_busytg,
            input  [3:0]             i_set4x_exctg,
            input                    i_rst_n,
            input                    i_clk);

localparam NBANK = 4;

localparam WIDTH = 3 + 7 + WIDTH_BRM;
localparam SIZE = $pow(2, 5) / 4;

reg [31:0] pc[0:SIZE-1];
wire [WIDTH-1:0] data[0:NBANK-1];
wire [WIDTH-1:0] commit[0:NBANK-1];

wire [6:0]           dis_uops[0:NBANK-1];
wire [WIDTH_BRM-1:0] dis_mask[0:NBANK-1];

wire commit_en, we;

assign { dis_uops[3], dis_uops[2], dis_uops[1], dis_uops[0] } = i_dis_uops4x;
assign { dis_mask[3], dis_mask[2], dis_mask[1], dis_mask[0] } = i_dis_mask4x;

assign commit_en = commit[3][WIDTH-1] & commit[2][WIDTH-1] & commit[1][WIDTH-1] & commit[0][WIDTH-1];
assign we = i_dis_we;

wire [31:2] gg;

ringbuf m_pc_b(.o_data(gg),
               .i_data(i_dis_pc[31:2]),
               .i_re(commit_en),
               .i_we(we),
               .i_rst_n(i_rst_n),
               .i_clk(i_clk));
defparam m_pc_b.WIDTH = 32 - 2;
defparam m_pc_b.SIZE = SIZE;

/*
generate
	genvar i;
	for (i = 0; i < NBANK; i = i + 1) begin
		// val busy exc uops brmask
		assign data[i] = { 1'b1, 1'b1, 1'b0, dis_uops[i], dis_mask[i] };

		ringbuf m_inst_b(.o_data(commit[i]),
		                 .i_data(data[i]),
		                 .i_re(commit_en),
		                 .i_we(we),
		                 .i_rst_n(i_rst_n),
		                 .i_clk(i_clk));
		defparam m_inst_b.WIDTH = WIDTH;
		defparam m_inst_b.SIZE = SIZE;
	end
endgenerate
*/

/*
encoder m_encoder(.o_q(o_dis_tag),
                  .i_d(m_inst_b.tail));
defparam m_encoder.SIZE = SIZE;
*/

endmodule

