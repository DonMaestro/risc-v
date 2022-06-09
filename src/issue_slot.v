// data = { BrMask, tag, RDst, RS2, RS1, val, p2, p1 }

module issue_slot #(parameter WIDTH_REG = 5, WIDTH_TAG = 5, WIDTH_BRM = 3,
                              WIDTH_PRY = 2, TAG_BANK = 2'b00,
                              WIDTH_I = WIDTH_BRM + WIDTH_TAG + 0
                              + 3*WIDTH_REG + WIDTH_PRY + 3,
                              WIDTH_O = WIDTH_BRM + WIDTH_TAG + 2
                              + 3*WIDTH_REG +         0 + 0)
                  (output                   o_request,
                   output [WIDTH_PRY-1:0]   o_priority,
                   output [WIDTH_O-1:0]     o_rslot, // without ready flags
                   output [WIDTH_I-1:0]     o_data,
                   input  [WIDTH_I-1:0]     i_data,
                   input  [4*WIDTH_REG-1:0] i_WDest4x,
                   input  [$pow(2, WIDTH_BRM)-1:0] i_brkill,
                   input  i_grant, i_en, i_rst_n, i_clk);

`include "src/killf.v"

reg [WIDTH_I-1:3] data;
wire [WIDTH_O-1:0] rslot;
wire            p1, p2, val;

wire [WIDTH_REG-1:0] WDest[0:3];
wire RS1eqWD[0:3];
wire RS2eqWD[0:3];

wire [WIDTH_BRM-1:0] BrMask;
wire [WIDTH_TAG-1:0] Tag;
wire [WIDTH_REG-1:0] RD, RS1, RS2;
wire [WIDTH_PRY-1:0] PRY; // Priority

wire Dp1, Dp2, i_p1, i_p2;
wor  checkp1, checkp2;
wire killslot;
wire Dval, rstVal, i_val;

// input px bit
assign { i_val, i_p2, i_p1 } = i_data[2:0];

assign { BrMask, Tag, RD, RS2, RS1, PRY } = data[WIDTH_I-1:3];

// logic

// kill logic
assign killslot = killf(BrMask, i_brkill);

assign checkp1 = p1;
assign checkp2 = p2;
generate
	genvar i;
	for (i = 0; i < 4; i = i + 1) begin
		assign WDest[i] = i_WDest4x[(i+1)*WIDTH_REG-1:i*WIDTH_REG];
		comparator #(WIDTH_REG) cm_rs1(RS1eqWD[i], WDest[i], RS1);
		comparator #(WIDTH_REG) cm_rs2(RS2eqWD[i], WDest[i], RS2);
		assign checkp1 = RS1eqWD[i];
		assign checkp2 = RS2eqWD[i];
	end
endgenerate

mux2in1 #(1) mux_p1(Dp1, i_en, checkp1, i_p1);
mux2in1 #(1) mux_p2(Dp2, i_en, checkp2, i_p2);

register #(1) r_p1(p1, 1'b1, Dp1, i_rst_n, i_clk);
register #(1) r_p2(p2, 1'b1, Dp2, i_rst_n, i_clk);

// reset val if branch kill or read slot
assign rstVal = val & ~killslot & ~i_grant;

mux2in1 #(1) mux_val(Dval, i_en, rstVal, i_val);

register #(1) r_val(val, 1'b1, Dval, i_rst_n, i_clk);

// request flag
assign o_request = val & p1 & p2;
assign o_priority = PRY;

// read logic
assign rslot = { BrMask, Tag, TAG_BANK, RD, RS2, RS1 };
assign o_rslot = i_grant ? rslot : { WIDTH_O{1'bZ} };

// read logic
assign o_data = { data, rstVal, checkp2, checkp1 };

// write logic
always @(posedge i_clk)
begin
	if (i_en) begin
		data <= i_data[WIDTH_I-1:3];
	end
end

endmodule

