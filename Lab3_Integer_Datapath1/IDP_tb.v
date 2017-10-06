`timescale 1ns / 1ps
/****************************** C E C S  4 4 0 ******************************
 * 
 * File Name:  IDP_tb.v
 * Project:    Lab_Assignment_3
 * Designer:   Chanartip Soonthornwan
 * Email:      Chanartip.Soonthornwan@gmail.com
 * Rev. No.:   Version 1.0
 * Rev. Date:  Current Rev. Date 10/1/2017
 *
 * Purpose:    Test Integer Data Path Module 
 *         
 ****************************************************************************/

module IDP_tb;

	// Inputs
	reg clk;
	reg reset;
	reg D_En;
	reg [4:0] D_Addr;
	reg [4:0] S_Addr;
	reg [4:0] T_Addr;
	reg [31:0] DT;
	reg T_Sel;
	reg [4:0] FS;
	reg HILO_ld;
	reg [31:0] DY;
	reg [31:0] PC_in;
	reg [2:0] Y_Sel;

	// Outputs
	wire C;
	wire V;
	wire N;
	wire Z;
	wire [31:0] ALU_OUT;
	wire [31:0] D_OUT;

	// Instantiate the Unit Under Test (UUT)
	IDP uut (
		.clk(clk), 
		.reset(reset), 
		.D_En(D_En), 
		.D_Addr(D_Addr), 
		.S_Addr(S_Addr), 
		.T_Addr(T_Addr), 
		.DT(DT), 
		.T_Sel(T_Sel), 
		.FS(FS), 
		.C(C), 
		.V(V), 
		.N(N), 
		.Z(Z), 
		.HILO_ld(HILO_ld), 
		.DY(DY), 
		.PC_in(PC_in), 
		.Y_Sel(Y_Sel), 
		.ALU_OUT(ALU_OUT), 
		.D_OUT(D_OUT)
	);
   
   // integer in used
   integer i;
   
   // Look-up table for Function Select(FS)
   parameter PASS_S = 5'h00,  AND  = 5'h08,  INC     = 5'h0F,
             PASS_T = 5'h01,  OR   = 5'h09,  DEC     = 5'h10,
             ADD    = 5'h02,  XOR  = 5'h0A,  INC4    = 5'h11,
             ADDU   = 5'h03,  NOR  = 5'h0B,  DEC4    = 5'h12,
             SUB    = 5'h04,  SLL  = 5'h0C,  ZEROS   = 5'h13,
             SUBU   = 5'h05,  SRL  = 5'h0D,  ONES    = 5'h14,
             SLT    = 5'h06,  SRA  = 5'h0E,  SP_INIT = 5'h15,
             SLTU   = 5'h07,  ANDI = 5'h16,
             MUL    = 5'h1E,  ORI  = 5'h17,
             DIV    = 5'h1F,  XORI = 5'h18,
                              LUI  = 5'h19;
                              
   // Generated clock
   always #5 clk = ~clk;

	initial begin
		// Initialize Inputs
	       clk = 0;  reset = 1;   D_En = 0;
	 	 D_Addr = 0; S_Addr = 0; T_Addr = 0;
		     DT = 0;  T_Sel = 0;     FS = 0;
		HILO_ld = 0;     DY = 0;  PC_in = 0;
		Y_Sel   = 0;
      
      $timeformat(-9, 1, " ns", 9);             // Display time in nanoseconds
      $readmemh("IntReg_Lab3.dat",uut.idp0.D_out);
      
      // Low the reset to get regfile32 ready
      // ie. set 0x00000000 at $zero
      @(negedge clk)
         reset = ~reset;
      
      // Do tasks
      $display(" "); $display(" ");
      $display("___________________________________________________________");
      $display("_______________Register After Initialization_______________");   
      @(negedge clk)
         Dump_Regs;     // Printout Registers
      @(negedge clk)
         Write_Regs;    // Write new data in to Registers
      
      $display(" "); $display(" ");
      $display("___________________________________________________________");
      $display("_________________Register After Write Loop_________________");     
      @(negedge clk)
         Dump_Regs;  // Printout Registers
      $finish;
	end               // End Initialization
      
/* ***************************************************************************
 *                            T A S K s                                      *
 * ***************************************************************************/
   // Dump Register
   //    Printout data in regfile32 registers 
   //    stimutanously where
   //    S display register 0 to 15, and
   //    T display register 16 to 31.
   task Dump_Regs; 
   begin
      
      for(i=0; i<16; i=i+1) begin
         @(negedge clk) 
               D_En = 0; D_Addr = 0;         // Turn off data write enable
             S_Addr = i; T_Addr = 0;         // Select S register
                 DT = 0;  T_Sel = 0;         // Nothing on T path
                 FS = 0;                     // PASS S
            HILO_ld = 0;  DY = 0;  PC_in = 0;// Nothing on HILO register
              Y_Sel = 0;                     // PASS Y_lo
         // @(posedge clk)    
         #1 $display("Time:%t  S_Addr=%2h: ALU_OUT=%h", 
                        $time, S_Addr, ALU_OUT);          
      end // End-loop
   end 
   endtask
   
   // Write Register
   //    Overwritten data in regfile32 register with D_in
   task Write_Regs;
   begin
      // a.) $r1 <= $r3 | $r4
      @(negedge clk)
            D_En = 1;    D_Addr = 5'd1;      // Turn on data write enable
          S_Addr = 5'd3; T_Addr = 5'd4;      // Select S and T registers
              DT = 0;     T_Sel = 0;         // PASS T 
              FS = OR;                       // OR
         HILO_ld = 0;                        // Not used
              DY = 0;     PC_in = 0;         // Not used
           Y_Sel = 0;                        // PASS Y_lo
      
      // b.) $r2 <= $r1 - $r14
      @(negedge clk)
            D_En = 1;    D_Addr = 5'd2;      // Turn on data write enable
          S_Addr = 5'd1; T_Addr = 5'd14;     // Select S and T registers
              DT = 0;     T_Sel = 0;         // PASS T 
              FS = SUB;                      // Subtract signed
         HILO_ld = 0;                        // Not used
              DY = 0;     PC_in = 0;         // Not used
           Y_Sel = 0;                        // PASS Y_lo
           
      // c.) $r3 <= shr $r4
      @(negedge clk)
            D_En = 1;    D_Addr = 5'd3;      // Turn on data write enable
          S_Addr = 5'd0; T_Addr = 5'd4;      // Select T register
              DT = 0;     T_Sel = 0;         // PASS T 
              FS = SRL;                      // Shift Right Logic
         HILO_ld = 0;                        // Not used
              DY = 0;     PC_in = 0;         // Not used
           Y_Sel = 0;                        // PASS Y_lo
           
      // d.) $r4 <= shl $r5
      @(negedge clk)
            D_En = 1;    D_Addr = 5'd4;      // Turn on data write enable
          S_Addr = 5'd0; T_Addr = 5'd5;      // Select T register
              DT = 0;     T_Sel = 0;         // PASS T 
              FS = SLL;                      // Shift Left Logic
         HILO_ld = 0;                        // Not used
              DY = 0;     PC_in = 0;         // Not used
           Y_Sel = 0;                        // PASS Y_lo     
           
      // e*.) {$r6,$r5} <= $r15/$r14
      @(negedge clk)                         // DIV then store in HILO
            D_En = 0;     D_Addr = 5'd0;     // Turn off data write enable
          S_Addr = 5'd15; T_Addr = 5'd14;    // Select S, T registers
              DT = 0;      T_Sel = 0;        // PASS T 
              FS = DIV;                      // Divide
         HILO_ld = 1;                        // enable load HILO register
              DY = 0;     PC_in = 0;         // Not used
           Y_Sel = 0;                        // PASS Y_lo
           
      @(negedge clk)                         // Store HI in register file
            D_En = 1;     D_Addr = 5'd6;     // Turn on data write enable
          S_Addr = 5'd15; T_Addr = 5'd14;    // Not used
              DT = 0;      T_Sel = 0;        // PASS T 
              FS = DIV;                      // Not used
         HILO_ld = 0;                        // Not used
              DY = 0;     PC_in = 0;         // Not used
           Y_Sel = 3'b001;                   // PASS HI  
            
      @(negedge clk)                         // Store LO in register file
            D_En = 1;     D_Addr = 5'd5;     // Turn on data write enable
          S_Addr = 5'd15; T_Addr = 5'd14;    // Not used
              DT = 0;      T_Sel = 0;        // PASS T 
              FS = DIV;                      // Not used
         HILO_ld = 0;                        // Not used
              DY = 0;     PC_in = 0;         // Not used
           Y_Sel = 3'b010;                   // PASS LO
           
      // f*.) {$r8,$r7} <= $r11 * 0xFFFF_FFFB
      @(negedge clk)                         // MUL using DT store in HILO
            D_En = 0;     D_Addr = 5'd0;     // Turn off data write enable
          S_Addr = 5'd11; T_Addr = 5'd0;     // Select S registers
              DT = 32'hFFFF_FFFB; T_Sel = 1; // Select DT 
              FS = MUL;                      // Multiply
         HILO_ld = 1;                        // enable load HILO register
              DY = 0;     PC_in = 0;         // Not used
           Y_Sel = 0;                        // PASS Y_lo
           
      @(negedge clk)                         // Store HI in register file
            D_En = 1;     D_Addr = 5'd8;     // Turn on data write enable
          S_Addr = 5'd11; T_Addr = 5'd0;     // Not used
              DT = 0;      T_Sel = 0;        // PASS T 
              FS = MUL;                      // Not used
         HILO_ld = 0;                        // Not used
              DY = 0;      PC_in = 0;        // Not used
           Y_Sel = 3'b001;                   // PASS HI  
            
      @(negedge clk)                         // Store LO in register file
            D_En = 1;     D_Addr = 5'd7;     // Turn on data write enable
          S_Addr = 5'd15; T_Addr = 5'd14;    // Not used
              DT = 0;      T_Sel = 0;        // PASS T 
              FS = DIV;                      // Not used
         HILO_ld = 0;                        // Not used
              DY = 0;      PC_in = 0;        // Not used
           Y_Sel = 3'b010;                   // PASS LO
           
      // g.) $r12 <= 0xABCD_EF01
      @(negedge clk)                         // Init $r12
            D_En = 1;     D_Addr = 5'd12;    // Turn on data write enable
          S_Addr = 5'd0;  T_Addr = 5'd0;     // Not used
              DT = 0;      T_Sel = 0;        // PASS T 
              FS = PASS_S;                   // Not used
         HILO_ld = 0;                        // Not used
              DY = 32'hABCD_EF01; PC_in = 0; // SET DY value
           Y_Sel = 3'b011;                   // PASS DY       
           
      // h.) $r11 <= $r0 nor $r11
      @(negedge clk)                         // 1's complement
            D_En = 1;     D_Addr = 5'd11;    // Turn on data write enable
          S_Addr = 5'd0;  T_Addr = 5'd11;    // Not used
              DT = 0;      T_Sel = 0;        // PASS T 
              FS = NOR;                      // NOR
         HILO_ld = 0;                        // Not used
              DY = 0;      PC_in = 0;        // Not used
           Y_Sel = 0;                        // PASS Y_lo    
       
      // i.) $r10 <= $r0 - $r10
      @(negedge clk)                         // 2's complement
            D_En = 1;     D_Addr = 5'd10;    // Turn on data write enable
          S_Addr = 5'd0;  T_Addr = 5'd10;    // Not used
              DT = 0;      T_Sel = 0;        // PASS T 
              FS = SUB;                      // SUB
         HILO_ld = 0;                        // Not used
              DY = 0;      PC_in = 0;        // Not used
           Y_Sel = 0;                        // PASS Y_lo    
       
      // j.) $r9 <= $r10 + $r11
      @(negedge clk)                         // Addition (signed)
            D_En = 1;     D_Addr = 5'd9;     // Turn on data write enable
          S_Addr = 5'd10;  T_Addr = 5'd11;   // Not used
              DT = 0;      T_Sel = 0;        // PASS T 
              FS = ADD;                      // ADD
         HILO_ld = 0;                        // Not used
              DY = 0;      PC_in = 0;        // Not used
           Y_Sel = 0;                        // PASS Y_lo    
             
      // k.) $r13 <= 0x100100C0
      @(negedge clk)                         // Pass using PC_in
            D_En = 1;     D_Addr = 5'd13;    // Turn on data write enable
          S_Addr = 5'd0;  T_Addr = 5'd0;     // Not used
              DT = 0;      T_Sel = 0;        // PASS T 
              FS = PASS_S;                   // Not used
         HILO_ld = 0;                        // Not used
              DY = 0; PC_in = 32'h100100C0;  // Set PC_in
           Y_Sel = 3'b100;                   // PASS PC_in    
   end
   endtask
    
endmodule
 
