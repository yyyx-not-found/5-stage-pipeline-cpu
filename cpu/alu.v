module ALU(aluA, aluB, aluFunc, result, flags);
	input signed [31:0] aluA;
	input signed [31:0] aluB;  // two operands
	input [3:0] aluFunc;  // operation type
	output [31:0] result;  // calculation result
	output [2:0] flags;	// carry, zero, negative, overflow

	wire [31:0] sa;

    localparam  // ALU function
		ALU_ADD     = 0,
		ALU_SUB     = 1,
		ALU_AND     = 2,
		ALU_OR      = 3,
		ALU_XOR	    = 4,
		ALU_NOR		= 5,
		ALU_SLL		= 6,
		ALU_SRA		= 7,
		ALU_SRL		= 8,
        ALU_JR      = 9,
        ALU_JUMP    = 10,
		ALU_SLT		= 11,
		ALU_SLTU 	= 12,
		ALU_ZERO    = 13;

	assign sa = $signed(aluA % (1 << 5));
	
	assign result = 
		aluFunc == ALU_ADD ? aluA + aluB :
		aluFunc == ALU_SUB ? aluA - aluB :
		aluFunc == ALU_AND ? aluA & aluB :
		aluFunc == ALU_OR ? aluA | aluB :
		aluFunc == ALU_XOR ? aluA ^ aluB :
		aluFunc == ALU_NOR ? ~(aluA | aluB) :
		aluFunc == ALU_SLL ? aluB << sa :
		aluFunc == ALU_SRA ? (aluB >> sa) | (({32{aluB[31]}} % (1 << sa)) << (32 - sa)) :
		aluFunc == ALU_SRL ? aluB >> sa :
		aluFunc == ALU_JR ? aluA : 
		aluFunc == ALU_JUMP ? {aluA[31:28],aluB[25:0],2'b0} :
		aluFunc == ALU_SLT ? ($signed(aluA) < $signed(aluB)) :
		aluFunc == ALU_SLTU ? ($unsigned(aluA) < $unsigned(aluB)) :
		0;

	// ZF
	assign flags[2] = 
	 	result == 0;

	// SF
	assign flags[1] = 
		result[31];

	// OF
	assign flags[0] = 
		aluFunc == ALU_ADD ? aluA[31] == aluB[31] & aluA[31] != result[31] :
		aluFunc == ALU_SUB ? ~aluA[31] == aluB[31] & aluB[31] != result[31] :
		0; 

endmodule

