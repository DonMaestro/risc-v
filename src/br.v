module br #(parameter WIDTH_BRM = 4)
          (output reg [WIDTH_BRM-1:0] o_killbr,
           input wire [3:0]           i_control,
           input wire [WIDTH_BRM-1:0] i_brmask,
           input wire [31:0]          i_op1, i_op2);

localparam BEQ = 4'h0, BNE = 4'h1;
localparam BLT = 4'h4, BGE = 4'h5, BLTU = 4'h6, BGEU = 4'h7;

always @(*)
begin
	case(i_control)
		BEQ : o_killbr = (i_op1 == i_op2) ? i_brmask + 1 : i_brmask + 2;
		BNE : o_killbr = (i_op1 != i_op2) ? i_brmask + 1 : i_brmask + 2; 
		BLT : o_killbr = (i_op1 <  i_op2) ? i_brmask + 1 : i_brmask + 2; 
		BGE : o_killbr = (i_op1 >= i_op2) ? i_brmask + 1 : i_brmask + 2; 
		BLTU: o_killbr = (i_op1 <  i_op2) ? i_brmask + 1 : i_brmask + 2; 
		BGEU: o_killbr = (i_op1 >= i_op2) ? i_brmask + 1 : i_brmask + 2; 
		default	: o_killbr = { WIDTH_BRM{1'bX} };
	endcase
end

endmodule

