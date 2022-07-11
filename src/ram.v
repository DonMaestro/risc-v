module ram #(parameter WIDTH_ADDR = 8,
                       WIDTH_DATA = 8,
                       SIZE = 2 ** WIDTH_ADDR)
           (output [WIDTH_DATA-1:0] o_data,
            input                   i_we,
            input  [WIDTH_ADDR-1:0] i_addr,
            input  [WIDTH_DATA-1:0] i_data,
            input                   i_clk);

reg [WIDTH_DATA-1:0] m_ram[0:SIZE-1];

always @(posedge i_clk)
begin
	if (i_we)
		m_ram[i_addr] <= i_data;
end

assign o_data = m_ram[i_addr];

endmodule

