`include "src/register.v"
`include "src/mux3in1.v"
`include "src/alu.v"

module executeALU #(parameter WIDTH_BRM = 4, WIDTH_REG = 7)
                  (output [WIDTH_REG-1:0]  o_addr,
                   output [31:0]           o_data,
                   output [32+WIDTH_REG:0] o_bypass,    // { 1, WIDTH_PRD, 32 }
                   output                  o_valid,
                   input                   i_valid,
                   input  [6:0]            i_uop,
                   input  [9:0]            i_func,
                   input  [WIDTH_REG-1:0]  i_addr,
                   input  [31:0]           i_PC,
                   input  [31:0]           i_op1, i_op2,
                   input  [31:0]           i_imm,
                   input                   i_rst_n, i_clk);

wire [31:0] op1, op2, imm, PC;
wire [ 6:0] uop;
wire [ 9:0] func;
wire        val;
wire [WIDTH_REG-1:0] rd; // result register

reg  [ 5:0] ctrl;

wire [31:0] data, lui, auipc;

wire [31:0] result;

wire valOut;

register       r_pipeI_ADR(rd,   i_valid, i_addr,  i_rst_n, i_clk);
register #(32) r_pipeI_PC (PC,   i_valid, i_PC,    i_rst_n, i_clk);
register #(32) r_pipeI_OP1(op1,  i_valid, i_op1,   i_rst_n, i_clk);
register #(32) r_pipeI_OP2(op2,  i_valid, i_op2,   i_rst_n, i_clk);
register #(32) r_pipeI_IMM(imm,  i_valid, i_imm,   i_rst_n, i_clk);
register #( 7) r_pipeI_UOP(uop,  i_valid, i_uop,   i_rst_n, i_clk);
register #(10) r_pipeI_FNC(func, i_valid, i_func,  i_rst_n, i_clk);
register #( 1) r_pipeI_VAL(val,  1'b1,    i_valid, i_rst_n, i_clk);
defparam r_pipeI_ADR.WIDTH = WIDTH_REG;

// Control
//   alu
//   WALU 
always @(func)
begin
	ctrl[2:0] = func[2:0];
	case(func)
		7'b0000000: ctrl[3] = 1'b0;
		7'b0100000: ctrl[3] = 1'b1;
	endcase
end

always @(uop)
begin
	casez(uop)
		7'b0?10011: ctrl[5:4] = 2'b00; //R-type or I-type
		7'b0110111: ctrl[5:4] = 2'b01; //lui
		7'b0010111: ctrl[5:4] = 2'b10; //auipc
	endcase
end

// data

alu m_alu(.o_result(data),
          .i_control(ctrl[3:0]),
          .i_op1(op1),
          .i_op2(op2));

assign lui   = imm << 12;
assign auipc = lui +  PC;

mux3in1 #(32) mux_result(result, ctrl[5:4], data, lui, auipc);

assign o_bypass = { val, rd, result };

register       r_pipeO_ADDR(o_addr,  val,  rd,     i_rst_n, i_clk);
register #( 1) r_pipeO_VALI(o_valid, 1'b1, val,    i_rst_n, i_clk);
register #(32) r_pipeO_DATA(o_data,  val,  result, i_rst_n, i_clk);
defparam r_pipeO_ADDR.WIDTH = WIDTH_REG;

endmodule

