///////////////////////////////////////////////////////////////////////////////
//    
//    Company:          Xilinx
//    Engineer:         Jim Tatsukawa, Karl Kurbjun and Carl Ribbing
//						Sam Bobrowicz (Digilent Inc.)
//    Date:             5/30/2013
//    Design Name:      MMCME2 DRP
//    Module Name:      mmcme2_drp.v
//    Version:          1.03
//    Target Devices:   7 Series
//    Tool versions:    14.5
//    Description:      This calls the DRP register calculation functions and
//                      provides a state machine to perform MMCM reconfiguration
//                      based on the calulated values stored in a initialized 
//                      ROM.
//
//    Revisions:        1/13/11 Updated ROM[18,41] LOCKED bitmask to 16'HFC00
//                      5/30/13 Adding Fractional support for CLKFBOUT_MULT_F, CLKOUT0_DIVIDE_F
//						2/02/14 (Digilent, Sam Bobrowicz) Modified to use values provided from a top
//								level to output CLK0 with runtime configurable frequency. Also added
//								parameter for controlling what the default output clock is (affecting
//								the automatically generated timing constraints).
//
// 
//    Disclaimer:  XILINX IS PROVIDING THIS DESIGN, CODE, OR
//                 INFORMATION "AS IS" SOLELY FOR USE IN DEVELOPING
//                 PROGRAMS AND SOLUTIONS FOR XILINX DEVICES.  BY
//                 PROVIDING THIS DESIGN, CODE, OR INFORMATION AS
//                 ONE POSSIBLE IMPLEMENTATION OF THIS FEATURE,
//                 APPLICATION OR STANDARD, XILINX IS MAKING NO
//                 REPRESENTATION THAT THIS IMPLEMENTATION IS FREE
//                 FROM ANY CLAIMS OF INFRINGEMENT, AND YOU ARE
//                 RESPONSIBLE FOR OBTAINING ANY RIGHTS YOU MAY
//                 REQUIRE FOR YOUR IMPLEMENTATION.  XILINX
//                 EXPRESSLY DISCLAIMS ANY WARRANTY WHATSOEVER WITH
//                 RESPECT TO THE ADEQUACY OF THE IMPLEMENTATION,
//                 INCLUDING BUT NOT LIMITED TO ANY WARRANTIES OR
//                 REPRESENTATIONS THAT THIS IMPLEMENTATION IS FREE
//                 FROM CLAIMS OF INFRINGEMENT, IMPLIED WARRANTIES
//                 OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
//                 PURPOSE.
// 
//                 (c) Copyright 2009-2010 Xilinx, Inc.
//                 All rights reserved.
// 
///////////////////////////////////////////////////////////////////////////////

`timescale 1ps/1ps

module mmcme2_drp
 #(
      parameter DIV_F          = 5
   )
   (
      // These signals are controlled by user logic interface and are covered
      // in more detail within the XAPP.
      input             SEN,
      input             SCLK,
      input             RST,
      output reg        SRDY,
		
		input 	[35:0]	S1_CLKOUT0,
		input 	[35:0]	S1_CLKFBOUT,
		input 	[13:0]	S1_DIVCLK,
		input 	[39:0]	S1_LOCK,
		input 	[9:0]		S1_DIGITAL_FILT,
		
		input					REF_CLK,
		output				PXL_CLK,
		output				CLKFBOUT_O,
		input				CLKFBOUT_I,
		output				LOCKED_O
    
   );

   // 100 ps delay for behavioral simulations
   localparam  TCQ = 100;
   
   wire [38:0]  rom [12:0];  // 39 bit word 13 words deep array of reg writes to perform (no longer a ROM)
   reg [3:0]   rom_addr;
   reg [38:0]  rom_do;
   
   reg         next_srdy;

   reg [3:0]   next_rom_addr;
   reg [6:0]   next_daddr;
   reg         next_dwe;
   reg         next_den;
   reg         next_rst_mmcm;
   reg [15:0]  next_di;
	
	// These signals are to be connected to the MMCM_ADV by port name.
	// Their use matches the MMCM port description in the Device User Guide.
   wire      [15:0] DO;
   wire             DRDY;
   wire             LOCKED;
   reg        		  DWE;
   reg        		  DEN;
   reg [6:0]  		  DADDR;
   reg [15:0] 		  DI;
   wire             DCLK;
   reg        		  RST_MMCM;

   
   // Pass SCLK to DCLK for the MMCM
   assign DCLK = SCLK;

      // rom entries contain (in order) the address, a bitmask, and a bitset
      //***********************************************************************
      // State 1 Initialization
      //***********************************************************************
      
      // Store the power bits
      assign rom[0] = {7'h28, 16'h0000, 16'hFFFF};
      
      // Store CLKOUT0 divide and phase
      assign rom[1]  =  {7'h08, 16'h1000, S1_CLKOUT0[15:0]};
      assign rom[2]  =  {7'h09, 16'h8000, S1_CLKOUT0[31:16]};
						
      // Store CLKOUT0 additional frac values
      assign rom[3] = {7'h07, 16'hC3FF, 2'b00 , S1_CLKOUT0[35:32], 10'h000}; 
      
      // Store CLKFBOUT additional frac values
      assign rom[4] = {7'h13, 16'hC3FF, 2'b00 , S1_CLKFBOUT[35:32], 10'h000};
      
      // Store the input divider
      assign rom[5] = {7'h16, 16'hC000, {2'h0, S1_DIVCLK[13:0]} };
      
      // Store CLKFBOUT divide and phase
      assign rom[6] = {7'h14, 16'h1000, S1_CLKFBOUT[15:0]};
      assign rom[7] = {7'h15, 16'h8000, S1_CLKFBOUT[31:16]};
    
      // Store the lock settings
      assign rom[8] = {7'h18, 16'hFC00, {6'h00, S1_LOCK[29:20]} };
      assign rom[9] = {7'h19, 16'h8000, {1'b0 , S1_LOCK[34:30], S1_LOCK[9:0]} };
      assign rom[10] = {7'h1A, 16'h8000, {1'b0 , S1_LOCK[39:35], S1_LOCK[19:10]} };
      
      // Store the filter settings
      assign rom[11] = {7'h4E, 16'h66FF, 
                S1_DIGITAL_FILT[9], 2'h0, S1_DIGITAL_FILT[8:7], 2'h0, 
                S1_DIGITAL_FILT[6], 8'h00 };
      assign rom[12] = {7'h4F, 16'h666F, 
                S1_DIGITAL_FILT[5], 2'h0, S1_DIGITAL_FILT[4:3], 2'h0,
                S1_DIGITAL_FILT[2:1], 2'h0, S1_DIGITAL_FILT[0], 4'h0 };

   // Output the initialized rom value based on rom_addr each clock cycle
   always @(posedge SCLK) begin
      rom_do<= #TCQ rom[rom_addr];
   end
   
   //**************************************************************************
   // Everything below is associated whith the state machine that is used to
   // Read/Modify/Write to the MMCM.
   //**************************************************************************
   
   // State Definitions
   localparam RESTART      = 4'h1;
   localparam WAIT_LOCK    = 4'h2;
   localparam WAIT_SEN     = 4'h3;
   localparam ADDRESS      = 4'h4;
   localparam WAIT_A_DRDY  = 4'h5;
   localparam BITMASK      = 4'h6;
   localparam BITSET       = 4'h7;
   localparam WRITE        = 4'h8;
   localparam WAIT_DRDY    = 4'h9;
   
   // State sync
   reg [3:0]  current_state   = RESTART;
   reg [3:0]  next_state      = RESTART;
   
   // These variables are used to keep track of the number of iterations that 
   //    each state takes to reconfigure.
   // STATE_COUNT_CONST is used to reset the counters and should match the
   //    number of registers necessary to reconfigure each state.
   localparam STATE_COUNT_CONST  = 13;
   reg [3:0] state_count         = STATE_COUNT_CONST; 
   reg [3:0] next_state_count    = STATE_COUNT_CONST;
   
   // This block assigns the next register value from the state machine below
   always @(posedge SCLK) begin
      DADDR       <= #TCQ next_daddr;
      DWE         <= #TCQ next_dwe;
      DEN         <= #TCQ next_den;
      RST_MMCM    <= #TCQ next_rst_mmcm;
      DI          <= #TCQ next_di;
      
      SRDY        <= #TCQ next_srdy;
      
      rom_addr    <= #TCQ next_rom_addr;
      state_count <= #TCQ next_state_count;
   end
   
   // This block assigns the next state, reset is syncronous.
   always @(posedge SCLK) begin
      if(RST) begin
         current_state <= #TCQ RESTART;
      end else begin
         current_state <= #TCQ next_state;
      end
   end
   
   always @* begin
      // Setup the default values
      next_srdy         = 1'b0;
      next_daddr        = DADDR;
      next_dwe          = 1'b0;
      next_den          = 1'b0;
      next_rst_mmcm     = RST_MMCM;
      next_di           = DI;
      next_rom_addr     = rom_addr;
      next_state_count  = state_count;
   
      case (current_state)
         // If RST is asserted reset the machine
         RESTART: begin
            next_daddr     = 7'h00;
            next_di        = 16'h0000;
            next_rom_addr  = 6'h00;
            next_rst_mmcm  = 1'b1;
            next_state     = WAIT_LOCK;
         end
         
         // Waits for the MMCM to assert LOCKED - once it does asserts SRDY
         WAIT_LOCK: begin
            // Make sure reset is de-asserted
            next_rst_mmcm   = 1'b0;
            // Reset the number of registers left to write for the next 
            // reconfiguration event.
            next_state_count = STATE_COUNT_CONST ;
            
            if(LOCKED) begin
               // MMCM is locked, go on to wait for the SEN signal
               next_state  = WAIT_SEN;
               // Assert SRDY to indicate that the reconfiguration module is
               // ready
               next_srdy   = 1'b1;
            end else begin
               // Keep waiting, locked has not asserted yet
               next_state  = WAIT_LOCK;
            end
         end
         
         // Wait for the next SEN pulse and set the ROM addr appropriately 
         WAIT_SEN: begin
            if (SEN) begin
               // SEN was asserted
					next_rom_addr = 8'h00;

               // Go on to address the MMCM
               next_state = ADDRESS;
            end else begin
               // Keep waiting for SEN to be asserted
               next_state = WAIT_SEN;
            end
         end
         
         // Set the address on the MMCM and assert DEN to read the value
         ADDRESS: begin
            // Reset the DCM through the reconfiguration
            next_rst_mmcm  = 1'b1;
            // Enable a read from the MMCM and set the MMCM address
            next_den       = 1'b1;
            next_daddr     = rom_do[38:32];
            
            // Wait for the data to be ready
            next_state     = WAIT_A_DRDY;
         end
         
         // Wait for DRDY to assert after addressing the MMCM
         WAIT_A_DRDY: begin
            if (DRDY) begin
               // Data is ready, mask out the bits to save
               next_state = BITMASK;
            end else begin
               // Keep waiting till data is ready
               next_state = WAIT_A_DRDY;
            end
         end
         
         // Zero out the bits that are not set in the mask stored in rom
         BITMASK: begin
            // Do the mask
            next_di     = rom_do[31:16] & DO;
            // Go on to set the bits
            next_state  = BITSET;
         end
         
         // After the input is masked, OR the bits with calculated value in rom
         BITSET: begin
            // Set the bits that need to be assigned
            next_di           = rom_do[15:0] | DI;
            // Set the next address to read from ROM
            next_rom_addr     = rom_addr + 1'b1;
            // Go on to write the data to the MMCM
            next_state        = WRITE;
         end
         
         // DI is setup so assert DWE, DEN, and RST_MMCM.  Subtract one from the
         //    state count and go to wait for DRDY.
         WRITE: begin
            // Set WE and EN on MMCM
            next_dwe          = 1'b1;
            next_den          = 1'b1;
            
            // Decrement the number of registers left to write
            next_state_count  = state_count - 1'b1;
            // Wait for the write to complete
            next_state        = WAIT_DRDY;
         end
         
         // Wait for DRDY to assert from the MMCM.  If the state count is not 0
         //    jump to ADDRESS (continue reconfiguration).  If state count is
         //    0 wait for lock.
         WAIT_DRDY: begin
            if(DRDY) begin
               // Write is complete
               if(state_count > 0) begin
                  // If there are more registers to write keep going
                  next_state  = ADDRESS;
               end else begin
                  // There are no more registers to write so wait for the MMCM
                  // to lock
                  next_state  = WAIT_LOCK;
               end
            end else begin
               // Keep waiting for write to complete
               next_state     = WAIT_DRDY;
            end
         end
         
         // If in an unknown state reset the machine
         default: begin
            next_state = RESTART;
         end
      endcase
   end
	
//////////////////////////////////////////////////////////////////////////////////////
/////////                   MMCM Instantiation                             ///////////
//////////////////////////////////////////////////////////////////////////////////////


  // Clocking primitive
  //------------------------------------
  // Instantiation of the MMCM primitive
  //    * Unused inputs are tied off
  //    * Unused outputs are labeled unused
  wire        psdone_unused;
  wire        clkfboutb_unused;
  wire        clkout0b_unused;
  wire        clkout1_unused;
  wire        clkout1b_unused;
  wire        clkout2_unused;
  wire        clkout2b_unused;
  wire        clkout3_unused;
  wire        clkout3b_unused;
  wire        clkout4_unused;
  wire        clkout5_unused;
  wire        clkout6_unused;
  wire        clkfbstopped_unused;
  wire        clkinstopped_unused;

  MMCME2_ADV
  #(.BANDWIDTH            ("OPTIMIZED"),
    .CLKOUT4_CASCADE      ("FALSE"),
    .COMPENSATION         ("ZHOLD"),
    .STARTUP_WAIT         ("FALSE"),
    .DIVCLK_DIVIDE        (1),
    .CLKFBOUT_MULT_F      (10.000),
    .CLKFBOUT_PHASE       (0.000),
    .CLKFBOUT_USE_FINE_PS ("FALSE"),
    .CLKOUT0_DIVIDE_F     (DIV_F),
    .CLKOUT0_PHASE        (0.000),
    .CLKOUT0_DUTY_CYCLE   (0.500),
    .CLKOUT0_USE_FINE_PS  ("FALSE"),
    .CLKIN1_PERIOD        (10.000),
    .REF_JITTER1          (0.010))
  mmcm_adv_inst
    // Output clocks
   (.CLKFBOUT            (CLKFBOUT_O),
    .CLKFBOUTB           (clkfboutb_unused),
    .CLKOUT0             (PXL_CLK),
    .CLKOUT0B            (clkout0b_unused),
    .CLKOUT1             (clkout1_unused),
    .CLKOUT1B            (clkout1b_unused),
    .CLKOUT2             (clkout2_unused),
    .CLKOUT2B            (clkout2b_unused),
    .CLKOUT3             (clkout3_unused),
    .CLKOUT3B            (clkout3b_unused),
    .CLKOUT4             (clkout4_unused),
    .CLKOUT5             (clkout5_unused),
    .CLKOUT6             (clkout6_unused),
     // Input clock control
    .CLKFBIN             (CLKFBOUT_I),
    .CLKIN1              (REF_CLK),
    .CLKIN2              (1'b0),
     // Tied to always select the primary input clock
    .CLKINSEL            (1'b1),
    // Ports for dynamic reconfiguration
    .DADDR               (DADDR),
    .DCLK                (DCLK),
    .DEN                 (DEN),
    .DI                  (DI),
    .DO                  (DO),
    .DRDY                (DRDY),
    .DWE                 (DWE),
    // Ports for dynamic phase shift
    .PSCLK               (1'b0),
    .PSEN                (1'b0),
    .PSINCDEC            (1'b0),
    .PSDONE              (psdone_unused),
    // Other control and status signals
    .LOCKED              (LOCKED),
    .CLKINSTOPPED        (clkinstopped_unused),
    .CLKFBSTOPPED        (clkfbstopped_unused),
    .PWRDWN              (1'b0),
    .RST                 (RST_MMCM));


   assign LOCKED_O = LOCKED;
	
	
endmodule
