`include "src/issue_slot.v"

module queue4in2 #(parameter SIZE = 32, WIDTH_REG = 5,
                             WIDTH_TAG = 5, WIDTH_BRM = 3,
                             WIDTH = 7 + WIDTH_BRM + WIDTH_TAG + 3*WIDTH_REG + 3)
                 (output [WIDTH-1:0] o_inst1,
                  output [WIDTH-1:0] o_inst2,
                  output             o_ready1,
                  output             o_ready2,
	          input  [WIDTH-1:0] i_inst1,
	          input  [WIDTH-1:0] i_inst2,
	          input  [WIDTH-1:0] i_inst3,
	          input  [WIDTH-1:0] i_inst4,
                  input  [4*WIDTH_REG-1:0] i_wdest4x,
                  input  [WIDTH_BRM-1:0] i_BrKill,
                  input i_en, i_rst_n, i_clk);

localparam LENGTH = SIZE / 2;
genvar i, j;

wire [LENGTH-1:0] request[0:2];
wire [LENGTH-1:0] grant[0:2];

wire [1:0] empty;
wire [WIDTH-1:0] data[0:1][0:LENGTH+1];
wire [WIDTH-4:0] grant_data[0:1];

assign data[0][LENGTH] = i_inst1;
assign data[1][LENGTH] = i_inst2;

assign data[0][LENGTH+1] = i_inst3;
assign data[1][LENGTH+1] = i_inst4;

assign o_inst1 = grant_data[0];
assign o_inst2 = grant_data[1];

assign o_ready1 = ~empty[0];
assign o_ready2 = ~empty[1];

generate
	for (i = 0; i < LENGTH; i = i + 1) begin
		for (j = 0; j < 2; j = j + 1) begin
			issue_slot mod_slot(.o_request(request[j][i]),
			                    .o_rslot(grant_data[j]),
			                    .o_data(data[j][i]),
			                    .i_data(data[j][i+2]),
			                    .i_WDest4x(i_wdest4x),
			                    .i_BrKill(i_BrKill),
			                    .i_grant(grant[j][i]),
			                    .i_en(i_en),
			                    .i_rst_n(i_rst_n),
			                    .i_clk(i_clk));
			defparam mod_slot.WIDTH_REG = WIDTH_REG;
			defparam mod_slot.WIDTH_TAG = WIDTH_TAG;
			defparam mod_slot.WIDTH_BRM = WIDTH_BRM;

		end

        end

	for (i = 0; i < 2; i = i + 1) begin
		arbiters mod_arbiters(.o_grant(grant[i]),
		                      .o_empty(empty[i]),
		                      .i_request(request[i]));
		defparam mod_arbiters.WIDTH = LENGTH;
	end
endgenerate

endmodule

module arbiters #(parameter WIDTH = 4)
                (output reg [WIDTH-1:0] o_grant,
                 output             o_empty,
                 input  [WIDTH-1:0] i_request);
integer i;

assign o_empty = ~|i_request;

always @(*)
begin
	for (i = WIDTH - 1; i >= 0; i = i - 1) begin
		if (i_request[i])
			o_grant = 1 << i;
	end
end

endmodule
/*
module arbiters #(parameter WIDTH = 4)
                (output [WIDTH-1:0] o_grant,
                 output             o_empty,
                 input  [WIDTH-1:0] i_request);
genvar i;
wire [WIDTH-1:0] gg;

assign o_empty = ~|i_request;

assign gg[0] = ~i_request[0];

generate
	for (i = 1; i < WIDTH; i = i + 1) begin
		assign gg[i] = ~gg[i-1] & ~i_request[i];
	end

	for (i = 0; i < WIDTH; i = i + 1) begin
		assign o_grant[i] = gg[i] & i_request[i];
	end
endgenerate

endmodule
*/

