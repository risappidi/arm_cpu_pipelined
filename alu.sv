`timescale 1ps/1ps

module alu(
	input logic [63:0] A, B,
	input logic [2:0] cntrl,
	output logic [63:0] result,
	output logic negative, zero, overflow, carry_out
);
	logic [64:0] carries;
	assign carries[0]=cntrl[0];
	
	genvar i;
	generate
	  for (i = 0; i < 64; i++) begin: alu_slices
			alu_slice as (.a(A[i]), .b(B[i]), .cin(carries[i]), .cntrl(cntrl), .out(result[i]), .cout(carries[i+1]));
	  end
	endgenerate
	
	xor #50 v_xor(overflow, carries[64], carries[63]);
	assign carry_out=carries[64];
	assign negative=result[63];
	nor64 zero_nor(.A(result), .out(zero));
	 
endmodule

module alu_slice(
	input logic a, b, cin,
	input logic [2:0] cntrl,
	output logic out, cout
);
	logic b_neg;
	logic b_final;
	not #50 b_neg_not (b_neg, b);
	mux2 b_sel(.a(b), .b(b_neg), .sel(cntrl[0]), .out(b_final));
	
	logic sum;
	full_adder fa(.A(a), .B(b_final), .carryin(cin), .out(sum), .carryout(cout));
	logic and_bit, or_bit, xor_bit;
	and #50 bit_and(and_bit, a, b);
	or #50 bit_or(or_bit, a, b);
	xor #50 bit_xor(xor_bit, a, b);
	logic [7:0] mux_8_in;
	assign mux_8_in={a, xor_bit, or_bit, and_bit, sum, sum, 1'b0, b};
	mux8 m8(.in(mux_8_in), .sel(cntrl), .en(1'b1), .out(out));
endmodule

module alu_slice_tb();

	parameter delay = 100000;
	localparam time SETTLE = 1ns;
	logic		a, b, cin;
	logic		[2:0]		cntrl;
	logic 	out, cout;

	parameter ALU_PASS_B=3'b000, ALU_ADD=3'b010, ALU_SUBTRACT=3'b011, ALU_AND=3'b100, ALU_OR=3'b101, ALU_XOR=3'b110, ALU_PASS_A=3'b111;
	

	alu_slice dut (.*);

	// Force %t's to print in a nice format.
	initial $timeformat(-9, 2, " ns", 10);

	integer i;
	logic [63:0] test_val=0;
	logic [1:0] sum_test=0;
	logic bit_op_test=0;
	initial begin
		cntrl=ALU_PASS_B; #SETTLE;
		a=0; b=0; cin=0; #SETTLE;

		assert(out == b);
		$display("ctrl=%b a=%0d b=%0d cin=%0d  -> out=%0d cout=%0d  (exp out=%0d cout=%0d, bit_op_out=%0d)",
             cntrl, a, b, cin, out, cout, sum_test[0], sum_test[1], bit_op_test);
		b=1;
		a=0;
		#SETTLE;
		assert(out == b);
		$display("ctrl=%b a=%0d b=%0d cin=%0d  -> out=%0d cout=%0d  (exp out=%0d cout=%0d, bit_op_out=%0d)",
             cntrl, a, b, cin, out, cout, sum_test[0], sum_test[1], bit_op_test);
		
		$display("%t testing ADD operations", $time);
		cntrl = ALU_ADD; #SETTLE;
		for(i=0;i<8;i++) begin
			a=i[0];
			b=i[1];
			cin=i[2];
			sum_test=a+b+cin;
			#SETTLE;
			assert(sum_test[0]==out && sum_test[1]==cout);
			$display("ctrl=%b i=%0d a=%0d  b=%0d cin=%0d  -> out=%0d cout=%0d  (exp out=%0d cout=%0d, bit_op_out=%0d)",
             cntrl, i, a, b, cin, out, cout, sum_test[0], sum_test[1], bit_op_test);
		end
		
		$display("%t testing SUB operations", $time);
		cntrl = ALU_SUBTRACT; #SETTLE;
		for(i=0;i<8;i++) begin
			a=i[0];
			b=i[1];
			cin=i[2];
			sum_test=a+1'(~b)+cin;
			#SETTLE;
			assert(sum_test[0]==out && sum_test[1]==cout);
			$display("ctrl=%b a=%0d b=%0d cin=%0d  -> out=%0d cout=%0d  (exp out=%0d cout=%0d, bit_op_out=%0d)",
             cntrl, a, b, cin, out, cout, sum_test[0], sum_test[1], bit_op_test);
		end
		
		$display("%t testing AND operations", $time);
		cntrl = ALU_AND; #SETTLE;
		for(i=0;i<4;i++) begin
			a=i[0];
			b=i[1];
			bit_op_test=a&b;
			#SETTLE;
			assert(out==bit_op_test); 
			$display("ctrl=%b a=%0d b=%0d cin=%0d  -> out=%0d cout=%0d  (exp out=%0d cout=%0d, bit_op_out=%0d)",
             cntrl, a, b, cin, out, cout, sum_test[0], sum_test[1], bit_op_test);
		end
		cntrl = ALU_OR; #SETTLE;
		for(i=0;i<4;i++) begin
			a=i[0];
			b=i[1];
			bit_op_test=a|b;
			#SETTLE;
			assert(out==bit_op_test); 
			$display("ctrl=%b a=%0d b=%0d cin=%0d  -> out=%0d cout=%0d  (exp out=%0d cout=%0d, bit_op_out=%0d)",
             cntrl, a, b, cin, out, cout, sum_test[0], sum_test[1], bit_op_test);
		end
		$display("%t testing XOR operations", $time);
		cntrl = ALU_XOR; #SETTLE;
		for(i=0;i<4;i++) begin
			a=i[0];
			b=i[1];
			bit_op_test=a^b;
			#SETTLE;
			assert(out==bit_op_test); 
			$display("ctrl=%b a=%0d b=%0d cin=%0d  -> out=%0d cout=%0d  (exp out=%0d cout=%0d, bit_op_out=%0d)",
             cntrl, a, b, cin, out, cout, sum_test[0], sum_test[1], bit_op_test);
		end
		$stop;
		$display("%t testing or operations", $time);
	end
endmodule
