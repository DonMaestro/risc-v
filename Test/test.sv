class test #(parameter ADDR_WIDTH = 32);
	`include "Test/driver.sv"
	`include "Test/generate.sv"
	`include "Test/monitor.sv"

	rand reg [31:0] mem[0:$pow(2, ADDR_WIDTH) - 1];
	rand reg [3:0] kk;

	constraint c_mode { kk < 6; }

	virtual mem_intf #(ADDR_WIDTH) busdr;

	Driver #(ADDR_WIDTH) Dr;
	Monitor #(ADDR_WIDTH) Mon;
	Generator Gen; 

	function new(virtual mem_intf #(ADDR_WIDTH) busdr);
		int i;
		this.busdr = busdr;

		logo();

		Dr = new(busdr);
		Mon = new(busdr);
		Gen = new();

		busdr.rst_n = 1'b0;
	endfunction
	
	task test_all();
		bit [31:0] instruction;

		$display("Start test_all");

		repeat (1000)
		begin
			instruction = Gen.GenLW();
			busdr.data_mem_core = instruction;
			$display("LW %x", instruction);
			@(posedge busdr.clk)
			busdr.data_mem_core = $random;
			@(posedge busdr.re);
		end
	endtask

	extern protected function void logo();
endclass

function void test::logo();
	$display("Test");
endfunction

