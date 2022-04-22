module encoder4in2(output reg [4:0] o_addr,
                   input      [1:0] i_d);

always @(i_d)
begin
	casex (i_d)
		4'b0001: o_addr = 2'b00;
		4'b001x: o_addr = 2'b01;
		4'b01xx: o_addr = 2'b10;
		4'b1xxx: o_addr = 2'b11;
	endcase

end

endmodule

