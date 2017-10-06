`timescale 1ns / 1ps
/* ***************************** C E C S  4 4 0 *******************************
 * 
 * File Name:  regfile32_tb.v
 * Project:    Lab_Assignment_2
 * Designer:   Chanartip Soonthornwan
 * Email:      Chanartip.Soonthornwan@gmail.com
 * Rev. No.:   Version 1.0
 * Rev. Date:  Current Rev. Date 9/18/2017
 *
 * ***************************************************************************/
module regfile32_tb;

	// Inputs
	reg clk;
	reg reset;
	reg D_En;
	reg [4:0] D_Addr;
	reg [4:0] S_Addr;
	reg [4:0] T_Addr;
	reg [31:0] D_in;

	// Outputs
	wire [31:0] S;
	wire [31:0] T;
   
   // Integer
   integer i;
   
	// Instantiate the Unit Under Test (UUT)
	regfile32 uut (
		.clk(clk), 
		.reset(reset), 
		.D_En(D_En), 
		.D_Addr(D_Addr), 
		.S_Addr(S_Addr), 
		.T_Addr(T_Addr), 
		.D_in(D_in), 
		.S(S), 
		.T(T)
	);
   
   // Create a 10 ns clock
   always #5 clk = ~clk;
    
	initial begin
      $timeformat(-9, 1, " ps", 9);             // Display time in nanoseconds
      $readmemh("IntReg_Lab2.dat", uut.D_out);  // Load file to regfile32
      
      // Reset Clock and set High to Reset signal
      clk     = 1'b0;                          
      reset   = 1'b1;
      
      // Low the reset to get regfile32 ready
      // ie. set 0x00000000 at $zero
      @(negedge clk)
         reset = ~reset;
      
      // Do tasks
      $display(" "); $display(" ");
      $display("___________________________________________________________");
      $display("_______________Register After Initialization_______________");   
      Dump_Regs;     // Printout Registers
      Write_Regs;    // Write new data in to Registers
      $display(" "); $display(" ");
      $display("___________________________________________________________");
      $display("_________________Register After Write Loop_________________");     
      Dump_Regs;     // Printout Registers
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
      D_En = 0;                     // Turn off data write enable
      for(i=0; i<16; i=i+1) begin
         @(negedge clk)
            S_Addr = i;
            T_Addr = i+16;
            #1 $display("Time:%t  S_Addr=%2h: S=%h  ||  T_Addr=%2h: T=%h", 
                        $time, S_Addr, S, T_Addr, T); 
      end // End-loop
   end 
   endtask
   
   // Write Register
   //    Overwritten data in regfile32 register with D_in
   task Write_Regs;
   begin
      D_En = 1;                     // Turn on data write enable
      for(i=1; i<32; i=i+1) begin
         @(negedge clk)
            D_Addr = i;
            D_in = ((~i) <<8) + (-65536 * i) +i;
      end 
      
      // Wait for one clock for register to setup right
      // Then turn off data write enable
      @(negedge clk) 
         D_En = 0;
   end
   endtask
   
endmodule

