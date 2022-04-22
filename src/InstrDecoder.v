module InstrDecoder(output reg [2:0] o_ImmSrc,
                    input      [6:0] i_Op);

localparam [2:0] RT = 3'd0,
                 IT = 3'd1,
                 ST = 3'd2,
                 BT = 3'd3,
                 UT = 3'd4,
                 JT = 3'd5;

always @(*)
begin
	casez (i_Op)
		7'b00?_0011: o_ImmSrc = IT;
		7'b010_0011: o_ImmSrc = ST;
		7'b110_0011: o_ImmSrc = BT;
		7'b110_1111: o_ImmSrc = JT;
		7'b0?1_0111: o_ImmSrc = UT;
	endcase
end

endmodule

