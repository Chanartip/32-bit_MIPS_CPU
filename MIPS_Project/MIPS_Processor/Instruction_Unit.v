`timescale 1ns / 1ps
/****************************** C E C S  4 4 0 ******************************
 * 
 * File Name:  Instruction_Unit.v
 * Project:    Final Project
 * Designer:   Chanartip Soonthornwan, Jonathan Shihata
 * Email:      Chanartip.Soonthornwan@gmail.com, JonnyShihata@gmail.com
 * Rev. No.:   Version 1.0
 * Rev. Date:  Date 10/10/2017
 *
 * Rev. No.1:  Version 1.1
 * Rev. Date:  Date 10/24/2017
 * update:     Get rid of [31:0] D_in, and Add pc_sel for PC_MUX
 *
 * Rev. No.2:  Version 1.2
 * Rev. Date:  Current Rev. Date 11/19/2017
 * update:     Adjusts Instruction Memory address pin to only
 *             get 12 bits from PC_out since the project's memory is small
 *             and there is no need for using more than 12 bits.
 *
 * Purpose:    Instruction Unit(CPU_IU) is a memory holding instructions
 *             could be accessed by an address from the Program Counter(PC),
 *             then sending the called instruction through data output(D_OUT).        
 *
 ****************************************************************************/
module Instruction_Unit(
   input               clk, reset,     // On-board clock and reset signal
   input     pc_ld, pc_inc, ir_ld,     // PC and IR load, and PC increment
   input     im_cs,  im_wr, im_rd,     // Instruction Memory (im)
                                       //    Chip Select, Write, and Read
   input     [1:0]         pc_sel,     // pc select for PC_MUX                                    
   input    [31:0]          PC_in,     // PC Input
   output   [31:0]         PC_out,     // PC Output
   output   [31:0]  IR_out, SE_16      // Instruction Output
                                       //    and Sign-Extension output
   );
   
   wire     [31:0]         IM_out;     // Instruction Memory Output
   wire     [31:0]         pc_mux;     // PC_MUX for pc_in
   
   // PC_MUX 
   //    if pc_sel = 0, select PC_in (pc+4)
   //       pc_sel = 1, select Jump instruction PC <- {pc[31:28], 26bit-imme, 00}
   //       pc_sel = 2, select Branch instruction PC <- PC + {sign_ext(ir[15:0]),00}
	assign pc_mux = (pc_sel == 2'b01) ? {PC_out[31:28],IR_out[25:0],2'b00} :// Jump
                   (pc_sel == 2'b10) ? {PC_out + {SE_16[29:0],2'b00}}     :// Branch
                                       PC_in;                              // PC+4
                                       
   // Program Counter(PC)
   pc PC (.clk(clk),                   // On-board clock
          .reset(reset),               // Reset
          .pc_ld(pc_ld),               // Load
          .pc_inc(pc_inc),             // Increment
          .pc_in(pc_mux),              // Input
          .pc_out(PC_out)              // Output
          );
   
   // Instrcution Memory
   Memory IM (.clk(clk),               // On-board clock
              .cs(im_cs),              // Chip-select
              .wr(im_wr),              // Write Enable
              .rd(im_rd),              // Read Enable
              .Addr({20'b0,PC_out[11:0]}),// Address from PC
              .D_In(32'b0),            // Deasserted
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
