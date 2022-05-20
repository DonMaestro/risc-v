module regfile4in8 #(WIDTH = 5)
                   (output [31:0]      o_rdata0, o_rdata1, o_rdata2, o_rdata3,
                    output [31:0]      o_rdata4, o_rdata5, o_rdata6, o_rdata7,
                    input  [WIDTH-1:0] i_raddr0, i_raddr1, i_raddr2, i_raddr3,
                    input  [WIDTH-1:0] i_raddr4, i_raddr5, i_raddr6, i_raddr7,
                    input              i_we0,    i_we1,    i_we2,    i_we3,
                    input  [WIDTH-1:0] i_waddr0, i_waddr1, i_waddr2, i_waddr3,
                    input  [31:0]      i_wdata0, i_wdata1, i_wdata2, i_wdata3,           
                    input              i_clk);
               

reg  [31:0] register[1:31];

/* read */

assign o_rdata0 = (!i_raddr0) ? 32'b0 : register[i_raddr0];
assign o_rdata1 = (!i_raddr1) ? 32'b0 : register[i_raddr1];

assign o_rdata2 = (!i_raddr2) ? 32'b0 : register[i_raddr2];
assign o_rdata3 = (!i_raddr3) ? 32'b0 : register[i_raddr3];

assign o_rdata4 = (!i_raddr4) ? 32'b0 : register[i_raddr4];
assign o_rdata5 = (!i_raddr5) ? 32'b0 : register[i_raddr5];

assign o_rdata6 = (!i_raddr6) ? 32'b0 : register[i_raddr6];
assign o_rdata7 = (!i_raddr7) ? 32'b0 : register[i_raddr7];

/* write */

always @(posedge i_clk)
begin
	if (i_we0)
		register[i_waddr0] <= i_wdata0;
	if (i_we1)
		register[i_waddr1] <= i_wdata1;
	if (i_we2)
		register[i_waddr2] <= i_wdata2;
	if (i_we3)
		register[i_waddr3] <= i_wdata3;
	if (i_we0 || i_we1 || i_we2 || i_we3)
		$writememh("Debug/regiser_result.dat", register);
end

endmodule

