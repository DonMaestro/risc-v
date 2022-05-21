module queue4in2 #(parameter SIZE = 32, WIDTH_REG = 5,
                   WIDTH_TAG = 5, WIDTH_BRM = 3,
                   WIDTH_I = 7 + WIDTH_BRM + WIDTH_TAG + 0 + 3*WIDTH_REG + 3,
                   WIDTH_O = 7 + WIDTH_BRM + WIDTH_TAG + 2 + 3*WIDTH_REG + 0)
                 (output [WIDTH_O-1:0] o_inst1,
                  output [WIDTH_O-1:0] o_inst2,
                  output               o_ready1,
                  output               o_ready2,
	          input  [WIDTH_I-1:0] i_inst1,
	          input  [WIDTH_I-1:0] i_inst2,
	          input  [WIDTH_I-1:0] i_inst3,
	          input  [WIDTH_I-1:0] i_inst4,
                  input  [4*WIDTH_REG-1:0] i_wdest4x,
                  input  [WIDTH_BRM:0] i_BrKill, // { enKill, BranchMask }
                  input i_en, i_rst_n, i_clk);

localparam LENGTH = SIZE / 2;
genvar i, j;

wire [LENGTH-1:0] request[0:2];
wire [LENGTH-1:0] grant[0:2];

wire [1:0] empty;
wire [WIDTH_I-1:0] data[0:1][0:LENGTH+1];
wire [WIDTH_O-1:0] grant_data[0:1];

assign data[0][LENGTH] = i_inst1;
assign data[1][LENGTH] = i_inst2;

assign data[0][LENGTH+1] = i_inst3;
assign data[1][LENGTH+1] = i_inst4;

assign o_inst1 = grant_data[0];
assign o_inst2 = grant_data[1];

assign o_ready1 = ~empty[0];
assign o_ready2 = ~empty[1];

generate
	for (i = 0; i < LENGTH; i = i + 1) begin: slot
		for (j = 0; j < 2; j = j + 1) begin: out
			issue_slot m_slot(.o_request(request[j][i]),
			                  .o_rslot(grant_data[j]),
			                  .o_data(data[j][i]),
			                  .i_data(data[j][i+2]),
			                  .i_WDest4x(i_wdest4x),
			                  .i_BrKill(i_BrKill),
			                  .i_grant(grant[j][i]),
			                  .i_en(i_en),
			                  .i_rst_n(i_rst_n),
			                  .i_clk(i_clk));
			defparam m_slot.WIDTH_REG = WIDTH_REG;
			defparam m_slot.WIDTH_TAG = WIDTH_TAG;
			defparam m_slot.TAG_BANK  = { i[0], j[0] };
			defparam m_slot.WIDTH_BRM = WIDTH_BRM;

		end

        end

	for (i = 0; i < 2; i = i + 1) begin
		queue_arbiter m_arbiters(.o_grant(grant[i]),
		                         .o_empty(empty[i]),
		                         .i_request(request[i]));
		defparam m_arbiters.WIDTH = LENGTH;
	end
endgenerate

endmodule

