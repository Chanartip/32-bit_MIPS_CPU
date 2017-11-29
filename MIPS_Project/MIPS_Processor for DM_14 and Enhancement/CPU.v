`timescale 1ns / 1ps
/****************************** C E C S  4 4 0 ******************************
 * 
 * File Name:  CPU.v
 * Project:    Final_Project
 * Designer:   Chanartip Soonthornwan, Jonathan Shihata
 * Email:      Chanartip.Soonthornwan@gmail.com, JonnyShihata@gmail.com
 * Rev. No.:   Version 1.0
 * Rev. Date:  Date 11/17/2017
 *
 * Rev. No.1:  Version 1.1
 * Rev. Date:  Current Rev. Date 11/21/2017
 * update:     Add wires for perform RETI and INTR (SP_Sel, S_Sel,
 *                flag_in, flag_out).
 *             Update MCU and IDP Port list.
 *
 * Purpose:    Top level of Instruction Unit(IU, Integer Data Path(IDP), 
 *             and Control Unit(MCU). Shows connection between modules above.
 *         
 ****************************************************************************/
module CPU( 
	input       sys_clk, reset, intr,      // System clock, reset, IO_interupt
   output                   int_ack,      // IO Interrupt Acknowledge
   //  From and To Memory
   input  [31:0] DM_out,                  // Data output from Memory
   output [31:0] MAddr,  idp_out,         // Memory Address and Data in to memory
	output        dm_cs,  dm_rd,  dm_wr,   // Data Memory Controls
   output        io_cs,  io_rd,  io_wr    // IO Memory Controls
   );

   //  Controls from MCU to Instruction Unit (IU)
   wire        pc_ld,  pc_inc, ir_ld;     // Program Counter Register
	wire        im_cs,  im_rd,  im_wr;     // Instruction Memory

   //
   //  Controls from MCU to Integer Data Path (IDP)
   wire 		   D_En,   HILO_ld;           // Register File
   wire  [1:0] T_Sel;                     //    Controls
   wire        SP_Sel, S_Sel;             // Stack Pointer Control
	wire  [1:0] pc_sel, DA_sel;            // T-MUX and DA_MUX for T or D_Addr
	wire  [2:0] Y_Sel;                     // ALU_Out select
	wire  [4:0] FS; 			               // Function select
	
	// Flags status
   //  From IDP and MCU
	wire         c,n,z,v;
   wire [4:0]   flag_in, flag_out;        // input-output flag
   
	// Interconnection
   //    From Instruction Unit(IU) to IDP
	wire [31:0] IR_out, pc_out, se_16;

   //*****************//
	// Instantiate MCU //
	//*****************//
	MCU mcu ( 
            // Inputs
            .sys_clk(sys_clk), .reset(reset),   .intr(intr), 
				.c(c), .n(n), .z(z), .v(v), 						   
				.IR(IR_out), 	
            .sp_flags_in(flag_in),
            
            // Outputs
            .int_ack(int_ack), 									
            
            // Controls For Instruction Unit
				.pc_sel(pc_sel),   .pc_ld(pc_ld),   .pc_inc(pc_inc), .ir_ld(ir_ld), 		
				.im_cs(im_cs),     .im_rd(im_rd),   .im_wr(im_wr),
            
            // Controls For Integer Data Path (IDP)
				.D_En(D_En),       .DA_sel(DA_sel), .T_Sel(T_Sel),   
            .HILO_ld(HILO_ld), .Y_Sel(Y_Sel),   .FS(FS),
            .SP_Sel(SP_Sel),   .S_Sel(S_Sel),   
            .sp_flags_out(flag_out), 
            
             // Controls For Data Memory
				.dm_cs(dm_cs),     .dm_rd(dm_rd),   .dm_wr(dm_wr),
            
            // Controls For IO Memory
 				.io_cs(io_cs),     .io_rd(io_rd),   .io_wr(io_wr)
   );			 
             
   //******************//
	// Instruction Unit //
	//******************//
	Instruction_Unit iu(
            // Scalar IO
            .clk(sys_clk),   .reset(reset),  
            .pc_sel(pc_sel), .pc_ld(pc_ld), .pc_inc(pc_inc), .ir_ld(ir_ld), 
            .im_cs(im_cs),   .im_wr(im_wr), .im_rd(im_rd),
            // 32-bit IO                                                
            .PC_in(MAddr),   .PC_out(pc_out),     
            .IR_out(IR_out), .SE_16(se_16)     
   );

   //******************//
	// Integer Datapath //
	//******************//
	IDP idp(  // Inputs
            .clk(sys_clk), 
            .reset(reset), 
            .D_En(D_En),                  // Data write Enable
            .DA_Sel(DA_sel),              // Destination Address Select       
            .D_Addr(IR_out[15:11]),       // $rd from IR_out
            .S_Addr(IR_out[25:21]),       // $rs from IR_out  
            .T_Addr(IR_out[20:16]),       // $rt from IR_out  
            .DT(se_16),                   // SignExtension from IU
            .T_Sel(T_Sel),                
            .FS(FS),                      // Address from IR_out 
            .shamt(IR_out[10:6]),         // Shifting amount from IR_out
            .HILO_ld(HILO_ld),   
            .DY(DM_out),                  // Input from Data Memory output
            .pc_in(pc_out),               // Input from Instruction Unit PC_out
            .Y_Sel(Y_Sel),
            .SP_Sel(SP_Sel),              // Stack
            .S_Sel(S_Sel),                //       Pointer Control
            .sp_flags_in(flag_out),       //             
            
            // Outputs
            .sp_flags_out(flag_in),       //
            .C(c),                        // Flag
            .V(v),                        //    status
            .N(n),                        //       to
            .Z(z),                        //          MCU
            .ALU_OUT(MAddr),              // Memory Address to Data and IO memory
            .D_OUT(idp_out)               // Data output to Data and IO memory
   );
   
endmodule
