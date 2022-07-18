`timescale 1 ns / 1 ns
`include "src/register.v"
`include "src/ringbuf.v"

`include "uvm_macros.svh"
`include "uvm/ringbuf/pkg.svh"

module top;
import uvm_pkg::*;
import ringbuf_pkg::*;

//localparam WIDTH = 8;
logic rst, clk;

ringbuf_intf #(.WIDTH(ringbuf_pkg::WIDTH)) intf(rst, clk);

// DUT
ringbuf DUT(.o_data     (intf.rdata),
            .o_empty    (intf.empty),
            .o_overflow (intf.overflow),
            .i_data     (intf.wdata),
            .i_re       (intf.re),
            .i_we       (intf.we),
            .i_rst_n    (intf.rst),
            .i_clk      (intf.clk));
defparam DUT.WIDTH = ringbuf_pkg::WIDTH;
defparam DUT.SIZE = 8;

initial
begin
	clk = 1'b1;
	rst = 1'b0;
	@(negedge clk);
	#1 rst = 1'b1;
end

initial
begin
	uvm_config_db#(virtual ringbuf_intf #(.WIDTH(ringbuf_pkg::WIDTH)))::set(null, "*", "vif", intf);
	run_test("test");
end

initial
begin
	$dumpfile("Debug/ringbuf.vcd");
	$dumpvars;
	#1000 $finish;
end

initial forever #5 clk = ~clk;

endmodule

