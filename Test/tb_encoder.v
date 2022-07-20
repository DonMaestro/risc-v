`timescale 1 ns / 10 ps
`include "src/encoder.v"

module tb_encoder;

parameter SIZE = 32;
parameter WIDTH = 5;
wire [WIDTH-1:0] q;
reg  [SIZE-1 :0] d;
reg              en;

/* Core */
encoder m_encoder(.o_q (q),
                  .i_en(en),
                  .i_d (d));
defparam m_encoder.WIDTH = WIDTH;
defparam m_encoder.SIZE  = SIZE;

initial begin
	d  = 32'b0;
	en = 1'b1;
	#10 d = 32'b00010;
	#10 d = 32'b01000;
	#10 d = 32'b00100;
	#10 $finish;
end

initial
begin
        $dumpfile ("Debug/encoder.vcd");
        $dumpvars;
end

endmodule 

