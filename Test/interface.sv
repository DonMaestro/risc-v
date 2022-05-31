
interface robtable #(parameter WIDTH_DT = 53, WIDTH_BRM = 3)(
	input valid, busy,
        input [WIDTH_DT-1:0]  data,
        input [WIDTH_BRM-1:0] brmask);
endinterface: robtable

