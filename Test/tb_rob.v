`timescale 1 ns / 1 ns
`include "src/rob.v"
`include "src/register.v"
`include "src/encoder.v"
`include "src/ringbuf.v"

module tb_rob;

localparam WIDTH_REG = 7;
localparam WIDTH_BRM = 4;

wire [2:0]             tag;
wire [4*WIDTH_REG-1:0] com_prd4x;
wire                   com_en;
reg             rst_n, clk;
 
reg [31:0]            PC;
reg [4*7-1:0]         uop4x;
reg [4*WIDTH_BRM-1:0] brm4x;
reg [4*WIDTH_REG-1:0] prd4x;
reg [4*32-1:0]        imm4x;
reg                   we;

rob m_rob(.o_dis_tag(tag),
          .o_com_prd4x(com_prd4x),
          .o_com_en(com_en),
          .i_dis_pc(PC),
          .i_dis_uops4x(uop4x),
          .i_dis_mask4x(brm4x),
          .i_dis_prd4x(prd4x),
          .i_dis_imm(imm4x),
          .i_dis_we(we),
          .i_rst4x_valtg(),
          .i_rst4x_busytg(),
          .i_set4x_exctg(),
          .i_rst_n(rst_n),
          .i_clk(clk));
defparam m_rob.WIDTH_REG = WIDTH_REG;
defparam m_rob.WIDTH_BRM = WIDTH_BRM;

initial
begin
	rst_n = 1'b0;
	rst_n <= #1 1'b1;

	$display("gg %d", m_rob.we);

	PC = 32'b0;
	uop4x = { 7'h5, 7'h3, 7'h40, 7'h4f };
	brm4x = { 4'b1000, 4'b0100, 4'b0010, 4'b0001 };
	prd4x = { 7'h3, 7'h2, 7'h1, 7'h0 };
	imm4x = { 32'hff, 32'hff00, 32'hff0000, 32'hff000000 };
	we = 1'b1;
end

initial
begin
	clk = 1'b0;
	forever #20 clk = ~clk;
end

initial
begin
	$dumpfile("Debug/rob.vcd");
	$dumpvars;

	#1000 $finish;
end

endmodule

