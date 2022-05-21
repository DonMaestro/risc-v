// i_regFileX = { RS2, RS1 };
// instr = { CTRL, BRMASK, UOPCode, PC, IMM, RD, RS2, RS1 }
// CTRL = { ENMOD, FUNC }
module bypass #(parameter WIDTH = 32, WIDTH_REG = 5)
              (output [WIDTH-1:0]     o_mod0, o_mod1, o_mod2, o_mod3,
               input  [WIDTH-64-1:0]  i_instr0, i_instr1, i_instr2, i_instr3, //without RS2 and RS1
               input  [2*32-1:0]      i_regFile0, i_regFile1, i_regFile2, i_regFile3,
               input  [WIDTH_REG-1:0] i_bypass);

localparam WIDTH_MOD = WIDTH - 2*WIDTH_REG + 2*32 - 2; // rm RS2, RS1, CTRL[end:end-2]

integer i;
wire [1:0]           ctrl[0:2];
wire [WIDTH_MOD-1:0] instr[0:3];
wire [WIDTH_MOD-1:0] mod1[1:2], mod2[1:2], mod3[1:2], mod4[1:2];

// read control bits
assign ctrl[0] = i_instr0[WIDTH-1:WIDTH-3]; // length 2b
assign ctrl[1] = i_instr1[WIDTH-1:WIDTH-3]; // length 2b
assign ctrl[2] = i_instr2[WIDTH-1:WIDTH-3]; // length 2b

// forwarding from regFile or modules
assign instr[0] = { i_instr0, i_regFile0 };
assign instr[1] = { i_instr1, i_regFile1 };
assign instr[2] = { i_instr2, i_regFile2 };
assign instr[3] = { i_instr3, i_regFile3 };

// forwarding to modules
//demux1to4 demux1(mod1[1], mod2[1], mod3[1], mod4[1], ctrl[1], instr[1]);
//demux1to4 demux2(mod1[2], mod2[2], mod3[2], mod4[2], ctrl[2], instr[2]);
//defparam demux1.WIDTH = WIDTH_MOD;
//defparam demux2.WIDTH = WIDTH_MOD;

assign o_mod0 = instr[0];
assign o_mod1 = instr[1];
assign o_mod2 = instr[2];
assign o_mod3 = instr[3];

//assign o_error = ctrl[1] && ctrl[2];

endmodule

