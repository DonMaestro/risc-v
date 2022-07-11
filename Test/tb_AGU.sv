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
reg [9:0]           func;
reg [WIDTH_REG-1:0] rd;
reg [WIDTH_BRM-1:0] brmask;
reg [WIDTH_TAG-1:0] tag;
reg [6:0]           uop;
reg [1:0]           val;
reg [$pow(2, WIDTH_BRM)-1:0] brkill;

wire          [31:0] ram_data;
wire          [31:0] dc_data;
wire [WIDTH_MEM-1:0] dc_addr;
wire          [31:0] dc_wdata;
wire                 dc_we;
wire                 dc_kill;

wire                 o_val;
wire          [31:0] o_data;
wire [WIDTH_REG-1:0] o_addr;

reg rst_n, clk;

assign instr = { val, uop, tag, brmask, rd, func, imm, op2, op1 };

AGU m_AGU(//regFile
          .o_data(o_data),
          .o_addr(o_addr),
          .o_val (o_val),
          // DCatch
          .dcache_i_data(dc_wdata),
          .dcache_i_addr(dc_addr),
          .dcache_i_we  (dc_we),
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

ram m_cache(.o_data(ram_data),
            .i_addr(dc_addr),
            .i_data(dc_wdata),
            .i_we  (dc_we & ~dc_kill),
            .i_clk (clk));
defparam m_cache.WIDTH_ADDR = WIDTH_MEM;
defparam m_cache.WIDTH_DATA = 32;

register #(32) r_dc_data(dc_data, 1'b1, ram_data, rst_n, clk);

initial
begin
	m_cache.m_ram[0] = 32'h0;
	m_cache.m_ram[1] = 32'hf;
	m_cache.m_ram[2] = 32'hff;
	m_cache.m_ram[3] = 32'hfff;
	m_cache.m_ram[4] = 32'hffff;
end

initial
begin
	rst_n = 1'b0;
	rst_n <= #1 1'b1;

	brkill = 16'b0000_0000_0000_0000;
	brmask = 4'h2;

	func = 10'h0;
	imm = 32'h1;

	val = 2'b01;
	uop  = 7'b0000011; //lw
	tag = 4'h1;
	op1 = 32'h2;
	op2 = 32'h3;
	rd = 7'h2;

	#40
	val = 2'b01;
	uop  = 7'b0100011; //sw
	tag = 4'h2;
	op1 = 32'h3;
	// address = 0x4;
	op2 = 32'h4;

	#40
	val = 2'b01;
	uop  = 7'b0000011; //lw
	tag = 4'h3;
	// address not change
	rd = 7'h4;

	#40
	val = 2'b10;
	uop  = 7'b0100011; //sw
	tag = 4'h2;
	op1 = 32'h3;
	// address = 0x4;
	op2 = 32'h4;

	#40
	val = 2'b00;
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

