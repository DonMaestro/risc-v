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
localparam WIDTH_TAG = 5;
// wire decode
wire [ 4:0] drd [0:3];
wire [ 4:0] drs1[0:3];
wire [ 4:0] drs2[0:3];
wire [19:0] dimm[0:3];

wire [4*7-1:0] uop4x;
wire [3*5-1:0] rg[0:3];
wire [3*WIDTH_PRD-1:0] prs[0:3];

wire com_en;
wire [WIDTH_PRD-1:0] com_prd[0:3];
wire [WIDTH_PRD-1:0] freelist[0:3];
wire [4*WIDTH_PRD-1:0] com_prd4x, freelist4x;

reg [4*WIDTH_PRD-1:0] rds, rs1, rs2;
reg [4*20-1:0] imm;

// wire rename
wire [3*WIDTH_PRD-1:0] prgs[0:3];
wire [2*WIDTH_PRD-1:0] prs2x[0:3];
wire [  WIDTH_PRD-1:0] prd[0:3];

// busy table
wire [2-1:0]           p2x[0:3];
wire [4*WIDTH_PRD-1:0] setBusy4x;

// wire issue queue
localparam WIDTH_ISSUE = 7+WIDTH_BRM+WIDTH_TAG+WIDTH_PRD*3+3;
wire [WIDTH_ISSUE-1:0] issmem, issalu;
reg  [3:0] valmem, valalu;
wire [7-1:0] uop[0:3];
wire [WIDTH_TAG-1:0] tag[0:3]; 

// wire regFile
wire [31:0] wDataMem;
wire [WIDTH_PRD-1:0] wAddrMem;

wire [3*WIDTH-1:0] waddr3x;
wire [WIDTH-1:0] waddr[0:2];
wire [WIDTH-1:0] instr[0:2];
wire [31:0] DPS[0:5];
wire [31:0] PRS1[0:2];
wire [31:0] PRS2[0:2];

// wire alu
/* main block */

mux2in1 mux_PC(.o_dat(newPC),
               .i_control(w_AdrSrc), 
               .i_dat0(nextPC),
               .i_dat1(rPC)); 

register r_PC (PC, 1'b1, newPC, rst_n, clk);

/* MEM */
assign ReadData = i_data;
assign o_we     = w_MemWrite;	

assign i_IcacheData = B;

icache_m mod_icache(dataIC4x, o_IcacheAddr, PC);

/*
ram m_fetchBuff(.o_data(ReadData),
                .i_we(), 
                .i_data(B), 
                .i_clk(clk));
*/

register r_instr(Packet, 1'b1, dataIC4x, rst_n, clk);

//
// Decode state
//
// rg = { drd, drs2, drs1 }
//

generate
	genvar i;

	assign { PCx, Inst4x, Imask } = Packet;

	for (i = 0; i < 4; i = i + 1) begin
		assign Instr[i] = Inst4x[(i+1)*32-1:i*32];

		decode mod_decode(.o_regs (rg[i]),
		                  .o_func (func[i]),
		                  .o_ctrl (),
		                  .o_imm  (dimm[i]),
		                  .i_instr(Instr[i]),
		                  .i_imask(Imask[i]));

		assign uop4x[(i+1)*7-1:i*7] = Instr[i][6:0];
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

	for (r = 1; r < 4; r = r + 1) begin
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
		assign freelist4x[(r+1)*WIDTH_PRD-1:r*WIDTH_PRD] = freelist[i];

		assign { prd[r], prs2x[r] } = prgs[r];
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
                  .i_en(1'b1),
                  .i_rst_n(rst_n),
                  .i_clk(clk));
defparam m_rename.WIDTH = WIDTH_PRD;

// rob
rob m_rob(.o_dis_tag(tag),
          .o_com_prd4x(com_prd4x),
          .o_com_en(com_en),
          .i_dis_pc(PC),
          .i_dis_data4x(data4x),
          .i_dis_we(1'b1),
          .i_kill(), // { en, mask }
          .i_rst_busy0(),
          .i_rst_busy1(),
          .i_rst_busy2(),
          .i_rst_busy3(),
          .i_rst_n(rst_n),
          .i_clk(clk));

register r_1tag4x(rg1tag4x1, 1'b1, tag4x, rst_n, clk);
defparam r_1tag4x.WIDTH = 4*3;

register r_1uop4x(rg1uop4x, 1'b1, uop4x, rst_n, clk);
defparam r_1uop4x.WIDTH = 4*7;

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
		assign uop[j] = rg1uop4x[(j+1)*7-1:j*7];
		assign tag[j] = rg1tag4x[(j+1)*WIDTH_TAG-1:j*WIDTH_TAG];

		// valxxx = { val, p2, p1 }
		assign valmem[j] = { ~val[j], ~p2x[j] };
		assign valalu[j] = {  val[j], ~p2x[j] };
		// issue_slot = { UOPcode, brmask, tag, prd, prs2, prs1, val, p2, p1 };
		assign issmem[j] = { uop[j], brmask, tag[j], prd[j], prs2x[j], valmem[j] };
		assign issalu[j] = { uop[j], brmask, tag[j], prd[j], prs2x[j], valalu[j] };
	end
endgenerate

queue4in1 m_issue_mem(.o_inst1(),
                      .o_ready(),
                      .i_inst1(issmem[0]),
                      .i_inst2(issmem[1]),
                      .i_inst3(issmem[2]),
                      .i_inst4(issmem[3]),
                      .i_wdest4x(wdest4x),
                      .i_en(1'b1),
                      .i_rst_n(rst_n),
                      .i_clk(clk));
defparam m_issue_mem.WIDTH = WIDTH_ISSUE;
defparam m_issue_mem.WIDTH_REG = WIDTH_PRD;
defparam m_issue_mem.WIDTH_TAG = WIDTH_TAG;
defparam m_issue_mem.WIDTH_BRM = WIDTH_BRM;
defparam m_issue_mem.SIZE = 32;

queue4in2 m_issue_alu(.o_inst1(inst[0]),
                      .o_inst2(inst[1]),
                      .o_ready(),
                      .i_inst1(issalu[0]),
                      .i_inst2(issalu[1]),
                      .i_inst3(issalu[2]),
                      .i_inst4(issalu[3]),
                      .i_wdest4x(wdest4x),
                      .i_en(1'b1),
                      .i_rst_n(rst_n),
                      .i_clk(clk));
defparam m_issue_alu.WIDTH = WIDTH_ISSUE;
defparam m_issue_alu.WIDTH_REG = WIDTH_PRD;
defparam m_issue_alu.WIDTH_TAG = WIDTH_TAG;
defparam m_issue_alu.WIDTH_BRM = WIDTH_BRM;
defparam m_issue_alu.SIZE = 32;

register r_issue_mem(.o_q(InstMEM1x),
                     .i_en(1'b1),
                     .i_d(),
                     .i_rst_n(rst_n),
                     .i_clk(clk));
defparam r_issue_mem.WIDTH = WIDTH_ISSUE;

register r_issue_alu(.o_q(InstALU2x),
                     .i_en(1'b1),
                     .i_d(),
                     .i_rst_n(rst_n),
                     .i_clk(clk));
defparam r_issue_alu.WIDTH = WIDTH_ISSUE;


// reg state
assign instr[0] = InstMEM1x;
assign { instr[2], instr[1] } = InstALU2x;
assign waddr3x = { waddr2, waddr1, waddr0 };

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
                      .i_waddr0(wAddrMem), .i_waddr1(waddr1), .i_waddr2(waddr2),
                      .i_wdata0(wDataMem), .i_wdata1, .i_wdata2,           
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

MemCalc_m mod_mem(.o_data (wDataMem),
                  .o_addr (wAddrMem),
                  .o_valid(we_mem),
                  .i_instr(mod_mem),
                  .i_rst_n(rst_n),
                  .i_clk  (clk));
defparam mod_mem.WIDTH = 4;
defparam mod_mem.WIDTH_REG = WIDTH_REG;

// ALU
executeALU mod_ALU0(.o_addr(),
                    .o_data(),
                    .o_bypass(),    // { 1, WIDTH_PRD, 32 }
                    .o_valid(),
                    .i_instr(mod_alu0),
                    .i_rst_n(rst_n),
                    .i_clk(clk));
defparam mod_ALU0.WIDTH = WIDTH_EXE;
defparam mod_ALU0.WIDTH_BRM = WIDTH_BRM;
defparam mod_ALU0.WIDTH_REG = WIDTH_PRD;

executeALU mod_ALU1(.o_addr(),
                    .o_data(),
                    .o_bypass(),    // { 1, WIDTH_PRD, 32 }
                    .o_valid(),
                    .i_instr(mod_alu1),
                    .i_rst_n(rst_n),
                    .i_clk(clk));
defparam mod_ALU1.WIDTH = WIDTH_EXE;
defparam mod_ALU1.WIDTH_BRM = WIDTH_BRM;
defparam mod_ALU1.WIDTH_REG = WIDTH_PRD;


executeBR  mod_BR(.o_brmask(),
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
defparam mod_BR.WIDTH = WIDTH_EXE;
defparam mod_BR.WIDTH_BRM = WIDTH_BRM;
defparam mod_BR.WIDTH_REG = WIDTH_PRD;

/*
MulDiv mod_MulDiv(.o_rd(), 
                 .o_WBdata(o_data),
                 .o_read(we_mem),
                 .i_instr(mod_br),
                 .i_rst_n(rst_n),
                 .i_clk(clk));
defparam mod_MulDiv.WIDTH = WIDTH_EXE;


mux2in1 m_mux( , , o_alu0, muldiv);
mux2in1 m_mux( , , o_alu1, muldiv);
*/
//reg ALU->Result
//
assign wdest4x = { {WIDTH_PRD{1'b0}}, PRD[2], PRD[1], wAddrMem };

endmodule

