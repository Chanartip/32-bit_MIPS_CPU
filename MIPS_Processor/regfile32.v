`timescale 1ns / 1ps
/* ***************************** C E C S  4 4 0 *******************************
 * 
 * File Name:  regfile32.v
 * Project:    Lab_Assignment_2
 * Designer:   Chanartip Soonthornwan, Jonathan Shihata
 * Email:      Chanartip.Soonthornwan@gmail.com, JonnyShihata@gmail.com
 * Rev. No.:   Version 1.0
 * Rev. Date:  Current Rev. Date 9/14/2017
 *
 * Purpose:    Represents an array of register that has 32x32 Width
 *             (32 registers) and Depth(32 bits each). Being able to save 
 *             32-bit input(D_in) and any register(specified by D_Addr) when 
 *             Data Write Enable(D_En) is HIGH. Also being able to output 
 *             two 32-bit data through S and T paths where S and T will 
 *             get the data from S_Addr and T_Addrrespectively.
 *             
 * Notes:      (*)At Write Section, if Data Write Enable(D_En) is HIGH, 
 *             it will write the input data into the register at D_Addr, 
 *             but it will notwrite on $r0 because Address $zero is restrict 
 *             for READ-ONLY.Therefore, when D_En is HIGH and D_Addr is 
 *             at $r0, the program will fall into Not changing content.
 *
 * ***************************************************************************/
module regfile32(clk, reset, D_En, D_Addr, S_Addr, T_Addr, D_in, S, T);

   input             clk, reset;          // Clock and Reset Signal
   input                   D_En;          // Data Write Enable
   input  [ 4:0]         D_Addr;          // Address of register to write
   input  [ 4:0] S_Addr, T_Addr;          // Address of register to read
   input  [31:0]           D_in;          // 32-bit input data
   
   output [31:0]           S, T;          // 32-bit read data
   reg    [31:0]  reg_array [31:0];       // 32 of 32-bit registers

   // Write Section
   always@(posedge clk, posedge reset) begin
      if(reset)                           // Get reset signal
         reg_array[0] <= 32'h0;           //    assign $r0 to zeroes
      else if(D_En && D_Addr != 5'h0)     // Load Input data 
         reg_array[D_Addr] <= D_in;       //    to a register that is not $r0
      else                                // Not changing content
         reg_array[D_Addr] <= reg_array[D_Addr]; // (*)
   end
   
   // Read Section
   //    S and T read get 32-bit data from registers 
   //    at S_Addr and T_addr respectively
   assign   S = reg_array[S_Addr];            
   assign   T = reg_array[T_Addr];
   
endmodule
