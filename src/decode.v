module decode(output reg [ 4:0] o_drd,
              output reg [ 2:0] o_funct3,
              output reg [ 4:0] o_drs1,
              output reg [ 4:0] o_drs2,
              output reg [ 6:0] o_funct7,
              output     [19:0] o_imm,
              input wire [31:0] i_instr);

localparam [2:0] RT = 3'd0,
                 IT = 3'd1,
                 ST = 3'd2,
                 BT = 3'd3,
                 UT = 3'd4,
                 JT = 3'd5;

wire [2:0] ImmSrc;

InstrDecoder m_decod(.o_ImmSrc(ImmSrc),
                     .i_Op(i_instr[6:0]));

signExtend mod_signEntend(.o_data(o_imm),
                          .i_en(ImmSrc),
                          .i_data(Instr[31:7]));

always @(*)
begin
	o_drd = i_instr[11:7];
	o_funct3 = i_instr[14:12];
	o_drs1 = i_instr[19:15];
	o_drs2 = i_instr[24:20];
	o_funct7 = 7'b0;
	case(ImmSrc)
		RT: o_funct7 = i_instr[31:25];
		IT: o_drs2 = 5'b0;
		ST: o_drd = 5'b0;
		BT: o_drd = 5'b0;
		UT: begin
			o_funct3 = 3'b0;
			o_drd    = 5'b0;
			o_drs1   = 5'b0;
			o_drs2   = 5'b0;
		end
		JT: begin
			o_funct3 = 3'b0;
			o_drs1   = 5'b0;
			o_drs2   = 5'b0;
		end
end

endmodule

