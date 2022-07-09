module imm4 #(parameter WIDTH_ADDR = 5, WIDTH = 32)
            (output [WIDTH-1:0]      o_rdata0, o_rdata1,
             output [WIDTH-1:0]      o_rdata2, o_rdata3,
             input  [WIDTH_ADDR-1:0] i_raddr0, i_raddr1,
             input  [WIDTH_ADDR-1:0] i_raddr2, i_raddr3,
             input                   i_we,
             input  [(2 ** WIDTH_ADDR)/4-1:0]  i_waddr,
             input  [WIDTH-1:0]      i_wdata0, i_wdata1,
             input  [WIDTH-1:0]      i_wdata2, i_wdata3,
             input  i_clk);

localparam SIZE = 2 ** WIDTH_ADDR;
integer i;

reg [WIDTH-1:0] data[0:SIZE-1];

assign o_rdata0 = data[i_raddr0];
assign o_rdata1 = data[i_raddr1];
assign o_rdata2 = data[i_raddr2];
assign o_rdata3 = data[i_raddr3];

always @(posedge i_clk)
begin
	for (i = 0; i < SIZE; i = i + 4) begin
		if (i_we & i_waddr[i[SIZE/4-1:2]]) begin
			data[i+0] <= i_wdata0;
			data[i+1] <= i_wdata1;
			data[i+2] <= i_wdata2;
			data[i+3] <= i_wdata3;
		end
	end
end

endmodule

