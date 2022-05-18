`timescale 1 ns / 1 ns
`include "src/register.v"
`include "src/decode.v"
`include "src/InstrDecoder.v"
`include "src/signExtend.v"

module tb_decode;

localparam WIDTH_BRM = 3;
reg rst_n, clk;

reg [31:0] Instr;
reg        Imask;
reg        en;

wire [14:0] regs;
wire [31:0] dimm;
wire [9:0] func;
wire [4:0] ctrl;

wire [WIDTH_BRM-1:0] o_brmask, brmask;
wire                 o_en_bm,  en_bm;

wire [4:0] drd, drs1, drs2;

assign { drd, drs2, drs1 } = regs;

register #(1) r_en_j(en_bm, 1'b1, o_en_bm, rst_n, clk);
register      r_brmask(brmask, 1'b1, o_brmask, rst_n, clk);
defparam r_brmask.WIDTH = WIDTH_BRM;

decode m_decode(.o_regs  (regs),
                .o_func  (func),
                .o_ctrl  (ctrl),
                .o_imm   (dimm),
                .o_en_j  (o_en_bm),
                .o_brmask(o_brmask),
                .i_en_j  (en_bm),
                .i_brmask(brmask),
                .i_en    (en),
                .i_instr (Instr),
                .i_imask (Imask));
defparam m_decode.WIDTH_BRM = WIDTH_BRM;

initial
begin
	en    = 1;
	Imask = 1;
	Instr = 32'h00002137;
	$display("lui     sp,0x2");

	#40
	Imask = 1;
	Instr = 32'h044000ef;
	$display("jal     ra,48 <main>");

	#40
	Imask = 1;
	Instr = 32'hfe010113;
	$display("addi    sp,sp,-32");
	
	#40
	Imask = 1;
	Instr = 32'h00812e23;
	$display("sw      s0,28(sp)");
	
	#40
	en    = 1;
	Imask = 0;
	Instr = 32'h00812e23;
	$display("sw      s0,28(sp)");
	
	#40
	en    = 0;
	Imask = 1;
	Instr = 32'h00812e23;
	$display("sw      s0,28(sp)");
	
	#40
	en    = 0;
	Imask = 0;
	Instr = 32'h00812e23;
	$display("sw      s0,28(sp)");
	
end
	  
initial
begin
	rst_n = 0;
	clk = 0;
	rst_n <= #10 1;
	forever #20 clk = ~clk;
end

initial
begin
	$dumpfile("Debug/decode.vcd");
	$dumpvars;

	#1000 $finish;
end

endmodule

