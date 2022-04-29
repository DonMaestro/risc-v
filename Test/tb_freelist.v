`timescale 1 ns / 1 ns
`include "src/freelist.v"

module tb_freelist;

localparam WIDTH = 5;

reg clk;
reg rst_n;
reg re, we;

wire [WIDTH-1:0] freelist;

freelist m_freelist(.o_data (freelist),
                    .i_data (freelist),
                    .i_re   (re),
                    .i_we   (we),
                    .i_rst_n(rst_n),
                    .i_clk  (clk));
defparam m_freelist.WIDTH = WIDTH;
defparam m_freelist.SIZE  = $pow(2, WIDTH) - 1;
defparam m_freelist.STNUM = 1;

initial
begin
	rst_n = 0;
	#1 rst_n = 1;

	re = 1;
	we = 1; 
end
	  
initial
begin
	clk = 0;
	forever #20 clk = ~clk;
end

initial
begin
	$dumpfile("Debug/freelist.vcd");
	$dumpvars;

	#10000 $finish;
end

endmodule

