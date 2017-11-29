`timescale 1ns / 1ps
/****************************** C E C S  4 4 0 ******************************
 * 
 * File Name:  pc.v
 * Project:    Lab_Assignment_5
 * Designer:   Chanartip Soonthornwan, Jonathan Shihata
 * Email:      Chanartip.Soonthornwan@gmail.com, JonnyShihata@gmail.com
 * Rev. No.:   Version 1.0
 * Rev. Date:  Current Rev. Date 10/10/2017
 *
 * Purpose:    Program Counter(PC) register holds an address of Instruction
 *             Memory(CPU_IU). As pc_ld is high, the address is loaded
 *             with data input(pc_in), and the address is increased by 4
 *             (or move to the next memory location) as pc_inc is high.
 *             Otherwise, there is no changed.
 *         
 * Notes:      If both pc_ld and pc_inc are high, there is no changed.
 *
 ****************************************************************************/
module pc(clk, reset, pc_ld, pc_inc, pc_in, pc_out);

   input          clk, reset;             // on-board clock and reset
   input       pc_ld, pc_inc;             // Load and Increment signals
   input      [31:0]   pc_in;             // Address in
   output reg [31:0]  pc_out;             // Address out

   always @ (posedge clk, posedge reset)
      if(reset) pc_out <= 32'b0;          // reset
      else                                // Update pc_out on active edge clk
         case({pc_ld, pc_inc})               
            2'b01: pc_out <= pc_out + 4;  // increment
            2'b10: pc_out <= pc_in;       // load
            default: pc_out <= pc_out;    // default
         endcase

endmodule
