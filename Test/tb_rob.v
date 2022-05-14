`timescale 1 ns / 1 ns
`include "src/ringbuf.v"
`include "src/register.v"
`include "src/rob.v"
`include "src/encoder.v"

module tb_rob;

integer i;
localparam WIDTH_BANK = 3;
localparam WIDTH_REG = 7;
localparam WIDTH_BRM = 4;
localparam WIDTH = 2 + 7 + 32 + WIDTH_REG + WIDTH_BRM;

localparam WIDTH_BRST = 1 + WIDTH_BANK + 2; // 4 banks

reg rst_n, clk;

reg                     we;
reg  [31:0]             PC;
wire [4*WIDTH-1:0]      data4x;
wire [4*WIDTH_BRST-1:0] rst4x_busy;

wire [WIDTH_BANK-1:0]  o_tag;
wire [4*WIDTH_REG-1:0] o_com_prd4x;
wire                   o_com_en;
 
reg [WIDTH-1:0]      data[0:3];
reg                  val[0:3];
reg                  busy[0:3];
reg [7-1:0]          uop[0:3];
reg [WIDTH_BRM-1:0]  brm[0:3];
reg [WIDTH_REG-1:0]  prd[0:3];
reg [32-1:0]         imm[0:3];
reg [WIDTH_BRST-1:0] rst_busy[0:3]; // EN[1] + [WIDTH_BANK] + SET_BANK[2]

always @(*)
begin
	for (i = 0; i < 4; i = i + 1) begin
		data[i] = { val[i], busy[i], uop[i], imm[i], prd[i], brm[i]};
	end
end

assign data4x = { data[3], data[2], data[1], data[0] };

rob m_rob(.o_dis_tag(o_tag),
          .o_com_prd4x(o_com_prd4x),
          .o_com_en(o_com_en),
          .i_dis_pc(PC),
          .i_dis_data4x(data4x),
          .i_dis_we(we),
          .i_kill({ (WIDTH_BRM+1){1'b0} }),
          .i_rst_busy0(rst_busy[0]),
          .i_rst_busy1(rst_busy[1]),
          .i_rst_busy2(rst_busy[2]),
          .i_rst_busy3(rst_busy[3]),
          .i_rst_n(rst_n),
          .i_clk(clk));
defparam m_rob.WIDTH_BANK = WIDTH_BANK;
defparam m_rob.WIDTH_REG  = WIDTH_REG;
defparam m_rob.WIDTH_BRM  = WIDTH_BRM;

initial
begin
	rst_n = 1'b0;
	rst_n <= #1 1'b1;

	we = 1'b1;

	PC = 32'b0;
	val[0] = 1'b1; val[1] = 1'b1; val[2] = 1'b1; val[3] = 1'b1;
	busy[0] = 1'b1; busy[1] = 1'b1; busy[2] = 1'b1; busy[3] = 1'b1;

	uop[0] = 7'h4f;
	uop[1] = 7'h40;
	uop[2] = 7'h03;
	uop[3] = 7'h05;

	brm[0] = 4'b0001;
	brm[1] = 4'b0001;
	brm[2] = 4'b0010;
	brm[3] = 4'b0010;

	prd[0] = 7'h0;
	prd[1] = 7'h1;
	prd[2] = 7'h2;
	prd[3] = 7'h3;

	imm[0] = 32'hff000000;
	imm[1] = 32'hff0000;
	imm[2] = 32'hff00;
	imm[3] = 32'hff;

end

initial
begin
	rst_busy[0] = { 1'b0, 3'h0, 2'b00 };
	rst_busy[1] = { 1'b0, 3'h0, 2'b01 };
	rst_busy[2] = { 1'b0, 3'h0, 2'b10 };
	rst_busy[3] = { 1'b0, 3'h0, 2'b11 };

	#40
	rst_busy[0] = { 1'b1, 3'h0, 2'b00 };
	rst_busy[1] = { 1'b1, 3'h0, 2'b01 };
	rst_busy[2] = { 1'b1, 3'h0, 2'b10 };
	rst_busy[3] = { 1'b1, 3'h0, 2'b11 };

	#40
	rst_busy[0] = { 1'b1, 3'h1, 2'b00 };
	rst_busy[1] = { 1'b1, 3'h1, 2'b01 };
	rst_busy[2] = { 1'b1, 3'h1, 2'b10 };
	rst_busy[3] = { 1'b1, 3'h1, 2'b11 };
end

always @(posedge clk)
begin
	PC <= PC + 16; // 4 insturtions(each 4 byte)
	brm[0] <= brm[0] + 4'h1;
	brm[1] <= brm[1] + 4'h1;
	brm[2] <= brm[2] + 4'h1;
	brm[3] <= brm[3] + 4'h1;
end

initial
begin
	clk = 1'b0;
	forever #20 clk = ~clk;
end

initial
begin
	$dumpfile("Debug/rob.vcd");
	$dumpvars;

	#1000 $finish;
end

endmodule

