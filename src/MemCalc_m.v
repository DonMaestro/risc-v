module MemCalc_m #(parameter WIDTH_MEM = 4, WIDTH_BRM = 4, WIDTH_REG = 5,
                             WIDTH = 1 + 7 + WIDTH_BRM + WIDTH_REG + 10 + 4*32)
                 (output [31:0]          o_data,
                  output [WIDTH_REG-1:0] o_addr,
                  output                 o_valid,
                  output [32+WIDTH_REG:0] o_bypass, // { val, WIDTH_REG, data }
                  input  [WIDTH-1:0]     i_instr,
                  input                  i_rst_n,
                  input                  i_clk);

localparam SIZE = $pow(2, WIDTH_MEM-1);
localparam IT = 2'b01, ST = 2'b10, OT = 2'b00;

//
wire [31:0] pc;

reg [1:0] FMT;

reg [7:0] data[0:SIZE-1];

wire [WIDTH-1:0] instr;

wire [31:0] op1, op2, imm;
wire [ 6:0] uop;
wire [WIDTH_BRM-1:0] brmask;
wire [ 9:0] func;
wire        val;
wire [WIDTH_REG-1:0] rd; // result register

wire [31:0]          data_r;
wire [WIDTH_MEM-1:0] addr;

wire valOut;

initial
begin
	$readmemh("ram.dat", data);
end

register r_pipeI(instr, 1'b1, i_instr, i_rst_n, i_clk);
defparam r_pipeI.WIDTH = WIDTH;

assign { val, uop, brmask, rd, pc, func, imm, op2, op1 } = instr;

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

assign o_bypass = { valOut, rd, data_r };

register #( 1) r_pipeO_VALI(o_valid, 1'b1, valOut, i_rst_n, i_clk);
register #(32) r_pipeO_DATA(o_data,  val,  data_r, i_rst_n, i_clk);
register       r_pipeO_ADDR(o_addr,  val,  rd,     i_rst_n, i_clk);
defparam r_pipeO_ADDR.WIDTH = WIDTH_REG;

endmodule

