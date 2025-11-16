`timescale 1ns/1ps
module CPU_pipelined(clk, reset);
//IF
	input logic clk, reset;
	logic [63:0] PC, PC_plus_4, PC_next, PC_ID;
	logic [31:0] instr, instr_EX, instr_next;
	logic [3:0] flags, flags_ex, flags_mem;
	logic [63:0] branch_target;
	logic [10:0] controls_ID, controls_EX, controls_MEM, controls_WB;
	logic negative, zero, overflow, carry_out;
	logic [63:0] res_wb_next ;
	
	logic branch_taken;
	//Control signal indexing parameters
	parameter FlagUp=0;
	parameter Reg2Loc=1;
	parameter BrTaken=2;
	parameter UncondBr=3;
	parameter MemRead=4;
	parameter Mem2Reg=5;
	parameter MemWrite=6;
	parameter ALUSrc=7;
	parameter RegWrite=8;
	parameter Shift=9;
	parameter ImmSel=10;

	adder incr_PC_IF (.A(PC), .B(64'd4), .out(PC_plus_4), .overflow(), .carryout());


	//Branch taken mux
	mux64_2 PC_select_mux (
	 .sel(controls_ID[BrTaken]),  
	 .A(PC_plus_4),          
	 .B(branch_target),   
	 .out(PC_next)           
	);


	//Instruction memory
	instructmem get_instr (.address(PC), .instruction(instr_next), .clk(clk));

	//PC update register
	register pc_reg(.wd(PC_next), .clk(clk), .we(1'b1), .rst(reset), .rd(PC));

	//IF-ID pipeline registers
	register PC_ID_reg(.wd(PC), .clk(clk), .we(1'b1), .rst(reset), .rd(PC_ID));
	register #(.N(32)) instr_reg(.wd(instr_next), .clk(clk), .we(1'b1), .rst(reset), .rd(instr));

//ID
   
	//Final Da and Db to be passed to EX
	logic [63:0] Da, Db;

	//Rn, Rm, Rd for current instr and Rd for EX and MEM instrs
	logic [4:0] Rd, Rd_EX, Rd_MEM, Rd_WB, Rn, Rm;
	assign Rd = instr[4:0];
	assign Rn = instr[9:5];
	assign Rm = instr[20:16];

	//Read registers
	logic [4:0] Ab, Aa;

	//Regfile outputs to pass to ID-EX pipeline reg
	logic [63:0] Da_next, Db_next;

	//Da and Db assuming no forwarding
	logic [63:0] Da_no_forward, Db_no_forward; 

	//Data to be forwarded
	logic [63:0] res_ex,res_mem, res_ex_mem, res_wb;

	//ALUOp
	logic [2:0] ALUOp, ALUOp_next;

	//Controls to be passed to pipeline reg
	logic [10:0] controls_next_ID;

	//Accelerated CBZ check
	logic DbZero;
	//Control signal gen
	control cpu_ctrl(
		.instr(instr),
		.flags(flags),
		.DbZero(DbZero),
		.Reg2Loc(controls_ID[Reg2Loc]),
		.UncondBr(controls_ID[UncondBr]),
		.MemRead(controls_ID[MemRead]),
		.BrTaken(controls_ID[BrTaken]),
		.Mem2Reg(controls_ID[Mem2Reg]),
		.MemWrite(controls_ID[MemWrite]),
		.ALUSrc(controls_ID[ALUSrc]),
		.RegWrite(controls_ID[RegWrite]),
		.Shift(controls_ID[Shift]),
		.ImmSel(controls_ID[ImmSel]),
		.FlagUp(controls_ID[FlagUp]),
		.ALUOp(ALUOp_next)
	);

	//Reg2Loc mux
	mux5_2 Reg_to_Location (.sel(controls_ID[Reg2Loc]), .A(Rd), .B(Rm), .out(Ab));

	//Regfile
	regfile RegFile (
		.ReadData1(Da_no_forward), 
		.ReadData2(Db_no_forward), 
		.WriteData(res_wb), 
		.ReadRegister1(Rn), 
		.ReadRegister2(Ab), 
		.WriteRegister(Rd_WB), 
		.RegWrite(controls_WB[RegWrite]), 
		.reset(1'b0),
		.clk(~clk)
	);

	//forwarding unit

	
	forwarding_unit fu(
		.Aa(Rn), 
		.Ab(Ab), 
		.Da_no_forward(Da_no_forward), 
		.Db_no_forward(Db_no_forward), 
		.rd_ex(Rd_EX),
		.rd_mem(Rd_MEM),
		.d_ex(res_ex),
		.d_mem(res_wb_next),
		.regwrite_ex(controls_EX[RegWrite]),
		.regwrite_mem(controls_MEM[RegWrite]),
		.flags_ex(flags_ex), 
		.flags_mem(flags_mem),
		.FlagUp_ex(controls_EX[FlagUp]),
		.Da(Da_next), 
		.Db(Db_next),
		.flags(flags)
	);

	//Branch Accel
	//Immediate extend
	logic [63:0] Imm26_ID, unconditional; // [25:0] 16 bits sign extended to 64
	logic [63:0] Imm19_ID, conditional; // [18:0] 19 bits sign extended to 64
	assign Imm26_ID = {{38{instr[25]}}, instr[25:0]};
	assign Imm19_ID = {{45{instr[23]}}, instr[23:5]};
	assign unconditional = {Imm26_ID[61:0], 2'b0};
   assign conditional = {Imm19_ID[61:0], 2'b0};

	//Check if Da is 0
	nor64 zero_nor(.A(Db_next), .out(DbZero));

	//Select correct branch
	logic [63:0] selected_branch;
	mux64_2  uncond_sel (.sel(controls_ID[UncondBr]), .A(conditional), .B(unconditional), .out(selected_branch));
	adder  branch_add (.A(PC_ID), .B(selected_branch), .out(branch_target), .overflow(), .carryout());

	//ID regs
	register #(.N(11)) control_reg_EX (.wd(controls_ID), .clk(clk), .we(1'b1), .rst(reset), .rd(controls_EX));
	register #(.N(3)) ALUOp_reg (.wd(ALUOp_next), .clk(clk), .we(1'b1), .rst(reset), .rd(ALUOp));
	register Da_reg (.wd(Da_next), .clk(clk), .we(1'b1), .rst(reset), .rd(Da)); 
	register Db_reg (.wd(Db_next), .clk(clk), .we(1'b1), .rst(reset), .rd(Db)); 
	register #(.N(5)) Rd_EX_reg(.wd(Rd), .clk(clk), .we(1'b1), .rst(reset), .rd(Rd_EX));
	register #(.N(32)) instr_EX_reg(.wd(instr), .clk(clk), .we(1'b1), .rst(reset), .rd(instr_EX));

//EX
    //ALU inputs
	logic [63:0] ALU_B, Db_MEM, ALUOut, ShiftOut, ImmOut;
	logic [63:0] Imm26_EX; // [25:0] 16 bits sign extended to 64
	logic [63:0] Imm19_EX; // [18:0] 19 bits sign extended to 64
	logic [63:0] Imm12_EX; // [11:0] 12 bits sign extended to 64
	logic [63:0] Imm9_EX; // [8:0] 9 bits sign extended to 64
	logic [5:0] shamt; // shift amount	
	assign Imm26_EX = {{38{instr_EX[25]}}, instr_EX[25:0]};
	assign Imm19_EX = {{45{instr_EX[23]}}, instr_EX[23:5]};
	assign Imm12_EX = {52'b0, instr_EX[21:10]};
	assign Imm9_EX = {{55{instr_EX[20]}}, instr_EX[20:12]};
	assign shamt = instr_EX[15:10];
   // Selects Imm9 into ALU if ALUSrc==1, Db otherwise
	mux64_2 Imm_Source (.sel(controls_EX[ImmSel]), .A(Imm9_EX), .B(Imm12_EX), .out(ImmOut));
	mux64_2 ALU_Source (.sel(controls_EX[ALUSrc]), .A(Db), .B(ImmOut), .out(ALU_B));

	//Shifter
	shifter shift_by_num (.value(Da), .direction(1'b1), .distance(shamt), .result(ShiftOut)); 

	//ALU
	alu main_ALU (
	  .A(Da), 
	  .B(ALU_B), 
	  .cntrl(ALUOp), 
	  .result(ALUOut), 
	  .negative(negative), 
	  .zero(zero), 
	  .overflow(overflow), 
	  .carry_out(carry_out)
	);

	// Selects Shifter output if Shift==1, ALU output otherwise
	mux64_2 ex_out (.sel(controls_EX[Shift]), .A(ALUOut), .B(ShiftOut), .out(res_ex));

	//Update flag, result, and control registers
	assign flags_ex={negative,zero,overflow,carry_out};

	register #(.N(4)) flag_reg (.wd(flags_ex), .clk(clk), .we(controls_EX[FlagUp]), .rst(reset), .rd(flags_mem));
	register ALUOut_reg (.wd(res_ex), .clk(clk), .we(1'b1), .rst(reset), .rd(res_ex_mem));
	register #(.N(11)) control_reg_MEM (.wd(controls_EX), .clk(clk), .we(1'b1), .rst(reset), .rd(controls_MEM));
	register #(.N(5)) Rd_MEM_reg(.wd(Rd_EX), .clk(clk), .we(1'b1), .rst(reset), .rd(Rd_MEM));
	register Db_MEM_reg(.wd(Db), .clk(clk), .we(1'b1), .rst(reset), .rd(Db_MEM));

//MEM
    //Data Memory
    datamem DataMemory (
        .address(res_ex_mem), 
        .write_enable(controls_MEM[MemWrite]), 
        .read_enable(controls_MEM[MemRead]), .write_data(Db_MEM), 
        .clk(clk), 
        .xfer_size(4'd8), 
        .read_data(res_mem)
    );

    //Mux to select EX stage result or memory read data to writeback
    
	mux64_2 MemToRegister (.sel(controls_MEM[Mem2Reg]), .A(res_ex_mem), .B(res_mem), .out(res_wb_next));

    register res_WB_reg (.wd(res_wb_next), .clk(clk), .we(1'b1), .rst(reset), .rd(res_wb));
	register #(.N(11)) control_reg_WB (.wd(controls_MEM), .clk(clk), .we(1'b1), .rst(reset), .rd(controls_WB));
    register #(.N(5)) Rd_WB_reg(.wd(Rd_MEM), .clk(clk), .we(1'b1), .rst(reset), .rd(Rd_WB));
//WB

endmodule

module CPU_pipelined_tb ();

//    parameter clk_period = 1000000;
	 

	logic clk, reset;	
	initial clk = 0;
	always #100 clk = ~clk;
	CPU_pipelined dut (.*);
	
	// Force %t's to print in a nice format.
	initial $timeformat(-9, 2, " ns", 10);

	initial begin
		  // Apply reset

		  reset = 1;
		  @(posedge clk)
		  // De-assert reset (CPU starts execution)
		  reset = 0;
		  // Wait for a few clock cycles or a longer execution period
		  // You might need to adjust this wait time based on your test.
		  repeat(10000) begin
			 @(posedge clk);
		  end 
		  
		  // 3. TERMINATION
		  $display("\n*** Simulation Finished ***");
		  $stop; // Use $stop to halt simulation
	 end

endmodule
		