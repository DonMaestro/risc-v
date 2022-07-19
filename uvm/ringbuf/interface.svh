
interface ringbuf_intf #(parameter WIDTH = 4)
                       (input rst, clk);
	logic [WIDTH-1:0] rdata;
	logic             empty;
	logic             overflow;
	logic [WIDTH-1:0] wdata;
	logic             re, we;
endinterface

