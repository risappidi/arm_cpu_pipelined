`timescale 1ps/1ps
//FLAG ORDER: N Z V C
module control(
    input logic [31:0] instr,
    input logic [3:0] flags,
	 input logic DbZero,
    output logic Reg2Loc,
                 UncondBr,
                 BrTaken,
                 Mem2Reg,	
                 MemWrite,
                 ALUSrc,
                 RegWrite,
                 Shift,
					  ImmSel,
					  
					  FlagUp,
		MemRead,
    output logic [2:0] ALUOp
);
    // logic N=flags[3];
    // logic Z=flags[2];
    // logic V=flags[1];
    // logic C=flags[0];
    logic N, Z, V, C;
    assign {N, Z, V, C} = flags;
	parameter ALU_PASS_B=3'b000, ALU_ADD=3'b010, ALU_SUBTRACT=3'b011, ALU_AND=3'b100, ALU_OR=3'b101, ALU_XOR=3'b110, ALU_PASS_A=3'b111;
    enum logic [3:0] {B, B_LT, CBZ, ADDS, AND_OP, EOR, LSR, SUBS, ADDI, LDUR, STUR, none} op;

    always_comb begin
        if (instr[31:26] == 6'b000101) op = B;
        else if (instr[31:24] == 8'b01010100) op = B_LT;
        else if (instr[31:24] == 8'b10110100) op = CBZ; 
        else if (instr[31:21] == 11'b10101011000) op = ADDS; 
        else if (instr[31:21] == 11'b10001010000) op = AND_OP;
        else if (instr[31:21] == 11'b11001010000) op = EOR;
        else if (instr[31:21] == 11'b11010011010) op = LSR;
        else if (instr[31:21] == 11'b11101011000) op = SUBS;
        else if (instr[31:22] == 10'b1001000100) op = ADDI;
        else if (instr[31:21] == 11'b11111000010) op = LDUR;
        else if (instr[31:21] == 11'b11111000000) op = STUR;
        else                                      op = none;
    end
    
    //Assign control signals
    always_comb begin
		 Reg2Loc=1;
		 UncondBr=0;
		 BrTaken=0;
		 Mem2Reg=0;
		 ALUOp=ALU_PASS_B;
		 MemWrite=0;
		 RegWrite=0;
		 ALUSrc=0;
		 Shift=0;
		 ImmSel=0;
		 MemRead=0;
		 FlagUp=0;
		 
        case (op)
            B: begin
                // Reg2Loc=;
                UncondBr=1;
                BrTaken=1;
                // Mem2Reg;
                // ALUOp;
                MemWrite=0;
                RegWrite=0;
                // ALUSrc;
                Shift=0;
//				ImmSel=;
				FlagUp=0;
		MemRead=0;
            end
            B_LT: begin
                // Reg2Loc=;
                UncondBr=0;
                BrTaken=N^V;
                // Mem2Reg;
                // ALUOp;
                MemWrite=0;
                RegWrite=0;
                // ALUSrc;
                Shift=0;
//				ImmSel=;
				FlagUp=0;
		MemRead=0;

            end
            CBZ: begin
                Reg2Loc=0;
                UncondBr=0;
                BrTaken=DbZero;
                // Mem2Reg;
                ALUOp=ALU_PASS_B;
                MemWrite=0;
                RegWrite=0;
                ALUSrc=0;
                Shift=0;
//				ImmSel=;
				FlagUp=0;
		MemRead=0;

            end

            ADDS: begin
                Reg2Loc=1;
                // UncondBr=;
                BrTaken=0;
                Mem2Reg=0;
                ALUOp=ALU_ADD;
                MemWrite=0;
                RegWrite=1;
                ALUSrc=0;
                Shift=0;
//				ImmSel=;
				FlagUp=1;
		MemRead=0;

            end

            AND_OP: begin
                Reg2Loc=1;
                // UncondBr=;
                BrTaken=0;
                Mem2Reg=0;
                ALUOp=ALU_AND;
                MemWrite=0;
                RegWrite=1;
                ALUSrc=0;
                Shift=0;
//              ImmSel=;
				FlagUp=0;
		MemRead=0;


            end
            
            EOR: begin
                Reg2Loc=1;
                // UncondBr=;
                BrTaken=0;
                Mem2Reg=0;
                ALUOp=ALU_XOR;
                MemWrite=0;
                RegWrite=1;
                ALUSrc=0;
                Shift=0;
//              ALUSrc=;
				FlagUp=0;
		MemRead=0;


            end

            LSR: begin
                Reg2Loc=0;
                // UncondBr=;
                BrTaken=0;
                Mem2Reg=0;
                ALUOp=ALU_PASS_A;
                MemWrite=0;
                RegWrite=1;
//              ALUSrc=;
                Shift=1;
				ImmSel=0;
				FlagUp=0;
		MemRead=0;

            end

            SUBS: begin
                Reg2Loc=1;
                // UncondBr=;
                BrTaken=0;
                Mem2Reg=0;
                ALUOp=ALU_SUBTRACT;
                MemWrite=0;
                RegWrite=1;
                ALUSrc=0;
                Shift=0;
//				ImmSel=;
				FlagUp=1;
		MemRead=0;

            end

            ADDI: begin
//                Reg2Loc=;
                // UncondBr=;
                BrTaken=0;
                Mem2Reg=0;
                ALUOp=ALU_ADD;
                MemWrite=0;
                RegWrite=1;
                ALUSrc=1;
                Shift=0;
				ImmSel=1;
				FlagUp=0;
		MemRead=0;

            end

            LDUR: begin
                Reg2Loc=0;
                // UncondBr=;
                BrTaken=0;
                Mem2Reg=1;
                ALUOp=ALU_ADD;
                MemWrite=0;
                RegWrite=1;
                ALUSrc=1;
                Shift=0;
				ImmSel=0;
				FlagUp=0;
		MemRead=1;

            end

            STUR: begin
                Reg2Loc=0;
                // UncondBr=;
                BrTaken=0;
                // Mem2Reg=;
                ALUOp=ALU_ADD;
                MemWrite=1;
                RegWrite=0;
                ALUSrc=1;
                Shift=0;
				ImmSel=0;
				FlagUp=0;
		MemRead=0;

            end

            none: ;
        endcase
    end
endmodule