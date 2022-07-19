
class test extends uvm_test;
	
	`uvm_component_utils(test)

	ringbuf_env env;

	function new(string name, uvm_component parent);
		super.new(name, parent);
	endfunction

	function void build_phase(uvm_phase phase);
		super.build_phase(phase);
		env = ringbuf_env::type_id::create("env", this);
	endfunction

	/*
	task run_phase(uvm_phase phase);
		phase.raise_objection(this);
		#10;
		`uvm_info("ID", "TEST_RUN", UVM_MEDIUM)
		phase.drop_objection(this);
	endtask
	*/

	function void end_of_elaboration();
		print();
	endfunction

endclass

