`timescale 1 ns / 1 ns 

`include "Test/interface.sv"
`include "Test/intf_queue.sv"

`include "src/core.v"
`include "src/sreg.v"
`include "src/icache_m.v"

`include "src/decode.v"
`include "src/InstrDecoder.v"
`include "src/signExtend.v"

`include "src/freelist.v"
`include "src/rename.v"

`include "src/rob.v"
`include "src/ringbuf.v"
`include "src/encoder.v"

`include "src/busytb.v"

`include "src/queue4in1.v"
`include "src/queue4in2.v"
`include "src/issue_slot.v"
`include "src/queue_arbiter.v"
`include "src/regfile4in8.v"
`include "src/imm4.v"

`include "src/bypass.v"
`include "src/demux1to4.v"

`include "src/MemCalc_m.v"

`include "src/executeALU.v"
`include "src/alu.v"
`include "src/mux3in1.v"

`include "src/executeBR.v"
`include "src/br.v"

module tb_core;
localparam WIDTH = 12;

wire [WIDTH-1:0] addrD, addrI;
wire [31:0] data_dcache, data_icache;
wire [31:0] data_core_mem;
wire we;
reg clk, rst_n;

/* Core */
core #(WIDTH) m_core(.o_we(we),
                     .o_DcacheAddr(addrD),
                     .o_IcacheAddr(addrI),
                     .o_data(data_core_mem),
                     .i_DcacheData(data_dcache),
                     .i_IcacheData(data_icache),
                     .i_rst_n(rst_n),
                     .i_clk(clk));

`define ROB m_core.m_rob
`include "Test/printROB.sv"

`define QUE1 m_core.m_issue_mem
`define QUE2 m_core.m_issue_alu
`include "Test/printQUE.sv"

always @(posedge clk)
begin
	$display("time: %d", $realtime);
	printROB(rb, pc);
	$display("queue MEM");
	printQUE1(qi1);
	$display("queue ALU");
	printQUE2(qi2);
	$display;
end
initial begin
end

initial begin
	rst_n = 0;
	clk = 1;
	rst_n <= #1 1;
	forever #20 clk = ~clk;
end

initial
begin
        # 10000 $finish;
end

initial
begin
        $dumpfile ("Debug/core.vcd");
        $dumpvars;
end

endmodule 
