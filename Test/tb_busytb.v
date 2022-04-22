`timescale 1 ns / 10 ps
`include "src/busytb.v"

module tb_busytb;

localparam WIDTH = 7;

reg [WIDTH-1:0] set1, set2, set3, set4;
reg [WIDTH-1:0] rst1, rst2, rst3, rst4;
reg [WIDTH-1:0] addr1, addr2, addr3, addr4, addr5, addr6, addr7, addr8;
reg rst_n, clk;

wire [4*WIDTH-1:0] set4x, rst4x;
wire [2-1:0]       data2x[0:3];

assign set4x = { set4, set3, set2, set1 };
assign rst4x = { rst4, rst3, rst2, rst1 };

busytb #(WIDTH) m_busytb(.o_data1(data2x[0]),
                         .o_data2(data2x[1]),
                         .o_data3(data2x[2]),
                         .o_data4(data2x[3]),
                         .i_addr1({ addr2, addr1 }),
                         .i_addr2({ addr4, addr3 }),
                         .i_addr3({ addr6, addr5 }),
                         .i_addr4({ addr8, addr7 }),
                         .i_setAddr4x(set4x),
                         .i_rstAddr4x(rst4x),
                         .i_rst_n(rst_n),
                         .i_clk(clk));

initial
begin
	rst_n <= #0 1'b1;
	rst_n <= #1 1'b0;
	rst_n <= #2 1'b1;

	set1 = 7'b000_0000;
	set2 = 7'b000_0000;
	set3 = 7'b000_0000;
	set4 = 7'b000_0000;
	rst1 = 7'b000_0000;
	rst2 = 7'b000_0000;
	rst3 = 7'b000_0000;
	rst4 = 7'b000_0000;

	addr1 = 7'b000_1111;
	addr2 = 7'b000_1111;
	addr3 = 7'b001_1111;
	addr4 = 7'b010_1111;
	addr5 = 7'b011_1111;
	addr6 = 7'b100_1111;
	addr7 = 7'b111_1111;
	addr8 = 7'b111_1111;

	@(posedge clk)

	set1 = 7'b001_1111;
	set2 = 7'b010_1111;
	set3 = 7'b011_1111;
	set4 = 7'b100_1111;

	@(posedge clk)

	rst1 = 7'b001_1111;
	rst2 = 7'b010_1111;
	rst3 = 7'b011_1111;
	rst4 = 7'b100_1111;
end

initial
begin
	clk = 1'b0;
	forever #20 clk = ~clk;
end

initial
begin
	$dumpfile("Debug/busytb.vcd");
	$dumpvars;

	#1000 $finish;
end
endmodule
