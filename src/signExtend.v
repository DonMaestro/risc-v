module signExtend(output reg [31:0] o_data,
                  input      [ 2:0] i_en,
                  input      [31:7] i_data);

`include "src/IType.v"

always @(*)
begin
	case (i_en)
		RT: o_data = { { 20{i_data[31]} }, i_data[31:25], 5'b0 };
		IT: o_data = { { 20{i_data[31]} }, i_data[31:20] };
		ST: o_data = { { 20{i_data[31]} }, i_data[31:25], i_data[11:7] };
		BT: o_data = { { 20{i_data[31]} }, i_data[7],
		                        i_data[30:25], i_data[11:8], 1'b0 };
		JT: o_data = { { 12{i_data[31]} }, i_data[19:12],
		                        i_data[20], i_data[30:21], 1'b0 };
		UT: o_data = { i_data[31:12], 12'b0 };
		default: o_data = 31'bX;
	endcase
end

endmodule

