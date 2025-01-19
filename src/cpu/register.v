// Different types of registers, all derivatives of module BasicReg

// Clocked register with enable signal and synchronous reset
module BasicReg(out, in, enable, reset, resetval, clock);
    parameter width = 8;
    output [width-1:0] out;
    reg [width-1:0] out;
    input [width-1:0] in;
    input enable;
    input reset;
    input [width-1:0] resetval;
    input clock;

    always
        @(posedge clock)
        begin
            if (reset)
                out <= resetval;
            else if (enable)
                out <= in;
        end
endmodule

// Pipeline register. Uses reset signal to inject bubble
// When bubbling, must specify value that will be loaded
module PipelinedReg(out, in, stall, bubble, bubbleval, clock);
    parameter width = 8;
    output [width-1:0] out;
    input [width-1:0] in;
    input stall, bubble;
    input [width-1:0] bubbleval;
    input clock;

    BasicReg #(width) r(out, in, ~stall, bubble, bubbleval, clock);
endmodule

// Condition code register
module FlagsReg(cc, new_cc, set_cc, reset, clock);
    output[2:0] cc;
    input [2:0] new_cc;
    input set_cc;
    input reset;
    input clock;
    BasicReg #(3) c(cc, new_cc, set_cc, reset, 3'b000, clock);
endmodule

module RegisterFile(clock, reset, srcA, srcB, dstE, valE, dstM, valM, valA, valB,
                    zero, at, v0, v1, a0, a1, a2, a3, t0, t1, t2, t3, t4,
                    t5, t6, t7, s0, s1, s2, s3, s4, s5, s6, s7, t8, t9, k0,
                    k1, gp, sp, fp, ra);
    input clock, reset;
    input [4:0] srcA, srcB;
    input [4:0] dstE, dstM;
    input [31:0] valE, valM;
    output [31:0] valA, valB;

    // Make every registers visible for debugging
    output [31:0] zero, at, v0, v1, a0, a1, a2, a3, t0, t1, t2, t3, t4,
                    t5, t6, t7, s0, s1, s2, s3, s4, s5, s6, s7, t8, t9, k0,
                    k1, gp, sp, fp, ra;

    // general register IDs
    localparam
        REG_ZERO   = 5'b00000,
        REG_AT     = 5'b00001,
        REG_V0     = 5'b00010,
        REG_V1     = 5'b00011,
        REG_A0     = 5'b00100,
        REG_A1     = 5'b00101,
        REG_A2     = 5'b00110,
        REG_A3     = 5'b00111,
        REG_T0     = 5'b01000,
        REG_T1     = 5'b01001,
        REG_T2     = 5'b01010,
        REG_T3     = 5'b01011,
        REG_T4     = 5'b01100,
        REG_T5     = 5'b01101,
        REG_T6     = 5'b01110,
        REG_T7     = 5'b01111,
        REG_S0     = 5'b10000,
        REG_S1     = 5'b10001,
        REG_S2     = 5'b10010,
        REG_S3     = 5'b10011,
        REG_S4     = 5'b10100,
        REG_S5     = 5'b10101,
        REG_S6     = 5'b10110,
        REG_S7     = 5'b10111,
        REG_T8     = 5'b11000,
        REG_T9     = 5'b11001,
        REG_K0     = 5'b11010,
        REG_K1     = 5'b11011,
        REG_GP     = 5'b11100,
        REG_SP     = 5'b11101,
        REG_FP     = 5'b11110,
        REG_RA     = 5'b11111;

    // Make every registers visible for debugging
    wire [31:0] zero_data, at_data, v0_data, v1_data, a0_data, a1_data, a2_data, a3_data, t0_data, t1_data, t2_data, t3_data, t4_data,
                  t5_data, t6_data, t7_data, s0_data, s1_data, s2_data, s3_data, s4_data, s5_data, s6_data, s7_data, t8_data, t9_data,
                  k0_data, k1_data, gp_data, sp_data, fp_data, ra_data;

    wire zero_wrt, at_wrt, v0_wrt, v1_wrt, a0_wrt, a1_wrt, a2_wrt, a3_wrt, t0_wrt, t1_wrt, t2_wrt, t3_wrt, t4_wrt,
           t5_wrt, t6_wrt, t7_wrt, s0_wrt, s1_wrt, s2_wrt, s3_wrt, s4_wrt, s5_wrt, s6_wrt, s7_wrt, t8_wrt, t9_wrt, 
           k0_wrt, k1_wrt, gp_wrt, sp_wrt, fp_wrt, ra_wrt;

    // Implement with clocked registers
    BasicReg # (32) zero_reg(zero, zero_data, zero_wrt, reset, 32'b0, clock);
    BasicReg # (32)   at_reg(at,   at_data,   at_wrt, reset, 32'b0, clock);
    BasicReg # (32)   v0_reg(v0,   v0_data,   v0_wrt, reset, 32'b0, clock);
    BasicReg # (32)   v1_reg(v1,   v1_data,   v1_wrt, reset, 32'b0, clock);
    BasicReg # (32)   a0_reg(a0,   a0_data,   a0_wrt, reset, 32'b0, clock);
    BasicReg # (32)   a1_reg(a1,   a1_data,   a1_wrt, reset, 32'b0, clock);
    BasicReg # (32)   a2_reg(a2,   a2_data,   a2_wrt, reset, 32'b0, clock);
    BasicReg # (32)   a3_reg(a3,   a3_data,   a3_wrt, reset, 32'b0, clock);
    BasicReg # (32)   t0_reg(t0,   t0_data,   t0_wrt, reset, 32'b0, clock);
    BasicReg # (32)   t1_reg(t1,   t1_data,   t1_wrt, reset, 32'b0, clock);    
    BasicReg # (32)   t2_reg(t2,   t2_data,   t2_wrt, reset, 32'b0, clock);
    BasicReg # (32)   t3_reg(t3,   t3_data,   t3_wrt, reset, 32'b0, clock);
    BasicReg # (32)   t4_reg(t4,   t4_data,   t4_wrt, reset, 32'b0, clock);
    BasicReg # (32)   t5_reg(t5,   t5_data,   t5_wrt, reset, 32'b0, clock);    
    BasicReg # (32)   t6_reg(t6,   t6_data,   t6_wrt, reset, 32'b0, clock);
    BasicReg # (32)   t7_reg(t7,   t7_data,   t7_wrt, reset, 32'b0, clock);
    BasicReg # (32)   s0_reg(s0,   s0_data,   s0_wrt, reset, 32'b0, clock);
    BasicReg # (32)   s1_reg(s1,   s1_data,   s1_wrt, reset, 32'b0, clock);    
    BasicReg # (32)   s2_reg(s2,   s2_data,   s2_wrt, reset, 32'b0, clock);
    BasicReg # (32)   s3_reg(s3,   s3_data,   s3_wrt, reset, 32'b0, clock);
    BasicReg # (32)   s4_reg(s4,   s4_data,   s4_wrt, reset, 32'b0, clock);
    BasicReg # (32)   s5_reg(s5,   s5_data,   s5_wrt, reset, 32'b0, clock);    
    BasicReg # (32)   s6_reg(s6,   s6_data,   s6_wrt, reset, 32'b0, clock);
    BasicReg # (32)   s7_reg(s7,   s7_data,   s7_wrt, reset, 32'b0, clock);
    BasicReg # (32)   t8_reg(t8,   t8_data,   t8_wrt, reset, 32'b0, clock);
    BasicReg # (32)   t9_reg(t9,   t9_data,   t9_wrt, reset, 32'b0, clock);    
    BasicReg # (32)   k0_reg(k0,   k0_data,   k0_wrt, reset, 32'b0, clock);
    BasicReg # (32)   k1_reg(k1,   k1_data,   k1_wrt, reset, 32'b0, clock);
    BasicReg # (32)   gp_reg(gp,   gp_data,   gp_wrt, reset, 32'b0, clock);
    BasicReg # (32)   sp_reg(sp,   sp_data,   sp_wrt, reset, 32'b0, clock);
    BasicReg # (32)   fp_reg(fp,   fp_data,   fp_wrt, reset, 32'b0, clock);
    BasicReg # (32)   ra_reg(ra,   ra_data,   ra_wrt, reset, 32'b0, clock);

    // Read
    assign valA =  
        srcA ==   REG_ZERO ? zero :
        srcA ==   REG_AT   ?   at :
        srcA ==   REG_V0   ?   v0 :
        srcA ==   REG_V1   ?   v1 :
        srcA ==   REG_A0   ?   a0 :
        srcA ==   REG_A1   ?   a1 :
        srcA ==   REG_A2   ?   a2 :
        srcA ==   REG_A3   ?   a3 :
        srcA ==   REG_T0   ?   t0 :
        srcA ==   REG_T1   ?   t1 :
        srcA ==   REG_T2   ?   t2 :
        srcA ==   REG_T3   ?   t3 :
        srcA ==   REG_T4   ?   t4 :
        srcA ==   REG_T5   ?   t5 :
        srcA ==   REG_T6   ?   t6 :
        srcA ==   REG_T7   ?   t7 :
        srcA ==   REG_S0   ?   s0 :
        srcA ==   REG_S1   ?   s1 :
        srcA ==   REG_S2   ?   s2 :
        srcA ==   REG_S3   ?   s3 :
        srcA ==   REG_S4   ?   s4 :
        srcA ==   REG_S5   ?   s5 :
        srcA ==   REG_S6   ?   s6 :
        srcA ==   REG_S7   ?   s7 :
        srcA ==   REG_T8   ?   t8 :
        srcA ==   REG_T9   ?   t9 :
        srcA ==   REG_K0   ?   k0 :
        srcA ==   REG_K1   ?   k1 :
        srcA ==   REG_GP   ?   gp :
        srcA ==   REG_SP   ?   sp :
        srcA ==   REG_FP   ?   fp :
        srcA ==   REG_RA   ?   ra :
        0;
    
    assign valB =      
        srcB ==   REG_ZERO ? zero :
        srcB ==   REG_AT   ?   at :
        srcB ==   REG_V0   ?   v0 :
        srcB ==   REG_V1   ?   v1 :
        srcB ==   REG_A0   ?   a0 :
        srcB ==   REG_A1   ?   a1 :
        srcB ==   REG_A2   ?   a2 :
        srcB ==   REG_A3   ?   a3 :
        srcB ==   REG_T0   ?   t0 :
        srcB ==   REG_T1   ?   t1 :
        srcB ==   REG_T2   ?   t2 :
        srcB ==   REG_T3   ?   t3 :
        srcB ==   REG_T4   ?   t4 :
        srcB ==   REG_T5   ?   t5 :
        srcB ==   REG_T6   ?   t6 :
        srcB ==   REG_T7   ?   t7 :
        srcB ==   REG_S0   ?   s0 :
        srcB ==   REG_S1   ?   s1 :
        srcB ==   REG_S2   ?   s2 :
        srcB ==   REG_S3   ?   s3 :
        srcB ==   REG_S4   ?   s4 :
        srcB ==   REG_S5   ?   s5 :
        srcB ==   REG_S6   ?   s6 :
        srcB ==   REG_S7   ?   s7 :
        srcB ==   REG_T8   ?   t8 :
        srcB ==   REG_T9   ?   t9 :
        srcB ==   REG_K0   ?   k0 :
        srcB ==   REG_K1   ?   k1 :
        srcB ==   REG_GP   ?   gp :
        srcB ==   REG_SP   ?   sp :
        srcB ==   REG_FP   ?   fp :
        srcB ==   REG_RA   ?   ra :
        0;

    // Write
    assign zero_data = dstM == REG_ZERO ? valM : valE;
    assign   at_data = dstM == REG_AT   ? valM : valE;
    assign   v0_data = dstM == REG_V0   ? valM : valE;
    assign   v1_data = dstM == REG_V1   ? valM : valE;
    assign   a0_data = dstM == REG_A0   ? valM : valE;
    assign   a1_data = dstM == REG_A1   ? valM : valE;
    assign   a2_data = dstM == REG_A2   ? valM : valE;
    assign   a3_data = dstM == REG_A3   ? valM : valE;
    assign   t0_data = dstM == REG_T0   ? valM : valE;
    assign   t1_data = dstM == REG_T1   ? valM : valE;
    assign   t2_data = dstM == REG_T2   ? valM : valE;
    assign   t3_data = dstM == REG_T3   ? valM : valE;
    assign   t4_data = dstM == REG_T4   ? valM : valE;
    assign   t5_data = dstM == REG_T5   ? valM : valE;
    assign   t6_data = dstM == REG_T6   ? valM : valE;
    assign   t7_data = dstM == REG_T7   ? valM : valE;
    assign   s0_data = dstM == REG_S0   ? valM : valE;
    assign   s1_data = dstM == REG_S1   ? valM : valE;
    assign   s2_data = dstM == REG_S2   ? valM : valE;
    assign   s3_data = dstM == REG_S3   ? valM : valE;
    assign   s4_data = dstM == REG_S4   ? valM : valE;
    assign   s5_data = dstM == REG_S5   ? valM : valE;
    assign   s6_data = dstM == REG_S6   ? valM : valE;
    assign   s7_data = dstM == REG_S7   ? valM : valE;
    assign   t8_data = dstM == REG_T8   ? valM : valE;
    assign   t9_data = dstM == REG_T9   ? valM : valE;
    assign   k0_data = dstM == REG_K0   ? valM : valE;
    assign   k1_data = dstM == REG_K1   ? valM : valE;
    assign   gp_data = dstM == REG_GP   ? valM : valE;
    assign   sp_data = dstM == REG_SP   ? valM : valE;
    assign   fp_data = dstM == REG_FP   ? valM : valE;
    assign   ra_data = dstM == REG_RA   ? valM : valE;

    assign zero_wrt =   0; // $zero is not writable
    assign   at_wrt =  dstM == REG_AT | dstE == REG_AT;
    assign   v0_wrt =  dstM == REG_V0 | dstE == REG_V0;
    assign   v1_wrt =  dstM == REG_V1 | dstE == REG_V1;
    assign   a0_wrt =  dstM == REG_A0 | dstE == REG_A0;
    assign   a1_wrt =  dstM == REG_A1 | dstE == REG_A1;
    assign   a2_wrt =  dstM == REG_A2 | dstE == REG_A2;
    assign   a3_wrt =  dstM == REG_A3 | dstE == REG_A3;
    assign   t0_wrt =  dstM == REG_T0 | dstE == REG_T0;
    assign   t1_wrt =  dstM == REG_T1 | dstE == REG_T1;
    assign   t2_wrt =  dstM == REG_T2 | dstE == REG_T2;
    assign   t3_wrt =  dstM == REG_T3 | dstE == REG_T3;
    assign   t4_wrt =  dstM == REG_T4 | dstE == REG_T4;
    assign   t5_wrt =  dstM == REG_T5 | dstE == REG_T5;
    assign   t6_wrt =  dstM == REG_T6 | dstE == REG_T6;
    assign   t7_wrt =  dstM == REG_T7 | dstE == REG_T7;
    assign   s0_wrt =  dstM == REG_S0 | dstE == REG_S0;
    assign   s1_wrt =  dstM == REG_S1 | dstE == REG_S1;
    assign   s2_wrt =  dstM == REG_S2 | dstE == REG_S2;
    assign   s3_wrt =  dstM == REG_S3 | dstE == REG_S3;
    assign   s4_wrt =  dstM == REG_S4 | dstE == REG_S4;
    assign   s5_wrt =  dstM == REG_S5 | dstE == REG_S5;
    assign   s6_wrt =  dstM == REG_S6 | dstE == REG_S6;
    assign   s7_wrt =  dstM == REG_S7 | dstE == REG_S7;
    assign   t8_wrt =  dstM == REG_T8 | dstE == REG_T8;
    assign   t9_wrt =  dstM == REG_T9 | dstE == REG_T9;
    assign   k0_wrt =  dstM == REG_K0 | dstE == REG_K0;
    assign   k1_wrt =  dstM == REG_K1 | dstE == REG_K1;
    assign   gp_wrt =  dstM == REG_GP | dstE == REG_GP;
    assign   sp_wrt =  dstM == REG_SP | dstE == REG_SP;
    assign   fp_wrt =  dstM == REG_FP | dstE == REG_FP;
    assign   ra_wrt =  dstM == REG_RA | dstE == REG_RA;

endmodule


