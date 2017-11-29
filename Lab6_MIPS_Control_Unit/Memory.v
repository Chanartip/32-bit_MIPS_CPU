`timescale 1ns / 1ps
/****************************** C E C S  4 4 0 ******************************
 * 
 * File Name:  Memory.v
 * Project:    Lab_Assignment_5
 * Designer:   Chanartip Soonthornwan, Jonathan Shihata
 * Email:      Chanartip.Soonthornwan@gmail.com, JonnyShihata@gmail.com
 * Rev. No.:   Version 1.0
 * Rev. Date:  Current Rev. Date 10/11/2017
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
module Memory(clk, cs, wr, rd, Addr, D_In, D_Out);

   input                  clk;  // clock signal
   input           cs, wr, rd;  // Data memory "ChipSelect", "Write", "Read"
   input  [31:0]         Addr;  // Address to the memory
   input  [31:0]         D_In;  // Data input
   output [31:0]        D_Out;  // Data output

   reg    [7:0]  Mem [0:4095];  // 4Kx8 array of registers 
   
   // Read data from Memory
   //    Addr is the ALU_out which contained 
   //    register in-direct address.
   //       for instance, Addr <- ALU_out_r(0x0000_000F) // register 15
   //       Addr is located at register 15 in this memory
   //       and then read the value of base(reg15) 
   //       which are 0x03C to 0x03F [4 addresses at the time.]
   //    If the memory is not being read, D_Out will output HighImpedance(z).
   assign D_Out = (cs & rd & !wr)? {Mem[Addr+0],
                                    Mem[Addr+1],
                                    Mem[Addr+2],
                                    Mem[Addr+3]} : 32'bz; 
 
   // Write data on Memory
   //    Writing data on memory is synchronous with the clock(clk)
   //    and only if Chip Select(cs) and Write Enable(wr) are HIGH.
   //    Otherwise, the memory cannot be written.
   always@(posedge clk)
      if(cs & wr & !rd)                // Write Data Input into the Memory
         {Mem[Addr+0], 
          Mem[Addr+1], 
          Mem[Addr+2], 
          Mem[Addr+3]} = D_In;      
      else begin                       // Keep the same value
          Mem[Addr+0] = Mem[Addr+0];
          Mem[Addr+1] = Mem[Addr+1];
          Mem[Addr+2] = Mem[Addr+2];
          Mem[Addr+3] = Mem[Addr+3];
      end

endmodule
