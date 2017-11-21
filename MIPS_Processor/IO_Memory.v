`timescale 1ns / 1ps
/****************************** C E C S  4 4 0 ******************************
 * 
 * File Name:  IO_Memory.v
 * Project:    Final Project
 * Designer:   Chanartip Soonthornwan, Jonathan Shihata
 * Email:      Chanartip.Soonthornwan@gmail.com, JonnyShihata@gmail.com
 * Rev. No.:   Version 1.0
 * Rev. Date:  Current Rev. Date 10/7/2017
 *
 * Purpose:    a 4096x8 byte addressable memory in big endian format
 *             storing data and instructions that could be accessed
 *             by addressing Address(Addr) as a base of the location
 *             of the memory and the add 1,2,3 for the rest of the base
 *             (see details at Read section).
 *         
 * Notes:      For the purposes of this lab Addr will be used only
 *             12 bits out of 32 bits.
 *
 ****************************************************************************/
module IO_Memory(clk, cs, wr, rd, int_r, int_ack, Addr, IO_In, IO_Out);

   input             clk;       // clock signal
   input      cs, wr, rd;       // "ChipSelect", "Write", "Read"
   input         int_ack;       // interrupt acknowledge output
   output  reg     int_r;       // interrupt request input 
   input  [31:0]    Addr;       // Address to the memory
   input  [31:0]   IO_In;       // Data input
   output [31:0]  IO_Out;       // Data output

   reg    [7:0]  Mem [0:4095];  // 4Kx8 array of registers 
   
   // Send interrupt request to CPU
   //    after 2000/10 ns = 200 clock cycles
   //    Even though interrupt request is set,
   //    if instruction SETIE is not called, 
   //    CPU will not be interrupted.
   initial begin
      #2000 int_r=1;
      @(posedge int_ack) int_r=0;
   end
   
   // Read data from Memory
   //    Addr is the ALU_out which contained 
   //    register in-direct address.
   //       for instance, Addr <- ALU_out_r(0x0000_000F) // register 15
   //       Addr is located at register 15 in this memory
   //       and then read the value of base(reg15) 
   //       which are 0x03C to 0x03F [4 addresses at the time.]
   //    If the memory is not being read, D_Out will output HighImpedance(z).
   assign IO_Out = (cs & rd & !wr)? {Mem[Addr+0],
                                     Mem[Addr+1],
                                     Mem[Addr+2],
                                     Mem[Addr+3]} : 32'hz; 
   
   // Write data on Memory
   //    Writing data on memory is synchronous with the clock(clk)
   //    and only if Chip Select(cs) and Write Enable(wr) are HIGH.
   //    Otherwise, the memory cannot be written.
   always@(posedge clk)
      if(cs & wr & !rd)                // Write Data Input into the Memory
         {Mem[Addr+0], 
          Mem[Addr+1], 
          Mem[Addr+2], 
          Mem[Addr+3]} <= IO_In;      
      else begin                       // Keep the same value
          Mem[Addr+0] <= Mem[Addr+0];
          Mem[Addr+1] <= Mem[Addr+1];
          Mem[Addr+2] <= Mem[Addr+2];
          Mem[Addr+3] <= Mem[Addr+3];
      end

endmodule
