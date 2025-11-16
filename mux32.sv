`timescale 1ps/1ps

module mux32(input logic[31:0] in, input logic [4:0] sel, output logic out);
   logic [4:0] sel_inv;
	not #(50) n_sel_0(sel_inv[0], sel[0]);
	not #(50) n_sel_1(sel_inv[1], sel[1]);
	not #(50) n_sel_2(sel_inv[2], sel[2]);
	not #(50) n_sel_3(sel_inv[3], sel[3]);
	not #(50) n_sel_4(sel_inv[4], sel[4]);
	
	logic en0, en1, en2, en3;
	and #(50) a_en0(en0, sel_inv[4], sel_inv[3]);
	and #(50) a_en1(en1, sel_inv[4], sel[3]);
	and #(50) a_en2(en2, sel[4], sel_inv[3]);
	and #(50) a_en3(en3, sel[4], sel[3]);
	
	logic[3:0] d;
	
	mux8 m1(.in(in[7:0]), .sel(sel[2:0]), .en(en0), .out(d[0]));
	mux8 m2(.in(in[15:8]), .sel(sel[2:0]), .en(en1), .out(d[1]));
	mux8 m3(.in(in[23:16]), .sel(sel[2:0]), .en(en2), .out(d[2]));
	mux8 m4(.in(in[31:24]), .sel(sel[2:0]), .en(en3), .out(d[3]));
	
	or #(50) o_out(out, d[0], d[1], d[2], d[3]);
endmodule

module mux32_tb();
	logic [31:0] in;
	logic [4:0] sel;
	logic out;
	logic [31:0] in_stim;
	mux32 dut(.*);
	initial begin
		for(int i=0;i<99;i++) begin
			in_stim=$urandom();
			in=in_stim;
			for(int sel_stim=0;sel_stim<32;sel_stim++) begin
				
				sel=sel_stim;
				#5000000;
				assert(out===in[sel_stim]) else begin
					$error("Mismatch: sel=%0d, in=%032b, out_test=%b, out=%b", sel_stim, in, out, in[sel_stim]);
					$fatal(1);
				end
			end
		end
		$display("passed");
	end
endmodule 