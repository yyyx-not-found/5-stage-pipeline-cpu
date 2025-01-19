`include "alu.v"
`include "register.v"
`include "InstructionRAM.v"
`include "MainMemory.v"

// The processor can run in 4 different modes:
// RUN: normal operation
// RESET: Sets PC to 0, clears all pipe registers, and initializes condition codes
// UPLOAD: Upload bytes from memory
// STATUS: Upload other status information
module CPU(mode, udaddr, odata, stat, clock);
    input [1:0] mode;       // Signal operating mode to processor
    input [31:0] udaddr;    // Upload address
    output [31:0] odata;    // Upload data word
    output [1:0] stat;      // Status
    input clock;            // Clock input
    
    /*** Constants ***/
    
    localparam  // Define modes
        RUN_MODE = 0, // Normal operation
        RESET_MODE = 1, // Resetting processor;
        UPLOAD_MODE = 2, // Reading from memory
        STATUS_MODE = 3; // Uploading register & other status information
    
    localparam  // PC sources
        PC_PLUS4 = 0,
        PC_JUMP = 1,
        PC_BRANCH = 2,
        PC_JR = 3;    

    localparam  // R type
        OP_R          = 6'b000000, 
        FUNC_SLL      = 6'b000000,
        FUNC_SRL      = 6'b000010,
        FUNC_SRA      = 6'b000011,
        FUNC_SLLV     = 6'b000100,
        FUNC_SRLV     = 6'b000110, 
        FUNC_SRAV     = 6'b000111,
        FUNC_JR       = 6'b001000,
        FUNC_ADD      = 6'b100000,  // use add 0, 0, 0 as nop instruction
        FUNC_ADDU     = 6'b100001,
        FUNC_SUB      = 6'b100010,
        FUNC_SUBU     = 6'b100011,
        FUNC_AND      = 6'b100100,
        FUNC_OR       = 6'b100101,
        FUNC_XOR      = 6'b100110,
        FUNC_NOR      = 6'b100111,
        FUNC_SLT      = 6'b101010,
        FUNC_SLTU     = 6'b101011;

    localparam  // I type
        OP_BEQ        = 6'b000100,
        OP_BNE        = 6'b000101,
        OP_ADDI       = 6'b001000,
        OP_ADDIU      = 6'b001001,
        OP_ANDI       = 6'b001100,
        OP_ORI        = 6'b001101,
        OP_XORI       = 6'b001110,
        OP_LW         = 6'b100011,
        OP_SW         = 6'b101011;

    localparam  // J type
        OP_J          = 6'b000010,
	    OP_JAL        = 6'b000011;
    
    localparam  // Status 
        STAT_ALLOK    = 2'b00,
        STAT_BUBBLE   = 2'b01,
        STAT_STALL    = 2'b10,
        STAT_STOP     = 2'b11;

    localparam  // register ID
        REG_NONE   = 5'b00000,
        REG_RA     = 5'b11111;

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
        ALU_SLT     = 11,
        ALU_SLTU    = 12,
		ALU_ZERO    = 13;

  
    /*** Stage Signals ***/
    
    /** Fetch Stage **/
    wire F_stall, F_reset, F_bubble;
    wire [31:0] F_pred_pc, f_pred_pc;
    wire [31:0] f_pc;
    wire [31:0] f_instr;
    wire [5:0] f_opcode;
    wire [4:0] f_rs, f_rt, f_rd, f_sa;
    wire [5:0] f_func;
    wire [15:0] f_imm;
    wire [25:0] f_target;
    wire [31:0] f_sign_extended_imm, f_unsign_extended_imm, f_extended_sa, f_extended_target;
    wire [31:0] f_valC, f_valP;
    wire [1:0] f_stat;
    
    
    /** Decode Stage **/
    wire D_stall, D_bubble, D_reset;
    wire [5:0] D_opcode;
    wire [4:0] D_rs, D_rt, D_rd;
    wire [5:0] D_func;
    wire [31:0] D_valC, D_valP;
    wire [4:0] d_srcA, d_srcB;
    wire [4:0] d_dstE, d_dstM;
    wire [31:0] d_valA, d_valB, d_rvalA, d_rvalB;
    wire [1:0] D_stat;
    
    
    /** Execute Stage **/
    wire E_stall, E_reset, E_bubble;
    wire [5:0] E_opcode, E_func;
    wire [31:0] E_valA, E_valB, E_valC, E_valP;
    wire [4:0] E_dstE, E_dstM;
    wire [31:0] e_aluA, e_aluB;
    wire [3:0] e_aluFunc;
    wire [31:0] e_valE;
    wire [2:0] e_flags;
    wire e_Cnd;
    wire [1:0] E_stat;
    
    
    /** Memory Stage **/
    wire M_stall, M_reset, M_bubble;
    wire [5:0] M_opcode;
    wire [31:0] M_valA, M_valB, M_valE, M_valP;
    wire [31:0] m_valM, m_valE;
    wire M_Cnd;
    wire [4:0] M_dstE, M_dstM;
    wire mem_read, mem_write;
    wire [1:0] M_stat;
    
    /** Write Back Stage **/
    wire W_stall, W_reset, W_bubble;
    wire [5:0] W_opcode;
    wire [31:0] W_valE, W_valM;
    wire [4:0] W_dstE, W_dstM;
    wire [1:0] W_stat;

    /** DEBUG **/
    wire [31:0] zero, at, v0, v1, a0, a1, a2, a3, t0, t1, t2, t3, t4,
    t5, t6, t7, s0, s1, s2, s3, s4, s5, s6, s7, t8, t9, k0,
    k1, gp, sp, fp, ra;

    /** Control Signals **/
    wire mem_clock = ~clock;
    wire set_flags;
    wire [2:0] flags;
    wire [1:0] Stat;

    wire resetting = (mode == RESET_MODE);
    wire uploading = (mode == UPLOAD_MODE);
    wire running = (mode == RUN_MODE);
    wire getting_info = (mode == STATUS_MODE);

    // Logic to control resetting of pipeline registers
    assign F_reset = F_bubble | resetting;
    assign D_reset = D_bubble | resetting;
    assign E_reset = E_bubble | resetting;
    assign M_reset = M_bubble | resetting;
    assign W_reset = W_bubble | resetting;

    /*** Ouput Data ***/
    assign stat = Stat;

    assign odata = 
        getting_info ? 
            (udaddr == 0   ? zero :
             udaddr == 4   ? at   :
             udaddr == 8   ? v0   :
             udaddr == 12  ? v1   :
             udaddr == 16  ? a0   :
             udaddr == 20  ? a1   :
             udaddr == 24  ? a2   :
             udaddr == 28  ? a3   :
             udaddr == 32  ? t0   :
             udaddr == 36  ? t1   :
             udaddr == 40  ? t2   :
             udaddr == 44  ? t3   :
             udaddr == 48  ? t4   :
             udaddr == 52  ? t5   :
             udaddr == 56  ? t6   :
             udaddr == 60  ? t7   :
             udaddr == 64  ? s0   :
             udaddr == 68  ? s1   :
             udaddr == 72  ? s2   :
             udaddr == 76  ? s3   :
             udaddr == 80  ? s4   :
             udaddr == 84  ? s5   :
             udaddr == 88  ? s6   :
             udaddr == 92  ? s7   :
             udaddr == 96  ? t8   :
             udaddr == 100 ? t9   :
             udaddr == 104 ? k0   :
             udaddr == 108 ? k1   :
             udaddr == 112 ? gp   :
             udaddr == 116 ? sp   :
             udaddr == 120 ? fp   :
             udaddr == 124 ? ra   : 0) 
        : m_valM;

    
    /*** Pliplined Registers ***/

    /** Fetch Stage **/

    PipelinedReg # (32) F_pred_pc_preg(F_pred_pc, f_pred_pc, F_stall, F_reset, 0, clock);
    
    /** Decode Stage **/

    // instruction
    PipelinedReg # (6)  D_opcode_preg(D_opcode, f_opcode, D_stall, D_reset, OP_R, clock);
    PipelinedReg # (5)  D_rs_preg(D_rs, f_rs, D_stall, D_reset, REG_NONE, clock);
    PipelinedReg # (5)  D_rt_preg(D_rt, f_rt, D_stall, D_reset, REG_NONE, clock);
    PipelinedReg # (5)  D_rd_preg(D_rd, f_rd, D_stall, D_reset, REG_NONE, clock);
    PipelinedReg # (32) D_valC_preg(D_valC, f_valC, D_stall, D_reset, 0, clock);
    PipelinedReg # (6)  D_func_preg(D_func, f_func, D_stall, D_reset, FUNC_ADD, clock);
    PipelinedReg # (32) D_valP_preg(D_valP, f_valP, D_stall, D_reset, 0, clock);

    // status
    PipelinedReg # (2) D_stat_preg(D_stat, f_stat, D_stall, D_reset, STAT_BUBBLE, clock);
    
    /** Execute Stage **/

    // instruction
    PipelinedReg # (6) E_opcode_preg (E_opcode, D_opcode,   E_stall, E_reset, OP_R, clock);
    PipelinedReg # (6) E_func_preg(E_func, D_func, E_stall, E_reset, FUNC_ADD, clock);
    PipelinedReg # (32) E_valC_preg(E_valC, D_valC, E_stall, E_reset, 0, clock);
    PipelinedReg # (32) E_valP_preg(E_valP, D_valP, E_stall, E_reset, 0, clock);

    // ALU
    PipelinedReg # (32) E_valA_preg(E_valA, d_valA, E_stall, E_reset, 0, clock);
    PipelinedReg # (32) E_valB_preg(E_valB, d_valB, E_stall, E_reset, 0, clock);

    // memory
    PipelinedReg # (5) E_dstE_preg(E_dstE, d_dstE, E_stall, E_reset, REG_NONE, clock);
    PipelinedReg # (5) E_dstM_preg(E_dstM, d_dstM, E_stall, E_reset, REG_NONE, clock);
    
    // status
    PipelinedReg # (2) E_stat_preg(E_stat, D_stat, E_stall, E_reset, STAT_BUBBLE, clock);
    
    /** Memory Stage **/

    // instruction
    PipelinedReg # (6) M_opcode_preg (M_opcode, E_opcode, M_stall, M_reset, OP_R, clock);
    PipelinedReg # (32) M_valP_preg(M_valP, E_valP, M_stall, M_reset, 0, clock);

    // ALU
    PipelinedReg # (32) M_valE_preg(M_valE, e_valE, M_stall, M_reset, 0, clock);
    PipelinedReg # (32) M_valA_preg(M_valA, E_valA, M_stall, M_reset, 0, clock);
    PipelinedReg # (32) M_valB_preg(M_valB, E_valB, M_stall, M_reset, 0, clock);
    PipelinedReg # (1) M_Cnd_preg(M_Cnd, e_Cnd, M_stall, M_reset, 1'b0, clock);

    // memory
    PipelinedReg # (5) M_dstE_preg(M_dstE, E_dstE, M_stall, M_reset, REG_NONE, clock);
    PipelinedReg # (5) M_dstM_preg(M_dstM, E_dstM, M_stall, M_reset, REG_NONE, clock);
    
    // status
    PipelinedReg # (2) M_stat_preg(M_stat, E_stat, M_stall, M_reset, STAT_BUBBLE, clock);
    
    /** Write Back Stage **/
    
    // instruction
    PipelinedReg # (6) W_opcode_preg (W_opcode, M_opcode, W_stall, W_reset, OP_R, clock);

    // ALU
    PipelinedReg # (32) W_valE_preg(W_valE, m_valE, W_stall, W_reset, 0, clock);
    
    // memory
    PipelinedReg # (32) W_valM_preg(W_valM, m_valM, W_stall, W_reset, 0, clock);
    PipelinedReg # (5) W_dstE_preg(W_dstE, M_dstE, W_stall, W_reset, REG_NONE, clock);
    PipelinedReg # (5) W_dstM_preg(W_dstM, M_dstM, W_stall, W_reset, REG_NONE, clock);
    
    // status
    PipelinedReg # (2) W_stat_preg(W_stat, M_stat, W_stall, W_reset, STAT_BUBBLE, clock);

 
    /*** Stage Logic Implementation ***/
    
    /** Fetch Stage **/

    // select and increment  PC

    assign f_pc = 
        // misprediction
        (M_opcode == OP_BEQ | M_opcode == OP_BNE) & ~M_Cnd ? M_valP :
        // jr
        (E_opcode == OP_R & E_func == FUNC_JR) ? E_valA :
        // j, jal
        (M_opcode == OP_J | M_opcode == OP_JAL) ? M_valE :
        F_pred_pc;
        
    assign f_valP = f_pc + 4;

    InstructionRAM instruction_RAM(
        .CLOCK(mem_clock),
        .RESET(resetting),
        .FETCH_ADDRESS(f_pc >> 2),
        .ENABLE(running),
        .DATA(f_instr)
    );

    // align

    assign f_opcode = f_instr[31:26];
    assign f_rs     = f_instr[25:21];
    assign f_rt     = f_instr[20:16];
    assign f_rd     = f_instr[15:11];
    assign f_sa     = f_instr[10:6];
    assign f_func   = f_instr[5:0];
    assign f_imm    = f_instr[15:0];
    assign f_target = f_instr[25:0];

    // extend immediate, shift amount and target

    assign f_sign_extended_imm = f_imm[15] ? {{16{f_imm[15]}},f_imm} : {16'b0,f_imm};
    
    assign f_unsign_extended_imm = {16'b0,f_imm};
    
    assign f_extended_sa  = {27'b0,f_sa};

    assign f_extended_target = {6'b0,f_target};

    // merge constants

    assign f_valC = 
        f_opcode == OP_J | f_opcode == OP_JAL ? f_extended_target :
        f_opcode == OP_R & (f_func == FUNC_SLL | f_func == FUNC_SRA | f_func == FUNC_SRL) ? f_extended_sa : 
        f_opcode == OP_ADDI | f_opcode == OP_LW | f_opcode == OP_SW | f_opcode == OP_BEQ | f_opcode == OP_BNE ? f_sign_extended_imm : 
        f_unsign_extended_imm;

    // predict PC: 
    // For all branch operations (bne, beq), always predict as occurance.

    assign f_pred_pc = 
        f_opcode == OP_BEQ | f_opcode == OP_BNE ? f_valP + (f_sign_extended_imm << 2) :
        f_valP;
    
    assign f_stat = 
        f_instr == 32'hFFFFFFFF ? STAT_STOP :
        STAT_ALLOK;
    
    /** Decode Stage **/

    // destination registers for write back stage

    assign d_dstE = 
        D_opcode == OP_R & D_func != FUNC_JR ? D_rd :
        D_opcode == OP_JAL ? REG_RA :
        D_opcode == OP_SW | D_opcode == OP_LW | D_opcode == OP_BEQ | D_opcode == OP_BNE | D_opcode == OP_J | (D_opcode == OP_R & D_func == FUNC_JR) ? REG_NONE :
        D_rt;

    assign d_dstM = 
        D_opcode == OP_LW ? D_rt :
        REG_NONE;

    // read value from register file

    assign d_srcA = 
        D_opcode == OP_R & (D_func == FUNC_SLL | D_func == FUNC_SRA | D_func == FUNC_SRL) | D_opcode == OP_J | D_opcode == OP_JAL ? REG_NONE :
        D_rs;

    assign d_srcB = 
        D_opcode == OP_J | D_opcode == OP_JAL | (D_opcode == OP_R & D_func == FUNC_JR) ? REG_NONE :
        D_rt;

    RegisterFile register_file(
        .clock(mem_clock), .reset(resetting),
        .srcA(d_srcA), .srcB(d_srcB), 
        .dstE(W_dstE), .valE(W_valE), 
        .dstM(W_dstM), .valM(W_valM), 
        .valA(d_rvalA), .valB(d_rvalB),
        .zero(zero), .at(at), .v0(v0), .v1(v1), .a0(a0), .a1(a1), .a2(a2), .a3(a3), 
        .t0(t0), .t1(t1), .t2(t2), .t3(t3), .t4(t4), .t5(t5), .t6(t6), .t7(t7), .s0(s0), 
        .s1(s1), .s2(s2), .s3(s3), .s4(s4), .s5(s5), .s6(s6), .s7(s7), .t8(t8), .t9(t9), 
        .k0(k0), .k1(k1), .gp(gp), .sp(sp), .fp(fp), .ra(ra));

    // operand values selection: 
    // forwarding data if data harzard occurs.

    assign d_valA = 
        d_srcA == REG_NONE ? 0 :
        d_srcA == E_dstE ? e_valE :
        d_srcA == M_dstM ? m_valM :
        d_srcA == M_dstE ? M_valE :
        d_srcA == W_dstM ? W_valM :
        d_srcA == W_dstE ? W_valE :
        d_rvalA;

    assign d_valB = 
        d_srcB == REG_NONE ? 0 :
        d_srcB == E_dstE ? e_valE :
        d_srcB == M_dstM ? m_valM :
        d_srcB == M_dstE ? M_valE :
        d_srcB == W_dstM ? W_valM :
        d_srcB == W_dstE ? W_valE :
        d_rvalB;        
    
    /** Exectue Stage **/

    // ALU

    assign e_aluA = 
        E_opcode == OP_R & (E_func == FUNC_SLL | E_func == FUNC_SRA | E_func == FUNC_SRL) ? E_valC :
        E_opcode == OP_J | E_opcode == OP_JAL ? E_valP :
        E_valA;
    
    assign e_aluB = 
        E_opcode == OP_R & E_func != FUNC_JR | E_opcode == OP_BNE | E_opcode == OP_BEQ ? E_valB :
        E_valC;

    assign e_aluFunc = 
        E_opcode == OP_R & (E_func == FUNC_ADD | E_func == FUNC_ADDU) | E_opcode == OP_ADDI | E_opcode == OP_ADDIU | 
        E_opcode == OP_LW | E_opcode == OP_SW ? ALU_ADD :
        E_opcode == OP_R & (E_func == FUNC_SUB | E_func == FUNC_SUBU) | E_opcode == OP_BEQ | E_opcode == OP_BNE ? ALU_SUB :
        E_opcode == OP_R & E_func == FUNC_AND | E_opcode == OP_ANDI ? ALU_AND :
        E_opcode == OP_R & E_func == FUNC_OR | E_opcode == OP_ORI ? ALU_OR :
        E_opcode == OP_R & E_func == FUNC_XOR | E_opcode == OP_XORI ? ALU_XOR :
        E_opcode == OP_R & E_func == FUNC_NOR ? ALU_NOR :
        E_opcode == OP_R & (E_func == FUNC_SLL | E_func == FUNC_SLLV) ? ALU_SLL :
        E_opcode == OP_R & (E_func == FUNC_SRA | E_func == FUNC_SRAV) ? ALU_SRA :
        E_opcode == OP_R & (E_func == FUNC_SRL | E_func == FUNC_SRLV) ? ALU_SRL :
        E_opcode == OP_R & E_func == FUNC_JR ? ALU_JR :
        E_opcode == OP_J | E_opcode == OP_JAL ? ALU_JUMP :
        E_opcode == OP_R & E_func == FUNC_SLT ? ALU_SLT :
        E_opcode == OP_R & E_func == FUNC_SLTU ? ALU_SLTU :
        ALU_ZERO;

    ALU alu(e_aluA, e_aluB, e_aluFunc, e_valE, e_flags);

    // flags

    assign set_flags =
        (E_opcode == OP_R & (E_func == FUNC_ADD | E_func == FUNC_SUB | E_func == FUNC_SLT | E_func == FUNC_SLTU) | 
         E_opcode == OP_ADDI | E_opcode == OP_BEQ | E_opcode == OP_BNE) & ~(W_stat == STAT_STOP);

    FlagsReg flags_reg(flags, e_flags, running & set_flags, resetting, clock);

    // check branch
    assign e_Cnd = 
        (E_opcode == OP_BEQ & e_flags[2]) | (E_opcode == OP_BNE & ~e_flags[2]);
    
    /** Memory Stage **/

    assign mem_read = M_opcode == OP_LW;
    assign mem_write = M_opcode == OP_SW;

    // seclect merge valE and valP (handle JAL)

    assign m_valE = 
        M_opcode == OP_JAL ? M_valP :
        M_valE;

    // Only update memory when everything is running normally
    MainMemory main_memory(
        .CLOCK(mem_clock),
        .ENABLE(running | uploading),
        .FETCH_ADDRESS(uploading ? udaddr : M_valE >> 2),
        .EDIT_SERIAL({mem_write & running, M_valE >> 2, M_valB}),
        .DATA(m_valM)
    );
    
    /** Write Back Stage **/
    
    assign Stat = 
        W_stat == STAT_BUBBLE ? STAT_ALLOK : 
        W_stat;

    /** Harzard Detection **/

    assign F_stall = 
        // load/use harzard
        (E_opcode == OP_LW & (E_dstM == d_srcA | E_dstM == d_srcB)) | 
        // jump
        (D_opcode == OP_J | D_opcode == OP_JAL | (D_opcode == OP_R & D_func == FUNC_JR)) | (E_opcode == OP_J | E_opcode == OP_JAL);

    assign F_bubble = 0;

    assign D_stall =
        // load/use harzard
        E_opcode == OP_LW & (E_dstM == d_srcA | E_dstM == d_srcB);

    assign D_bubble =
        // jump
        ((D_opcode == OP_J | D_opcode == OP_JAL | (D_opcode == OP_R & D_func == FUNC_JR)) | (E_opcode == OP_J | E_opcode == OP_JAL) |
        // misprediction
         ((E_opcode == OP_BEQ | E_opcode == OP_BNE) & ~e_Cnd)) & 
        // handle confilction with load/use harzard
        ~(E_opcode == OP_LW & (E_dstM == d_srcA | E_dstM == d_srcB));

    assign E_stall =
        0;

    assign E_bubble =
        // misprediction
        (E_opcode == OP_BEQ | E_opcode == OP_BNE) & ~e_Cnd |
        // handle confilction with load/use harzard
        E_opcode == OP_LW & (E_dstM == d_srcA | E_dstM == d_srcB);

    assign M_stall =
        0;

    assign M_bubble =
        W_stat == STAT_STOP;

    assign W_stall =
        W_stat == STAT_STOP;

    assign W_bubble =
        0;
    
    
endmodule
