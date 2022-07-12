module comparator #(parameter WIDTH_SAQ = 2, WIDTH_LAQ = 2,
                              SIZE_SAQ = 2 ** WIDTH_SAQ,
                              SIZE_LAQ = 2 ** WIDTH_LAQ,
                              WIDTH_REG = 7, WIDTH_TAG = 4,
                              WIDTH_ADDR = 32,
                              DATA_ENT = 1 + WIDTH_ADDR + WIDTH_TAG,
                              DATA_SAQ = 4 + WIDTH_ADDR + WIDTH_TAG,
                              DATA_LAQ = 4 + WIDTH_ADDR + WIDTH_REG + WIDTH_TAG)
                  (output wor                     o_comp_saq,
                   output wor                     o_comp_laq,
                   output [WIDTH_SAQ-1:0]         o_sdq_addr,
                   output [WIDTH_REG-1:0]         o_rd,
                   input  [DATA_ENT-1:0]          i_entry,
                   input  [DATA_LAQ*SIZE_LAQ-1:0] entries_laq,
                   input  [DATA_SAQ*SIZE_SAQ-1:0] entries_saq);

wire                  ent_type;
wire [WIDTH_ADDR-1:0] ent_addr;
wire [WIDTH_TAG-1:0]  ent_tag;

wire                  saq_A[0:SIZE_SAQ-1];
wire                  saq_val[0:SIZE_SAQ-1];
wire [WIDTH_ADDR-1:0] saq_addr[0:SIZE_SAQ-1];
wire                  saq_V[0:SIZE_SAQ-1];
wire                  saq_aval[0:SIZE_SAQ-1];
wire [WIDTH_TAG-1:0]  saq_tag[0:SIZE_SAQ-1];

wire                  laq_A[0:SIZE_LAQ-1];
wire                  laq_val[0:SIZE_LAQ-1];
wire [WIDTH_ADDR-1:0] laq_addr[0:SIZE_LAQ-1];
wire                  laq_V[0:SIZE_LAQ-1];
wire                  laq_M[0:SIZE_LAQ-1];
wire [WIDTH_REG-1:0]  laq_rd[0:SIZE_LAQ-1];
wire [WIDTH_TAG-1:0]  laq_tag[0:SIZE_LAQ-1];

assign { ent_type, ent_addr, ent_tag } = i_entry;

generate
	genvar i;
	for (i = 0; i < SIZE_SAQ; i = i + 1) begin: array_entry_saq
		assign {
			saq_A[i],
			saq_val[i],
			saq_addr[i],
			saq_V[i],
			saq_tag[i],
			saq_aval[i]
		} = entries_saq[(i+1) * DATA_SAQ - 1 : i * DATA_SAQ];
		assign o_comp_saq = saq_A[i] & saq_val[i]
		                    & saq_addr[i] == ent_addr;
	end

	for (i = 0; i < SIZE_LAQ; i = i + 1) begin: array_entry_laq
		assign {
			laq_A[i],
			laq_val[i],
			laq_addr[i],
			laq_V[i],
			laq_M[i],
			laq_rd[i],
			laq_tag[i]
		} = entries_laq[(i+1) * DATA_LAQ - 1 : i * DATA_LAQ];
		assign o_comp_laq = laq_A[i] & ~laq_val[i]
		                    & laq_addr[i] == ent_addr;
		assign o_rd = o_comp_laq ? laq_rd[i] : o_rd;
	end
endgenerate

endmodule

