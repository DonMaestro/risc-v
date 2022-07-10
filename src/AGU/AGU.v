module AGU #(parameter WIDTH_REG = 5, WIDTH_BRM = 4, WIDTH_TAG = 4,
                       WIDTH_MEM = 4,
                       WIDTH = 2 + 7 + WIDTH_BRM + WIDTH_REG + 10 + 4*32)
           (// regFile
            output        [32-1:0] o_data,
            output [WIDTH_REG-1:0] o_addr,
            output                 o_val,
            // DCatch
            output [WIDTH_MEM-1:0] dcache_i_data,
            output [WIDTH_MEM-1:0] dcache_i_addr,
            output                 dcache_i_kill,
            input         [32-1:0] dcache_o_data,
            input                  dcache_o_nack,
            // input
            input            [WIDTH-1:0] i_instr,
            input [(2 ** WIDTH_BRM)-1:0] i_brkill,
            input                        i_rst_n,
            input                        i_clk);

`include "src/killf.v"

localparam SIZE = 2 ** WIDTH_MEM;
localparam WIDTH_LQ = WIDTH_TAG,
           WIDTH_SQ = WIDTH_TAG-1;
localparam IT = 2'b01, ST = 2'b10, OT = 2'b00;

reg [1:0] FMT;

wire [WIDTH-1:0] instr;

// wire execution
wire [31:0] op1, op2, imm;
wire [ 6:0] uop;
wire [31:0] pc;
wire [WIDTH_BRM-1:0] brmask;
wire [ 9:0] func;
wire [ 1:0] val;
wire [WIDTH_REG-1:0] rd; // result register

wire [WIDTH_MEM-1:0] naddr, qaddr, laddr, saddr;
wire [WIDTH_MEM-1:0] vaddr;

wire TLBms;

wire [WIDTH_MEM-1:0] paddr;

wire [:0] entries_saq;
wire [:0] entries_laq;

wire                 dcache_kill;
wire        [32-1:0] dcache_data;
wire [WIDTH_MEM-1:0] dcache_addr;

// wire memory

// wire writeback
wire       [32-1:0] sdq_data;
wire [WIDTH_SQ-1:0] sdq_addr;
wire       [32-1:0] sdq_wdata;
wire                sdq_we;


register r_pipeI(instr, 1'b1, i_instr, i_rst_n, i_clk);
defparam r_pipeI.WIDTH = WIDTH;

/*
 * Execution stage
 */
assign { val, uop, tag, brmask, rd, pc, func, imm, op2, op1 } = instr;

// control logic
always @(*)
begin
	case(uop)
		7'b0000011: FMT = IT;
		7'b0100011: FMT = ST;
		default:    FMT = OT;
	endcase

	vali = |val;
	vali = FMT == ST && killf(brmask, i_brkill) ? 1'b0 : vali;


end

// address calculation
assign naddr = op1[WIDTH_MEM-1:0] + imm[WIDTH_MEM-1:0];

mux2in1  mux_lsq(qaddr, 1'b0, saddr, laddr);
defparam mux_lsq.WIDTH = WIDTH_MEM;
mux2in1  mux_vaddr(vaddr, 1'b0, naddr, qaddr);
defparam mux_vaddr.WIDTH = WIDTH_MEM;

// TLB
assign paddr = vaddr;
assign TLBms = 1'b0;

mux3in1  mux_dcache_addr(dcache_addr, 1'b0, paddr, saddr, laddr);
defparam mux_dcache_addr.WIDTH = WIDTH_MEM;

//DCache
register r_dc_addr(dcache_i_addr, 1'b1, dcache_addr, i_rst_n, i_clk);
defparam r_dc_addr.WIDTH = WIDTH_MEM;
register r_dc_data(dcache_i_data, 1'b1,         op2, i_rst_n, i_clk);
defparam r_dc_data.WIDTH = 32;
assign dcache_i_kill = dcache_kill;
assign dcache_data   = dcache_o_data;

SAQ m_SAQ(.o_entries (entries_saq),  // all entries
          .i_we      (FMT[1]),
          .i_A       (1'b1),
          .i_addr    (paddr),
          .i_V       (TLBms), //V set when TLB miss
          .i_tag     (tag),
          .i_aval    (),
          .i_rst_n   (i_rst_n),
          .i_clk     (i_clk));
defparam m_SAQ.WIDTH = WIDTH_SQ;

LAQ m_LAQ(.o_entries (entries_laq),  // all entries
          .o_entry   (),
          .i_we      (FMT[0]),
          .i_A       (1'b0),
          .i_addr    (paddr),
          .i_V       (TLBms), //V set when TLB miss
          .i_M       (1'b0),
          .i_rd      (rd),
          .i_tag     (tag),
          .i_setM    (),
          .i_rst_n   (i_rst_n),
          .i_clk     (i_clk));
defparam m_LAQ.WIDTH     = WIDTH_LQ;
defparam m_LAQ.WIDTH_REG = WIDTH_REG;

register r_paddr(paddrmatch, ~TLBms, paddr, i_rst_n, i_clk);
defparam r_paddr.WIDTH = WIDTH_MEM;
/*
 * type instruction
 * addr
 * data
 * val data and addr
 * address in the queue
 */

/*
 * Memory stage
 */
always @(*)
begin
	for (i = 0; i < WIDTH_SQ; i = i + 1) begin
		match = entries_saq[i]
	end

	for (i = 0; i < WIDTH_LQ; i = i + 1) begin
		match = entries_laq[i]
	end
end

register #(WIDTH_SQ) r_sdq_addr(sdq_addr,  1'b1, 0, i_rst_n, i_clk);
register #(32)       r_sdq_data(sdq_wdata, 1'b1, 0, i_rst_n, i_clk);
register #(1)        r_sdq_we  (sdq_we,    1'b1, 0, i_rst_n, i_clk);

register #(1) r_pipeO_VALI(o_val,    1'b1, , i_rst_n, i_clk);
register      r_pipeO_ADDR(o_addr, valOut, , i_rst_n, i_clk);
defparam r_pipeO_ADDR.WIDTH = WIDTH_REG;

/*
 * Writeback stage
 */
ram m_SDQ(.o_data(sdq_data),
          .i_addr(sdq_addr),
          .i_data(sdq_wdata),
          .i_we  (sdq_we),
          .i_clk (i_clk));
defparam m_SDQ.WIDTH_ADDR = WIDTH_SQ;
defparam m_SDQ.WIDTH_DATA = 32;

mux2in1 #(32) m_pipeO_DATA(o_data, 1'b0, dcache_data, sdq_data);

endmodule

