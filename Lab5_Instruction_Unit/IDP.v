`timescale 1ns / 1ps
/****************************** C E C S  4 4 0 ******************************
 * 
 * File Name:  IDP.v
 * Project:    Lab_Assignment_4
 * Designer:   Chanartip Soonthornwan, Jonathan Shihata
 * Email:      Chanartip.Soonthornwan@gmail.com, JonnyShihata@gmail.com
 * Rev. No.:   Version 1.1
 * Rev. Date:  Date 10/6/2017
 * Update:     Add four registers as scratch register; 
 *             RS, RT, ALU_out_r, D_in.
 * 
 * Rev. No.:   Version 1.2
 * Rev. Date:  Current Rev. 1.2 Date 10/16/2017
 * Update:     Add DA_Sel to select either D_Addr or T_Addr
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
   input                    DA_Sel,    // DA_MUX
   input                     T_Sel,    // T-MUX select
   input   [2:0]             Y_Sel,    // Y-MUX select
   input   [4:0]                FS,    // ALU function select
   input   [4:0]            D_Addr,    // regfile Write address
   input   [4:0]   S_Addr,  T_Addr,    // regfile Source addresses
   input   [31:0]      DT,      DY,    // Data inputs
   input   [31:0]            pc_in,    // Program Counter input
   
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
    
   // Register File
   //    a memory unit for CPU
   regfile32 idp0 (.clk(clk),          // On-board clock
                   .reset(reset),      // Reset signal
                   .D_En(D_En),        // Load Enable
                   .D_Addr(DA_Out),    // Writing address
                   .S_Addr(S_Addr),    // Source S address
                   .T_Addr(T_Addr),    // Source T address
                   .D_in(ALU_OUT),     // Data input
                   .S(S),              // S output
                   .T(T)               // T output
                  );

   // DA_MUX
   //    if DA_Sel = 1, choose D_Addr
   //    otherwise, choose T_Addr
   assign DA_Out = (DA_Sel)? D_Addr: T_Addr;

   // T-MUX
   //    selecting an output to input T of ALU
   //    if T_sel is 1, assign DT
   //    otherwise assign T from regfile32
   assign rt_in = T_Sel ? DT : T;
   
   // Arithmetic Logic Unit (ALU)
   //    performs Arithmetic and logic calculation
   //    base on Function Select(FS)
   ALU_32 idp1 (.S(rs),                // S input
                .T(rt),                // T input
                .FS(FS),               // Function Select(OPcode)
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
