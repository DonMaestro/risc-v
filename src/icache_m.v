
module icache_m #(parameter WIDTH = 5)
                (output [4*32-1:0]  o_data,
                 input  [WIDTH-1:0] i_addr);

localparam SIZE = $pow(2, WIDTH);

reg [31:0] data[0:SIZE-1];

wire [WIDTH-1:0] addr = i_addr & { {(WIDTH-2){1'b1}}, 2'b0 };

initial
begin
	$readmemh("rom.dat", data);
end

assign o_data = data[addr];

endmodule

