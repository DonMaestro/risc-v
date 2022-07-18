
//`include "Test/uvm/sequence.svh"

class ringbuf_agent extends uvm_agent;

	uvm_sequencer#(ringbuf_seq_item) sequencer;
	ringbuf_driver    driver;
	
	`uvm_component_utils(ringbuf_agent)

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
		if (get_is_active() == UVM_ACTIVE) begin
			driver.seq_item_port.connect(sequencer.seq_item_export);
			`uvm_info("ID", "AGENT_CONNE_PHASE_UVM_ACT", UVM_MEDIUM);
		end
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

