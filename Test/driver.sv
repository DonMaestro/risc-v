
class Driver #(parameter ADDR_WIDTH = 32);

	int i;
	rand reg [31:0] mem[0:$pow(2, ADDR_WIDTH) - 1];
	rand reg [3:0] kk;

	constraint c_mode { kk < 6; }

	virtual mem_intf #(ADDR_WIDTH) busmem;

	function new(virtual mem_intf #(ADDR_WIDTH) busmem);
		this.busmem = busmem;

		for (i = 0; i < 32; i++)
		begin
			mem[i] = $random;
		end
	endfunction
	
	function void print_mem();
		for (i = 0; i < 32; i++)
		begin
			$display("[%2d] %.8x", i, mem[i]);
		end

	endfunction

endclass

