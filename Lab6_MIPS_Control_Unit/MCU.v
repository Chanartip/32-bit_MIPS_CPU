`timescale 1ns / 1ps
/****************************** C E C S 4 4 0 *********************************
 *
 * File Name:  MCU.v
 * Project:    Lab_Assignment_6
 * Designer:   Chanartip Soonthornwan
 *				   Jonathan Shihata
 * Email:      Chanartip.Soonthornwan@gmail.com
 *					Jonnyshihata@gmail.com
 *
 * Rev. No.1:  Version 1.0
 * Rev. Date:  10/24/2017
 *
 * Purpose:    A state machine implementing the MIPS Control Unit (MCU) 
 *             for the major cycles of fetch, execute and some MIPS instructions 
 *             from memory, including checking for interrupts.
 *
 * Notes:
 *
 ******************************************************************************
 
 *-----------------------------------------------------------------------------
 * MCU C O N T R O L W O R D
 *-----------------------------------------------------------------------------
 *
 * {pc_sel, pc_ld, pc_inc, ir_ld} = 5'b00_0_0_0;
 * {im_cs, im_rd, im_wr} = 3'b0_0_0;
 * {D_En, DA_sel, T_Sel, HILO_ld, Y_Sel} = 8'b0_00_0_0_000; 	FS=5'h0;
 * {dm_cs, dm_rd, dm_wr} = 3'b0_0_0; 								int_ack=0;
 *
 *****************************************************************************/

module MCU (sys_clk, reset, intr, 					// system inputs
				c, n, z, v, 								// ALU status inputs
				IR, 											// Instruction Register input
				int_ack, 									// output to I/O subsystem
				pc_sel,  pc_ld,  pc_inc, ir_ld, 		// rest of control word fields
				im_cs,   im_rd,  im_wr,
				D_En,    DA_sel, T_Sel,  HILO_ld,  Y_Sel,
				dm_cs,   dm_rd,  dm_wr,
				FS);
//*****************************************************************************
	input    sys_clk, reset, intr; 		   // system clock, reset, interrupt request
	input 		      c, n, z, v; 		   // Integer ALU status inputs
	input    [31:0]   IR; 					   // Instruction Register input from IU
	output   reg		int_ack; 			   // Interrupt acknowledge
   
   // All OF THE REMAINING CONTROL WORD OUTPUTS
   //       For Instruction Unit
	output   reg	 pc_ld, pc_inc, ir_ld;     // Program Counter Register
	output   reg	 im_cs, im_rd,  im_wr;     // Instruction Memory
	//
   //       For Data Memory
	output   reg	 dm_cs, dm_rd,  dm_wr;     // Data Memory
   //
   //       For Integer Data Path (IDP)
   output   reg		 D_En,  T_Sel, HILO_ld; // Register File
	output   reg [1:0] pc_sel, DA_sel;        // T-MUX and DA_MUX for T or D_Addr
	output   reg [2:0] Y_Sel;                 // ALU_Out select
	output   reg [4:0] FS; 			      		// Function select
	
	// Counter variables
	integer i;

	//****************************
	// internal data structures
	//****************************

	// state assignments
	 parameter
      RESET 	 = 00,  FETCH 	= 01, DECODE = 02,
      ADD 		 = 10,  ADDU 	= 11, AND 	 = 12, OR 	 = 13, NOR    = 14,
      ORI		 = 20,  LUI 	= 21, LW 	 = 22, SW 	 = 23,
      WB_alu 	 = 30,  WB_imm = 31, WB_Din = 32, WB_hi = 33, WB_lo  = 34,  
                                                             WB_mem = 35,
      INTR_1 	 = 501, INTR_2 = 502,INTR_3 = 503,
      BREAK 	 = 510,
      ILLEGAL_OP= 511;
      
	//state register (up to 512 states)
	reg [8:0] state;

	/************************************************
	 * 440 MIPS CONTROL UNIT (Finite State Machine) *
	 ************************************************/

	always @(posedge sys_clk, posedge reset)
	  if (reset)
		 begin
			// ALU_Out <- 32'h3FC
			@(negedge sys_clk)
			{pc_sel, pc_ld, pc_inc, ir_ld} = 5'b00_0_0_0;
			{im_cs, im_rd, im_wr} = 3'b0_0_0;
			{D_En, DA_sel, T_Sel, HILO_ld, Y_Sel} = 8'b0_00_0_0_000;  FS=5'h15;
			{dm_cs, dm_rd, dm_wr} = 3'b0_0_0; 								 int_ack=0;
			state = RESET;
		 end
	  else
		 case (state)
		    FETCH:
				if (int_ack==0 & intr==1) // Recieve Interrupt Signal
				  begin //*** new interrupt pending; prepare for ISR ***
					// control word assignments for "deasserting" everything
				   @(negedge sys_clk)
				   {pc_sel, pc_ld, pc_inc, ir_ld} = 5'b00_0_0_0;
				   {im_cs, im_rd, im_wr} = 3'b0_0_0;
				   {D_En, DA_sel, T_Sel, HILO_ld, Y_Sel} = 8'b0_00_0_0_000;  FS=5'h0;
				   {dm_cs, dm_rd, dm_wr} = 3'b0_0_0; 								 int_ack=0;
					state = INTR_1;
				  end
				else  // No Interrupt Signal involve
				  begin //*** no new interrupt pending; fetch and instruction ***
					 if (int_ack==1 & intr==0) int_ack=1'b0;
					 // control word assignments for IR <- iM[PC]; PC <- PC+4
				    @(negedge sys_clk)
					 {pc_sel, pc_ld, pc_inc, ir_ld} = 5'b00_0_1_1;
				    {im_cs, im_rd, im_wr} = 3'b1_1_0;
				    {D_En, DA_sel, T_Sel, HILO_ld, Y_Sel} = 8'b0_00_0_0_000;  FS=5'h0;
				    {dm_cs, dm_rd, dm_wr} = 3'b0_0_0; 								  int_ack=0;
					 state = DECODE;
				  end

			 RESET:
				begin
				  // control word assignments for $sp <- ALU_Out(32'h3FC)
				  @(negedge sys_clk)
				  {pc_sel, pc_ld, pc_inc, ir_ld} = 5'b00_0_0_0;
				  {im_cs, im_rd, im_wr} = 3'b0_0_0;
				  {D_En, DA_sel, T_Sel, HILO_ld, Y_Sel} = 8'b1_11_0_0_000; 	FS=5'h0;
				  {dm_cs, dm_rd, dm_wr} = 3'b0_0_0; 								int_ack=0;
				  state = FETCH;
				end

			 DECODE:
				begin
				  @(negedge sys_clk)
              // check for MIPS format
              // [000000][rs][rt][rd][shmt][func] - R type
				  if (MIPS_CU_TB.iu.IR_out[31:26] == 6'h0)
					 begin 
                  // it is an R-type format
			      	// control word assignments: RS <- $rs, RT <- $rt (default)
						{pc_sel, pc_ld, pc_inc, ir_ld} = 5'b00_0_0_0;
					   {im_cs, im_rd, im_wr} = 3'b0_0_0;
					   {D_En, DA_sel, T_Sel, HILO_ld, Y_Sel} = 8'b0_00_0_0_000; 
																							FS = 5'h0;
					   {dm_cs, dm_rd, dm_wr} = 3'b0_0_0; 						int_ack = 1'b0;
					   
                  // check for function for R type
                  case (MIPS_CU_TB.iu.IR_out[5:0])
						  6'h0D :  state = BREAK;
						  6'h20 :  state = ADD;
						  default: state = ILLEGAL_OP;
					   endcase
				    end // end of if for R-type Format
				  else
					 begin 
                  // it is an I-type or J-type format
                  // [pppppp][rs][rt][16'b imme] - I type
                  // [pppppp][26'b imme] - J type
                  // control word assignments: RS <- $rs, RT <- DT(se_16)
					   {pc_sel, pc_ld, pc_inc, ir_ld} = 5'b00_0_0_0;
					   {im_cs, im_rd, im_wr} = 3'b0_0_0;
					   {D_En, DA_sel, T_Sel, HILO_ld, Y_Sel} = 8'b0_00_1_0_000;
																							FS = 5'h0;
					   {dm_cs, dm_rd, dm_wr} = 3'b0_0_0; 						int_ack = 1'b0;
                  
                  // Check opcode for I and J type
					   case (MIPS_CU_TB.iu.IR_out[31:26])
						  6'h0D : state = ORI;
						  6'h0F : state = LUI;
						  6'h2B : state = SW;
						  default: state = ILLEGAL_OP;
						endcase
					 end // end of else for I-type or J-type formats
				end // end of DECODE

			 ADD:
				begin
				  // control word assignments: ALU_Out <- $rs + $rt
				  @(negedge sys_clk)
				  {pc_sel, pc_ld, pc_inc, ir_ld} = 5'b00_0_0_0;
				  {im_cs, im_rd, im_wr} = 3'b0_0_0;
				  {D_En, DA_sel, T_Sel, HILO_ld, Y_Sel} = 8'b0_00_0_0_000; 	FS=5'h02;
				  {dm_cs, dm_rd, dm_wr} = 3'b0_0_0; 								int_ack=0;
				  state = WB_alu;
				end

			 ORI:
				begin
				  // ctrl word assignments for ALU_Out <- $rs | {16'h0, RT[15:0]}
				  @(negedge sys_clk)
				  {pc_sel, pc_ld, pc_inc, ir_ld} = 5'b00_0_0_0;
				  {im_cs, im_rd, im_wr} = 3'b0_0_0;
				  {D_En, DA_sel, T_Sel, HILO_ld, Y_Sel} = 8'b0_00_1_0_000; 	FS=5'h17;
				  {dm_cs, dm_rd, dm_wr} = 3'b0_0_0; 								int_ack=0;
				  state = WB_imm;
				end

			 LUI:
				begin
				  // control word assignments for ALU_Out <- { RT[15:0], 16'h0}
				  @(negedge sys_clk)
				  {pc_sel, pc_ld, pc_inc, ir_ld} = 5'b00_0_0_0;
				  {im_cs, im_rd, im_wr} = 3'b0_0_0;
				  {D_En, DA_sel, T_Sel, HILO_ld, Y_Sel} = 8'b0_00_1_0_000; 	FS=5'h19;
				  {dm_cs, dm_rd, dm_wr} = 3'b0_0_0; 								int_ack=0;
				  state = WB_imm;
				end

			 SW:
				begin
				  // control word assignments for ALU_Out <- $rs + $rt(se_16) "EA calc"
				  @(negedge sys_clk)
				  {pc_sel, pc_ld, pc_inc, ir_ld} = 5'b00_0_0_0;
				  {im_cs, im_rd, im_wr} = 3'b0_0_0;
				  {D_En, DA_sel, T_Sel, HILO_ld, Y_Sel} = 8'b0_01_0_0_000; 	FS=5'h02;
				  {dm_cs, dm_rd, dm_wr} = 3'b0_0_0; 								int_ack=0;
				  state = WB_mem;
				end
			
			 WB_alu:
				begin
				  // control word assignments for R[rd] <- ALU_Out
				  @(negedge sys_clk)
				  {pc_sel, pc_ld, pc_inc, ir_ld} = 5'b00_0_0_0;
				  {im_cs, im_rd, im_wr} = 3'b0_0_0;
				  {D_En, DA_sel, T_Sel, HILO_ld, Y_Sel} = 8'b1_00_0_0_000; 	FS=5'h0;
				  {dm_cs, dm_rd, dm_wr} = 3'b0_0_0; 								int_ack=0;
				  state = FETCH;
				end

			 WB_imm:
				begin
				  // control word assignments for R[rt] <- ALU_Out
				  @(negedge sys_clk)
				  {pc_sel, pc_ld, pc_inc, ir_ld} = 5'b00_0_0_0;
				  {im_cs, im_rd, im_wr} = 3'b0_0_0;
				  {D_En, DA_sel, T_Sel, HILO_ld, Y_Sel} = 8'b1_01_0_0_000; 	FS=5'h0;
				  {dm_cs, dm_rd, dm_wr} = 3'b0_0_0; 								int_ack=0;
				  state = FETCH;
				end

			 WB_mem:
				begin
				  // control word assignments for M[ ALU_Out(rs+se_16)] <- RT(rt)
				  @(negedge sys_clk)
				  {pc_sel, pc_ld, pc_inc, ir_ld} = 5'b00_0_0_0;
				  {im_cs, im_rd, im_wr} = 3'b0_0_0;
				  {D_En, DA_sel, T_Sel, HILO_ld, Y_Sel} = 8'b0_00_0_0_000; 	FS=5'h0;
				  {dm_cs, dm_rd, dm_wr} = 3'b1_0_1; 								int_ack=0;
				  state = FETCH;
				end

			 BREAK:
				begin
				  $display("BREAK INSTRUCTION FETCHED %t",$time);
				  // control word assignments for "deasserting" everything
				  @(negedge sys_clk)
				  {pc_sel, pc_ld, pc_inc, ir_ld} = 5'b00_0_0_0;
				  {im_cs, im_rd, im_wr} = 3'b0_0_0;
				  {D_En, DA_sel, T_Sel, HILO_ld, Y_Sel} = 8'b0_00_0_0_000; 	FS=5'h0;
				  {dm_cs, dm_rd, dm_wr} = 3'b0_0_0; 								int_ack=0;
				  $display(" R E G I S T E R ' S  A F T E R  B R E A K");
				  $display(" ");
				  Dump_Registers; // task to output MIPS RegFile
				  $display(" ");
				  $display("time=%t M[3F0]=%h", $time, {MIPS_CU_TB.dMem.Mem[12'h3F0],
																    MIPS_CU_TB.dMem.Mem[12'h3F1],
																    MIPS_CU_TB.dMem.Mem[12'h3F2],
																    MIPS_CU_TB.dMem.Mem[12'h3F3]});
				  $finish;                              
				end

			 ILLEGAL_OP:
				begin
				  $display("ILLEGAL OPCODE FETCHED %t",$time);
				  // control word assignments for "deasserting" everything
				  @(negedge sys_clk)
				  {pc_sel, pc_ld, pc_inc, ir_ld} = 5'b00_0_0_0;
				  {im_cs, im_rd, im_wr} = 3'b0_0_0;
				  {D_En, DA_sel, T_Sel, HILO_ld, Y_Sel} = 8'b0_00_0_0_000; 	FS=5'h0;
				  {dm_cs, dm_rd, dm_wr} = 3'b0_0_0; 								int_ack=0;
				  $display(" ");
				  $display("Memory:");
				  $display(" ");
				  Dump_Registers;
				  $display(" ");
				  Dump_PC_and_IR;
				$finish;
				end

			 INTR_1:
				begin
				  // PC gets address of interrupt vector; Save PC in $ra
				  // control word assignments for ALU_Out <- 0x3FC, R[$ra] <- PC
				  @(negedge sys_clk)
				  {pc_sel, pc_ld, pc_inc, ir_ld} = 5'b00_0_0_0;
				  {im_cs, im_rd, im_wr} = 3'b0_0_0;
				  {D_En, DA_sel, T_Sel, HILO_ld, Y_Sel} = 8'b1_10_0_0_100; 	FS=5'h15;
				  {dm_cs, dm_rd, dm_wr} = 3'b0_0_0; 								int_ack=0;
				  state = INTR_2;
				end

			 INTR_2:
				begin
				  // Read address of ISR into D_in;
				  // control word assignments for D_in <- dM[ALU_Out(0x3FC]
				  @(negedge sys_clk)
				  {pc_sel, pc_ld, pc_inc, ir_ld} = 5'b00_0_0_0;
				  {im_cs, im_rd, im_wr} = 3'b0_0_0;
				  {D_En, DA_sel, T_Sel, HILO_ld, Y_Sel} = 8'b0_00_0_0_000; 	FS=5'h0;
				  {dm_cs, dm_rd, dm_wr} = 3'b1_1_0; 								int_ack=0;
				  state = INTR_3;
				end

			 INTR_3:
				begin
				  // Reload PC with address of ISR; ack the intr; goto FETCH
				  // control word assignments for PC <- D_in( dM[0x3FC] ), int_ack <- 1
				  @(negedge sys_clk)
				  {pc_sel, pc_ld, pc_inc, ir_ld} = 5'b00_1_0_0;
				  {im_cs, im_rd, im_wr} = 3'b0_0_0;
				  {D_En, DA_sel, T_Sel, HILO_ld, Y_Sel} = 8'b0_00_0_0_011; 	FS=5'h0;
				  {dm_cs, dm_rd, dm_wr} = 3'b0_0_0; 								int_ack=1;
				  state = FETCH;
				end
            
		 endcase // end of FSM logic
	 
	//*******************************************************
	//          Integer Register File Dump Task             *
	//*******************************************************
	task Dump_Registers;
		begin
			for(i = 0; i < 16; i = i + 1) 
          begin
				 $display ("t=%t   $r%0d = %h  ||  t=%t   $r%0d = %h",
				 $time, i, MIPS_CU_TB.id.regfile.reg_array[i],
				 $time, i+16, MIPS_CU_TB.id.regfile.reg_array[i+16]);
			 end
		end
	endtask
	
	//*******************************************************
	//             PC and IR Register Dump Task             *
	//*******************************************************
	task Dump_PC_and_IR;
		begin
			$display(" "); $display("PC Register:");
			$display(" ");
			$display("t=%t PC=%h", $time, MIPS_CU_TB.iu.PC.pc_out);
			$display(" ");                
			$display("IR Register:");
			$display("t=%t IR=%h", $time, MIPS_CU_TB.iu.IR.q);
			$display(" "); $display(" ");
		end
	endtask
	
endmodule
