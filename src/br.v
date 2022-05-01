module br(output reg        o_result,
          input wire [2:0]  i_control,
          input wire [31:0] i_op1, i_op2);

localparam BEQ = 3'h0, BNE = 3'h1;
localparam BLT = 3'h4, BGE = 3'h5, BLTU = 3'h6, BGEU = 3'h7;

always @(*)
begin
	case(i_control)
		BEQ : o_result = (i_op1 == i_op2) ? 1'b1 : 1'b0;
		BNE : o_result = (i_op1 != i_op2) ? 1'b1 : 1'b0; 
		BLT : o_result = (i_op1 <  i_op2) ? 1'b1 : 1'b0; 
		BGE : o_result = (i_op1 >= i_op2) ? 1'b1 : 1'b0; 
		BLTU: o_result = (i_op1 <  i_op2) ? 1'b1 : 1'b0; 
		BGEU: o_result = (i_op1 >= i_op2) ? 1'b1 : 1'b0; 
		default	: o_result = 1'bX;
	endcase
end

endmodule

