`timescale 1ns / 1ps
/****************************** C E C S  4 4 0 ******************************
 * 
 * File Name:  Instruction_Unit.v
 * Project:    Lab_Assignment_5
 * Designer:   Chanartip Soonthornwan, Jonathan Shihata
 * Email:      Chanartip.Soonthornwan@gmail.com, JonnyShihata@gmail.com
 * Rev. No.:   Version 1.0
 * Rev. Date:  Current Rev. Date 10/10/2017
 *
 * Purpose:    Instruction Unit(CPU_IU) is a memory holding instructions
 *             could be accessed by an address from the Program Counter(PC),
 *             then sending the called instruction through data output(D_OUT).
 *         
 * Notes:      * For this lab im_wr is deasserted(hardwired 1'b0)
 *             ** For this lab D_in for IM is unused(hardwired 32'h0)
 *
 ****************************************************************************/
module Instruction_Unit(
   input               clk, reset,     // On-board clock and reset signal
   input     pc_ld, pc_inc, ir_ld,     // PC and IR load, and PC increment
   input     im_cs,  im_wr, im_rd,     // Instruction Memory (im)
                                       //    Chip Select, Write, and Read
   input    [31:0]    D_in, PC_in,     // Data Input, PC Input
   output   [31:0]         PC_out,     // PC Output
   output   [31:0]  IR_out, SE_16      // Instruction Output
                                       //    and Sign-Extension output
   );

   wire     [31:0]         IM_out;     // Instruction Memory Output
   
   // Program Counter(PC)
   pc PC (.clk(clk),                   // On-board clock
          .reset(reset),               // Reset
          .pc_ld(pc_ld),               // Load
          .pc_inc(pc_inc),             // Increment
          .pc_in(PC_in),               // Input
          .pc_out(PC_out)              // Output
          );
   
   // Instrcution Memory
   Memory IM (.clk(clk),               // On-board clock
              .cs(im_cs),              // Chip-select
              .wr(im_wr),              // Write Enable (*)
              .rd(im_rd),              // Read Enable
              .Addr(PC_out),           // Address from PC
              .D_In(D_in),             // Data input (**)
              .D_Out(IM_out)           // Instruction output
              );
   
   // Instruction Register
   //
   reg32_w_ld IR (.clk(clk),           // On-board clock
                  .reset(reset),       // Reset
                  .load(ir_ld),        // Load
                  .d(IM_out),          // Data input
                  .q(IR_out)           // Data output
                  );
   
   // Sign Extend 16 bits
   //    Takes 15th bit of IR_out, creates 16-bit of the 15th bit,
   //    then concatenates with lower bits of IR_out
   assign SE_16 = { {16{IR_out[15]}}, IR_out[15:0]};

endmodule
