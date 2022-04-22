`timescale 1 ns / 10 ps
`include "src/issue_slot.v"

module tb_issue_slot;

localparam WIDTH_REG = 3;
localparam WIDTH_TAG = 3;
localparam WIDTH_BRM = 3;
localparam WIDTH = 7 + WIDTH_BRM + WIDTH_TAG + 3*WIDTH_REG + 3;

reg [WIDTH-1:0]       data;
reg [4*WIDTH_REG-1:0] wdest;
reg [WIDTH_REG-1:0]   pr1, pr2, prd;
reg [WIDTH_BRM-1:0]   brkill;
reg grant, we, rst, clk;


wire [WIDTH-1:0] rdata;
wire [WIDTH-1:0] shiftdata;
wire request;

issue_slot m_slot(.o_request(request),
                  .o_rslot(rdata),
                  .o_data(shiftdata),
                  .i_data(data),
                  .i_WDest4x(wdest),
                  .i_BrKill(brkill),
                  .i_grant(grant),
                  .i_en(we),
                  .i_rst_n(rst),
                  .i_clk(clk));

defparam m_slot.WIDTH_REG = WIDTH_REG;
defparam m_slot.WIDTH_TAG = WIDTH_TAG;
defparam m_slot.WIDTH_BRM = WIDTH_BRM;

initial
begin
	rst <= #0 1'b1;
	rst <= #1 1'b0;
	rst <= #2 1'b1;

	wdest = { 3'b110, 3'b110, 3'b110, 3'b110 };
	prd = 3'b001;
	pr2 = 3'b011;
	pr1 = 3'b001;
	we  = 1'b1;
	grant = 1'b0;
	brkill = 3'b010;
	data = { 7'h14, 3'b101, 3'b010, prd, pr2, pr1, 3'b100 };

	#40
	wdest = { 3'b110, 3'b110, 3'b110, 3'b001 };
	we = 1'b0;
	grant = 1'b0;

	#40
	wdest = { 3'b110, 3'b110, 3'b011, 3'b000 };
	we = 1'b0;
	grant = 1'b0;

	#40
	wdest = { 3'b110, 3'b110, 3'b000, 3'b000 };
	we = 1'b0;
	grant = 1'b1;

	#80
	data = { 7'h14, 3'b101, 3'b010, prd, pr2, pr1, 3'b111 };
	we = 1'b1;
	grant = 1'b0;

	#40
	brkill = 3'b101;
end

initial
begin
	clk = 1'b0;
	forever #20 clk = ~clk;
end

initial
begin
	$dumpfile("Debug/issue_slot.vcd");
	$dumpvars;

	#1000 $finish;
end
endmodule
