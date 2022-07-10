`timescale 1 ns / 1 ns
`include "src/register.v"
`include "src/mux2in1.v"
`include "src/mux3in1.v"
`include "src/ram.v"
`include "src/AGU/SAQ.v"
`include "src/AGU/LAQ.v"
`include "src/AGU/AGU.v"

module tb_AGU;

localparam WIDTH_REG = 7;
localparam WIDTH_BRM = 4;
localparam WIDTH_TAG = 4;
localparam WIDTH_MEM = 4;

wire [m_AGU.WIDTH-1:0] instr;

reg [31:0]          op1, op2, imm;
reg [WIDTH_REG-1:0] rd;
reg [6:0]           uop;
reg [9:0]           func;
reg [WIDTH_BRM-1:0] brmask;
reg [1:0]           val;
reg [$pow(2, WIDTH_BRM)-1:0] brkill;

wire          [31:0] dc_data;
wire [WIDTH_MEM-1:0] dc_addr;
wire          [31:0] dc_wdata;
wire                 dc_we;
wire                 dc_kill;

wire                 o_val;
wire          [31:0] o_data;
wire [WIDTH_REG-1:0] o_addr;

reg rst_n, clk;

assign instr = { val, func, brmask, uop, imm, rd, op2, op1 };

AGU m_AGU(//regFile
          .o_data(o_data),
          .o_addr(o_addr),
          .o_val (o_val),
          // DCatch
          .dcache_i_data(dc_wdata),
          .dcache_i_addr(dc_addr),
          .dcache_i_kill(dc_kill),
          .dcache_o_data(dc_data),
          .dcache_o_nack(1'b0),
          // input
          .i_instr (instr),
          .i_brkill(brkill),
          .i_rst_n (rst_n),
          .i_clk   (clk));
defparam m_AGU.WIDTH_REG = WIDTH_REG;
defparam m_AGU.WIDTH_BRM = WIDTH_BRM;
defparam m_AGU.WIDTH_TAG = WIDTH_TAG;
defparam m_AGU.WIDTH_MEM = WIDTH_MEM;

ram m_cache(.o_data(dc_data),
            .i_addr(dc_addr),
            .i_data(dc_wdata),
            .i_we  (dc_we & ~dc_kill),
            .i_clk (i_clk));
defparam m_cache.WIDTH_ADDR = WIDTH_MEM;
defparam m_cache.WIDTH_DATA = 32;

initial
begin
	rst_n = 1'b0;
	rst_n <= #1 1'b1;

	rd = 7'h2;

	val = 1;
	func = 10'h0;
	uop  = 7'b1100011;
	brmask = 4'h2;

	imm = 32'h1;
	op1 = 32'h2;
	op2 = 32'h3;
end

initial
begin
	clk = 1'b0;
	forever #20 clk = ~clk;
end

initial
begin
	$dumpfile("Debug/AGU.vcd");
	$dumpvars;

	#1000 $finish;
end

endmodule

