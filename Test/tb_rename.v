`timescale 1 ns / 10 ps
`include "src/rename.v"
`include "src/maptable.v"
`include "src/mux2in1.v"
`include "src/register.v"
`include "src/comparator.v"

module tb_rename;

reg [4*7-1:0] freelist;
reg [3*5-1:0] rg1, rg2, rg3, rg4;
reg rst, clk;

wire [3*7-1:0] prg1, prg2, prg3, prg4;
wire [4*7-1:0] mtab;
wire [3:0]     enflist;

rename #(7) m_rename(.o_prg1(prg1),
                     .o_prg2(prg2),
                     .o_prg3(prg3),
                     .o_prg4(prg4),
                     .o_mtab(mtab),             // old prd for commit
                     .o_enfreelist(enflist),    // enable read freelist
                     .i_rg1(rg1),
                     .i_rg2(rg2),
                     .i_rg3(rg3),
                     .i_rg4(rg4),
                     .i_freelist(freelist),
                     .i_en(1'b1),
                     .i_rst_n(rst),
                     .i_clk(clk));

initial
begin
	rst <= #0 1'b1;
	rst <= #1 1'b0;
	rst <= #2 1'b1;

	freelist = { 7'h14, 7'h13, 7'h12, 7'h11 };
	rg1 = { 5'h01, 5'h00, 5'h00 };
	rg2 = { 5'h02, 5'h00, 5'h00 };
	rg3 = { 5'h03, 5'h00, 5'h00 };
	rg4 = { 5'h04, 5'h00, 5'h00 };

	#21
	freelist = { 7'h18, 7'h17, 7'h16, 7'h15 };
	rg1 = { 5'h01, 5'h02, 5'h01 };
	rg2 = { 5'h00, 5'h02, 5'h01 };
	rg3 = { 5'h03, 5'h02, 5'h01 };
	rg4 = { 5'h03, 5'h02, 5'h01 };
end

initial
begin
	clk = 1'b0;
	forever #20 clk = ~clk;
end

initial
begin
	$dumpfile("Debug/rename.vcd");
	$dumpvars;

	#1000 $finish;
end
endmodule
