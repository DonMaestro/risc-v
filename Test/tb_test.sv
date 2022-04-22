`timescale 1 ns / 10 ps
module tb_test;
`include "Test/test.sv"

localparam WIDTH = 12;

reg clk;
reg [31:0] register[0:31];
int i;

mem_intf #(WIDTH) busram(clk);

test #(WIDTH) tt;

/* Core */
core #(WIDTH) m_core(.o_data(busram.data_core_mem),
                     .o_addr(busram.addr),
                     .o_we  (busram.we),
                     .i_data(busram.data_mem_core),
                     .rst_n (busram.rst_n),
                     .clk   (busram.clk));

assign busram.re = m_core.w_IRWrite;

always @(*)
begin
	for (i = 0; i < 32; i++)
	begin
		register[i] <= m_core.mod_regFile.register[i];
	end
end

initial
begin
	tt = new(busram);
	#10 busram.rst_n = 1'b1;
	tt.test_all();

        $finish;
end

initial
begin
	clk = 1;
	forever #20 clk = ~clk;
end

initial
begin
        $dumpfile ("Debug/core.vcd");
        $dumpvars;
end

endmodule

