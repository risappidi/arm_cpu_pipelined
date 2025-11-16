`timescale 1ps/1ps

module register #(parameter N=64)(input logic [N-1:0] wd,
											 input logic clk, we, rst,
											 output logic [N-1:0] rd);
	genvar i;
	generate
		for(i=0;i<N;i++) begin : register_logic
			logic d_cur;
			//2:1 mux for write enable
			logic we_inv;
			logic a0_out, a1_out;
			not #(50) n0(we_inv, we);
			and #(50) a0(a0_out, we, wd[i]);
			and #(50) a1(a1_out, we_inv, rd[i]);
			or #(50) o1(d_cur, a0_out, a1_out);
			D_FF u_dff(.q(rd[i]), .d(d_cur), .reset(rst), .clk(clk));
		end
	endgenerate
endmodule