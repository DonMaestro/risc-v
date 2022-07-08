module decode #(parameter WIDTH_BRM = 6)
              (output     [ 6:0]      o_uop,
               output reg [14:0]      o_regs,
               output reg [ 9:0]      o_func,
               output reg [ 4:0]      o_ctrl,
               output reg [31:0]      o_imm,
               output reg             o_en_j,
               output [WIDTH_BRM-1:0] o_brmask,
               input wire             i_en_j,
               input [WIDTH_BRM-1:0]  i_brmask,
               input wire             i_en,
               input wire [31:0]      i_instr,
               input wire             i_imask);

//`include "src/IType.v"
localparam [2:0] NO = 3'd0,
                 RT = 3'd1,
                 IT = 3'd2,
                 ST = 3'd3,
                 BT = 3'd4,
                 UT = 3'd5,
                 JT = 3'd6;

reg [2:0] ImmSrc;

reg [4:0] drd, drs1, drs2;
reg [2:0] funct3;
reg [6:0] funct7;
reg [1:0] pry; // priority
wire [1:0] queue;

assign o_brmask = i_en_j ? i_brmask + { {(WIDTH_BRM-1){1'b0}}, 1'b1} : i_brmask;

assign o_uop = i_instr[6:0];

always @(i_instr[6:0], i_en, i_imask)
begin
	o_en_j = 1'b0;
	if (i_en && i_imask) begin
		case (i_instr[6:0])
			7'b1100011: o_en_j = 1;
			7'b1101111: o_en_j = 1;
			7'b1100111: o_en_j = 1;
			default:    o_en_j = 0;
		endcase
	end
end

// Instruction type decode
always @(i_instr[6:0])
begin
	casez (i_instr[6:0])
		7'b011_0011: ImmSrc = RT;

		7'b001_0011: ImmSrc = IT;
		7'b000_0011: ImmSrc = IT;
		7'b110_0111: ImmSrc = IT;
		7'b111_0011: ImmSrc = IT;

		7'b010_0011: ImmSrc = ST;
		7'b110_0011: ImmSrc = BT;
		7'b110_1111: ImmSrc = JT;
		7'b0?1_0111: ImmSrc = UT;
		default:     ImmSrc = NO;
	endcase
end

// decode imm
always @(ImmSrc, i_instr[31:7])
begin
	case (ImmSrc)
		RT: o_imm = { { 20{i_instr[31]} }, i_instr[31:25], 5'b0 };
		IT: o_imm = { { 20{i_instr[31]} }, i_instr[31:20] };
		ST: o_imm = { { 20{i_instr[31]} }, i_instr[31:25], i_instr[11:7] };
		BT: o_imm = { { 20{i_instr[31]} }, i_instr[7],
		                        i_instr[30:25], i_instr[11:8], 1'b0 };
		JT: o_imm = { { 12{i_instr[31]} }, i_instr[19:12],
		                        i_instr[20], i_instr[30:21], 1'b0 };
		UT: o_imm = { i_instr[31:12], 12'b0 };
		default: o_imm = 31'bX;
	endcase
end

type_queue m_type_queue(.o_type(queue),
                        .i_en(i_imask),
                        .i_uop(i_instr[6:0]));

always @(*)
begin
	drd  = i_instr[11:7];
	drs1 = i_instr[19:15];
	drs2 = i_instr[24:20];

	funct7 = i_instr[31:25];
	funct3 = i_instr[14:12];

	pry = 2'b0;

	case(ImmSrc)
		RT:
		begin
			o_regs = { drd, drs2, drs1 };
			o_func = { funct7, funct3 };
		end
		IT:
		begin
			o_regs = { drd, 5'b0, drs1 };
			/*
			need check SLLI SRLI SRAI	
			*/
			o_func = { 7'b0, funct3 };

			//Jump And Link Reg
			if (7'b1100111 == o_uop)
				pry = 2'b11;
		end
		ST:
		begin
			o_regs = { 5'b0, drs2, drs1 };
			o_func = { 7'b0, funct3 };
		end
		BT:
		begin
			o_regs = { 5'b0, drs2, drs1 };
			o_func = { 7'b0, funct3 };
			pry = 2'b11;
		end
		UT:
		begin
			o_regs = { drd, 5'b0, 5'b0 };
			o_func = { 7'b0, 3'b0 };
		end
		JT:
		begin
			o_regs = { drd, 5'b0, 5'b0 };
			o_func = { 7'b0, 3'b0 };
			pry = 2'b11;
		end
		default:
		begin
			o_regs = { 5'b0, 5'b0, 5'b0 };
			o_func = { 7'b0, 3'b0 };
		end
	endcase

	if (!i_imask) begin
		o_regs = { 5'b0, 5'b0, 5'b0 };
		o_func = { 7'b0, 3'b0 };
	end

	o_ctrl = { pry, queue, i_en & i_imask };

end

endmodule

module type_queue(output reg [1:0] o_type,
                  input            i_en,
                  input      [6:0] i_uop);

localparam [1:0] MEMQ = 2'b01, ALUQ = 2'b10, NONE = 2'b00;

always @(*)
begin
	if (i_en) begin
		casez (i_uop)
		7'b0?00011: o_type = MEMQ;
	//	7'b1100011: o_type =
	//	7'b1101111: o_type =
	//	7'b1100111: o_type =
		default:    o_type = ALUQ;
		endcase
	end else
		o_type = NONE;
end

endmodule

