
`include "uvm/ringbuf/interface.svh"

package ringbuf_pkg;
import uvm_pkg::*;

parameter WIDTH = 8;

`include "uvm/ringbuf/sequence.svh"
`include "uvm/ringbuf/driver.svh"
`include "uvm/ringbuf/monitor.svh"
`include "uvm/ringbuf/agent.svh"
`include "uvm/ringbuf/scoreboard.svh"
`include "uvm/ringbuf/env.svh"
`include "uvm/ringbuf/test.svh"

endpackage: ringbuf_pkg

