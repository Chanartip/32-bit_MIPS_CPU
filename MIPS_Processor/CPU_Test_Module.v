`timescale 1ns / 1ps
/****************************** C E C S  4 4 0 ******************************
 * 
 * File Name:  CPU_Test_Module.v
 * Project:    Final_Project
 * Designer:   Chanartip Soonthornwan, Jonathan Shihata
 * Email:      Chanartip.Soonthornwan@gmail.com, JonnyShihata@gmail.com
 * Rev. No.:   Version 1.0
 * Rev. Date:  Current Rev. Date 11/17/2017
 *
 * Purpose:    Top level of CPU, Data Memory, and IO Memory.
 *             Performing as a test fixture of CPU and utilizing instruction
 *             memory and data memory from dat files.
 *         
 ****************************************************************************/

module CPU_Test_Module;

	// Inputs
	reg sys_clk;
	reg sys_rst;
   
   // Interconnection wires
	wire [31:0] MAddr;          // Memory Address from CPU
	wire [31:0] idp_out;        // Data output from IDP in CPU
   wire [31:0] Mem_out, Mem_in;// DM and IO Memory bus
   
   // Wires for Data Memory
	wire dm_cs, dm_rd, dm_wr;   // chip select, write enable, read enable
   wire [31:0] DM_out;         // Data Memory output
   
   // Wires for IO Memory
   wire  io_intr;              // IO interrupt request input
   wire io_int_ack;            // IO interrupt acknowledge output
   wire io_cs, io_wr, io_rd;   // chip select, write enable, read enable
   //wire [31:0] IO_out, IO_in; // IO Memory output
   
	// Instantiate CPU
	CPU cpu (
		.sys_clk(sys_clk), 
		.reset(sys_rst), 
		.intr(io_intr),         // interrupt input from IO memory
		.int_ack(io_int_ack),   // interrupt ourput to IO memory
		.DM_out(DM_out),        // Data input from both memories
		.MAddr(MAddr),          // Memory address to access both memories
		.idp_out(idp_out),      // Data output to both memories
		.dm_cs(dm_cs),          // Data memory
		.dm_rd(dm_rd),          //    control
		.dm_wr(dm_wr),          //       words
      .io_cs(io_cs),          // IO memory
		.io_rd(io_rd),          //    control
		.io_wr(io_wr)           //       words
	);
   
   // Instantiate Data Memory
   Data_Memory DM(
      .clk(sys_clk), 
      .dm_cs(dm_cs), 
      .dm_wr(dm_wr), 
      .dm_rd(dm_rd), 
      .Addr({20'h0,MAddr[11:0]}), 
      .DM_In(idp_out), 
      .DM_Out(DM_out)
   );
   
   // Instancitate IO Memory
   /* Will Change this one later*/
   IO_Memory IO(
      .clk(sys_clk), 
      .cs(io_cs), 
      .wr(io_wr), 
      .rd(io_rd), 
      .int_r(io_intr), 
      .int_ack(io_int_ack),
      .Addr({20'h0,MAddr[11:0]}), 
      .IO_In(idp_out), 
      .IO_Out(DM_out)
   );

 // Generate 10ns clock period
	always #5 sys_clk = ~sys_clk;
	 
   // Initialization
	initial begin
		$timeformat(-9, 1, " ns", 9);
		sys_clk = 0;
      sys_rst = 1;
      
      // Bring system to 'known state'
		@(negedge sys_clk)
		sys_rst = 0;
		
      //*******************************//
		// Initialize Instruction Memory //
		//*******************************//
		@(negedge sys_clk)
      /* For iMem01 - 12 Verification */
		//$readmemh("iMem06_Sp17_commented.dat",cpu.iu.IM.Mem);    
      
      /* For iMem13 - 14 Verification */
		$readmemh("iMem13_Sp17_w_isr_commented.dat",cpu.iu.IM.Mem);
      
		//************************//
		// Initialize Data Memory //
		//************************//
		@(negedge sys_clk)
		$readmemh("dMem13_Sp17.dat",DM.Mem);

	end 
      
endmodule

