`timescale 1 ns / 10 ps
module tb_core();
localparam WIDTH = 12;

wire [WIDTH - 1:0] addr;
wire [31:0] data_mem_core, data_core_mem;
wire we;
reg	clk;
reg	rst_n;

/* Core */
core #(WIDTH) m_core(.o_we(we),
            .o_addr(addr),
            .o_data(data_core_mem),
            .i_data(data_mem_core),
            .rst_n(rst_n),
	    .clk(clk));

/* MEM */
ram #(WIDTH) m_ram(.o_data(data_mem_core),
          .i_we(we), 
          .i_addr(addr), 
          .i_data(data_core_mem), 
          .i_clk(clk));

initial begin
	rst_n = 1;
	#10 rst_n = 0;
	#10 rst_n = 1;
end

initial begin
	clk = 1;
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
