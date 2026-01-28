\m4_TLV_version 1d: tl-x.org
\SV
   // This code can be found in: https://github.com/stevehoover/VSDOpen2020_TLV_RISC-V_Tutorial
   
   m4_include_lib(['https://raw.githubusercontent.com/cmanovit/makerchip-labs/refs/heads/main/lib/shell.tlv'])

\SV
   m4_makerchip_module   // (Expanded in Nav-TLV pane.)
   /* verilator lint_on WIDTH */

                   
\TLV

   // /====================\
   // | Sum 1 to 9 Program |
   // \====================/
   //
   // Program for MYTH Workshop to test RV32I
   // Add 1,2,3,...,9 (in that order).
   //
   // Regs:
   //  r10 (a0): In: 0, Out: final sum
   //  r12 (a2): 10
   //  r13 (a3): 1..10
   //  r14 (a4): Sum
   // 
   // External to function:
   m4_asm(ADD, r10, r0, r0)             // Initialize x10 to 0.
   // Function:
   m4_asm(ADD, r14, r10, r0)            // Initialize sum register x14 with 0x0
   m4_asm(ADDI, r12, r10, 1010)         // Store count of 10 in register x12.
   m4_asm(ADD, r13, r10, r0)            // Initialize intermediate sum register x13 with 0
   // Loop:
   m4_asm(ADD, r14, r13, r14)           // Incremental addition
   m4_asm(ADDI, r13, r13, 1)            // Increment intermediate register by 1
   m4_asm(BLT, r13, r12, 1111111111000) // If x13 is less than x12, branch to <loop>
   m4_asm(ADDI, r13, r13, 1)            // Increment intermediate register by 1
   m4_asm(ADD, r10, r14, r0)            // Store final result to register x10 so that it can be read by main program
   m4_asm(ADDI, r31, r0, 1)             // Signal end of test
   
   
   
   // ---
   // CPU
   // ---
   
   |cpu
      @0
         // Lab: PC
         $pc[31:0] = >>1$reset        ? 32'b0 :
                     >>2$taken_branch ? >>2$br_target_pc :    // (initially $taken_branch == 0)
                                        >>1$inc_pc;
         // Lab: Fetch
         $imem_rd_addr[3:0] = $pc[5:2];
         $instr[31:0] = $imem_rd_data;

      @1
         $inc_pc[31:0] = $pc + 32'b100;

         // Lab: Instruction Types Decode
         $is_i_instr = $instr[6:5] == 2'b00;
         $is_r_instr = $instr[6:5] == 2'b01 || $instr[6:5] == 2'b10;
         $is_b_instr = $instr[6:5] == 2'b11;

         // Lab: Instruction Immediate Decode
         $imm[31:0]  = $is_i_instr ? { {21{$instr[31]}}, $instr[30:20] } :   // I-type
                       $is_b_instr ? { {20{$instr[31]}}, $instr[7], $instr[30:25], $instr[11:8], 1'b0 } :    // B-type
                       32'b0;   // Default (unused)

         // Lab: Instruction Field Decode
         $rs2[4:0]    = $instr[24:20];
         $rs1[4:0]    = $instr[19:15];
         $funct3[2:0] = $instr[14:12];
         $rd[4:0]     = $instr[11:7];
         $opcode[6:0] = $instr[6:0];

         // Lab: Register Validity Decode
         $rs1_valid = $is_r_instr || $is_i_instr || $is_b_instr;
         $rs2_valid = $is_r_instr || $is_b_instr;
         $rd_valid  = $is_r_instr || $is_i_instr;

         // Lab: Instruction Decode
         $dec_bits[9:0] = {$funct3, $opcode};
         $is_blt  = $dec_bits == 10'b100_1100011;
         $is_addi = $dec_bits == 10'b000_0010011;
         $is_add  = $dec_bits == 10'b000_0110011;

         // Lab: Register File Read
         $rf_rd_en1         = $rs1_valid;
         $rf_rd_en2         = $rs2_valid;
         $rf_rd_index1[4:0] = $rs1;
         $rf_rd_index2[4:0] = $rs2;

      @2
         $src1_value[31:0] = >>1$rf_wr_valid && >>1$rf_wr_index == $rf_rd_index1 ? >>1$rf_wr_data : $rf_rd_data1;
         $src2_value[31:0] = >>1$rf_wr_valid && >>1$rf_wr_index == $rf_rd_index2 ? >>1$rf_wr_data : $rf_rd_data2;
         //$src2_value[31:0] = $rf_rd_data2;

         // Lab: ALU
         $result[31:0] = $is_addi ? $src1_value + $imm :    // ADDI: src1 + imm
                         $is_add  ? $src1_value + $src2_value :   // ADD: src1 + src2
                                    32'b0;   // Default (unused)

         // Lab: Branch Target
         $br_target_pc[31:0] = $pc + $imm;
         // $taken_branch and $br_target_pc control the PC mux.

         // Lab: Branch Condition
         $taken_branch = $is_blt ? ($src1_value < $src2_value) : 1'b0;
         $valid_taken_branch = $taken_branch && $valid;
         $valid = ! $reset && ! >>1$valid_taken_branch; // && ! $taken_branch;

         $rf_wr_valid = $rd_valid && $valid;

      @3
         // Lab: Register File Write
         $rf_wr_en         = $rf_wr_valid;
         $rf_wr_index[4:0] = $rd;
         $rf_wr_data[31:0] = $result;

   
   m4+shell(@3, @0, @1, @3, @3, (1+2+3+4+5+6+7+8+9), 75)  // (@viz, @imem, @rf_rd, @rf_wr, @rf_check, check_value, end_cycle)


\SV
   endmodule
