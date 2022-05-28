// i_regFileX = { RS2, RS1 };
// instr = { CTRL, BRMASK, UOPCode, PC, IMM, RD, RS2, RS1 }
// CTRL = { ENMOD, FUNC }
module bypass #(parameter WIDTH_REG = 5)
              (output [2*32-1:0]         o_data0, o_data1, o_data2, o_data3,
               input  [2*WIDTH_REG-1:0]  i_irs0, i_irs1, i_irs2, i_irs3,
               input  [2*32-1:0]         i_regFile0, i_regFile1, i_regFile2, i_regFile3,
               input  [32+WIDTH_REG:0]   i_bypass0, i_bypass1, i_bypass2, i_bypass3,
               input  [32+WIDTH_REG:0]   i_bypass4, i_bypass5, i_bypass6);

integer i, j;

wire [WIDTH_REG-1:0] rs[0:7];

wire [32-1:0]        freg[0:7];

wire                 val[0:6];
wire [WIDTH_REG-1:0] brs[0:6];
wire [32-1:0]        breg[0:6];

reg [32-1:0] rg[0:7];

assign { rs[1], rs[0] } = i_irs0;
assign { rs[3], rs[2] } = i_irs1;
assign { rs[5], rs[4] } = i_irs2;
assign { rs[7], rs[6] } = i_irs3;

assign { freg[1], freg[0] } = i_regFile0;
assign { freg[3], freg[2] } = i_regFile1;
assign { freg[5], freg[4] } = i_regFile2;
assign { freg[7], freg[6] } = i_regFile3;

assign { val[0], brs[0], breg[0] } = i_bypass0;
assign { val[1], brs[1], breg[1] } = i_bypass1;
assign { val[2], brs[2], breg[2] } = i_bypass2;
assign { val[3], brs[3], breg[3] } = i_bypass3;

assign { val[4], brs[4], breg[4] } = i_bypass4;
assign { val[5], brs[5], breg[5] } = i_bypass5;
assign { val[6], brs[6], breg[6] } = i_bypass6;

always @(*)
begin
	for (i = 0; i < 8; i = i + 1) begin
		rg[i] = freg[i];
		for (j = 0; j < 7; j = j + 1) begin
			if (val[j] && rs[i] == brs[j])
 				rg[i] = breg[j];
		end
	end
end

assign o_data0 = { rg[1], rg[0] };
assign o_data1 = { rg[3], rg[2] };
assign o_data2 = { rg[5], rg[4] };
assign o_data3 = { rg[7], rg[6] };

endmodule

