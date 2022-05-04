
module demux1to4 #(parameter WIDTH = 32)
                 (output reg [WIDTH-1:0] o_q0, o_q1, o_q2, o_q3,
                  input wire [1:0]       i_s,
                  input wire [WIDTH-1:0] i_d);

always @(i_d, i_s)
begin
	o_q0 = {WIDTH{1'b0}};
	o_q1 = {WIDTH{1'b0}};
	o_q2 = {WIDTH{1'b0}};
	o_q3 = {WIDTH{1'b0}};

	case (i_s)
		2'b00: o_q0 = i_d;
		2'b01: o_q1 = i_d;
		2'b10: o_q2 = i_d;
		2'b11: o_q3 = i_d;
	endcase
end

endmodule

