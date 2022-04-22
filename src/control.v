//`include "src/InstrDecoder.v"
module control(output           o_PCWrite,
               output reg       o_AdrSrc,
               output reg       o_MemWrite,
               output reg       o_IRWrite,
               output reg [1:0] o_ResultSrc,
               output     [2:0] o_ALUControl,
               output reg [1:0] o_ALUSrcA,
               output reg [1:0] o_ALUSrcB,
               output     [2:0] o_ImmSrc,
               output reg       o_RegWrite,
               input      [6:0] i_Op,
               input      [2:0] i_func3,
               input            i_func7_5,
               input            i_Zero,
               input            i_rst_n,
               input            i_clk);


localparam [3:0] FETCH = 4'd0,
                 DECODE = 4'd1,
                 MEMADR = 4'd2,
                 EXECUTE_R = 4'd3,
                 EXECUTE_I = 4'd4,
                 EXECUTE_U = 4'd5,
                 JAL = 4'd6,
                 BEQ = 4'd7,
                 MEMREAD = 4'd8,
                 MEMWRITE = 4'd9,
                 ALUWB = 4'd10,
                 MEMWB = 4'd11;

// R-type 
// I-type 
// J-type 

reg [3:0] state;
reg [1:0] ALUOp;
reg       PCUpdate, Branch;

assign o_PCWrite = ( Branch & i_Zero ) | PCUpdate;

always @(posedge i_clk, negedge i_rst_n)
begin
	if (!i_rst_n)
		state <= FETCH;
	else
	begin
		case (state)
			FETCH:     state <= DECODE;
			DECODE:    state <= DecodeTo(i_Op);
			MEMADR:    state <= MemAdrTo(i_Op);
			EXECUTE_R: state <= ALUWB;
			EXECUTE_I: state <= ExecuteITo(i_Op);
			EXECUTE_U: state <= ALUWB;
			JAL:       state <= ALUWB;
			BEQ:       state <= FETCH;
			MEMREAD:   state <= MEMWB;
			MEMWRITE:  state <= FETCH;
			ALUWB:     state <= FETCH;
			MEMWB:     state <= FETCH;
		endcase
	end
end

function [3:0] DecodeTo(input [6:0] i_Op);
	casez (i_Op)
		7'b0?0_0011: DecodeTo = MEMADR;
		7'b011_0111: DecodeTo = ALUWB;     // LUI
		7'b011_0011: DecodeTo = EXECUTE_R;
		7'b001_0011: DecodeTo = EXECUTE_I;
		7'b110_0111: DecodeTo = EXECUTE_I; // JALR
		7'b110_1111: DecodeTo = JAL;
		7'b110_0011: DecodeTo = BEQ;
	endcase
	//$display("%d", DecodeTo);
endfunction

function [3:0] MemAdrTo(input [6:0] i_Op);
	case (i_Op)
		7'b0000011: MemAdrTo = MEMREAD;
		7'b0100011: MemAdrTo = MEMWRITE;
	endcase
endfunction

function [3:0] ExecuteITo(input [6:0] i_Op);
	case (i_Op)
		7'b0010011: ExecuteITo = ALUWB;
		7'b1100111: ExecuteITo = JAL;
	endcase
endfunction

always @(state)
begin
	o_IRWrite  = 1'b0;
	o_MemWrite = 1'b0;
	Branch     = 1'b0;
	PCUpdate   = 1'b0;
	o_RegWrite = 1'b0;
	case (state)
		FETCH:
		begin
			o_AdrSrc  <= 1'b0;
			o_IRWrite <= 1'b1;
			o_ALUSrcA <= 2'b00;
			o_ALUSrcB <= 2'b10;
			ALUOp     <= 2'b00;
			o_ResultSrc <= 2'b10;
			PCUpdate  <= 1'b1;
		end
		DECODE:
		begin
			o_ALUSrcA <= 2'b01;
			o_ALUSrcB <= 2'b01;
			ALUOp     <= 2'b00;
		end
		MEMADR:
		begin
			o_ALUSrcA <= 2'b10;
			o_ALUSrcB <= 2'b01;
			ALUOp     <= 2'b00;
		end
		EXECUTE_R:
		begin
			o_ALUSrcA <= 2'b10;
			o_ALUSrcB <= 2'b00;
			ALUOp     <= 2'b10;
		end
		EXECUTE_I:
		begin
			o_ALUSrcA <= 2'b10;
			o_ALUSrcB <= 2'b01;
			ALUOp     <= 2'b10;
		end
		EXECUTE_U:
		begin
			o_ALUSrcA <= 2'b00;
			o_ALUSrcB <= 2'b01;
			ALUOp     <= 2'b10;
		end
		JAL:
		begin
			o_ALUSrcA <= 2'b01;
			o_ALUSrcB <= 2'b10;
			ALUOp     <= 2'b00;
			o_ResultSrc <= 2'b00;
			PCUpdate  <= 1'b1;
		end
		BEQ:
		begin
			o_ALUSrcA <= 2'b10;
			o_ALUSrcB <= 2'b00;
			ALUOp     <= 2'b01;
			o_ResultSrc <= 2'b00;
			Branch    <= 1'b1;
		end
		MEMREAD:
		begin
			o_ResultSrc <= 2'b00;
			o_AdrSrc    <= 1'b1;
		end
		MEMWRITE:
		begin
			o_ResultSrc <= 2'b00;
			o_AdrSrc    <= 1'b1;
			o_MemWrite  <= 1'b1;
		end
		ALUWB:
		begin
			o_ResultSrc <= 2'b00;
			o_RegWrite  <= 1'b1;
		end
		MEMWB:
		begin
			o_ResultSrc <= 2'b01;
			o_RegWrite  <= 1'b1;
		end
	endcase
end

ALUControl mod_ALUControl(.o_ALUControl(o_ALUControl),
                          .i_ALUOp(ALUOp),
                          .i_func3(i_func3),
                          .i_func7_5(i_func7_5),
                          .i_Op_5(i_Op[5]));

InstrDecoder mod_InstrDecoder(o_ImmSrc, i_Op);

endmodule
