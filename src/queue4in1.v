module queue4in1 #(parameter SIZE = 32, WIDTH_REG = 5,
                             WIDTH_TAG = 5, WIDTH_BRM = 3,
                             WIDTH = 7 + WIDTH_BRM + WIDTH_TAG + 3*WIDTH_REG + 3)
                 (output [WIDTH-1:0] o_inst1,
                  output             o_ready,
	          input  [WIDTH-1:0] i_inst1,
	          input  [WIDTH-1:0] i_inst2,
	          input  [WIDTH-1:0] i_inst3,
	          input  [WIDTH-1:0] i_inst4,
                  input  [4*WIDTH_REG-1:0] i_wdest4x,
                  input  [WIDTH_BRM-1:0] i_BrKill,
                  input i_en, i_rst_n, i_clk);

localparam LENGTH = SIZE;
genvar i, j;

wire [LENGTH-1:0] request;
wire [LENGTH-1:0] grant;

wire empty;
wire [WIDTH-1:0] data[0:LENGTH+3];
wire [WIDTH-4:0] grant_data;

assign data[LENGTH]   = i_inst1;
assign data[LENGTH+1] = i_inst2;
assign data[LENGTH+2] = i_inst3;
assign data[LENGTH+3] = i_inst4;

assign o_inst1 = grant_data;
assign o_ready = ~empty;

generate
	for (i = 0; i < LENGTH; i = i + 1) begin
		issue_slot mod_slot(.o_request(request[i]),
		                    .o_rslot(grant_data),
		                    .o_data(data[i]),
		                    .i_data(data[i+4]),
		                    .i_WDest4x(i_wdest4x),
		                    .i_BrKill(i_BrKill),
		                    .i_grant(grant[i]),
		                    .i_en(i_en),
		                    .i_rst_n(i_rst_n),
		                    .i_clk(i_clk));
		defparam mod_slot.WIDTH_REG = WIDTH_REG;
		defparam mod_slot.WIDTH_TAG = WIDTH_TAG;
		defparam mod_slot.WIDTH_BRM = WIDTH_BRM;
        end

	queue_arbiter mod_arbiters(.o_grant(grant),
	                           .o_empty(empty),
	                           .i_request(request));
	defparam mod_arbiters.WIDTH = LENGTH;
endgenerate

endmodule

