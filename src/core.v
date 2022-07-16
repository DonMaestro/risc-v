module core #(parameter ADDR_MEM_WIDTH = 32)
            (output [31:0] o_data,
             output [ADDR_MEM_WIDTH - 1:0] o_DcacheAddr, o_IcacheAddr,
             output   o_we,
             input  [31:0] i_DcacheData, i_IcacheData,
             input    i_rst_n,
	     input    i_clk);

wire clk = i_clk;
wire rst_n = i_rst_n;

localparam WIDTH_PRD = 7;
localparam WIDTH_BRM = 3;
localparam WIDTH_TAG = 3;
//localparam WIDTH_QUEUE_O = WIDTH_BRM + WIDTH_TAG + 2 + 3*WIDTH_PRD + 0;
localparam WIDTH_QUEUE_O = m_issue_alu.WIDTH_O;
//assign { val, uop, brmask, rd, pc, func, imm, op2, op1 } = instr;
localparam W_I_EXEC = 1 + 7 + WIDTH_BRM + WIDTH_PRD + 10 + 4*32;

// kill function
`include "src/killf.v"

reg en_core;

wire [31:0] newPC, nextPC, rPC;
wire        w_AdrSrc;
wire [31:0] PC, PCx;
wire [4*32-1:0] dataIC4x;

// wire decode
reg             en_dec;
wire            en_decode;
wire [4*32-1:0] Inst4x;
wire [  32-1:0] Instr[0:3];
reg  [4-1:0]    Imask;

wire [3*5-1:0]         rg[0:3];
wire [10-1:0]          func[0:3];
wire [5-1:0]           ctrl[0:3];
wire [32-1:0]          imm[0:3];
wire [7-1:0]           uop[0:3];

wire                   en_bm[0:4];
wire [WIDTH_BRM-1:0]   brmask[0:4];

reg [3:0] save_mask;
reg       save_en;
wire      maptb_busy;

// wire rename
reg                    en_ren;
wire                   en_rename1, en_rename2;
wire [WIDTH_TAG-1:0]   tagPkg; 

wire [7-1:0]           uoprg1[0:3],    uoprg2[0:3];
wire [10-1:0]          funcrg1[0:3];//,   funcrg2[0:3];
wire [5-1:0]           ctrlrg1[0:3],   ctrlrg2[0:3];
wire [32-1:0]          immrg1[0:3];//,    immrg2[0:3];
wire [WIDTH_BRM-1:0]   brmaskrg1[0:3], brmaskrg2[0:3];
wire [WIDTH_TAG-1:0]                   tagrg2;
wire [32-1:0]          PCrg1;

wire [3*WIDTH_PRD-1:0] prgs[0:3];
wire [WIDTH_PRD-1:0]   prs2[0:3], prs1[0:3];
wire [WIDTH_PRD-1:0]   prd[0:3];

reg                      we_rob;
wire [m_rob.WIDTH-1:0]   pkg_rob[0:3];
wire [4*m_rob.WIDTH-1:0] data4x;

wire                   overflow_rob;
wire [3:0]             enflist, com_en;
wire [4*WIDTH_PRD-1:0] com_prd4x, freelist4x;
wire [WIDTH_PRD-1:0]   freelist[0:3];
wire [WIDTH_PRD-1:0]   com_prd[0:3];
wire [4*WIDTH_PRD-1:0] prdo4x;
wire [WIDTH_PRD-1:0]   prdo[0:3];

// busy table
wire [2-1:0]           p2x[0:3];
wire [4*WIDTH_PRD-1:0] setBusy4x;

// wire issue queue
reg                            we_que;
wire                           en_queue;
wire [m_issue_alu.WIDTH_O-1:0] issue[0:2];
wire [m_issue_mem.WIDTH_I-1:0] issmem[0:3];
wire [m_issue_alu.WIDTH_I-1:0] issalu[0:3];
wire [2:0] valmem[0:3], valalu[0:3];
wire [4*WIDTH_PRD-1:0] wdest4x;

wire [3-1:0] ready;

// wire regFile
wire [3-1:0]         ready_reg;
wire [WIDTH_QUEUE_O-1:0] instr[0:2];

wire [3-1:0]           Ival;
wire [WIDTH_PRD-1:0]   PRD[0:2];
wire [7-1:0]           UOPCode[0:2];
wire [WIDTH_BRM-1:0]   BrMask[0:2];
wire [WIDTH_TAG+2-1:0] Tag[0:2];

wire [32-1:0]          PC_ROB[0:2];
wire [32-1:0]          PCtoBR;
wire [32+10-1:0]       Func_Imm[0:2];

wire [WIDTH_PRD-1:0]   waddr[0:2];
wire [32-1:0]          DPS[0:5];
wire [7-1:0]           PRS1[0:2];
wire [7-1:0]           PRS2[0:2];

wire [W_I_EXEC-1:0] pkg[0:3];

// wire alu
wire [$pow(2, WIDTH_BRM)-1:0] brkill;
wire [2*32-1:0]       DPS2x[0:2];
wire [32+WIDTH_PRD:0] bppkg[0:6];

wire [32-1:0]        wdata0, wdata1, wdata2;
wire [WIDTH_PRD-1:0] waddr1, waddr2, waddr0;
wire                 we0,    we1,    we2;

/* main block */

// control
wire overflow_que = 1'b0;
always @(*)
begin
	en_core = ~overflow_rob & ~overflow_que;
	en_dec = en_core & ~w_AdrSrc & en_decode;
	en_ren = en_core & ~w_AdrSrc & en_rename1;
	we_rob = en_core & ~w_AdrSrc & en_rename2;
	we_que = en_core & ~w_AdrSrc & en_queue;
end

/* FrontEnd */

mux2in1 mux_PC(.o_dat(newPC),
               .i_control(w_AdrSrc), 
               .i_dat0(nextPC),
               .i_dat1(rPC)); 
defparam mux_PC.WIDTH = 32;

assign nextPC = { (PC[31:4] + 28'h1), 4'b0000 };

register r_PC (PC, en_core | w_AdrSrc, newPC, rst_n, clk);

/* MEM */
icache_m m_icache(dataIC4x, PC[11:0]);
defparam m_icache.WIDTH = 12;

/*
ram m_fetchBuff(.o_data(ReadData),
                .i_we(), 
                .i_data(B), 
                .i_clk(clk));
*/

sreg #(1) r_en_dec(en_decode, en_core, 1'b1, w_AdrSrc, rst_n, clk);
register r_PCx    (PCx,       en_core, PC, rst_n, clk);
register r_instr  (Inst4x,    en_core, dataIC4x, rst_n, clk);
defparam r_instr.WIDTH = 32 * 4;

//
// Decode state
//
// rg = { drd, drs2, drs1 }
//

always @(PCx)
begin
	case(PCx[3:2])
		2'b00: Imask = 4'b1111;
		2'b01: Imask = 4'b1110;
		2'b10: Imask = 4'b1100;
		2'b11: Imask = 4'b1000;
	endcase
end

sreg #(1) r_en_j  (en_bm[0], en_core, en_bm[4], ~w_AdrSrc,  rst_n, clk);
register      r_brmask(brmask[0], en_core, brmask[4], rst_n, clk);
defparam r_brmask.WIDTH = WIDTH_BRM;

generate
	genvar i;

	for (i = 0; i < 4; i = i + 1) begin: decode
		assign Instr[i] = Inst4x[(i+1)*32-1:i*32];

		decode m_decode(.o_uop   (uop[i]),
		                .o_regs  (rg[i]),
		                .o_func  (func[i]),
		                .o_ctrl  (ctrl[i]),
		                .o_imm   (imm[i]),
		                .o_en_j  (en_bm[i+1]),
		                .o_brmask(brmask[i+1]),
		                .i_en_j  (en_bm[i]),
		                .i_brmask(brmask[i]),
		                .i_en    (en_dec),
		                .i_instr (Instr[i]),
		                .i_imask (Imask[i]));
		defparam m_decode.WIDTH_BRM = WIDTH_BRM;
	end
endgenerate

always @(*)
begin
	save_mask = { en_bm[4], en_bm[3], en_bm[2], en_bm[1] };
	save_en = |save_mask & ~maptb_busy;
	case(save_mask)
		4'b0001: save_mask = 4'b0001;
		4'b0010: save_mask = 4'b0011;
		4'b0100: save_mask = 4'b0111;
		4'b1000: save_mask = 4'b1111;
		default: save_mask = 4'b1111;
	endcase
end

/* Execute */

//
// rename state
//      
// uop  tag  rd, rs2, rs1    rename1
// ---  ---  ------------  ---------  register
// uop  tag  rd, rs2, rs1  prd4x_old  rename2
// ---  ---  ------------  ---------  register
// issue state
//
// wire rd4x -> maptab -> wire prd4x_old -> rob
//

//register #(1) r_en_rename1(en_rename1, 1'b1, en_decode, rst_n, clk);
assign en_rename1 = en_decode;

generate
	genvar r;

	freelist m_freelist(.o_data (freelist[0]),
	                    .i_data (com_prd[0]),
	                    .i_re   (enflist[0]),
	                    .i_we   (com_en[0]),
	                    .i_rst_n(rst_n),
	                    .i_clk  (clk));
	defparam m_freelist.WIDTH = WIDTH_PRD;
	defparam m_freelist.SIZE  = $pow(2, WIDTH_PRD - 2) - 1;
	defparam m_freelist.STNUM = 1;

	for (r = 1; r < 4; r = r + 1) begin: flist
		freelist m_freelist(.o_data (freelist[r]),
		                    .i_data (com_prd[r]),
		                    .i_re   (enflist[r]),
		                    .i_we   (com_en[r]),
		                    .i_rst_n(rst_n),
		                    .i_clk  (clk));
		defparam m_freelist.WIDTH = WIDTH_PRD;
		defparam m_freelist.SIZE = $pow(2, WIDTH_PRD - 2);
		defparam m_freelist.STNUM = r * $pow(2, WIDTH_PRD - 2);
	end

	for (r = 0; r < 4; r = r + 1) begin
		assign com_prd[r] = com_prd4x[(r+1)*WIDTH_PRD-1:r*WIDTH_PRD];
		assign freelist4x[(r+1)*WIDTH_PRD-1:r*WIDTH_PRD] = freelist[r];

		assign { prd[r], prs2[r], prs1[r] } = prgs[r];
	end

	register #(32) r_pcrg1(PCrg1, en_core, PCx, rst_n, clk);
	for (r = 0; r < 4; r = r + 1) begin
		register #(10) r_funcrg1(funcrg1[r], en_core,
		                         func[r], rst_n, clk);
		register #(5) r_ctrlrg1(ctrlrg1[r], en_core,
		                        ctrl[r], rst_n, clk);
		register #(32) r_immrg1(immrg1[r], en_core,
		                        imm[r], rst_n, clk);
		register r_brmaskrg1(brmaskrg1[r], en_core,
		                     brmask[r+1], rst_n, clk);
		defparam r_brmaskrg1.WIDTH = WIDTH_BRM;
		register #(7) r_uoprg1(uoprg1[r], en_core,
		                       uop[r], rst_n, clk);
 
		assign prdo[r] = prdo4x[(r+1)*WIDTH_PRD-1:r*WIDTH_PRD];
		assign pkg_rob[r] = {ctrlrg1[r][0], 1'b1, uoprg1[r],
		                     prdo[r], m_rename.prd[r], brmaskrg1[r] };
		assign data4x[(r+1)*m_rob.WIDTH-1:r*m_rob.WIDTH] = pkg_rob[r];

//register #(10) r_funcrg2(funcrg2[r], en_rename2, funcrg1[r], rst_n, clk);
		register #(5) r_ctrlrg2(ctrlrg2[r], en_core,
		                        ctrlrg1[r], rst_n, clk);
//register #(32) r_immrg2(immrg2[r], en_rename2, immrg1[r], rst_n, clk);
		register r_brmaskrg2(brmaskrg2[r], en_core,
		                     brmaskrg1[r], rst_n, clk);
		defparam r_brmaskrg2.WIDTH = WIDTH_BRM;
//		register #(7) r_uoprg2(uoprg2[r], en_core,
//		                       uoprg1[r], rst_n, clk);
		register r_tagrg2(tagrg2, en_core, tagPkg, rst_n, clk);
		defparam r_tagrg2.WIDTH = WIDTH_TAG;

	end
endgenerate

rename m_rename(.o_prg1(prgs[0]),
                .o_prg2(prgs[1]),
                .o_prg3(prgs[2]),
                .o_prg4(prgs[3]),
                .o_mtab(prdo4x),        // for commit
                .o_enfreelist(enflist),    // enable read freelist
                .o_busy(maptb_busy),
                .i_rg1(rg[0]),
                .i_rg2(rg[1]),
                .i_rg3(rg[2]),
                .i_rg4(rg[3]),
                .i_freelist(freelist4x),
                .i_save_mask(save_mask),
                .i_save_en(save_en),
                .i_return(w_AdrSrc),
                .i_en(en_ren),
                .i_rst_n(rst_n),
                .i_clk(clk));
defparam m_rename.WIDTH_PRD = WIDTH_PRD;

sreg #(1) r_en_rename2(en_rename2, en_core, en_rename1, w_AdrSrc, rst_n, clk);

// rob
// dis_data = { val, uop, imm, prd, mask }
rob m_rob(.o_dis_tag(tagPkg),
          .o_pc0(PC_ROB[0]),
          .o_pc1(PC_ROB[1]),
          .o_pc2(PC_ROB[2]),
          .o_pc3(),
          .o_pcbr(PCtoBR),
          .o_com_prd4x(com_prd4x),
          .o_com_en(com_en),
          .o_overflow(overflow_rob),
          .i_tag0(Tag[0]),
          .i_tag1(Tag[1]),
          .i_tag2(Tag[2]),
          .i_tag3(5'b0),
          .i_dis_pc(PCrg1),
          .i_dis_data4x(data4x),
          .i_dis_we(we_rob),
          .i_brkill(brkill),
          .i_rst_busy0({ ready_reg[0], Tag[0] }),
          .i_rst_busy1({ ready_reg[1], Tag[1] }),
          .i_rst_busy2({ ready_reg[2], Tag[2] }),
          .i_rst_busy3(),
          .i_rst_n(rst_n),
          .i_clk(clk));
defparam m_rob.WIDTH_BANK = WIDTH_TAG;
defparam m_rob.WIDTH_REG  = WIDTH_PRD;
defparam m_rob.WIDTH_BRM  = WIDTH_BRM;

// busy table
assign setBusy4x = { m_rename.prd[3], m_rename.prd[2],
                     m_rename.prd[1], m_rename.prd[0] };

busytb m_btab(.o_data1(p2x[0]),
              .o_data2(p2x[1]),
              .o_data3(p2x[2]),
              .o_data4(p2x[3]),
              .i_addr1({ prs2[0], prs1[0] }),
              .i_addr2({ prs2[1], prs1[1] }),
              .i_addr3({ prs2[2], prs1[2] }),
              .i_addr4({ prs2[3], prs1[3] }),
              .i_setAddr4x(setBusy4x),
              .i_rstAddr4x(wdest4x),
              .i_rst_n(i_rst_n),
              .i_clk(clk));
defparam m_btab.WIDTH = WIDTH_PRD;

// queue state

sreg #(1) r_en_queue(en_queue, en_core, en_rename2, w_AdrSrc, rst_n, clk);

wire [WIDTH_PRD-1:0] WDest[0:3];
wire RS1eqWD[0:3][0:3];
wire RS2eqWD[0:3][0:3];
wor checkp1[0:3];
wor checkp2[0:3];

generate
	genvar j, d;
	for (j = 0; j < 4; j = j + 1)
		assign WDest[j] = wdest4x[(j+1)*WIDTH_PRD:j*WIDTH_PRD];

	for (j = 0; j < 4; j = j + 1) begin
		for (d = 0; d < 4; d = d + 1) begin: wdest
			comparator cm_ps1(RS1eqWD[j][d], WDest[d], prs1[j]);
			defparam cm_ps1.WIDTH = WIDTH_PRD;
			comparator cm_ps2(RS2eqWD[j][d], WDest[d], prs2[j]);
			defparam cm_ps2.WIDTH = WIDTH_PRD;

			assign checkp1[j] = RS1eqWD[j][d];
			assign checkp2[j] = RS2eqWD[j][d];
		end

		// valxxx = { val, p2, p1 }
		assign valmem[j] = { ctrlrg2[j][1], ~p2x[j]
		                     | { checkp2[j], checkp1[j] } };
		assign valalu[j] = { ctrlrg2[j][2], ~p2x[j]
		                     | { checkp2[j], checkp1[j] } };
		// issue_slot = { UOPcode, brmask, tag, prd, prs2, prs1, val, p2, p1 };
		assign issmem[j] = { brmaskrg2[j], tagrg2, prgs[j],
		                     1'b0, valmem[j] };
		assign issalu[j] = { brmaskrg2[j], tagrg2, prgs[j],
		                     ctrlrg2[j][4:3], valalu[j] };
	end
endgenerate

queue4in1 m_issue_mem(.o_inst1(issue[0]),
                      .o_ready(ready[0]),
                      .i_inst1(issmem[0]),
                      .i_inst2(issmem[1]),
                      .i_inst3(issmem[2]),
                      .i_inst4(issmem[3]),
                      .i_wdest4x(wdest4x),
                      .i_brkill(brkill),
                      .i_en(we_que),
                      .i_rst_n(rst_n),
                      .i_clk(clk));
defparam m_issue_mem.WIDTH_REG = WIDTH_PRD;
defparam m_issue_mem.WIDTH_TAG = WIDTH_TAG;
defparam m_issue_mem.WIDTH_BRM = WIDTH_BRM;
defparam m_issue_mem.WIDTH_PRY = 1;
defparam m_issue_mem.SIZE = 32;

queue4in2 m_issue_alu(.o_inst1(issue[1]),
                      .o_inst2(issue[2]),
                      .o_ready1(ready[1]),
                      .o_ready2(ready[2]),
                      .i_inst1(issalu[0]),
                      .i_inst2(issalu[1]),
                      .i_inst3(issalu[2]),
                      .i_inst4(issalu[3]),
                      .i_wdest4x(wdest4x),
                      .i_brkill(brkill),
                      .i_en(we_que),
                      .i_rst_n(rst_n),
                      .i_clk(clk));
defparam m_issue_alu.WIDTH_REG = WIDTH_PRD;
defparam m_issue_alu.WIDTH_TAG = WIDTH_TAG;
defparam m_issue_alu.WIDTH_BRM = WIDTH_BRM;
defparam m_issue_alu.WIDTH_PRY = 2;
defparam m_issue_alu.SIZE = 32;

register #(3) r_ready_que(.o_q(ready_reg),
                          .i_en(1'b1),
                          .i_d(ready),
                          .i_rst_n(rst_n),
                          .i_clk(clk));

register r_issue_mem(.o_q(instr[0]),
                     .i_en(ready[0]),
                     .i_d(issue[0]),
                     .i_rst_n(rst_n),
                     .i_clk(clk));
defparam r_issue_mem.WIDTH = WIDTH_QUEUE_O;

register r_issue_alu0(.o_q(instr[1]),
                      .i_en(ready[1]),
                      .i_d(issue[1]),
                      .i_rst_n(rst_n),
                      .i_clk(clk));
defparam r_issue_alu0.WIDTH = WIDTH_QUEUE_O;

register r_issue_alu1(.o_q(instr[2]),
                      .i_en(ready[2]),
                      .i_d(issue[2]),
                      .i_rst_n(rst_n),
                      .i_clk(clk));
defparam r_issue_alu1.WIDTH = WIDTH_QUEUE_O;

// reg state
assign { BrMask[0], Tag[0], PRD[0], PRS2[0], PRS1[0] } = instr[0];
assign { BrMask[1], Tag[1], PRD[1], PRS2[1], PRS1[1] } = instr[1];
assign { BrMask[2], Tag[2], PRD[2], PRS2[2], PRS1[2] } = instr[2];

assign wdest4x = { {WIDTH_PRD{1'b0}}, PRD[2], PRD[1], PRD[0] };

imm4 m_func_imm(.o_rdata0({ UOPCode[0], Func_Imm[0] }),
                .o_rdata1({ UOPCode[1], Func_Imm[1] }),
                .o_rdata2({ UOPCode[2], Func_Imm[2] }),
                .o_rdata3(),
                .i_raddr0(Tag[0]), .i_raddr1(Tag[1]),
                .i_raddr2(Tag[2]), .i_raddr3(Tag[3]),
                .i_we(en_rename2 & ~w_AdrSrc),
                .i_waddr(m_rob.tail),
                .i_wdata0({ uoprg1[0], funcrg1[0], immrg1[0] }),
                .i_wdata1({ uoprg1[1], funcrg1[1], immrg1[1] }),
                .i_wdata2({ uoprg1[2], funcrg1[2], immrg1[2] }),
                .i_wdata3({ uoprg1[3], funcrg1[3], immrg1[3] }),
                .i_clk(clk));
defparam m_func_imm.WIDTH = 7 + 32 + 10;
defparam m_func_imm.WIDTH_ADDR = 5;
//defparam m_func_imm.SIZE  = 32;

// register
regfile4in8 m_regfile(.o_rdata0(DPS[0]),  .o_rdata1(DPS[1]),
                      .o_rdata2(DPS[2]),  .o_rdata3(DPS[3]),
                      .o_rdata4(DPS[4]),  .o_rdata5(DPS[5]),
                      .o_rdata6(),        .o_rdata7(),
                      .i_raddr0(PRS1[0]), .i_raddr1(PRS2[0]),
                      .i_raddr2(PRS1[1]), .i_raddr3(PRS2[1]),
                      .i_raddr4(PRS1[2]), .i_raddr5(PRS2[2]),
                      .i_raddr6(7'b0),    .i_raddr7(7'b0),
                      .i_we0(we0), .i_we1(we1), .i_we2(we2), .i_we3(1'b0),
                      .i_waddr0(waddr0), .i_waddr1(waddr1),
                      .i_waddr2(waddr2), .i_waddr3(),
                      .i_wdata0(wdata0), .i_wdata1(wdata1),
                      .i_wdata2(wdata2), .i_wdata3(),
                      .i_clk(clk));
defparam m_regfile.WIDTH = WIDTH_PRD;

// W_I_EXEC = { val, func, brmask, uop, pc, imm, rd, op2, op1 }
bypass m_bypassNetwork(.o_data0(DPS2x[0]),
                       .o_data1(DPS2x[1]),
                       .o_data2(DPS2x[2]),
                       .o_data3(),
                       .i_irs0({ PRS2[0], PRS1[0] }),
                       .i_irs1({ PRS2[1], PRS1[1] }),
                       .i_irs2({ PRS2[2], PRS1[2] }),
                       .i_irs3({ WIDTH_PRD{2'b0} }),
                       .i_regFile0({ DPS[1], DPS[0] }),
                       .i_regFile1({ DPS[3], DPS[2] }),
                       .i_regFile2({ DPS[5], DPS[4] }),
                       .i_regFile3({ 32'b0,  32'b0  }),
                       .i_bypass0(bppkg[0]),
                       .i_bypass1(bppkg[1]),
                       .i_bypass2(bppkg[2]),
                       .i_bypass3(bppkg[3]),
                       .i_bypass4(bppkg[4]),
                       .i_bypass5(bppkg[5]),
                       .i_bypass6(bppkg[6]));
defparam m_bypassNetwork.WIDTH_REG = WIDTH_PRD;

wire [$pow(2, WIDTH_BRM)-1:0] _brkill;
register r_kill_mask(.o_q(_brkill),
                     .i_en(1'b1),
                     .i_d(brkill),
                     .i_rst_n(rst_n),
                     .i_clk(clk));
defparam r_kill_mask.WIDTH = $pow(2, WIDTH_BRM);

assign Ival[0] = ready_reg[0] & ~killf(BrMask[0], brkill | _brkill);
assign Ival[1] = ready_reg[1] & ~killf(BrMask[1], brkill | _brkill);
assign Ival[2] = ready_reg[2] & ~killf(BrMask[2], brkill | _brkill);

//assign { val, uop, brmask, rd, pc, func, imm, op2, op1 } = instr;
assign pkg[0] = { Ival[0], UOPCode[0], BrMask[0],
                     PRD[0], PC_ROB[0], Func_Imm[0], DPS2x[0] };
assign pkg[1] = { Ival[1], UOPCode[1], BrMask[1],
                     PRD[1], PC_ROB[1], Func_Imm[1], DPS2x[1] };
assign pkg[2] = { Ival[2], UOPCode[2], BrMask[2],
                     PRD[2], PC_ROB[2], Func_Imm[2], DPS2x[2] };
// instr = { CTRL, BRMASK, UOPCode, PC, IMM, RD, RS2, RS1 }

/* EXECUTION STATE */

pkg0 m_pkg0(.o_data  (wdata0),
            .o_addr  (waddr0),
            .o_val   (we0),
            .o_bypass(bppkg[0]),
            .i_data  (pkg[0]),
            .i_brkill(brkill),
            .i_rst_n (rst_n),
            .i_clk   (clk));
defparam m_pkg0.WIDTH     = W_I_EXEC;
defparam m_pkg0.WIDTH_REG = WIDTH_PRD;
defparam m_pkg0.WIDTH_BRM = WIDTH_BRM;

assign w_AdrSrc = |brkill;
pkg1 m_pkg1(.o_brkill (brkill),
            .o_PC     (rPC),
            .o_data   (wdata1),
            .o_addr   (waddr1),
            .o_val    (we1),
            .o_bypass0(bppkg[1]),
            .o_bypass1(bppkg[2]),
            .i_PC     (PCtoBR),
            .i_data   (pkg[1]),
            .i_brmask (brmask[4]),
            .i_brkill (brkill),
            .i_rst_n  (rst_n),
            .i_clk    (clk));
defparam m_pkg1.WIDTH     = W_I_EXEC;
defparam m_pkg1.WIDTH_REG = WIDTH_PRD;
defparam m_pkg1.WIDTH_BRM = WIDTH_BRM;

pkg2 m_pkg2(.o_data  (wdata2),
            .o_addr  (waddr2),
            .o_val   (we2),
            .o_bypass(bppkg[3]),
            .i_data  (pkg[2]),
            .i_rst_n (rst_n),
            .i_clk   (clk));
defparam m_pkg2.WIDTH     = W_I_EXEC;
defparam m_pkg2.WIDTH_REG = WIDTH_PRD;
defparam m_pkg2.WIDTH_BRM = WIDTH_BRM;

assign bppkg[4] = { we0, waddr0, wdata0 };
assign bppkg[5] = { we1, waddr1, wdata1 };
assign bppkg[6] = { we2, waddr2, wdata2 };
//reg ALU->Result
//
endmodule

/*
 * pkg0
 * AGU
 */
module pkg0 #(parameter WIDTH_REG = 7, WIDTH_BRM = 6,
                        WIDTH = m_mem.WIDTH)
            (output [32-1:0]         o_data,
             output [WIDTH_REG-1:0]  o_addr,
             output                  o_val,
             output [32+WIDTH_REG:0] o_bypass,
             input  [WIDTH-1:0]      i_data,
             input  [$pow(2, WIDTH_BRM)-1:0] i_brkill,
             input                   i_rst_n, i_clk);

MemCalc_m m_mem(.o_data  (o_data),
                .o_addr  (o_addr),
                .o_valid (o_val),
                .o_bypass(o_bypass), // { 1, WIDTH_PRD, 32 }
                .i_instr (i_data),
                .i_brkill(i_brkill),
                .i_rst_n (i_rst_n),
                .i_clk   (i_clk));
defparam m_mem.WIDTH_MEM = 14;
defparam m_mem.WIDTH_REG = WIDTH_REG;
defparam m_mem.WIDTH_BRM = WIDTH_BRM;

endmodule

/*
 * pkg1
 * ALU, BR
 */
module pkg1 #(parameter WIDTH_REG = 7, WIDTH_BRM = 6,
                        WIDTH = m_ALU.WIDTH)
            (output [$pow(2, WIDTH_BRM)-1:0] o_brkill,
             output [32-1:0]         o_PC,
             output [32-1:0]         o_data,
             output [WIDTH_REG-1:0]  o_addr,
             output                  o_val,
             output [32+WIDTH_REG:0] o_bypass0,
             output [32+WIDTH_REG:0] o_bypass1,
             input  [32-1:0]         i_PC,
             input  [WIDTH-1:0]      i_data,
             input  [WIDTH_BRM-1:0]  i_brmask,
             input  [$pow(2, WIDTH_BRM)-1:0] i_brkill,
             input                   i_rst_n, i_clk);

wire [32-1:0]        data_alu, data_br;
wire [WIDTH_REG-1:0] addr_alu, addr_br;
wire                 val_alu,  val_br;

executeALU m_ALU(.o_addr  (addr_alu),
                 .o_data  (data_alu),
                 .o_valid (val_alu),
                 .o_bypass(o_bypass0), // { 1, WIDTH_PRD, 32 }
                 .i_instr (i_data),
                 .i_rst_n (i_rst_n),
                 .i_clk   (i_clk));
defparam m_ALU.WIDTH_BRM = WIDTH_BRM;
defparam m_ALU.WIDTH_REG = WIDTH_REG;

executeBR  m_BR(.o_brkill(o_brkill),
                .o_PC    (o_PC),
                .o_addr  (addr_br),
                .o_data  (data_br),
                .o_we    (val_br),
                .o_valid (),
                .o_bypass(o_bypass1),    // { 1, WIDTH_PRD, 32 }
                .i_PCNext(i_PC),
                .i_instr (i_data),
                .i_brmask(i_brmask),
                .i_brkill(i_brkill),
                .i_rst_n (i_rst_n),
                .i_clk   (i_clk));
defparam m_BR.WIDTH_BRM = WIDTH_BRM;
defparam m_BR.WIDTH_REG = WIDTH_REG;

mux2in1 mux_addr(o_addr, val_br, addr_alu, addr_br);
defparam mux_addr.WIDTH = WIDTH_REG;
mux2in1 mux_data(o_data, val_br, data_alu, data_br);
defparam mux_data.WIDTH = 32;

assign o_val = val_alu | val_br;

endmodule

/*
 * pkg2
 * ALU, MUL
 */
module pkg2 #(parameter WIDTH_REG = 7, WIDTH_BRM = 6,
                        WIDTH = m_ALU.WIDTH)
            (output [32-1:0]         o_data,
             output [WIDTH_REG-1:0]  o_addr,
             output                  o_val,
             output [32+WIDTH_REG:0] o_bypass,
             input  [WIDTH-1:0]      i_data,
             input                   i_rst_n, i_clk);

executeALU m_ALU(.o_addr  (o_addr),
                 .o_data  (o_data),
                 .o_bypass(o_bypass),    // { 1, WIDTH_PRD, 32 }
                 .o_valid (o_val),
                 .i_instr (i_data),
                 .i_rst_n (i_rst_n),
                 .i_clk   (i_clk));
defparam m_ALU.WIDTH_BRM = WIDTH_BRM;
defparam m_ALU.WIDTH_REG = WIDTH_REG;

/*
MulDiv m_MulDiv(.o_rd(),
                .o_WBdata(o_data),
                .o_read(we_mem),
                .i_instr(mod_alu1),
                .i_rst_n(rst_n),
                .i_clk(clk));
defparam m_MulDiv.WIDTH = W_I_EXEC;

*/

endmodule

