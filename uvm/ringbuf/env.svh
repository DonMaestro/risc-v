
//`include "Test/uvm/agent.sv"
//`include "Test/uvm/scoreboard.sv"

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

