/*
*    x_rg = { rd, rs2, rs1 }
*/
module rename #(parameter WIDTH_PRD = 7)
              (output [3*WIDTH_PRD-1:0] o_prg1, o_prg2, o_prg3, o_prg4,
               output [4*WIDTH_PRD-1:0] o_mtab,          // old prd for commit
               output [3:0]             o_enfreelist,    // enable read freelist
               input  [3*5-1:0]         i_rg1, i_rg2, i_rg3, i_rg4,
               input  [4*WIDTH_PRD-1:0] i_freelist,
               input                    i_en, i_rst_n, i_clk);
integer k;

wire [5-1:0] rsd[0:3];
wire [5-1:0] rs1[0:3];
wire [5-1:0] rs2[0:3];

wire [4*5-1:0]         rsd4x, rs24x, rs14x;
wire [4*WIDTH_PRD-1:0] prdo4x, prsd4x, prs24x, prs14x;
wire [WIDTH_PRD-1:0] prsd[0:3];

wire [WIDTH_PRD-1:0] prdo    [0:3];
wire [WIDTH_PRD-1:0] prd     [0:3];
wire [WIDTH_PRD-1:0] prs[1:2][0:3];

wire [4*5-1:0]         rg4xrsd;
wire [4*WIDTH_PRD-1:0] rg4xprd, rg4xprdo;
wire [4*WIDTH_PRD-1:0] rg4xprs[1:2];

// rd equals zero reg
wire [3:0] crd0;
wire [WIDTH_PRD-1:0] flist[0:3];

wire       equals2[0:2];
wire [1:0] equals3[0:2];
wire [2:0] equals4[0:2];

wire       comp2[0:2];
wire [1:0] comp3[0:2];
wire [2:0] comp4[0:2];

reg  [WIDTH_PRD-1:0]   state[0:3];
wire [4*WIDTH_PRD-1:0] state4x;
reg  [WIDTH_PRD-1:0] mux[0:3][1:2];

assign { rsd[0], rs2[0], rs1[0] } = i_rg1; 
assign { rsd[1], rs2[1], rs1[1] } = i_rg2; 
assign { rsd[2], rs2[2], rs1[2] } = i_rg3; 
assign { rsd[3], rs2[3], rs1[3] } = i_rg4; 

assign o_enfreelist = ~crd0;

maptable m_maptab(.o_data12x({ prdo4x, prs24x, prs14x }),
                  .i_addr8x({ rs24x, rs14x }),
                  .i_waddr4x(rsd4x),
                  .i_wdata4x(prsd4x),
                  .i_we(i_en),
                  .i_rst_n(i_rst_n),
                  .i_clk(i_clk));
defparam m_maptab.WIDTH = WIDTH_PRD;

generate
	genvar i, j;
	for (i = 0; i < 4; i = i + 1) begin
		assign rsd4x[(i+1)*5-1:i*5] = rsd[i];
		assign rs14x[(i+1)*5-1:i*5] = rs1[i];
		assign rs24x[(i+1)*5-1:i*5] = rs2[i];

		// check zero rd
		assign flist[i] = i_freelist[(i+1)*WIDTH_PRD-1:i*WIDTH_PRD];
		comparator #(5) cm_prd_zero(crd0[i], rsd[i], 5'b0);
		mux2in1 mux_prd_zero(prsd[i], crd0[i], flist[i], {WIDTH_PRD{1'b0}});
		defparam mux_prd_zero.WIDTH = WIDTH_PRD;
		assign prsd4x[(i+1)*WIDTH_PRD-1:i*WIDTH_PRD] = prsd[i];    // for mtab
	end

	comparator #(5) cm_2rd (equals2[0], rsd[1], rsd[0]);
	comparator #(5) cm_2rs1(equals2[1], rs1[1], rsd[0]);
	comparator #(5) cm_2rs2(equals2[2], rs2[1], rsd[0]);

	for (j = 0; j < 2; j = j + 1) begin
		comparator #(5) cm_3rd (equals3[0][j], rsd[2], rsd[j]);
		comparator #(5) cm_3rs1(equals3[1][j], rs1[2], rsd[j]);
		comparator #(5) cm_3rs2(equals3[2][j], rs2[2], rsd[j]);
	end

	for (j = 0; j < 3; j = j + 1) begin
		comparator #(5) cm_4rd (equals4[0][j], rsd[3], rsd[j]);
		comparator #(5) cm_4rs1(equals4[1][j], rs1[3], rsd[j]);
		comparator #(5) cm_4rs2(equals4[2][j], rs2[3], rsd[j]);
	end

	// register
	for (i = 0; i < 3; i = i + 1) begin
		register #(1) r_1prg2(comp2[i], i_en, equals2[i], i_rst_n, i_clk);
		register #(2) r_1prg3(comp3[i], i_en, equals3[i], i_rst_n, i_clk);
		register #(3) r_1prg4(comp4[i], i_en, equals4[i], i_rst_n, i_clk);
	end
endgenerate

//logic prsd4x = x != 0 ? i_freelist : 0;

//register #(4*WIDTH_PRD) r_prd (regcom,  i_en, prdcom, i_rst_n, i_clk);
register #(4*5) r_rsd(rg4xrsd, i_en, rsd4x, i_rst_n, i_clk);

// mtab(rd) -> old prd for commit
register #(4*WIDTH_PRD) r_prdo(rg4xprdo,   i_en, prdo4x, i_rst_n, i_clk);

// freelist -> new prd
register #(4*WIDTH_PRD) r_prsd(rg4xprd,    i_en, prsd4x, i_rst_n, i_clk);
register #(4*WIDTH_PRD) r_prs1(rg4xprs[1], i_en, prs14x, i_rst_n, i_clk);
register #(4*WIDTH_PRD) r_prs2(rg4xprs[2], i_en, prs24x, i_rst_n, i_clk);

// rename2
generate
	genvar g;
	for (g = 0; g < 4; g = g + 1) begin
		assign prdo  [g] = rg4xprdo  [(g+1)*WIDTH_PRD-1:g*WIDTH_PRD];

		assign prd   [g] = rg4xprd   [(g+1)*WIDTH_PRD-1:g*WIDTH_PRD];
		assign prs[1][g] = rg4xprs[1][(g+1)*WIDTH_PRD-1:g*WIDTH_PRD];
		assign prs[2][g] = rg4xprs[2][(g+1)*WIDTH_PRD-1:g*WIDTH_PRD];

		assign state4x[(g+1)*WIDTH_PRD-1:g*WIDTH_PRD] = state[g];    // for mtab
	end
endgenerate

always @(*)
begin
	state[0] = prdo[0];

	casez(comp2[0])
		1'b0: state[1] = prdo[1];
		1'b1: state[1] = prd[0];
	endcase
	
	casez(comp3[0])
		2'b00: state[2] = prdo[2];
		2'b1?: state[2] = prd[1];
		2'b01: state[2] = prd[0];
	endcase

	casez(comp4[0])
		3'b000: state[3] = prdo[3];
		3'b1??: state[3] = prd[2];
		3'b01?: state[3] = prd[1];
		3'b001: state[3] = prd[0];
	endcase

	// mux prsX -> output
	for (k = 1; k < 3; k = k + 1) begin
		mux[0][k] = prs[k][0];

		casez(comp2[k])
			1'b0: mux[1][k] = prs[k][1];
			1'b1: mux[1][k] = prd   [0];
		endcase
		
		casez(comp3[k])
			2'b00: mux[2][k] = prs[k][2];
			2'b1?: mux[2][k] = prd   [1];
			2'b01: mux[2][k] = prd   [0];
		endcase

		casez(comp4[k])
			3'b000: mux[3][k] = prs[k][3];
			3'b1??: mux[3][k] = prd   [2];
			3'b01?: mux[3][k] = prd   [1];
			3'b001: mux[3][k] = prd   [0];
		endcase
	end
end

// return
register r_2prg1(o_prg1, i_en, { prd[0], mux[0][2], mux[0][1] }, i_rst_n, i_clk);
register r_2prg2(o_prg2, i_en, { prd[1], mux[1][2], mux[1][1] }, i_rst_n, i_clk);
register r_2prg3(o_prg3, i_en, { prd[2], mux[2][2], mux[2][1] }, i_rst_n, i_clk);
register r_2prg4(o_prg4, i_en, { prd[3], mux[3][2], mux[3][1] }, i_rst_n, i_clk);
defparam r_2prg1.WIDTH = 3*WIDTH_PRD;
defparam r_2prg2.WIDTH = 3*WIDTH_PRD;
defparam r_2prg3.WIDTH = 3*WIDTH_PRD;
defparam r_2prg4.WIDTH = 3*WIDTH_PRD;

//register r_2mtab(o_mtab, i_en, state4x, i_rst_n, i_clk);
assign o_mtab = state4x;

endmodule

