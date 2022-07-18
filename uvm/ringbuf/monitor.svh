
class ringbuf_monitor extends uvm_monitor;
	
	`uvm_component_utils(ringbuf_monitor)

	uvm_analysis_port #(ringbuf_seq_item) aport;
	virtual ringbuf_intf #(.WIDTH(WIDTH)) vif;

	function new(string name, uvm_component parent);
		super.new(name, parent);
	endfunction

	virtual function void build_phase(uvm_phase phase);
		super.build_phase(phase);
		if (!uvm_config_db #(virtual ringbuf_intf #(.WIDTH(WIDTH)))::get(this, "", "vif", vif)) begin
			`uvm_fatal(get_type_name(), "DUT interface not found")
		end
		aport = new("aport", this);
	endfunction

	virtual task run_phase(uvm_phase phase);
		super.run_phase(phase);
		//ringbuf_seq_item tx;
		//`uvm_warning(get_type_name(), "RUN PHASE")
		forever
		begin
			@(posedge vif.clk);
			//tx = ringbuf_seq_item::type_id::create("tx");
			//tx.wdata = vif.wdata;
			if (vif.empty) begin
				`uvm_info(get_type_name(), "EMPTY", UVM_MEDIUM)
			end

			if (vif.overflow) begin
				`uvm_info(get_type_name(), "OVERFLOW", UVM_MEDIUM)
			end
			//aport.write(tx);
		end
	endtask
endclass

