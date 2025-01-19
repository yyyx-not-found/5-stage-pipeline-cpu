`include "alu.v"
`timescale 1ns/1ps

module test();
    reg  [31:0] instruction;
    reg  [31:0] regA;
    reg  [31:0] regB;
    reg  [31:0] exp_result;
    reg  [2:0] exp_flags;
    reg  [7:0] testID;
    wire [31:0] result;
    wire [2:0] flags;

    initial begin
        $dumpfile("test.vcd");
        $dumpvars;
    end

    initial begin
        $display("\ninitialize...");
        $monitor("INPUT: instruction = 32'b%b\nregA = 32'h%h, regB = 32'h%h\nOUTPUT: result = 32'h%h, flags = 3'b%b\nEXPECTED: result = 32'h%h, flags = 3'b%b", 
                 instruction, regA, regB, result, flags, exp_result, exp_flags);
        instruction = 32'b0;
        regA = 32'b0; 
        regB = 32'b0;
        exp_result = 32'b0;
        exp_flags = 3'b0;
        testID = 0;
        #500

        $display("\n##############################\nTests for R Type\n##############################"); 
        $display("\nTEST %d: add test (overflow): 127 + 1 = -128", testID);
        instruction = 32'h00200020;   // testing for add overflow
        regA = 32'h7FFFFFFF;
        regB = 32'h00000001;
        exp_result = 32'h80000000;
        exp_flags = 3'b001;
        testID += 1;
        #100
        $display("\nTEST %d: add test: 1 + 2 = 3", testID);
        instruction = 32'h00010020;   // testing for add normal
        regA = 32'h00000001;
        regB = 32'h00000002;
        exp_result = 32'h00000003;
        exp_flags = 3'b000;
        testID += 1;
        #100
        $display("\nTEST %d: sub test (overflow): 127 - -1 = -128", testID);
        instruction = 32'h00010022;   // testing for sub overflow
        regA = 32'h7FFFFFFF;
        regB = 32'hFFFFFFFF;
        exp_result = 32'h80000000;
        exp_flags = 3'b001;
        testID += 1;
        #100
        $display("\nTEST %d: sub test: 4 - 3 = 1", testID);
        instruction = 32'h00010022;   // testing for sub normal
        regA = 32'h00000004;
        regB = 32'h00000003;
        exp_result = 32'h00000001;
        exp_flags = 3'b000;
        testID += 1;
        #100
        $display("\nTEST %d: addu test: 127 + 1 = 128", testID);
        instruction = 32'h00200021;   // testing for addu 
        regA = 32'h7FFFFFFF;
        regB = 32'h00000001;
        exp_result = 32'h80000000;
        exp_flags = 3'b000;
        testID += 1;
        #100 
        $display("\nTEST %d: subu test: 127 - -1= 128", testID);
        instruction = 32'h00010023;   // testing for subu
        regA = 32'h7FFFFFFF;
        regB = 32'hFFFFFFFF;
        exp_result = 32'h80000000;
        exp_flags = 3'b000;
        testID += 1;
        #100
        $display("\nTEST %d: and test: 0xFFFF FFFF & 0x0000 0001 = 1", testID);
        instruction = 32'h00010024;   // testing for and
        regA = 32'hFFFFFFFF;
        regB = 32'h00000001;
        exp_result = 32'h00000001;
        exp_flags = 3'b000;
        testID += 1;
        #100
        $display("\nTEST %d: or test: 0x0000 0000 | 0x0000 0001 = 0x0000 0001", testID);
        instruction = 32'h00200025;   // testing for or
        regA = 32'h00000000;
        regB = 32'h00000001;
        exp_result = 32'h00000001;
        exp_flags = 3'b000;
        testID += 1;
        #100
        $display("\nTEST %d: xor test: 0xFFFF FFFF ^ 0x0000 000F = 0xFFFF FFF0", testID);
        instruction = 32'h00200026;  // testing for xor
        regA = 32'hFFFFFFFF;
        regB = 32'h0000000F;
        exp_result = 32'hFFFFFFF0;
        exp_flags = 3'b000;
        testID += 1;
        #100
        $display("\nTEST %d: nor test: ~(0x0000 0000 | 0xFFFF FFFF) = 0x0000 0000", testID);
        instruction = 32'h00200027;  //testing for nor
        regA = 32'h00000000;
        regB = 32'hFFFFFFFF;
        exp_result = 32'h00000000;
        exp_flags = 3'b000;  
        testID += 1;     
        #100
        $display("\nTEST %d: slt test (set): 0 < 1", testID);
        instruction = 32'h0001002A;  // testing for slt
        regA = 32'h00000000;
        regB = 32'h00000001;
        exp_result = 32'hFFFFFFFF;
        exp_flags = 3'b010;
        testID += 1;
        #100
        $display("\nTEST %d: slt test (not set): 1 > 0", testID);
        instruction = 32'h0001002A;
        regA = 32'h00000001;
        regB = 32'h00000000;
        exp_result = 32'h00000001;
        exp_flags = 3'b000;
        testID += 1;
        #100
        $display("\nTEST %d: sltu test (set): 0x0000 0000 < 0xFFFF FFFF", testID);
        instruction = 32'h0001002B;  // testing for sltu
        regA = 32'h00000000;
        regB = 32'hFFFFFFFF;
        exp_result = 32'h00000001;
        exp_flags = 3'b000;
        testID += 1;
        #100
        $display("\nTEST %d: sltu test (not set): 0xFFFF FFFF > 0xFFFF FFFE", testID);
        instruction = 32'h0001002B;  // testing for sltu
        regA = 32'hFFFFFFFF;
        regB = 32'hFFFFFFFE;
        exp_result = 32'h00000001;
        exp_flags = 3'b000;
        testID += 1;
        #100
        $display("\nTEST %d: sll test: 0x0000 0001 << 10 = 0x0000 0400", testID);
        instruction = 32'h00010280;  // testing for sll
        regA = 32'h00000000;
        regB = 32'h00000001;
        exp_result = 32'h00000400;
        exp_flags = 3'b000;
        testID += 1;
        #100
        $display("\nTEST %d: srl test: 0xF0000 0000 >> 10 = 0x003C 0000", testID);
        instruction = 32'h00010282;  //testing for srl
        regA = 32'h00000000;
        regB = 32'hF0000000;
        exp_result = 32'h003C0000;
        exp_flags = 3'b000;
        testID += 1;
        #100
        $display("\nTEST %d: sllv test: 0x0000 0001 << 16 = 0x0001 0000", testID);
        instruction = 32'h00010004; //testing for sllv
        regA = 32'h00000010;
        regB = 32'h00000001;
        exp_result = 32'h00010000;
        exp_flags = 3'b000;
        testID += 1;
        #100
        $display("\nTEST %d: srlv test: 0xF000 0000 >> 4 = 0x0F00 0000", testID);
        instruction = 32'h00010006; // testing for srlv
        regA = 32'h00000004;
        regB = 32'hF0000000;
        exp_result = 32'h0F000000;
        exp_flags = 3'b000;
        testID += 1;
        #100
        $display("\nTEST %d: srav test: 0xF000 0000 >> 4 = 0xFF00 0000", testID);
        instruction = 32'h00010007; // testing for srav
        regA = 32'h00000004;
        regB = 32'hF0000000;
        exp_result = 32'hFF000000;
        exp_flags = 3'b000;
        testID += 1;
        #100
        $display("\nTEST %d: sra test: 0xF000 0000 >> 2 = 0xCF00 0000", testID);
        instruction = 32'h00010083; // testing for sra
        regA = 32'h00000004;
        regB = 32'hF0000000;
        exp_result = 32'hFC000000;
        exp_flags = 3'b000;
        testID += 1;
        #100

        $display("\n##############################\nTest for I Type\n##############################");
        $display("\nTEST %d: addi test: 0 + 1 = 1", testID);
        instruction = 32'h20200001;  // testing for addi
        regA = 32'h00000001;
        regB = 32'h00000000;
        exp_result = 32'h00000001;
        exp_flags = 3'b000;
        testID += 1;
        #100
        $display("\nTEST %d: addi test (overflow): 127 + 1 = -128", testID);
        instruction = 32'h20010001;  // testing for addi
        regA = 32'h7FFFFFFF;
        regB = 32'h00000000;
        exp_result = 32'h80000000;
        exp_flags = 3'b001;
        testID += 1;
        #100
        $display("\nTEST %d: andi test: 0xFFFF FFFF & 0x0000 0001 = 0x0000 0001", testID);
        instruction = 32'h30010001;  // testing for andi
        regA = 32'hFFFFFFFF;
        regB = 32'h00000000;
        exp_result = 32'h00000001;
        exp_flags = 3'b000;
        testID += 1;
        #100
        $display("\nTEST %d: addiu test: 0 + 129 = 129", testID);
        instruction = 32'h24208001;  //testing for addiu
        regA = 32'h00000001;
        regB = 32'h00000000;
        exp_result = 32'h00008001;
        exp_flags = 3'b000;
        testID += 1;
        #100
        $display("\nTEST %d: ori test: 0x0000 0010 | 0x0000 0001 = 0x0000 0011", testID);
        instruction = 32'h34010001; //testing for ori
        regA = 32'h00000010;
        regB = 32'h00000000;
        exp_result = 32'h00000011;
        exp_flags = 3'b000;
        testID += 1;
        #100
        $display("\nTEST %d: xori test: 0x0000 0001 ^ 0x0000 0003 = 0x0000 0002", testID);
        instruction = 32'h38010003; //testing for xori
        regA = 32'h00000001;
        regB = 32'h00000000;
        exp_result = 32'h00000002;
        exp_flags = 3'b000;
        testID += 1;
        #100
        $display("\nTEST %d: slti test (set): 0 < 1", testID);
        instruction = 32'h28010001; //testing for slti
        regA = 32'h00000000;
        regB = 32'h00000000;
        exp_result = 32'hFFFFFFFF;
        exp_flags = 3'b010;
        testID += 1;
        #100
        $display("\nTEST %d: slti test (not set): 1 > 0", testID);
        instruction = 32'h28010000; //testing for slti
        regA = 32'h00000001;
        regB = 32'h00000000;
        exp_result = 32'h00000001;
        exp_flags = 3'b000;
        testID += 1;
        #100
        $display("\nTEST %d: beq test (branch occurs): 1 == 1", testID);
        instruction = 32'h10010001; //testing for beq
        regA = 32'h00000001;
        regB = 32'h00000001;
        exp_result = 32'h00000000;
        exp_flags = 3'b100;
        testID += 1;
        #100
        $display("\nTEST %d: beq test (branch not occurs): 0 != 1", testID);
        instruction = 32'h10010001; //testing for beq
        regA = 32'h00000000;
        regB = 32'h00000001;
        exp_result = 32'hFFFFFFFF;
        exp_flags = 3'b000;
        testID += 1;
        #100
        $display("\nTEST %d: bne test (branch occurs) 1 != 0", testID);
        instruction = 32'h14010001; //testing for bne
        regA = 32'h00000001;
        regB = 32'h00000000;
        exp_result = 32'h00000001;
        exp_flags = 3'b000;
        testID += 1;
        #100
        $display("\nTEST %d: bne test (branch not occurs): 1 == 1", testID);
        instruction = 32'h14010001; //testing for bne
        regA = 32'h00000001;
        regB = 32'h00000001;
        exp_result = 32'h00000000;
        exp_flags = 3'b100;
        testID += 1;
        #100
        $display("\nTEST %d: sltiu test (set): 1 < 16", testID);
        instruction = 32'h2C010010; //testing for sltiu
        regA = 32'h00000001;
        regB = 32'h00000000;
        exp_result = 32'hFFFFFFF1;
        exp_flags = 3'b010;
        testID += 1;
        #100
        $display("\nTEST %d: sltiu test (not set): 16 == 16", testID);
        instruction = 32'h2C010010; //testing for sltiu
        regA = 32'h00000010;
        regB = 32'h00000000;
        exp_result = 32'h00000000;
        exp_flags = 3'b000;
        testID += 1;
        #100
        $display("\nTEST %d: lw test: 0x0000 F00F + 0x0000 0010 = 0xFFFF F01F", testID);
        instruction = 32'h8C01F00F; //testing for lw
        regA = 32'h00000010;
        regB = 32'h00000000;
        exp_result = 32'hFFFFF01F;
        exp_flags = 3'b000;
        testID += 1;
        #100
        $display("\nTEST %d: sw test: 0x0000 700F + 0x0000 0100 = 0x0000 710F", testID);
        instruction = 32'hAC01700F; //testing for sw
        regA = 32'h00000100;
        regB = 32'h00000000;
        exp_result = 32'h0000710F;
        exp_flags = 3'b000;
        testID += 1;
        #100
        $stop;
    end

    alu alu_test(
        .instruction( instruction ),
        .regA( regA ),
        .regB( regB ),
        .result( result ),
        .flags(flags)
    );

endmodule