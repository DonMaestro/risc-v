module SDQ #(parameter WIDTH = 5)
           (output [31:0]      o_data, 
            input  [31:0]      i_data,
            input  [WIDTH-1:0] i_tag,
            input  [WIDTH-1:0] i_raddr,
            input              i_en,
            input              i_rst_n, i_clk);

localparam SIZE = 2 ** WIDTH;
integer i, j;

reg [31:0] data[0:SIZE-1]; 
reg        val [0:SIZE-1]; 

always @(posedge i_clk, negedge i_rst_n)
begin
	if (!i_rst_n) begin
		for (j = 0; j < SIZE; j = j + 1) begin
			data[j] <= 32'b0;
			val [j] <=  1'b0;
		end
	end else begin
		if (i_en) begin
			data[i_tag] <= i_data;
			val [i_tag] <= 1'b1;
		end
	end
end

assign o_data = data[i_raddr];

endmodule

