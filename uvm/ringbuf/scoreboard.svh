
class scoreboard extends uvm_scoreboard;

	`uvm_component_utils(scoreboard)
	uvm_analysis_imp #(ringbuf_seq_item, scoreboard) item_collected_export;

	function new(string name, uvm_component parent);
		super.new(name, parent);
	endfunction

	virtual function void build_phase(uvm_phase phase);
		super.build_phase(phase);
		`uvm_info("ID", "SCR_BUILD_PHASE", UVM_MEDIUM);
		item_collected_export = new("item_collected_export", this);
	endfunction

	function void write(ringbuf_seq_item pkt);
		pkt.print();
	endfunction

	virtual task run_phase(uvm_phase phase);
		ringbuf_seq_item rb_pkt;
	endtask

endclass


