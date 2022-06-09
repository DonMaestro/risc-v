`timescale 1 ns / 10 ps
`include "src/issue_slot.v"
`include "src/mux2in1.v"
`include "src/register.v"
`include "src/comparator.v"

module tb_issue_slot;

localparam WIDTH_REG = 3;
localparam WIDTH_TAG = 3;
localparam WIDTH_BRM = 2;

reg [m_slot.WIDTH_I-1:0] data;
reg [4*WIDTH_REG-1:0]    wdest;
reg [WIDTH_REG-1:0]      pr1, pr2, prd;
reg [4-1:0]              brkill;
reg grant, we, rst, clk;


wire [m_slot.WIDTH_O-1:0] rdata;
wire [m_slot.WIDTH_I-1:0] shiftdata;
wire request;

issue_slot m_slot(.o_request(request),
                  .o_priority(),
                  .o_rslot(rdata),
                  .o_data(shiftdata),
                  .i_data(data),
                  .i_WDest4x(wdest),
                  .i_brkill(brkill),
                  .i_grant(grant),
                  .i_en(we),
                  .i_rst_n(rst),
                  .i_clk(clk));

defparam m_slot.WIDTH_REG = WIDTH_REG;
defparam m_slot.WIDTH_TAG = WIDTH_TAG;
defparam m_slot.WIDTH_BRM = WIDTH_BRM;
defparam m_slot.WIDTH_PRY = 1;
defparam m_slot.TAG_BANK  = 2'b01;

always @(request) grant = request;

initial
begin
	we  = 1'b1;
	brkill = 4'b0000;

	wdest = { 3'b000, 3'b000, 3'b000, 3'b001 };
	prd = 3'b111;
	pr2 = 3'b011;
	pr1 = 3'b001;
     // data = { BrMask, tag, RDst, RS2, RS1, PRY, val, p2, p1 }
	data = { 2'b01, 3'b010, prd, pr2, pr1, 1'b0, 3'b110 };

	#40
	we  = 1'b0;

	#40
	we  = 1'b0;

	#40
	we  = 1'b1;

	wdest = { 3'b000, 3'b000, 3'b000, 3'b001 };
	prd = 3'b111;
	pr2 = 3'b011;
	pr1 = 3'b001;
     // data = { BrMask, tag, RDst, RS2, RS1, PRY, val, p2, p1 }
	data = { 2'b01, 3'b010, prd, pr2, pr1, 1'b0, 3'b110 };

	#40
	brkill = 4'b0111;
	we  = 1'b0;

end

initial
begin
	rst <= #0 1'b1;
	rst <= #1 1'b0;
	rst <= #2 1'b1;

	clk = 1'b0;
	forever #20 clk = ~clk;
end

initial
begin
	$dumpfile("Debug/issue_slot.vcd");
	$dumpvars;

	#500 $finish;
end
endmodule
