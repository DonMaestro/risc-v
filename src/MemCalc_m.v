`include "src/register.v"
module MemCalc_m #(parameter WIDTH = 4, WIDTH_REG = 5)
                 (output [31:0]          o_data,
                  output [WIDTH_REG-1:0] o_addr,
                  output                 o_valid,
                  input                  i_valid,
                  input  [ 6:0]          i_uop,
                  input  [ 9:0]          i_func,
                  input  [WIDTH_REG-1:0] i_addr,
                  input  [31:0]          i_op1, i_op2, i_imm,
                  input                  i_rst_n,
                  input                  i_clk);

localparam SIZE = $pow(2, WIDTH);
localparam IT = 2'b01, ST = 2'b10, OT = 2'b00;

reg [1:0] FMT;

reg [7:0] data[0:SIZE-1];

wire [31:0] op1, op2, imm;
wire [ 6:0] uop;
wire [ 9:0] func;
wire        val;
wire [WIDTH_REG-1:0] rd; // result register

wire [31:0]      data_r;
wire [WIDTH-1:0] addr;

wire valOut;

initial
begin
	$readmemh("ram.dat", data);
end

register       r_pipeI_ADR(rd,   i_valid, i_addr,  i_rst_n, i_clk);
register #(32) r_pipeI_OP1(op1,  i_valid, i_op1,   i_rst_n, i_clk);
register #(32) r_pipeI_OP2(op2,  i_valid, i_op2,   i_rst_n, i_clk);
register #(32) r_pipeI_IMM(imm,  i_valid, i_imm,   i_rst_n, i_clk);
register #( 7) r_pipeI_UOP(uop,  i_valid, i_uop,   i_rst_n, i_clk);
register #(10) r_pipeI_FNC(func, i_valid, i_func,  i_rst_n, i_clk);
register #( 1) r_pipeI_VAL(val,  1'b1,    i_valid, i_rst_n, i_clk);
defparam r_pipeI_ADR.WIDTH = WIDTH_REG;

assign addr = op1 + imm;

always @(uop)
begin
	case(uop)
		7'b0000011: FMT = IT;
		7'b0100011: FMT = ST;
		default:    FMT = OT;
	endcase
end

always @(posedge i_clk)
begin
	// if S-type instruction and valid data
	if (val && FMT == ST) begin
		data[addr] = op2;
		$writememh("Debug/ram.dat", data);
	end
end

// read
assign data_r[ 7: 0] = (func >= 10'h0) ? data[addr+0] : 32'b0;
assign data_r[15: 8] = (func >= 10'h1) ? data[addr+1] : 32'b0;
assign data_r[23:16] = (func >= 10'h1) ? data[addr+2] : 32'b0;
assign data_r[31:24] = (func == 10'h2) ? data[addr+3] : 32'b0;

assign valOut = (FMT == IT) ? 1'b1 : 1'b0;

register #( 1) r_pipeO_VALI(o_valid, 1'b1, valOut, i_rst_n, i_clk);
register #(32) r_pipeO_DATA(o_data,  val,  data_r, i_rst_n, i_clk);
register       r_pipeO_ADDR(o_addr,  val,  rd,     i_rst_n, i_clk);
defparam r_pipeO_ADDR.WIDTH = WIDTH_REG;

endmodule

