
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

	task run_phase(uvm_phase phase);
		phase.raise_objection(this);
		#10
		`uvm_info("ID", "ENV_BUILD_PHASE", UVM_MEDIUM);
		phase.drop_objection(this);
	endtask

//	function void end_of_elaboration();
//		print();
//	endfunction

	/*
	virtual task run_phase(uvm_phase phase);
		phase.raise_objection(this);
			//seq.start(envirenment.);
			`uvm_info("ID", "TEST_RUN", UVM_MEDIUM);
		phase.drop_objection(this);
		`uvm_info("ID", "TEST_FINISH", UVM_MEDIUM);
	endtask
	*/

endclass

