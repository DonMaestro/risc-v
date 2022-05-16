module decode(output reg [14:0] o_regs,
              output reg [ 9:0] o_func,
              output reg [ 4:0] o_ctrl,
              output     [31:0] o_imm,
              input wire [31:0] i_instr,
              input wire        i_imask);

localparam [2:0] RT = 3'd0,
                 IT = 3'd1,
                 ST = 3'd2,
                 BT = 3'd3,
                 UT = 3'd4,
                 JT = 3'd5;

wire [2:0] ImmSrc;

reg [4:0] drd, drs1, drs2;
reg [2:0] funct3;
reg [6:0] funct7;

InstrDecoder m_decod(.o_ImmSrc(ImmSrc),
                     .i_Op(i_instr[6:0]));

signExtend mod_signEntend(.o_data(o_imm),
                          .i_en(ImmSrc),
                          .i_data(i_instr[31:7]));

always @(*)
begin
	drd  = i_instr[11:7];
	drs1 = i_instr[19:15];
	drs2 = i_instr[24:20];

	funct7 = i_instr[31:25];
	funct3 = i_instr[14:12];

	o_ctrl = 5'b11;

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
		end
	endcase
end

endmodule

