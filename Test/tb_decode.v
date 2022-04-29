`timescale 1 ns / 10 ps
`include "src/decode.v"

module tb_decode;

reg clk;

reg [31:0] Instr;
reg        Imask;

wire [14:0] regs;
wire [31:0] dimm;
wire [9:0] func;
wire [4:0] ctrl;

wire [4:0] drd, drs1, drs2;

assign { drd, drs2, drs1 } = regs;

decode mod_decode(.o_regs (regs),
                  .o_func (func),
                  .o_ctrl (ctrl),
                  .o_imm  (dimm),
                  .i_instr(Instr),
                  .i_imask(Imask));

initial
begin
	Imask = 1;
	Instr = 32'hfe010113;

	#10
	Imask = 1;
	Instr = 32'h00112e23;

	#10
	Imask = 1;
	Instr = 32'h01c0006f;
	
end
	  
initial
begin
	clk = 0;
	forever #20 clk = ~clk;
end

initial
begin
	$dumpfile("Debug/decode.vcd");
	$dumpvars;

	#1000 $finish;
end

endmodule

