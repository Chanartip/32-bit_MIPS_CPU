`timescale 1ns / 1ps
/****************************** C E C S  4 4 0 ******************************
 * 
 * File Name:  IDP.v
 * Project:    Final Project
 * Designer:   Chanartip Soonthornwan, Jonathan Shihata
 * Email:      Chanartip.Soonthornwan@gmail.com, JonnyShihata@gmail.com
 * Rev. No.:   Version 1.1
 * Rev. Date:  Date 10/6/2017
 * Update:     Add four registers as scratch register; 
 *             RS, RT, ALU_out_r, D_in.
 * 
 * Rev. No.:   Version 1.2
 * Rev. Date:  Rev. 1.2 Date 10/16/2017
 * Update:     Added DA_Sel to select either D_Addr or T_Addr
 * 
 * Rev. No.:   Version 1.3
 * Rev. Date:  1.3 Date 10/24/2017
 * Update:     Added another bit for DA_Sel to select 
 *             D_Addr, T_Addr, $ra(return Address), or $sp(stack Pointer)
 *
 * Rev. No.:   Version 1.4
 * Rev. Date:  Current Rev. 1.3 Date 11/21/2017
 * Update:     Added SP_Sel, S_Sel, sp_flags_in and sp_flags_out for
 *             performing Stack Memory
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
module IDP( 
   input              clk,   reset,    // On-board clock and reset signal
   input             D_En, HILO_ld,    // Load enable for regfiles
   input   [1:0]            DA_Sel,    // DA_MUX
   input   [1:0]             T_Sel,    // T-MUX select
   input   [2:0]             Y_Sel,    // Y-MUX select
   input   [4:0]                FS,    // ALU function select
   input   [4:0]             shamt,    // Shifting amount
   input   [4:0]            D_Addr,    // regfile Write address
   input   [4:0]   S_Addr,  T_Addr,    // regfile Source addresses
   input   [31:0]      DT,      DY,    // Data inputs
   input   [31:0]            pc_in,    // Program Counter input
   input             S_Sel, SP_Sel,    // S_MUX and Stack Pointer Select
   input   [4:0]       sp_flags_in,    // input stack flags
   output  [4:0]      sp_flags_out,    // output stack flags 
   output               C, V, N, Z,    // Status flags from ALU
   output  [31:0]  ALU_OUT,  D_OUT     // Outputs
   );
   
   wire    [31:0]        S,      T;    // Wires S to ALU and T to T-MUX
   wire    [31:0]            rt_in;    // A wire from T-MUX to RT
   wire    [31:0]     Y_hi,   Y_lo;    // Wires to HILO regfile and Y-MUX
   wire    [31:0]       hi,     lo;    // Outputs from HILO regfile
   wire    [31:0]       rs,     rt;    // Scratch 
   wire    [31:0]  alu_out,   d_in;    //    registers  wires
   wire    [4:0]            DA_Out;    // Wire to D_Addr
   wire    [4:0]        SP_MUX_Out;    // SP_MUX output to regfile S_Addr 
   wire    [31:0]        S_MUX_Out;    // S_MUX output to ALU S input
   
   // Register File
   //    a memory unit for CPU
   regfile32 regfile (.clk(clk),          // On-board clock
                      .reset(reset),      // Reset signal
                      .D_En(D_En),        // Load Enable
                      .D_Addr(DA_Out),    // Writing address
                      .S_Addr(SP_MUX_Out),// Source S address
                      .T_Addr(T_Addr),    // Source T address
                      .D_in(ALU_OUT),     // Data input
                      .S(S),              // S output
                      .T(T)               // T output
                      );

   // DA_MUX
   //    if DA_Sel = 1, choose T_Addr(rt)
   //    if DA_Sel = 2, choose $ra (register 31)
   //    if DA_Sel = 3, choose $sp (register 29)
   //    otherwise,     choose D_Addr(rd) by default
   assign DA_Out = (DA_Sel == 2'b01)? T_Addr:   // $rt
                   (DA_Sel == 2'b10)?  5'h1F:   // 31 for $ra
                   (DA_Sel == 2'b11)?  5'h1D:   // 29 for $sp
                                      D_Addr;   // $rd default
                                      
   // SP_MUX
   //    selecting either S_Addr from Instuction or
   //    Stack Pointer's address($sp at 5'h1D)
   assign  SP_MUX_Out = (SP_Sel)? 5'h1D: S_Addr;
  
   // S_MUX
   //    selecting either rs or alu_out
   //    and load it into S input of ALU
   assign  S_MUX_Out = (S_Sel)? alu_out: rs;
  
   // T-MUX
   //    selecting an output to input T of ALU
   //    if T_sel is 1, assign DT (SE_16 from Instruction Unit)
   //                2, PC_in
   //                3, flags from Data Memory before Interrupted
   //    otherwise assign T from regfile32
   assign rt_in = (T_Sel==2'b01) ? DT: 
                  (T_Sel==2'b10) ? pc_in:
                  (T_Sel==2'b11) ? {27'b0, sp_flags_in}: // status flags from mem
                                   T;
   // Arithmetic Logic Unit (ALU)
   //    performs Arithmetic and logic calculation
   //    base on Function Select(FS)
   ALU_32 alu (.S(S_MUX_Out),         // S input
               .T(rt),                // T input
               .FS(FS),               // Function Select(OPcode)
               .shamt(shamt),         // Shift Amount
               .Y_hi(Y_hi),           // upper part of 64-bit result
               .Y_lo(Y_lo),           // lower part of 64-bit resutl
               .C(C),                 // Carry flag
               .V(V),                 // Overflow flag
               .N(N),                 // Negative flag
               .Z(Z)                  // Zero flag
               );
   
   // Hi-Lo register
   //    holds result from multiplication
   //    and division.
   //    clk   -  On-board clock
   //    reset -  Reset signal
   //    load  -  Load enable
   //    d     -  upper part of 64-bit input
   //    q     -  lower part of 64-bit input
   //             clk, reset,    load,    d,  q
   reg32_w_ld HI (clk, reset, HILO_ld, Y_hi, hi),
              LO (clk, reset, HILO_ld, Y_lo, lo);
   
   
   // Scratch register
   //    holding value for the next clock
   //    clk   -  On-board clock
   //    reset -  Reset signal
   //    d     -  32-bit input
   //    q     -  32-bit output
   //              clk, reset,     d,       q
   reg32_no_ld  RS (clk, reset,     S,      rs),
                RT (clk, reset, rt_in,      rt),
           ALU_out (clk, reset,  Y_lo, alu_out),
              D_in (clk, reset,    DY,    d_in);
   
   // Wire flags status to MCU
   //    when IDP got flags from Memory(D_in)
   assign sp_flags_out = d_in[4:0];
    
   // Y-MUX
   //    selecting output (ALU_OUT) from Y_Sel
   assign ALU_OUT = (Y_Sel == 3'b001) ?    hi:  // upper part of 64-bit result
                    (Y_Sel == 3'b010) ?    lo:  // lower part of 64-bit result
                    (Y_Sel == 3'b011) ?  d_in:  // Data Input
                    (Y_Sel == 3'b100) ? pc_in:  // Program Counter Input
                                      alu_out;  // Pass alu_out by default
   
   // Assign D_OUT from the output of RT register
   assign D_OUT = rt;
   
endmodule
