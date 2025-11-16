`timescale 1ns/10ps
// Single Cycle CPU
module CPU (clk, reset);
    //PC Counter Starts at 0, gets incremented
    logic [63:0] PC, PC_next;
    
    // Error Checking Clock
    input logic clk, reset;
	 
    // Get next instruction
    logic [31:0] instr;
    logic [3:0] flags, flags_next;
	 logic FlagUp;
	 register pc_reg(.wd(PC_next), .clk(clk), .we(1), .rst(reset), .rd(PC));
	 instructmem get_instr (.address(PC), .instruction(instr), .clk(clk));
	 register #(.N(4)) flag_reg (.wd(flags_next), .clk(clk), .we(FlagUp), .rst(reset), .rd(flags));
    // Get Instruction Values
    logic [63:0] Imm26; // [25:0] 16 bits sign extended to 64
    logic [63:0] Imm19; // [18:0] 19 bits sign extended to 64
    logic [63:0] Imm12; // [11:0] 12 bits sign extended to 64
    logic [63:0] Imm9; // [8:0] 9 bits sign extended to 64
    logic [5:0] shamt; // shift amount
    logic [4:0] Rd, Rn, Rm;
    logic negative, zero, overflow, carry_out;
	assign flags_next={negative,zero,overflow,carry_out};

    assign Imm26 = {{38{instr[25]}}, instr[25:0]};
    assign Imm19 = {{45{instr[23]}}, instr[23:5]};
    assign Imm12 = {52'b0, instr[21:10]};
    assign Imm9 = {{55{instr[20]}}, instr[20:12]};
    assign shamt = instr[15:10];
    assign Rd = instr[4:0];
    assign Rn = instr[9:5];
    assign Rm = instr[20:16];
    logic [2:0] ALUOp;
   
    // Defining Control Logic
    logic DbZero,
		  Reg2Loc,
		  BrTaken,
          UncondBr,
          MemRead,
          Mem2Reg,
          MemWrite,
          ALUSrc,
          RegWrite,
          Shift,
          ImmSel;
	
			 
    control cpu_ctrl(
        .instr(instr),
        .flags(flags),
		.DaZero(DbZero),
        .Reg2Loc(Reg2Loc),
        .UncondBr(UncondBr),
        .BrTaken(BrTaken),
        .Mem2Reg(Mem2Reg),
        .MemWrite(MemWrite),
        .ALUSrc(ALUSrc),
        .RegWrite(RegWrite),
        .Shift(Shift),
		.ImmSel(ImmSel),
		.FlagUp(FlagUp),
	.MemRead(MemRead),
        .ALUOp(ALUOp)
    );
	
    // Increment PC
    logic [63:0] branch_incr, unconditional, conditional;
    assign unconditional = {Imm26[61:0], 2'b0};
    assign conditional = {Imm19[61:0], 2'b0};

    // Selects Imm26 when UncondBr == 1, Imm19 otherwise
    mux64_2 conditional_PC_mux (.sel(UncondBr), .A(conditional), .B(unconditional), .out(branch_incr));


    // ALUs for adding to PC
    logic [63:0] temp_PC_1;
    adder incr_PC (.A(PC), .B(64'd4), .out(temp_PC_1), .overflow(), .carryout());

    logic [63:0] temp_PC_2;
    adder incr_PC_br (.A(PC), .B(branch_incr), .out(temp_PC_2), .overflow(), .carryout());

    // Selects +=4 when BrTaken == 0, += branch_incr otherwise
    mux64_2 BranchTaken_mux (.sel(BrTaken), .A(temp_PC_1), .B(temp_PC_2), .out(PC_next));


    //RegFile
    logic [4:0] Ab;
    mux5_2 Reg_to_Location (.sel(Reg2Loc), .A(Rd), .B(Rm), .out(Ab)); //FIX: Register selectors need to be 5 bit, otherwise can't be read by regfile


	logic [63:0] Da, Db, cpu_out;
    regfile RegFile (
        .ReadData1(Da), 
        .ReadData2(Db), 
        .WriteData(cpu_out), 
        .ReadRegister1(Rn), 
        .ReadRegister2(Ab), 
        .WriteRegister(Rd), 
        .RegWrite(RegWrite), 
        .clk(clk)
    );
	nor64 zero_nor(.A(Db), .out(DbZero));
    //ALU inputs
    logic [63:0] ALU_B, ALUOut, ShiftOut, OperatorOut, ImmOut;

    // Selects Imm9 into ALU if ALUSrc==1, Db otherwise
	mux64_2 Imm_Source (.sel(ImmSel), .A(Imm9), .B(Imm12), .out(ImmOut));
    mux64_2 ALU_Source (.sel(ALUSrc), .A(Db), .B(ImmOut), .out(ALU_B));
    
    shifter shift_by_num (.value(Da), .direction(1'b1), .distance(shamt), .result(ShiftOut)); // Get Shifter Output
    
    // Selects Shifter output if Shift==1, ALU output otherwise
    mux64_2 operator_out (.sel(Shift), .A(ALUOut), .B(ShiftOut), .out(OperatorOut)); // Decide whether to use shifter or ALU output

    alu main_ALU (
        .A(Da), 
        .B(ALU_B), 
        .cntrl(ALUOp), 
        .result(ALUOut), 
        .negative(negative), 
        .zero(zero), 
        .overflow(overflow), 
        .carry_out(carry_out)
    ); // Get ALU output

    //Data Memory unit
    logic [63:0] Dout;
    datamem DataMemory (.address(OperatorOut), .write_enable(MemWrite), .read_enable(MemRead), .write_data(Db), .clk(clk), .xfer_size(4'd8), .read_data(Dout));
    
    // Sends memory Dout to reg if Mem2Reg == 1, Operator output otherwise
    mux64_2 MemToRegister (.sel(Mem2Reg), .A(OperatorOut), .B(Dout), .out(cpu_out));



endmodule

module CPU_tb ();

	logic clk, reset;	
	initial clk = 0;
	always #10 clk = ~clk;
	CPU dut (.*);
	
	// Force %t's to print in a nice format.
	initial $timeformat(-9, 2, " ns", 10);

	initial begin
        // Apply reset
        reset = 1;
        #20; 
        @(posedge clk)
        // De-assert reset (CPU starts execution)
        reset = 0;
        #1
        // Wait for a few clock cycles or a longer execution period
        // You might need to adjust this wait time based on your test.
        repeat(10000000) begin
			 @(posedge clk);
			 #1;
		  end 
        
        // 3. TERMINATION
        $display("\n*** Simulation Finished ***");
        $stop; // Use $stop to halt simulation
    end

endmodule