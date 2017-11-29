`timescale 1ns / 1ps
/****************************** C E C S  4 4 0 ******************************
 * 
 * File Name:  MIPS_32.v
 * Project:    Lab_Assignment_1
 * Designer:   Chanartip Soonthornwan, Jonathan Shihata
 * Email:      Chanartip.Soonthornwan@gmail.com, JonnyShihata@gmail.com
 * Rev. No.:   Version 1.0
 * Rev. Date:  Current Rev. Date 9/3/2017
 *
 * Purpose:    Processes two 32-bit input(S and T) according to
 *             Function Select(FS) and then return a 32-bit result,
 *             Overflow flag(V), and Carry flag(C).
 *         
 * Notes:      For an OP code that does not affect overflow flag (V) or 
 *             Carry flag (C) will output as 'x'
 *             U - unsigned
 *             I - Immediate
 *
 ****************************************************************************/
module MIPS_32(S, T, FS, Y, V, C);

   input      [31:0] S, T;      // Input Registers
   input      [ 4:0]   FS;      // Function Select(OP code)

   output reg [31:0]    Y;      // Output below 32th bit
   output reg        V, C;      // Overflow and Carry Flags

   integer   int_s, int_t;      // parse interger of S and T
   
   // Look-up table for Function Select(FS)
   parameter PASS_S = 5'h00,  AND  = 5'h08,  INC     = 5'h0F,
             PASS_T = 5'h01,  OR   = 5'h09,  DEC     = 5'h10,
             ADD    = 5'h02,  XOR  = 5'h0A,  INC4    = 5'h11,
             ADDU   = 5'h03,  NOR  = 5'h0B,  DEC4    = 5'h12,
             SUB    = 5'h04,  SLL  = 5'h0C,  ZEROS   = 5'h13,
             SUBU   = 5'h05,  SRL  = 5'h0D,  ONES    = 5'h14,
             SLT    = 5'h06,  SRA  = 5'h0E,  SP_INIT = 5'h15,
             SLTU   = 5'h07,  ANDI = 5'h16,
             MUL    = 5'h1E,  ORI  = 5'h17,
             DIV    = 5'h1F,  XORI = 5'h18,
                              LUI  = 5'h19;
             
   // Parse S and T to integer
   always@(*) begin
      int_s <= S;
      int_t <= T;
   end

   // Combination Logic for both Arithmetic and Logic Operations
   always@(*) begin
      case(FS)
         PASS_S: {V,C,Y} = {2'bxx, S};                // Pass S  
         PASS_T: {V,C,Y} = {2'bxx, T};                // Pass T
         ADD   : begin                                // Adding
            {C,Y} = S + T;
               V  = {  S[31] &  T[31] & ~Y[31] }|     // (+) + (+) = (-)
                    { ~S[31] & ~T[31] &  Y[31] };     // (-) + (-) = (+)
            end
         ADDU  : begin                                // Adding Unsigned
            {C,Y} = S + T;
               V  = C;
            end
         SUB   : begin                                // Subtracting
            {C,Y} = S - T;
               V  = {  S[31] & ~T[31] & ~Y[31] }|     // (+) - (-) = (-)
                    { ~S[31] &  T[31] &  Y[31] };     // (-) - (+) = (+)
            end
         SUBU  : begin                                // Subtracting Unsigned
            {C,Y} = S - T;
               V  = C;
            end
         SLT   : begin                                // Set Less Than
            {V,C} = 2'bxx;
                Y = int_s < int_t;                    // comparing signed integers
            end
         SLTU  : begin                                // Set Less Than Unsigned
            {V,C} = 2'bxx;
               Y  = S < T;                            // comparing bits
            end
         AND   : {V,C,Y} = {2'bxx, S & T};             // And
         OR    : {V,C,Y} = {2'bxx, S | T};             // Or
         XOR   : {V,C,Y} = {2'bxx, S ^ T};             // Xor
         NOR   : {V,C,Y} = {2'bxx, ~(S | T)};          // Nor
         SLL   : begin                                // Shift Left Logic
            {V,C} = {1'bx, T[31]};
                Y = {T[30:0], 1'b0}; 
            end   
         SRL   : begin                                // Shift Right Logic
            {V,C} = {1'bx, T[0]};
                Y = {1'b0, T[31:1]}; 
            end   
         SRA   : begin                                // Shift Right Arithmatic
            {V,C} = {1'bx, T[0]};
                Y = {T[31], T[31:1]}; 
            end   
         ANDI  : {V,C,Y} = {2'bxx, S & {16'b0, T[15:0]}};
         ORI   : {V,C,Y} = {2'bxx, S | {16'b0, T[15:0]}};
         XORI  : {V,C,Y} = {2'bxx, S ^ {16'b0, T[15:0]}};
         LUI   : {V,C,Y} = {2'bxx, T[15:0], 16'b0};    // Load Upper Immediate
         INC   : begin                                // Increment (by one)
            {C,Y} = S + 1;
               V  = {  S[31] & ~Y[31] }|              // (+) + 1 = (-)
                    { ~S[31] &  Y[31] };              // (-) + 1 = (+)
            end
         DEC   : begin                                // Decrement (by one)
            {C,Y} = S - 1;
               V  = {  S[31] & ~Y[31] }|              // (+) - 1 = (-)
                    { ~S[31] &  Y[31] };              // (-) - 1 = (+)
            end
         INC4  : begin                                // Increment (by four)
            {C,Y} = S + 4;
               V  = {  S[31] & ~Y[31] }|              // (+) + 4 = (-)
                    { ~S[31] &  Y[31] };              // (-) + 4 = (+)
            end
         DEC4  : begin                                // Decrement (by four)
            {C,Y} = S - 4;
               V  = {  S[31] & ~Y[31] }|              // (+) - 4 = (-)
                    { ~S[31] &  Y[31] };              // (-) - 4 = (+)
            end
         ZEROS : {V,C,Y} = {2'bxx, 32'h0};             // Set to Zero
         ONES  : {V,C,Y} = {2'bxx, 32'hFFFFFFFF};      // Set to One
         SP_INIT: {V,C,Y} = {2'bxx, 32'h3FC};          // Stack Pointer Init
         default: {V,C,Y} = {2'bxx, S};                // Pass S
      endcase 
   end

endmodule
