
class ringbuf_scoreboard extends uvm_scoreboard;

	`uvm_component_utils(ringbuf_scoreboard)
	uvm_analysis_imp #(ringbuf_seq_item, ringbuf_scoreboard) item_analysis_imp;

	function new(string name, uvm_component parent);
		super.new(name, parent);
	endfunction

	virtual function void build_phase(uvm_phase phase);
		super.build_phase(phase);
		item_analysis_imp = new("item_analysis_imp", this);
	endfunction

	virtual function write(ringbuf_seq_item pkt);
		//pkt.print();
	endfunction

	virtual task run_phase(uvm_phase phase);
		ringbuf_seq_item rb_pkt;
	endtask

endclass

