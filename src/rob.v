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
            input  [4*WIDTH_BANK-1:0] i_rst4x_valtg,
            input  [4*WIDTH_BANK-1:0] i_rst4x_busytg,
            input                     i_rst_n,
            input                     i_clk);

localparam NBANK = 4;
localparam integer SIZE = $pow(2, WIDTH_BANK);

wire [WIDTH-1:0] new_data[0:NBANK-1];
wire [WIDTH-1:0] commit[0:NBANK-1];

wire [6:0]           dis_uops[0:NBANK-1];
wire [WIDTH_BRM-1:0] dis_mask[0:NBANK-1];

wire [WIDTH_REG-1:0] com_prd[0:NBANK-1];
wire                 com_val[0:NBANK-1];

wire we, re;
wire [SIZE-1:0] head, tail;

assign re = ~com_val[3] & ~com_val[2] & ~com_val[1] & ~com_val[0];
assign we = i_dis_we;

// output
assign o_com_prd4x = { com_prd[3], com_prd[2], com_prd[1], com_prd[0] };
assign o_com_en = re;

ringbuf m_pc_b(.o_data(),
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
		assign com_val[i] = commit[i][WIDTH-1];
		assign com_prd[i] = commit[i][WIDTH_BRM+WIDTH_REG-1:WIDTH_BRM];

		bank m_inst_b(.o_data(commit[i]),
		              .i_head(head),
		              .i_tail(tail),
		              .i_data(new_data[i]),
		              .i_re(re),
		              .i_we(we),
		              .i_rst_n(i_rst_n),
		              .i_clk(i_clk));
		defparam m_inst_b.WIDTH = WIDTH;
		defparam m_inst_b.SIZE = SIZE;
		defparam m_inst_b.WIDTH_REG = WIDTH_REG;
		defparam m_inst_b.WIDTH_BRM = WIDTH_BRM;
	end
endgenerate

encoder m_encoder(.o_q(o_dis_tag),
                  .i_d(tail));
defparam m_encoder.SIZE = SIZE;

endmodule


module bank #(parameter WIDTH = 13, SIZE = 20, WIDTH_REG = 7, WIDTH_BRM = 4)
            (output [WIDTH-1:0]   o_data,
             input  [SIZE-1:0]    i_head, i_tail,
             input  [WIDTH-1:0]   i_data,
             input  [WIDTH_BRM:0] i_killmask, // { enkill, brmask }
             input                i_rst_busy,
             //input  i_rst_val, i_rst_busy, i_set_exc,
             input  i_re, i_we, i_rst_n, i_clk);

localparam WIDTH_DT = WIDTH - 1 - WIDTH_BRM;
wire [WIDTH-1:0] data[0:SIZE-1];
wire [SIZE-1:0]  clear, en_busy, rst_busy;

// output

/**
 * kill logic
 */


/**
 * clean busy bit
 */
assign rst_busy = 1 << i_rst_busy;

generate
	genvar i;
	for (i = 0; i < SIZE; i = i + 1) begin
		slot m_slot(.o_q    (brmask[i]),
		            .i_d    (new_brmask),
		            .i_en   (i_head[i]),
		            .i_rst_n(i_rst_n),
		            .i_clk  (i_clk));
		defparam m_slot.WIDTH_REG = WIDTH_REG;
		defparam m_slot.WIDTH_BRM = WIDTH_BRM;
	end
endgenerate

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


// slot
module slot #(parameter  SIZE = 8, WIDTH_REG = 7, WIDTH_BRM = 4)
            (output [WIDTH_DT-1:0] i_data, 
             input                 i_rst_n, i_clk);

wire new_val;
wire [WIDTH_DT-1:0] new_data;
wire [WIDTH_BRM-1:0] new_brmask;

wire [WIDTH_BRM-1:0] killmask;
wire                 enkill;

wire [WIDTH_BRM-1:0] brmask;


assign enkill = i_killmask[WIDTH_BRM];
assign killmask = i_killmask[WIDTH_BRM-1:0];

assign new_val = i_data[WIDTH_DT-1];
assign new_data = i_data[WIDTH_DT-2:WIDTH_BRM];
assign new_brmask = i_data[WIDTH_BRM-1:0];

assign clear = brkill(enkill, killmask, brmask[i], brmask[i]);

assign en_busy = i_tail | rst_busy;

register #(1) r_val(.o_q    (val),
                    .i_d    (new_val),
                    .i_en   (i_tail | clear),
                    .i_rst_n(i_rst_n),
                    .i_clk  (i_clk));

register #(1) r_busy(.o_q    (busy),
                     .i_d    (1'b1),
                     .i_en   (i_head),
                     .i_rst_n(i_rst_n),
                     .i_clk  (i_clk));

register r_data(.o_q    (data),
                .i_d    (new_data),
                .i_en   (i_tail),
                .i_rst_n(i_rst_n),
                .i_clk  (i_clk));
defparam r_data.WIDTH = WIDTH_DT;

register r_brmask(.o_q    (brmask),
                  .i_d    (new_brmask),
                  .i_en   (i_head),
                  .i_rst_n(i_rst_n),
                  .i_clk  (i_clk));
defparam r_brmask.WIDTH = WIDTH_BRM;

endmodule

