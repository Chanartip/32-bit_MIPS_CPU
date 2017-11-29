`timescale 1ns / 1ps
/* ***************************** C E C S  4 4 0 *******************************
 * 
 * File Name:  reg32_no_ld.v
 * Project:    Lab_Assignment_4
 * Designer:   Chanartip Soonthornwan, Jonathan Shihata
 * Email:      Chanartip.Soonthornwan@gmail.com, JonnyShihata@gmail.com
 * Rev. No.:   Version 1.0
 * Rev. Date:  10/7/2017
 * 
 * Rev. No.:   Version 1.1
 * Rev. Date:  Current Rev. 10/10/2017
 *    Notes:   - filename changed
 *             - comments added
 *
 * Purpose:    A 32-bit memory holding 32-bit value and output it
 *             on next active clock.
 *
 * ***************************************************************************/
module reg32_no_ld(clk, reset, d, q);

   input     clk, reset;      // on-board clock, and reset signal
   input      [31:0]  d;      // data inputs
   output reg [31:0]  q;      // data outputs

   always@(posedge clk, posedge reset) 
      if(reset) q <= 32'b0;   // reset
      else      q <= d;       // assign new value

endmodule
