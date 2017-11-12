`timescale 1ns / 1ps
/****************************** C E C S  4 4 0 ******************************
 * 
 * File Name:  ALU_32.v
 * Project:    Lab_Assignment_1
 * Designer:   Chanartip Soonthornwan, Jonathan Shihata
 * Email:      Chanartip.Soonthornwan@gmail.com, JonnyShihata@gmail.com
 * Rev. No.:   Version 1.0
 * Rev. Date:  Current Rev. Date 9/3/2017
 *
 * Purpose:    Top View of 32-bit Arithmatics Logic Unit(ALU). Used for 
 *             computing Arithmatic of two 32-bit inputs, register S and T.
 *             Performs 30 different operations where 28 operations in 
 *             MIPS_32.v, multiplication in MPY_32.v, and division in DIV_32.v
 *         
 * Notes:      ~|{Y1, Y2} Nor all bits in side the concatenated Y1 and Y2
 *             if all bits are zero, the result is one (or true).
 *
 ****************************************************************************/
module ALU_32(S, T, FS, Y_hi, Y_lo, C, V, N, Z);

   input  [31:0]  S, T;                         // 32-bit inputs
   input  [ 4:0]    FS;                         // Function Select

   output [31:0]  Y_hi;                         // Upper 32-bit of Output
   output [31:0]  Y_lo;                         // Lower 32-bit of Output
   output   C, V, N, Z;                         // Flag Status

   wire   mips_v, mips_c, mul_z, mip_z, div_z;  // Temporary flag status
   wire   [31:0]   mips_y                    ;  // Y Output from MIPS_32
   wire   [31:0]   mul_hi, mul_lo            ;  // Y Output from MPY_32
   wire   [31:0]   div_rem, div_qout         ;  // Y Output from DIV_32

   parameter  ADDU = 5'h03,
              SUBU = 5'h05,
              MUL  = 5'h1E,
              DIV  = 5'h1F;
 
   // Multiplication
   // return a64-bit result of multiplying S and T 
   //             (S, T, _______Y_______ )
   MPY_32 alu_mul (S, T, {mul_hi, mul_lo});
   
   // Division
   // return 32-bit results where Y_hi = remainder and Y_lo = qoutian
   //             (S, T, __rem__, __qout__)
   DIV_32 alu_div (S, T, div_rem, div_qout);
   
   // Million Instructions Per Second (MIPS)
   // return a 32-bit result(Y), overflow flag(v), and carry flag(c)
   //              (S, T, FS, __Y___, __V___, __C___)
   MIPS_32 alu_mips(S, T, FS, mips_y, mips_v, mips_c);

   // Multiplexer to assign 64-bit outputs
   // If MULtiplication, return a 64-bit output.
   // Else if DIVision,  return a remainder and qoutian.
   // Else               return 32-bit zeros and 32-bit result.     
   assign {Y_hi, Y_lo} = (FS == MUL)? { mul_hi , mul_lo  }: 
                         (FS == DIV)? { div_rem, div_qout}:
                                      {   32'b0, mips_y  };

   // Checking and assigning temporary the Zero flag 
   // ~| is nor reduction operand where 
   // the all output bits will be Nor
   // and return 1 if all bits are zero.
   // Return 0 if any bit is one.
   assign mul_z = ~|{Y_hi, Y_lo},
          div_z = (T == 32'b0)? 1'bz : ~|{Y_lo},
          mip_z = ~|{Y_lo};

   // Multiplexer to assign the Zero flag output
   // assign z flag according to Function Select(FS)
   assign Z = (FS == MUL)? mul_z: 
              (FS == DIV)? div_z:
                           mip_z;
   
   // Multiplexer to assign Negative flag 
   // Assign n flag according to the Most Significant Bit(MSB)
   assign N = (FS == MUL) ? Y_hi[31]:
              (FS == DIV) ? Y_lo[31]:
              (FS == ADDU)?     1'b0:
              (FS == SUBU)?     1'b0:
                            Y_lo[31];
   
   // Multiplexer to assign Overflow flag 
   // *Note: Multiplication and Division 
   // are not affected over flow flag
   assign V = (FS == MUL) ? 1'bx:
              (FS == DIV) ? 1'bx:
                          mips_v;
   
   // Multiplexer to assign Carry flag    
   // *Note: Multiplication and Division 
   // are not affected carry out flag
   assign C = (FS == MUL) ? 1'bx:
              (FS == DIV) ? 1'bx:
                          mips_c;
   
endmodule 
