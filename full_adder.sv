`timescale 1ns/10ps

module adder(A, B, out, overflow, carryout);

    input logic [63:0] A, B;
    output logic [63:0] out;
    output logic overflow, carryout;

    //65 carries, 0th is default 0, 65th is final output
    logic [64:0] carries;
    assign carries[0] = 0;

    genvar i;
    generate
        for (i = 0; i < 64; i++) begin: chain_adders
            full_adder add (.A(A[i]), .B(B[i]), .carryin(carries[i]), .out(out[i]), .carryout(carries[i+1]));
        end
    endgenerate

    assign carryout = carries[64];

    //Logic for overflow operations
    logic step_1, step_2;
    xnor #50 step1 (step_1, A[63], B[63]);
    xor #50 step2 (step_2, A[63], out[63]);
    and #50 overflow_step (overflow, step_1, step_2);

endmodule


module full_adder(A, B, carryin, out, carryout);

    input logic A, B, carryin;
    output logic out, carryout;

    // Gets the sum bit
    xor #50 sum (out, A, B, carryin);

    // Gets the helper bits for carryout
    logic and1, and2, and3;
    and #50 and_1 (and1, A, B);
    and #50 and_2 (and2, A, carryin);
    and #50 and_3 (and3, B, carryin);

    // Gets the carryout bit
    or #50 carry (carryout, and1, and2, and3);

endmodule

// module adder_tb;
//   logic [63:0] A, B;
//   logic [63:0] out;
//   logic overflow, carryout;

//   adder dut (.A(A), .B(B), .out(out), .overflow(overflow), .carryout(carryout));

//   task automatic check(input logic [63:0] a, b);
//     logic [64:0] u_add;        // unsigned add for carry
//     logic [63:0] exp_sum;
//     logic        exp_carry, exp_over;

//     A = a; B = b;
//     #2000;

//     u_add     = {1'b0, a} + {1'b0, b};
//     exp_sum   = u_add[63:0];
//     exp_carry = u_add[64];

//     // 2's-complement overflow
//     exp_over  = ((a[63] ~^ b[63]) & (a[63] ^ exp_sum[63]));

//     assert (out      == exp_sum)   else $error("SUM mismatch: A=%h B=%h got=%h exp=%h", a, b, out, exp_sum);
//     assert (carryout == exp_carry) else $error("CARRY mismatch: A=%h B=%h got=%0b exp=%0b", a, b, carryout, exp_carry);
//     assert (overflow == exp_over)  else $error("OVERFLOW mismatch: A=%h B=%h got=%0b exp=%0b", a, b, overflow, exp_over);
//   endtask

//   initial begin
//     // Directed edge cases
//     check(64'h0000_0000_0000_0000, 64'h0000_0000_0000_0000); // 0 + 0
//     check(64'hFFFF_FFFF_FFFF_FFFF, 64'h0000_0000_0000_0001); // carry out
//     check(64'h7FFF_FFFF_FFFF_FFFF, 64'h0000_0000_0000_0001); // +max + 1 => overflow
//     check(64'h8000_0000_0000_0000, 64'hFFFF_FFFF_FFFF_FFFF); // min + (-1) => overflow
//     check(64'h1234_5678_9ABC_DEF0, 64'h0FED_CBA9_8765_4321); // mixed pattern

//     // A few randoms
//     int unsigned seed = 32'hABCDEF;
//     for (int k = 0; k < 10; k++) begin
//       logic [63:0] ra = $urandom(seed);
//       logic [63:0] rb = $urandom(seed);
//       check(ra, rb);
//     end

//     $display("All tests completed.");
//     $finish;
//   end
// endmodule
