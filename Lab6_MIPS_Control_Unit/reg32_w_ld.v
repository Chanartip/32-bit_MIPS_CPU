`timescale 1ns / 1ps
/****************************** C E C S  4 4 0 ******************************
 * 
 * File Name:  reg32_w_ld.v
 * Project:    Lab_Assignment_1
 * Designer:   Chanartip Soonthornwan, Jonathan Shihata
 * Email:      Chanartip.Soonthornwan@gmail.com, JonnyShihata@gmail.com
 * Rev. No.:   Version 1.0
 * Rev. Date:  Date 9/29/2017
 *
 * Rev. No.:   Version 2.0
 * Rev. Date:  Current Rev. Date 10/10/2017
 *    Notes:   - change port list to be reuseable as 32-bit register module
 *
 * Purpose:    A register to hold 32-bit result until load enable(load)
 *             allows data input(d) to overwritten previous value.
 *         
 * Notes:      This register operates on the active edge of the clock
 *             signal input (clk). If the load enable (load) is HIGH,
 *             the register will hold the new data input instead.
 *
 ****************************************************************************/
 module reg32_w_ld (clk, reset, load, d, q);
 
   input      clk, reset;                // on-board clock, and reset signal
   input            load;                // load enable
   input      [31:0]   d;                // data inputs
   output reg [31:0]   q;                // data outputs
   
   always @ (posedge clk, posedge reset)
      if(reset) q <= 32'b0;   else     // reset
      if(load)  q <=     d;            // assign new value
      else      q <=     q;            // keep previous value

endmodule
