// -- (c) Copyright 2010 - 2011 Xilinx, Inc. All rights reserved.
// --
// -- This file contains confidential and proprietary information
// -- of Xilinx, Inc. and is protected under U.S. and 
// -- international copyright and other intellectual property
// -- laws.
// --
// -- DISCLAIMER
// -- This disclaimer is not a license and does not grant any
// -- rights to the materials distributed herewith. Except as
// -- otherwise provided in a valid license issued to you by
// -- Xilinx, and to the maximum extent permitted by applicable
// -- law: (1) THESE MATERIALS ARE MADE AVAILABLE "AS IS" AND
// -- WITH ALL FAULTS, AND XILINX HEREBY DISCLAIMS ALL WARRANTIES
// -- AND CONDITIONS, EXPRESS, IMPLIED, OR STATUTORY, INCLUDING
// -- BUT NOT LIMITED TO WARRANTIES OF MERCHANTABILITY, NON-
// -- INFRINGEMENT, OR FITNESS FOR ANY PARTICULAR PURPOSE; and
// -- (2) Xilinx shall not be liable (whether in contract or tort,
// -- including negligence, or under any other theory of
// -- liability) for any loss or damage of any kind or nature
// -- related to, arising under or in connection with these
// -- materials, including for any direct, or any indirect,
// -- special, incidental, or consequential loss or damage
// -- (including loss of data, profits, goodwill, or any type of
// -- loss or damage suffered as a result of any action brought
// -- by a third party) even if such damage or loss was
// -- reasonably foreseeable or Xilinx had been advised of the
// -- possibility of the same.
// --
// -- CRITICAL APPLICATIONS
// -- Xilinx products are not designed or intended to be fail-
// -- safe, or for use in any application requiring fail-safe
// -- performance, such as life-support or safety devices or
// -- systems, Class III medical devices, nuclear facilities,
// -- applications related to the deployment of airbags, or any
// -- other applications that could lead to death, personal
// -- injury, or severe property or environmental damage
// -- (individually and collectively, "Critical
// -- Applications"). Customer assumes the sole risk and
// -- liability of any use of Xilinx products in Critical
// -- Applications, subject only to applicable laws and
// -- regulations governing limitations on product liability.
// --
// -- THIS COPYRIGHT NOTICE AND DISCLAIMER MUST BE RETAINED AS
// -- PART OF THIS FILE AT ALL TIMES.
//-----------------------------------------------------------------------------
//
// Description: 
//  Optimized 16/32 word deep FIFO.
//
// Verilog-standard:  Verilog 2001
//--------------------------------------------------------------------------
//
// Structure:
//   
//
//--------------------------------------------------------------------------
`timescale 1ps/1ps


(* DowngradeIPIdentifiedWarnings="yes" *) 
module generic_baseblocks_v2_1_0_command_fifo #
  (
   parameter         C_FAMILY                        = "virtex6",
   parameter integer C_ENABLE_S_VALID_CARRY          = 0,
   parameter integer C_ENABLE_REGISTERED_OUTPUT      = 0,
   parameter integer C_FIFO_DEPTH_LOG                = 5,      // FIFO depth = 2**C_FIFO_DEPTH_LOG
                                                               // Range = [4:5].
   parameter integer C_FIFO_WIDTH                    = 64      // Width of payload [1:512]
   )
  (
   // Global inputs
   input  wire                        ACLK,    // Clock
   input  wire                        ARESET,  // Reset
   // Information
   output wire                        EMPTY,   // FIFO empty (all stages)
   // Slave  Port
   input  wire [C_FIFO_WIDTH-1:0]     S_MESG,  // Payload (may be any set of channel signals)
   input  wire                        S_VALID, // FIFO push
   output wire                        S_READY, // FIFO not full
   // Master  Port
   output wire [C_FIFO_WIDTH-1:0]     M_MESG,  // Payload
   output wire                        M_VALID, // FIFO not empty
   input  wire                        M_READY  // FIFO pop
   );

  /////////////////////////////////////////////////////////////////////////////
  // Variables for generating parameter controlled instances.
  /////////////////////////////////////////////////////////////////////////////
  
  // Generate variable for data vector.
  genvar addr_cnt;
  genvar bit_cnt;
  integer index;
  
  
  /////////////////////////////////////////////////////////////////////////////
  // Internal signals
  /////////////////////////////////////////////////////////////////////////////
  
  wire [C_FIFO_DEPTH_LOG-1:0] addr;
  wire                        buffer_Full;
  wire                        buffer_Empty;
  
  wire                        next_Data_Exists;
  reg                         data_Exists_I;
  
  wire                        valid_Write;
  wire                        new_write;
  
  wire [C_FIFO_DEPTH_LOG-1:0] hsum_A;
  wire [C_FIFO_DEPTH_LOG-1:0] sum_A;
  wire [C_FIFO_DEPTH_LOG-1:0] addr_cy;

  wire                        buffer_full_early;
  
  wire [C_FIFO_WIDTH-1:0]     M_MESG_I;   // Payload
  wire                        M_VALID_I;  // FIFO not empty
  wire                        M_READY_I;  // FIFO pop
  
  /////////////////////////////////////////////////////////////////////////////
  // Create Flags 
  /////////////////////////////////////////////////////////////////////////////
  
  assign buffer_full_early  = ( (addr == {{C_FIFO_DEPTH_LOG-1{1'b1}}, 1'b0}) & valid_Write & ~M_READY_I ) |
                              ( buffer_Full & ~M_READY_I );

  assign S_READY            = ~buffer_Full;

  assign buffer_Empty       = (addr == {C_FIFO_DEPTH_LOG{1'b0}});

  assign next_Data_Exists   = (data_Exists_I & ~buffer_Empty) |
                              (buffer_Empty & S_VALID) |
                              (data_Exists_I & ~(M_READY_I & data_Exists_I));

  always @ (posedge ACLK) begin
    if (ARESET) begin
      data_Exists_I <= 1'b0;
    end else begin
      data_Exists_I <= next_Data_Exists;
    end
  end

  assign M_VALID_I = data_Exists_I;
  
  // Select RTL or FPGA optimized instatiations for critical parts.
  generate
    if ( C_FAMILY == "rtl" || C_ENABLE_S_VALID_CARRY == 0 ) begin : USE_RTL_VALID_WRITE
      reg                         buffer_Full_q;
      
      assign valid_Write = S_VALID & ~buffer_Full;
      
      assign new_write = (S_VALID | ~buffer_Empty);
     
      assign addr_cy[0] = valid_Write;
      
      always @ (posedge ACLK) begin
        if (ARESET) begin
          buffer_Full_q <= 1'b0;
        end else if ( data_Exists_I ) begin
          buffer_Full_q <= buffer_full_early;
        end
      end
      assign buffer_Full = buffer_Full_q;
      
    end else begin : USE_FPGA_VALID_WRITE
      wire s_valid_dummy1;
      wire s_valid_dummy2;
      wire sel_s_valid;
      wire sel_new_write;
      wire valid_Write_dummy1;
      wire valid_Write_dummy2;
      
      assign sel_s_valid = ~buffer_Full;
      
      generic_baseblocks_v2_1_0_carry_and #
        (
         .C_FAMILY(C_FAMILY)
         ) s_valid_dummy_inst1
        (
         .CIN(S_VALID),
         .S(1'b1),
         .COUT(s_valid_dummy1)
         );
      
      generic_baseblocks_v2_1_0_carry_and #
        (
         .C_FAMILY(C_FAMILY)
         ) s_valid_dummy_inst2
        (
         .CIN(s_valid_dummy1),
         .S(1'b1),
         .COUT(s_valid_dummy2)
         );
      
      generic_baseblocks_v2_1_0_carry_and #
        (
         .C_FAMILY(C_FAMILY)
         ) valid_write_inst
        (
         .CIN(s_valid_dummy2),
         .S(sel_s_valid),
         .COUT(valid_Write)
         );
      
      assign sel_new_write = ~buffer_Empty;
       
      generic_baseblocks_v2_1_0_carry_latch_or #
        (
         .C_FAMILY(C_FAMILY)
         ) new_write_inst
        (
         .CIN(valid_Write),
         .I(sel_new_write),
         .O(new_write)
         );
         
      generic_baseblocks_v2_1_0_carry_and #
        (
         .C_FAMILY(C_FAMILY)
         ) valid_write_dummy_inst1
        (
         .CIN(valid_Write),
         .S(1'b1),
         .COUT(valid_Write_dummy1)
         );
      
      generic_baseblocks_v2_1_0_carry_and #
        (
         .C_FAMILY(C_FAMILY)
         ) valid_write_dummy_inst2
        (
         .CIN(valid_Write_dummy1),
         .S(1'b1),
         .COUT(valid_Write_dummy2)
         );
      
      generic_baseblocks_v2_1_0_carry_and #
        (
         .C_FAMILY(C_FAMILY)
         ) valid_write_dummy_inst3
        (
         .CIN(valid_Write_dummy2),
         .S(1'b1),
         .COUT(addr_cy[0])
         );
      
      FDRE #(
       .INIT(1'b0)              // Initial value of register (1'b0 or 1'b1)
       ) FDRE_I1 (
       .Q(buffer_Full),         // Data output
       .C(ACLK),                // Clock input
       .CE(data_Exists_I),      // Clock enable input
       .R(ARESET),              // Synchronous reset input
       .D(buffer_full_early)    // Data input
       );
       
    end
  endgenerate
      
    
  /////////////////////////////////////////////////////////////////////////////
  // Create address pointer
  /////////////////////////////////////////////////////////////////////////////

  generate
    if ( C_FAMILY == "rtl" ) begin : USE_RTL_ADDR
    
      reg  [C_FIFO_DEPTH_LOG-1:0] addr_q;
      
      always @ (posedge ACLK) begin
        if (ARESET) begin
          addr_q <= {C_FIFO_DEPTH_LOG{1'b0}};
        end else if ( data_Exists_I ) begin
          if ( valid_Write & ~(M_READY_I & data_Exists_I) ) begin
            addr_q <= addr_q + 1'b1;
          end else if ( ~valid_Write & (M_READY_I & data_Exists_I) & ~buffer_Empty ) begin
            addr_q <= addr_q - 1'b1;
          end
          else begin
            addr_q <= addr_q;
          end
        end
        else begin
          addr_q <= addr_q;
        end
      end
      
      assign addr = addr_q;
      
    end else begin : USE_FPGA_ADDR
      for (addr_cnt = 0; addr_cnt < C_FIFO_DEPTH_LOG ; addr_cnt = addr_cnt + 1) begin : ADDR_GEN
        assign hsum_A[addr_cnt] = ((M_READY_I & data_Exists_I) ^ addr[addr_cnt]) & new_write;
        
        // Don't need the last muxcy, addr_cy(last) is not used anywhere
        if ( addr_cnt < C_FIFO_DEPTH_LOG - 1 ) begin : USE_MUXCY
          MUXCY MUXCY_inst (
           .DI(addr[addr_cnt]),
           .CI(addr_cy[addr_cnt]),
           .S(hsum_A[addr_cnt]),
           .O(addr_cy[addr_cnt+1])
           );
           
        end
        else begin : NO_MUXCY
        end
        
        XORCY XORCY_inst (
         .LI(hsum_A[addr_cnt]),
         .CI(addr_cy[addr_cnt]),
         .O(sum_A[addr_cnt])
         );
        
        FDRE #(
         .INIT(1'b0)             // Initial value of register (1'b0 or 1'b1)
         ) FDRE_inst (
         .Q(addr[addr_cnt]),     // Data output
         .C(ACLK),               // Clock input
         .CE(data_Exists_I),     // Clock enable input
         .R(ARESET),             // Synchronous reset input
         .D(sum_A[addr_cnt])     // Data input
         );
        
      end // end for bit_cnt
    end // C_FAMILY
  endgenerate
      
      
  /////////////////////////////////////////////////////////////////////////////
  // Data storage
  /////////////////////////////////////////////////////////////////////////////
  
  generate
    if ( C_FAMILY == "rtl" ) begin : USE_RTL_FIFO
      reg  [C_FIFO_WIDTH-1:0] data_srl[2 ** C_FIFO_DEPTH_LOG-1:0];
      
      always @ (posedge ACLK) begin
        if ( valid_Write ) begin
          for (index = 0; index < 2 ** C_FIFO_DEPTH_LOG-1 ; index = index + 1) begin
            data_srl[index+1] <= data_srl[index];
          end
          data_srl[0]   <= S_MESG;
        end
      end
      
      assign M_MESG_I = data_srl[addr];
      
    end else begin : USE_FPGA_FIFO
      for (bit_cnt = 0; bit_cnt < C_FIFO_WIDTH ; bit_cnt = bit_cnt + 1) begin : DATA_GEN
        
        if ( C_FIFO_DEPTH_LOG == 5 ) begin : USE_32
            SRLC32E # (
             .INIT(32'h00000000)    // Initial Value of Shift Register
            ) SRLC32E_inst (
             .Q(M_MESG_I[bit_cnt]), // SRL data output
             .Q31(),                // SRL cascade output pin
             .A(addr),              // 5-bit shift depth select input
             .CE(valid_Write),      // Clock enable input
             .CLK(ACLK),            // Clock input
             .D(S_MESG[bit_cnt])    // SRL data input
            );
        end else begin : USE_16
            SRLC16E # (
             .INIT(32'h00000000)    // Initial Value of Shift Register
            ) SRLC16E_inst (
             .Q(M_MESG_I[bit_cnt]), // SRL data output
             .Q15(),                // SRL cascade output pin
             .A0(addr[0]),          // 4-bit shift depth select input 0
             .A1(addr[1]),          // 4-bit shift depth select input 1
             .A2(addr[2]),          // 4-bit shift depth select input 2
             .A3(addr[3]),          // 4-bit shift depth select input 3
             .CE(valid_Write),      // Clock enable input
             .CLK(ACLK),            // Clock input
             .D(S_MESG[bit_cnt])    // SRL data input
            );
        end // C_FIFO_DEPTH_LOG
      
      end // end for bit_cnt
    end // C_FAMILY
  endgenerate
  
  
  /////////////////////////////////////////////////////////////////////////////
  // Pipeline stage
  /////////////////////////////////////////////////////////////////////////////
  
  generate
    if ( C_ENABLE_REGISTERED_OUTPUT != 0 ) begin : USE_FF_OUT
      
      wire [C_FIFO_WIDTH-1:0]     M_MESG_FF;    // Payload
      wire                        M_VALID_FF;   // FIFO not empty
      
      // Select RTL or FPGA optimized instatiations for critical parts.
      if ( C_FAMILY == "rtl" ) begin : USE_RTL_OUTPUT_PIPELINE
      
        reg  [C_FIFO_WIDTH-1:0]     M_MESG_Q;   // Payload
        reg                         M_VALID_Q;  // FIFO not empty
        
        always @ (posedge ACLK) begin
          if (ARESET) begin
            M_MESG_Q    <= {C_FIFO_WIDTH{1'b0}};
            M_VALID_Q   <= 1'b0;
          end else begin
            if ( M_READY_I ) begin
              M_MESG_Q    <= M_MESG_I;
              M_VALID_Q   <= M_VALID_I;
            end
          end
        end
      
        assign M_MESG_FF     = M_MESG_Q;
        assign M_VALID_FF    = M_VALID_Q;
        
      end else begin : USE_FPGA_OUTPUT_PIPELINE
      
        reg  [C_FIFO_WIDTH-1:0]     M_MESG_CMB;   // Payload
        reg                         M_VALID_CMB;  // FIFO not empty
        
        always @ *
        begin
          if ( M_READY_I ) begin
            M_MESG_CMB  <= M_MESG_I;
            M_VALID_CMB <= M_VALID_I;
          end else begin
            M_MESG_CMB  <= M_MESG_FF;
            M_VALID_CMB <= M_VALID_FF;
          end
        end
        
        for (bit_cnt = 0; bit_cnt < C_FIFO_WIDTH ; bit_cnt = bit_cnt + 1) begin : DATA_GEN
              
          FDRE #(
           .INIT(1'b0)                    // Initial value of register (1'b0 or 1'b1)
           ) FDRE_inst (
           .Q(M_MESG_FF[bit_cnt]),        // Data output
           .C(ACLK),                      // Clock input
           .CE(1'b1),                     // Clock enable input
           .R(ARESET),                    // Synchronous reset input
           .D(M_MESG_CMB[bit_cnt])        // Data input
           );
        end // end for bit_cnt
            
        FDRE #(
         .INIT(1'b0)                    // Initial value of register (1'b0 or 1'b1)
         ) FDRE_inst (
         .Q(M_VALID_FF),                // Data output
         .C(ACLK),                      // Clock input
         .CE(1'b1),                     // Clock enable input
         .R(ARESET),                    // Synchronous reset input
         .D(M_VALID_CMB)                // Data input
         );
      
      end
      
      assign EMPTY      = ~M_VALID_I & ~M_VALID_FF;
      assign M_MESG     = M_MESG_FF;
      assign M_VALID    = M_VALID_FF;
      assign M_READY_I  = ( M_READY & M_VALID_FF ) | ~M_VALID_FF;
      
    end else begin : NO_FF_OUT
      
      assign EMPTY      = ~M_VALID_I;
      assign M_MESG     = M_MESG_I;
      assign M_VALID    = M_VALID_I;
      assign M_READY_I  = M_READY;
      
    end
  endgenerate

endmodule
