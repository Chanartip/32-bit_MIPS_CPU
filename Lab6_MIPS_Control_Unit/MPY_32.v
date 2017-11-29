`timescale 1ns / 1ps
/****************************** C E C S  4 4 0 ******************************
 * 
 * File Name:  MPY_32.v
 * Project:    Lab_Assignment_1
 * Designer:   Chanartip Soonthornwan, Jonathan Shihata
 * Email:      Chanartip.Soonthornwan@gmail.com, JonnyShihata@gmail.com
 * Rev. No.:   Version 1.0
 * Rev. Date:  Current Rev. Date 9/3/2017
 *
 * Purpose:    Multiply two 32-bit inputs and return a 64-bit results.
 *             
 * Notes:      Two inputs are needed to be casted as integers before
 *             being operated.
 *
 ****************************************************************************/
module MPY_32(S, T, Y);
   
   input      [31:0] S, T;       // 32-bit inputs
   output reg [63:0]    Y;       // 64-bit result
   
   integer   int_s, int_t;       // integer for each inputs
   
   // Cast S and T into integers
   always@(*) begin
      int_s <= S;
      int_t <= T;
   end
   
   // Multiply the two integers
   always@(*)   
      Y = int_s * int_t;    
                       
endmodule
