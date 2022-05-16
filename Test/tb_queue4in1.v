`timescale 1 ns / 10 ps
`include "src/queue4in1.v"
`include "src/queue_arbiter.v"
`include "src/issue_slot.v"
`include "src/mux2in1.v"
`include "src/register.v"
`include "src/comparator.v"


module tb_queue4in1;

localparam WIDTH_REG = 3;
localparam WIDTH_TAG = 3;
localparam WIDTH_BRM = 3;
localparam WIDTH = 7 + WIDTH_BRM + WIDTH_TAG + 3*WIDTH_REG + 3;

integer i;

reg [WIDTH-1:0]       instr[0:3];
reg [4*WIDTH_REG-1:0] wdest4x;
reg [WIDTH_BRM-1:0]   brkill;
reg we, rst, clk;


wire [WIDTH-1:0] instr_return;
wire             instr_ready;

wire [WIDTH-1:0] instruction1, instruction2, instruction3, instruction4;

assign instruction1 = instr[0];
assign instruction2 = instr[1];
assign instruction3 = instr[2];
assign instruction4 = instr[3];

queue4in1 m_queue(.o_inst1(instr_return),
                  .o_ready(instr_ready),
	          .i_inst1(instr[0]),
	          .i_inst2(instr[1]),
	          .i_inst3(instr[2]),
	          .i_inst4(instr[3]),
                  .i_wdest4x(wdest4x),
                  .i_BrKill(brkill),
                  .i_en(we),
                  .i_rst_n(rst),
                  .i_clk(clk));
defparam m_queue.WIDTH_REG = WIDTH_REG;
defparam m_queue.WIDTH_TAG = WIDTH_TAG;
defparam m_queue.WIDTH_BRM = WIDTH_BRM;

initial
begin
	rst <= #0 1'b1;
	rst <= #1 1'b0;
	rst <= #2 1'b1;

	wdest4x = { 3'b110, 3'b110, 3'b110, 3'b110 };
	we  = 1'b1;
	brkill = 3'b010;

	$display("UOP, BrM, Tag, prd, pr2, pr1, val, p2, p1");
	for (i = 0; i < 4; i = i + 1) begin
		instr[i] = rand_instr(1);
		//wdest[i] = instr[i][];
		printInstr(instr[i]);
	end
	$write("\n");

	@(posedge clk)
	for (i = 0; i < 4; i = i + 1) begin
		instr[i] = rand_instr(1);
		printInstr(instr[i]);
	end
	$display("\n");

	@(posedge clk)
	we  = 1'b0;
end

initial
begin
	clk = 1'b0;
	forever #20 clk = ~clk;
end

initial
begin
	$dumpfile("Debug/queue4in1.vcd");
	$dumpvars;

	#1000 $finish;
end

always @(posedge clk)
begin
	if (instr_ready) begin
		$write("return");
		printInstr({instr_return, 3'b0});
	end
end

task printInstr(input [WIDTH-1:0] instruction);
	reg [6:0] UOP;
	reg [WIDTH_BRM-1:0] BrM;
	reg [WIDTH_TAG-1:0] Tag;
	reg [WIDTH_REG-1:0] prd, pr2, pr1; 
	reg val, p2, p1;

	begin
		{ UOP, BrM, Tag, prd, pr2, pr1, val, p2, p1 } = instruction;
		$display("'%h' %h [%h] [%h %h %h] [%b%b%b]", UOP, BrM,
			 Tag, prd, pr2, pr1, val, p2, p1);
        
	end
endtask

function [WIDTH-1:0] rand_instr(input gg);
	begin
		rand_instr = $random;
		rand_instr[2] = 1'b1;
	end
endfunction

endmodule
