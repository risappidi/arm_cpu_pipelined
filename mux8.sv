`timescale 1ps/1ps

module mux8(input logic[7:0] in, input logic [2:0] sel, input logic en, output logic out);
	
	logic [2:0] sel_inv;
	not #(50) n_sel_0(sel_inv[0], sel[0]);
	not #(50) n_sel_1(sel_inv[1], sel[1]);
	not #(50) n_sel_2(sel_inv[2], sel[2]);
	
	logic [7:0] out_no_or;
	and #(50) a_out_0(out_no_or[0], sel_inv[2], sel_inv[1], sel_inv[0], in[0]);
	and #(50) a_out_1(out_no_or[1], sel_inv[2], sel_inv[1], sel[0], in[1]);
	and #(50) a_out_2(out_no_or[2], sel_inv[2], sel[1], sel_inv[0], in[2]);
	and #(50) a_out_3(out_no_or[3], sel_inv[2], sel[1], sel[0], in[3]);
	and #(50) a_out_4(out_no_or[4], sel[2], sel_inv[1], sel_inv[0], in[4]);
	and #(50) a_out_5(out_no_or[5], sel[2], sel_inv[1], sel[0], in[5]);
	and #(50) a_out_6(out_no_or[6], sel[2], sel[1], sel_inv[0], in[6]);
	and #(50) a_out_7(out_no_or[7], sel[2], sel[1], sel[0], in[7]);
	
	logic or0, or1, sel_out;
	or #(50) o0(or0, out_no_or[0], out_no_or[1], out_no_or[2], out_no_or[3]);
	or #(50)  o1(or1, out_no_or[4], out_no_or[5], out_no_or[6], out_no_or[7]);
	or #(50)  o2(sel_out, or0, or1);
	and #(50) a_out_final(out, sel_out, en);
endmodule


module mux2(input logic a, b, sel, output logic out);
  logic sel_inv, a_sel, b_sel;
  not  #50 inv_sel (sel_inv, sel);
  and  #50 and_a (a_sel, a, sel_inv);
  and  #50 and_b (b_sel, b, sel);
  or   #50 or_out (out, a_sel, b_sel);
endmodule