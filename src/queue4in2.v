module queue4in2 #(parameter SIZE = 32, WIDTH_REG = 5,
                   WIDTH_TAG = 5, WIDTH_BRM = 3, WIDTH_PRY = 2,
                   WIDTH_I = 7 + WIDTH_BRM + WIDTH_TAG + 0 + 3*WIDTH_REG + WIDTH_PRY + 3,
                   WIDTH_O = 7 + WIDTH_BRM + WIDTH_TAG + 2 + 3*WIDTH_REG +         0 + 0)
                 (output [WIDTH_O-1:0] o_inst1,
                  output [WIDTH_O-1:0] o_inst2,
                  output               o_ready1,
                  output               o_ready2,
	          input  [WIDTH_I-1:0] i_inst1,
	          input  [WIDTH_I-1:0] i_inst2,
	          input  [WIDTH_I-1:0] i_inst3,
	          input  [WIDTH_I-1:0] i_inst4,
                  input  [4*WIDTH_REG-1:0] i_wdest4x,
                  input  [$pow(2, WIDTH_BRM)-1:0] i_brkill,
                  input i_en, i_rst_n, i_clk);

localparam LENGTH = SIZE / 2;
genvar i, j;

wire [LENGTH-1:0] request[0:1];
reg  [LENGTH-1:0] grant[0:1];
wire [LENGTH-1:0] gg[0:1];
assign gg[0] = grant[0];
assign gg[1] = grant[1];

wire [LENGTH-1:0] only_br[0:1];
wire [LENGTH-1:0] pry_br[0:1];
wire [LENGTH-1:0] only_alu[0:1];
wire [LENGTH-1:0] pry_alu[0:1];

reg ctrl;
reg [1:0] empty;

wire [1:0] empty_br, empty_alu;
wire [WIDTH_I-1:0]   data[0:1][0:LENGTH+2-1];
wire [WIDTH_O-1:0]   rslot[0:1];

wire [WIDTH_PRY-1:0] pry[0:1][0:LENGTH-1];

assign data[0][LENGTH] = i_inst1;
assign data[1][LENGTH] = i_inst2;

assign data[0][LENGTH+1] = i_inst3;
assign data[1][LENGTH+1] = i_inst4;

assign o_ready1 = ~empty[0];
assign o_ready2 = ~empty[1];

generate
	for (i = 0; i < LENGTH; i = i + 1) begin: slot
		for (j = 0; j < 2; j = j + 1) begin: out
			issue_slot m_slot(.o_request(request[j][i]),
			                  .o_priority(pry[j][i]),
			                  .o_rslot(rslot[j]),
			                  .o_data(data[j][i]),
			                  .i_data(data[j][i+2]),
			                  .i_WDest4x(i_wdest4x),
			                  .i_brkill(i_brkill),
			                  .i_grant(grant[j][i]),
			                  .i_en(i_en),
			                  .i_rst_n(i_rst_n),
			                  .i_clk(i_clk));
			defparam m_slot.WIDTH_REG = WIDTH_REG;
			defparam m_slot.WIDTH_TAG = WIDTH_TAG;
			defparam m_slot.WIDTH_PRY = WIDTH_PRY;
			defparam m_slot.TAG_BANK  = { i[0], j[0] };
			defparam m_slot.WIDTH_BRM = WIDTH_BRM;

			assign only_br[j][i] = request[j][i] & (pry[j][i] ~^ 2'b11);
			assign only_alu[j][i] = request[j][i] & (pry[j][i] ~^ 2'b00);
		end

        end

	for (i = 0; i < 2; i = i + 1) begin: arbiter
		queue_arbiter m_only_br(.o_grant(pry_br[i]),
		                         .o_empty(empty_br[i]),
		                         .i_request(only_br[i]));
		defparam m_only_br.WIDTH = LENGTH;

		queue_arbiter m_arbiters(.o_grant(pry_alu[i]),
		                         .o_empty(empty_alu[i]),
		                         .i_request(only_alu[i]));
		defparam m_arbiters.WIDTH = LENGTH;
	end
endgenerate

always @(*)
begin
	ctrl = 1'b0;
	grant[0] = pry_alu[0];
	grant[1] = pry_alu[1];
	empty[0] = empty_alu[0];
	empty[1] = empty_alu[1];

	if (!empty_br[1]) begin
		ctrl = 1'b1;
		grant[1] = pry_br[1];
		empty[0] = empty_alu[0];
		empty[1] = empty_br[1];
	end else if (!empty_br[0]) begin
		grant[0] = pry_br[0];
		empty[0] = empty_br[0];
		empty[1] = empty_alu[1];
	end
end

mux2in1 mux_port0(o_inst1, ctrl, rslot[0], rslot[1] );
defparam mux_port0.WIDTH = WIDTH_O;
mux2in1 mux_port1(o_inst2, ctrl, rslot[1], rslot[0] );
defparam mux_port1.WIDTH = WIDTH_O;

endmodule

