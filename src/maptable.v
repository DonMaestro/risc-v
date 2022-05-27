/*
*  maptable
*/
module maptable #(parameter WIDTH = 5)
                (output [12*WIDTH-1:0] o_data12x,
                 input  [8*5-1:0]      i_addr8x,
                 input  [4*5-1:0]      i_waddr4x,
                 input  [4*WIDTH-1:0]  i_wdata4x,
                 input                 i_we, i_rst_n, i_clk);

localparam SIZE = $pow(2, WIDTH);
integer j;

reg  [WIDTH-1:0] ram[0:31];
wire [WIDTH-1:0] wdata[0:3];
wire [4:0] addr[0:11];

generate
	genvar i;
	for (i = 0; i < 8; i = i + 1) begin
		// write first 8 slots
		assign addr[i] = i_addr8x[(i+1)*5-1:i*5];
	end

	for (i = 0; i < 4; i = i + 1) begin
		// offset by 8 slots
		assign addr[i+8] = i_waddr4x[(i+1)*5-1:i*5];
		assign wdata[i] = i_wdata4x[(i+1)*WIDTH-1:i*WIDTH];
	end

	for (i = 0; i < 12; i = i + 1) begin
		assign o_data12x[(i+1)*WIDTH-1:i*WIDTH] = ram[addr[i]];
	end
endgenerate

always @(posedge i_clk, negedge i_rst_n)
begin
	if (!i_rst_n) begin
		for (j = 0; j < SIZE; j = j + 1) begin
			ram[j] = { WIDTH{1'b0} };
		end
		$writememh("Debug/mtab_rst.dat", ram);
	end else begin
		if (i_we) begin
			for (j = 0; j < 4; j = j + 1) begin
				ram[addr[j+8]] <= wdata[j];
			end
		end
	end
	ram[0] = { WIDTH{1'b0} };
end

endmodule

