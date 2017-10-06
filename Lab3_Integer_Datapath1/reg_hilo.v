`timescale 1ns / 1ps
/****************************** C E C S  4 4 0 ******************************
 * 
 * File Name:  reg_hilo.v
 * Project:    Lab_Assignment_1
 * Designer:   Chanartip Soonthornwan
 * Email:      Chanartip.Soonthornwan@gmail.com
 * Rev. No.:   Version 1.0
 * Rev. Date:  Current Rev. Date 9/29/2017
 *
 * Purpose:    A register to hold 64-bit result from Multiplication,
 *             or Division operation from ALU.
 *         
 * Notes:      This register operates on the active edge of the clock
 *             signal input (clk). If the load enable (hilo_ld) is HIGH,
 *             the register will hold the new data input instead.
 *
 ****************************************************************************/
module reg_hilo(clk, reset, hilo_ld, d_hi, d_lo, q_hi, q_lo);
   input          clk, reset;          // on-board clock, and reset signal
   input             hilo_ld;          // load enable
   input   [31:0] d_hi, d_lo;          // data inputs
   output  [31:0] q_hi, q_lo;          // data outputs
   
   reg     [31:0] y_hi, y_lo;          // registers
   
   always @ (posedge clk, posedge reset)
      if(reset)   {y_hi, y_lo} <= {32'b0, 32'b0}; else   // reset
      if(hilo_ld) {y_hi, y_lo} <= { d_hi,  d_lo};        // assign new value
      else        {y_hi, y_lo} <= { y_hi,  y_lo};        // keep previous value
       
   assign {q_hi, q_lo} = {y_hi, y_lo}; // output the holded values

endmodule
