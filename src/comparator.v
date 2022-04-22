
module comparator #(parameter WIDTH = 5)
                  (output            o_equals,
                   input [WIDTH-1:0] i_data1,
                   input [WIDTH-1:0] i_data2);

assign o_equals = i_data1 == i_data2;

endmodule

