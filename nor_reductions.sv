`timescale 1ps/1ps
//64 bit AND reduction
module nor64(
	input logic [63:0] A,
	output logic out
);
	logic [3:0] nors;
	nor16 nor0(.A(A[15:0]), .out(nors[0]));
	nor16 nor1(.A(A[31:16]), .out(nors[1]));
	nor16 nor2(.A(A[47:32]), .out(nors[2]));
	nor16 nor3(.A(A[63:48]), .out(nors[3]));
	and #50 nor_out(out, nors[0], nors[1], nors[2], nors[3]);
endmodule

module nor16(input logic [15:0] A, output logic out);
	logic [3:0] nors;
	nor #50 nor0_gate(nors[0], A[0], A[1], A[2], A[3]);
	nor #50 nor1_gate(nors[1], A[4], A[5], A[6], A[7]);
	nor #50 nor2_gate(nors[2], A[8], A[9], A[10], A[11]);
	nor #50 nor3_gate(nors[3], A[12], A[13], A[14], A[15]);
	and #50 nor_out(out, nors[0], nors[1], nors[2], nors[3]);
endmodule

module and64(
	input logic [63:0] A,
	output logic out
);
	logic [3:0] ands;
	and16 and0(.A(A[15:0]), .out(ands[0]));
	and16 and1(.A(A[31:16]), .out(ands[1]));
	and16 and2(.A(A[47:32]), .out(ands[2]));
	and16 and3(.A(A[63:48]), .out(ands[3]));
	and #50 and_out(out, ands[0], ands[1], ands[2], ands[3]);
endmodule

module and16(input logic [15:0] A, output logic out);
	logic [3:0] ands;
	and #50 and0(ands[0], A[0], A[1], A[2], A[3]);
	and #50 and1(ands[1], A[4], A[5], A[6], A[7]);
	and #50 and2(ands[2], A[8], A[9], A[10], A[11]);
	and #50 and3(ands[3], A[12], A[13], A[14], A[15]);
	and #50 and_out(out, ands[0], ands[1], ands[2], ands[3]);
endmodule



