/**
 * dis_data = { val, uop, imm, prd, mask }
 */
module rob #(parameter WIDTH_BANK = 3, WIDTH_REG = 7, WIDTH_BRM = 4,
                       WIDTH = 2 + 7 + 32 + WIDTH_REG + WIDTH_BRM)
           (output [WIDTH_BANK-1:0]   o_dis_tag,
            output [4*WIDTH_REG-1:0]  o_com_prd4x,
            output                    o_com_en,
            input  [31:0]             i_dis_pc,
            input  [4*WIDTH-1:0]      i_dis_data4x,
            input                     i_dis_we,
            input  [WIDTH_BRM:0]      i_kill,
            input  [3+WIDTH_BANK-1:0] i_rst_busy0,
            input  [3+WIDTH_BANK-1:0] i_rst_busy1,
            input  [3+WIDTH_BANK-1:0] i_rst_busy2,
            input  [3+WIDTH_BANK-1:0] i_rst_busy3,
            input                     i_rst_n,
            input                     i_clk);

localparam NBANK = 4;
localparam WIDTH_DT = WIDTH - 2 - WIDTH_BRM;
localparam integer SIZE = $pow(2, WIDTH_BANK);

localparam integer WIDTH_RSTB = 1 + WIDTH_BANK + $clog2(NBANK);

wire [WIDTH-1:0] new_data[0:NBANK-1];
wire [WIDTH-1:0] commit[0:NBANK-1];

wire [6:0]           dis_uops[0:NBANK-1];
wire [WIDTH_BRM-1:0] dis_mask[0:NBANK-1];

wire [WIDTH_REG-1:0] com_prd[0:NBANK-1];
wire                 com_val[0:NBANK-1];
wor  [SIZE-1:0]      rst_busy[0:NBANK-1];

wire we, re;
wire [SIZE-1:0] head, tail;
wire empty;

// output
assign o_com_prd4x = { com_prd[3], com_prd[2], com_prd[1], com_prd[0] };
assign o_com_en = re;

assign re = ~empty & ~com_val[3] & ~com_val[2] & ~com_val[1] & ~com_val[0];
assign we = i_dis_we;

ringbuf m_pc_b(.o_data(),
               .o_empty(empty),
               .i_data(i_dis_pc[31:2]),
               .i_re(re),
               .i_we(we),
               .i_rst_n(i_rst_n),
               .i_clk(i_clk));
defparam m_pc_b.WIDTH = 32 - 2;
defparam m_pc_b.SIZE = SIZE;

assign head = m_pc_b.head;
assign tail = m_pc_b.tail;

generate
	genvar i;
	for (i = 0; i < NBANK; i = i + 1) begin
		// val exc uops prd brmask
		assign new_data[i] = i_dis_data4x[(i+1)*WIDTH-1:i*WIDTH];
		assign com_val[i] = commit[i][WIDTH-2];
		assign com_prd[i] = commit[i][WIDTH_BRM+WIDTH_REG-1:WIDTH_BRM];

		assign rst_busy[i] = rstBusy(i_rst_busy0, i[1:0]);
		assign rst_busy[i] = rstBusy(i_rst_busy1, i[1:0]);
		assign rst_busy[i] = rstBusy(i_rst_busy2, i[1:0]);
		assign rst_busy[i] = rstBusy(i_rst_busy3, i[1:0]);

		bank m_inst_b(.o_pkg(commit[i]),
		              .i_pkg(new_data[i]),
		              .i_head(head),
		              .i_tail(tail),
	                      .i_killMask(i_kill),
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
	end
endgenerate

function [SIZE-1:0] rstBusy(
	input [3+WIDTH_BANK-1:0]  i_rst_busytg,
	input [$clog2(NBANK)-1:0] i_NBank);
	reg                     en;
	reg [WIDTH_BANK-1:0]    tag;
	reg [$clog2(NBANK)-1:0] bank;
	begin
		rstBusy = { SIZE{1'b0} };
		{ en, tag, bank } = i_rst_busytg;

		if (i_NBank == bank && en)
			rstBusy = 1 << tag;

	end
endfunction

encoder m_encoder(.o_q(o_dis_tag),
                  .i_d(tail));
defparam m_encoder.SIZE = SIZE;

endmodule


/**
 * bank
 */
module bank #(parameter SIZE = 32, WIDTH_DT = 39, WIDTH_REG = 7, WIDTH_BRM = 4,
                        WIDTH = 2 + WIDTH_DT + WIDTH_BRM)
            (output [WIDTH-1:0]   o_pkg,
             input  [WIDTH-1:0]   i_pkg,
             input  [SIZE-1:0]    i_head, i_tail,
             input  [WIDTH_BRM:0] i_killMask, // { enkill, brmask }
             input  [SIZE-1:0]    i_rst_busy,
             input  i_re, i_we, i_rst_n, i_clk);

integer j;

wire [WIDTH-1:0]      pkg[0:SIZE-1];
reg  [WIDTH-1:0]      pkg_head;

wire                 killEn;
wire [WIDTH_BRM-1:0] killMask;

wire            rstEn;
wire [SIZE-1:0] rstBusy;

// output
assign o_pkg = pkg_head;

/**
 * kill logic
 */
assign killEn   = i_killMask[WIDTH_BRM];
assign killMask = i_killMask[WIDTH_BRM-1:0];

generate
	genvar i;
	for (i = 0; i < SIZE; i = i + 1) begin
		bankSlot m_slot(.o_pkg(pkg[i]),
		                .i_pkg(i_pkg),
		                .i_killMask(killMask),
		                .i_killEn(killEn),
		                .i_re(i_head[i]),
		                .i_we(i_tail[i]),
		                .i_rst_busy(i_rst_busy[i]),
		                .i_rst_n(i_rst_n),
		                .i_clk (i_clk));
		defparam m_slot.WIDTH_DT  = WIDTH_DT;
		defparam m_slot.WIDTH_REG = WIDTH_REG;
		defparam m_slot.WIDTH_BRM = WIDTH_BRM;
		defparam m_slot.WIDTH     = WIDTH;
	end
endgenerate

always @(*)
begin
	pkg_head = { WIDTH{1'b0} };
	for (j = 0; j < SIZE; j = j + 1) begin
		pkg_head |= pkg[j];
	end
end

endmodule


/**
 * slot
 */
module bankSlot #(parameter WIDTH_DT = 39, WIDTH_REG = 7, WIDTH_BRM = 4,
                        WIDTH = 2 + WIDTH_DT + WIDTH_BRM)
            (output [WIDTH-1:0]     o_pkg, 
             input  [WIDTH-1:0]     i_pkg, 
             input  [WIDTH_BRM-1:0] i_killMask,
             input                  i_killEn,
             input                  i_re, i_we,
             input                  i_rst_busy,
             input                  i_rst_n, i_clk);

wire [WIDTH-1:0]  pkg;

wire                 val,    val_new, val_rst;
wire                 busy,   busy_new;
wire [WIDTH_DT-1:0]  data,   data_new;
wire [WIDTH_BRM-1:0] brmask, brmask_new;

// output
assign o_pkg = i_re ? pkg : { WIDTH{1'b0} };


assign pkg = { val, busy, data, brmask };

assign val_new = i_pkg[WIDTH_DT+WIDTH_BRM+1];
assign val_rst = brkill(i_killEn, i_killMask, brmask, brmask);

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

// fun
function brkill(input                 kill_en,
                input [WIDTH_BRM-1:0] kill_mask, mask, last_mask);
begin
	brkill = 1'b0;
	if (kill_en) begin
		if (kill_mask < last_mask) begin // normal count
			if (kill_mask < mask && mask <= last_mask)
				brkill = 1'b1;
		end
		else begin // reset counter
			if (kill_mask < mask || mask < last_mask)
				brkill = 1'b1;
		end
	end
end
endfunction

endmodule

// register with synchronous reset
module sreg #(parameter WIDTH=32)
            (output reg [WIDTH-1:0] o_q,
             input wire [WIDTH-1:0] i_d,
             input i_en, i_srsh, i_rst_n, i_clk);

always @(posedge i_clk, negedge i_rst_n)
begin
	if (!i_rst_n)
		o_q <= { WIDTH{1'b0} };
	else if (i_srsh) begin
		o_q <= { WIDTH{1'b0} };
	end else begin
		if (i_en)
			o_q <= i_d;
	end
end

endmodule

