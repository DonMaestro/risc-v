module alu_mem(output reg [31:0] o_addr,
               output reg [31:0] o_data,
               output reg        o_we,
               input wire [6:0]  i_uop,
               input wire [2:0]  i_funct3,
               input wire [31:0] i_op1, i_op2,
               input wire [11:0] i_imm,
               input wire        i_clk);

localparam LB = 3'h0, LH = 3'h1, LW = 3'h2, LBU = 3'h4, LHU = 3'h5;
localparam SB = 3'h0, SH = 3'h1, SW = 3'h2;
localparam IT = 7'b0000011, ST = 7'b0100011;

wire [31:0] addr, data;
wire [31:0] imm;
assign imm = { { 20{ i_imm[11] } }, i_imm };

assign addr = i_op1 + imm;
assign data = i_op2;

always @(posedge i_clk)
begin
	o_addr  <= addr;
	o_data  <= data;
	o_we    <= ( i_uop == ST ) ? 1'b1 : 1'b0;
end

endmodule

