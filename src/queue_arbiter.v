module queue_arbiter #(parameter WIDTH = 4)
                     (output reg [WIDTH-1:0] o_grant,
                      output             o_empty,
                      input  [WIDTH-1:0] i_request);
integer i;

assign o_empty = ~|i_request;

always @(*)
begin
	o_grant = { WIDTH{1'b0} };
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

