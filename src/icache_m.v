
module icache_m #(parameter WIDTH = 5)
                (output [4*32-1:0]  o_data,
                 input  [WIDTH-1:0] i_addr);

localparam SIZE = $pow(2, WIDTH);

reg [31:0] data[0:SIZE-1];

reg [WIDTH-1:0] addr;

always @(i_addr)
begin
	addr = i_addr >> 2;
	addr[1:0] = 2'b0;
end

initial
begin
	$readmemh("rom.dat", data);
end

assign o_data = { data[addr+3], data[addr+2], data[addr+1], data[addr] };

endmodule

