`timescale 1ps/1ps

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
    xor #50 overflow_calc (overflow, carries[63], carries[64]);

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

module adder_tb;
  logic [63:0] A, B, out;
  logic overflow, carryout;

  adder dut (.A(A), .B(B), .out(out), .overflow(overflow), .carryout(carryout));

  task automatic check(input logic [63:0] a, b);
    logic [64:0] u;
    logic [63:0] exp_sum;
    logic        exp_carry, exp_over;
    A = a; B = b;
    #8000;
    u         = {1'b0, a} + {1'b0, b};
    exp_sum   = u[63:0];
    exp_carry = u[64];
    exp_over  = ((a[63] ~^ b[63]) & (a[63] ^ exp_sum[63]));
    assert (out == exp_sum)   else $error("SUM  A=%h B=%h got=%h exp=%h", a, b, out, exp_sum);
    assert (carryout == exp_carry) else $error("COUT A=%h B=%h got=%0b exp=%0b", a, b, carryout, exp_carry);
    assert (overflow == exp_over)  else $error("OVF  A=%h B=%h got=%0b exp=%0b", a, b, overflow, exp_over);
  endtask

  initial begin
    check(64'h0, 64'h0); //0 + 0 is 0
    check(64'hFFFF_FFFF_FFFF_FFFF, 64'h1); //all 1s + 1 is carry no overflow
    check(64'h7FFF_FFFF_FFFF_FFFF, 64'h1); //0 and all 1s + 1 is 2^63, overflow no carry
    check(64'h8000_0000_0000_0000, 64'hFFFF_FFFF_FFFF_FFFF); // 1 and all 0s + all 1s, carry and overflow
    check(64'h1234_5678_9ABC_DEF0, 64'h0FED_CBA9_8765_4321); //random sequence
    for (int k = 0; k < 16; k++) begin
      logic [63:0] a;
      logic [63:0] b;
      a = 64'h0123_4567_89AB_CDEF ^ {56'd0, k[7:0]};
      b = 64'h1111_1111_1111_1111 * k;
      check(a, b);
    end
    $display("All tests completed.");
    $stop;
  end
endmodule

