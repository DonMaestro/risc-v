
genvar i, j;
localparam PQUE1_W_SIZE  = `QUE1.LENGTH;
localparam PQUE2_W_SIZE  = `QUE2.LENGTH;

bind issue_slot qintf _qi(
	.uop    (UOPCode),
	.brmask (BrMask),
	.tag    (tag),
	.valid  (val),
	.RD     (RD),
	.p2     (p2),
	.RS2    (RS2),
	.p1     (p1),
	.RS1    (RS1)
);

static virtual qintf qi1[PQUE1_W_SIZE];
static virtual qintf qi2[PQUE2_W_SIZE][2];

for (i = 0; i < PQUE1_W_SIZE; i++) begin
	initial qi1[i] = `QUE1.slot[i].m_slot._qi;
end

for (i = 0; i < PQUE2_W_SIZE; i++) begin
	for (j = 0; j < 2; j++) begin
		initial qi2[i][j] = `QUE2.slot[i].out[j].m_slot._qi;
	end
end

task printQUE2(virtual qintf qi[PQUE2_W_SIZE][2]);
int i, j;
begin
	$write("    ");
	for (j = 0; j < 2; j++)
		$write("   uop mask tag val RD p2 RS1 p1 RS1");
	$display;

	for (i = 0; i < PQUE2_W_SIZE; i++) begin
		$write("[%2d]", i);
		for (j = 0; j < 2; j++) begin
			$write(" | %b %b %b %b %d %b %d %b %d",
				qi[i][j].uop, qi[i][j].brmask,
				qi[i][j].tag,
				qi[i][j].valid, qi[i][j].RD,
				qi[i][j].p2, qi[i][j].RS2,
				qi[i][j].p1, qi[i][j].RS1);
		end
		$display;
	end
end
endtask

task printQUE1(virtual qintf qi[PQUE1_W_SIZE]);
int i, j;
begin
	$write("    ");
	for (j = 0; j < 2; j++)
		$write("   uop mask tag val RD p2 RS1 p1 RS1");
	$display;

	for (i = 0; i < PQUE1_W_SIZE; i += 2) begin
		$write("[%2d]", i);
		for (j = 0; j < 2; j++) begin
			$write(" | %b %b %b %b %d %b %d %b %d",
				qi[i+j].uop, qi[i+j].brmask,
				qi[i+j].tag,
				qi[i+j].valid, qi[i+j].RD,
				qi[i+j].p2, qi[i+j].RS2,
				qi[i+j].p1, qi[i+j].RS1);
		end
		$display;
	end
end
endtask

