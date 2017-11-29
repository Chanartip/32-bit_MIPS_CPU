`timescale 1ns / 1ps
/****************************** C E C S  4 4 0 ******************************
 * 
 * File Name:  IDP.v
 * Project:    Lab_Assignment_3
 * Designer:   Chanartip Soonthornwan
 * Email:      Chanartip.Soonthornwan@gmail.com
 * Rev. No.:   Version 1.0
 * Rev. Date:  Current Rev. Date 9/29/2017
 *
 * Purpose:    Integer Data Path (IDP) performs arithmetics calculation 
 *             from 32-bit data inside a register file and output the result.
 *         
 * Notes:      IDP receives control from a control unit(CU) to control
 *             the data flow (data path) in IDP by sending source
 *             register addresses to the register file and execute the 
 *             arithmetic operation in Arithmetic Logic Unit (ALU), then
 *             selects output by Y-MUX.
 *
 ****************************************************************************/
module IDP(    clk,  reset,   D_En, 
            D_Addr, S_Addr, T_Addr,    
                        DT,  T_Sel,    
                FS,   C, V,   N, Z,
                           HILO_ld,  
                DY,  PC_in,  Y_Sel,
                   ALU_OUT,  D_OUT
           );
           
   input              clk,   reset;    // On-board clock and reset signal
   input             D_En, HILO_ld;    // Load enable for regfiles
   input                     T_Sel;    // T-MUX select
   input   [2:0]             Y_Sel;    // Y-MUX select
   input   [4:0]                FS;    // ALU function select
   input   [4:0]            D_Addr;    // regfile Write address
   input   [4:0]   S_Addr,  T_Addr;    // regfile Source addresses
   input   [31:0]      DT,      DY;    // Data inputs
   input   [31:0]            PC_in;    // Program Counter input
   
   output               C, V, N, Z;    // Status flags from ALU
   output  [31:0]  ALU_OUT,  D_OUT;    // Outputs

   wire    [31:0]        S,      T;    // Wires S to ALU and T to T-MUX
   wire    [31:0]     Y_hi,   Y_lo;    // Wires to HILO regfile and Y-MUX
   wire    [31:0]       HI,     LO;    // Outputs from HILO regfile
   
   // Register File
   //    a memory unit for CPU
   regfile32 idp0 (.clk(clk),          // On-board clock
                   .reset(reset),      // Reset signal
                   .D_En(D_En),        // Load Enable
                   .D_Addr(D_Addr),    // Writing address
                   .S_Addr(S_Addr),    // Source S address
                   .T_Addr(T_Addr),    // Source T address
                   .D_in(ALU_OUT),     // Data input
                   .S(S),              // S output
                   .T(T)               // T output
                  );
                  
   // T-MUX
   //    selecting an output to input T of ALU
   //    if T_sel is 1, assign DT
   //    otherwise assign T from regfile32
   assign D_OUT = T_Sel ? DT : T;
   
   // Arithmetic Logic Unit (ALU)
   //    performs Arithmetic and logic calculation
   //    base on Function Select(FS)
   ALU_32 idp1 (.S(S),                 // S input
                .T(D_OUT),             // T input
                .FS(FS),               // Function Select(OPcode)
                .Y_hi(Y_hi),           // upper part of 64-bit result
                .Y_lo(Y_lo),           // lower part of 64-bit resutl
                .C(C),                 // Carry flag
                .V(V),                 // Overflow flag
                .N(N),                 // Negative flag
                .Z(Z)                  // Zero flag
                );
   
   reg_hilo idp2 (.clk(clk),           // On-board clock
                  .reset(reset),       // Reset signal
                  .hilo_ld(HILO_ld),   // Load enable
                  .d_hi(Y_hi),         // upper part of 64-bit input
                  .d_lo(Y_lo),         // lower part of 64-bit input
                  .q_hi(HI),           // upper part of 64-bit result
                  .q_lo(LO)            // lower part of 64-bit result
                  );
   
   // Y-MUX
   //    selecting output (ALU_OUT) from Y_Sel
   assign ALU_OUT = (Y_Sel == 3'b001) ?    HI:  // upper part of 64-bit result
                    (Y_Sel == 3'b010) ?    LO:  // lower part of 64-bit result
                    (Y_Sel == 3'b011) ?    DY:  // Data Input
                    (Y_Sel == 3'b100) ? PC_in:  // Program Counter Input
                                         Y_lo;  // Pass Y_lo by default
   
endmodule
