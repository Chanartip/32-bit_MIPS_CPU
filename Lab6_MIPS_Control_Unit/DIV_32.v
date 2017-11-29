`timescale 1ns / 1ps
/****************************** C E C S  4 4 0 ******************************
 * 
 * File Name:  DIV_32.v
 * Project:    Lab_Assignment_1
 * Designer:   Chanartip Soonthornwan, Jonathan Shihata
 * Email:      Chanartip.Soonthornwan@gmail.com, JonnyShihata@gmail.com
 * Rev. No.:   Version 1.0
 * Rev. Date:  Current Rev. Date 9/3/2017
 *
 * Purpose:    Divide two 32-bit inputs and return remainder and qoutian
 *         
 * Notes:      Two inputs are needed to be casted as integers.
 *             division is qoutationg, or p reslt.
 *             modulus has
 *
 ****************************************************************************/
module DIV_32(S, T, rem, qout);
 
   input      [31:0]      S, T;     // 32-bit inputs
   output reg [31:0] rem, qout;     // Remainder and Qoutian outputs
   
   integer int_s, int_t;            // Integer of each inputs
   
   // Parse S and T into integers
   always@(*) begin
      int_s <= S;
      int_t <= T;
   end
   
   // Divide the two integers
   always@(*) begin
         qout = int_s / int_t;      // Quotient
         rem  = int_s % int_t;      // Remainder      
   end                           

endmodule
