
module busytb #(parameter WIDTH = 5)
              (output [2-1:0]       o_data1,
               output [2-1:0]       o_data2,
               output [2-1:0]       o_data3,
               output [2-1:0]       o_data4,
               input  [2*WIDTH-1:0] i_addr1,
               input  [2*WIDTH-1:0] i_addr2,
               input  [2*WIDTH-1:0] i_addr3,
               input  [2*WIDTH-1:0] i_addr4,
               input  [4*WIDTH-1:0] i_setAddr4x,
               input  [4*WIDTH-1:0] i_rstAddr4x,
               input                i_rst_n,
               input                i_clk);

integer i;
localparam SIZE = $pow(2, WIDTH);

reg busy[0:SIZE-1];
wire [WIDTH-1:0] addr_set[0:3];
wire [WIDTH-1:0] addr_rst[0:3];

generate
	genvar j;
	for (j = 0; j < 4; j = j + 1) begin
		assign addr_set[j] = i_setAddr4x[(j+1)*WIDTH-1:j*WIDTH];
		assign addr_rst[j] = i_rstAddr4x[(j+1)*WIDTH-1:j*WIDTH];
	end

	for (j = 0; j < 2; j = j + 1) begin
		assign o_data1[j] = busy[i_addr1[(j+1)*WIDTH-1:j*WIDTH]];
		assign o_data2[j] = busy[i_addr2[(j+1)*WIDTH-1:j*WIDTH]];
		assign o_data3[j] = busy[i_addr3[(j+1)*WIDTH-1:j*WIDTH]];
		assign o_data4[j] = busy[i_addr4[(j+1)*WIDTH-1:j*WIDTH]];
	end
endgenerate

always @(posedge i_clk, negedge i_rst_n)
begin
	if (!i_rst_n)
		for (i = 1; i < SIZE; i = i + 1)
			busy[i] = 1'b1;
	else begin

		for (i = 0; i < WIDTH; i = i + 1) begin
			busy[addr_set[i]] <= 1'b1;
			busy[addr_rst[i]] <= 1'b0;
		end

	end
	busy[0] <= 1'b0;
end

endmodule

