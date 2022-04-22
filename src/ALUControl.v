module ALUControl(o_ALUControl, i_ALUOp, i_func3, i_func7_5, i_Op_5);

localparam AND = 3'b010, OR = 3'b011;
localparam ADD = 3'b000, SUB = 3'b001, SLT = 3'b101;
 
output reg [2:0] o_ALUControl;
input      [1:0] i_ALUOp;
input      [2:0] i_func3;
input            i_func7_5, i_Op_5;

always @(*)
begin 
	casez({i_ALUOp, i_func3, i_func7_5, i_Op_5})
		8'b00_???_??: o_ALUControl = ADD;
		8'b01_???_??: o_ALUControl = SUB;
		8'b10_000_0?: o_ALUControl = ADD;
		8'b10_000_?0: o_ALUControl = ADD;
		8'b10_000_11: o_ALUControl = SUB;
		8'b10_010_??: o_ALUControl = SLT;
		8'b10_110_??: o_ALUControl = OR;
		8'b10_111_??: o_ALUControl = AND;
		default     : o_ALUControl = 3'bXXX;
	endcase
end

endmodule

