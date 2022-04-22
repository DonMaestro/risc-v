module alu(output reg [31:0] o_result,
           input wire [3:0]  i_control,
           input wire [31:0] i_op1, i_op2);

localparam ADD = 4'h0, SLL = 4'h1, SLT = 4'h2, SLTU = 4'h3;
localparam XOR = 4'h4, SRL = 4'h5, OR  = 4'h6, AND  = 4'h7;
localparam SUB = 4'h8, SRA = 4'hd;

always @(*)
begin
	case(i_control)
		AND : o_result = i_op1 & i_op2;
		SUB : o_result = i_op1 - i_op2;
		SLL : o_result = i_op1 << i_op2;
		SLT : o_result = ( i_op1 < i_op2) ? 32'b01 : 32'b0;
		//SLTU: o_result = ( i_op1 < i_op2) ? 32'b01 : 32'b0;
		XOR : o_result = i_op1 ^ i_op2;
		SRL : o_result = i_op1 >> i_op2;
		SRA : o_result = i_op1 >>> i_op2;
		OR  : o_result = i_op1 | i_op2;
		ADD : o_result = i_op1 + i_op2;
		default	: o_result = 32'b0;
	endcase
end

endmodule

