class Generator;
	function new();
		$display("Init generator");
	endfunction

	function void gen();
		$display("Work!!!");
	endfunction

//	extern function [31:0] GenSW();
	function [31:0] GenSW();
		bit [ 6:0] op;
		bit [ 2:0] func_3;
		bit [ 4:0] rs1, rs2;
		bit [11:0] imm_12;

		op     = 7'b010_0011;
		// imm_5
		func_3 = 3'b010;
		rs1    = $random;
		rs2    = $random;
		imm_12 = $random;

		GenSW = { imm_12[11:5], rs2, rs1, func_3, imm_12[4:0], op };
	endfunction

	function [31:0] GenLW();
		bit [ 6:0] op;
		bit [ 4:0] rd;
		bit [ 2:0] func_3;
		bit [ 4:0] rs1;
		bit [11:0] imm_12;

		op     = 7'b000_0011;
		rd     = $random;
		func_3 = 3'b010;
		rs1    = $random;
		imm_12 = $random;

		GenLW = { imm_12[11:0], rs1, func_3, rd, op };
	endfunction

endclass


