
class ringbuf_scoreboard extends uvm_scoreboard;

	`uvm_component_utils(ringbuf_scoreboard)
	uvm_analysis_imp #(ringbuf_seq_item, ringbuf_scoreboard) item_analysis_imp;

	logic [WIDTH-1:0] data[$];

	function new(string name, uvm_component parent);
		super.new(name, parent);
	endfunction

	virtual function void build_phase(uvm_phase phase);
		super.build_phase(phase);
		item_analysis_imp = new("item_analysis_imp", this);
	endfunction

	virtual function write(ringbuf_seq_item pkt);
		if (pkt.we) begin
			data.push_back(pkt.wdata);
		end

		if (pkt.re) begin
			if (pkt.rdata != data.pop_front())
				`uvm_error(get_type_name(), "data don't match")
		end

		if (pkt.empty) begin
			`uvm_info(get_type_name(), "EMPTY", UVM_MEDIUM)
		end

		if (pkt.overflow) begin
			`uvm_info(get_type_name(), "OVERFLOW", UVM_MEDIUM)
		end
	endfunction


	virtual task run_phase(uvm_phase phase);
		ringbuf_seq_item rb_pkt;
	endtask

endclass

