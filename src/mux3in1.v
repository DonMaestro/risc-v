module mux3in1 #(parameter WIDTH = 32)
               (output reg [WIDTH-1:0] o_dat,
                input [1:0]       i_control,
                input [WIDTH-1:0] i_dat0, i_dat1, i_dat2);

always @(*)
begin
	case (i_control)
		2'b00:   o_dat <= i_dat0;
		2'b01:   o_dat <= i_dat1;
		2'b10:   o_dat <= i_dat2;
	endcase
end

endmodule

