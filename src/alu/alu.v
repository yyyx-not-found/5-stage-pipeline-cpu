// instruction: 32-bit instruction
// regA/B: 32-bit data in registerA(addr=00000), registerB(addr=00001)
// result: 32-bit result of Alu execution
// flags: 3-bit alu flag
// flags[2] : zero flag
// flags[1] : negative flag
// flags[0] : overflow flag 
module alu(instruction, regA, regB, result, flags);
    input [31:0] instruction, regA, regB; // the address of regA is 00000, the address of regB is 00001
    output [31:0] result;
    output [2:0] flags; // the first bit is zero flag, the second bit is negative flag, the third bit is overflow flag.

	/*** Constants ***/

	localparam  // R type
		OP_R = 6'b000000,
		FUNC_SLL = 6'b000000,
		FUNC_SRL = 6'b000010,
		FUNC_SRA = 6'b000011,
		FUNC_SLLV = 6'b000100,
		FUNC_SRLV = 6'b000110,
		FUNC_SRAV = 6'b000111,
		FUNC_JR = 6'b001000,
		FUNC_ADD = 6'b100000,
		FUNC_ADDU = 6'b100001,
		FUNC_SUB = 6'b100010,
		FUNC_SUBU = 6'b100011,
		FUNC_AND = 6'b100100,
		FUNC_OR = 6'b100101,
		FUNC_XOR = 6'b100110,
		FUNC_NOR = 6'b100111,
		FUNC_SLT = 6'b101010,
		FUNC_SLTU = 6'b101011;
    
    localparam  // I type
		OP_BEQ      = 6'b000100,
		OP_BNE 		= 6'b000101,
		OP_ADDI 	= 6'b001000,
		OP_ADDIU 	= 6'b001001,
		OP_ANDI 	= 6'b001100,
		OP_ORI 		= 6'b001101,
		OP_XORI 	= 6'b001110,
		OP_LW 		= 6'b100011,
		OP_SW 		= 6'b101011,
		OP_SLTI 	= 6'b001010,
		OP_SLTIU 	= 6'b001011;

    localparam
		ALU_ADD    	= 0,
		ALU_ADDU	= 1,
		ALU_SUB    	= 2,
		ALU_SUBU 	= 3,
		ALU_AND    	= 4,
		ALU_NOR		= 5,
		ALU_OR		= 6,
		ALU_XOR		= 7,
		ALU_SLL		= 8,
		ALU_SLLV	= 9,
		ALU_SRL		= 10,
		ALU_SRLV	= 11,
		ALU_SRA		= 12,
		ALU_SRAV	= 13,
		ALU_SLT		= 14,
		ALU_SLTU    = 15,
		ALU_ZERO 	= 16;

	/*** Signals ***/

	wire [5:0] opcode;
    wire [4:0] rs, rt, rd, sa;
    wire [5:0] func;
    wire [15:0] imm;
	wire [31:0] valA, valB;
	wire [31:0] sign_extended_imm, unsign_extended_imm;
	wire [31:0] unsign_extended_sa;
	wire signed [31:0] aluA, aluB;

	// Control signals
	wire [1:0] ALUOp;
	wire ALUSrcA, ALUSrcB;
	wire [4:0] ALUControl;

	/*** Logic Implementation ***/

	assign opcode = instruction[31:26];
    assign rs     = instruction[25:21];
    assign rt     = instruction[20:16];
    assign rd     = instruction[15:11];
    assign sa     = instruction[10: 6];
    assign func   = instruction[ 5: 0];
    assign imm    = instruction[15: 0];

	// 0: rs    1: sa
    assign ALUSrcA = 
    	opcode == OP_R & (func == FUNC_SLL | func == FUNC_SRA | func == FUNC_SRL);
    
    // 0: rt   1: imm
    assign ALUSrcB = 
    	~(opcode == OP_R & func != FUNC_JR | opcode == OP_BNE | opcode == OP_BEQ);

	// 00: addition for loads and stores
    // 01: subtraction for branch
    // 10: determined by the operation encoded in the funct field
    // 11: other I type instructions
    assign ALUOp = 
		opcode == OP_LW | opcode == OP_SW ? 2'b00 :
		opcode == OP_BEQ | opcode == OP_BNE ? 2'b01 :
		opcode == OP_R ? 2'b10 :
		2'b11;

	assign valA = 
		rs == 5'b00000 ? regA :
		regB;
	assign valB = 
		rt == 5'b00000 ? regA :
		regB;

	assign sign_extended_imm = imm[15] ? {{16{imm[15]}},imm} : {16'b0,imm};
	assign unsign_extended_imm = {16'b0,imm};
    assign unsign_extended_sa  = {27'b0,sa};

	assign aluA = ALUSrcA ? unsign_extended_sa : valA;
	assign aluB = 
		ALUSrcB ? (opcode == OP_ADDI | opcode == OP_SLTI | opcode == OP_LW | opcode == OP_SW ? sign_extended_imm : unsign_extended_imm) :
		valB;

	assign ALUControl = 
        (ALUOp == 2'b10 & func == FUNC_ADD) | ALUOp == 2'b00 | (ALUOp == 2'b11 & opcode == OP_ADDI) ? ALU_ADD :
        (ALUOp == 2'b10 & func == FUNC_ADDU) | (ALUOp == 2'b11 & opcode == OP_ADDIU) ? ALU_ADDU :
        (ALUOp == 2'b10 & func == FUNC_SUB) | ALUOp == 2'b01 ? ALU_SUB :
        ALUOp == 2'b10 & func == FUNC_SUBU ? ALU_SUBU :
        (ALUOp == 2'b10 & func == FUNC_AND) | (ALUOp == 2'b11 & opcode == OP_ANDI) ? ALU_AND :
        ALUOp == 2'b10 & func == FUNC_NOR ? ALU_NOR :
        (ALUOp == 2'b10 & func == FUNC_OR) | (ALUOp == 2'b11 & opcode == OP_ORI) ? ALU_OR :
        (ALUOp == 2'b10 & func == FUNC_XOR) | (ALUOp == 2'b11 & opcode == OP_XORI) ? ALU_XOR :
        ALUOp == 2'b10 & func == FUNC_SLL ? ALU_SLL :
        ALUOp == 2'b10 & func == FUNC_SLLV ? ALU_SLLV :
        ALUOp == 2'b10 & func == FUNC_SRL ? ALU_SRL :
        ALUOp == 2'b10 & func == FUNC_SRLV ? ALU_SRLV :
        ALUOp == 2'b10 & func == FUNC_SRA ? ALU_SRA :
        ALUOp == 2'b10 & func == FUNC_SRAV ? ALU_SRAV :
        (ALUOp == 2'b10 & func == FUNC_SLT) | (ALUOp == 2'b11 & opcode == OP_SLTI) ? ALU_SLT :
		(ALUOp == 2'b10 & func == FUNC_SLTU) | (ALUOp == 2'b11 & opcode == OP_SLTIU) ? ALU_SLTU :
        ALU_ZERO;

	assign result = 
		ALUControl == ALU_ADD | ALUControl == ALU_ADDU ? aluA + aluB :
		ALUControl == ALU_SUB | ALUControl == ALU_SUBU | ALUControl == ALU_SLT | ALUControl == ALU_SLTU ? aluA - aluB :
		ALUControl == ALU_AND ? aluA & aluB :
		ALUControl == ALU_NOR ? ~(aluA | aluB) :
		ALUControl == ALU_OR ? aluA | aluB :
		ALUControl == ALU_XOR ? aluA ^ aluB :
		ALUControl == ALU_SLL ? aluB << aluA :
		ALUControl == ALU_SLLV ? aluB << aluA[4:0] : // 3
		ALUControl == ALU_SRL ? aluB >> aluA :
		ALUControl == ALU_SRLV ? aluB >> (aluA % (1 << 5)) : // 3
		ALUControl == ALU_SRA ? $signed(aluB) >>> aluA :
		ALUControl == ALU_SRAV ? $signed(aluB) >>> (aluA % (1 << 5)) : // 3
		0;

	assign set_flags = 
        func == FUNC_ADD | func == OP_ADDI | func == FUNC_SUB | func == OP_BEQ | 
        func == OP_BNE | func == FUNC_SLT | func == FUNC_SLTU;	

	// ZF
	assign flags[2] = 
	 	opcode == OP_BNE | opcode == OP_BEQ ? result == 0 :
		0;
	// SF
	assign flags[1] = 
		opcode == OP_R & (func == FUNC_SLT | func ==FUNC_SLTU) | opcode == OP_SLTI | opcode == OP_SLTIU ? result[31] :
		0;
	// OF
	assign flags[0] = 
		opcode == OP_R & func == FUNC_ADD | opcode == OP_ADDI ? aluA[31] == aluB[31] & aluA[31] != result[31] :
		opcode == OP_R & func == FUNC_SUB ? aluA[31] != aluB[31] & aluA[31] != result[31] :
		0;
    
endmodule