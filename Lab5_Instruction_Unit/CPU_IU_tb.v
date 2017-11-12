`timescale 1ns / 1ps
/****************************** C E C S  4 4 0 ******************************
 * 
 * File Name:  CPU_IU_tb.v
 * Project:    Lab_Assignment_5
 * Designer:   Chanartip Soonthornwan, Jonathan Shihata
 * Email:      Chanartip.Soonthornwan@gmail.com, JonnyShihata@gmail.com
 * Rev. No.:   Version 1.0
 * Rev. Date:  Current Rev. Date 10/11/2017
 *
 * Purpose:    A top level of Instruction Unit, Integer Datapath(IDP) and 
 *             Data Memory(DM). Instanciates both modules, interconnection 
 *             with 32-bit busses, and providing all necessary 
 *             control signal inputs.
 *
 ****************************************************************************/
module CPU_IU_tb;

	reg               clk, reset;    // On-board clock and reset signal
   
   // Instruction Unit Port list
   reg     pc_ld, pc_inc, ir_ld;    // PC and IR load, and PC increment
   reg     im_cs,  im_wr, im_rd;    // Instruction Memory (im)
                                    //    Chip Select, Write, and Read
   reg    [31:0]    D_in, PC_in;    // Data Input, PC Input
   wire   [31:0]         PC_out;    // PC Output
   wire   [31:0]  IR_out, SE_16;    // Instruction Output
                                    //    and Sign-Extension output
   
   // Data Memory Port list
   reg      dm_cs, dm_wr, dm_rd;    // "ChipSelect", "Write", "Read"
   reg    [31:0]           Addr;    // Address to the memory
   reg    [31:0]          DM_In;    // Data input
   wire   [31:0]         DM_Out;    // Data output

   // Integer Data Path Port list
   reg             D_En,HILO_ld;    // Load enable for regfiles
   reg                   DA_Sel;    // DA-MUX select
   reg                    T_Sel;    // T-MUX select
   reg    [2:0]           Y_Sel;    // Y-MUX select
   reg    [4:0]              FS;    // ALU function select
   reg    [4:0]          D_Addr;    // regfile Write address
   reg    [4:0]  S_Addr, T_Addr;    // regfile Source addresses
   reg    [31:0]     DT,     DY;    // Data inputs
   reg    [31:0]          pc_in;    // Program Counter input
   wire                C, V,N,Z;    // Status flags from ALU
   wire   [31:0] ALU_OUT, D_OUT;    // Outputs
   
	// Declare variables
	integer i, X;

	// Instruction Units
	Instruction_Unit uut0 (
		.clk(clk), 
		.reset(reset), 
		.pc_ld(pc_ld), 
		.pc_inc(pc_inc), 
		.ir_ld(ir_ld), 
		.im_cs(im_cs),  
		.im_wr(im_wr),                
		.im_rd(im_rd),                
		.D_in(32'h0),                 // ZERO
		.PC_in(ALU_OUT), 
		.PC_out(PC_out), 
		.IR_out(IR_out),              // Instruction Output
		.SE_16(SE_16)                 // Sign Extension
	);
   
   // Integer Data Path
   IDP uut1(
      .clk(clk), 
		.reset(reset), 
		.D_En(D_En),                  
		.D_Addr(IR_out[15:11]),       // Address from IR_out
		.S_Addr(IR_out[25:21]),       // Address from IR_out  
		.T_Addr(IR_out[20:16]),       // Address from IR_out  
		.DT(SE_16),
      .DA_Sel(DA_Sel),              // DA_Sel
		.T_Sel(T_Sel),    
		.FS(IR_out[31:27]),           // Address from IR_out      
		.C(C), 
		.V(V), 
		.N(N), 
		.Z(Z), 
		.HILO_ld(HILO_ld),   
		.DY(DM_Out),                  // Input from Data Memory output
		.pc_in(PC_out),               // Input from Instruction Unit PC_out
		.Y_Sel(Y_Sel),     
		.ALU_OUT(ALU_OUT), 
		.D_OUT(D_OUT)
   );
   
   // Data Memory
   Data_Memory uut2 (
      .clk(clk), 
      .dm_cs(dm_cs), 
      .dm_wr(dm_wr), 
      .dm_rd(dm_rd), 
      .Addr({20'h0, ALU_OUT[11:0]}),   // Only use 12 bit of ALU_OUT
      .DM_In(D_OUT),                   // Get D_OUT from IDP
      .DM_Out(DM_Out)                  // Send Data_out to IDP's DY
   );
   
   // Generated clock
   always #5 clk = ~clk;
   
	initial begin
      $timeformat(-9, 1, " ns", 9);
		clk = 0;
		reset = 1;
      
		@(negedge clk)
         reset = 0;
		 
		//****************************************************
		// Initialize Integer Register File
		//****************************************************
		@(negedge clk)
         $readmemh("IntReg_Lab5.dat",uut1.idp0.D_out);

		//****************************************************
		// Initialize Data Memory
		//****************************************************
		@(negedge clk)
         $readmemh("dMem_Lab5.dat",uut2.Mem);
		
		//****************************************************
		// Initialize Instruction Memory
		//****************************************************
		@(negedge clk)
         $readmemb("iMem_Lab5.dat",uut0.IM.Mem);
		
		//****************************************************
		//Initial Integer Register File Dump
		//****************************************************
         $display(" ");
         $display("Initial Contents of Integer Register File");
         $display(" ");
         Reg_Dump;
		
		//****************************************************
		//Update Contents of Integer Register File and Memory
		//****************************************************
		 
		// a. $r1 <- $r3 | $r4 (logical OR)
		//************************************************************
		@(negedge clk)				// uop1: IR <- iM[PC], PC <- PC + 4
		// Instruction Unit Control
		   {pc_ld, pc_inc, ir_ld, im_cs, im_rd, im_wr} = 6'b0_1_1_1_1_0;
		// Datapath Control
		   {D_En, DA_Sel, T_Sel, HILO_ld, Y_Sel} = 7'b0_0_0_0_000;
		// Data Memory Control
		   {dm_cs, dm_rd, dm_wr} = 3'b0_0_0;
		@(negedge clk)				// uop2: RS <- $r3(r3), RT <- $r4(r4)
		   {pc_ld, pc_inc, ir_ld, im_cs, im_rd, im_wr} = 6'b0_0_0_0_0_0;
		   {D_En, DA_Sel, T_Sel, HILO_ld, Y_Sel} = 7'b0_0_0_0_000;
		   {dm_cs, dm_rd, dm_wr} = 3'b0_0_0;
		@(negedge clk)				// uop3: ALU_OUT <- RS(r3) | RT(r4)
		   {pc_ld, pc_inc, ir_ld, im_cs, im_rd, im_wr} = 6'b0_0_0_0_0_0;
		   {D_En, DA_Sel, T_Sel, HILO_ld, Y_Sel} = 7'b0_0_0_0_000;
		   {dm_cs, dm_rd, dm_wr} = 3'b0_0_0;
		@(negedge clk)				// uop4: $r1 <- ALU_OUT(r3 | r4)
		   {pc_ld, pc_inc, ir_ld, im_cs, im_rd, im_wr} = 6'b0_0_0_0_0_0;
		   {D_En, DA_Sel, T_Sel, HILO_ld, Y_Sel} = 7'b1_1_0_0_000;
		   {dm_cs, dm_rd, dm_wr} = 3'b0_0_0;
		
		// b. $r2 <- $r1 - $r14 (signed subtraction)
		//************************************************************
		@(negedge clk)				// uop1: IR <- iM[PC], PC <- PC + 4
		   {pc_ld, pc_inc, ir_ld, im_cs, im_rd, im_wr} = 6'b0_1_1_1_1_0;
		   {D_En, DA_Sel, T_Sel, HILO_ld, Y_Sel} = 7'b0_0_0_0_000;
		   {dm_cs, dm_rd, dm_wr} = 3'b0_0_0;
		@(negedge clk)				// uop2: RS <- $r1(r1), RT <- $r14(r14)
		   {pc_ld, pc_inc, ir_ld, im_cs, im_rd, im_wr} = 6'b0_0_0_0_0_0;
		   {D_En, DA_Sel, T_Sel, HILO_ld, Y_Sel} = 7'b0_0_0_0_000;
		   {dm_cs, dm_rd, dm_wr} = 3'b0_0_0;
		@(negedge clk)				// uop3: ALU_OUT <- RS(r1) - RT(r14)
		   {pc_ld, pc_inc, ir_ld, im_cs, im_rd, im_wr} = 6'b0_0_0_0_0_0;
		   {D_En, DA_Sel, T_Sel, HILO_ld, Y_Sel} = 7'b0_0_0_0_000;
		   {dm_cs, dm_rd, dm_wr} = 3'b0_0_0;
		@(negedge clk)				// uop4: $r2 <- ALU_OUT(r1 - r14)
		   {pc_ld, pc_inc, ir_ld, im_cs, im_rd, im_wr} = 6'b0_0_0_0_0_0;
		   {D_En, DA_Sel, T_Sel, HILO_ld, Y_Sel} = 7'b1_1_0_0_000;
		   {dm_cs, dm_rd, dm_wr} = 3'b0_0_0;
		
		// c. $r3 <- shr $r4 (logical shift right)
		//************************************************************
		@(negedge clk)				// uop1: IR <- iM[PC], PC <- PC + 4
		   {pc_ld, pc_inc, ir_ld, im_cs, im_rd, im_wr} = 6'b0_1_1_1_1_0;
		   {D_En, DA_Sel, T_Sel, HILO_ld, Y_Sel} = 7'b0_0_0_0_000;
		   {dm_cs, dm_rd, dm_wr} = 3'b0_0_0;
		@(negedge clk)				// uop2: RT <- $r4(r4)
		   {pc_ld, pc_inc, ir_ld, im_cs, im_rd, im_wr} = 6'b0_0_0_0_0_0;
		   {D_En, DA_Sel, T_Sel, HILO_ld, Y_Sel} = 7'b0_0_0_0_000;
		   {dm_cs, dm_rd, dm_wr} = 3'b0_0_0;
		@(negedge clk)				// uop3: ALU_OUT <- RT(shr r4)
		   {pc_ld, pc_inc, ir_ld, im_cs, im_rd, im_wr} = 6'b0_0_0_0_0_0;
		   {D_En, DA_Sel, T_Sel, HILO_ld, Y_Sel} = 7'b0_0_0_0_000;
		   {dm_cs, dm_rd, dm_wr} = 3'b0_0_0;
		@(negedge clk)				// uop4: $r3 <- ALU_OUT(shr r4)
		   {pc_ld, pc_inc, ir_ld, im_cs, im_rd, im_wr} = 6'b0_0_0_0_0_0;
		   {D_En, DA_Sel, T_Sel, HILO_ld, Y_Sel} = 7'b1_1_0_0_000;
		   {dm_cs, dm_rd, dm_wr} = 3'b0_0_0;
		
		// d. $r4 <- shl $r5 (logical shift left)
		//************************************************************
		@(negedge clk)				// uop1: IR <- iM[PC], PC <- PC + 4
		   {pc_ld, pc_inc, ir_ld, im_cs, im_rd, im_wr} = 6'b0_1_1_1_1_0;
		   {D_En, DA_Sel, T_Sel, HILO_ld, Y_Sel} = 7'b0_0_0_0_000;
		   {dm_cs, dm_rd, dm_wr} = 3'b0_0_0;
		@(negedge clk)				// uop2: RT <- $r5(r5)
		   {pc_ld, pc_inc, ir_ld, im_cs, im_rd, im_wr} = 6'b0_0_0_0_0_0;
		   {D_En, DA_Sel, T_Sel, HILO_ld, Y_Sel} = 7'b0_0_0_0_000;
		   {dm_cs, dm_rd, dm_wr} = 3'b0_0_0;
		@(negedge clk)				// uop3: ALU_OUT <- RT(shr r5)
		   {pc_ld, pc_inc, ir_ld, im_cs, im_rd, im_wr} = 6'b0_0_0_0_0_0;
		   {D_En, DA_Sel, T_Sel, HILO_ld, Y_Sel} = 7'b0_0_0_0_000;
		   {dm_cs, dm_rd, dm_wr} = 3'b0_0_0;
		@(negedge clk)				// uop4: $r4 <- ALU_OUT(shr r5)
		   {pc_ld, pc_inc, ir_ld, im_cs, im_rd, im_wr} = 6'b0_0_0_0_0_0;
		   {D_En, DA_Sel, T_Sel, HILO_ld, Y_Sel} = 7'b1_1_0_0_000;
		   {dm_cs, dm_rd, dm_wr} = 3'b0_0_0;
		
		// e. {$r6,$r5} <- $r15 / $r14 (division)
		//************************************************************
		@(negedge clk)				// uop1: IR <- iM[PC], PC <- PC + 4
		   {pc_ld, pc_inc, ir_ld, im_cs, im_rd, im_wr} = 6'b0_1_1_1_1_0;
		   {D_En, DA_Sel, T_Sel, HILO_ld, Y_Sel} = 7'b0_0_0_0_000;
		   {dm_cs, dm_rd, dm_wr} = 3'b0_0_0;
		@(negedge clk)				// uop2: RS <- $r15(r15), RT <- $r14(r14)
		   {pc_ld, pc_inc, ir_ld, im_cs, im_rd, im_wr} = 6'b0_0_0_0_0_0;
		   {D_En, DA_Sel, T_Sel, HILO_ld, Y_Sel} = 7'b0_0_0_0_000;
		   {dm_cs, dm_rd, dm_wr} = 3'b0_0_0;
		@(negedge clk)				// uop3: {HI,LO} <- RS(r15) / RT(r14)
		   {pc_ld, pc_inc, ir_ld, im_cs, im_rd, im_wr} = 6'b0_0_0_0_0_0;
		   {D_En, DA_Sel, T_Sel, HILO_ld, Y_Sel} = 7'b0_0_0_1_000;
		   {dm_cs, dm_rd, dm_wr} = 3'b0_0_0;
		@(negedge clk)				// uop4: IR <- iM[PC], PC <- PC + 4 //gets $rd for $r6
		   {pc_ld, pc_inc, ir_ld, im_cs, im_rd, im_wr} = 6'b0_1_1_1_1_0;
		   {D_En, DA_Sel, T_Sel, HILO_ld, Y_Sel} = 7'b0_0_0_0_000;
		   {dm_cs, dm_rd, dm_wr} = 3'b0_0_0;
		@(negedge clk)				// uop5: $r6 <- HI(r15 % r14)
		   {pc_ld, pc_inc, ir_ld, im_cs, im_rd, im_wr} = 6'b0_0_0_0_0_0;
		   {D_En, DA_Sel, T_Sel, HILO_ld, Y_Sel} = 7'b1_1_0_0_001;
		   {dm_cs, dm_rd, dm_wr} = 3'b0_0_0;
		@(negedge clk)				// uop6: IR <- iM[PC], PC <- PC + 4 //gets $rd for $r5
		   {pc_ld, pc_inc, ir_ld, im_cs, im_rd, im_wr} = 6'b0_1_1_1_1_0;
		   {D_En, DA_Sel, T_Sel, HILO_ld, Y_Sel} = 7'b0_0_0_0_000;
		   {dm_cs, dm_rd, dm_wr} = 3'b0_0_0;
		@(negedge clk)				// uop7: $r5 <- LO(r15 / r14)
		   {pc_ld, pc_inc, ir_ld, im_cs, im_rd, im_wr} = 6'b0_0_0_0_0_0;
		   {D_En, DA_Sel, T_Sel, HILO_ld, Y_Sel} = 7'b1_1_0_0_010;
		   {dm_cs, dm_rd, dm_wr} = 3'b0_0_0;
		
		// f. {$r8,$r7} <- $r11 * 0xFFFF_FFFB (multiply using DT)
		//************************************************************
		@(negedge clk)				// uop1: IR <- iM[PC], PC <- PC + 4
		   {pc_ld, pc_inc, ir_ld, im_cs, im_rd, im_wr} = 6'b0_1_1_1_1_0;
		   {D_En, DA_Sel, T_Sel, HILO_ld, Y_Sel} = 7'b0_0_0_0_000;
		   {dm_cs, dm_rd, dm_wr} = 3'b0_0_0;
		@(negedge clk)				// uop2: RS <- $r11(r11), RT <- DT(SE_16)
		   {pc_ld, pc_inc, ir_ld, im_cs, im_rd, im_wr} = 6'b0_0_0_0_0_0;
		   {D_En, DA_Sel, T_Sel, HILO_ld, Y_Sel} = 7'b0_0_1_0_000;
		   {dm_cs, dm_rd, dm_wr} = 3'b0_0_0;
		@(negedge clk)				// uop3: {HI,LO} <- RS(r11) * RT(0xFFFF_FFFB)
		   {pc_ld, pc_inc, ir_ld, im_cs, im_rd, im_wr} = 6'b0_0_0_0_0_0;
		   {D_En, DA_Sel, T_Sel, HILO_ld, Y_Sel} = 7'b0_0_0_1_000;
		   {dm_cs, dm_rd, dm_wr} = 3'b0_0_0;
		@(negedge clk)				// uop4: IR <- iM[PC], PC <- PC + 4 //gets $rd for $r8
		   {pc_ld, pc_inc, ir_ld, im_cs, im_rd, im_wr} = 6'b0_1_1_1_1_0;
		   {D_En, DA_Sel, T_Sel, HILO_ld, Y_Sel} = 7'b0_0_0_0_000;
		   {dm_cs, dm_rd, dm_wr} = 3'b0_0_0;
		@(negedge clk)				// uop5: $r8 <- HI
		   {pc_ld, pc_inc, ir_ld, im_cs, im_rd, im_wr} = 6'b0_0_0_0_0_0;
		   {D_En, DA_Sel, T_Sel, HILO_ld, Y_Sel} = 7'b1_1_0_0_001;
		   {dm_cs, dm_rd, dm_wr} = 3'b0_0_0;
		@(negedge clk)				// uop6: IR <- iM[PC], PC <- PC + 4 //gets $rd for $r7
		   {pc_ld, pc_inc, ir_ld, im_cs, im_rd, im_wr} = 6'b0_1_1_1_1_0;
		   {D_En, DA_Sel, T_Sel, HILO_ld, Y_Sel} = 7'b0_0_0_0_000;
		   {dm_cs, dm_rd, dm_wr} = 3'b0_0_0;
		@(negedge clk)				// uop7: $r7 <- LO
		   {pc_ld, pc_inc, ir_ld, im_cs, im_rd, im_wr} = 6'b0_0_0_0_0_0;
		   {D_En, DA_Sel, T_Sel, HILO_ld, Y_Sel} = 7'b1_1_0_0_010;
		   {dm_cs, dm_rd, dm_wr} = 3'b0_0_0;
		
		// g. $r12 <- M[$r15 + 0] //$r12 will be encoded in the $rt field, not $rd
		//************************************************************
		@(negedge clk)				// uop1: IR <- iM[PC], PC <- PC + 4
		   {pc_ld, pc_inc, ir_ld, im_cs, im_rd, im_wr} = 6'b0_1_1_1_1_0;
		   {D_En, DA_Sel, T_Sel, HILO_ld, Y_Sel} = 7'b0_0_0_0_000;
		   {dm_cs, dm_rd, dm_wr} = 3'b0_0_0;
		@(negedge clk)				// uop2: RS <- $r15(r15), RT <- DT(0x0000_0000)
		   {pc_ld, pc_inc, ir_ld, im_cs, im_rd, im_wr} = 6'b0_0_0_0_0_0;
		   {D_En, DA_Sel, T_Sel, HILO_ld, Y_Sel} = 7'b0_0_1_0_000;
		   {dm_cs, dm_rd, dm_wr} = 3'b0_0_0;
		@(negedge clk)				// uop3: ALU_OUT <- RS(r15) + RT(0x0000_0000)
		   {pc_ld, pc_inc, ir_ld, im_cs, im_rd, im_wr} = 6'b0_0_0_0_0_0;
		   {D_En, DA_Sel, T_Sel, HILO_ld, Y_Sel} = 7'b0_0_0_0_000;
		   {dm_cs, dm_rd, dm_wr} = 3'b0_0_0;
		@(negedge clk)				// uop4: D_in(ID register) <- M[ALU_OUT(r15 + 0)]
		   {pc_ld, pc_inc, ir_ld, im_cs, im_rd, im_wr} = 6'b0_0_0_0_0_0;
		   {D_En, DA_Sel, T_Sel, HILO_ld, Y_Sel} = 7'b0_0_0_0_000;
		   {dm_cs, dm_rd, dm_wr} = 3'b1_1_0;
		@(negedge clk)				// uop5: $r12 <- D_in(M[(r15 + 0)])
		   {pc_ld, pc_inc, ir_ld, im_cs, im_rd, im_wr} = 6'b0_0_0_0_0_0;
		   {D_En, DA_Sel, T_Sel, HILO_ld, Y_Sel} = 7'b1_0_0_0_011;
		   {dm_cs, dm_rd, dm_wr} = 3'b0_0_0;
      
		// h. $r11 <- $r0 nor $r11 (one's complement)
		//************************************************************
		@(negedge clk)				// uop1: IR <- iM[PC], PC <- PC + 4
		   {pc_ld, pc_inc, ir_ld, im_cs, im_rd, im_wr} = 6'b0_1_1_1_1_0;
		   {D_En, DA_Sel, T_Sel, HILO_ld, Y_Sel} = 7'b0_0_0_0_000;
		   {dm_cs, dm_rd, dm_wr} = 3'b0_0_0;
		@(negedge clk)				// uop2: RS <- $r0(r0), RT <- $r11(r11)
		   {pc_ld, pc_inc, ir_ld, im_cs, im_rd, im_wr} = 6'b0_0_0_0_0_0;
		   {D_En, DA_Sel, T_Sel, HILO_ld, Y_Sel} = 7'b0_0_0_0_000;
		   {dm_cs, dm_rd, dm_wr} = 3'b0_0_0;
		@(negedge clk)				// uop3: ALU_OUT <- RS(r0) nor RT(r11)
		   {pc_ld, pc_inc, ir_ld, im_cs, im_rd, im_wr} = 6'b0_0_0_0_0_0;
		   {D_En, DA_Sel, T_Sel, HILO_ld, Y_Sel} = 7'b0_0_0_0_000;
		   {dm_cs, dm_rd, dm_wr} = 3'b0_0_0;
		@(negedge clk)				// uop4: $r11 <- ALU_OUT(r0 nor r11)
		   {pc_ld, pc_inc, ir_ld, im_cs, im_rd, im_wr} = 6'b0_0_0_0_0_0;
		   {D_En, DA_Sel, T_Sel, HILO_ld, Y_Sel} = 7'b1_1_0_0_000;
		   {dm_cs, dm_rd, dm_wr} = 3'b0_0_0;
		
		// i. $r10 <- $r0 - $r10 (two's complement)
		//************************************************************
		@(negedge clk)				// uop1: IR <- iM[PC], PC <- PC + 4
		   {pc_ld, pc_inc, ir_ld, im_cs, im_rd, im_wr} = 6'b0_1_1_1_1_0;
		   {D_En, DA_Sel, T_Sel, HILO_ld, Y_Sel} = 7'b0_0_0_0_000;
		   {dm_cs, dm_rd, dm_wr} = 3'b0_0_0;
		@(negedge clk)				// uop2: RS <- $r0(r0), RT <- $r10(r10)
		   {pc_ld, pc_inc, ir_ld, im_cs, im_rd, im_wr} = 6'b0_0_0_0_0_0;
		   {D_En, DA_Sel, T_Sel, HILO_ld, Y_Sel} = 7'b0_0_0_0_000;
		   {dm_cs, dm_rd, dm_wr} = 3'b0_0_0;
		@(negedge clk)				// uop3: ALU_OUT <- RS(r0) - RT(r10)
		   {pc_ld, pc_inc, ir_ld, im_cs, im_rd, im_wr} = 6'b0_0_0_0_0_0;
		   {D_En, DA_Sel, T_Sel, HILO_ld, Y_Sel} = 7'b0_0_0_0_000;
		   {dm_cs, dm_rd, dm_wr} = 3'b0_0_0;
		@(negedge clk)				// uop4: $r10 <- ALU_OUT(r0 - r10)
		   {pc_ld, pc_inc, ir_ld, im_cs, im_rd, im_wr} = 6'b0_0_0_0_0_0;
		   {D_En, DA_Sel, T_Sel, HILO_ld, Y_Sel} = 7'b1_1_0_0_000;
		   {dm_cs, dm_rd, dm_wr} = 3'b0_0_0;
		
		// j. $r9 <- $r10 + $r11 (signed addition)
		//************************************************************
		@(negedge clk)				// uop1: IR <- iM[PC], PC <- PC + 4
		   {pc_ld, pc_inc, ir_ld, im_cs, im_rd, im_wr} = 6'b0_1_1_1_1_0;
		   {D_En, DA_Sel, T_Sel, HILO_ld, Y_Sel} = 7'b0_0_0_0_000;
		   {dm_cs, dm_rd, dm_wr} = 3'b0_0_0;
		@(negedge clk)				// uop2: rs <- $r10(r10), rt <- $r11(r11)
		   {pc_ld, pc_inc, ir_ld, im_cs, im_rd, im_wr} = 6'b0_0_0_0_0_0;
		   {D_En, DA_Sel, T_Sel, HILO_ld, Y_Sel} = 7'b0_0_0_0_000;
		   {dm_cs, dm_rd, dm_wr} = 3'b0_0_0;
		@(negedge clk)				// uop3: ALU_OUT <- rs(r10) + rt(r11)
		   {pc_ld, pc_inc, ir_ld, im_cs, im_rd, im_wr} = 6'b0_0_0_0_0_0;
		   {D_En, DA_Sel, T_Sel, HILO_ld, Y_Sel} = 7'b0_0_0_0_000;
		   {dm_cs, dm_rd, dm_wr} = 3'b0_0_0;
		@(negedge clk)				// uop4: $r9 <- ALU_OUT(r10 + r11)
		   {pc_ld, pc_inc, ir_ld, im_cs, im_rd, im_wr} = 6'b0_0_0_0_0_0;
		   {D_En, DA_Sel, T_Sel, HILO_ld, Y_Sel} = 7'b1_1_0_0_000;
		   {dm_cs, dm_rd, dm_wr} = 3'b0_0_0;
		
		// k. M[$r14 + 0] <- $r12 
		//************************************************************
		@(negedge clk)				// uop1: IR <- iM[PC], PC <- PC + 4
		   {pc_ld, pc_inc, ir_ld, im_cs, im_rd, im_wr} = 6'b0_1_1_1_1_0;
		   {D_En, DA_Sel, T_Sel, HILO_ld, Y_Sel} = 7'b0_0_0_0_000;
		   {dm_cs, dm_rd, dm_wr} = 3'b0_0_0;
		@(negedge clk)				// uop2: RS <- $r14(r14), RT <- DT(0x0000_0000)
		   {pc_ld, pc_inc, ir_ld, im_cs, im_rd, im_wr} = 6'b0_0_0_0_0_0;
		   {D_En, DA_Sel, T_Sel, HILO_ld, Y_Sel} = 7'b0_0_1_0_000;
		   {dm_cs, dm_rd, dm_wr} = 3'b0_0_0;
		@(negedge clk)				// uop3: ALU_OUT <- RS(r14) + RT(0x0000_0000)
		   {pc_ld, pc_inc, ir_ld, im_cs, im_rd, im_wr} = 6'b0_0_0_0_0_0;
		   {D_En, DA_Sel, T_Sel, HILO_ld, Y_Sel} = 7'b0_0_0_0_000;
		   {dm_cs, dm_rd, dm_wr} = 3'b0_0_0;
		@(negedge clk)				// uop4: M[ALU_OUT(r14 + 0)] <- RT(r12)
		   {pc_ld, pc_inc, ir_ld, im_cs, im_rd, im_wr} = 6'b0_0_0_0_0_0;
		   {D_En, DA_Sel, T_Sel, HILO_ld, Y_Sel} = 7'b0_0_0_0_000;
		   {dm_cs, dm_rd, dm_wr} = 3'b1_0_1;
      
		//****************************************************
		//Final Integer Register File and Data Memory Dump
		//****************************************************
		$display(" ");
		$display("Final Contents of Integer Register File");
		$display(" ");
		Reg_Dump;
		
		$display(" ");
		$display("Final Contents of Data Memory");
		$display(" ");
		Mem_Dump;
		
		#10;
		$stop;
		
	end
	
	//*******************************************************
	//Integer Register File Dump Task
	//*******************************************************
	task Reg_Dump;
		//read loop
		for(i = 0; i < 16; i = i + 1) begin
			@(negedge clk)
				D_En = 1'b0;
				X = uut1.idp0.D_out[i];
      
			@(posedge clk)
			#1 $display("t=%t $r%h=%h", $time, i[4:0], X);
								
		end
	endtask
	
	//*******************************************************
	//Data Memory Dump Task
	//*******************************************************
	task Mem_Dump;
		//read loop
		for(i = 12'h0FF8; i < 12'h0FFC; i = i + 4) begin
			@(negedge clk)
				   {dm_cs, dm_rd, dm_wr} = 3'b1_1_0;
				X = {uut2.Mem[i], uut2.Mem[i+1], uut2.Mem[i+2], uut2.Mem[i+3]};
				
			@(posedge clk)
			#1 $display("t=%t M[%h]=%h", $time, i[11:0], X);
							 	
		end
	endtask
      
endmodule

