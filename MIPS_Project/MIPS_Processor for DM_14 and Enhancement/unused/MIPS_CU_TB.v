`timescale 1ns / 1ps
/****************************** C E C S  4 4 0 ******************************
 * 
 * File Name:  MIPS_CU_TB.v
 * Project:    Lab_Assignment_6
 * Designer:   Chanartip Soonthornwan, Jonathan Shihata
 * Email:      Chanartip.Soonthornwan@gmail.com, JonnyShihata@gmail.com
 * Rev. No.:   Version 1.0
 * Rev. Date:  Current Rev. Date 10/24/2017
 *
 * Purpose:    This is the testbench file to verify operation of the mips 
 * 				Control unit.
 *         
 * Notes:      
 *
 ****************************************************************************/
module MIPS_CU_TB;

	// Inputs
	reg         sys_clk, reset, intr;
	wire         c,n,z,v;
	reg  [31:0] IR;

	// Outputs
   wire        int_ack;
   //   For Instruction Unit
   wire        pc_ld,  pc_inc, ir_ld;     // Program Counter Register
	wire        im_cs,  im_rd,  im_wr;     // Instruction Memory
	//
   //    For Data Memory
	wire        dm_cs,  dm_rd,  dm_wr;     // Data Memory
   //
   //    For Integer Data Path (IDP)
   wire 		   D_En,   T_Sel,  HILO_ld;   // Register File
	wire  [1:0] pc_sel, DA_sel;            // T-MUX and DA_MUX for T or D_Addr
	wire  [2:0] Y_Sel;                     // ALU_Out select
	wire  [4:0] FS; 			               // Function select
	
	
	wire [31:0] IR_out, pc_out, se_16, MAddr, DM_out, idp_out;
	
//	//*****************//
//	// Instantiate MCU //
//	//*****************//
//	MCU mcu ( 
//            // Inputs
//            .sys_clk(sys_clk), .reset(reset),   .intr(intr), 
//				.c(c), .n(n), .z(z), .v(v), 						   
//				.IR(IR_out), 											   
//				
//            // Outputs
//            .int_ack(int_ack), 									
//            
//               // For Instruction Unit
//				.pc_sel(pc_sel),   .pc_ld(pc_ld),   .pc_inc(pc_inc), .ir_ld(ir_ld), 		
//				.im_cs(im_cs),     .im_rd(im_rd),   .im_wr(im_wr),
//            
//               // For Integer Data Path (IDP)
//				.D_En(D_En),       .DA_sel(DA_sel), .T_Sel(T_Sel),   
//            .HILO_ld(HILO_ld), .Y_Sel(Y_Sel),   .FS(FS),
//            
//               //For Data Memory
//				.dm_cs(dm_cs),     .dm_rd(dm_rd),   .dm_wr(dm_wr)
//   );			 
//             
//   //******************//
//	// Instruction Unit //
//	//******************//
//	Instruction_Unit iu(
//            // Scalar
//            .clk(sys_clk),   .reset(reset),  
//            .pc_sel(pc_sel), .pc_ld(pc_ld), .pc_inc(pc_inc), .ir_ld(ir_ld), 
//            .im_cs(im_cs),   .im_wr(im_wr), .im_rd(im_rd),
//            // 32-bit                                                 
//            .PC_in(MAddr),   .PC_out(pc_out),     
//            .IR_out(IR_out), .SE_16(se_16)     
//   );
//
//   //******************//
//	// Integer Datapath //
//	//******************//
//	IDP idp(  // Inputs
//            .clk(sys_clk), 
//            .reset(reset), 
//            .D_En(D_En),         
//            .DA_Sel(DA_sel),              // DA_Sel         
//            .D_Addr(IR_out[15:11]),       // $rd from IR_out
//            .S_Addr(IR_out[25:21]),       // $rs from IR_out  
//            .T_Addr(IR_out[20:16]),       // $rt from IR_out  
//            .DT(se_16),
//            .T_Sel(T_Sel),    
//            .FS(FS),                      // Address from IR_out 
//            .shamt(IR_out[10:6]),         // Shifting amount from IR_out
//            .HILO_ld(HILO_ld),   
//            .DY(DM_out),                  // Input from Data Memory output
//            .pc_in(pc_out),               // Input from Instruction Unit PC_out
//            .Y_Sel(Y_Sel),     
//            
//            // Outputs
//            .C(c), 
//            .V(v), 
//            .N(n), 
//            .Z(z), 
//            .ALU_OUT(MAddr), 
//            .D_OUT(idp_out)
//   );
//   
//   //*************//
//	// Data Memory //
//	//*************//               
//	Data_Memory dMem (
//   
//      // Inputs
//      .clk(sys_clk),
//      .dm_cs(dm_cs), 
//      .dm_wr(dm_wr), 
//      .dm_rd(dm_rd), 
//      .Addr({20'h0,MAddr[11:0]}),  
//      .DM_In(idp_out),
//       
//      // Output
//      .DM_Out(DM_out)
//     );  

   // Generate 10ns clock period
	always #1 sys_clk = ~sys_clk;
	
   // Initialization
	initial begin
		$timeformat(-9, 1, " ns", 9);
		sys_clk = 0;
      reset = 1;
      intr = 0;
      
		@(negedge sys_clk)
		reset = 0;
		
      //*******************************//
		// Initialize Instruction Memory //
		//*******************************//
		@(negedge sys_clk)
		$readmemh("iMem_Lab6_with_isr.dat",iu.IM.Mem);
      
		//************************//
		// Initialize Data Memory //
		//************************//
		@(negedge sys_clk)
		$readmemh("dMem_Lab6.dat",dMem.Mem);
      
      //__________Test Interrupt Section___________
      // After running the MCU for 100 ns,
      //    Sending Interrupt signal
      //    And reset the interrupt a moment later
      // The result of memory in regfile should
      //    Patially appear since it got interrupt.
		#100 intr = 1;
      #10  intr = 0; // If there is an interrupt, this will resume the work
       
	end
	
endmodule

