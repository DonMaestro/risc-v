
genvar ibk, isl;
localparam PROB_W_DATA  = `ROB.WIDTH_DT;
localparam PROB_W_DRM   = `ROB.WIDTH_BRM;
localparam PROB_W_NBANK = `ROB.NBANK;
localparam PROB_W_SIZE  = `ROB.SIZE;


reg [ 7-1:0] sl_uop;
reg [32-1:0] sl_imm;
reg [ 7-1:0] sl_prdo, sl_prdn;

bind bankSlot robtable #(21, 3) my_rb(
	.valid  (val),
	.busy   (busy),
	.data   (data),
	.brmask (brmask)
);

//static virtual robtable pc[PROB_W_SIZE];
wire [31:4] pc[PROB_W_SIZE];
static virtual robtable #(21, 3) rb[PROB_W_NBANK][PROB_W_SIZE];

for (isl = 0; isl < PROB_W_SIZE; isl++) begin
	assign pc[isl] = `ROB.m_pc_b.slot[isl].r_data.data;
end

for (ibk = 0; ibk < PROB_W_NBANK; ibk++) begin
	for (isl = 0; isl < PROB_W_SIZE; isl++) begin
		initial rb[ibk][isl] = `ROB.bank[ibk].m_inst_b.
			               slot[isl].m_slot.my_rb;
	end
end

task printROB(virtual robtable #(21, 3) rb[0:3][0:7],
              input logic [31:4]         pc[PROB_W_SIZE]);
int i, j;
begin
	$write("           pc");
	for (j = 0; j < 4; j++)
		$write("   v b     uop prd   mask");
	$display;

	for (i = 0; i < 8; i++) begin
		$write("[%2d] %h", i, { pc[i], 4'b0 });
		for (j = 0; j < 4; j++) begin
			{ sl_uop, sl_prdo, sl_prdn } = rb[j][i].data;
			$write(" | %b %b %b %h->%h %b",
				rb[j][i].valid, rb[j][i].busy,
				sl_uop, sl_prdo, sl_prdn,
				rb[j][i].brmask);
		end
		$display;
	end
end
endtask

