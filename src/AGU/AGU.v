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

localparam SIZE = 2 ** WIDTH_MEM;
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

reg vali;

wire [32-1:0] naddr, qaddr, laddr, saddr;
wire [32-1:0] vaddr;

wire TLBms;

wire [32-1:0] paddr;

reg we_saq, we_sdq, we_laq;

wire          ent_type;
wire [32-1:0] ent_addr;

wire [32-1:0] ent_data;
wire          ent_we;

wire          ent_val;
wire [WIDTH_REG-1:0] ent_rd;

wire [m_SAQ.WIDTH * m_SAQ.SIZE - 1:0] entries_saq;
wire [m_LAQ.WIDTH * m_LAQ.SIZE - 1:0] entries_laq;

reg                  dcache_kill;
wire        [32-1:0] dcache_data;
wire [WIDTH_MEM-1:0] dcache_addr;

// wire memory

wire                wb_type;
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
	case(uop)
		7'b0000011: FMT = IT;
		7'b0100011: FMT = ST;
		default:    FMT = OT;
	endcase
	if (&(~val))
		FMT = OT;

	vali = |val;
	vali = FMT == ST && killf(brmask, i_brkill) ? 1'b0 : vali;

	we_saq = val[0] & FMT[1];
	we_sdq = val[1] & FMT[1];
	we_laq = FMT[0];
end

// address calculation
assign naddr = op1 + imm;

mux2in1  mux_lsq(qaddr, FMT[0], saddr, laddr);
defparam mux_lsq.WIDTH = 32;
mux2in1  mux_vaddr(vaddr, 1'b0, naddr, qaddr);
defparam mux_vaddr.WIDTH = 32;

// TLB
assign paddr = vaddr;
assign TLBms = 1'b0;

mux3in1  mux_dcache_addr(dcache_addr, 2'b0, paddr[WIDTH_MEM-1:0],
                         saddr[WIDTH_MEM-1:0], laddr[WIDTH_MEM-1:0]);
defparam mux_dcache_addr.WIDTH = WIDTH_MEM;

//DCache
register r_dc_addr(dcache_i_addr, 1'b1, dcache_addr, i_rst_n, i_clk);
defparam r_dc_addr.WIDTH = WIDTH_MEM;
register r_dc_data(dcache_i_data, 1'b1,         op2, i_rst_n, i_clk);
defparam r_dc_data.WIDTH = 32;
register r_dc_wren(dcache_i_we,   1'b1,      we_sdq, i_rst_n, i_clk);
defparam r_dc_wren.WIDTH = 1;
//assign dcache_i_kill = dcache_kill;
assign dcache_i_kill = 1'b0;
assign dcache_data   = dcache_o_data;

SAQ m_SAQ(.o_entries (entries_saq),  //entries_saq all entries
          .o_entry   (),
          // ring buffer ports
          .o_empty   (),
          .o_overflow(),
          .i_re      (1'b0),
          .i_we      (we_saq),
          // write new data for the table
          .i_A       (1'b1),
          .i_val     (1'b1),
          .i_addr    (paddr),
          .i_V       (TLBms),  //V set when TLB miss
          .i_tag     (tag),
          .i_aval    (val[1]),
          // set/reset flags
          .i_set_aval(),
          .i_rst_n   (i_rst_n),
          .i_clk     (i_clk));
defparam m_SAQ.WIDTH_TAG = WIDTH_TAG;
defparam m_SAQ.WIDTH_ADDR = WIDTH_SQ;

LAQ m_LAQ(.o_entries (entries_laq),  // all entries
          .o_entry   (),
          // ring buffer
          .o_empty   (),
          .o_overflow(),
          .i_re      (1'b0),
          .i_we      (we_laq),
          // input data for the table
          .i_A       (1'b1),
          .i_val     (1'b1),
          .i_addr    (paddr),
          .i_V       (TLBms), //V set when TLB miss
          .i_M       (1'b0),
          .i_rd      (rd),
          .i_tag     (tag),
          // set/reset flags
          .i_setM    (),
          .i_rst_n   (i_rst_n),
          .i_clk     (i_clk));
defparam m_LAQ.WIDTH_REG = WIDTH_REG;
defparam m_LAQ.WIDTH_TAG = WIDTH_TAG;
defparam m_LAQ.WIDTH_ADDR = WIDTH_LQ;

/*
 * type instruction
 * tag
 * addr
 *
 * write enable data
 * data
 *
 * valid instruction
 * destination register(rd)
 */
register #(1)  r_ent_type(ent_type, 1'b1, FMT[1], i_rst_n, i_clk);
register #(32) r_ent_addr(ent_addr, 1'b1, paddr,  i_rst_n, i_clk);

register #(1)  r_ent_we  (ent_we,   1'b1,   val[1], i_rst_n, i_clk);
register #(32) r_ent_data(ent_data, val[0], op2,    i_rst_n, i_clk);

register r_ent_val(ent_val, 1'b1, FMT[0], i_rst_n, i_clk);
defparam r_ent_val.WIDTH = 1;
register r_ent_rd(ent_rd, 1'b1, rd, i_rst_n, i_clk);
defparam r_ent_rd.WIDTH = WIDTH_REG;

/*
 * Memory stage
 */

reg [m_SAQ.WIDTH-1:0] entry_saq[0:m_SAQ.SIZE-1];
reg [m_LAQ.WIDTH-1:0] entry_laq[0:m_LAQ.SIZE-1];

wire                 saq_A[0:m_SAQ.SIZE-1];
wire                 saq_val[0:m_SAQ.SIZE-1];
wire [31:0]          saq_addr[0:m_SAQ.SIZE-1];
wire                 saq_V[0:m_SAQ.SIZE-1];
wire                 saq_aval[0:m_SAQ.SIZE-1];
wire [WIDTH_TAG-1:0] saq_tag[0:m_SAQ.SIZE-1];

wire                 laq_A[0:m_LAQ.SIZE-1];
wire                 laq_val[0:m_LAQ.SIZE-1];
wire [31:0]          laq_addr[0:m_LAQ.SIZE-1];
wire                 laq_V[0:m_LAQ.SIZE-1];
wire                 laq_M[0:m_LAQ.SIZE-1];
wire [WIDTH_REG-1:0] laq_rd[0:m_LAQ.SIZE-1];
wire [WIDTH_TAG-1:0] laq_tag[0:m_LAQ.SIZE-1];

wor comp_saq, comp_laq;

generate
	genvar i;
	for (i = 0; i < m_SAQ.SIZE; i = i + 1) begin: array_entry_saq
		assign entry_saq[i] = entries_saq[(i+1) * m_SAQ.WIDTH - 1
		                                 : i    * m_SAQ.WIDTH];
		assign {saq_A[i],
			saq_val[i],
			saq_addr[i],
			saq_V[i],
			saq_tag[i],
			saq_aval[i]
		} = entry_saq[i];
		assign comp_saq = saq_addr[i] == ent_addr;
	end

	for (i = 0; i < m_LAQ.SIZE; i = i + 1) begin: array_entry_laq
		assign entry_laq[i] = entries_laq[(i+1) * m_LAQ.WIDTH - 1
		                                 : i    * m_LAQ.WIDTH];
		assign {laq_A[i],
			laq_val[i],
			laq_addr[i],
			laq_V[i],
			laq_M[i],
			laq_rd[i],
			laq_tag[i]
		} = entry_laq[i];
		assign comp_laq = laq_addr[i] == ent_addr;
	end
endgenerate

integer j;


always @(*)
begin


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
register #(1)  r_wb_type(wb_type, 1'b1, ent_type, i_rst_n, i_clk);
register r_sdq_addr(sdq_addr,  ent_we, {WIDTH_SQ{1'b0}}, i_rst_n, i_clk);
defparam r_sdq_addr.WIDTH = WIDTH_SQ;
register #(1)  r_sdq_we  (sdq_we,    1'b1,   ent_we,   i_rst_n, i_clk);
register #(32) r_sdq_data(sdq_wdata, ent_we, ent_data, i_rst_n, i_clk);

register #(1) r_pipeO_VALI(o_val,  1'b1, ent_val, i_rst_n, i_clk);
register      r_pipeO_ADDR(o_addr, 1'b1, ent_rd,  i_rst_n, i_clk);
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

