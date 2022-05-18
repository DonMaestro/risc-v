module InstrDecoder(output reg [2:0] o_ImmSrc,
                    input      [6:0] i_Op);

`include "src/IType.v"

always @(*)
begin
	casez (i_Op)
		7'b001_0011: o_ImmSrc = IT;
		7'b000_0011: o_ImmSrc = IT;
		7'b110_0111: o_ImmSrc = IT;
		7'b111_0011: o_ImmSrc = IT;

		7'b010_0011: o_ImmSrc = ST;
		7'b110_0011: o_ImmSrc = BT;
		7'b110_1111: o_ImmSrc = JT;
		7'b0?1_0111: o_ImmSrc = UT;
	endcase
end

endmodule

