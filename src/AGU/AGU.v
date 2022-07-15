module AGU #(parameter WIDTH_REG = 5, WIDTH_BRM = 4, WIDTH_TAG = 4,
                       WIDTH_MEM = 4,
                       WIDTH = 2 + 7 + WIDTH_TAG + WIDTH_BRM + WIDTH_REG + 10 + 3*32)
           (// regFile
            output        [32-1:0] o_data,
            output [WIDTH_REG-1:0] o_addr,
            output                 o_val,
            // DCatch
            output        [32-1:0] dcache_i_data,
            output [WIDTH_MEM-1:0] dcache_i_addr,
            output                 dcache_i_we,
            output                 dcache_i_kill,
            input         [32-1:0] dcache_o_data,
            input                  dcache_o_nack,
            // input
            input            [WIDTH-1:0] i_instr,
            input [(2 ** WIDTH_BRM)-1:0] i_brkill,
            input                        i_rst_n,
            input                        i_clk);

//localparam SIZE = 2 ** WIDTH_MEM;
localparam WIDTH_LQ = WIDTH_TAG,
           WIDTH_SQ = WIDTH_TAG-1;
localparam IT = 2'b01, ST = 2'b10, OT = 2'b00;

//integer i;

`include "src/killf.v"

reg [1:0] FMT;

wire [WIDTH-1:0] instr;

// wire execution
wire [31:0] op1, op2, imm;
wire [ 6:0] uop;
wire [WIDTH_BRM-1:0] brmask;
wire [WIDTH_TAG-1:0] tag;
wire [ 9:0] func;
wire [ 1:0] val;  // valid { data, addr }
wire [WIDTH_REG-1:0] rd; // result register

wire [WIDTH_MEM-1:0] naddr, qaddr, laddr, saddr;
wire [WIDTH_MEM-1:0] vaddr;

wire TLBms;

wire [WIDTH_MEM-1:0] paddr;

reg val_wu;
reg we_saq, we_sdq, we_laq;

wire                saq_wkup_val;
wire                laq_wkup_val;

wire [WIDTH_SQ-1:0] saq_waddrD;
wire                saq_setD;

wire                 ent_type;
wire [WIDTH_MEM-1:0] ent_addr;
wire [WIDTH_TAG-1:0] ent_tag;

wire          ent_we;

wire          ent_val;

wire [m_SAQ.WIDTH_DATA * m_SAQ.SIZE - 1:0] cells_saq;
wire [m_LAQ.WIDTH_DATA * m_LAQ.SIZE - 1:0] cells_laq;

reg                  dcache_kill;
wire [WIDTH_MEM-1:0] dcache_addr;

// wire memory
integer j;

wire comp_saq, comp_saq_D, comp_laq;
wire                wb_type;

reg we_rf;

wire                laq_setS;
wire [WIDTH_LQ-1:0] laq_addrS;

// wire writeback
wire       [32-1:0] sdq_data;
wire [WIDTH_SQ-1:0] sdq_addr;
wire       [32-1:0] sdq_wdata;
wire                sdq_we;

/*
 * input registers
 */
register r_pipeI(instr, 1'b1, i_instr, i_rst_n, i_clk);
defparam r_pipeI.WIDTH = WIDTH;

/*
 * Execution stage
 */

assign { val, uop, tag, brmask, rd, func, imm, op2, op1 } = instr;

// control logic
always @(*)
begin
	// decoder
	case (uop)
	7'b0000011: FMT = IT;
	7'b0100011: FMT = ST;
	default:    FMT = OT;
	endcase

	val_wu = &(~val);
	if (val_wu) begin
		case ({ saq_wkup_val, laq_wkup_val })
		2'b00: FMT = OT;
		2'b01: FMT = IT;
		2'b10: FMT = ST;
		2'b11: FMT = IT;
		endcase
	end

	// only input data;
	we_saq = val[0] & FMT[1];
	we_sdq = val[1] & FMT[1];
	we_laq = val[0] & FMT[0];
end

// address calculation
assign naddr = op1[WIDTH_MEM-1:0] + imm[WIDTH_MEM-1:0];

mux2in1  mux_lsq(qaddr, FMT[0], saddr, laddr);
defparam mux_lsq.WIDTH = WIDTH_MEM;
mux2in1  mux_vaddr(vaddr, val_wu, naddr, qaddr);
defparam mux_vaddr.WIDTH = WIDTH_MEM;

// TLB
//defparam WIDTH = WIDTH_MEM;
assign paddr = vaddr;
assign TLBms = 1'b0;

mux3in1  mux_dcache_addr(dcache_addr, 2'b0, paddr, saddr, laddr);
defparam mux_dcache_addr.WIDTH = WIDTH_MEM;

assign saddr        = { WIDTH_MEM{1'b1} };
assign saq_wkup_val = 1'b0;
SAQ m_SAQ(.o_cells   (cells_saq),  // cells_saq all entries
          .o_entry   (),
          // ring buffer ports
          .o_empty   (),
          .o_overflow(),
          .i_re      (1'b0),
          // input
          // new entry
          .i_we      (we_saq),
          .i_val     (1'b1),
          .i_tag     (tag),
          // addr
          .i_weV     (1'b0),
          .i_waddrV  (),
          .i_addr    (paddr),
          .i_V       (TLBms),  // V set when TLB miss
          // data availability
          .i_setD    (saq_setD),
          .i_waddrD  (saq_waddrD),
          // clk
          .i_rst_n   (i_rst_n),
          .i_clk     (i_clk));
defparam m_SAQ.WIDTH_TAG  = WIDTH_TAG;
defparam m_SAQ.WIDTH_ADDR = WIDTH_MEM;
defparam m_SAQ.WIDTH      = WIDTH_SQ;

LAQ m_LAQ(.o_cells    (cells_laq),  // all entries
          .o_entry    (),
          .o_wkup_addr(laddr),
          .o_wkup_val (laq_wkup_val),
          // ring buffer
          .o_empty   (),
          .o_overflow(),
          .i_re      (1'b0),
          // input data for the table
          .i_we      (we_laq),
          .i_val     (1'b0),
          .i_rd      (rd),
          .i_tag     (tag),
          // addr
          .i_weV     (1'b0),
          .i_waddrV  (),
          .i_addr    (paddr),
          .i_V       (TLBms),  // V set when TLB miss
          // set/reset flags
          .i_setS    (laq_setS),
          .i_waddrS  (laq_addrS),
          .i_weM     (1'b0),
          .i_waddrM  (),
          .i_M       (),
          // read wake up
          .i_r_wu    (1'b0),
          .i_rst_n   (i_rst_n),
          .i_clk     (i_clk));
defparam m_LAQ.WIDTH_REG  = WIDTH_REG;
defparam m_LAQ.WIDTH_TAG  = WIDTH_TAG;
defparam m_LAQ.WIDTH_ADDR = WIDTH_MEM;
defparam m_LAQ.WIDTH      = WIDTH_LQ;

/*
 * type instruction
 * addr
 * tag
 *
 * valid instruction
 * write enable data
 * data
 */

//DCache
register r_dc_addr(dcache_i_addr, ~TLBms, dcache_addr, i_rst_n, i_clk);
defparam r_dc_addr.WIDTH = WIDTH_MEM;
register r_dc_data(dcache_i_data,   1'b1,         op2, i_rst_n, i_clk);
defparam r_dc_data.WIDTH = 32;
register r_dc_wren(dcache_i_we,     1'b1,      we_sdq, i_rst_n, i_clk);
defparam r_dc_wren.WIDTH = 1;
assign dcache_i_kill = dcache_kill;

register #(1) r_ent_val(ent_val, 1'b1, val[0], i_rst_n, i_clk);
register #(1) r_ent_we (ent_we,  1'b1, val[1], i_rst_n, i_clk);

register r_ent_type(ent_type, 1'b1, FMT[1], i_rst_n, i_clk);
defparam r_ent_type.WIDTH = 1;
register r_ent_addr(ent_addr, 1'b1, paddr,  i_rst_n, i_clk);
defparam r_ent_addr.WIDTH = WIDTH_MEM;
register r_ent_tag (ent_tag,  1'b1, tag,    i_rst_n, i_clk);
defparam r_ent_tag.WIDTH = WIDTH_TAG;

/*
 * Memory stage
 */

//mux2in1  mux_addr(addr, val_wu, ent_addr, laddr);
//defparam mux_addr.WIDTH = WIDTH_MEM;

wire [WIDTH_REG-1:0] comp_rd;
wire [WIDTH_SQ-1:0]  saq_addr;
wire [WIDTH_SQ-1:0]  saq_addr_D;
wire [WIDTH_LQ-1:0]  laq_addr;

comparator m_comp(.o_comp_saq (comp_saq),
                  .o_saq_addr (saq_addr),
                  .o_comp_saq_D (comp_saq_D),
                  .o_saq_addr_D (saq_addr_D),
                  .o_comp_laq (comp_laq),
                  .o_laq_addr (laq_addr),
                  .o_rd       (comp_rd),
                  .i_addr     (ent_addr),
                  .i_cells_laq(cells_laq),
                  .i_cells_saq(cells_saq));
defparam m_comp.WIDTH_SAQ  = WIDTH_SQ;
defparam m_comp.WIDTH_LAQ  = WIDTH_LQ;
//defparam m_comp.SIZE_SAQ = 2 ** WIDTH_SAQ;
//defparam m_comp.SIZE_LAQ = 2 ** WIDTH_LAQ;
defparam m_comp.WIDTH_ADDR = WIDTH_MEM;
defparam m_comp.WIDTH_REG  = WIDTH_REG;
defparam m_comp.WIDTH_TAG  = WIDTH_TAG;
//defparam m_comp.DATA_SAQ = 4 + 32 + WIDTH_TAG;
//defparam m_comp.DATA_LAQ = 4 + 32 + WIDTH_REG + WIDTH_TAG;

assign saq_setD   = ent_we & comp_saq_D;
assign saq_waddrD = saq_addr_D;
assign laq_setS   = ~ent_type & ent_val &  comp_saq;
assign laq_addrS  = laq_addr;
always @(*)
begin
	if (ent_type) begin  // Store type
		we_rf = 1'b0;
		dcache_kill = killf(ent_tag, i_brkill);
	end else begin  // Load type
		we_rf      = ent_val & !comp_saq & killf(ent_tag, i_brkill);
		dcache_kill = ent_val & comp_saq | killf(ent_tag, i_brkill);
	end
end

/*
 * type instruction
 * tag
 * queue address
 *
 * write enable data
 * data
 *
 * valid instruction
 * destination register(rd)
 */
register #(1)  r_wb_type (wb_type,   1'b1,   ent_type, i_rst_n, i_clk);
register       r_sdq_addr(sdq_addr,  ent_we, saq_addr, i_rst_n, i_clk);
defparam       r_sdq_addr.WIDTH = WIDTH_SQ;

register #(1)  r_sdq_we  (sdq_we,    1'b1,   ent_we,        i_rst_n, i_clk);
register #(32) r_sdq_data(sdq_wdata, 1'b1,   dcache_i_data, i_rst_n, i_clk);

register #(1) r_pipeO_VAL(o_val,  1'b1, we_rf,   i_rst_n, i_clk);
register      r_pipeO_RD (o_addr, 1'b1, comp_rd, i_rst_n, i_clk);
defparam      r_pipeO_RD.WIDTH = WIDTH_REG;

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

mux2in1 #(32) m_pipeO_DATA(o_data, 1'b0, dcache_o_data, sdq_data);

endmodule

