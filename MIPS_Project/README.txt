11/17/2017
- Created CPU module to instanciate IDP, IU, and MCU instead of previous MIPS_CU_TB.
	- leave Data Memory outside the scope but will send input/output through the same port declared in CPU's port list.
- Copy previous MCU before making CPU for incase of casestatements in DECODE state that previously use MIPS_CU_TB.iu.IR_Out[....]
- Adjust MIPS states pattern in MCU to be the same as your R-Type


- On Going list
	- creating CPU Module that instanciates CPU, Data Memory, and IO module
		- but will leave IO module for the last test on dm13, dm14 since they have interrupt involve
	- will test dm_1 as soon as CPU module finish
	- I will updating I-Type and J-Type later..... 


if you have time check what I listed above or can progress further and leave some note for me.
The project is really big in short time. Just make sure we keep communicating each other.

We don't really have obvious responsibilities like the other groups where one does coding and another does documenting.

I'm trying to get the baseline and 13 dm module testing done by this Monday if possible. So we can add Vector later.

11/17/17 Jonny:
OK Im working on the documentation right now and can start to code once finished cause the documentation is really long.
Im not sure what you want me to do in code.

11/18/17 1:30am Aim:
finish CPU Test Module.... trying DM1, but BEQ flag is set wrong.... 
for the code, you can look where i'm updating and help me track of any thing that could be wrong.
In other word, you should know our CPU module 

11/18/17 10:30 am Aim:
+switch sys_clk generate at CPU_Test_Module to #5 instead of #1 ns
+Test module 1 - successful
+added dump memory to printout memory after testbench
+added IO Memory, but haven't connected io_intr and io_int_ack yet
+add "Verification report" in the same folder as MIPS_project to save the isim log

11/19/17 1:10 pm Aim:
+ Corrected BarrialShifter32 to get right function select(FS or Type) and shamt
+ Done verification 2
   - found Jump instruction was correct, but Instruction Memory's address wire should be truncated, so it gets only 12 bit from PC_out
          because our project memory aren't that big to use beyond 12 bits.
   - Tuan's use kinda same but he does in pc_mux while I change the port of Instruction memory
+ update CPU, MCU, IDP, ALU_32, BarrailShifter32 headers.

11/20/17 2pm - 10pm 
+ Done verification 3-13, and double check with current code
+ Copied current code created new project for DM14
+ Adjust wires for top level from CPU to both Memories properly
+ Added INPUT, OUTPUT
+ RETI is on process..... (INTR is pre-dec push, RETI post-inc pop)
   - INTR steps.... push current PC in M[--sp], and current flags in M[--(--sp)]
   - RETI steps.....pop flags from M[sp++], and current PC[(sp++)++]

11/21/17 2pm - 12:30 am
+ finish all verification
+ Finish commenting on Major change files
+ Tomorrow, re-verification all DM, and edit a little bit more on header and comments.

11/25/17 2:20am
+ Added ROTL, ROTR, BLT, BGE, MOV, DJNZ, PUSH, POP, CLR, NOP
+ CPU for DM14 can be used for all DM.

Verification
1.) LUI, ORI, BEQ, BNE
2.) ADDI, SRL, J
3.) SRA
4.) SLT
5.) SLTI
6.) LW
7.) JAL, JR
8.) MULT, MFLO, MFHI
9.) XOR, AND, SLTU, AND, OR, NOR
10.) DIV
11.) SLTIU, ANDI, XORI 
12.) BLEZ, BGTZ
13.) SETIE, OUTPUT, INPUT
14.) ISR with INTR, RETI

11/26/17 Jonny:
Baseline ISA looks complete
We need to :
1. add enhanced instructions
2. add verilog code to documentation
3. add annotated memory modules.


11/27/2017 1:15am Aim:
tested all enhance op: ROTL, ROTR, BLT, BGE, MOV, DJNZ, PUSH, POP, CLR, NOP
Added verification for enhancement
- going to do annotating.
