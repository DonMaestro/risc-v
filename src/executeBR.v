module executeBR #(parameter WIDTH_BRM = 4, WIDTH_REG = 7,
                             WIDTH = 1 + 7 + WIDTH_BRM + WIDTH_REG + 10 + 4*32)
                 (output [(2 ** WIDTH_BRM)-1:0] o_brkill,
                  output [WIDTH_REG-1:0]  o_addr,
                  output [31:0]           o_data,
                  output [32+WIDTH_REG:0] o_bypass,    // { 1, WIDTH_PRD, 32 }
                  output                  o_we,
                  output [31:0]           o_PC,
                  output                  o_valid,
                  input  [WIDTH-1:0]      i_instr,
                  input  [31:0]           i_PCNext,
                  input  [WIDTH_BRM-1:0]  i_brmask,
                  input  [(2 ** WIDTH_BRM)-1:0] i_brkill,
                  input                   i_rst_n, i_clk);

`include "src/killf.v"
integer i;

wire [WIDTH-1:0] instr;
wire [WIDTH_BRM-1:0] brmask_new;

wire [31:0] op1, op2, imm, PC;
wire [ 6:0] uop;
wire [ 9:0] func;
wire        val;
wire [WIDTH_BRM-1:0] brmask;
wire [WIDTH_REG-1:0] rd; // result register

reg  [4:0] ctrl;

wire assertion;
reg        valid;

wire [31:0] PCNext;
wire [31:0] PC_pl4, PC_jal, PC_jalr;
wire [31:0] PC_JT, PC_BT;
wire [31:0] PC_new, rdDt;

wire comp, killEn;
reg valOut;
reg [(2 ** WIDTH_BRM)-1:0] brkill;

register #(32) r_pipeI_PCN(PCNext, 1'b1, i_PCNext, i_rst_n, i_clk);
register r_pipeI(instr, 1'b1, i_instr, i_rst_n, i_clk);
defparam r_pipeI.WIDTH = WIDTH;
register r_pipeIbrmask(brmask_new, 1'b1, i_brmask, i_rst_n, i_clk);
defparam r_pipeIbrmask.WIDTH = WIDTH_BRM;

assign { val, uop, brmask, rd, PC, func, imm, op2, op1 } = instr;

// control
always @(*)
begin
	valOut = val;
	ctrl[4] = 1'b0;
	case(uop)
		7'b1100011: ctrl[4:3] = 2'b01; // b-type
		7'b1101111: ctrl[4:3] = 2'b10;// jal
		7'b1100111: ctrl[4:3] = 2'b11;// jalr
		default:    valOut = 1'b0;
	endcase

	valOut = killf(brmask, i_brkill) ? 1'b0 : valOut;
end

always @(func)
begin
	ctrl[2:0] = func[2:0];
end

// data

// mask formatting
always @(*)
begin
	brkill = { WIDTH_BRM{1'b0} };
	if (killEn) begin
		for (i = 0; i < 2 ** WIDTH_BRM; i = i + 1) begin
			if (brmask < brmask_new) begin
				if (brmask < i && i <= brmask_new)
					brkill[i] = 1'b1;
			end else begin
				if (brmask < i || i <= brmask_new)
					brkill[i] = 1'b1;
			end
		end
	end
end

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

assign killEn = ~comp & valOut;
assign rdDt = PC_pl4;

assign o_bypass = { valOut, rd, rdDt };

register       r_pipeO_MASK(o_brkill, 1'b1,   brkill, i_rst_n, i_clk);
register #(32) r_pipeO_PC  (o_PC,     valOut, PC_new, i_rst_n, i_clk);
register #( 1) r_pipeO_VALI(o_valid,  1'b1,   valOut, i_rst_n, i_clk);
register       r_pipeO_ADDR(o_addr,   valOut, rd,     i_rst_n, i_clk);
register #(32) r_pipeO_DATA(o_data,   valOut, rdDt,   i_rst_n, i_clk);
register #( 1) r_pipeO_WERD(o_we,     1'b1,   valOut, i_rst_n, i_clk);
defparam r_pipeO_MASK.WIDTH = 2 ** WIDTH_BRM;
defparam r_pipeO_ADDR.WIDTH = WIDTH_REG;

endmodule

