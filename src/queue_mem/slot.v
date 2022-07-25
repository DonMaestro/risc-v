// data = { BrMask, tag, RDst, RT, RS, val, p2, p1 }

module queue_mem_slot #(parameter WIDTH_REG = 5, WIDTH_TAG = 3, WIDTH_BRM = 3,
                        WIDTH_I = WIDTH_BRM + WIDTH_TAG + 3*WIDTH_REG + 4,
                        WIDTH_O = WIDTH_BRM + WIDTH_TAG + 3*WIDTH_REG + 2)
                      (output                        o_request,
                       output [WIDTH_O-1:0]          o_rslot, // without flags
                       output [WIDTH_I-1:0]          o_data,
                       input  [WIDTH_I-1:0]          i_data,
                       input  [4*WIDTH_REG-1:0]      i_WDest4x,
                       input  [(2 ** WIDTH_BRM)-1:0] i_brkill,
                       input  i_grant, i_en, i_rst_n, i_clk);

wire       i_p1, i_p2;
wire [1:0] i_val;

reg  [WIDTH_I-1:4] data;
wire               p1, p2;
wire [1:0]         val;

wire [WIDTH_BRM-1:0] BrMask;
wire [WIDTH_TAG-1:0] Tag;
wire [WIDTH_REG-1:0] RD, RS, RT;

wire [WIDTH_REG-1:0] WDest[0:3];
wor  checkp1, checkp2;
wire Dp1, Dp2;

wire killslot;
wire [1:0] Dval, rstVal;

wire [WIDTH_O-1:0] rslot;

// input px bit
assign { i_val, i_p2, i_p1 } = i_data[3:0];

assign { BrMask, Tag, RD, RT, RS } = data[WIDTH_I-1:4];

// logic

assign checkp1 = p1;
assign checkp2 = p2;
generate
	genvar i;
	for (i = 0; i < 4; i = i + 1) begin: check
		assign WDest[i] = i_WDest4x[(i+1)*WIDTH_REG-1:i*WIDTH_REG];
		assign checkp1 = WDest[i] == RS;
		assign checkp2 = WDest[i] == RT;
	end
endgenerate

mux2in1 #(1) mux_p1(Dp1, i_en, checkp1, i_p1);
mux2in1 #(1) mux_p2(Dp2, i_en, checkp2, i_p2);

register #(1) r_p1(p1, 1'b1, Dp1, i_rst_n, i_clk);
register #(1) r_p2(p2, 1'b1, Dp2, i_rst_n, i_clk);

// reset val if branch kill or read slot
// kill logic
killf #(WIDTH_BRM) m_killf(killslot, BrMask, i_brkill);

assign rstVal[0] = val[0] & ~killslot & ~i_grant & p1;
assign rstVal[1] = val[1] & ~killslot & ~i_grant & p2;

mux2in1 #(2) mux_val(Dval, i_en, rstVal, i_val);

register #(2) r_val(val, 1'b1, Dval, i_rst_n, i_clk);

// request flag
assign o_request = val[0] & p1 | val[1] & p2;

// read logic
assign rslot = { BrMask, Tag, RD, RT, RS, val };
//assign o_rslot = i_grant ? rslot : { WIDTH_O{1'bZ} };
assign o_rslot = rslot;

// read logic
assign o_data = { data, rstVal, checkp2, checkp1 };

// write logic
always @(posedge i_clk)
begin
	if (i_en) begin
		data <= i_data[WIDTH_I-1:4];
	end
end

endmodule

