/**
 * dis_data = { val, uop, imm, prd, mask }
 */
module rob #(parameter WIDTH_BANK = 3, WIDTH_REG = 7, WIDTH_BRM = 4,
                       WIDTH = 2 + 7 + 2*WIDTH_REG + WIDTH_BRM)
           (output [WIDTH_BANK-1:0]   o_dis_tag,
            output [4*WIDTH_REG-1:0]  o_com_prd4x,
            output [32-1:0]           o_pc0, o_pc1, o_pc2, o_pc3, o_pcbr,
            output [4-1:0]            o_com_en,
            output                    o_overflow,
            input  [WIDTH_BANK+2-1:0] i_tag0, i_tag1, i_tag2, i_tag3,
            input  [31:0]             i_dis_pc,
            input  [4*WIDTH-1:0]      i_dis_data4x,
            input                     i_dis_we,
            input  [(2 ** WIDTH_BRM)-1:0] i_brkill,
            input  [3+WIDTH_BANK-1:0] i_rst_busy0,
            input  [3+WIDTH_BANK-1:0] i_rst_busy1,
            input  [3+WIDTH_BANK-1:0] i_rst_busy2,
            input  [3+WIDTH_BANK-1:0] i_rst_busy3,
            input                     i_rst_n,
            input                     i_clk);

localparam WIDTH_NBANK = 2;
localparam NBANK = 4;
localparam WIDTH_DT = WIDTH - 2 - WIDTH_BRM;
localparam SIZE = 2 ** WIDTH_BANK;

wire [WIDTH-1:0] new_data[0:NBANK-1];
wire [WIDTH-1:0] commit[0:NBANK-1];

wire [6:0]           dis_uops[0:NBANK-1];
wire [WIDTH_BRM-1:0] dis_mask[0:NBANK-1];

wire [WIDTH_REG-1:0] com_prd[0:NBANK-1];
wire [WIDTH_REG-1:0] prdo[0:NBANK-1], prdn[0:NBANK-1];
wire                 com_val[0:NBANK-1];
wire                 com_busy[0:NBANK-1];
wor  [SIZE-1:0]      rst_busy[0:NBANK-1];

wire [SIZE-1:0] val[0:NBANK-1];
reg  [2-1:0]     ni;

wire we;
wand re;
wire [SIZE-1:0] head, tail;
wire [32-1:4] PC[0:SIZE-1];
wire empty;

// output
assign o_com_prd4x = { com_prd[3], com_prd[2], com_prd[1], com_prd[0] };

assign o_pc0 = { PC[i_tag0[WIDTH_BANK+2-1:2]], i_tag0[1:0], 2'b0 };
assign o_pc1 = { PC[i_tag1[WIDTH_BANK+2-1:2]], i_tag1[1:0], 2'b0 };
assign o_pc2 = { PC[i_tag2[WIDTH_BANK+2-1:2]], i_tag2[1:0], 2'b0 };
assign o_pc3 = { PC[i_tag3[WIDTH_BANK+2-1:2]], i_tag3[1:0], 2'b0 };

// read next pc
wire [2:0] tgN = i_tag1[WIDTH_BANK+2-1:2] + 1;
always @(*)
begin
	casex({ val[3][tgN], val[2][tgN], val[1][tgN], val[0][tgN] })
		4'b0001: ni = 2'b11;
		4'b001?: ni = 2'b10;
		4'b01??: ni = 2'b01;
		4'b1???: ni = 2'b00;
	endcase
end
assign o_pcbr = { PC[tgN], ni, 2'b0 };

assign we = i_dis_we;

ringbuf m_pc_b(.o_data(),
               .o_empty(empty),
               .o_overflow(o_overflow),
               .i_data(i_dis_pc[31:4]),
               .i_re(re),
               .i_we(we),
               .i_rst_n(i_rst_n),
               .i_clk(i_clk));
defparam m_pc_b.WIDTH = 32 - 4;
defparam m_pc_b.SIZE = SIZE;

assign head = m_pc_b.head;
assign tail = m_pc_b.tail;

generate
	genvar i, j;

	assign re = ~empty;
	for (i = 0; i < NBANK; i = i + 1) begin: _bank
		// val exc uops prd brmask
		assign new_data[i] = i_dis_data4x[(i+1)*WIDTH-1:i*WIDTH];

		assign rst_busy[i] = rstBusy(i_rst_busy0, i[1:0]);
		assign rst_busy[i] = rstBusy(i_rst_busy1, i[1:0]);
		assign rst_busy[i] = rstBusy(i_rst_busy2, i[1:0]);
		assign rst_busy[i] = rstBusy(i_rst_busy3, i[1:0]);

		bank m_inst_b(.o_pkg(commit[i]),
		              .o_val(val[i]),
		              .i_pkg(new_data[i]),
		              .i_head(head),
		              .i_tail(tail),
	                      .i_brkill(i_brkill),
		              .i_re(re),
		              .i_we(we),
		              .i_rst_busy(rst_busy[i]),
		              .i_rst_n(i_rst_n),
		              .i_clk(i_clk));
		defparam m_inst_b.SIZE      = SIZE;
		defparam m_inst_b.WIDTH_DT  = WIDTH_DT;
		defparam m_inst_b.WIDTH_REG = WIDTH_REG;
		defparam m_inst_b.WIDTH_BRM = WIDTH_BRM;
		defparam m_inst_b.WIDTH     = WIDTH;

		// read valid and busy bits
		assign com_val[i]  = commit[i][WIDTH-1];
		assign com_busy[i] = commit[i][WIDTH-2];
		// read the old and new renamed register
		assign { prdo[i], prdn[i] } = commit[i][WIDTH_BRM+2*WIDTH_REG-1:WIDTH_BRM];
		// check en commit
		assign re = ~(com_val[i] & com_busy[i]);
		// check for zero address
		assign o_com_en[i] = re & |com_prd[i];

		// select the register to commit
		// val  == 0 ? new renamed register
		// busy == 0 ? old renamed register
		mux2in1 m_comprd(com_prd[i],
			com_val[i], prdn[i], prdo[i] );
		defparam m_comprd.WIDTH = WIDTH_REG;
	end
	for (i = 0; i < SIZE; i = i + 1) begin: PC_read
		assign PC[i] = m_pc_b.slot[i].r_data.data;
	end
endgenerate

function [SIZE-1:0] rstBusy(
	input [3+WIDTH_BANK-1:0] i_rst_busytg,
	input [WIDTH_NBANK-1:0]  i_NBank);
	reg                   en;
	reg [WIDTH_BANK-1:0]  tag;
	reg [WIDTH_NBANK-1:0] bank;
	begin
		rstBusy = { SIZE{1'b0} };
		{ en, tag, bank } = i_rst_busytg;

		if (i_NBank == bank && en)
			rstBusy = 1 << tag;

	end
endfunction

encoder m_encoder(.o_q(o_dis_tag),
                  .i_en(1'b1),
                  .i_d(tail));
defparam m_encoder.SIZE = SIZE;

endmodule

/**
 * bank
 */
module bank #(parameter SIZE = 32, WIDTH_DT = 39, WIDTH_REG = 7, WIDTH_BRM = 4,
                        WIDTH = 2 + WIDTH_DT + WIDTH_BRM)
            (output [WIDTH-1:0]   o_pkg,
             output [SIZE-1:0]    o_val,
             input  [WIDTH-1:0]   i_pkg,
             input  [SIZE-1:0]    i_head, i_tail,
             input  [(2 ** WIDTH_BRM)-1:0] i_brkill,
             input  [SIZE-1:0]    i_rst_busy,
             input  i_re, i_we, i_rst_n, i_clk);

wire [WIDTH-1:0] pkg[0:SIZE-1];
wor  [WIDTH-1:0] pkg_head;

// output
assign o_pkg = pkg_head;

generate
	genvar i;
	for (i = 0; i < SIZE; i = i + 1) begin: _slot
		assign pkg_head = pkg[i];

		assign o_val[i] = pkg[i][WIDTH-1];

		bankSlot m_slot(.o_pkg(pkg[i]),
		                .i_pkg(i_pkg),
		                .i_brkill(i_brkill),
		                .i_re(i_head[i]),
		                .i_we(i_tail[i] & i_we),
		                .i_rst_busy(i_rst_busy[i]),
		                .i_rst_n(i_rst_n),
		                .i_clk (i_clk));
		defparam m_slot.WIDTH_DT  = WIDTH_DT;
		defparam m_slot.WIDTH_REG = WIDTH_REG;
		defparam m_slot.WIDTH_BRM = WIDTH_BRM;
		defparam m_slot.WIDTH     = WIDTH;
	end
endgenerate

endmodule

/**
 * slot
 */
module bankSlot #(parameter WIDTH_DT = 39, WIDTH_REG = 7, WIDTH_BRM = 4,
                        WIDTH = 2 + WIDTH_DT + WIDTH_BRM)
            (output [WIDTH-1:0]     o_pkg, 
             input  [WIDTH-1:0]     i_pkg, 
             input  [(2 ** WIDTH_BRM)-1:0] i_brkill,
             input                  i_re, i_we,
             input                  i_rst_busy,
             input                  i_rst_n, i_clk);

`include "src/killf.v"

wire                 val,    val_new, val_rst;
wire                 busy,   busy_new;
wire [WIDTH_DT-1:0]  data,   data_new;
wire [WIDTH_BRM-1:0] brmask, brmask_new;

// output
assign o_pkg = i_re ? { val, busy, data, brmask } : { WIDTH{1'b0} };

assign val_new = i_pkg[WIDTH_DT+WIDTH_BRM+1];
assign val_rst = killf(brmask, i_brkill);
/*
reg [(2 ** WIDTH_BRM)-1:0] dmask;
reg killf;

assign val_rst = killf;

always @(brmask, i_brkill)
begin
	//dmask = 1 << brmask;
	dmask = brmask;
	killf = |(dmask & i_brkill);
end
*/

assign busy_new = i_pkg[WIDTH_DT+WIDTH_BRM];

assign data_new   = i_pkg[WIDTH_DT+WIDTH_BRM-1:WIDTH_BRM];
assign brmask_new = i_pkg[WIDTH_BRM-1:0];

sreg #(1) r_val(.o_q    (val),
                .i_d    (val_new),
                .i_en   (i_we),
                .i_srsh (val_rst),
                .i_rst_n(i_rst_n),
                .i_clk  (i_clk));

sreg #(1) r_busy(.o_q    (busy),
                 .i_d    (busy_new),
                 .i_en   (i_we),
                 .i_srsh (i_rst_busy),
                 .i_rst_n(i_rst_n),
                 .i_clk  (i_clk));

register r_data(.o_q    (data),
                .i_d    (data_new),
                .i_en   (i_we),
                .i_rst_n(i_rst_n),
                .i_clk  (i_clk));
defparam r_data.WIDTH = WIDTH_DT;

register r_brmask(.o_q    (brmask),
                  .i_d    (brmask_new),
                  .i_en   (i_we),
                  .i_rst_n(i_rst_n),
                  .i_clk  (i_clk));
defparam r_brmask.WIDTH = WIDTH_BRM;

endmodule

