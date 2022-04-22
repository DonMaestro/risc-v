
class Monitor #(parameter ADDR_WIDTH = 32);

	virtual mem_intf #(ADDR_WIDTH) busmem;

	function new(virtual mem_intf #(ADDR_WIDTH) busmem);
		this.busmem = busmem;
		$display("Init Monitor");
	endfunction

	function void CheckMemRead();
	//	@(posedge busmem.re) ##[1:5] busmem.we;
	//	display("Read mem good");

	endfunction

	function void CheckMemWrite();
	//	@(posedge busmem.we)
	//	@(posedge busmem.clk)

	endfunction

	function void CheckRegWrite();
	//	@(posedge ram_we)

	endfunction

	extern function void MonSW();
	extern function void MonLW();
endclass

function void Monitor::MonSW();

	CheckMemWrite();
	CheckRegWrite();

endfunction

function void Monitor::MonLW();

	CheckMemWrite();
	CheckRegWrite();

endfunction

