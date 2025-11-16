`timescale 1ps/1ps

module mux64_32(input logic [4:0] regsel, input logic [63:0] regdata [31:0], output logic [63:0] rd);
	genvar i,j;
	
	generate
		for(i=0;i<64;i++) begin : cur_bit
			logic [31:0] col;
			for(j=0;j<32;j++) begin : cur_word
				assign col[j]=regdata[j][i];
			end
			mux32 m(.in(col), .sel(regsel), .out(rd[i]));
		end
	endgenerate
endmodule



module mux64_2(input logic sel, input logic [63:0] A, input logic [63:0] B, output logic [63:0] out);
	genvar i;
	generate
		for(i=0;i<64;i++) begin : cur_bit
			mux2 m(.a(A[i]), .b(B[i]), .sel(sel), .out(out[i]));
		end
	endgenerate
endmodule 

module mux4_2(input logic sel, input logic [3:0] A, input logic [3:0] B, output logic [3:0] out);
	genvar i;
	generate
		for(i=0;i<4;i++) begin : cur_bit
			mux2 m(.a(A[i]), .b(B[i]), .sel(sel), .out(out[i]));
		end
	endgenerate
endmodule 

module mux5_2(input logic sel, input logic [4:0] A, input logic [4:0] B, output logic [4:0] out);
	genvar i;
	generate
		for(i=0;i<5;i++) begin : cur_bit
			mux2 m(.a(A[i]), .b(B[i]), .sel(sel), .out(out[i]));
		end
	endgenerate
endmodule 


module mux64_32_tb();
	logic [4:0] regsel;
	logic [63:0] regdata [31:0];
	logic [63:0] rd;
	mux64_32 dut(.*);
	initial begin
		for(int i=0;i<99;i++) begin
			logic [63:0] regdata_stim [31:0];
			for(int j=0;j<32;j++) begin
				regdata_stim[j]={$urandom(), $urandom()};
			end
			regdata=regdata_stim;
			for(int sel_stim=0;sel_stim<32;sel_stim++) begin
				regsel=sel_stim;
				#5000000;	
				assert(rd===regdata[sel_stim]) else begin
					$error("Mismatch: sel=%0d, rd_test=%b, rd=%b", sel_stim, rd, regdata[sel_stim]);
					$fatal(1);
				end
			end
		end
		$display("passed");
	end
endmodule 
