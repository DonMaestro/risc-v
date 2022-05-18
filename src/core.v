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
localparam WIDTH_ISSUE = 7 + WIDTH_BRM + WIDTH_TAG + 3*WIDTH_PRD + 3;

wire [31:0] newPC, nextPC, rPC;
wire        w_AdrSrc;
wire [31:0] PC, PCx;
wire [4*32-1:0] dataIC4x;

// wire decode
wire            en_decode;
wire [4*32-1:0] Inst4x;
wire [  32-1:0] Instr[0:3];
reg  [4-1:0]    Imask;

wire [3*5-1:0]         rg[0:3];
wire [10-1:0]          func[0:3];
wire [5-1:0]           ctrl[0:3];
wire [32-1:0]          imm[0:3];
wire [4*7-1:0]         uop[0:3];
wire [3*WIDTH_PRD-1:0] prs[0:3];

wire                   en_bm[0:4];
wire [WIDTH_BRM-1:0]   brmask[0:4];

// wire rename
wire                   en_rename1, en_rename2;
wire [WIDTH_TAG-1:0]   tagPkg; 

wire [7-1:0]           uoprg1[0:3],    uoprg2[0:3];
wire [10-1:0]          funcrg1[0:3],   funcrg2[0:3];
wire [5-1:0]           ctrlrg1[0:3],   ctrlrg2[0:3];
wire [32-1:0]          immrg1[0:3],    immrg2[0:3];
wire [WIDTH_BRM-1:0]   brmaskrg1[0:3], brmaskrg2[0:3];
wire [WIDTH_TAG-1:0]                   tagrg2;

wire [3*WIDTH_PRD-1:0] prgs[0:3];
wire [2*WIDTH_PRD-1:0] prs2x[0:3];
wire [  WIDTH_PRD-1:0] prd[0:3];

wire                   com_en;
wire [3:0]             enflist;
wire [4*WIDTH_PRD-1:0] com_prd4x, freelist4x;
wire [WIDTH_PRD-1:0]   freelist[0:3];
wire [WIDTH_PRD-1:0]   com_prd[0:3];
wire [4*WIDTH_PRD-1:0] prdo4x;

// busy table
wire [2-1:0]           p2x[0:3];
wire [4*WIDTH_PRD-1:0] setBusy4x;

wire                  val[0:3];

// wire issue queue
wire [WIDTH_ISSUE-1:0] issue[0:2];
wire [WIDTH_ISSUE-1:0] issmem[0:3], issalu[0:3];
wire [2:0] valmem[0:3], valalu[0:3];

// wire regFile
wire [7-1:0]         UOPCode;
wire [WIDTH_BRM-1:0] BrMask;
wire [WIDTH_TAG-1:0] Tag;
wire [WIDTH_PRD-1:0] PRD;

wire [31:0] wDataMem;
wire [WIDTH_PRD-1:0] waddr1, waddr2, wAddrMem;

wire [3*WIDTH_PRD-1:0] waddr3x;
wire [WIDTH_PRD-1:0] waddr[0:2];
wire [WIDTH_ISSUE-1:0] instr[0:2];
wire [31:0] DPS[0:5];
wire [31:0] PRS1[0:2];
wire [31:0] PRS2[0:2];

// wire alu
/* main block */

assign w_AdrSrc = 1'b0;
mux2in1 mux_PC(.o_dat(newPC),
               .i_control(w_AdrSrc), 
               .i_dat0(nextPC),
               .i_dat1(rPC)); 
defparam mux_PC.WIDTH = 32;

assign nextPC = { (PC[31:4] + 28'h1), 4'b0000 };

register r_PC (PC, 1'b1, newPC, rst_n, clk);

/* MEM */
icache_m m_icache(dataIC4x, PC[12:0]);
defparam m_icache.WIDTH = 12;

/*
ram m_fetchBuff(.o_data(ReadData),
                .i_we(), 
                .i_data(B), 
                .i_clk(clk));
*/

register r_instr(Inst4x, 1'b1, dataIC4x, rst_n, clk);
defparam r_instr.WIDTH = 32 * 4;
register r_PCx  (PCx, 1'b1, PC, rst_n, clk);
register #(1) r_en_decode(en_decode, 1'b1, 1'b1, rst_n, clk);

//
// Decode state
//
// rg = { drd, drs2, drs1 }
//

always @(PCx)
begin
	case(PCx[1:0])
		2'b00: Imask = 4'b1111;
		2'b01: Imask = 4'b1110;
		2'b10: Imask = 4'b1100;
		2'b11: Imask = 4'b1000;
	endcase
end

register #(1) r_en_j  (en_bm[0],  1'b1, en_bm[4],  rst_n, clk);
register      r_brmask(brmask[0], 1'b1, brmask[4], rst_n, clk);
defparam r_brmask.WIDTH = WIDTH_BRM;

generate
	genvar i;

	for (i = 0; i < 4; i = i + 1) begin: decode
		assign Instr[i] = Inst4x[(i+1)*32-1:i*32];

		decode m_decode(.o_regs (rg[i]),
		                .o_func (func[i]),
		                .o_ctrl (ctrl[i]),
		                .o_imm  (imm[i]),
		                .o_en_j  (en_bm[i+1]),
		                .o_brmask(brmask[i+1]),
		                .i_en_j  (en_bm[i]),
		                .i_brmask(brmask[i]),
		                .i_en   (en_decode),
		                .i_instr(Instr[i]),
		                .i_imask(Imask[i]));
		defparam m_decode.WIDTH_BRM = WIDTH_BRM;

		assign uop[i] = Instr[i][6:0];
	end
endgenerate

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
	                    .i_we   (com_en),
	                    .i_rst_n(rst_n),
	                    .i_clk  (clk));
	defparam m_freelist.WIDTH = WIDTH_PRD;
	defparam m_freelist.SIZE  = $pow(2, WIDTH_PRD - 2) - 1;
	defparam m_freelist.STNUM = 1;

	for (r = 1; r < 4; r = r + 1) begin: flist
		freelist m_freelist(.o_data (freelist[r]),
		                    .i_data (com_prd[r]),
		                    .i_re   (enflist[r]),
		                    .i_we   (com_en),
		                    .i_rst_n(rst_n),
		                    .i_clk  (clk));
		defparam m_freelist.WIDTH = WIDTH_PRD;
		defparam m_freelist.SIZE = $pow(2, WIDTH_PRD - 2);
		defparam m_freelist.STNUM = r * $pow(2, WIDTH_PRD - 2);
	end

	for (r = 0; r < 4; r = r + 1) begin
		assign com_prd[r] = com_prd4x[(r+1)*WIDTH_PRD-1:r*WIDTH_PRD];
		assign freelist4x[(r+1)*WIDTH_PRD-1:r*WIDTH_PRD] = freelist[r];

		assign { prd[r], prs2x[r] } = prgs[r];
	end

	for (r = 0; r < 4; r = r + 1) begin
		register #(10) r_funcrg1(funcrg1[r], en_rename1, func[r], rst_n, clk);
		register #(5) r_ctrlrg1(ctrlrg1[r], en_rename1, ctrl[r], rst_n, clk);
		register #(32) r_immrg1(immrg1[r], en_rename1, imm[r], rst_n, clk);
		register r_brmaskrg1(brmaskrg1[r], en_rename1, brmask[r+1], rst_n, clk);
		defparam r_brmaskrg1.WIDTH = WIDTH_BRM;
		register #(7) r_uoprg1(uoprg1[r], en_rename1, uop[r], rst_n, clk);


		register #(10) r_funcrg2(funcrg2[r], en_rename2, funcrg1[r], rst_n, clk);
		register #(5) r_ctrlrg2(ctrlrg2[r], en_rename2, ctrlrg1[r], rst_n, clk);
		register #(32) r_immrg2(immrg2[r], en_rename2, immrg1[r], rst_n, clk);
		register r_brmaskrg2(brmaskrg2[r], en_rename1, brmaskrg1[r], rst_n, clk);
		defparam r_brmaskrg2.WIDTH = WIDTH_BRM;
		register #(7) r_uoprg2(uoprg2[r], en_rename2, uoprg1[r], rst_n, clk);
		register r_tagrg2(tagrg2, en_rename2, tagPkg, rst_n, clk);
		defparam r_tagrg2.WIDTH = WIDTH_TAG;

	end
endgenerate

rename m_rename(.o_prg1(prgs[0]),
                .o_prg2(prgs[1]),
                .o_prg3(prgs[2]),
                .o_prg4(prgs[3]),
                .o_mtab(prdo4x),        // for commit
                .o_enfreelist(enflist),    // enable read freelist
                .i_rg1(rg[0]),
                .i_rg2(rg[1]),
                .i_rg3(rg[2]),
                .i_rg4(rg[3]),
                .i_freelist(freelist4x),
                .i_en(en_rename1),
                .i_rst_n(rst_n),
                .i_clk(clk));
defparam m_rename.WIDTH_PRD = WIDTH_PRD;

register #(1) r_en_rename2(en_rename2, 1'b1, en_rename1, rst_n, clk);
//assign data4x = 

// rob
// dis_data = { val, uop, imm, prd, mask }
rob m_rob(.o_dis_tag(tagPkg),
          .o_com_prd4x(com_prd4x),
          .o_com_en(com_en),
          .i_dis_pc(PC),
          .i_dis_data4x(data4x),
          .i_dis_we(en_rename2),
          .i_kill(), // { en, mask }
          .i_rst_busy0(),
          .i_rst_busy1(),
          .i_rst_busy2(),
          .i_rst_busy3(),
          .i_rst_n(rst_n),
          .i_clk(clk));
defparam m_rob.WIDTH_BANK = WIDTH_TAG;
defparam m_rob.WIDTH_REG  = WIDTH_PRD;
defparam m_rob.WIDTH_BRM  = WIDTH_BRM;

// busy table
assign setBusy4x = { prd[3], prd[2], prd[1], prd[0] };

busytb m_btab(.o_data1(p2x[0]),
              .o_data2(p2x[1]),
              .o_data3(p2x[2]),
              .o_data4(p2x[3]),
              .i_addr1(prs2x[0]),
              .i_addr2(prs2x[1]),
              .i_addr3(prs2x[2]),
              .i_addr4(prs2x[3]),
              .i_setAddr4x(setBusy4x),
              .i_rstAddr4x(wdest4x),
              .i_rst_n(i_rst_n),
              .i_clk(clk));
defparam m_btab.WIDTH = WIDTH_PRD;

// queue state
generate
	genvar j;
	for (j = 0; j < 4; j = j + 1) begin

		// valxxx = { val, p2, p1 }
		assign valmem[j] = { ctrlrg2[j][1], ~p2x[j] };
		assign valalu[j] = { ctrlrg2[j][2], ~p2x[j] };
		// issue_slot = { UOPcode, brmask, tag, prd, prs2, prs1, val, p2, p1 };
		assign issmem[j] = { uoprg2[j], brmaskrg2[j], tagrg2, prgs[j], valmem[j] };
		assign issalu[j] = { uoprg2[j], brmaskrg2[j], tagrg2, prgs[j], valalu[j] };
	end
endgenerate

queue4in1 m_issue_mem(.o_inst1(issue[0]),
                      .o_ready(),
                      .i_inst1(issmem[0]),
                      .i_inst2(issmem[1]),
                      .i_inst3(issmem[2]),
                      .i_inst4(issmem[3]),
                      .i_wdest4x(wdest4x),
                      .i_en(en_rename2),
                      .i_rst_n(rst_n),
                      .i_clk(clk));
defparam m_issue_mem.WIDTH = WIDTH_ISSUE;
defparam m_issue_mem.WIDTH_REG = WIDTH_PRD;
defparam m_issue_mem.WIDTH_TAG = WIDTH_TAG;
defparam m_issue_mem.WIDTH_BRM = WIDTH_BRM;
defparam m_issue_mem.SIZE = 32;

queue4in2 m_issue_alu(.o_inst1(issue[1]),
                      .o_inst2(issue[2]),
                      .o_ready1(),
                      .o_ready2(),
                      .i_inst1(issalu[0]),
                      .i_inst2(issalu[1]),
                      .i_inst3(issalu[2]),
                      .i_inst4(issalu[3]),
                      .i_wdest4x(wdest4x),
                      .i_en(en_rename2),
                      .i_rst_n(rst_n),
                      .i_clk(clk));
defparam m_issue_alu.WIDTH = WIDTH_ISSUE;
defparam m_issue_alu.WIDTH_REG = WIDTH_PRD;
defparam m_issue_alu.WIDTH_TAG = WIDTH_TAG;
defparam m_issue_alu.WIDTH_BRM = WIDTH_BRM;
defparam m_issue_alu.SIZE = 32;

register r_issue_mem(.o_q(InstMEM1x),
                     .i_en(1'b1),
                     .i_d(issue[0]),
                     .i_rst_n(rst_n),
                     .i_clk(clk));
defparam r_issue_mem.WIDTH = WIDTH_ISSUE;

register r_issue_alu(.o_q(InstALU2x),
                     .i_en(1'b1),
                     .i_d({ issue[2], issue[1] }),
                     .i_rst_n(rst_n),
                     .i_clk(clk));
defparam r_issue_alu.WIDTH = WIDTH_ISSUE;


// reg state
assign instr[0] = InstMEM1x;
assign { instr[2], instr[1] } = InstALU2x;
assign waddr3x = { waddr2, waddr1, wAddrMem };

assign { UOPCode[0], BrMask[0], Tag[0], PRD[0], PRS2[0], PRS1[0] } = instr[0];
assign { UOPCode[1], BrMask[1], Tag[1], PRD[1], PRS2[1], PRS1[1] } = instr[1];
assign { UOPCode[2], BrMask[2], Tag[2], PRD[2], PRS2[2], PRS1[2] } = instr[2];

// register
regfile4in8 m_regfile(.o_rdata0(DPS[0]),  .o_rdata1(DPS[1]),
                      .o_rdata2(DPS[2]),  .o_rdata3(DPS[3]),
                      .o_rdata4(DPS[4]),  .o_rdata5(DPS[5]),
                      .i_raddr0(PRS1[0]), .i_raddr1(PRS2[0]),
                      .i_raddr2(PRS1[1]), .i_raddr3(PRS2[1]),
                      .i_raddr4(PRS1[2]), .i_raddr5(PRS2[2]),
                      .i_we0(we_mem), .i_we1(), .i_we2(), .i_we3(1'b0),
                      .i_waddr0(wAddrMem),
                      .i_waddr1(waddr1), .i_waddr2(waddr2),
                      .i_wdata0(wDataMem), .i_wdata1(), .i_wdata2(),
                      .i_clk(clk));

// instr = { CTRL, BRMASK, UOPCode, PC, IMM, RD, RS2, RS1 }
bypass m_bypassNetwork(.o_mod0(mod_mem),
                       .o_mod1(mod_alu0),
                       .o_mod2(mod_alu1),
                       .o_mod3(mod_br),
                       .o_mod4(mod_mul),
                       .i_instr0(instr[0]),
                       .i_instr1(instr[1]),
                       .i_instr2(instr[2]),
                       .i_regFile0({ DPS[1], DPS[0] }),
                       .i_regFile1({ DPS[3], DPS[2] }),
                       .i_regFile2({ DPS[5], DPS[4] }),
                       .i_regFile3({ 32'b0,  32'b0  }),
                       .i_bypass());
defparam m_bypassNetwork.WIDTH = 6 + WIDTH_BRM + 7 + 2 * 32 + 3 * WIDTH_PRD;
defparam m_bypassNetwork.WIDTH_REG = WIDTH_PRD;

localparam WIDTH_EXE = 6 + WIDTH_BRM + 7 + 4 * 32 + WIDTH_PRD;
/* EXECUTION STATE */

MemCalc_m m_mem(.o_data (wDataMem),
                .o_addr (wAddrMem),
                .o_valid(we_mem),
                .i_instr(mod_mem),
                .i_rst_n(rst_n),
                .i_clk  (clk));
defparam m_mem.WIDTH_MEM = 4;
defparam m_mem.WIDTH_REG = WIDTH_PRD;
defparam m_mem.WIDTH_BRM = WIDTH_BRM;

// ALU
executeALU m_ALU0(.o_addr(),
                  .o_data(),
                  .o_bypass(),    // { 1, WIDTH_PRD, 32 }
                  .o_valid(),
                  .i_instr(mod_alu0),
                  .i_rst_n(rst_n),
                  .i_clk(clk));
defparam m_ALU0.WIDTH = WIDTH_EXE;
defparam m_ALU0.WIDTH_BRM = WIDTH_BRM;
defparam m_ALU0.WIDTH_REG = WIDTH_PRD;

executeALU m_ALU1(.o_addr(),
                  .o_data(),
                  .o_bypass(),    // { 1, WIDTH_PRD, 32 }
                  .o_valid(),
                  .i_instr(mod_alu1),
                  .i_rst_n(rst_n),
                  .i_clk(clk));
defparam m_ALU1.WIDTH = WIDTH_EXE;
defparam m_ALU1.WIDTH_BRM = WIDTH_BRM;
defparam m_ALU1.WIDTH_REG = WIDTH_PRD;


executeBR  m_BR(.o_brmask(),
                .o_brkill(),
                .o_we(),
                .o_PC(),
                .o_addr(),
                .o_data(),
                .o_valid(),
                .i_instr(mod_mul),
                .i_PCNext(),
                .i_rst_n(rst_n),
                .i_clk(clk));
defparam m_BR.WIDTH = WIDTH_EXE;
defparam m_BR.WIDTH_BRM = WIDTH_BRM;
defparam m_BR.WIDTH_REG = WIDTH_PRD;

/*
MulDiv m_MulDiv(.o_rd(),
                .o_WBdata(o_data),
                .o_read(we_mem),
                .i_instr(mod_br),
                .i_rst_n(rst_n),
                .i_clk(clk));
defparam m_MulDiv.WIDTH = WIDTH_EXE;


mux2in1 m_mux( , , o_alu0, muldiv);
mux2in1 m_mux( , , o_alu1, muldiv);
*/
//reg ALU->Result
//
assign wdest4x = { {WIDTH_PRD{1'b0}}, PRD[2], PRD[1], wAddrMem };

endmodule

