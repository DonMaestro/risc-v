module comparator #(parameter WIDTH_SAQ = 2, WIDTH_LAQ = 2,
                              SIZE_SAQ = 2 ** WIDTH_SAQ,
                              SIZE_LAQ = 2 ** WIDTH_LAQ,
                              WIDTH_REG = 7, WIDTH_TAG = 4,
                              WIDTH_ADDR = 32,
                              DATA_SAQ = 4 + WIDTH_ADDR + WIDTH_TAG,
                              DATA_LAQ = 5 + WIDTH_ADDR + WIDTH_REG + WIDTH_TAG)
                  (output wor                     o_comp_saq,
                   output reg [WIDTH_SAQ-1:0]     o_saq_addr,
                   output wor                     o_comp_saq_D,
                   output reg [WIDTH_SAQ-1:0]     o_saq_addr_D,
                   output wor                     o_comp_laq,
                   output reg [WIDTH_LAQ-1:0]     o_laq_addr,
                   output reg [WIDTH_REG-1:0]     o_rd,
                   input  [WIDTH_ADDR-1:0]        i_addr,
                   input  [DATA_LAQ*SIZE_LAQ-1:0] i_cells_laq,
                   input  [DATA_SAQ*SIZE_SAQ-1:0] i_cells_saq);

wire                  ent_type;
wire [WIDTH_TAG-1:0]  ent_tag;

wire                  saq_A[0:SIZE_SAQ-1];
wire                  saq_val[0:SIZE_SAQ-1];
wire [WIDTH_ADDR-1:0] saq_addr[0:SIZE_SAQ-1];
wire                  saq_V[0:SIZE_SAQ-1];
wire                  saq_D[0:SIZE_SAQ-1];
wire [WIDTH_TAG-1:0]  saq_tag[0:SIZE_SAQ-1];

wire                  laq_A[0:SIZE_LAQ-1];
wire                  laq_val[0:SIZE_LAQ-1];
wire [WIDTH_ADDR-1:0] laq_addr[0:SIZE_LAQ-1];
wire                  laq_V[0:SIZE_LAQ-1];
wire                  laq_S[0:SIZE_LAQ-1];
wire                  laq_M[0:SIZE_LAQ-1];
wire [WIDTH_REG-1:0]  laq_rd[0:SIZE_LAQ-1];
wire [WIDTH_TAG-1:0]  laq_tag[0:SIZE_LAQ-1];

wire                  comp_saq[0:SIZE_SAQ-1];
wire                  comp_laq[0:SIZE_LAQ-1];

generate
	genvar i;
	for (i = 0; i < SIZE_SAQ; i = i + 1) begin: array_entry_saq
		assign {
			saq_A[i],
			saq_val[i],
			saq_addr[i],
			saq_V[i],
			saq_D[i],
			saq_tag[i]
		} = i_cells_saq[(i+1) * DATA_SAQ - 1 : i * DATA_SAQ];
		assign comp_saq[i] = saq_A[i] & saq_val[i]
		                     & saq_addr[i] == i_addr;
		assign o_comp_saq   = comp_saq[i];
		assign o_comp_saq_D = comp_saq[i] & ~saq_D[i];
	end

	for (i = 0; i < SIZE_LAQ; i = i + 1) begin: array_entry_laq
		assign {
			laq_A[i],
			laq_val[i],
			laq_addr[i],
			laq_V[i],
			laq_S[i],
			laq_M[i],
			laq_rd[i],
			laq_tag[i]
		} = i_cells_laq[(i+1) * DATA_LAQ - 1 : i * DATA_LAQ];
		assign comp_laq[i] = laq_A[i]
		                     & laq_addr[i] == i_addr;
		assign o_comp_laq = comp_laq[i];
	end
endgenerate

integer g;

always @(*)
begin
	for (g = SIZE_SAQ - 1; g >= 0; g = g - 1) begin
		if (comp_saq[g]) begin
			o_saq_addr = g[WIDTH_SAQ-1:0];
			if (!saq_D[g])
				o_saq_addr_D = g[WIDTH_SAQ-1:0];
		end
	end

	for (g = SIZE_LAQ - 1; g >= 0; g = g - 1) begin
		if (comp_laq[g]) begin
			o_laq_addr = g[WIDTH_LAQ-1:0];
			o_rd       = laq_rd[g];
		end
	end
end

endmodule

