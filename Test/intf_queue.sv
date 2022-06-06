
interface qintf #(parameter WIDTH_BRM = 3, WIDTH_TAG = 3, WIDTH_REG = 7,
                            WIDTH_PRY = 2)(
        input [WIDTH_BRM-1:0] brmask,
        input [WIDTH_TAG-1:0] tag,
        input [WIDTH_REG-1:0] RD, RS1, RS2,
        input [WIDTH_PRY-1:0] PRY,
        input                 valid, p1, p2);
endinterface: qintf

