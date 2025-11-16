`timescale 1ps/1ps

module threeToEightDecoder(enable, in_bits, out_bits);
	input logic [2:0] in_bits;
	output logic [7:0] out_bits;
	
	input logic enable;
	
	logic NotA0, NotA1, NotA2;
	
	not #50 NotA0Gate(NotA0, in_bits[0]);
	not #50 NotA1Gate(NotA1, in_bits[1]);
	not #50 NotA2Gate(NotA2, in_bits[2]);
	
	and #50 D0 (out_bits[0], NotA0, NotA1, NotA2, enable);
	and #50 D1 (out_bits[1], in_bits[0], NotA1, NotA2, enable);
	and #50 D2 (out_bits[2], NotA0, in_bits[1], NotA2, enable);
	and #50 D3 (out_bits[3], in_bits[0], in_bits[1], NotA2, enable);
	and #50 D4 (out_bits[4], NotA0, NotA1, in_bits[2], enable);
	and #50 D5 (out_bits[5], in_bits[0], NotA1, in_bits[2], enable);
	and #50 D6 (out_bits[6], NotA0, in_bits[1], in_bits[2], enable);
	and #50 D7 (out_bits[7], in_bits[0], in_bits[1], in_bits[2], enable);
	
endmodule

module twoToFourDecoder(in_bits, out_bits);
	input logic [1:0] in_bits;
	output logic [3:0] out_bits;
	
	logic NotA0, NotA1;
	
	not #50 NotA0Gate(NotA0, in_bits[0]);
	not #50 NotA1Gate(NotA1, in_bits[1]);
	
	and #50 D0 (out_bits[0], NotA0, NotA1);
	and #50 D1 (out_bits[1], in_bits[0], NotA1);
	and #50 D2 (out_bits[2], NotA0, in_bits[1]);
	and #50 D3 (out_bits[3], in_bits[0], in_bits[1]);
	
endmodule
	
	

module decoder (reg_write, reg_in, reg_out);
	input logic reg_write;
	input logic [4:0] reg_in;
	output logic [31:0] reg_out;
	
	logic [3:0] enable, final_enable;
	
	twoToFourDecoder decoderSelector(reg_in[4:3], enable);
	
	and #50 write1(final_enable[0], enable[0], reg_write);
	and #50 write2(final_enable[1], enable[1], reg_write);
	and #50 write3(final_enable[2], enable[2], reg_write);
	and #50 write4(final_enable[3], enable[3], reg_write);
	
	threeToEightDecoder firstEight(final_enable[0], reg_in[2:0], reg_out[7:0]);
	threeToEightDecoder secondEight(final_enable[1], reg_in[2:0], reg_out[15:8]);
	threeToEightDecoder thirdEight(final_enable[2], reg_in[2:0], reg_out[23:16]);
	threeToEightDecoder fourthEight(final_enable[3], reg_in[2:0], reg_out[31:24]);
	
endmodule