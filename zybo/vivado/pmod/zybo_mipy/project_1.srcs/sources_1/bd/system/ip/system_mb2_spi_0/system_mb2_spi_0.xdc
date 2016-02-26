# file: system_mb2_spi_0.xdc
# (c) Copyright 2009 - 2012 Xilinx, Inc. All rights reserved.
# 
# This file contains confidential and proprietary information
# of Xilinx, Inc. and is protected under U.S. and
# international copyright and other intellectual property
# laws.
# 
# DISCLAIMER
# This disclaimer is not a license and does not grant any
# rights to the materials distributed herewith. Except as
# otherwise provided in a valid license issued to you by
# Xilinx, and to the maximum extent permitted by applicable
# law: (1) THESE MATERIALS ARE MADE AVAILABLE "AS IS" AND
# WITH ALL FAULTS, AND XILINX HEREBY DISCLAIMS ALL WARRANTIES
# AND CONDITIONS, EXPRESS, IMPLIED, OR STATUTORY, INCLUDING
# BUT NOT LIMITED TO WARRANTIES OF MERCHANTABILITY, NON-
# INFRINGEMENT, OR FITNESS FOR ANY PARTICULAR PURPOSE; and
# (2) Xilinx shall not be liable (whether in contract or tort,
# including negligence, or under any other theory of
# liability) for any loss or damage of any kind or nature
# related to, arising under or in connection with these
# materials, including for any direct, or any indirect,
# special, incidental, or consequential loss or damage
# (including loss of data, profits, goodwill, or any type of
# loss or damage suffered as a result of any action brought
# by a third party) even if such damage or loss was
# reasonably foreseeable or Xilinx had been advised of the
# possibility of the same.
# 
# CRITICAL APPLICATIONS
# Xilinx products are not designed or intended to be fail-
# safe, or for use in any application requiring fail-safe
# performance, such as life-support or safety devices or
# systems, Class III medical devices, nuclear facilities,
# applications related to the deployment of airbags, or any
# other applications that could lead to death, personal
# injury, or severe property or environmental damage
# (individually and collectively, "Critical
# Applications"). Customer assumes the sole risk and
# liability of any use of Xilinx products in Critical
# Applications, subject only to applicable laws and
# regulations governing limitations on product liability.
# 
# THIS COPYRIGHT NOTICE AND DISCLAIMER MUST BE RETAINED AS
# PART OF THIS FILE AT ALL TIMES.
# Set false path on the reset synchronizers
set_false_path -from [get_cells -hierarchical -filter {NAME =~*_FIFO_II/USE_2N_DEPTH.V6_S6_AND_LATER.I_ASYNC_FIFO_BRAM/*rstblk*/*rst_reg_reg[*]}]
set_false_path -to [get_pins -hierarchical -filter {NAME =~*_FIFO_II/USE_2N_DEPTH.V6_S6_AND_LATER.I_ASYNC_FIFO_BRAM/*rstblk*/*PRE}]
##set_false_path -to [get_pins -hierarchical -filter {NAME =~*/*rstblk*/*CLR}]

## IOB constraints ######
set_property IOB true [get_cells -hierarchical -filter {NAME =~*IO*_I_REG}]











#####################################################################################################
# The following section list the board specific constraints (with/without STARTUPE2/E3 primitive)   #
# as per guidance given in product guide.                                                           #
# User should update based on board delays and use                                                  #
#####################################################################################################

#####################################################################################################
# STARTUPE2 primitive is not used                                                                   #
#####################################################################################################
#### All the delay numbers have to be provided by the user

#### CCLK max delay is 6.7 ns ; refer Data sheet
#### We need to consider the max delay for worst case analysis
##set cclk_delay 6.7

#### Following are the SPI device parameters
#### Max Tco
##set tco_max 7
#### Min Tco
##set tco_min 1
#### Setup time requirement
##set tsu 2
#### Hold time requirement
##set th 3

#### Following are the board/trace delay numbers
#### Assumption is that all Data lines are matched
##set tdata_trace_delay_max 0.25
##set tdata_trace_delay_min 0.25
##set tclk_trace_delay_max 0.2
##set tclk_trace_delay_min 0.2

##### End of user provided delay numbers
##create_generated_clock -name clk_sck -source [get_pins -hierarchical *axi_quad_spi_1/ext_spi_clk] [get_ports <SCK_IO>] -edges {3 5 7}

#### Data is captured into FPGA on the second rising edge of ext_spi_clk after the SCK falling edge
#### Data is driven by the FPGA on every alternate rising_edge of ext_spi_clk
##set_input_delay -clock clk_sck -max [expr $tco_max + $tdata_trace_delay_max + $tclk_trace_delay_max] [get_ports IO*_IO] -clock_fall;
##set_input_delay -clock clk_sck -min [expr $tco_min + $tdata_trace_delay_min + $tclk_trace_delay_min] [get_ports IO*_IO] -clock_fall;
##set_multicycle_path 2 -setup -from clk_sck -to [get_clocks -of_objects [get_pins -hierarchical */ext_spi_clk]]
##set_multicycle_path 1 -hold -end -from clk_sck -to [get_clocks -of_objects [get_pins -hierarchical */ext_spi_clk]]

#### Data is captured into SPI on the following rising edge of SCK
#### Data is driven by the IP on alternate rising_edge of the ext_spi_clk
##set_output_delay -clock clk_sck -max [expr $tsu + $tdata_trace_delay_max - $tclk_trace_delay_min] [get_ports IO*_IO];
##set_output_delay -clock clk_sck -min [expr $tdata_trace_delay_min - $th - $tclk_trace_delay_max] [get_ports IO*_IO];
##set_multicycle_path 2 -setup -start -from [get_clocks -of_objects [get_pins -hierarchical */ext_spi_clk]] -to clk_sck
##set_multicycle_path 1 -hold -from [get_clocks -of_objects [get_pins -hierarchical */ext_spi_clk]] -to clk_sck

