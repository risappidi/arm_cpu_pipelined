`timescale 1ps/1ps

// This module writes to the specified WriteRegister if desired,
// and outputs the value currently at said register
module regfile(ReadData1, ReadData2, WriteData, ReadRegister1, ReadRegister2, WriteRegister, RegWrite, reset,  clk);
	input logic [4:0] WriteRegister, ReadRegister1, ReadRegister2; // write and read register selectors
	input logic RegWrite, clk; //clk, reset, and whether to write
  input logic [63:0] WriteData; // data to write
	output logic [63:0] ReadData1, ReadData2; //read data

    input logic reset;
    logic [31:0] write_reg_selector;
    logic [63:0] regdata [31:0];

    // Hardcodes X31 to 0, and reset to 0
    assign regdata[31] = '0;

    // Outputs 32 bit selector, all 0s and one 1 bit, which indicates the register to write to
    decoder dec(.reg_write(RegWrite), .reg_in(WriteRegister), .reg_out(write_reg_selector));

    // Reads two values from the reg data
    mux64_32 read_one(.regsel(ReadRegister1), .regdata(regdata), .rd(ReadData1));
    mux64_32 read_two(.regsel(ReadRegister2), .regdata(regdata), .rd(ReadData2));
    
    // Checks write for every register, excludes X31 which is set to 0
    genvar i;
    generate
        for (i=0;i<31;i++) begin: all_reg
            register write(.wd(WriteData), .clk(clk), .we(write_reg_selector[i]), .rst(reset), .rd(regdata[i]));
        end
    endgenerate
	
endmodule
