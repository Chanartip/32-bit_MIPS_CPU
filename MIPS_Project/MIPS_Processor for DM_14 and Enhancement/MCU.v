`timescale 1ns / 1ps
/****************************** C E C S 4 4 0 *********************************
 *
 * File Name:  MCU.v
 * Project:    Final Project
 * Designer:   Chanartip Soonthornwan
 *				   Jonathan Shihata
 * Email:      Chanartip.Soonthornwan@gmail.com
 *					Jonnyshihata@gmail.com
 *
 * Rev. No.1:  Version 1.0
 * Rev. Date:  10/24/2017
 *
 * Rev. No.2:  Version 1.1
 * Rev. Date:  11/18/2017
 * update   :  add Dump_mem to display 32 registers on Data Memory and IO Memory
 *
 * Rev. No.3:  Version 2.0
 * Rev. Date:  Current Rev. 11/21/2017
 * update   :  Added SP_Sel, S_Sel for stack PC and flags on Memory.
 *             Added ports for stacked flags.
 *             Added RETI and Edited INTR states
 *
 * Purpose:    A state machine implementing the MIPS Control Unit (MCU) 
 *             for the major cycles of fetch, execute and some MIPS instructions 
 *             from memory, including checking for interrupts.
 *
 ******************************************************************************
 
 *-----------------------------------------------------------------------------
 * MCU C O N T R O L W O R D
 *-----------------------------------------------------------------------------
 *                            int_ack=0;   FS=5'h0;
 *        {pc_sel, pc_ld, pc_inc, ir_ld} = 5'b00_0_0_0;
 *                 {im_cs, im_rd, im_wr} = 3'b0_0_0;
 * {D_En, DA_sel, T_Sel, HILO_ld, Y_Sel} = 9'b0_00_00_0_000; 	
 *                 {dm_cs, dm_rd, dm_wr} = 3'b0_0_0; 								
 *                 {io_cs, io_rd, io_wr} = 3'b0_0_0;
 *                       {SP_Sel, S_Sel} = 2'b0_0;
 *          #1 {nsi, nsc, nsv, nsn, nsz} = {psi, psc, psv, psn, psz};								
 *
 *****************************************************************************/
module MCU (sys_clk, reset, intr, 					// system inputs
				c, n, z, v, 								// ALU status inputs
				IR, 											// Instruction Register input
				int_ack, 									// output to I/O subsystem
				pc_sel,  pc_ld,  pc_inc, ir_ld, 		// rest of control word fields
				im_cs,   im_rd,  im_wr,
				D_En,    DA_sel, T_Sel,  HILO_ld,  Y_Sel,
            SP_Sel,  S_Sel,  sp_flags_in, sp_flags_out,
				dm_cs,   dm_rd,  dm_wr,
            io_cs,   io_rd,  io_wr,
				FS);
//*****************************************************************************
	input    sys_clk, reset, intr; 		   // system clock, reset, interrupt request
	input 		      c, n, z, v; 		   // Integer ALU status inputs
	input    [31:0]   IR; 					   // Instruction Register input from IU
	output   reg		int_ack; 			   // Interrupt acknowledge
   input    [4:0]    sp_flags_in;         // Stack Pointer flags input
   
   // All OF THE REMAINING CONTROL WORD OUTPUTS
   //       For Instruction Unit
	output   reg	 pc_ld, pc_inc, ir_ld;     // Program Counter Register
	output   reg	 im_cs, im_rd,  im_wr;     // Instruction Memory
	//
   //       For Data and IO Memory
	output   reg	 dm_cs, dm_rd,  dm_wr;     // Data Memory
   output   reg    io_cs, io_rd,  io_wr;     // IO Memory
   //
   //       For Integer Data Path (IDP)
   output   reg		 D_En,   HILO_ld;        // Register File
   output   reg [1:0] T_Sel;                  //      Controls
   output   reg       SP_Sel, S_Sel;          // Stack Pointer Controls  
   output   reg [4:0] sp_flags_out;           // Stack Pointer flags output
	output   reg [1:0] pc_sel, DA_sel;         // T-MUX and DA_MUX for T or D_Addr
	output   reg [2:0] Y_Sel;                  // ALU_Out select
	output   reg [4:0] FS; 			      		 // Function select
	
	// Counter variables
	integer i, X, Y;

	//****************************
	// internal data structures
	//****************************

	// state assignments
	 parameter
      RESET = 00, FETCH = 01, DECODE = 02,
      // R-type (20 instructions)
      SLL =  3, SRL =  4, SRA  =  5, JR   =  6, MFHI  =  7, MFLO =  8, MULT =  9,
		DIV = 10, ADD = 11, ADDU = 12, SUB  = 13, SUBU  = 14, AND  = 15, OR   = 16, 
		XOR = 17, NOR = 18, SLT  = 19, SLTU = 20, SETIE = 21,
         //R-type Continued
      JR_2 = 106,   
         
      // I-type (13 instructions)
      BEQ  = 24, BNE   = 25, BLEZ = 26, BGTZ = 27, ADDI = 28, 
      SLTI = 29, SLTIU = 30, ANDI = 31, ORI  = 32, XORI = 33,
      LUI  = 34, LW    = 35, SW   = 36, 
         // I-type Continued
      BEQ_2 = 124, BNE_2 = 125, BLEZ_2 = 126, BGTZ_2 = 127,
      LW_2  = 135,
         
      // J-type (2 instructions)
      J = 37 , JAL = 38,
         // J-typd Continued
      JAL_2 = 138,

      // E-type
      INPUT   =  80, OUTPUT   =  81, RETI   =  82,
      INPUT_2 = 180, OUTPUT_2 = 181, RETI_2 = 182,
      ROTL    =  84, ROTR     =  85, RETI_3 = 282,
      ROTL_2  = 184, ROTR_2   = 185, RETI_4 = 382,
      BLT     =  86, BGE      =  87, RETI_5 = 482,
      BLT_2   = 186, BGE_2    = 187, RETI_6 = 483,
      CLR     =  88, DJNZ     =  89, MOV    =  90, 
      CLR_2   = 188, DJNZ_2   = 189, MOV_2  = 190,
      NOP    =  91,
      PUSH   =  92, POP    =  96,
      PUSH_2 =  93, POP_2  =  97,
      PUSH_3 =  94, POP_3  =  98,
      PUSH_4 =  95, POP_4  =  99,
                    POP_5  = 100,
      
      
      // Extras
      WB_alu 	  = 50,  WB_imm = 51,  WB_Din = 52, INTR_1 = 501,  
      WB_hi      = 53,  WB_lo  = 54,  WB_mem = 55, INTR_2 = 502,
      BREAK 	  = 510,                            INTR_3 = 503,
      ILLEGAL_OP = 511,                            INTR_4 = 504,
                                                   INTR_5 = 505,
                                                   INTR_6 = 506;
      
      
	//state register (up to 512 states)
	reg [8:0] state;

   /******************
    * Flags register *
    ******************/
   reg   psi, psc, psv, psn, psz;   // flags present state registers
   reg   nsi, nsc, nsv, nsn, nsz;   // flags next state registers

   // Updating flags register
   always @(posedge sys_clk, posedge reset)
      if(reset)
         {psi, psc, psv, psn, psz} = 5'b0;
      else
         {psi, psc, psv, psn, psz} = {nsi, nsc, nsv, nsn, nsz};

	/************************************************
	 * 440 MIPS CONTROL UNIT (Finite State Machine) *
	 ************************************************/
	always @(posedge sys_clk, posedge reset)
	  if (reset)
		 begin
			// ALU_Out <- 32'h3FC
			@(negedge sys_clk)
                                       int_ack=0;   FS=5'h15;
                   {pc_sel, pc_ld, pc_inc, ir_ld} = 5'b00_0_0_0;
                            {im_cs, im_rd, im_wr} = 3'b0_0_0;
            {D_En, DA_sel, T_Sel, HILO_ld, Y_Sel} = 9'b0_00_00_0_000;
                            {dm_cs, dm_rd, dm_wr} = 3'b0_0_0; 								
                            {io_cs, io_rd, io_wr} = 3'b0_0_0;
                                  {SP_Sel, S_Sel} = 2'b0_0;
              #1 {nsi, nsc, nsv, nsn, nsz} = 5'b0;
			state = RESET;
		 end
	  else
		 case (state)
		    FETCH:
				if (int_ack==0 & (intr==1 & psi==1)) // Recieve Interrupt Signal
				  begin //*** new interrupt pending; prepare for ISR ***
					// control word assignments for "deasserting" everything
				   @(negedge sys_clk)
                                             int_ack=0;   FS=5'h0;
                         {pc_sel, pc_ld, pc_inc, ir_ld} = 5'b00_0_0_0;
                                  {im_cs, im_rd, im_wr} = 3'b0_0_0;
                  {D_En, DA_sel, T_Sel, HILO_ld, Y_Sel} = 9'b0_00_00_0_000; 
                                  {dm_cs, dm_rd, dm_wr} = 3'b0_0_0; 								
                                  {io_cs, io_rd, io_wr} = 3'b0_0_0;
                                        {SP_Sel, S_Sel} = 2'b0_0;
              #1 {nsi, nsc, nsv, nsn, nsz} = {psi, psc, psv, psn, psz};
                  state = INTR_1;
				  end
				else  // No Interrupt Signal involved
				  begin //*** no new interrupt pending; fetch and instruction ***
					if((int_ack==1 & intr==1) || (psi==1 & intr==0)) int_ack=1'b0;
					// control word assignments for IR <- iM[PC]; PC <- PC+4
               @(negedge sys_clk)
                                             int_ack=0;   FS=5'h0;
                         {pc_sel, pc_ld, pc_inc, ir_ld} = 5'b00_0_1_1;
                                  {im_cs, im_rd, im_wr} = 3'b1_1_0;
                  {D_En, DA_sel, T_Sel, HILO_ld, Y_Sel} = 9'b0_00_00_0_000; 
                                  {dm_cs, dm_rd, dm_wr} = 3'b0_0_0; 								 
                                  {io_cs, io_rd, io_wr} = 3'b0_0_0;
                                        {SP_Sel, S_Sel} = 2'b0_0;
              #1 {nsi, nsc, nsv, nsn, nsz} = {psi, psc, psv, psn, psz};
                  state = DECODE;
				  end

			 RESET:
				begin
				  // control word assignments for $sp <- ALU_Out(32'h3FC)
				  @(negedge sys_clk)
                                             int_ack=0;   FS=5'h0;
                         {pc_sel, pc_ld, pc_inc, ir_ld} = 5'b00_0_0_0;
                                  {im_cs, im_rd, im_wr} = 3'b0_0_0;
                  {D_En, DA_sel, T_Sel, HILO_ld, Y_Sel} = 9'b1_11_00_0_000; 	
                                  {dm_cs, dm_rd, dm_wr} = 3'b0_0_0; 								
              #1  {nsi, nsc, nsv, nsn, nsz} = {psi, psc, psv, psn, psz};
                  state = FETCH;
				end

			 DECODE:
				begin
				  @(negedge sys_clk)
              // check for MIPS format
              // [000000][rs][rt][rd][shmt][func] - R type
				  if (CPU.iu.IR_out[31:26] == 6'h0)
					 begin 
                  // it is an R-type format
			      	// control word assignments: RS <- $rs, RT <- $rt (default)
                                             int_ack=0;   FS=5'h0;
						       {pc_sel, pc_ld, pc_inc, ir_ld} = 5'b00_0_0_0;
					                   {im_cs, im_rd, im_wr} = 3'b0_0_0;
					   {D_En, DA_sel, T_Sel, HILO_ld, Y_Sel} = 9'b0_00_00_0_000; 												
					                   {dm_cs, dm_rd, dm_wr} = 3'b0_0_0; 						
					                   {io_cs, io_rd, io_wr} = 3'b0_0_0;
                                       {SP_Sel, S_Sel} = 2'b0_0;
              #1 {nsi, nsc, nsv, nsn, nsz} = {psi, psc, psv, psn, psz};
                  
                  // check for function for R type
                  case (CPU.iu.IR_out[5:0])
                    6'h00 :  state = SLL;
                    6'h02 :  state = SRL;
                    6'h03 :  state = SRA;
                    6'h08 :  state = JR;
                    6'h10 :  state = MFHI;
                    6'h12 :  state = MFLO;
                    6'h18 :  state = MULT;
                    6'h1A :  state = DIV;
                    6'h20 :  state = ADD;
                    6'h21 :  state = ADDU;
						  6'h22 :  state = SUB;
						  6'h23 :  state = SUBU;
						  6'h24 :  state = AND;
						  6'h25 :  state = OR;
						  6'h26 :  state = XOR;
						  6'h27 :  state = NOR;
						  6'h2A :  state = SLT;
						  6'h2B :  state = SLTU;
						  6'h0D :  state = BREAK;
						  6'h1F :  state = SETIE;
                    default: state = ILLEGAL_OP;
					   endcase
				    end // end of if for R-type Format
              else if(CPU.iu.IR_out[31:26] == 6'h1F)
					 begin 
                  // E-key is R-type format
			      	// control word assignments: RS <- $rs, RT <- $rt (default)
                                           int_ack=0;   FS=5'h0;
						       {pc_sel, pc_ld, pc_inc, ir_ld} = 5'b00_0_0_0;
					                   {im_cs, im_rd, im_wr} = 3'b0_0_0;
					   {D_En, DA_sel, T_Sel, HILO_ld, Y_Sel} = 9'b0_00_00_0_000; 												
					                   {dm_cs, dm_rd, dm_wr} = 3'b0_0_0; 						
					                   {io_cs, io_rd, io_wr} = 3'b0_0_0;
                                      {SP_Sel, S_Sel} = 2'b0_0;
              #1 {nsi, nsc, nsv, nsn, nsz} = {psi, psc, psv, psn, psz};
                  
                  // check for function for E-key type
                  case (CPU.iu.IR_out[5:0])
                     6'h01  : state = ROTL;
                     6'h02  : state = ROTR;
                     6'h05  : state = CLR;
                     6'h07  : state = MOV;
                     6'h08  : state = NOP;
                     6'h09  : state = PUSH;
                     6'h0A  : state = POP;
                     default: state = ILLEGAL_OP;
                  endcase
                end  // end of if E-key format
				  else
					 begin 
                  // it is an I-type or J-type format
                  // [pppppp][rs][rt][16'b imme] - I type
                  // [pppppp][26'b imme] - J type
                  // control word assignments: RS <- $rs, RT <- DT(se_16)
                                             int_ack=0;   FS=5'h00;
					          {pc_sel, pc_ld, pc_inc, ir_ld} = 5'b00_0_0_0;
					                   {im_cs, im_rd, im_wr} = 3'b0_0_0;
					   {D_En, DA_sel, T_Sel, HILO_ld, Y_Sel} = 9'b0_00_01_0_000;
					                   {dm_cs, dm_rd, dm_wr} = 3'b0_0_0; 						
                                  {io_cs, io_rd, io_wr} = 3'b0_0_0;
                                        {SP_Sel, S_Sel} = 2'b0_0;
              #1 {nsi, nsc, nsv, nsn, nsz} = {psi, psc, psv, psn, psz};
                  
                  // Check opcode for I and J type
					   case (CPU.iu.IR_out[31:26])
                    6'h02 : state = J;
                    6'h03 : state = JAL;
                    6'h04 : state = BEQ;
                    6'h05 : state = BNE;
                    6'h06 : state = BLEZ;
                    6'h07 : state = BGTZ;
                    6'h08 : state = ADDI;
                    6'h0A : state = SLTI;
                    6'h0B : state = SLTIU;
                    6'h0C : state = ANDI;
						  6'h0D : state = ORI;
                    6'h0E : state = XORI;
						  6'h0F : state = LUI;
                    6'h23 : state = LW;
						  6'h2B : state = SW;
                    6'h1C : state = INPUT;
                    6'h1D : state = OUTPUT;
                    6'h1E : state = RETI;
                    6'h2C : state = BLT;
                    6'h2D : state = BGE;
                    6'h2E : state = DJNZ;
						  default: state = ILLEGAL_OP;
						endcase
                  
                  // Case of Branches
                  //    if T_Sel = 0, RT <- $rt
                  //    so IR[15:0] will be used to calculate
                  //    Branch address.
                  if(state == BEQ || state == BNE ||
                     state == BLEZ|| state == BGTZ||
                     state == BLT || state == BGE  )
                     T_Sel = 2'b00;
                  else
                     T_Sel = 2'b01;
                  
					 end // end of else for I-type or J-type formats
				end // end of DECODE
            
   /***************************************************************************
    ****************          R-type   Instruction           ******************
    ***************************************************************************/ 
			SLL:
				begin
				  // control word assignments: ALU_Out <- $rt << shamt
				  @(negedge sys_clk)
                                             int_ack=0;	 FS=5'h0C;
                         {pc_sel, pc_ld, pc_inc, ir_ld} = 5'b00_0_0_0;
                                  {im_cs, im_rd, im_wr} = 3'b0_0_0;
                  {D_En, DA_sel, T_Sel, HILO_ld, Y_Sel} = 9'b0_00_00_0_000;
                                  {dm_cs, dm_rd, dm_wr} = 3'b0_0_0;
				  #1  {nsi, nsc, nsv, nsn, nsz} = {psi, psc, psv, psn, psz};
                  state = WB_alu;
				end
				
			SRL:
				begin
				  // control word assignments: ALU_Out <- $rt >> shamt
				  @(negedge sys_clk)
                                            int_ack=0;	FS=5'h0D;
                        {pc_sel, pc_ld, pc_inc, ir_ld} = 5'b00_0_0_0;
                                 {im_cs, im_rd, im_wr} = 3'b0_0_0;
                 {D_En, DA_sel, T_Sel, HILO_ld, Y_Sel} = 9'b0_00_00_0_000;
                                 {dm_cs, dm_rd, dm_wr} = 3'b0_0_0;
                                 {io_cs, io_rd, io_wr} = 3'b0_0_0;
                                       {SP_Sel, S_Sel} = 2'b0_0;
              #1 {nsi, nsc, nsv, nsn, nsz} = {psi, psc, psv, psn, psz};
                 state = WB_alu;
				end
				
			SRA:
				begin
				  // control word assignments: ALU_Out <- $rt >> shamt
				  @(negedge sys_clk)
                                            int_ack=0;	FS=5'h0E;
                        {pc_sel, pc_ld, pc_inc, ir_ld} = 5'b00_0_0_0;
                                 {im_cs, im_rd, im_wr} = 3'b0_0_0;
                 {D_En, DA_sel, T_Sel, HILO_ld, Y_Sel} = 9'b0_00_00_0_000;
                                 {dm_cs, dm_rd, dm_wr} = 3'b0_0_0;
                                 {io_cs, io_rd, io_wr} = 3'b0_0_0;
                                       {SP_Sel, S_Sel} = 2'b0_0;
              #1 {nsi, nsc, nsv, nsn, nsz} = {psi, c, v, n, z};
                 state = WB_alu;
				end
				
			JR:
				begin
				  // control word assignments: PC <- [$rt]
				  @(negedge sys_clk)
                                            int_ack=0;	 FS=5'h0;
                        {pc_sel, pc_ld, pc_inc, ir_ld} = 5'b00_0_0_0;
                                 {im_cs, im_rd, im_wr} = 3'b0_0_0;
                 {D_En, DA_sel, T_Sel, HILO_ld, Y_Sel} = 9'b0_00_00_0_000;
                                 {dm_cs, dm_rd, dm_wr} = 3'b0_0_0;
                                 {io_cs, io_rd, io_wr} = 3'b0_0_0;
                                       {SP_Sel, S_Sel} = 2'b0_0;
              #1 {nsi, nsc, nsv, nsn, nsz} = {psi, psc, psv, psn, psz};
                 state = JR_2;
				end
				
			JR_2:
				begin
				  // control word assignments: PC <- [$rt]
				  @(negedge sys_clk)
                                            int_ack=0;	 FS=5'h0;
                        {pc_sel, pc_ld, pc_inc, ir_ld} = 5'b00_1_0_0;
                                 {im_cs, im_rd, im_wr} = 3'b0_0_0;
                 {D_En, DA_sel, T_Sel, HILO_ld, Y_Sel} = 9'b0_00_00_0_000;
                                 {dm_cs, dm_rd, dm_wr} = 3'b0_0_0;
                                 {io_cs, io_rd, io_wr} = 3'b0_0_0;
                                       {SP_Sel, S_Sel} = 2'b0_0;
              #1 {nsi, nsc, nsv, nsn, nsz} = {psi, psc, psv, psn, psz};
                 state = FETCH;
				end
				 
			MFHI:
				begin
				  // control word assignments: R[$rd] <- Hi
				  @(negedge sys_clk)
                                            int_ack=0;	 FS=5'h0;
                        {pc_sel, pc_ld, pc_inc, ir_ld} = 5'b00_0_0_0;
                                 {im_cs, im_rd, im_wr} = 3'b0_0_0;
                 {D_En, DA_sel, T_Sel, HILO_ld, Y_Sel} = 9'b1_00_00_0_001;
                                 {dm_cs, dm_rd, dm_wr} = 3'b0_0_0;
                                 {io_cs, io_rd, io_wr} = 3'b0_0_0;
                                       {SP_Sel, S_Sel} = 2'b0_0;
              #1 {nsi, nsc, nsv, nsn, nsz} = {psi, psc, psv, psn, psz};
                 state = FETCH;
				end
				
			MFLO:
				begin
				  // control word assignments: R[$rd] <- Lo
				  @(negedge sys_clk)
                                            int_ack=0;	 FS=5'h0;
                        {pc_sel, pc_ld, pc_inc, ir_ld} = 5'b00_0_0_0;
                                 {im_cs, im_rd, im_wr} = 3'b0_0_0;
                 {D_En, DA_sel, T_Sel, HILO_ld, Y_Sel} = 9'b1_00_00_0_010;
                                 {dm_cs, dm_rd, dm_wr} = 3'b0_0_0;
                                 {io_cs, io_rd, io_wr} = 3'b0_0_0;
                                       {SP_Sel, S_Sel} = 2'b0_0;
              #1 {nsi, nsc, nsv, nsn, nsz} = {psi, psc, psv, psn, psz};
                 state = FETCH;
				end
				
			MULT:
				begin
				  // control word assignments: {Hi,Lo} <- R[$rs] * R[$rt]
				  @(negedge sys_clk)
                                            int_ack=0;	 FS=5'h1E;
                        {pc_sel, pc_ld, pc_inc, ir_ld} = 5'b00_0_0_0;
                                 {im_cs, im_rd, im_wr} = 3'b0_0_0;
                 {D_En, DA_sel, T_Sel, HILO_ld, Y_Sel} = 9'b0_00_00_1_000;
                                 {dm_cs, dm_rd, dm_wr} = 3'b0_0_0;
                                 {io_cs, io_rd, io_wr} = 3'b0_0_0;
                                       {SP_Sel, S_Sel} = 2'b0_0;
              #1 {nsi, nsc, nsv, nsn, nsz} = {psi, c, v, n, z};
                 state = FETCH;
				end
				
			DIV:
				begin
				  // control word assignments: Lo <- R[$rs] / R[$rt], Hi <- R[$rs] % R[$rt]
				  @(negedge sys_clk)
                                            int_ack=0;	 FS=5'h1F;
                        {pc_sel, pc_ld, pc_inc, ir_ld} = 5'b00_0_0_0;
                                 {im_cs, im_rd, im_wr} = 3'b0_0_0;
                 {D_En, DA_sel, T_Sel, HILO_ld, Y_Sel} = 9'b0_00_00_1_000;
                                 {dm_cs, dm_rd, dm_wr} = 3'b0_0_0;
                                 {io_cs, io_rd, io_wr} = 3'b0_0_0;
                                       {SP_Sel, S_Sel} = 2'b0_0;
              #1 {nsi, nsc, nsv, nsn, nsz} = {psi, c, v, n, z};
                 state = WB_alu;
				end
				
			 ADD:
				begin
				  // control word assignments: ALU_Out <- $rs + $rt
				  @(negedge sys_clk)
                                            int_ack=0;	 FS=5'h02;
                        {pc_sel, pc_ld, pc_inc, ir_ld} = 5'b00_0_0_0;
                                 {im_cs, im_rd, im_wr} = 3'b0_0_0;
                 {D_En, DA_sel, T_Sel, HILO_ld, Y_Sel} = 9'b0_00_00_0_000;
                                 {dm_cs, dm_rd, dm_wr} = 3'b0_0_0;
                                 {io_cs, io_rd, io_wr} = 3'b0_0_0;
                                       {SP_Sel, S_Sel} = 2'b0_0;
              #1 {nsi, nsc, nsv, nsn, nsz} = {psi, c, v, n, z};
                 state = WB_alu;
				end
			
			ADDU:
				begin
				  // control word assignments: ALU_Out <- $rs + $rt
				  @(negedge sys_clk)
                                            int_ack=0;	 FS=5'h02;
                        {pc_sel, pc_ld, pc_inc, ir_ld} = 5'b00_0_0_0;
                                 {im_cs, im_rd, im_wr} = 3'b0_0_0;
                 {D_En, DA_sel, T_Sel, HILO_ld, Y_Sel} = 9'b0_00_00_0_000; 
                                 {dm_cs, dm_rd, dm_wr} = 3'b0_0_0; 					
                                 {io_cs, io_rd, io_wr} = 3'b0_0_0;
                                       {SP_Sel, S_Sel} = 2'b0_0;
              #1 {nsi, nsc, nsv, nsn, nsz} = {psi, c, v, n, z};
                 state = WB_alu;
				end
				
			SUB:
				begin
				  // control word assignments: ALU_Out <- $rs - $rt
				  @(negedge sys_clk)
                                            int_ack=0;	 FS=5'h04;
                        {pc_sel, pc_ld, pc_inc, ir_ld} = 5'b00_0_0_0;
                                 {im_cs, im_rd, im_wr} = 3'b0_0_0;
                 {D_En, DA_sel, T_Sel, HILO_ld, Y_Sel} = 9'b0_00_00_0_000;
                                 {dm_cs, dm_rd, dm_wr} = 3'b0_0_0;
                                 {io_cs, io_rd, io_wr} = 3'b0_0_0;
                                       {SP_Sel, S_Sel} = 2'b0_0;
              #1 {nsi, nsc, nsv, nsn, nsz} = {psi, c, v, n, z};
                 state = WB_alu;
				end
				
			SUBU:
				begin
				  // control word assignments: 
				  @(negedge sys_clk)
				  // control word assignments: ALU_Out <- $rs - $rt
				  @(negedge sys_clk)
                                            int_ack=0;	 FS=5'h05;
                        {pc_sel, pc_ld, pc_inc, ir_ld} = 5'b00_0_0_0;
                                 {im_cs, im_rd, im_wr} = 3'b0_0_0;
                 {D_En, DA_sel, T_Sel, HILO_ld, Y_Sel} = 9'b0_00_00_0_000;
                                 {dm_cs, dm_rd, dm_wr} = 3'b0_0_0;
                                 {io_cs, io_rd, io_wr} = 3'b0_0_0;
                                       {SP_Sel, S_Sel} = 2'b0_0;
              #1 {nsi, nsc, nsv, nsn, nsz} = {psi, c, v, n, z};
                 state = WB_alu;
				end
				
			AND:
				begin
				  // control word assignments: ALU_Out <- $rs & $rt
				  @(negedge sys_clk)
                                            int_ack=0;	 FS=5'h08;
                        {pc_sel, pc_ld, pc_inc, ir_ld} = 5'b00_0_0_0;
                                 {im_cs, im_rd, im_wr} = 3'b0_0_0;
                 {D_En, DA_sel, T_Sel, HILO_ld, Y_Sel} = 9'b0_00_00_0_000;
                                 {dm_cs, dm_rd, dm_wr} = 3'b0_0_0;
                                 {io_cs, io_rd, io_wr} = 3'b0_0_0;
                                       {SP_Sel, S_Sel} = 2'b0_0;
              #1 {nsi, nsc, nsv, nsn, nsz} = {psi, psc, psv, psn, psz};
                 state = WB_alu;
				end

			OR:
				begin
				  // control word assignments: ALU_Out <- $rs | $rt
				  @(negedge sys_clk)
                                            int_ack=0;	 FS=5'h09;
                        {pc_sel, pc_ld, pc_inc, ir_ld} = 5'b00_0_0_0;
                                 {im_cs, im_rd, im_wr} = 3'b0_0_0;
                 {D_En, DA_sel, T_Sel, HILO_ld, Y_Sel} = 9'b0_00_00_0_000;
                                 {dm_cs, dm_rd, dm_wr} = 3'b0_0_0;
                                 {io_cs, io_rd, io_wr} = 3'b0_0_0;
                                       {SP_Sel, S_Sel} = 2'b0_0;
              #1 {nsi, nsc, nsv, nsn, nsz} = {psi, psc, psv, psn, psz};
                 state = WB_alu;
				end
				
			XOR:
				begin
				  // control word assignments: ALU_Out <- $rs ^ $rt
				  @(negedge sys_clk)
                                            int_ack=0;	 FS=5'h0A;
                        {pc_sel, pc_ld, pc_inc, ir_ld} = 5'b00_0_0_0;
                                 {im_cs, im_rd, im_wr} = 3'b0_0_0;
                 {D_En, DA_sel, T_Sel, HILO_ld, Y_Sel} = 9'b0_00_00_0_000;
                                 {dm_cs, dm_rd, dm_wr} = 3'b0_0_0;
                                 {io_cs, io_rd, io_wr} = 3'b0_0_0;
                                       {SP_Sel, S_Sel} = 2'b0_0;
              #1 {nsi, nsc, nsv, nsn, nsz} = {psi, psc, psv, psn, psz};
                 state = WB_alu;
				end
				
			NOR:
				begin
				  // control word assignments: ALU_Out <- ~($rs | $rt)
				  @(negedge sys_clk)
                                            int_ack=0;	 FS=5'h0B;
                        {pc_sel, pc_ld, pc_inc, ir_ld} = 5'b00_0_0_0;
                                 {im_cs, im_rd, im_wr} = 3'b0_0_0;
                 {D_En, DA_sel, T_Sel, HILO_ld, Y_Sel} = 9'b0_00_00_0_000;
                                 {dm_cs, dm_rd, dm_wr} = 3'b0_0_0;
                                 {io_cs, io_rd, io_wr} = 3'b0_0_0;
                                       {SP_Sel, S_Sel} = 2'b0_0;
              #1 {nsi, nsc, nsv, nsn, nsz} = {psi, psc, psv, psn, psz};
                 state = WB_alu;
				end
				
			SLT:
				begin
				  // control word assignments: ALU_Out <- $rs < $rt ? 1 : 0
				  @(negedge sys_clk)
                                            int_ack=0;	 FS=5'h06;
                        {pc_sel, pc_ld, pc_inc, ir_ld} = 5'b00_0_0_0;
                                 {im_cs, im_rd, im_wr} = 3'b0_0_0;
                 {D_En, DA_sel, T_Sel, HILO_ld, Y_Sel} = 9'b0_00_00_0_000;
                                 {dm_cs, dm_rd, dm_wr} = 3'b0_0_0;
                                 {io_cs, io_rd, io_wr} = 3'b0_0_0;
                                       {SP_Sel, S_Sel} = 2'b0_0;
              #1 {nsi, nsc, nsv, nsn, nsz} = {psi, c, v, n, z};
                 state = WB_alu;
				end
				
			SLTU:
				begin
				  // control word assignments: ALU_Out <- $rs < $rt ? 1 : 0
				  @(negedge sys_clk)
                                            int_ack=0;	 FS=5'h07;
                        {pc_sel, pc_ld, pc_inc, ir_ld} = 5'b00_0_0_0;
                                 {im_cs, im_rd, im_wr} = 3'b0_0_0;
                 {D_En, DA_sel, T_Sel, HILO_ld, Y_Sel} = 9'b0_00_00_0_000;
                                 {dm_cs, dm_rd, dm_wr} = 3'b0_0_0;
                                 {io_cs, io_rd, io_wr} = 3'b0_0_0;
                                       {SP_Sel, S_Sel} = 2'b0_0;
              #1 {nsi, nsc, nsv, nsn, nsz} = {psi, c, v, n, z};
                 state = WB_alu;
				end
            
         BREAK:
				begin
				  $display("BREAK INSTRUCTION FETCHED %t",$time);
				  // control word assignments for "deasserting" everything
				  @(negedge sys_clk)
                                            int_ack=0;	 FS=5'h00;
                        {pc_sel, pc_ld, pc_inc, ir_ld} = 5'b00_0_0_0;
                                 {im_cs, im_rd, im_wr} = 3'b0_0_0;
                 {D_En, DA_sel, T_Sel, HILO_ld, Y_Sel} = 9'b0_00_00_0_000; 	
                                 {dm_cs, dm_rd, dm_wr} = 3'b0_0_0; 								
                                 {io_cs, io_rd, io_wr} = 3'b0_0_0;
                                       {SP_Sel, S_Sel} = 2'b0_0;
              #1 {nsi, nsc, nsv, nsn, nsz} = {psi, psc, psv, psn, psz};
				  $display(" R E G I S T E R ' S  A F T E R  B R E A K");
				  $display(" ");
				  Dump_Registers; // task to output MIPS RegFile
				  $display(" ");
				  $display("time=%t M[3F0]=%h", $time, {CPU_Test_Module.DM.Mem[12'h3F0],
																    CPU_Test_Module.DM.Mem[12'h3F1],
																    CPU_Test_Module.DM.Mem[12'h3F2],
																    CPU_Test_Module.DM.Mem[12'h3F3]});
              $display(" ");
              Dump_Mem;
              $display(" ");
				  $finish;                              
				end
 
			SETIE:
				begin
				  // control word assignments: psi <- 1'b1
				  @(negedge sys_clk)
                                            int_ack=0;	 FS=5'h0;
                        {pc_sel, pc_ld, pc_inc, ir_ld} = 5'b00_0_0_0;
                                 {im_cs, im_rd, im_wr} = 3'b0_0_0;
                 {D_En, DA_sel, T_Sel, HILO_ld, Y_Sel} = 9'b0_00_00_0_000;
                                 {dm_cs, dm_rd, dm_wr} = 3'b0_0_0;
                                 {io_cs, io_rd, io_wr} = 3'b0_0_0;
                                       {SP_Sel, S_Sel} = 2'b0_0;
              #1 {nsi, nsc, nsv, nsn, nsz} = {1'b1, psc, psv, psn, psz};
                 state = FETCH;
				end
            
   /***************************************************************************
    ****************          I-type   Instruction           ******************
    ***************************************************************************/   
         J:
            begin
				  // ctrl word assignments for PC <- PC + signext(IR[25:0])<<2
				  @(negedge sys_clk)
                                            int_ack=0;	 FS=5'h00;
                        {pc_sel, pc_ld, pc_inc, ir_ld} = 5'b01_1_0_0;
                                 {im_cs, im_rd, im_wr} = 3'b0_0_0;
                 {D_En, DA_sel, T_Sel, HILO_ld, Y_Sel} = 9'b0_00_00_0_100; 
                                 {dm_cs, dm_rd, dm_wr} = 3'b0_0_0; 							
                                 {io_cs, io_rd, io_wr} = 3'b0_0_0;
                                       {SP_Sel, S_Sel} = 2'b0_0;
              #1 {nsi, nsc, nsv, nsn, nsz} = {psi, psc, psv, psn, psz};
                 state = FETCH;
				end
             
         JAL: 
            begin
				  // ctrl word assignments for PC <- PC + signext(IR[25:0])<<2
              //                         R[ra]<- PC
				  @(negedge sys_clk)
                                            int_ack=0;	 FS=5'h00;
                        {pc_sel, pc_ld, pc_inc, ir_ld} = 5'b01_1_0_0;
                                 {im_cs, im_rd, im_wr} = 3'b0_0_0;
                 {D_En, DA_sel, T_Sel, HILO_ld, Y_Sel} = 9'b1_10_00_0_100; 	
                                 {dm_cs, dm_rd, dm_wr} = 3'b0_0_0; 								
                                 {io_cs, io_rd, io_wr} = 3'b0_0_0;
                                       {SP_Sel, S_Sel} = 2'b0_0;
              #1 {nsi, nsc, nsv, nsn, nsz} = {psi, psc, psv, psn, psz};
                 state = FETCH;
				end
 
         BEQ:
            begin
               // ctrl word assignments for AluOut <- $rs - $rt
				  @(negedge sys_clk)
                                             int_ack=0;   FS=5'h04;
                         {pc_sel, pc_ld, pc_inc, ir_ld} = 5'b00_0_0_0;
                                  {im_cs, im_rd, im_wr} = 3'b0_0_0;
                  {D_En, DA_sel, T_Sel, HILO_ld, Y_Sel} = 9'b0_00_00_0_000; 	
                                  {dm_cs, dm_rd, dm_wr} = 3'b0_0_0; 								
              #1  {nsi, nsc, nsv, nsn, nsz} = {psi, c, v, n, z};
                  state = BEQ_2;    
				end
         BEQ_2:
            begin
               // ctrl word assignments for if(z==1), PC <- PC+signext(IR[15:0])<<2
                                             int_ack=0;   FS=5'h00;
                  if(psz == 1) // rs - rt == 0
                         {pc_sel, pc_ld, pc_inc, ir_ld} = 5'b10_1_0_0;
                  else
                         {pc_sel, pc_ld, pc_inc, ir_ld} = 5'b00_0_0_0;
                                  {im_cs, im_rd, im_wr} = 3'b0_0_0;
                  {D_En, DA_sel, T_Sel, HILO_ld, Y_Sel} = 9'b0_00_00_0_000; 	
                                  {dm_cs, dm_rd, dm_wr} = 3'b0_0_0; 							
              #1    {nsi, nsc, nsv, nsn, nsz} = {psi, psc, psv, psn, psz};
                  state = FETCH;
            end
            
         BNE:
            begin
               // ctrl word assignments for AluOut <- $rs - $rt
              @(negedge sys_clk)
                                             int_ack=0;   FS=5'h04;
                         {pc_sel, pc_ld, pc_inc, ir_ld} = 5'b00_0_0_0;
                                  {im_cs, im_rd, im_wr} = 3'b0_0_0;
                  {D_En, DA_sel, T_Sel, HILO_ld, Y_Sel} = 9'b0_00_00_0_000; 	
                                  {dm_cs, dm_rd, dm_wr} = 3'b0_0_0; 								
              #1  {nsi, nsc, nsv, nsn, nsz} = {psi, c, v, n, z};
                  state = BNE_2;   
				end
         BNE_2:
            begin
				  // ctrl word assignments for if(z!=1), PC <- PC + signext(IR[15:0])<<2
				  @(negedge sys_clk)
                                             int_ack=0;   FS=5'h00;
                  if(psz == 0) // rs - rt != 0
                         {pc_sel, pc_ld, pc_inc, ir_ld} = 5'b10_1_0_0;
                  else
                         {pc_sel, pc_ld, pc_inc, ir_ld} = 5'b00_0_0_0;
                                  {im_cs, im_rd, im_wr} = 3'b0_0_0;
                  {D_En, DA_sel, T_Sel, HILO_ld, Y_Sel} = 9'b0_00_00_0_000; 
                                  {dm_cs, dm_rd, dm_wr} = 3'b0_0_0; 								
              #1  {nsi, nsc, nsv, nsn, nsz} = {psi, psc, psv, psn, psz};
                  state = FETCH;
				end
          
         BLEZ:
            begin
               // ctrl word assignments for RS <- $rs, RT <- $zero
				  @(negedge sys_clk)
                                             int_ack=0;   FS=5'h04;
                         {pc_sel, pc_ld, pc_inc, ir_ld} = 5'b00_0_0_0;
                                  {im_cs, im_rd, im_wr} = 3'b0_0_0;
                  {D_En, DA_sel, T_Sel, HILO_ld, Y_Sel} = 9'b0_00_00_0_000; 	
                                  {dm_cs, dm_rd, dm_wr} = 3'b0_0_0; 								
              #1  {nsi, nsc, nsv, nsn, nsz} = {psi, c, v, n, z};
                  state = BLEZ_2;
				end
         BLEZ_2:
            begin
				  // ctrl word assignments for if(RS<=0), PC <- PC+signext(IR[15:0])<<2
              @(negedge sys_clk)
                                             int_ack=0;   FS=5'h00;
                  if(psn == 1 || psz == 1) 
                         {pc_sel, pc_ld, pc_inc, ir_ld} = 5'b10_1_0_0;
                  else
                         {pc_sel, pc_ld, pc_inc, ir_ld} = 5'b00_0_0_0;
                                  {im_cs, im_rd, im_wr} = 3'b0_0_0;
                  {D_En, DA_sel, T_Sel, HILO_ld, Y_Sel} = 9'b0_00_00_0_000; 	
                                  {dm_cs, dm_rd, dm_wr} = 3'b0_0_0; 								
              #1  {nsi, nsc, nsv, nsn, nsz} = {psi, psc, psv, psn, psz};
                  state = FETCH;
				end  
            
         BGTZ:
            begin
				  // ctrl word assignments for if(RS >= 0), PC <- PC + signext(IR[15:0])<<2
				  @(negedge sys_clk)
                                             int_ack=0;   FS=5'h04; 
                         {pc_sel, pc_ld, pc_inc, ir_ld} = 5'b00_0_0_0;
                                  {im_cs, im_rd, im_wr} = 3'b0_0_0;
                  {D_En, DA_sel, T_Sel, HILO_ld, Y_Sel} = 9'b0_00_00_0_000; 	
                                  {dm_cs, dm_rd, dm_wr} = 3'b0_0_0; 
              #1  {nsi, nsc, nsv, nsn, nsz} = {psi, c, v, n, z};
                  state = BGTZ_2;
				end
         BGTZ_2:
            begin
				  // ctrl word assignments for if(RS >= 0), PC <- PC + signext(IR[15:0])<<2
				  @(negedge sys_clk)
                                             int_ack=0;   FS=5'h00;
                  if(psn == 0 || psz == 1) 
                         {pc_sel, pc_ld, pc_inc, ir_ld} = 5'b10_1_0_0;
                 else
                         {pc_sel, pc_ld, pc_inc, ir_ld} = 5'b00_0_0_0;
                                  {im_cs, im_rd, im_wr} = 3'b0_0_0;
                  {D_En, DA_sel, T_Sel, HILO_ld, Y_Sel} = 9'b0_00_00_0_000;
                                  {dm_cs, dm_rd, dm_wr} = 3'b0_0_0; 							
              #1  {nsi, nsc, nsv, nsn, nsz} = {psi, psc, psv, psn, psz};
                  state = WB_imm;
				end

         ADDI: 
            begin
				  // control word assignments for ALU_Out <- $rs + $rt(se_16) 
				  @(negedge sys_clk)
                                            int_ack=0;	 FS=5'h02;
                        {pc_sel, pc_ld, pc_inc, ir_ld} = 5'b00_0_0_0;
                                 {im_cs, im_rd, im_wr} = 3'b0_0_0;
                 {D_En, DA_sel, T_Sel, HILO_ld, Y_Sel} = 9'b0_00_00_0_000; 	
                                 {dm_cs, dm_rd, dm_wr} = 3'b0_0_0; 								
                                 {io_cs, io_rd, io_wr} = 3'b0_0_0;
                                       {SP_Sel, S_Sel} = 2'b0_0;
              #1 {nsi, nsc, nsv, nsn, nsz} = {psi, c, v, n, z};
                 state = WB_imm;
				end
            
         SLTI: 
            begin
				  // ctrl word assignments for ALU_Out <- if($rs < $rt(se_16)) 1:0
				  @(negedge sys_clk)
                                            int_ack=0;	 FS=5'h06;
                        {pc_sel, pc_ld, pc_inc, ir_ld} = 5'b00_0_0_0;
                                 {im_cs, im_rd, im_wr} = 3'b0_0_0;
                 {D_En, DA_sel, T_Sel, HILO_ld, Y_Sel} = 9'b0_00_00_0_000; 
                                 {dm_cs, dm_rd, dm_wr} = 3'b0_0_0; 								
                                 {io_cs, io_rd, io_wr} = 3'b0_0_0;
                                       {SP_Sel, S_Sel} = 2'b0_0;
              #1 {nsi, nsc, nsv, nsn, nsz} = {psi, c, v, n, z};
                 state = WB_imm;
				end
            
          SLTIU: 
            begin
				  // ctrl word assignments for ALU_Out <- if($rs < $rt(se_16)) 1:0
				  @(negedge sys_clk)
                                            int_ack=0;	 FS=5'h07;
                        {pc_sel, pc_ld, pc_inc, ir_ld} = 5'b00_0_0_0;
                                 {im_cs, im_rd, im_wr} = 3'b0_0_0;
                 {D_En, DA_sel, T_Sel, HILO_ld, Y_Sel} = 9'b0_00_00_0_000; 	
                                 {dm_cs, dm_rd, dm_wr} = 3'b0_0_0; 							
                                 {io_cs, io_rd, io_wr} = 3'b0_0_0;
                                       {SP_Sel, S_Sel} = 2'b0_0;
              #1 {nsi, nsc, nsv, nsn, nsz} = {psi, c, v, n, z};
                 state = WB_imm;
				end
            
          ANDI: 
            begin
				  // ctrl word assignments for ALU_Out <- $rs & $rt(se_16)
				  @(negedge sys_clk)
                                            int_ack=0;	 FS=5'h16;
                        {pc_sel, pc_ld, pc_inc, ir_ld} = 5'b00_0_0_0;
                                 {im_cs, im_rd, im_wr} = 3'b0_0_0;
                 {D_En, DA_sel, T_Sel, HILO_ld, Y_Sel} = 9'b0_00_00_0_000; 
                                 {dm_cs, dm_rd, dm_wr} = 3'b0_0_0; 							
                                 {io_cs, io_rd, io_wr} = 3'b0_0_0;
                                       {SP_Sel, S_Sel} = 2'b0_0;
              #1 {nsi, nsc, nsv, nsn, nsz} = {psi, psc, psv, psn, psz};
                 state = WB_imm;
				end
            
          ORI: 
            begin
				  // ctrl word assignments for ALU_Out <- $rs | {16'h0, RT[15:0]}
				  @(negedge sys_clk)
                                            int_ack=0;	 FS=5'h17;
                        {pc_sel, pc_ld, pc_inc, ir_ld} = 5'b00_0_0_0;
                                 {im_cs, im_rd, im_wr} = 3'b0_0_0;
                 {D_En, DA_sel, T_Sel, HILO_ld, Y_Sel} = 9'b0_00_00_0_000; 
                                 {dm_cs, dm_rd, dm_wr} = 3'b0_0_0; 								
                                 {io_cs, io_rd, io_wr} = 3'b0_0_0;
                                       {SP_Sel, S_Sel} = 2'b0_0;
              #1 {nsi, nsc, nsv, nsn, nsz} = {psi, psc, psv, psn, psz};
                 state = WB_imm;
				end
            
          XORI: 
            begin
				  // ctrl word assignments for ALU_Out <- $rs ^ {16'h0, RT[15:0]}
				  @(negedge sys_clk)
                                            int_ack=0;	 FS=5'h18;
                        {pc_sel, pc_ld, pc_inc, ir_ld} = 5'b00_0_0_0;
                                 {im_cs, im_rd, im_wr} = 3'b0_0_0;
                 {D_En, DA_sel, T_Sel, HILO_ld, Y_Sel} = 9'b0_00_00_0_000;
                                 {dm_cs, dm_rd, dm_wr} = 3'b0_0_0; 							
                                 {io_cs, io_rd, io_wr} = 3'b0_0_0;
                                       {SP_Sel, S_Sel} = 2'b0_0;
              #1 {nsi, nsc, nsv, nsn, nsz} = {psi, psc, psv, psn, psz};
                 state = WB_imm;
				end
            
          LUI: 
				begin
				  // control word assignments for ALU_Out <- { RT[15:0], 16'h0}
				  @(negedge sys_clk)
                                            int_ack=0;	 FS=5'h19;
                        {pc_sel, pc_ld, pc_inc, ir_ld} = 5'b00_0_0_0;
                                 {im_cs, im_rd, im_wr} = 3'b0_0_0;
                 {D_En, DA_sel, T_Sel, HILO_ld, Y_Sel} = 9'b0_00_00_0_000;
                                 {dm_cs, dm_rd, dm_wr} = 3'b0_0_0; 								
                                 {io_cs, io_rd, io_wr} = 3'b0_0_0;
                                       {SP_Sel, S_Sel} = 2'b0_0;
              #1 {nsi, nsc, nsv, nsn, nsz} = {psi, psc, psv, psn, psz};
                 state = WB_imm;
				end
            
          LW: 
            begin
				  // control word assignments for ALU_Out <- $rs + $rt(se_16) "EA calc"
				  @(negedge sys_clk)
                                            int_ack=0;	 FS=5'h02;
                        {pc_sel, pc_ld, pc_inc, ir_ld} = 5'b00_0_0_0;
                                 {im_cs, im_rd, im_wr} = 3'b0_0_0;
                 {D_En, DA_sel, T_Sel, HILO_ld, Y_Sel} = 9'b0_00_00_0_000; 
                                 {dm_cs, dm_rd, dm_wr} = 3'b0_0_0; 								
                                 {io_cs, io_rd, io_wr} = 3'b0_0_0;
                                       {SP_Sel, S_Sel} = 2'b0_0;
              #1 {nsi, nsc, nsv, nsn, nsz} = {psi, c, v, n, z};
                 state = LW_2;
				end
          LW_2: 
            begin
				  // control word assignments for D_in <- M[ALU_Out]
				  @(negedge sys_clk)
                                            int_ack=0;	 FS=5'h00;
                        {pc_sel, pc_ld, pc_inc, ir_ld} = 5'b00_0_0_0;
                                 {im_cs, im_rd, im_wr} = 3'b0_0_0;
                 {D_En, DA_sel, T_Sel, HILO_ld, Y_Sel} = 9'b0_00_00_0_000; 
                                 {dm_cs, dm_rd, dm_wr} = 3'b1_1_0; 							
                                 {io_cs, io_rd, io_wr} = 3'b0_0_0;
                                       {SP_Sel, S_Sel} = 2'b0_0;
              #1 {nsi, nsc, nsv, nsn, nsz} = {psi, psc, psv, psn, psz};
                 state = WB_Din;
				end
            
			 SW: 
				begin
				  // control word assignments for ALU_Out <- $rs + $rt(se_16) "EA calc"
				  @(negedge sys_clk)
                                            int_ack=0;	 FS=5'h02;
                        {pc_sel, pc_ld, pc_inc, ir_ld} = 5'b00_0_0_0;
                                 {im_cs, im_rd, im_wr} = 3'b0_0_0;
                 {D_En, DA_sel, T_Sel, HILO_ld, Y_Sel} = 9'b0_00_00_0_000; 
                                 {dm_cs, dm_rd, dm_wr} = 3'b0_0_0; 								
                                 {io_cs, io_rd, io_wr} = 3'b0_0_0;
                                       {SP_Sel, S_Sel} = 2'b0_0;
              #1 {nsi, nsc, nsv, nsn, nsz} = {psi, c, v, n, z};
                 state = WB_mem;
				end
      
          WB_Din: 
            begin
				  // control word assignments for R[rt] <- D_in[M[ALUout]]
				  @(negedge sys_clk)	
                                            int_ack=0;	 FS=5'h00;
                        {pc_sel, pc_ld, pc_inc, ir_ld} = 5'b00_0_0_0;
                                 {im_cs, im_rd, im_wr} = 3'b0_0_0;
                 {D_En, DA_sel, T_Sel, HILO_ld, Y_Sel} = 9'b1_01_00_0_011; 
                                 {dm_cs, dm_rd, dm_wr} = 3'b0_0_0; 								
                                 {io_cs, io_rd, io_wr} = 3'b0_0_0;
                                       {SP_Sel, S_Sel} = 2'b0_0;
              #1 {nsi, nsc, nsv, nsn, nsz} = {psi, psc, psv, psn, psz};
                 state = FETCH;
				end
            
			 WB_alu: 
				begin
				  // control word assignments for R[rd] <- ALU_Out
				  @(negedge sys_clk)
                                            int_ack=0;	 FS=5'h00;
                        {pc_sel, pc_ld, pc_inc, ir_ld} = 5'b00_0_0_0;
                                 {im_cs, im_rd, im_wr} = 3'b0_0_0;
                 {D_En, DA_sel, T_Sel, HILO_ld, Y_Sel} = 9'b1_00_00_0_000; 
                                 {dm_cs, dm_rd, dm_wr} = 3'b0_0_0; 								
                                 {io_cs, io_rd, io_wr} = 3'b0_0_0;
                                       {SP_Sel, S_Sel} = 2'b0_0;
              #1 {nsi, nsc, nsv, nsn, nsz} = {psi, psc, psv, psn, psz};
                 state = FETCH;
				end

			 WB_imm: 
				begin
				  // control word assignments for R[rt] <- ALU_Out
				  @(negedge sys_clk)
                                            int_ack=0;	 FS=5'h00;
                        {pc_sel, pc_ld, pc_inc, ir_ld} = 5'b00_0_0_0;
                                 {im_cs, im_rd, im_wr} = 3'b0_0_0;
                 {D_En, DA_sel, T_Sel, HILO_ld, Y_Sel} = 9'b1_01_00_0_000; 
                                 {dm_cs, dm_rd, dm_wr} = 3'b0_0_0; 								
                                 {io_cs, io_rd, io_wr} = 3'b0_0_0;
                                       {SP_Sel, S_Sel} = 2'b0_0;
              #1 {nsi, nsc, nsv, nsn, nsz} = {psi, psc, psv, psn, psz};
                 state = FETCH;
				end

			 WB_mem: 
				begin
				  // control word assignments for M[ ALU_Out(rs+se_16)] <- RT(rt)
				  @(negedge sys_clk)
                                            int_ack=0;	 FS=5'h00;
                        {pc_sel, pc_ld, pc_inc, ir_ld} = 5'b00_0_0_0;
                                 {im_cs, im_rd, im_wr} = 3'b0_0_0;
                 {D_En, DA_sel, T_Sel, HILO_ld, Y_Sel} = 9'b0_00_00_0_000; 
                                 {dm_cs, dm_rd, dm_wr} = 3'b1_0_1; 						
                                 {io_cs, io_rd, io_wr} = 3'b0_0_0;
                                       {SP_Sel, S_Sel} = 2'b0_0;
              #1 {nsi, nsc, nsv, nsn, nsz} = {psi, psc, psv, psn, psz};
                 state = FETCH;
				end
            
   /***************************************************************************
    ****************          E-key   Instruction           ******************
    ***************************************************************************/
         INPUT: 
				begin
				  // control word assignments for ALU_Out <- $rs + $rt(se_16) "EA calc"
				  @(negedge sys_clk)
                                            int_ack=0;	 FS=5'h02;
                        {pc_sel, pc_ld, pc_inc, ir_ld} = 5'b00_0_0_0;
                                 {im_cs, im_rd, im_wr} = 3'b0_0_0;
                 {D_En, DA_sel, T_Sel, HILO_ld, Y_Sel} = 9'b0_00_00_0_000; 
                                 {dm_cs, dm_rd, dm_wr} = 3'b0_0_0; 						
                                 {io_cs, io_rd, io_wr} = 3'b0_0_0;
                                       {SP_Sel, S_Sel} = 2'b0_0;
              #1 {nsi, nsc, nsv, nsn, nsz} = {psi, c, v, n, z};
                 state = INPUT_2;
				end
         INPUT_2: 
				begin
				  // control word assignments for D_in <- IOM[ALU_Out]
				  @(negedge sys_clk)
                                            int_ack=0;	 FS=5'h00;
                        {pc_sel, pc_ld, pc_inc, ir_ld} = 5'b00_0_0_0;
                                 {im_cs, im_rd, im_wr} = 3'b0_0_0;
                 {D_En, DA_sel, T_Sel, HILO_ld, Y_Sel} = 9'b0_00_00_0_000; 
                                 {dm_cs, dm_rd, dm_wr} = 3'b0_0_0; 
                                 {io_cs, io_rd, io_wr} = 3'b1_1_0;
                                       {SP_Sel, S_Sel} = 2'b0_0;
              #1 {nsi, nsc, nsv, nsn, nsz} = {psi, psc, psv, psn, psz};
                 state = WB_Din;
				end
            
         OUTPUT: 
				begin
				  // control word assignments for ALU_Out <- $rs + $rt(se_16) "EA calc"
				  @(negedge sys_clk)
                                            int_ack=0;	 FS=5'h02;
                        {pc_sel, pc_ld, pc_inc, ir_ld} = 5'b00_0_0_0;
                                 {im_cs, im_rd, im_wr} = 3'b0_0_0;
                 {D_En, DA_sel, T_Sel, HILO_ld, Y_Sel} = 9'b0_00_00_0_000; 
                                 {dm_cs, dm_rd, dm_wr} = 3'b0_0_0; 						
                                 {io_cs, io_rd, io_wr} = 3'b0_0_0;
                                       {SP_Sel, S_Sel} = 2'b0_0;
              #1 {nsi, nsc, nsv, nsn, nsz} = {psi, c, v, n, z};
                 state = OUTPUT_2;
				end
         OUTPUT_2: 
				begin
				  // control word assignments for IOM[ALU_Out] <- D_in
				  @(negedge sys_clk)
                                            int_ack=0;	 FS=5'h00;
                        {pc_sel, pc_ld, pc_inc, ir_ld} = 5'b00_0_0_0;
                                 {im_cs, im_rd, im_wr} = 3'b0_0_0;
                 {D_En, DA_sel, T_Sel, HILO_ld, Y_Sel} = 9'b0_00_00_0_000; 
                                 {dm_cs, dm_rd, dm_wr} = 3'b0_0_0; 						
                                 {io_cs, io_rd, io_wr} = 3'b1_0_1;
                                       {SP_Sel, S_Sel} = 2'b0_0;
              #1 {nsi, nsc, nsv, nsn, nsz} = {psi, psc, psv, psn, psz};
                 state = FETCH;
				end
          
         RETI: 
				begin
              // Pass $sp value to ALU_Out as an Effective Address
				  // control word assignments for ALU_Out <- RS($sp)
				  @(negedge sys_clk)
                                            int_ack=0;	 FS=5'h00;
                        {pc_sel, pc_ld, pc_inc, ir_ld} = 5'b00_0_0_0;
                                 {im_cs, im_rd, im_wr} = 3'b0_0_0;
                 {D_En, DA_sel, T_Sel, HILO_ld, Y_Sel} = 9'b0_00_00_0_000; 
                                 {dm_cs, dm_rd, dm_wr} = 3'b0_0_0; 						
                                 {io_cs, io_rd, io_wr} = 3'b0_0_0;
                                       {SP_Sel, S_Sel} = 2'b0_0;
              #1 {nsi, nsc, nsv, nsn, nsz} = {psi, psc, psv, psn, psz};
                 state = RETI_2;
				end
          RETI_2: 
				begin
              // POP flag status to D_in
				  // control word assignments for D_in <- DM[ALU_Out($sp)]
				  @(negedge sys_clk)
                                            int_ack=0;	 FS=5'h00;
                        {pc_sel, pc_ld, pc_inc, ir_ld} = 5'b00_0_0_0;
                                 {im_cs, im_rd, im_wr} = 3'b0_0_0;
                 {D_En, DA_sel, T_Sel, HILO_ld, Y_Sel} = 9'b0_00_00_0_000; 
                                 {dm_cs, dm_rd, dm_wr} = 3'b1_1_0; 						
                                 {io_cs, io_rd, io_wr} = 3'b0_0_0;
                                       {SP_Sel, S_Sel} = 2'b0_0;
              #1 {nsi, nsc, nsv, nsn, nsz} = {psi, psc, psv, psn, psz};
                 state = RETI_3;
				end
         RETI_3: 
				begin
              // POP flag status from D_in to current flag status
              //     and increment $sp
				  // control word assignments for flags <- D_in[4:0]
              //                              ALU_Out <- ALU_Out($sp)+4                    
				  @(negedge sys_clk)
                                            int_ack=0;	 FS=5'h11;
                        {pc_sel, pc_ld, pc_inc, ir_ld} = 5'b00_0_0_0;
                                 {im_cs, im_rd, im_wr} = 3'b0_0_0;
                 {D_En, DA_sel, T_Sel, HILO_ld, Y_Sel} = 9'b0_00_00_0_000; 
                                 {dm_cs, dm_rd, dm_wr} = 3'b0_0_0; 						
                                 {io_cs, io_rd, io_wr} = 3'b0_0_0;
                                       {SP_Sel, S_Sel} = 2'b0_1;
              #1 {nsi, nsc, nsv, nsn, nsz} = {sp_flags_in};
                 state = RETI_4;
				end
          RETI_4: 
				begin
              // POP Returning Address(ra) to D_in before load it to PC
              //     and increment $sp
				  // control word assignments for D_in <- DM[ALU_Out($sp+4)]
              //                              ALU_Out <- ALU_Out($sp+4)+4 
				  @(negedge sys_clk)
                                            int_ack=0;	 FS=5'h11;
                        {pc_sel, pc_ld, pc_inc, ir_ld} = 5'b00_0_0_0;
                                 {im_cs, im_rd, im_wr} = 3'b0_0_0;
                 {D_En, DA_sel, T_Sel, HILO_ld, Y_Sel} = 9'b0_00_00_0_000; 
                                 {dm_cs, dm_rd, dm_wr} = 3'b1_1_0; 						
                                 {io_cs, io_rd, io_wr} = 3'b0_0_0;
                                       {SP_Sel, S_Sel} = 2'b0_1;
              #1 {nsi, nsc, nsv, nsn, nsz} = {psi, psc, psv, psn, psz};
                 state = RETI_5;
				end
         RETI_5: 
				begin
              // Load Return Address from Memory to PC register
              //     and hold the $sp
				  // control word assignments for PC <- D_in(PC),
              //                              ALU_Out <- ALU_Out($sp+8)
				  @(negedge sys_clk)
                                            int_ack=0;	 FS=5'h00;
                        {pc_sel, pc_ld, pc_inc, ir_ld} = 5'b00_1_0_0;
                                 {im_cs, im_rd, im_wr} = 3'b0_0_0;
                 {D_En, DA_sel, T_Sel, HILO_ld, Y_Sel} = 9'b0_00_00_0_011; 
                                 {dm_cs, dm_rd, dm_wr} = 3'b0_0_0; 						
                                 {io_cs, io_rd, io_wr} = 3'b0_0_0;
                                       {SP_Sel, S_Sel} = 2'b0_1;
              #1 {nsi, nsc, nsv, nsn, nsz} = {psi, psc, psv, psn, psz}; 
                 state = RETI_6;
				end
         RETI_6: 
				begin
              // Write back the current $sp in regfile
				  // control word assignments for R[$sp] <- ALU_Out($sp+8)
				  @(negedge sys_clk)
                                            int_ack=0;	 FS=5'h00;
                        {pc_sel, pc_ld, pc_inc, ir_ld} = 5'b00_0_0_0;
                                 {im_cs, im_rd, im_wr} = 3'b0_0_0;
                 {D_En, DA_sel, T_Sel, HILO_ld, Y_Sel} = 9'b1_11_00_0_000; 
                                 {dm_cs, dm_rd, dm_wr} = 3'b0_0_0; 						
                                 {io_cs, io_rd, io_wr} = 3'b0_0_0;
                                       {SP_Sel, S_Sel} = 2'b0_0;
              #1 {nsi, nsc, nsv, nsn, nsz} = {psi, psc, psv, psn, psz}; 
                 state = FETCH;
				end
          
         ROTL: 
				begin
				  // control word assignments 
				  @(negedge sys_clk)
                                            int_ack=0;	 FS=5'h1A;
                        {pc_sel, pc_ld, pc_inc, ir_ld} = 5'b00_0_0_0;
                                 {im_cs, im_rd, im_wr} = 3'b0_0_0;
                 {D_En, DA_sel, T_Sel, HILO_ld, Y_Sel} = 9'b0_00_00_0_000; 
                                 {dm_cs, dm_rd, dm_wr} = 3'b0_0_0; 						
                                 {io_cs, io_rd, io_wr} = 3'b0_0_0;
                                       {SP_Sel, S_Sel} = 2'b0_0;
              #1 {nsi, nsc, nsv, nsn, nsz} = {psi, c, v, n, z};
                 state = WB_alu;
				end
            
         ROTR: 
				begin
				  // control word assignments  
				  @(negedge sys_clk)
                                            int_ack=0;	 FS=5'h1B;
                        {pc_sel, pc_ld, pc_inc, ir_ld} = 5'b00_0_0_0;
                                 {im_cs, im_rd, im_wr} = 3'b0_0_0;
                 {D_En, DA_sel, T_Sel, HILO_ld, Y_Sel} = 9'b0_00_00_0_000; 
                                 {dm_cs, dm_rd, dm_wr} = 3'b0_0_0; 						
                                 {io_cs, io_rd, io_wr} = 3'b0_0_0;
                                       {SP_Sel, S_Sel} = 2'b0_0;
              #1 {nsi, nsc, nsv, nsn, nsz} = {psi, c, v, n, z};
                 state = WB_alu;
				end
         
         BLT: 
				begin
				  // control word assignments ALU_Out <- $rs - $rt
				  @(negedge sys_clk)
                                            int_ack=0;	 FS=5'h04;
                        {pc_sel, pc_ld, pc_inc, ir_ld} = 5'b00_0_0_0;
                                 {im_cs, im_rd, im_wr} = 3'b0_0_0;
                 {D_En, DA_sel, T_Sel, HILO_ld, Y_Sel} = 9'b0_00_00_0_000; 
                                 {dm_cs, dm_rd, dm_wr} = 3'b0_0_0; 						
                                 {io_cs, io_rd, io_wr} = 3'b0_0_0;
                                       {SP_Sel, S_Sel} = 2'b0_0;
              #1 {nsi, nsc, nsv, nsn, nsz} = {psi, c, v, n, z};
                 state = BLT_2;
				end
         BLT_2: 
				begin
				  // control word assignments 
              //     if(n==1)  PC <- PC + {sign_ext(ir[15:0]),00}
				  @(negedge sys_clk)
                                            int_ack=0;	 FS=5'h00;
              if(psn == 1) 
                        {pc_sel, pc_ld, pc_inc, ir_ld} = 5'b10_1_0_0;
              else
                        {pc_sel, pc_ld, pc_inc, ir_ld} = 5'b00_0_0_0;
                                 {im_cs, im_rd, im_wr} = 3'b0_0_0;
                 {D_En, DA_sel, T_Sel, HILO_ld, Y_Sel} = 9'b0_00_00_0_000; 
                                 {dm_cs, dm_rd, dm_wr} = 3'b0_0_0; 						
                                 {io_cs, io_rd, io_wr} = 3'b0_0_0;
                                       {SP_Sel, S_Sel} = 2'b0_0;
              #1 {nsi, nsc, nsv, nsn, nsz} = {psi, psc, psv, psn, psz};
                 state = FETCH;
				end
         
         BGE: 
				begin
				  // control word assignments ALU_Out <- $rs - $rt
				  @(negedge sys_clk)
                                            int_ack=0;	 FS=5'h04;
                        {pc_sel, pc_ld, pc_inc, ir_ld} = 5'b00_0_0_0;
                                 {im_cs, im_rd, im_wr} = 3'b0_0_0;
                 {D_En, DA_sel, T_Sel, HILO_ld, Y_Sel} = 9'b0_00_00_0_000; 
                                 {dm_cs, dm_rd, dm_wr} = 3'b0_0_0; 						
                                 {io_cs, io_rd, io_wr} = 3'b0_0_0;
                                       {SP_Sel, S_Sel} = 2'b0_0;
              #1 {nsi, nsc, nsv, nsn, nsz} = {psi, c, v, n, z};
                 state = BGE_2;
				end
         BGE_2: 
				begin
				  // control word assignments 
              // if(n==0 || z==1)  PC <- PC + {sign_ext(ir[15:0]),00}
				  @(negedge sys_clk)
                                            int_ack=0;	 FS=5'h00;
              if(psn == 0 || psz == 1) 
                        {pc_sel, pc_ld, pc_inc, ir_ld} = 5'b10_1_0_0;
              else
                        {pc_sel, pc_ld, pc_inc, ir_ld} = 5'b00_0_0_0;
                                 {im_cs, im_rd, im_wr} = 3'b0_0_0;
                 {D_En, DA_sel, T_Sel, HILO_ld, Y_Sel} = 9'b0_00_00_0_000; 
                                 {dm_cs, dm_rd, dm_wr} = 3'b0_0_0; 						
                                 {io_cs, io_rd, io_wr} = 3'b0_0_0;
                                       {SP_Sel, S_Sel} = 2'b0_0;
              #1 {nsi, nsc, nsv, nsn, nsz} = {psi, psc, psv, psn, psz};
                 state = FETCH;
				end
           
         CLR: 
				begin
				  // control word assignments ALU_Out <- 0x0000;
				  @(negedge sys_clk)
                                            int_ack=0;	 FS=5'h13;
                        {pc_sel, pc_ld, pc_inc, ir_ld} = 5'b00_0_0_0;
                                 {im_cs, im_rd, im_wr} = 3'b0_0_0;
                 {D_En, DA_sel, T_Sel, HILO_ld, Y_Sel} = 9'b0_00_00_0_000; 
                                 {dm_cs, dm_rd, dm_wr} = 3'b0_0_0; 						
                                 {io_cs, io_rd, io_wr} = 3'b0_0_0;
                                       {SP_Sel, S_Sel} = 2'b0_0;
              #1 {nsi, nsc, nsv, nsn, nsz} = {psi, psc, psv, psn, psz};
                 state = CLR_2;
				end
         CLR_2: 
				begin
				  // control word assignments R[$rt] <- ALU_out
				  @(negedge sys_clk)
                                            int_ack=0;	 FS=5'h00;
                        {pc_sel, pc_ld, pc_inc, ir_ld} = 5'b00_0_0_0;
                                 {im_cs, im_rd, im_wr} = 3'b0_0_0;
                 {D_En, DA_sel, T_Sel, HILO_ld, Y_Sel} = 9'b1_01_00_0_000; 
                                 {dm_cs, dm_rd, dm_wr} = 3'b0_0_0; 						
                                 {io_cs, io_rd, io_wr} = 3'b0_0_0;
                                       {SP_Sel, S_Sel} = 2'b0_0;
              #1 {nsi, nsc, nsv, nsn, nsz} = {psi, psc, psv, psn, psz};
                 state = FETCH;
				end
            
         DJNZ:
				begin
              // DJNZ is an I-type enhanced where $rs and $rt field
              // should be the same because ALU's FS Dec is using S
              // to decrement, but $rt field is used for writing back
              // to register files32.
				  // control word assignments ALU_Out <- RS-1;
				  @(negedge sys_clk)
                                            int_ack=0;	 FS=5'h10;
                        {pc_sel, pc_ld, pc_inc, ir_ld} = 5'b00_0_0_0;
                                 {im_cs, im_rd, im_wr} = 3'b0_0_0;
                 {D_En, DA_sel, T_Sel, HILO_ld, Y_Sel} = 9'b0_00_00_0_000; 
                                 {dm_cs, dm_rd, dm_wr} = 3'b0_0_0; 						
                                 {io_cs, io_rd, io_wr} = 3'b0_0_0;
                                       {SP_Sel, S_Sel} = 2'b0_0;
              #1 {nsi, nsc, nsv, nsn, nsz} = {psi, c, v, n, z};
                 state = DJNZ_2;
				end
         DJNZ_2: 
				begin
				  // control word assignments R[$rt] <- ALU_Out;
              //                          if(z==0) PC <- PC+IR[15:0]<<2
				  @(negedge sys_clk)
                                            int_ack=0;	 FS=5'h00;
               if(psz==0)
                        {pc_sel, pc_ld, pc_inc, ir_ld} = 5'b10_1_0_0;
               else
                        {pc_sel, pc_ld, pc_inc, ir_ld} = 5'b00_0_0_0;
                                 {im_cs, im_rd, im_wr} = 3'b0_0_0;
                 {D_En, DA_sel, T_Sel, HILO_ld, Y_Sel} = 9'b1_01_00_0_000; 
                                 {dm_cs, dm_rd, dm_wr} = 3'b0_0_0; 						
                                 {io_cs, io_rd, io_wr} = 3'b0_0_0;
                                       {SP_Sel, S_Sel} = 2'b0_0;
              #1 {nsi, nsc, nsv, nsn, nsz} = {psi, psc, psv, psn, psz};
                 state = FETCH;
				end
            
         MOV: 
				begin
              // Move data from R[$rs] to R[$rt]
				  // control word assignments ALU_Out <- R[$rs]
				  @(negedge sys_clk)
                                            int_ack=0;	 FS=5'h00;
                        {pc_sel, pc_ld, pc_inc, ir_ld} = 5'b00_0_0_0;
                                 {im_cs, im_rd, im_wr} = 3'b0_0_0;
                 {D_En, DA_sel, T_Sel, HILO_ld, Y_Sel} = 9'b0_00_00_0_000; 
                                 {dm_cs, dm_rd, dm_wr} = 3'b0_0_0; 						
                                 {io_cs, io_rd, io_wr} = 3'b0_0_0;
                                       {SP_Sel, S_Sel} = 2'b0_0;
              #1 {nsi, nsc, nsv, nsn, nsz} = {psi, psc, psv, psn, psz};
                 state = MOV_2;
				end
         MOV_2: 
				begin
				  // control word assignments R[$rt] <- ALU_out
				  @(negedge sys_clk)
                                            int_ack=0;	 FS=5'h00;
                        {pc_sel, pc_ld, pc_inc, ir_ld} = 5'b00_0_0_0;
                                 {im_cs, im_rd, im_wr} = 3'b0_0_0;
                 {D_En, DA_sel, T_Sel, HILO_ld, Y_Sel} = 9'b1_01_00_0_000; 
                                 {dm_cs, dm_rd, dm_wr} = 3'b0_0_0; 						
                                 {io_cs, io_rd, io_wr} = 3'b0_0_0;
                                       {SP_Sel, S_Sel} = 2'b0_0;
              #1 {nsi, nsc, nsv, nsn, nsz} = {psi, psc, psv, psn, psz};
                 state = FETCH;
				end
           
         NOP: 
				begin
              // No Operation. Nothing change in a clock
				  // control word assignments ALU_Out <- ALU_Out
				  @(negedge sys_clk)
                                            int_ack=0;	 FS=5'h00;
                        {pc_sel, pc_ld, pc_inc, ir_ld} = 5'b00_0_0_0;
                                 {im_cs, im_rd, im_wr} = 3'b0_0_0;
                 {D_En, DA_sel, T_Sel, HILO_ld, Y_Sel} = 9'b0_00_00_0_000; 
                                 {dm_cs, dm_rd, dm_wr} = 3'b0_0_0; 						
                                 {io_cs, io_rd, io_wr} = 3'b0_0_0;
                                       {SP_Sel, S_Sel} = 2'b0_1;
              #1 {nsi, nsc, nsv, nsn, nsz} = {psi, psc, psv, psn, psz};
                 state = FETCH;
				end
            
         PUSH: 
				begin
              // Pre-decrement PUSH DM[--$sp] <- $rt
				  // control word assignments RS <- R[$sp}; RT <- R[$rt]
				  @(negedge sys_clk)
                                            int_ack=0;	 FS=5'h00;
                        {pc_sel, pc_ld, pc_inc, ir_ld} = 5'b00_0_0_0;
                                 {im_cs, im_rd, im_wr} = 3'b0_0_0;
                 {D_En, DA_sel, T_Sel, HILO_ld, Y_Sel} = 9'b0_00_00_0_000; 
                                 {dm_cs, dm_rd, dm_wr} = 3'b0_0_0; 						
                                 {io_cs, io_rd, io_wr} = 3'b0_0_0;
                                       {SP_Sel, S_Sel} = 2'b1_0;
              #1 {nsi, nsc, nsv, nsn, nsz} = {psi, c, v, n, z};
                 state = PUSH_2;
				end
         PUSH_2: 
				begin
				  // control word assignments ALU_Out <- RS(sp)-4; RT <- R[$rt]
				  @(negedge sys_clk)
                                            int_ack=0;	 FS=5'h12;
                        {pc_sel, pc_ld, pc_inc, ir_ld} = 5'b00_0_0_0;
                                 {im_cs, im_rd, im_wr} = 3'b0_0_0;
                 {D_En, DA_sel, T_Sel, HILO_ld, Y_Sel} = 9'b0_00_00_0_000; 
                                 {dm_cs, dm_rd, dm_wr} = 3'b0_0_0; 						
                                 {io_cs, io_rd, io_wr} = 3'b0_0_0;
                                       {SP_Sel, S_Sel} = 2'b0_0;
              #1 {nsi, nsc, nsv, nsn, nsz} = {psi, psc, psv, psn, psz};
                 state = PUSH_3;
				end
         PUSH_3: 
				begin
				  // control word assignments DM[ALU_Out] <- RT(rt);
              //     and save SP pointer  ALU_Out <- ALU_Out($sp-4)
				  @(negedge sys_clk)
                                            int_ack=0;	 FS=5'h00;
                        {pc_sel, pc_ld, pc_inc, ir_ld} = 5'b00_0_0_0;
                                 {im_cs, im_rd, im_wr} = 3'b0_0_0;
                 {D_En, DA_sel, T_Sel, HILO_ld, Y_Sel} = 9'b0_00_00_0_000; 
                                 {dm_cs, dm_rd, dm_wr} = 3'b1_0_1; 						
                                 {io_cs, io_rd, io_wr} = 3'b0_0_0;
                                       {SP_Sel, S_Sel} = 2'b0_1;
              #1 {nsi, nsc, nsv, nsn, nsz} = {psi, psc, psv, psn, psz};
                 state = PUSH_4;
				end
         PUSH_4: 
				begin
				  // control word assignments R[$sp] <- ALU_Out($sp-4)
				  @(negedge sys_clk)
                                            int_ack=0;	 FS=5'h00;
                        {pc_sel, pc_ld, pc_inc, ir_ld} = 5'b00_0_0_0;
                                 {im_cs, im_rd, im_wr} = 3'b0_0_0;
                 {D_En, DA_sel, T_Sel, HILO_ld, Y_Sel} = 9'b1_11_00_0_000; 
                                 {dm_cs, dm_rd, dm_wr} = 3'b0_0_0; 						
                                 {io_cs, io_rd, io_wr} = 3'b0_0_0;
                                       {SP_Sel, S_Sel} = 2'b0_0;
              #1 {nsi, nsc, nsv, nsn, nsz} = {psi, psc, psv, psn, psz};
                 state = FETCH;
				end
         
         POP: 
				begin
              // Post-increment POP   R[rt] <- DM[sp++]
				  // control word assignments RS <- R[$sp]
				  @(negedge sys_clk)
                                            int_ack=0;	 FS=5'h00;
                        {pc_sel, pc_ld, pc_inc, ir_ld} = 5'b00_0_0_0;
                                 {im_cs, im_rd, im_wr} = 3'b0_0_0;
                 {D_En, DA_sel, T_Sel, HILO_ld, Y_Sel} = 9'b0_00_00_0_000; 
                                 {dm_cs, dm_rd, dm_wr} = 3'b0_0_0; 						
                                 {io_cs, io_rd, io_wr} = 3'b0_0_0;
                                       {SP_Sel, S_Sel} = 2'b1_0;
              #1 {nsi, nsc, nsv, nsn, nsz} = {psi, psc, psv, psn, psz};
                 state = POP_2;
				end
         POP_2: 
				begin
				  // control word assignments ALU_Out <- RS(sp)
				  @(negedge sys_clk)
                                            int_ack=0;	 FS=5'h00;
                        {pc_sel, pc_ld, pc_inc, ir_ld} = 5'b00_0_0_0;
                                 {im_cs, im_rd, im_wr} = 3'b0_0_0;
                 {D_En, DA_sel, T_Sel, HILO_ld, Y_Sel} = 9'b0_00_00_0_000; 
                                 {dm_cs, dm_rd, dm_wr} = 3'b0_0_0; 						
                                 {io_cs, io_rd, io_wr} = 3'b0_0_0;
                                       {SP_Sel, S_Sel} = 2'b0_0;
              #1 {nsi, nsc, nsv, nsn, nsz} = {psi, psc, psv, psn, psz};
                 state = POP_3;
				end
         POP_3: 
				begin
				  // control word assignments D_in <- DM[ALU_Out];
              //                          ALU_Out <- ALU_out(sp)
				  @(negedge sys_clk)
                                            int_ack=0;	 FS=5'h00;
                        {pc_sel, pc_ld, pc_inc, ir_ld} = 5'b00_0_0_0;
                                 {im_cs, im_rd, im_wr} = 3'b0_0_0;
                 {D_En, DA_sel, T_Sel, HILO_ld, Y_Sel} = 9'b0_00_00_0_000; 
                                 {dm_cs, dm_rd, dm_wr} = 3'b1_1_0; 						
                                 {io_cs, io_rd, io_wr} = 3'b0_0_0;
                                       {SP_Sel, S_Sel} = 2'b0_1;
              #1 {nsi, nsc, nsv, nsn, nsz} = {psi, psc, psv, psn, psz};
                 state = POP_4;
				end
         POP_4: 
				begin
				  // control word assignments R[rt] <- D_in;
              //                          ALU_Out <- ALU_Out(sp)+4
				  @(negedge sys_clk)
                                            int_ack=0;	 FS=5'h11;
                        {pc_sel, pc_ld, pc_inc, ir_ld} = 5'b00_0_0_0;
                                 {im_cs, im_rd, im_wr} = 3'b0_0_0;
                 {D_En, DA_sel, T_Sel, HILO_ld, Y_Sel} = 9'b1_01_00_0_011; 
                                 {dm_cs, dm_rd, dm_wr} = 3'b0_0_0; 						
                                 {io_cs, io_rd, io_wr} = 3'b0_0_0;
                                       {SP_Sel, S_Sel} = 2'b0_1;
              #1 {nsi, nsc, nsv, nsn, nsz} = {psi, c, v, n, z};
                 state = POP_5;
				end
         POP_5: 
				begin
				  // control word assignments R[sp] <- ALU_Out(sp+4)
				  @(negedge sys_clk)
                                            int_ack=0;	 FS=5'h00;
                        {pc_sel, pc_ld, pc_inc, ir_ld} = 5'b00_0_0_0;
                                 {im_cs, im_rd, im_wr} = 3'b0_0_0;
                 {D_En, DA_sel, T_Sel, HILO_ld, Y_Sel} = 9'b1_11_00_0_000; 
                                 {dm_cs, dm_rd, dm_wr} = 3'b0_0_0; 						
                                 {io_cs, io_rd, io_wr} = 3'b0_0_0;
                                       {SP_Sel, S_Sel} = 2'b0_0;
              #1 {nsi, nsc, nsv, nsn, nsz} = {psi, psc, psv, psn, psz};
                 state = FETCH;
				end
            
   /***************************************************************************
    ****************        Other type   Instruction         ******************
    ***************************************************************************/			
			 ILLEGAL_OP:
				begin
				  $display("ILLEGAL OPCODE FETCHED %t",$time);
				  // control word assignments for "deasserting" everything
				  @(negedge sys_clk)
                                            int_ack=0;	 FS=5'h00;
                        {pc_sel, pc_ld, pc_inc, ir_ld} = 5'b00_0_0_0;
                                 {im_cs, im_rd, im_wr} = 3'b0_0_0;
                 {D_En, DA_sel, T_Sel, HILO_ld, Y_Sel} = 9'b0_00_00_0_000; 
                                 {dm_cs, dm_rd, dm_wr} = 3'b0_0_0; 								
                                 {io_cs, io_rd, io_wr} = 3'b0_0_0;
                                       {SP_Sel, S_Sel} = 2'b0_0;
              #1 {nsi, nsc, nsv, nsn, nsz} = {psi, psc, psv, psn, psz};
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
				  // control word assignments for RS <- R[$sp], 
              //                              R[$ra] <- PC
				  @(negedge sys_clk)
                                            int_ack=0;	 FS=5'h00;
                        {pc_sel, pc_ld, pc_inc, ir_ld} = 5'b00_0_0_0;
                                 {im_cs, im_rd, im_wr} = 3'b0_0_0;
                 {D_En, DA_sel, T_Sel, HILO_ld, Y_Sel} = 9'b1_10_00_0_100; 
                                 {dm_cs, dm_rd, dm_wr} = 3'b0_0_0; 								
                                 {io_cs, io_rd, io_wr} = 3'b0_0_0;
                                       {SP_Sel, S_Sel} = 2'b1_0;
              #1 {nsi, nsc, nsv, nsn, nsz} = {psi, psc, psv, psn, psz};
               state = INTR_2;
				end
			 INTR_2:
				begin
				  // Pass $sp from RS to ALU_Out
				  // control word assignments for ALU_Out <- RS($sp)
				  @(negedge sys_clk)
                                            int_ack=0;	 FS=5'h00;
                        {pc_sel, pc_ld, pc_inc, ir_ld} = 5'b00_0_0_0;
                                 {im_cs, im_rd, im_wr} = 3'b0_0_0;
                 {D_En, DA_sel, T_Sel, HILO_ld, Y_Sel} = 9'b0_00_00_0_000; 
                                 {dm_cs, dm_rd, dm_wr} = 3'b0_0_0; 							
                                 {io_cs, io_rd, io_wr} = 3'b0_0_0;
                                       {SP_Sel, S_Sel} = 2'b0_0;
              #1 {nsi, nsc, nsv, nsn, nsz} = {psi, psc, psv, psn, psz};
                 state = INTR_3;
				end
          INTR_3:
				begin
				  // Read address of ISR into D_in;
				  // control word assignments for D_in <- dM[ALU_Out(0x3FC)]
				  @(negedge sys_clk)
                                            int_ack=0;	 FS=5'h00;
                        {pc_sel, pc_ld, pc_inc, ir_ld} = 5'b00_0_0_0;
                                 {im_cs, im_rd, im_wr} = 3'b0_0_0;
                 {D_En, DA_sel, T_Sel, HILO_ld, Y_Sel} = 9'b0_00_00_0_000; 
                                 {dm_cs, dm_rd, dm_wr} = 3'b1_1_0; 							
                                 {io_cs, io_rd, io_wr} = 3'b0_0_0;
                                       {SP_Sel, S_Sel} = 2'b0_0;
              #1 {nsi, nsc, nsv, nsn, nsz} = {psi, psc, psv, psn, psz};
                 state = INTR_4;
				end
			 INTR_4:
				begin
				  // Load PC with M[$sp], Pre-decrement $sp,
              //     and prepare PUSH current PC on stack.
				  // control word assignments for PC <- D_in(DM[$sp]), 
              //                              ALU_Out <- ALU_Out-4,
              //                              RT <- PC
				  @(negedge sys_clk)
                                           int_ack=0;		FS=5'h12;
                        {pc_sel, pc_ld, pc_inc, ir_ld} = 5'b00_1_0_0;
                                 {im_cs, im_rd, im_wr} = 3'b0_0_0;
                 {D_En, DA_sel, T_Sel, HILO_ld, Y_Sel} = 9'b0_00_10_0_011; 
                                 {dm_cs, dm_rd, dm_wr} = 3'b0_0_0; 								
                                 {io_cs, io_rd, io_wr} = 3'b0_0_0;
                                       {SP_Sel, S_Sel} = 2'b0_1;
              #1 {nsi, nsc, nsv, nsn, nsz} = {psi, psc, psv, psn, psz};
                 state = INTR_5;
				end
          INTR_5:
				begin
				  // PUSH the current PC on stack, decrement $sp,
              //      and prepare PUSH current flags on stack.
				  // control word assignments for DM[$sp-4] <- RT(PC), 
              //                              ALU_Out <- ALU_Out($sp-4)-4,
              //                              RT <- flags
				  @(negedge sys_clk)
                                            int_ack=0;	FS=5'h12;
                        {pc_sel, pc_ld, pc_inc, ir_ld} = 5'b00_0_0_0;
                                 {im_cs, im_rd, im_wr} = 3'b0_0_0;
                 {D_En, DA_sel, T_Sel, HILO_ld, Y_Sel} = 9'b0_00_11_0_000; 
                                 {dm_cs, dm_rd, dm_wr} = 3'b1_0_1; 								
                                 {io_cs, io_rd, io_wr} = 3'b0_0_0;
                                      {SP_Sel, S_Sel} = 2'b0_1;
              #1 {nsi, nsc, nsv, nsn, nsz} = {psi, psc, psv, psn, psz};
                 state = INTR_6;
				end
          INTR_6:
				begin
				  // PUSH flags on stack, write current $sp in regfile,
              //     and set interrupt acknowledge
				  // control word assignments for DM[ALU_Out($sp-8)] <- RT(flags)
              //                              R[$sp] <- ALU_Out($sp-8)
              //                              int_ack <- 1'b1;
				  @(negedge sys_clk)
                                            int_ack=1;	 FS=5'h00;
                        {pc_sel, pc_ld, pc_inc, ir_ld} = 5'b00_0_0_0;
                                 {im_cs, im_rd, im_wr} = 3'b0_0_0;
                 {D_En, DA_sel, T_Sel, HILO_ld, Y_Sel} = 9'b1_11_00_0_000; 
                                 {dm_cs, dm_rd, dm_wr} = 3'b1_0_1; 								
                                 {io_cs, io_rd, io_wr} = 3'b0_0_0;
                                       {SP_Sel, S_Sel} = 2'b0_0;
              #1 {nsi, nsc, nsv, nsn, nsz} = {1'b0, psc, psv, psn, psz};
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
				 $time, i, CPU_Test_Module.cpu.idp.regfile.reg_array[i],
				 $time, i+16, CPU_Test_Module.cpu.idp.regfile.reg_array[i+16]);
			 end
		end
	endtask
	
	//*******************************************************
	//             PC and IR Register Dump Task             *
	//*******************************************************
	task Dump_PC_and_IR;
		begin
			$display(" "); $display("PC Register:");
			$display("t=%t PC=%h", $time, CPU_Test_Module.cpu.iu.PC.pc_out);
			$display(" ");                
			$display("IR Register:");
			$display("t=%t IR=%h", $time, CPU_Test_Module.cpu.iu.IR.q);
			$display(" "); $display(" ");
		end
	endtask
	
   //******************************************************* 
   //        Data Memory and I/O Memory Dump Task          *
   //******************************************************* 
   task Dump_Mem; 
   begin 
   $display("_______Data Memory(DM)______________||_________IO Memory(IOM)_____"); 
      for(i = 9'h0C0; i < 9'h100; i = i + 4) begin 
         X = {CPU_Test_Module.DM.Mem[i], 
              CPU_Test_Module.DM.Mem[i+1], 
              CPU_Test_Module.DM.Mem[i+2], 
              CPU_Test_Module.DM.Mem[i+3]}; 
         Y = {CPU_Test_Module.IO.Mem[i], 
              CPU_Test_Module.IO.Mem[i+1], 
              CPU_Test_Module.IO.Mem[i+2], 
              CPU_Test_Module.IO.Mem[i+3]}; 
         $display("t=%t DM[%h] = %h || t=%t IOM[%h] = %h", 
         $time, i, X, $time, i, Y); 
      end 
   end 
   endtask
   
endmodule
