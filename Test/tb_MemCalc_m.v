`timescale 1 ns / 1 ns
`include "src/MemCalc_m.v"

module tb_MemCalc_m;

reg clk;
reg rst_n;

localparam WIDTH_REG = 7;

reg [31:0] op1, op2, imm;
reg [6:0]  uop;
reg [9:0]  func;
reg [WIDTH_REG-1:0]  rd;
reg        valid;

wire [31:0] o_data;
wire [WIDTH_REG-1:0] o_rd;
wire        o_valid;

wire [4:0] drd, drs1, drs2;

MemCalc_m mod_mem(.o_data (o_data),
                  .o_addr (o_rd),
                  .o_valid(o_valid),
                  .i_valid(valid),
                  .i_uop  (uop),
                  .i_func (func),
                  .i_addr (rd),
                  .i_op1  (op1),
                  .i_op2  (op2),
                  .i_imm  (imm),
                  .i_rst_n(rst_n),
                  .i_clk  (clk));
defparam mod_mem.WIDTH = 4;
defparam mod_mem.WIDTH_REG = WIDTH_REG;

initial
begin
	rst_n     = 1'b0;
	rst_n <= #1 1'b1;

	uop = 7'b0100011;
	func = 10'b0000000_000;
	valid = 1'b1;

	op1 = 32'h1; 
	imm = 32'h1;
	op2 = 32'h3;
	rd = 7'h3;
	
	#40
	uop = 7'b0000011;
	func = 10'b0000000_010;

	#40
	uop = 7'b0000000;
	op1 = 32'h2; 
	imm = 32'h3;
	op2 = 32'h4;
	rd = 7'h3;

	#40
	valid = 1'b0;
end
	  
initial
begin
	clk = 0;
	forever #20 clk = ~clk;
end

initial
begin
	$dumpfile("Debug/MemCalc_m.vcd");
	$dumpvars;

	#1000 $finish;
end

endmodule

