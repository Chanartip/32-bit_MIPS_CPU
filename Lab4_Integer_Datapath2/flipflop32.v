`timescale 1ns / 1ps
/* ***************************** C E C S  4 4 0 *******************************
 * 
 * File Name:  flipflop32.v
 * Project:    Lab_Assignment_4
 * Designer:   Chanartip Soonthornwan
 * Email:      Chanartip.Soonthornwan@gmail.com
 * Rev. No.:   Version 1.0
 * Rev. Date:  Current Rev. Date 10/7/2017
 *
 * Purpose:    A 32-bit memory holding 32-bit value and output it
 *             on next active clock.
 *
 * ***************************************************************************/
module flipflop32(clk, reset, d, q);

   input     clk, reset;
   input      [31:0]  d;
   output reg [31:0]  q;

   always@(posedge clk, posedge reset) 
      if(reset) q <= 32'b0;
      else      q <= d;

endmodule
