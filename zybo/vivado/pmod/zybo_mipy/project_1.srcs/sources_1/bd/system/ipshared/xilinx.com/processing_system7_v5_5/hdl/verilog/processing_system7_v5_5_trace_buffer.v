// -- (c) Copyright 2009 - 2011 Xilinx, Inc. All rights reserved.
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
// Filename:      trace_buffer.v
// Description:   Trace port buffer 
//-----------------------------------------------------------------------------
// Structure:   This section shows the hierarchical structure of 
//              pss_wrapper.
//
//              --processing_system7
//							 |	
//							 --trace_buffer
//-----------------------------------------------------------------------------


module processing_system7_v5_5_trace_buffer #
  (
   parameter integer FIFO_SIZE = 128,
	parameter integer USE_TRACE_DATA_EDGE_DETECTOR = 0,
   parameter integer C_DELAY_CLKS = 12
   )
  (
   input wire TRACE_CLK,
   input wire RST,
   input wire TRACE_VALID_IN,
   input wire [3:0] TRACE_ATID_IN,
   input wire [31:0] TRACE_DATA_IN,
   output wire TRACE_VALID_OUT,
   output wire [3:0] TRACE_ATID_OUT,
   output wire [31:0] TRACE_DATA_OUT
  );

//------------------------------------------------------------
// Architecture section
//------------------------------------------------------------

// function called clogb2 that returns an integer which has the 
// value of the ceiling of the log base 2.

function integer clogb2 (input integer bit_depth);
 integer i;
 integer temp_log;
 begin
  temp_log = 0;
  for(i=bit_depth; i > 0; i = i>>1)
  clogb2 = temp_log;
  temp_log=temp_log+1;		
 end
endfunction

localparam DEPTH  = clogb2(FIFO_SIZE-1);

wire [31:0] reset_zeros;
reg  [31:0] trace_pedge; // write enable for FIFO
reg  [31:0] ti;
reg  [31:0] tom;

reg  [3:0] atid;

reg [31:0] trace_fifo [FIFO_SIZE-1:0];//Memory 

reg  [4:0]  dly_ctr;
reg  [DEPTH-1:0]  fifo_wp;
reg  [DEPTH-1:0]  fifo_rp;

reg         fifo_re;
wire        fifo_empty;
wire        fifo_full;
reg         fifo_full_reg;

assign reset_zeros = 32'h0;  


// Pipeline Stage for Traceport ATID ports
  always @(posedge TRACE_CLK) begin
    // process pedge_ti
    // rising clock edge
    if((RST == 1'b1)) begin
      atid <= reset_zeros;
    end
    else begin	 
      atid <= TRACE_ATID_IN;
	 end
  end

  assign TRACE_ATID_OUT = atid;
  
  /////////////////////////////////////////////
  // Generate FIFO data based on TRACE_VALID_IN
  /////////////////////////////////////////////
  generate
    if (USE_TRACE_DATA_EDGE_DETECTOR == 0) begin : gen_no_data_edge_detector
  /////////////////////////////////////////////
        
		  // memory update process
		  // Update memory when positive edge detected and FIFO not full
		  always @(posedge TRACE_CLK) begin
				if (TRACE_VALID_IN == 1'b1 && fifo_full_reg != 1'b1) begin
					trace_fifo[fifo_wp]  <= TRACE_DATA_IN;
				end
		  end

		  // fifo write pointer
		  always @(posedge TRACE_CLK) begin
				// process
			 if(RST == 1'b1) begin
				fifo_wp <= {DEPTH{1'b0}};
			 end
			 else if(TRACE_VALID_IN ) begin
				if(fifo_wp == (FIFO_SIZE - 1)) begin
				  if (fifo_empty) begin
					 fifo_wp <= {DEPTH{1'b0}};
				  end
				end
				else begin
				  fifo_wp <= fifo_wp + 1;
				end
			 end
		  end


  /////////////////////////////////////////////
  // Generate FIFO data based on data edge
  /////////////////////////////////////////////
    end else begin : gen_data_edge_detector
  /////////////////////////////////////////////


		  // purpose: check for pos edge on any trace input
		  always @(posedge TRACE_CLK) begin
			 // process pedge_ti
			 // rising clock edge
			 if((RST == 1'b1)) begin
				ti          <= reset_zeros;
				trace_pedge <= reset_zeros;
			 end
			 else begin
				ti          <= TRACE_DATA_IN;
				trace_pedge <= (~ti & TRACE_DATA_IN);
				//trace_pedge <= ((~ti ^ TRACE_DATA_IN)) &  ~ti;
				// posedge only
			 end
		  end
		  
		  // memory update process
		  // Update memory when positive edge detected and FIFO not full
		  always @(posedge TRACE_CLK) begin
			 if(|(trace_pedge)  == 1'b1 && fifo_full_reg != 1'b1) begin
				trace_fifo[fifo_wp]  <= trace_pedge;
			 end
		  end

		  // fifo write pointer
		  always @(posedge TRACE_CLK) begin
				// process
			 if(RST == 1'b1) begin
				fifo_wp <= {DEPTH{1'b0}};
			 end
			 else if(|(trace_pedge)  == 1'b1) begin
				if(fifo_wp == (FIFO_SIZE - 1)) begin
				  if (fifo_empty) begin
					 fifo_wp <= {DEPTH{1'b0}};
				  end
				end
				else begin
				  fifo_wp <= fifo_wp + 1;
				end
			 end
		  end


    end
  endgenerate


  always @(posedge TRACE_CLK) begin
    tom <= trace_fifo[fifo_rp] ;
  end


//  // fifo write pointer
//  always @(posedge TRACE_CLK) begin
//      // process
//    if(RST == 1'b1) begin
//      fifo_wp <= {DEPTH{1'b0}};
//    end
//    else if(|(trace_pedge)  == 1'b1) begin
//      if(fifo_wp == (FIFO_SIZE - 1)) begin
//        fifo_wp <= {DEPTH{1'b0}};
//      end
//      else begin
//        fifo_wp <= fifo_wp + 1;
//      end
//    end
//  end


  // fifo read pointer update
  always @(posedge TRACE_CLK) begin
    if(RST == 1'b1) begin
      fifo_rp <= {DEPTH{1'b0}};
      fifo_re <= 1'b0;
    end
    else if(fifo_empty != 1'b1 && dly_ctr == 5'b00000 && fifo_re == 1'b0) begin
      fifo_re <= 1'b1;
      if(fifo_rp == (FIFO_SIZE - 1)) begin
        fifo_rp <= {DEPTH{1'b0}};
      end
      else begin
        fifo_rp <= fifo_rp + 1;
      end
    end
    else begin
      fifo_re <= 1'b0;
    end
  end
  
  // delay counter update
  always @(posedge TRACE_CLK) begin
    if(RST == 1'b1) begin
      dly_ctr <= 5'h0;
    end
    else if (fifo_re == 1'b1) begin
      dly_ctr <= C_DELAY_CLKS-1;
    end
    else if(dly_ctr != 5'h0) begin
      dly_ctr <= dly_ctr - 1;
    end
  end

  // fifo empty update
  assign fifo_empty = (fifo_wp == fifo_rp) ? 1'b1 : 1'b0;

  // fifo full update
  assign fifo_full = (fifo_wp == FIFO_SIZE-1)? 1'b1 : 1'b0;

  always @(posedge TRACE_CLK) begin
    if(RST == 1'b1) begin
      fifo_full_reg <= 1'b0;
    end
    else if (fifo_empty) begin
      fifo_full_reg <= 1'b0;
	 end else begin	
      fifo_full_reg <= fifo_full;
    end
  end  
  
//  always @(posedge TRACE_CLK) begin
//    if(RST == 1'b1) begin
//      fifo_full_reg <= 1'b0;
//    end
//    else if ((fifo_wp == FIFO_SIZE-1) && (|(trace_pedge) == 1'b1)) begin
//      fifo_full_reg <= 1'b1;
//    end
//	 else begin
//        fifo_full_reg <= 1'b0;
//    end
//  end  
//  
  assign TRACE_DATA_OUT     = tom;
  
  assign TRACE_VALID_OUT    = fifo_re;  
  
  


endmodule
