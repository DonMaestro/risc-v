
class test extends uvm_test;
	
	`uvm_component_utils(test);

	env envirenment;

	function new(string name, uvm_component parent);
		super.new(name, parent);
	endfunction

	function void build_phase(uvm_phase phase);
		super.build_phase(phase);
		envirenment = env::type_id::create("envirenment", this);
	endfunction

	/*
	task run_phase(uvm_phase phase);
		phase.raise_objection(this);
		#100
		`uvm_info("ID", "TEST_RUN", UVM_MEDIUM);
		phase.drop_objection(this);
	endtask
	*/

//	function void end_of_elaboration();
//		print();
//	endfunction

endclass

