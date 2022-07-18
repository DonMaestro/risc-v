
interface ringbuf_intf;
	logic [4-1:0] rdata;
	logic             empty;
	logic             overflow;
	logic [4-1:0] wdata;
	logic             re, we;
	logic             rst, clk;
endinterface

