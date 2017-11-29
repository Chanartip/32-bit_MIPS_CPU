`timescale 1ns / 1ps
/****************************** C E C S  4 4 0 ******************************
 * 
 * File Name:  IDP2_tb.v
 * Project:    Lab_Assignment_4
 * Designer:   Chanartip Soonthornwan
 * Email:      Chanartip.Soonthornwan@gmail.com
 * Rev. No.:   Version 1.0
 * Rev. Date:  Current Rev. Date 10/6/2017
 *
 * Purpose:    A top level of Integer Datapath(IDP) and Data Memory(DM).
 *             Instanciates both modules, interconnection with 32-bit busses,
 *             and providing all necessary control signal inputs.
 *
 ****************************************************************************/

module IDP2_tb;

	// Inputs
	reg           clk,  reset,   D_En, T_Sel, HILO_ld;
	reg [ 2:0]  Y_Sel;
	reg [ 4:0] D_Addr, S_Addr, T_Addr, FS;
	reg [31:0]     DT,  PC_in;
   reg         dm_cs,  dm_wr,  dm_rd;
   
	// Outputs
	wire        C,V,N,Z;
	wire [31:0] ALU_OUT;
	wire [31:0]   D_OUT;
   wire [31:0]  DM_OUT;

	// Instantiate the Unit Under Test (UUT)
   // for IDP(idp) and Data_Memory(dm)
	IDP uut0 (
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
		.DY(DM_OUT),                     // IDP's DY gets Data Mem output
		.PC_in(PC_in), 
		.Y_Sel(Y_Sel), 
		.ALU_OUT(ALU_OUT), 
		.D_OUT(D_OUT)
	);

   Data_Memory uut1(
      .clk(clk), 
      .dm_cs(dm_cs), 
      .dm_wr(dm_wr), 
      .dm_rd(dm_rd), 
      .Addr({20'h0, ALU_OUT[11:0]}),   // Only use 12 bit of ALU_OUT
      .DM_In(D_OUT),                   // Get D_OUT from IDP
      .DM_Out(DM_OUT)                  // Send Data_out to IDP's DY
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
      reset   = 1;
		DT      = 32'hFFFF_FFFB;
		PC_in   = 32'h1001_00C0;
		{  clk,  D_En,  D_Addr, S_Addr, T_Addr} = 0;
		{T_Sel,    FS, HILO_ld,  Y_Sel        } = 0;
      {dm_cs, dm_wr,   dm_rd                } = 0;
    
      // Prompt all registers and wires
      // to known state.
      @(negedge clk) reset = ~reset;
      
      $timeformat(-9, 1, " ns", 9);             // Display time in nanoseconds
      $readmemh("IntReg_Lab4.dat",uut0.idp0.D_out);
      $readmemh("dMem_Lab4.dat",uut1.Mem);
      

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
         
      $display(" "); $display(" ");
      $display("___________________________________________________________");
      $display("__________________Memory After Write Loop__________________");   
         Dump_Mem;
      $display(" "); $display(" ");
      
      $finish;
      
	end
      
/* ***************************************************************************
 *                            T A S K s                                      *
 * ***************************************************************************/
   // Dump Register
   //    Printout data in regfile32 registers 
   //    stimutanously where
   //    T display register 0 to 15, 
   task Dump_Regs; 
   begin
      for(i=0; i<16; i=i+1) begin
         @(negedge clk) 
           D_En = 0;      D_Addr = 5'd0;
         S_Addr = 5'd0;   T_Addr = i;
          T_Sel = 0;          
             FS = 5'b0;  HILO_ld = 0;
          Y_Sel = 3'b0;
         {dm_cs,   dm_wr, dm_rd} = 3'b000;
         @(posedge clk)                      //    Display register[i]
            $display("Time:%t  T[%2h]=%h", 
                        $time, T_Addr, uut0.idp0.T);          
      end // End-loop
   end 
   endtask
   
   // Dump Memory
   //    Printout data in Memory 0xFF8 : 0xFFB
   //    print(M[$r14])
   task Dump_Mem; 
   begin
         @(negedge clk)                      //    RS <= $r14(0xFFFF_FFF8);  
           D_En = 0;      D_Addr = 5'd0;
         S_Addr = 5'd14;   T_Addr = 0;
          T_Sel = 0;          
             FS = 5'b0;  HILO_ld = 0;
          Y_Sel = 3'b0;
         {dm_cs,   dm_wr, dm_rd} = 3'b000;
         @(negedge clk)                      //    ALU_OUT <= RS;
           D_En = 0;      D_Addr = 5'd0;
         S_Addr = 5'd0;   T_Addr = 0;
          T_Sel = 0;          
             FS = PASS_S;  HILO_ld = 0;
          Y_Sel = 3'b0;
         {dm_cs,   dm_wr, dm_rd} = 3'b000;
         @(negedge clk)                      //    Addr <= ALU_OUT    
           D_En = 0;      D_Addr = 5'd0;
         S_Addr = 5'd0;   T_Addr = 0;
          T_Sel = 0;          
             FS = 5'b0;  HILO_ld = 0;
          Y_Sel = 3'b0;
         {dm_cs,   dm_wr, dm_rd} = 3'b101;   //    Memory Read
         @(posedge clk)                            
            $display("Time:%t  MEM[%h to %h] = %h", 
                        $time, uut1.Addr, uut1.Addr+4, uut1.DM_Out);          
   end 
   endtask
   
   // Write Register
   //    Overwritten data in regfile32 register with D_in
   task Write_Regs;
   begin
      // a.) $r1 <= $r3 | $r4
      //    T1:  RS <= $r3; RT <= $r4;
      //    T2:  ALU_Out <= RS | RT;
      //    T3:  $r1 <= ALU_Out;
      @(negedge clk)                         //    T1:  RS <= $r3; RT <= $r4;
           D_En = 0;      D_Addr = 5'd0;
         S_Addr = 5'd3;   T_Addr = 5'd4;
          T_Sel = 0;          
             FS = 5'b0;  HILO_ld = 0;
          Y_Sel = 3'b0;
         {dm_cs,   dm_wr, dm_rd} = 3'b000; 
      @(negedge clk)                         //    T2:  ALU_Out <= RS | RT;
           D_En = 0;      D_Addr = 5'd0;
         S_Addr = 5'd0;   T_Addr = 5'd0;
          T_Sel = 0;          
             FS = OR;    HILO_ld = 0;
          Y_Sel = 3'b0;
         {dm_cs,   dm_wr, dm_rd} = 3'b000;
      @(negedge clk)                         //    T3:  $r1 <= ALU_Out;
           D_En = 1;      D_Addr = 5'd1;
         S_Addr = 5'd0;   T_Addr = 5'd0;
          T_Sel = 0;          
             FS = 5'b0;  HILO_ld = 0;
          Y_Sel = 3'b000;
         {dm_cs,   dm_wr, dm_rd} = 3'b000;
        
      // b.) $r2 <= $r1 - $r14
      //    T1:  RS <= $r1; RT <= $r14;
      //    T2:  ALU_Out <= RS - RT;
      //    T3:  $r2 <= ALU_Out;
      @(negedge clk)                         //    T1:  RS <= $r1; RT <= $r14;
           D_En = 0;      D_Addr = 5'd0;
         S_Addr = 5'd1;   T_Addr = 5'd14;
          T_Sel = 0;          
             FS = 5'b0;  HILO_ld = 0;
          Y_Sel = 3'b0;
         {dm_cs,   dm_wr, dm_rd} = 3'b000; 
      @(negedge clk)                         //    T2:  ALU_Out <= RS - RT;
           D_En = 0;      D_Addr = 5'd0;
         S_Addr = 5'd0;   T_Addr = 5'd0;
          T_Sel = 0;          
             FS = SUB;   HILO_ld = 0;
          Y_Sel = 3'b0;
         {dm_cs,   dm_wr, dm_rd} = 3'b000;
      @(negedge clk)                         //    T3:  $r2 <= ALU_Out;
           D_En = 1;      D_Addr = 5'd2;
         S_Addr = 5'd0;   T_Addr = 5'd0;
          T_Sel = 0;          
             FS = 5'b0;  HILO_ld = 0;
          Y_Sel = 3'b000;
         {dm_cs,   dm_wr, dm_rd} = 3'b000;
        
      // c.) $r3 <= shr $r4
      //    T1:  RT <= $r4;
      //    T2:  ALU_out <= RT >> 1;
      //    T3:  $r3 <= ALU_out;
      @(negedge clk)                         //    T1:  RT <= $r4;
           D_En = 0;      D_Addr = 5'd0;
         S_Addr = 5'd0;   T_Addr = 5'd4;
          T_Sel = 0;          
             FS = 5'b0;  HILO_ld = 0;
          Y_Sel = 3'b0;
         {dm_cs,   dm_wr, dm_rd} = 3'b000; 
      @(negedge clk)                         //    T2:  ALU_out <= RT >> 1;
           D_En = 0;      D_Addr = 5'd0;
         S_Addr = 5'd0;   T_Addr = 5'd0;
          T_Sel = 0;          
             FS = SRL;    HILO_ld = 0;
          Y_Sel = 3'b0;
         {dm_cs,   dm_wr, dm_rd} = 3'b000;
      @(negedge clk)                         //     T3:  $r3 <= ALU_out;
           D_En = 1;      D_Addr = 5'd3;
         S_Addr = 5'd0;   T_Addr = 5'd0;
          T_Sel = 0;          
             FS = 5'b0;  HILO_ld = 0;
          Y_Sel = 3'b000;
         {dm_cs,   dm_wr, dm_rd} = 3'b000;
            
      // d.) $r4 <= shl $r5
      //    T1:  RT <= $r5;
      //    T2:  ALU_out <= RT << 1;
      //    T3:  $r3 <= ALU_out;
      @(negedge clk)                         //    T1:  RT <= $r5;
           D_En = 0;      D_Addr = 5'd0;
         S_Addr = 5'd0;   T_Addr = 5'd5;
          T_Sel = 0;          
             FS = 5'b0;  HILO_ld = 0;
          Y_Sel = 3'b0;
         {dm_cs,   dm_wr, dm_rd} = 3'b000; 
      @(negedge clk)                         //    T2:  ALU_out <= RT << 1;
           D_En = 0;      D_Addr = 5'd0;
         S_Addr = 5'd0;   T_Addr = 5'd0;
          T_Sel = 0;          
             FS = SLL;    HILO_ld = 0;
          Y_Sel = 3'b0;
         {dm_cs,   dm_wr, dm_rd} = 3'b000;
      @(negedge clk)                         //    T3:  $r3 <= ALU_out;
           D_En = 1;      D_Addr = 5'd4;
         S_Addr = 5'd0;   T_Addr = 5'd0;
          T_Sel = 0;          
             FS = 5'b0;  HILO_ld = 0;
          Y_Sel = 3'b000;
         {dm_cs,   dm_wr, dm_rd} = 3'b000;
             
           
      // e*.) {$r6,$r5} <= $r15/$r14
      //    T1:  RS <= $r15;  RT <= $r14;
      //    T2:  {HI,LO} <= RS/RT;
      //    T3:  $r6 <= HI;
      //    T4:  $r5 <= LO;
      @(negedge clk)                         //    T1:  RS <= $r15;  RT <= $r14;
           D_En = 0;      D_Addr = 5'd0;
         S_Addr = 5'd15;  T_Addr = 5'd14;
          T_Sel = 0;          
             FS = 5'b0;  HILO_ld = 0;
          Y_Sel = 3'b0;
         {dm_cs,   dm_wr, dm_rd} = 3'b000; 
      @(negedge clk)                         //    T2:  {HI,LO} <= RS/RT;
           D_En = 0;      D_Addr = 5'd0;
         S_Addr = 5'd0;   T_Addr = 5'd0;
          T_Sel = 0;          
             FS = DIV;   HILO_ld = 1;
          Y_Sel = 3'b0;
         {dm_cs,   dm_wr, dm_rd} = 3'b000;
      @(negedge clk)                         //    T3:  $r6 <= HI;
           D_En = 1;      D_Addr = 5'd6;
         S_Addr = 5'd0;   T_Addr = 5'd0;
          T_Sel = 0;          
             FS = 5'b0;  HILO_ld = 0;
          Y_Sel = 3'b001;
         {dm_cs,   dm_wr, dm_rd} = 3'b000;
      @(negedge clk)                         //    T4:  $r5 <= LO;
           D_En = 1;      D_Addr = 5'd5;
         S_Addr = 5'd0;   T_Addr = 5'd0;
          T_Sel = 0;          
             FS = 5'b0;  HILO_ld = 0;
          Y_Sel = 3'b010;
         {dm_cs,   dm_wr, dm_rd} = 3'b000;
           
      // f*.) {$r8,$r7} <= $r11 * 0xFFFF_FFFB
      //    T1:  RS <= $r11;  RT <= DT(0xFFFF_FFFB);
      //    T2:  {HI,LO} <= RS*RT;
      //    T3:  $r8 <= HI;
      //    T4:  $r7 <= LO;
      @(negedge clk)                         //    T1:  RS <= $r11;  
           D_En = 0;      D_Addr = 5'd0;     //         RT <= DT(0xFFFF_FFFB);
         S_Addr = 5'd11;  T_Addr = 5'd0;
          T_Sel = 1;          
             FS = 5'b0;  HILO_ld = 0;
          Y_Sel = 3'b0;
         {dm_cs,   dm_wr, dm_rd} = 3'b000; 
      @(negedge clk)                         //    T2:  {HI,LO} <= RS*RT;
           D_En = 0;      D_Addr = 5'd0;
         S_Addr = 5'd0;   T_Addr = 5'd0;
          T_Sel = 0;          
             FS = MUL;   HILO_ld = 1;
          Y_Sel = 3'b0;
         {dm_cs,   dm_wr, dm_rd} = 3'b000;
      @(negedge clk)                         //    T3:  $r8 <= HI;
           D_En = 1;      D_Addr = 5'd8;
         S_Addr = 5'd0;   T_Addr = 5'd0;
          T_Sel = 0;          
             FS = 5'b0;  HILO_ld = 0;
          Y_Sel = 3'b001;
         {dm_cs,   dm_wr, dm_rd} = 3'b000;
      @(negedge clk)                         //    T4:  $r7 <= LO;
           D_En = 1;      D_Addr = 5'd7;
         S_Addr = 5'd0;   T_Addr = 5'd0;
          T_Sel = 0;          
             FS = 5'b0;  HILO_ld = 0;
          Y_Sel = 3'b010;
         {dm_cs,   dm_wr, dm_rd} = 3'b000;
           
      // g.) $r12 <= M[$r15]
      //    T1:  RS <= $r15; 
      //    T2:  ALU_out <= RS;
      //    T3:  MAR <= ALU_out; D_in <= M[ALU_out($r15)];
      //    T4:  $r12 <= D_in;
      @(negedge clk)                         //    T1:  RS <= $r15;
           D_En = 0;      D_Addr = 5'd0;
         S_Addr = 5'd15;  T_Addr = 5'd0;
          T_Sel = 0;          
             FS = 5'b0;  HILO_ld = 0;
          Y_Sel = 3'b0;
         {dm_cs,   dm_wr, dm_rd} = 3'b000; 
      @(negedge clk)                         //    T2:  ALU_out <= RS;
           D_En = 0;      D_Addr = 5'd0;
         S_Addr = 5'd0;   T_Addr = 5'd0;
          T_Sel = 0;          
             FS = PASS_S; HILO_ld = 0;
          Y_Sel = 3'b0;
         {dm_cs,   dm_wr, dm_rd} = 3'b000;
      @(negedge clk)                         //    T3:  MAR <= ALU_out; 
           D_En = 0;      D_Addr = 5'd0;     //         D_in <= M[ALU_out];
         S_Addr = 5'd0;   T_Addr = 5'd0;
          T_Sel = 0;          
             FS = 5'b0;  HILO_ld = 0;
          Y_Sel = 3'b000;
         {dm_cs,   dm_wr, dm_rd} = 3'b101;
      @(negedge clk)                         //    T4:  $r12 <= D_in;
           D_En = 1;      D_Addr = 5'd12;
         S_Addr = 5'd0;   T_Addr = 5'd0;
          T_Sel = 0;          
             FS = 5'b0;  HILO_ld = 0;
          Y_Sel = 3'b011;
         {dm_cs,   dm_wr, dm_rd} = 3'b000;
        
      // h.) $r11 <= $r0 nor $r11
      //    T1:  RS <= $r0; RT <= $r11;
      //    T2:  ALU_Out <= ~(RS|RT);
      //    T3:  $r11 <= ALU_Out;
      @(negedge clk)                         //    T1:  RS <= $r0; RT <= $r11;
           D_En = 0;      D_Addr = 5'd0;
         S_Addr = 5'd0;   T_Addr = 5'd11;
          T_Sel = 0;          
             FS = 5'b0;  HILO_ld = 0;
          Y_Sel = 3'b0;
         {dm_cs,   dm_wr, dm_rd} = 3'b000; 
      @(negedge clk)                         //    T2:  ALU_Out <= ~(RS|RT);
           D_En = 0;      D_Addr = 5'd0;
         S_Addr = 5'd0;   T_Addr = 5'd0;
          T_Sel = 0;          
             FS = NOR;   HILO_ld = 0;
          Y_Sel = 3'b0;
         {dm_cs,   dm_wr, dm_rd} = 3'b000;
      @(negedge clk)                         //    T3:  $r11 <= ALU_Out;
           D_En = 1;      D_Addr = 5'd11;
         S_Addr = 5'd0;   T_Addr = 5'd0;
          T_Sel = 0;          
             FS = 5'b0;  HILO_ld = 0;
          Y_Sel = 3'b000;
         {dm_cs,   dm_wr, dm_rd} = 3'b000;
        
      // i.) $r10 <= $r0 - $r10
      //    T1:  RS <= $r0; RT <= $r10;
      //    T2:  ALU_Out <= RS-RT;
      //    T3:  $r10 <= ALU_Out;
      @(negedge clk)                         //    T1:  RS <= $r0; RT <= $r10;
           D_En = 0;      D_Addr = 5'd0;
         S_Addr = 5'd0;   T_Addr = 5'd10;
          T_Sel = 0;          
             FS = 5'b0;  HILO_ld = 0;
          Y_Sel = 3'b0;
         {dm_cs,   dm_wr, dm_rd} = 3'b000; 
      @(negedge clk)                         //    T2:  ALU_Out <= RS-RT;
           D_En = 0;      D_Addr = 5'd0;
         S_Addr = 5'd0;   T_Addr = 5'd0;
          T_Sel = 0;          
             FS = SUB;   HILO_ld = 0;
          Y_Sel = 3'b0;
         {dm_cs,   dm_wr, dm_rd} = 3'b000;
      @(negedge clk)                         //    T3:  $r10 <= ALU_Out;
           D_En = 1;      D_Addr = 5'd10;
         S_Addr = 5'd0;   T_Addr = 5'd0;
          T_Sel = 0;          
             FS = 5'b0;  HILO_ld = 0;
          Y_Sel = 3'b000;
         {dm_cs,   dm_wr, dm_rd} = 3'b000;
         
      // j.) $r9 <= $r10 + $r11
      //    T1:  RS <= $r10; RT <= $r11;
      //    T2:  ALU_Out <= RS+RT;
      //    T3:  $r9 <= ALU_Out;
      @(negedge clk)                         //    T1:  RS <= $r10; RT <= $r11;
           D_En = 0;      D_Addr = 5'd0;
         S_Addr = 5'd10;  T_Addr = 5'd11;
          T_Sel = 0;          
             FS = 5'b0;  HILO_ld = 0;
          Y_Sel = 3'b0;
         {dm_cs,   dm_wr, dm_rd} = 3'b000; 
      @(negedge clk)                         //    T2:  ALU_Out <= RS+RT;
           D_En = 0;      D_Addr = 5'd0;
         S_Addr = 5'd0;   T_Addr = 5'd0;
          T_Sel = 0;          
             FS = ADD;   HILO_ld = 0;
          Y_Sel = 3'b0;
         {dm_cs,   dm_wr, dm_rd} = 3'b000;
      @(negedge clk)                         //    T3:  $r9 <= ALU_Out;
           D_En = 1;      D_Addr = 5'd9;
         S_Addr = 5'd0;   T_Addr = 5'd0;
          T_Sel = 0;          
             FS = 5'b0;  HILO_ld = 0;
          Y_Sel = 3'b000;
         {dm_cs,   dm_wr, dm_rd} = 3'b000;
            
      // k.) $r13 <= PC(0x100100C0);
      //    T1:  $r13 <= PC;
      @(negedge clk)                         //    T1:  $r13 <= PC;
           D_En = 1;      D_Addr = 5'd13;
         S_Addr = 5'd0;   T_Addr = 5'd0;
          T_Sel = 0;          
             FS = 5'b0;  HILO_ld = 0;
          Y_Sel = 3'b100;
         {dm_cs,   dm_wr, dm_rd} = 3'b000; 
            
      // l.) M[$r14] <= $r12;
      //    T1:  RS <= $r14; 
      //    T2:  ALU_out <= RS; RT <= $r12;
      //    T3:  MAR <= ALU_out; DM_In <= RT;
      @(negedge clk)                         //    T1:  RS <= $r14; 
           D_En = 0;      D_Addr = 5'd0;
         S_Addr = 5'd14;  T_Addr = 5'd0;
          T_Sel = 0;          
             FS = 5'b0;  HILO_ld = 0;
          Y_Sel = 3'b0;
         {dm_cs,   dm_wr, dm_rd} = 3'b000; 
      @(negedge clk)                         //    ALU_out <= RS; RT <= $r12;
           D_En = 0;      D_Addr = 5'd0;
         S_Addr = 5'd0;   T_Addr = 5'd12;
          T_Sel = 0;          
             FS = PASS_S; HILO_ld = 0;
          Y_Sel = 3'b0;
         {dm_cs,   dm_wr, dm_rd} = 3'b000;
      @(negedge clk)                         //    T3:  MAR <= ALU_out; 
           D_En = 0;      D_Addr = 5'd0;     //         DM_In <= RT; 
         S_Addr = 5'd0;   T_Addr = 5'd0;
          T_Sel = 0;          
             FS = 5'b0;  HILO_ld = 0;
          Y_Sel = 3'b000;
         {dm_cs,   dm_wr, dm_rd} = 3'b110;

      // Disable all control to be default
      @(negedge clk)
           D_En = 0;      D_Addr = 5'd0;
         S_Addr = 5'd0;   T_Addr = 5'd0;
          T_Sel = 0;          
             FS = 5'b0;  HILO_ld = 0;
          Y_Sel = 3'b000;
         {dm_cs,   dm_wr, dm_rd} = 3'b000;
         
   end
   endtask
    
endmodule

