`timescale 1ps/1ps

	module bitwise_and(A, B, out);

		 input logic [63:0] A, B;
		 output logic [63:0] out;

		 genvar i;
		 generate
			  for (i = 0; i < 64; i++) begin: ands
					and #50 gate (out[i], A[i], B[i]);
			  end
		 endgenerate
	endmodule

	module bitwise_or(A, B, out);

		 input logic [63:0] A, B;
		 output logic [63:0] out;

		 genvar i;
		 generate
			  for (i = 0; i < 64; i++) begin: ors
					or #50 gate (out[i], A[i], B[i]);
			  end
		 endgenerate
	endmodule

	module bitwise_xor(A, B, out);

		 input logic [63:0] A, B;
		 output logic [63:0] out;

		 genvar i;
		 generate
			  for (i = 0; i < 64; i++) begin: xors
					xor #50 gate (out[i], A[i], B[i]);
			  end
		 endgenerate
	endmodule

	module  bitwise_xnor#(parameter N=64) (A, B, out);

		 input logic [N-1:0] A, B;
		 output logic [N-1:0] out;

		 genvar i;
		 generate
			  for (i = 0; i < N; i++) begin: xnors
					xnor #50 gate (out[i], A[i], B[i]);
			  end
		 endgenerate
	endmodule

	module bitwise_tb;
	  logic [63:0] A, B;
	  logic [63:0] out_and, out_or, out_xor;

	  bitwise_and u_and (.A(A), .B(B), .out(out_and));
	  bitwise_or  u_or  (.A(A), .B(B), .out(out_or));
	  bitwise_xor u_xor (.A(A), .B(B), .out(out_xor));

	  task automatic check(input logic [63:0] a, b);
		 logic [63:0] exp_and, exp_or, exp_xor;
		 A = a; B = b;
		 #5000;
		 exp_and = a & b;
		 exp_or  = a | b;
		 exp_xor = a ^ b;
		 assert (out_and == exp_and) else $error("AND mismatch A=%h B=%h got=%h exp=%h", a, b, out_and, exp_and);
		 assert (out_or  == exp_or ) else $error("OR  mismatch A=%h B=%h got=%h exp=%h", a, b, out_or,  exp_or );
		 assert (out_xor == exp_xor) else $error("XOR mismatch A=%h B=%h got=%h exp=%h", a, b, out_xor, exp_xor);
	  endtask

	  initial begin
		 check(64'h0, 64'h0);
		 check(64'hFFFF_FFFF_FFFF_FFFF, 64'hFFFF_FFFF_FFFF_FFFF);
		 check(64'hAAAA_AAAA_AAAA_AAAA, 64'h5555_5555_5555_5555);
		 check(64'hFFFF_0000_FFFF_0000, 64'h0000_FFFF_0000_FFFF);
		 check(64'h1234_5678_9ABC_DEF0, 64'h0FED_CBA9_8765_4321);
		 for (int k = 0; k < 16; k++) begin
			logic [63:0] a, b;
			a = {8{8'(k)}};
			b = {8{8'(15-k)}};
			check(a, b);
		 end
		 $display("Bitwise tests completed.");
		 $finish;
	  end
	endmodule