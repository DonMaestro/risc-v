// data[WIDTH_I] = { BrMask, tag, RDst, RT, RS, val, p2, p1 }
module queue_mem #(parameter SIZE = 8, WIDTH_REG = 5,
                   WIDTH_TAG = 3, WIDTH_BRM = 3,
                   WIDTH_I = WIDTH_BRM + WIDTH_TAG + 3*WIDTH_REG + 4,
                   WIDTH_O = WIDTH_BRM + WIDTH_TAG + 3*WIDTH_REG + 2)
                 (output [WIDTH_O-1:0]          o_inst1,
                  output                        o_ready,
	          input  [WIDTH_I-1:0]          i_inst1,
	          input  [WIDTH_I-1:0]          i_inst2,
	          input  [WIDTH_I-1:0]          i_inst3,
	          input  [WIDTH_I-1:0]          i_inst4,
                  input  [4*WIDTH_REG-1:0]      i_wdest4x,
                  input  [(2 ** WIDTH_BRM)-1:0] i_brkill,
                  input                         i_en,
                  input                         i_rst_n,
                  input                         i_clk);

localparam LENGTH = SIZE;
genvar i;
integer j;

wire [LENGTH-1:0] request;
reg  [LENGTH-1:0] grant;
wire [1:0]        val[0:LENGTH-1];

wire empty;
wire [WIDTH_I-1:0] data[0:LENGTH+3];
wire [WIDTH_O-1:0] grant_data[0:LENGTH-1];

assign data[LENGTH]   = i_inst1;
assign data[LENGTH+1] = i_inst2;
assign data[LENGTH+2] = i_inst3;
assign data[LENGTH+3] = i_inst4;

assign o_inst1 = grant_data[grant];
assign o_ready = |request;

generate
	for (i = 0; i < LENGTH; i = i + 1) begin: slot
		queue_mem_slot m_slot(.o_request (request[i]),
		                      .o_rslot   (grant_data[i]),
		                      .o_data    (data[i]),
		                      .i_data    (data[i+4]),
		                      .i_WDest4x (i_wdest4x),
		                      .i_brkill  (i_brkill),
		                      .i_grant   (grant[i]),
		                      .i_en      (i_en),
		                      .i_rst_n   (i_rst_n),
		                      .i_clk     (i_clk));
		defparam m_slot.WIDTH_REG = WIDTH_REG;
		defparam m_slot.WIDTH_TAG = WIDTH_TAG;
		defparam m_slot.WIDTH_BRM = WIDTH_BRM;
		assign val[i] = data[i][3:2];
        end
endgenerate

always @(*)
begin
	grant = { LENGTH{1'b0} };
	for (j = LENGTH - 1; j >= 0; j = j - 1) begin
		if (|val[j])
			grant = {{(LENGTH-1){1'b0}}, 1'b1} << j;
	end
	
	if (!request[grant])
		grant = { LENGTH{1'b0} };
end

endmodule

