`timescale 1 ns / 1 ns
`include "src/register.v"
`include "src/ringbuf.v"

`define WIDTH 4

`include "uvm_macros.svh"
`include "uvm/ringbuf/pkg.svh"

module top;
import uvm_pkg::*;
import ringbuf_pkg::*;

//localparam WIDTH = 8;
logic rst, clk;

ringbuf_intf ff();

// DUT
ringbuf DUT(.o_data     (ff.rdata),
            .o_empty    (ff.empty),
            .o_overflow (ff.overflow),
            .i_data     (ff.wdata),
            .i_re       (ff.re),
            .i_we       (ff.we),
            .i_rst_n    (ff.rst),
            .i_clk      (ff.clk));
defparam DUT.WIDTH = `WIDTH;
defparam DUT.SIZE = 8;

assign ff.clk = clk;


initial
begin
	//envirenment = new("env");
	//uvm_resource_db#(virtual intf)::set("env", "intf", DUT.ff);
	clk = 1'b0;
	rst = 1'b0;
	rst <= #1 1'b1;
	
	`uvm_info("ID", "WELCOME TO UVM", UVM_MEDIUM);

end

initial
begin
	uvm_config_db#(virtual ringbuf_intf)::set(null, "*", "viff", ff);
	run_test("test");
end

initial forever #10 clk = ~clk;

initial
begin
	$dumpfile("Debug/uvm.vcd");
	$dumpvars;
	#1000 $finish;
end

endmodule

