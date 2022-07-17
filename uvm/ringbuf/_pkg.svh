
package tb_pkg;

import uvm_pkg::*;

//`include "Test/uvm/env.sv"
`include "uvm/ringbuf/sequence.svh"
`include "uvm/ringbuf/driver.svh"

class ringbuf_agent extends uvm_agent;

	`uvm_component_utils(ringbuf_agent)

	ringbuf_driver                   driver;
	uvm_sequencer#(ringbuf_seq_item) sequencer;
	
	function new(string name, uvm_component parent);
		super.new(name, parent);
	endfunction

	function void build_phase(uvm_phase phase);
		super.build_phase(phase);

		if(get_is_active() == UVM_ACTIVE) begin
			driver = ringbuf_driver::type_id::create("driver", this);
			sequencer = uvm_sequencer#(ringbuf_seq_item)::type_id::create("sequencer", this);
			`uvm_info("ID", "AGENT_BUILD_PHASE_UVM_ACT", UVM_MEDIUM);
		end
	endfunction

	function void connect_phase(uvm_phase phase);
		//if (get_is_active() == UVM_ACTIVE) begin
		driver.seq_item_port.connect(sequencer.seq_item_export);
		`uvm_info("ID", "AGENT_CONNE_PHASE_UVM_ACT", UVM_MEDIUM);
		//end
	endfunction

	task run_phase(uvm_phase phase);
		phase.raise_objection(this);
		begin
			ringbuf_sequence seq;
			seq = ringbuf_sequence::type_id::create("seq");
			seq.start(sequencer);
		end
		phase.drop_objection(this);
	endtask

endclass

class env extends uvm_env;

	ringbuf_agent agent;
	//scoreboard    scb;

	`uvm_component_utils(env);

	function new(string name, uvm_component parent);
		super.new(name, parent);
	endfunction

	function void build_phase(uvm_phase phase);
		super.build_phase(phase);
		agent = ringbuf_agent::type_id::create("agent", this);
		//scb   = scoreboard::type_id::create("scb", this);
	endfunction

//	virtual function void connect_phase(uvm_phase phase);
//		agent.monitor.item_collected_port.connect(scb.item_collected_export);
//		`uvm_info("ID", "ENV_CONNECT_PHASE", UVM_MEDIUM);
//	endfunction

endclass

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

endpackage

