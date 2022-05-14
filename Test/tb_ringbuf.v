`timescale 1 ns / 1 ns
`include "src/ringbuf.v"
`include "src/register.v"

module tb_ringbuf;

localparam WIDTH = 4;

reg rst_n, clk;

reg re, we, empty;
reg  [WIDTH-1:0] data;
wire [WIDTH-1:0] o_data;
wire             o_empty;

ringbuf m_ringbuf(.o_data(o_data),
                  .o_empty(o_empty),
                  .i_data(data),
                  .i_re(re),
                  .i_we(we),
                  .i_rst_n(rst_n),
                  .i_clk(clk));
defparam m_ringbuf.WIDTH = WIDTH;
defparam m_ringbuf.SIZE = 8;

initial
begin
	rst_n = 1'b0;
	rst_n <= #1 1'b1;

	re = 1'b0;
	we = 1'b1;
	data = 4'b1111;

	#360
	re = 1'b1;
	we = 1'b0;
end

always @(posedge clk)
begin
	data <= data + 1;
end

initial
begin
	clk = 1'b0;
	forever #20 clk = ~clk;
end

initial
begin
	$dumpfile("Debug/ringbuf.vcd");
	$dumpvars;

	#1000 $finish;
end


endmodule

