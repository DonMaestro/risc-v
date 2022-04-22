interface mem_intf #(ADDR_WIDTH = 32)
                  (input wire clk);
	wire [ADDR_WIDTH-1:0] addr;
	wire [31:0] data_core_mem;
	bit  [31:0] data_mem_core;
	wire we, re;
	bit  rst_n;
	modport drive(output data_mem_core, rst_n,
	            input addr, data_core_mem, we, re);
	modport core(output addr, data_core_mem, we, re,
	             input data_mem_core, rst_n);
	modport monitor(input addr, data_core_mem, data_mem_core, we, re, rst_n);
endinterface
