`timescale 1ns / 1ps
/****************************** C E C S  4 4 0 ******************************
 * 
 * File Name:  BarrialShifter32.v
 * Project:    MIPS_Final_project
 * Designer:   Chanartip Soonthornwan, Jonathan Shihata
 * Email:      Chanartip.Soonthornwan@gmail.com, JonnyShihata@gmail.com
 * Rev. No.:   Version 1.0
 * Rev. Date:  Date 11/13/2017
 *
 * Rev. No.1:  Version 1.1
 * Rev. Date:  Current Rev. Date 11/19/2017
 * update:     Correct case statement for type and shamt
 *
 * Purpose:    Perform Shifting 32-bit input with shifting amount(shamt)
 *             in different type of shifting method(type) and output back
 *             to ALU_32
 *         
 * Notes:      There are 5 modes but only 3 in used (SLL,SRL,SRA)
 *             SLL: type = 5'h0C
 *             SRL: type = 5'h0D
 *             SRA: type = 5'h0E
 *
 ****************************************************************************/
module BarrialShifter32(T, shamt, type, Y, C);
   
   input       [4:0]   type;           // Function Select from MCU
   input       [4:0]   shamt;          // Shifting amount from IR[10:6]
   input      [31:0]   T;              // Data input for shifiting
   output reg          C;              // Carry flag
   output reg [31:0]   Y;              // Shifted output
   
   always@(*)
      case(type)
         5'h0C: // SLL
            case(shamt)
               5'd0:  {C,Y} = {1'b0, T};
               5'd1:  {C,Y} = {T[31], T[30:0],  1'b0};
               5'd2:  {C,Y} = {T[30], T[29:0],  2'b0};
               5'd3:  {C,Y} = {T[29], T[28:0],  3'b0};
               5'd4:  {C,Y} = {T[28], T[27:0],  4'b0};
               5'd5:  {C,Y} = {T[27], T[26:0],  5'b0};
               5'd6:  {C,Y} = {T[26], T[25:0],  6'b0};
               5'd7:  {C,Y} = {T[25], T[24:0],  7'b0};
               5'd8:  {C,Y} = {T[24], T[23:0],  8'b0};
               5'd9:  {C,Y} = {T[23], T[22:0],  9'b0};
               5'd10: {C,Y} = {T[22], T[21:0], 10'b0};
               5'd11: {C,Y} = {T[21], T[20:0], 11'b0};
               5'd12: {C,Y} = {T[20], T[19:0], 12'b0};
               5'd13: {C,Y} = {T[19], T[18:0], 13'b0};
               5'd14: {C,Y} = {T[18], T[17:0], 14'b0};
               5'd15: {C,Y} = {T[17], T[16:0], 15'b0};
               5'd16: {C,Y} = {T[16], T[15:0], 16'b0};
               5'd17: {C,Y} = {T[15], T[14:0], 17'b0};
               5'd18: {C,Y} = {T[14], T[13:0], 18'b0};
               5'd19: {C,Y} = {T[13], T[12:0], 19'b0};
               5'd20: {C,Y} = {T[12], T[11:0], 20'b0};
               5'd21: {C,Y} = {T[11], T[10:0], 21'b0};
               5'd22: {C,Y} = {T[10], T[ 9:0], 22'b0};
               5'd23: {C,Y} = {T[ 9], T[ 8:0], 23'b0};
               5'd24: {C,Y} = {T[ 8], T[ 7:0], 24'b0};
               5'd25: {C,Y} = {T[ 7], T[ 6:0], 25'b0};
               5'd26: {C,Y} = {T[ 6], T[ 5:0], 26'b0};
               5'd27: {C,Y} = {T[ 5], T[ 4:0], 27'b0};
               5'd28: {C,Y} = {T[ 4], T[ 3:0], 28'b0};
               5'd29: {C,Y} = {T[ 3], T[ 2:0], 29'b0};
               5'd30: {C,Y} = {T[ 2], T[ 1:0], 30'b0};
               5'd31: {C,Y} = {T[ 1], T[0],    31'b0};
            endcase
         5'h0D: // SRL
            case(shamt)
               5'd0:  {C,Y} = {1'b0, T};
               5'd1:  {C,Y} = {T[ 0],  1'b0, T[31: 1]};
               5'd2:  {C,Y} = {T[ 1],  2'b0, T[31: 2]};
               5'd3:  {C,Y} = {T[ 2],  3'b0, T[31: 3]};
               5'd4:  {C,Y} = {T[ 3],  4'b0, T[31: 4]};
               5'd5:  {C,Y} = {T[ 4],  5'b0, T[31: 5]};
               5'd6:  {C,Y} = {T[ 5],  6'b0, T[31: 6]};
               5'd7:  {C,Y} = {T[ 6],  7'b0, T[31: 7]};
               5'd8:  {C,Y} = {T[ 7],  8'b0, T[31: 8]};
               5'd9:  {C,Y} = {T[ 8],  9'b0, T[31: 9]};
               5'd10: {C,Y} = {T[ 9], 10'b0, T[31:10]};
               5'd11: {C,Y} = {T[10], 11'b0, T[31:11]};
               5'd12: {C,Y} = {T[11], 12'b0, T[31:12]};
               5'd13: {C,Y} = {T[12], 13'b0, T[31:13]};
               5'd14: {C,Y} = {T[13], 14'b0, T[31:14]};
               5'd15: {C,Y} = {T[14], 15'b0, T[31:15]};
               5'd16: {C,Y} = {T[15], 16'b0, T[31:16]};
               5'd17: {C,Y} = {T[16], 17'b0, T[31:17]};
               5'd18: {C,Y} = {T[17], 18'b0, T[31:18]};
               5'd19: {C,Y} = {T[18], 19'b0, T[31:19]};
               5'd20: {C,Y} = {T[19], 20'b0, T[31:20]};
               5'd21: {C,Y} = {T[20], 21'b0, T[31:21]};
               5'd22: {C,Y} = {T[21], 22'b0, T[31:22]};
               5'd23: {C,Y} = {T[22], 23'b0, T[31:23]};
               5'd24: {C,Y} = {T[23], 24'b0, T[31:24]};
               5'd25: {C,Y} = {T[24], 25'b0, T[31:25]};
               5'd26: {C,Y} = {T[25], 26'b0, T[31:26]};
               5'd27: {C,Y} = {T[26], 27'b0, T[31:27]};
               5'd28: {C,Y} = {T[27], 28'b0, T[31:28]};
               5'd29: {C,Y} = {T[28], 29'b0, T[31:29]};
               5'd30: {C,Y} = {T[29], 30'b0, T[31:30]};
               5'd31: {C,Y} = {T[30], 31'b0, T[31]   };
            endcase
         5'h0E: // SRA
            case(shamt)
               5'd0:  {C,Y} = {1'b0, T};
               5'd1:  {C,Y} = {T[ 0], T[31], { 1{T[31]}}, T[30: 1]};
               5'd2:  {C,Y} = {T[ 1], T[31], { 2{T[31]}}, T[30: 2]};
               5'd3:  {C,Y} = {T[ 2], T[31], { 3{T[31]}}, T[30: 3]};
               5'd4:  {C,Y} = {T[ 3], T[31], { 4{T[31]}}, T[30: 4]};
               5'd5:  {C,Y} = {T[ 4], T[31], { 5{T[31]}}, T[30: 5]};
               5'd6:  {C,Y} = {T[ 5], T[31], { 6{T[31]}}, T[30: 6]};
               5'd7:  {C,Y} = {T[ 6], T[31], { 7{T[31]}}, T[30: 7]};
               5'd8:  {C,Y} = {T[ 7], T[31], { 8{T[31]}}, T[30: 8]};
               5'd9:  {C,Y} = {T[ 8], T[31], { 9{T[31]}}, T[30: 9]};
               5'd10: {C,Y} = {T[ 9], T[31], {10{T[31]}}, T[30:10]};
               5'd11: {C,Y} = {T[10], T[31], {11{T[31]}}, T[30:11]};
               5'd12: {C,Y} = {T[11], T[31], {12{T[31]}}, T[30:12]};
               5'd13: {C,Y} = {T[12], T[31], {13{T[31]}}, T[30:13]};
               5'd14: {C,Y} = {T[13], T[31], {14{T[31]}}, T[30:14]};
               5'd15: {C,Y} = {T[14], T[31], {15{T[31]}}, T[30:15]};
               5'd16: {C,Y} = {T[15], T[31], {16{T[31]}}, T[30:16]};
               5'd17: {C,Y} = {T[16], T[31], {17{T[31]}}, T[30:17]};
               5'd18: {C,Y} = {T[17], T[31], {18{T[31]}}, T[30:18]};
               5'd19: {C,Y} = {T[18], T[31], {19{T[31]}}, T[30:19]};
               5'd20: {C,Y} = {T[19], T[31], {20{T[31]}}, T[30:20]};
               5'd21: {C,Y} = {T[20], T[31], {21{T[31]}}, T[30:21]};
               5'd22: {C,Y} = {T[21], T[31], {22{T[31]}}, T[30:22]};
               5'd23: {C,Y} = {T[22], T[31], {23{T[31]}}, T[30:23]};
               5'd24: {C,Y} = {T[23], T[31], {24{T[31]}}, T[30:24]};
               5'd25: {C,Y} = {T[24], T[31], {25{T[31]}}, T[30:25]};
               5'd26: {C,Y} = {T[25], T[31], {26{T[31]}}, T[30:26]};
               5'd27: {C,Y} = {T[26], T[31], {27{T[31]}}, T[30:27]};
               5'd28: {C,Y} = {T[27], T[31], {28{T[31]}}, T[30:28]};
               5'd29: {C,Y} = {T[28], T[31], {29{T[31]}}, T[30:29]};
               5'd30: {C,Y} = {T[29], T[31], {30{T[31]}}, T[30]   };
               5'd31: {C,Y} = {T[30], T[31], {31{T[31]}}          };
            endcase
//         5'h3: // Rotate Left
//            case(shamt)
//               5'd0:  {C,Y} = T;
//               5'd1:  {C,Y} = {T[30:0], T[31]};
//               5'd2:  {C,Y} = {T[29:0], T[31:30]};
//               5'd3:  {C,Y} = {T[28:0], T[31:29]};
//               5'd4:  {C,Y} = {T[27:0], T[31:28]};
//               5'd5:  {C,Y} = {T[26:0], T[31:27]};
//               5'd6:  {C,Y} = {T[25:0], T[31:26]};
//               5'd7:  {C,Y} = {T[24:0], T[31:25]};
//               5'd8:  {C,Y} = {T[23:0], T[31:24]};
//               5'd9:  {C,Y} = {T[22:0], T[31:23]};
//               5'd10: {C,Y} = {T[21:0], T[31:22]};
//               5'd11: {C,Y} = {T[20:0], T[31:21]};
//               5'd12: {C,Y} = {T[19:0], T[31:20]};
//               5'd13: {C,Y} = {T[18:0], T[31:19]};
//               5'd14: {C,Y} = {T[17:0], T[31:18]};
//               5'd15: {C,Y} = {T[16:0], T[31:17]};
//               5'd16: {C,Y} = {T[15:0], T[31:16]};
//               5'd17: {C,Y} = {T[14:0], T[31:15]};
//               5'd18: {C,Y} = {T[13:0], T[31:14]};
//               5'd19: {C,Y} = {T[12:0], T[31:13]};
//               5'd20: {C,Y} = {T[11:0], T[31:12]};
//               5'd21: {C,Y} = {T[10:0], T[31:11]};
//               5'd22: {C,Y} = {T[9:0],  T[31:10]};
//               5'd23: {C,Y} = {T[8:0],  T[31:9]};
//               5'd24: {C,Y} = {T[7:0],  T[31:8]};
//               5'd25: {C,Y} = {T[6:0],  T[31:7]};
//               5'd26: {C,Y} = {T[5:0],  T[31:6]};
//               5'd27: {C,Y} = {T[4:0],  T[31:5]};
//               5'd28: {C,Y} = {T[3:0],  T[31:4]};
//               5'd29: {C,Y} = {T[2:0],  T[31:3]};
//               5'd30: {C,Y} = {T[1:0],  T[31:2]};
//               5'd31: {C,Y} = {T[0],    T[31:1]};
//            endcase
//         5'h4: // Rotate Right
//            case(shamt)
//               5'd0:  {C,Y} = T;
//               5'd1:  {C,Y} = {T[0],    T[31:1]};
//               5'd2:  {C,Y} = {T[1:0],  T[31:2]};
//               5'd3:  {C,Y} = {T[2:0],  T[31:3]};
//               5'd4:  {C,Y} = {T[3:0],  T[31:4]};
//               5'd5:  {C,Y} = {T[4:0],  T[31:5]};
//               5'd6:  {C,Y} = {T[5:0],  T[31:6]};
//               5'd7:  {C,Y} = {T[6:0],  T[31:7]};
//               5'd8:  {C,Y} = {T[7:0],  T[31:8]};
//               5'd9:  {C,Y} = {T[8:0],  T[31:9]};
//               5'd10: {C,Y} = {T[9:0],  T[31:10]};
//               5'd11: {C,Y} = {T[10:0], T[31:11]};
//               5'd12: {C,Y} = {T[11:0], T[31:12]};
//               5'd13: {C,Y} = {T[12:0], T[31:13]};
//               5'd14: {C,Y} = {T[13:0], T[31:14]};
//               5'd15: {C,Y} = {T[14:0], T[31:15]};
//               5'd16: {C,Y} = {T[15:0], T[31:16]};
//               5'd17: {C,Y} = {T[16:0], T[31:17]};
//               5'd18: {C,Y} = {T[17:0], T[31:18]};
//               5'd19: {C,Y} = {T[18:0], T[31:19]};
//               5'd20: {C,Y} = {T[19:0], T[31:20]};
//               5'd21: {C,Y} = {T[20:0], T[31:21]};
//               5'd22: {C,Y} = {T[21:0], T[31:22]};
//               5'd23: {C,Y} = {T[22:0], T[31:23]};
//               5'd24: {C,Y} = {T[23:0], T[31:24]};
//               5'd25: {C,Y} = {T[24:0], T[31:25]};
//               5'd26: {C,Y} = {T[25:0], T[31:26]};
//               5'd27: {C,Y} = {T[26:0], T[31:27]};
//               5'd28: {C,Y} = {T[27:0], T[31:28]};
//               5'd29: {C,Y} = {T[28:0], T[31:29]};
//               5'd30: {C,Y} = {T[29:0], T[31:30]};
//               5'd31: {C,Y} = {T[30:0], T[31]};
//            endcase
      endcase
endmodule
