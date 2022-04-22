module mux2in1 #(parameter WIDTH = 32)
               (output reg [WIDTH-1:0] o_dat,
                input             i_control,
                input [WIDTH-1:0] i_dat0, i_dat1);

always @(*)
begin
	case (i_control)
		0: o_dat <= i_dat0;
		1: o_dat <= i_dat1;
	endcase
end

endmodule

