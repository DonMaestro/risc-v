module AGU #(parameter WIDTH_MEM = 4, WIDTH_BRM = 4, WIDTH_REG = 5,
                       WIDTH = 2 + 7 + WIDTH_BRM + WIDTH_REG + 10 + 4*32)
           (output [32+WIDTH_REG:0] o_bypass, // { val, WIDTH_REG, data }
            // regFile
            output [31:0]          o_data,
            output [WIDTH_REG-1:0] o_addr,
            output                 o_valid,
            // DCatch
            output        [32-1:0] dcache_o_data,
            input  [WIDTH_MEM-1:0] dcache_i_data,
            input  [WIDTH_MEM-1:0] dcache_i_addr,
            input                  dcache_i_kill,
            // input
            input [WIDTH-1:0]            i_instr,
            input [(2 ** WIDTH_BRM)-1:0] i_brkill,
            input                        i_rst_n,
            input                        i_clk);

`include "src/killf.v"

localparam SIZE = 2 ** WIDTH_MEM;
localparam IT = 2'b01, ST = 2'b10, OT = 2'b00;

reg [1:0] FMT;

wire [WIDTH-1:0] instr;

wire [31:0] op1, op2, imm;
wire [ 6:0] uop;
wire [31:0] pc;
wire [WIDTH_BRM-1:0] brmask;
wire [ 9:0] func;
wire [ 1:0] val;
wire [WIDTH_REG-1:0] rd; // result register

wire [32-1:0] naddr, qaddr, laddr, saddr;
wire [32-1:0] vaddr;

wire [WIDTH_MEM-1:0] paddr;

wire [WIDTH_MEM-1:0] paddrmatch;

// output data
wire [31:0] dcache_data, sdq_data;

reg valOut;

// input Flip-Flop state
register r_pipeI(instr, 1'b1, i_instr, i_rst_n, i_clk);
defparam r_pipeI.WIDTH = WIDTH;

assign { val, uop, brmask, rd, pc, func, imm, op2, op1 } = instr;

// control logic
always @(*)
begin
	case(uop)
		7'b0000011: FMT = IT;
		7'b0100011: FMT = ST;
		default:    FMT = OT;
	endcase

	valOut = 1'b0;
	if (FMT == IT)
		valOut = val;
	valOut = killf(brmask, i_brkill) ? 1'b0 : valOut;
end

// data

// address calculation
assign naddr = op1 + imm;

mux2in1 mux_lsq(qaddr, 1'b0, saddr, laddr);
mux2in1 mux_vaddr(vaddr, 1'b0, naddr, qaddr);
// TLB
assign paddr = vaddr[WIDTH_MEM-1:0];
assign TLBms = 1'b0;

//DCache
assign dcache_data   = dcache_o_data;
assign dcache_i_kill = ~match;
register #(32) r_dc_addr(dcache_i_addr, 1'b1, paddr, i_rst_n, i_clk);
register #(32) r_dc_data(dcache_i_data, 1'b1,   op2, i_rst_n, i_clk);

register r_paddr(paddrmatch, ~TLBms, paddr, i_rst_n, i_clk);

SAQ m_SAQ(.o_match(match), 
          .i_addr(paddr),
          .i_V(TLBms), //V set when TLB miss
          .i_tag(),
          .i_en(val),
          .i_addrmatch(paddrmatch),
          .i_rst_n(i_rst_n),
          .i_clk(i_clk));
defparam m_SAQ.WIDTH = 5;

LAQ m_LAQ(.o_match(match), 
          .i_addr(paddr),
          .i_V(TLBms), //V set when TLB miss
          .i_tag(),
          .i_en(val),
          .i_addrmatch(paddrmatch),
          .i_rst_n(i_rst_n),
          .i_clk(i_clk));
defparam m_LAQ.WIDTH = 5;

SDQ m_SDQ(.o_data (sdq_data),
          .i_raddr(),
          .i_data (op2),
          .i_rd   (rd),
          .i_we   (val),
          .i_rst_n(i_rst_n),
          .i_clk  (i_clk));
defparam m_SAQ.WIDTH = 5;
module ringbuf #(parameter WIDTH = 4, SIZE = 20)
               (output wor [WIDTH-1:0] o_data,
                output                 o_empty, o_overflow,
                input      [WIDTH-1:0] i_data,
                input      i_re, i_we, i_rst_n, i_clk);

assign o_bypass = { valOut, rd, data_r };

mux2in1 #(32) m_d(o_data, 1'b0, dcache_data, sdq_data);

register #( 1) r_pipeO_VALI(o_valid, 1'b1,    valOut, i_rst_n, i_clk);
register       r_pipeO_ADDR(o_addr,  valOut,  rd,     i_rst_n, i_clk);
defparam r_pipeO_ADDR.WIDTH = WIDTH_REG;

endmodule

