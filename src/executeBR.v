`include "src/register.v"
`include "src/mux2in1.v"
`include "src/comparator.v"
`include "src/br.v"

module executeBR #(parameter WIDTH_BRM = 4, WIDTH_REG = 7,
                             WIDTH = 4*32 + WIDTH_REG + WIDTH_BRM + 7 + 10 + 1)
                 (output [WIDTH_BRM-1:0]  o_brmask,
                  output                  o_brkill,
                  output [WIDTH_REG-1:0]  o_addr,
                  output [31:0]           o_data,
                  output                  o_we,
                  output [31:0]           o_PC,
                  output                  o_valid,
                  input  [WIDTH-1:0]      i_instr,
                  input  [31:0]           i_PCNext,
                  input                   i_rst_n, i_clk);

wire [WIDTH-1:0] instr;

wire [31:0] op1, op2, imm, PC;
wire [ 6:0] uop;
wire [ 9:0] func;
wire        val;
wire [WIDTH_BRM-1:0] brmask;
wire [WIDTH_REG-1:0] rd; // result register

reg  [4:0] ctrl;

wire assertion;

wire [31:0] PCNext;
wire [31:0] PC_pl4, PC_jal, PC_jalr;
wire [31:0] PC_JT, PC_BT;
wire [31:0] PC_new, rdDt;

wire comp, brkill;
wire valOut;

register #(32) r_pipeI_PCN(PCNext, 1'b1, i_PCNext, i_rst_n, i_clk);
register r_pipeI(instr, 1'b1, i_instr, i_rst_n, i_clk);
defparam r_pipeI.WIDTH = WIDTH;

assign { val, func, brmask, uop, PC, imm, rd, op2, op1 } = instr;

// control
always @(uop)
begin
	ctrl[4] = 1'b0;
	case(uop)
		7'b1100011: ctrl[4:3] = 2'b01; // b-type
		7'b1101111: ctrl[4:3] = 2'b10;// jal
		7'b1100111: ctrl[4:3] = 2'b11;// jalr
	endcase
end

always @(func)
begin
	ctrl[2:0] = func[2:0];
end

// data

// calculation PC
assign PC_pl4 = PC  + 4;
assign PC_jal  = PC  + imm;
assign PC_jalr = op1 + imm;

// formation B-type
br mod_br(assertion, ctrl[2:0], op1, op2);
mux2in1 #(32) mux_BT(PC_BT, assertion, PC_pl4, PC_jal);

// formation J-type
mux2in1 #(32) mux_JT(PC_JT, ctrl[3], PC_jal, PC_jalr);

// choose type
mux2in1 #(32) mux_PC(PC_new, ctrl[4], PC_BT, PC_JT);

// check
comparator #(32) mod_comp(comp, PC_new, PCNext);

assign brkill = val & ~comp;
assign rdDt = PC_pl4;

register       r_pipeO_MASK(o_brmask, val,  brmask,  i_rst_n, i_clk);
register #( 1) r_pipeO_ENKL(o_brkill, 1'b1, brkill,  i_rst_n, i_clk);
register #(32) r_pipeO_PC  (o_PC,     val,  PC_new,  i_rst_n, i_clk);
register #( 1) r_pipeO_VALI(o_valid,  1'b1, val,     i_rst_n, i_clk);
register       r_pipeO_ADDR(o_addr,   val,  rd,      i_rst_n, i_clk);
register #(32) r_pipeO_DATA(o_data,   val,  rdDt,    i_rst_n, i_clk);
register #( 1) r_pipeO_WERD(o_we,     1'b1, ctrl[4], i_rst_n, i_clk);
defparam r_pipeO_MASK.WIDTH = WIDTH_BRM;
defparam r_pipeO_ADDR.WIDTH = WIDTH_REG;

endmodule

