
class ringbuf_seq_item extends uvm_sequence_item;

	`uvm_object_utils(ringbuf_seq_item)

	rand logic [WIDTH-1:0] wdata;
	rand logic              re, we;
	     logic              rst, clk;

	/*
	`uvm_object_utils_begin(ringbuf_seq_item)
		`uvm_field_int(wdata, UVM_ALL_ON)
		`uvm_field_int(re, UVM_ALL_ON)
		`uvm_field_int(we, UVM_ALL_ON)
	`uvm_object_utils_end
	*/

	function new(string name = "ringbuf_seq_item");
		super.new(name);
	endfunction

endclass: ringbuf_seq_item


class ringbuf_sequence extends uvm_sequence#(ringbuf_seq_item);

	`uvm_object_utils(ringbuf_sequence)

	int unsigned n_times = 10;

	function new(string name = "");
		super.new(name);
	endfunction

	//`uvm_declare_p_sequencer(ringbuf_sequencer)

	// task pre_body
	// task post_body
	task body;
		repeat (n_times) begin
			`uvm_warning(get_type_name(), "NEW DATA")
			req = ringbuf_seq_item::type_id::create("req");
			start_item(req);
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

