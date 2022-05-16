`timescale 1 ns / 1 ns
`include "src/executeALU.v"
`include "src/register.v"
`include "src/mux3in1.v"
`include "src/alu.v"


module tb_executeALU;

localparam WIDTH_REG = 7;
localparam WIDTH_BRM = 4;
localparam WIDTH = 4*32 + WIDTH_REG + WIDTH_BRM + 7 + 10 + 1;

wire [WIDTH-1:0] instr;

reg [31:0] op1, op2, imm, PC;
reg [WIDTH_BRM-1:0] brmask;
reg [WIDTH_REG-1:0] rd;
reg [6:0]  uop;
reg [9:0]  func;
reg valid;

wire [31:0] o_data;
wire [6:0]  o_addr;
wire o_valid;
wire [32+7:0] o_bypass;

reg rst_n, clk;

assign instr = { valid, func, brmask, uop, PC, imm, rd, op2, op1 };

executeALU  mod_ALU(.o_addr(o_addr),
                    .o_data(o_data),
                    .o_bypass(o_bypass),    // { 1, WIDTH_PRD, 32 }
                    .o_valid(o_valid),
                    .i_instr(instr),
                    .i_rst_n(rst_n),
                    .i_clk(clk));
defparam mod_ALU.WIDTH_BRM = WIDTH_BRM;
defparam mod_ALU.WIDTH_REG = WIDTH_REG;
defparam mod_ALU.WIDTH = WIDTH;

initial
begin
	rst_n = 1'b0;
	rst_n <= #1 1'b1;

	rd = 7'h2;

	valid = 1;
	func = 10'h0;
	uop  = 7'b0110011;

	imm = 32'h1;
	PC  = 32'h4;
	op1 = 32'h2;
	op2 = 32'h3;

	#40
	uop  = 7'b0110111;

	#40
	uop  = 7'b0010111;

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
	$dumpfile("Debug/executeALU.vcd");
	$dumpvars;

	#1000 $finish;
end

endmodule

