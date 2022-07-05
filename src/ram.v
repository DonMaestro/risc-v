module ram #(parameter ADDR_WIDTH = 32)
           (output [31:0]           o_data,
            input                   i_we,
            input  [ADDR_WIDTH-1:0] i_addr,
            input  [31:0]           i_data,
            input                   i_clk);

reg [31:0] m_ram[0:2 ** ADDR_WIDTH - 1];

initial
begin
	$readmemh("ram.dat", m_ram);
end

always @(posedge i_clk)
begin
	if(i_we)
	begin 
		m_ram[i_addr >> 2] = i_data;
		$writememh("Debug/ram_result.dat", m_ram);
	end
end

assign o_data = m_ram[i_addr >> 2];

endmodule

