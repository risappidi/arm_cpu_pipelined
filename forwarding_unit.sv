`timescale 1ps/1ps

module forwarding_unit(
	input logic [4:0] Aa, Ab,
	input logic [63:0] Da_no_forward, Db_no_forward,
	input logic [4:0] rd_ex, rd_mem,
	input logic [63:0] d_ex, d_mem,
	input logic regwrite_ex, regwrite_mem,
	input logic [3:0] flags_ex, flags_mem,
	input logic FlagUp_ex,
	output logic [63:0] Da, Db,
	output logic [3:0] flags
);
	logic ex_to_Da;
	logic ex_to_Db;
	logic mem_to_Da;
	logic mem_to_Db;


	logic ex_eq_Da;
	logic ex_eq_Db;
	logic mem_eq_Da;
	logic mem_eq_Db;

	
	logic rd_ex_31, rd_mem_31;
	
	equal_5 eq51(.A(Aa), .B(rd_ex), .eq(ex_eq_Da));
	equal_5 eq52(.A(Ab), .B(rd_ex), .eq(ex_eq_Db));
	equal_5 eq53(.A(Aa), .B(rd_mem), .eq(mem_eq_Da));
	equal_5 eq54(.A(Ab), .B(rd_mem), .eq(mem_eq_Db));
	
	equal_5 eq_rd_31(.A(5'd31), .B(rd_ex), .eq(rd_ex_31));
	equal_5 eq_mem_31(.A(5'd31), .B(rd_mem), .eq(rd_mem_31));
	
	logic regwrite_ex_safe, regwrite_mem_safe;
	
	mux2 m21(.sel(rd_ex_31), .a(regwrite_ex), .b(1'b0), .out(regwrite_ex_safe));
	mux2 m22(.sel(rd_mem_31), .a(regwrite_mem), .b(1'b0), .out(regwrite_mem_safe));
	
	
	and #50 ex_Da_and(ex_to_Da, ex_eq_Da, regwrite_ex_safe);
	and #50 ex_Db_and(ex_to_Db, ex_eq_Db, regwrite_ex_safe);
	and #50 mem_Da_and(mem_to_Da, mem_eq_Da, regwrite_mem_safe);
	and #50 mem_Db_and(mem_to_Db, mem_eq_Db, regwrite_mem_safe);
	

	mux64_3 Da_sel(
        .sel1(ex_to_Da), 
        .sel0(mem_to_Da), 
        .in0(Da_no_forward),  
        .in1(d_ex), 
        .in2(d_mem), 
        .out(Da)
    );
	mux64_3 Db_sel(
        .sel1(ex_to_Db), 
        .sel0(mem_to_Db), 
        .in0(Db_no_forward),  
        .in1(d_ex), 
        .in2(d_mem), 
        .out(Db)
    );
	
	mux4_2 flags_sel(.sel(FlagUp_ex), .A(flags_mem), .B(flags_ex), .out(flags));
	
endmodule

module equal_5 (
	 input  logic [4:0] A,
	 input  logic [4:0] B,
	 output logic       eq   
);
	 logic [4:0] xnor_result;
	 bitwise_xnor #(.N(5)) xnor_inst (
		  .A(A),
		  .B(B),
		  .out(xnor_result)
	 );

	 and_5 reduce_and (
		  .A(xnor_result),
		  .out(eq)
	 );
endmodule

module and_5(input logic [4:0] A, output logic out);
	logic and_temp;
	and #50 and0(and_temp, A[0], A[1], A[2], A[3]);

	and #50 and_out(out, and_temp, A[4]);
endmodule

module mux64_3 (
    input  logic       sel1, sel0,       
    input  logic [63:0] in0, in1, in2,    
    output logic [63:0] out
);
    logic [63:0] tmp;
    mux64_2 m0 (.sel(sel0), .A(in0), .B(in2), .out(tmp));  
    mux64_2 m1 (.sel(sel1), .A(tmp), .B(in1), .out(out));  
endmodule

