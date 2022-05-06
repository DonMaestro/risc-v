`timescale 1 ns / 1 ns
`include "src/executeBR.v"

module tb_executeBR;

localparam WIDTH_REG = 7;
localparam WIDTH_BRM = 4;
localparam WIDTH = 4*32 + WIDTH_REG + WIDTH_BRM + 7 + 10 + 1;

wire [WIDTH-1:0] instr;

reg [31:0] op1, op2, imm, PC, PCNext;
reg [6:0] rd;
reg [6:0] uop;
reg [9:0] func;
reg [3:0] brmask;
reg valid, brkill;


wire [31:0] o_PC;
wire [31:0] o_data;
wire [6:0]  o_addr;
wire [3:0]  o_brmask;
wire o_we, o_valid, o_brkill;
wire [32+7:0] o_bypass;

reg rst_n, clk;

assign instr = { valid, func, brmask, uop, PC, imm, rd, op2, op1 };

executeBR  mod_BR(.o_brmask(o_brmask),
                  .o_brkill(o_brkill),
                  .o_we(o_we),
                  .o_PC(o_PC),
                  .o_addr(o_addr),
                  .o_data(o_data),
                  .o_valid(o_valid),
                  .i_instr(instr),
                  .i_PCNext(PCNext),
                  .i_rst_n(rst_n),
                  .i_clk(clk));
defparam mod_BR.WIDTH_BRM = WIDTH_BRM;
defparam mod_BR.WIDTH_REG = WIDTH_REG;
defparam mod_BR.WIDTH     = WIDTH;

initial
begin
	rst_n = 1'b0;
	rst_n <= #1 1'b1;

	rd = 7'h2;

	valid = 1;
	func = 10'h0;
	uop  = 7'b1100011;
	brmask = 4'h2;
	PCNext = 32'h4;

	imm = 32'h1;
	PC  = 32'h4;
	op1 = 32'h2;
	op2 = 32'h3;

	#40
	uop  = 7'b1101111;

	#40
	uop  = 7'b1100111;

	#40
	PCNext = 32'h3;

	#40
	valid = 0;
end

initial
begin
	clk = 1'b0;
	forever #20 clk = ~clk;
end

initial
begin
	$dumpfile("Debug/executeBR.vcd");
	$dumpvars;

	#1000 $finish;
end

endmodule

