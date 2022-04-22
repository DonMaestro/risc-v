`include "src/register.v"
`include "src/mux2in1.v"

module execute #(parameter WIDTH_BRM = 4, WIDTH_PRD = 7)
               (output [31:0]           o_pdst,
                output [31:0]           o_WBdata,
                output [32+WIDTH_PRD:0] o_bypass,    // { 1, WIDTH_PRD, 32 }
                output                  o_valid,
                input                   i_valid,
                input  [6:0]            i_uop,
                input  [WIDTH_BRM-1:0]  i_brmask,
                input  [2:0]            i_ctrl,
                input  [31:0]           i_PC,
                input  [31:0]           i_op1, i_op2,
                input  [31:0]           i_imm,
                input                   i_rst_n, i_clk);

mux2in1 #(32) mux_A(A, i_ctrl[4], i_op1, i_PC);
mux2in1 #(32) mux_B(B, i_ctrl[5], i_op2, i_imm);

wire [31:0]          SrcA, SrcB, data;
wire [WIDTH_PRD-1:0] pdst;
wire [ 3:0]          ctrl;
wire                 val;

register #(32) r_pipeIO(SrcA, i_valid, A,       i_rst_n, i_clk);
register #(32) r_pipeIO(SrcB, i_valid, B,       i_rst_n, i_clk);
register       r_pipeIO(pdst, i_valid, i_pdst,  i_rst_n, i_clk);
defparam r_pipeIO.WIDTH = WIDTH_PRD;
register #( 4) r_pipeIO(ctrl, i_valid, i_ctrl[3:0], i_rst_n, i_clk);
register #( 1) r_pipeIO(val,  1'b1,    i_valid, i_rst_n, i_clk);

alu m_alu(.o_result(data),
          .i_control(ctrl),
          .i_op1(SrcA),
          .i_op2(SrcB));

assign o_bypass = { val, rdst, data };

register #(32) r_alu(o_WBdata, val, data, i_rst_n, i_clk);
register #(32) r_alu(o_pdst,   val, rdst, i_rst_n, i_clk);
endmodule

