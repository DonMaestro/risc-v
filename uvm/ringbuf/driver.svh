
class ringbuf_driver extends uvm_driver #(ringbuf_seq_item);

	`uvm_component_utils(ringbuf_driver)

	virtual ringbuf_intf vif;

	function new(string name, uvm_component parent);
		super.new(name, parent);
	endfunction

	function void build_phase(uvm_phase phase);
		super.build_phase(phase);
		if (!uvm_config_db#(virtual ringbuf_intf)::get(this, "", "viff", vif))
			`uvm_fatal("DRV", "Could not get vif");
		//uvm_config_db#(virtual intf #(.WIDTH(8)))::set(this, "e0.a0.*", "vif", vif)
	endfunction

	task run_phase(uvm_phase phase);
		vif.rst = 1'b0;
		@(posedge vif.clk);
		#1
		vif.rst = 1'b1;
		forever begin
			seq_item_port.get_next_item(req);
			vif.wdata = req.wdata;
			vif.we    = req.we;
			vif.re    = req.re;
			@(posedge vif.clk);
			//drive();
			seq_item_port.item_done();
		end
	endtask

	virtual task drive();
		`uvm_info("ID", "DRIVE_TASK_DRIVE", UVM_MEDIUM);	
		$display("DRIVE_TASK_DRIVE");
	endtask

endclass

