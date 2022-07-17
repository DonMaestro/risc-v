
class ringbuf_seq_item extends uvm_sequence_item;

	`uvm_object_utils(ringbuf_seq_item)

	rand logic [4-1:0] wdata;
	rand logic              re, we;
	     logic              rst, clk;

	/*
	`uvm_object_utils_begin(ringbuf_seq_item)
		`uvm_field_int(wdata, UVM_ALL_ON)
		`uvm_field_int(re, UVM_ALL_ON)
		`uvm_field_int(we, UVM_ALL_ON)
	`uvm_object_utils_end
	*/

	function new(string name = "");
		super.new(name);
	endfunction

endclass: ringbuf_seq_item


class ringbuf_sequence extends uvm_sequence#(ringbuf_seq_item);

	`uvm_object_utils(ringbuf_sequence)

	function new(string name = "");
		super.new(name);
	endfunction

	//`uvm_declare_p_sequencer(ringbuf_sequencer)

	// task pre_body
	// task post_body
	task body;
		repeat(8) begin
			req = ringbuf_seq_item::type_id::create("req");
			start_item(req);
			//req = ringbuf_seq_item::type_id::create("req");
			//`uvm_info("BASE_SEQ", $sformatf("Starting body of %s", this.get_name()), UVM_MEDIUM);
			`uvm_warning("BASE_SEQ", "Starting body");
			//`uvm_create(req);
			req.wdata = $urandom;
			req.we = $urandom;
			req.re = $urandom;
			//`uvm_send(req);
			//wait_for_item_done();
			finish_item(req);
		end
	endtask: body

endclass: ringbuf_sequence

