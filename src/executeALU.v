module executeALU #(parameter WIDTH_BRM = 4, WIDTH_REG = 7,
                              WIDTH = 1 + 7 + WIDTH_BRM + WIDTH_REG + 10 + 4*32)
                  (output [WIDTH_REG-1:0]  o_addr,
                   output [31:0]           o_data,
                   output [32+WIDTH_REG:0] o_bypass,    // { 1, WIDTH_PRD, 32 }
                   output                  o_valid,
                   input  [WIDTH-1:0]      i_instr,
                   input                   i_rst_n, i_clk);

wire [WIDTH-1:0] instr;

wire [31:0]          op1, op2, imm, PC;
wire [31:0]          B;
wire [ 6:0]          uop;
wire [WIDTH_BRM-1:0] brmask;
wire [ 9:0]          func;
wire                 val;
wire [WIDTH_REG-1:0] rd; // result register

reg  [ 5:0] ctrl;

wire [31:0] data, auipc;

wire [31:0] result;

reg valOut;

register r_pipeI(instr, 1'b1, i_instr, i_rst_n, i_clk);
defparam r_pipeI.WIDTH = WIDTH;

assign { val, uop, brmask, rd, PC, func, imm, op2, op1 } = instr;

// Control
always @(func)
begin
	ctrl[2:0] = func[2:0];
	case(func[9:3])
		7'b0000000: ctrl[3] = 1'b0;
		7'b0100000: ctrl[3] = 1'b1;
	endcase
end

always @(uop)
begin
	valOut = val;
	casez(uop)
		7'b0?10011: ctrl[5:4] = 2'b00; //R-type or I-type
		7'b0110111: ctrl[5:4] = 2'b01; //lui
		7'b0010111: ctrl[5:4] = 2'b10; //auipc
		default:    valOut = 1'b0;
	endcase
end

// data

mux2in1 #(32) mux_op2(B, uop[5], imm, op2);

alu m_alu(.o_result(data),
          .i_control(ctrl[3:0]),
          .i_op1(op1),
          .i_op2(B));

assign auipc = imm + PC;

mux3in1 #(32) mux_result(result, ctrl[5:4], data, imm, auipc);

assign o_bypass = { valOut, rd, result };

register       r_pipeO_ADDR(o_addr,  val,  rd,     i_rst_n, i_clk);
register #( 1) r_pipeO_VALI(o_valid, 1'b1, valOut, i_rst_n, i_clk);
register #(32) r_pipeO_DATA(o_data,  val,  result, i_rst_n, i_clk);
defparam r_pipeO_ADDR.WIDTH = WIDTH_REG;

endmodule

