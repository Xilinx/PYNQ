###############################################################################
 #  Copyright (c) 2016, Xilinx, Inc.
 #  All rights reserved.
 #
 #  Redistribution and use in source and binary forms, with or without
 #  modification, are permitted provided that the following conditions are met:
 #
 #  1.  Redistributions of source code must retain the above copyright notice,
 #     this list of conditions and the following disclaimer.
 #
 #  2.  Redistributions in binary form must reproduce the above copyright
 #      notice, this list of conditions and the following disclaimer in the
 #      documentation and/or other materials provided with the distribution.
 #
 #  3.  Neither the name of the copyright holder nor the names of its
 #      contributors may be used to endorse or promote products derived from
 #      this software without specific prior written permission.
 #
 #  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 #  AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
 #  THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
 #  PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR
 #  CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
 #  EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 #  PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS;
 #  OR BUSINESS INTERRUPTION). HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
 #  WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR
 #  OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
 #  ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 #
###############################################################################
###############################################################################
 #
 #
 # @file base.tcl
 #
 # Vivado tcl script to generate the bitstream base.bit.
 # Supporting DDR memory access and IRQ from IOP3.
 #
 # <pre>
 # MODIFICATION HISTORY:
 #
 # Ver   Who  Date     Changes
 # ----- --- -------- -----------------------------------------------
 # 1.00a pp  01/24/2017 initial release
 #
 # </pre>
 #
###############################################################################
################################################################
# This is a generated script based on design: system
#
# Though there are limitations about the generated script,
# the main purpose of this utility is to make learning
# IP Integrator Tcl commands easier.
################################################################

namespace eval _tcl {
proc get_script_folder {} {
   set script_path [file normalize [info script]]
   set script_folder [file dirname $script_path]
   return $script_folder
}
}
variable script_folder
set script_folder [_tcl::get_script_folder]

################################################################
# Check if script is running in correct Vivado version.
################################################################
set scripts_vivado_version 2016.1
set current_vivado_version [version -short]

if { [string first $scripts_vivado_version $current_vivado_version] == -1 } {
   puts ""
   catch {common::send_msg_id "BD_TCL-109" "ERROR" "This script was generated using Vivado <$scripts_vivado_version> and is being run in <$current_vivado_version> of Vivado. Please run the script in Vivado <$scripts_vivado_version> then open the design in Vivado <$current_vivado_version>. Upgrade the design by running \"Tools => Report => Report IP Status...\", then run write_bd_tcl to create an updated script."}

   return 1
}

################################################################
# START
################################################################

# To test this script, run the following commands from Vivado Tcl console:
# source system_script.tcl

# If there is no project opened, this script will create a
# project, but make sure you do not have an existing project
# <./base/base.xpr> in the current working folder.

set list_projs [get_projects -quiet]
if { $list_projs eq "" } {
   create_project base base -part xc7z020clg400-1
}

set_property  ip_repo_paths  ../../ip [current_project]
update_ip_catalog

# CHANGE DESIGN NAME HERE
set design_name system

# If you do not already have an existing IP Integrator design open,
# you can create a design using the following command:
#    create_bd_design $design_name

# Creating design if needed
set errMsg ""
set nRet 0

set cur_design [current_bd_design -quiet]
set list_cells [get_bd_cells -quiet]

if { ${design_name} eq "" } {
   # USE CASES:
   #    1) Design_name not set

   set errMsg "Please set the variable <design_name> to a non-empty value."
   set nRet 1

} elseif { ${cur_design} ne "" && ${list_cells} eq "" } {
   # USE CASES:
   #    2): Current design opened AND is empty AND names same.
   #    3): Current design opened AND is empty AND names diff; design_name NOT in project.
   #    4): Current design opened AND is empty AND names diff; design_name exists in project.

   if { $cur_design ne $design_name } {
      common::send_msg_id "BD_TCL-001" "INFO" "Changing value of <design_name> from <$design_name> to <$cur_design> since current design is empty."
      set design_name [get_property NAME $cur_design]
   }
   common::send_msg_id "BD_TCL-002" "INFO" "Constructing design in IPI design <$cur_design>..."

} elseif { ${cur_design} ne "" && $list_cells ne "" && $cur_design eq $design_name } {
   # USE CASES:
   #    5) Current design opened AND has components AND same names.

   set errMsg "Design <$design_name> already exists in your project, please set the variable <design_name> to another value."
   set nRet 1
} elseif { [get_files -quiet ${design_name}.bd] ne "" } {
   # USE CASES: 
   #    6) Current opened design, has components, but diff names, design_name exists in project.
   #    7) No opened design, design_name exists in project.

   set errMsg "Design <$design_name> already exists in your project, please set the variable <design_name> to another value."
   set nRet 2

} else {
   # USE CASES:
   #    8) No opened design, design_name not in project.
   #    9) Current opened design, has components, but diff names, design_name not in project.

   common::send_msg_id "BD_TCL-003" "INFO" "Currently there is no design <$design_name> in project, so creating one..."

   create_bd_design $design_name

   common::send_msg_id "BD_TCL-004" "INFO" "Making design <$design_name> as current_bd_design."
   current_bd_design $design_name

}

common::send_msg_id "BD_TCL-005" "INFO" "Currently the variable <design_name> is equal to \"$design_name\"."

if { $nRet != 0 } {
   catch {common::send_msg_id "BD_TCL-114" "ERROR" $errMsg}
   return $nRet
}

##################################################################
# DESIGN PROCs
##################################################################


# Hierarchical cell: mb3_timers_subsystem
proc create_hier_cell_mb3_timers_subsystem { parentCell nameHier } {

  variable script_folder

  if { $parentCell eq "" || $nameHier eq "" } {
     catch {common::send_msg_id "BD_TCL-102" "ERROR" create_hier_cell_mb3_timers_subsystem() - Empty argument(s)!"}
     return
  }

  # Get object for parentCell
  set parentObj [get_bd_cells $parentCell]
  if { $parentObj == "" } {
     catch {common::send_msg_id "BD_TCL-100" "ERROR" "Unable to find parent cell <$parentCell>!"}
     return
  }

  # Make sure parentObj is hier blk
  set parentType [get_property TYPE $parentObj]
  if { $parentType ne "hier" } {
     catch {common::send_msg_id "BD_TCL-101" "ERROR" "Parent <$parentObj> has TYPE = <$parentType>. Expected to be <hier>."}
     return
  }

  # Save current instance; Restore later
  set oldCurInst [current_bd_instance .]

  # Set parent object as current
  current_bd_instance $parentObj

  # Create cell and set as current instance
  set hier_obj [create_bd_cell -type hier $nameHier]
  current_bd_instance $hier_obj

  # Create interface pins
  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S_AXI
  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S_AXI1
  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S_AXI2
  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S_AXI3
  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S_AXI4
  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S_AXI5

  # Create pins
  create_bd_pin -dir I -from 7 -to 0 capture_i
  create_bd_pin -dir O -from 7 -to 0 generate_o
  create_bd_pin -dir O -from 5 -to 0 mb3_timer_interrupts
  create_bd_pin -dir O -from 5 -to 0 pwm_o
  create_bd_pin -dir I -type clk s_axi_aclk
  create_bd_pin -dir I -from 0 -to 0 -type rst s_axi_aresetn
  create_bd_pin -dir I -from 0 -to 0 -type rst s_axi_aresetn1

  # Create instance: mb3_timer_0, and set properties
  set mb3_timer_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_timer:2.0 mb3_timer_0 ]

  # Create instance: mb3_timer_1, and set properties
  set mb3_timer_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_timer:2.0 mb3_timer_1 ]

  # Create instance: mb3_timer_2, and set properties
  set mb3_timer_2 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_timer:2.0 mb3_timer_2 ]

  # Create instance: mb3_timer_3, and set properties
  set mb3_timer_3 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_timer:2.0 mb3_timer_3 ]

  # Create instance: mb3_timer_4, and set properties
  set mb3_timer_4 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_timer:2.0 mb3_timer_4 ]

  # Create instance: mb3_timer_5, and set properties
  set mb3_timer_5 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_timer:2.0 mb3_timer_5 ]

  # Create instance: mb3_timer_capture_0, and set properties
  set mb3_timer_capture_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice:1.0 mb3_timer_capture_0 ]
  set_property -dict [ list \
CONFIG.DIN_FROM {0} \
CONFIG.DIN_TO {0} \
CONFIG.DIN_WIDTH {8} \
 ] $mb3_timer_capture_0

  # Create instance: mb3_timer_capture_1, and set properties
  set mb3_timer_capture_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice:1.0 mb3_timer_capture_1 ]
  set_property -dict [ list \
CONFIG.DIN_FROM {1} \
CONFIG.DIN_TO {1} \
CONFIG.DIN_WIDTH {8} \
CONFIG.DOUT_WIDTH {1} \
 ] $mb3_timer_capture_1

  # Create instance: mb3_timer_capture_2, and set properties
  set mb3_timer_capture_2 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice:1.0 mb3_timer_capture_2 ]
  set_property -dict [ list \
CONFIG.DIN_FROM {2} \
CONFIG.DIN_TO {2} \
CONFIG.DIN_WIDTH {8} \
CONFIG.DOUT_WIDTH {1} \
 ] $mb3_timer_capture_2

  # Create instance: mb3_timer_capture_3, and set properties
  set mb3_timer_capture_3 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice:1.0 mb3_timer_capture_3 ]
  set_property -dict [ list \
CONFIG.DIN_FROM {3} \
CONFIG.DIN_TO {3} \
CONFIG.DIN_WIDTH {8} \
CONFIG.DOUT_WIDTH {1} \
 ] $mb3_timer_capture_3

  # Create instance: mb3_timer_capture_4, and set properties
  set mb3_timer_capture_4 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice:1.0 mb3_timer_capture_4 ]
  set_property -dict [ list \
CONFIG.DIN_FROM {4} \
CONFIG.DIN_TO {4} \
CONFIG.DIN_WIDTH {8} \
CONFIG.DOUT_WIDTH {1} \
 ] $mb3_timer_capture_4

  # Create instance: mb3_timer_capture_5, and set properties
  set mb3_timer_capture_5 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice:1.0 mb3_timer_capture_5 ]
  set_property -dict [ list \
CONFIG.DIN_FROM {5} \
CONFIG.DIN_TO {5} \
CONFIG.DIN_WIDTH {8} \
CONFIG.DOUT_WIDTH {1} \
 ] $mb3_timer_capture_5

  # Create instance: mb3_timer_capture_6, and set properties
  set mb3_timer_capture_6 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice:1.0 mb3_timer_capture_6 ]
  set_property -dict [ list \
CONFIG.DIN_FROM {6} \
CONFIG.DIN_TO {6} \
CONFIG.DIN_WIDTH {8} \
CONFIG.DOUT_WIDTH {1} \
 ] $mb3_timer_capture_6

  # Create instance: mb3_timer_capture_7, and set properties
  set mb3_timer_capture_7 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice:1.0 mb3_timer_capture_7 ]
  set_property -dict [ list \
CONFIG.DIN_FROM {7} \
CONFIG.DIN_TO {7} \
CONFIG.DIN_WIDTH {8} \
CONFIG.DOUT_WIDTH {1} \
 ] $mb3_timer_capture_7

  # Create instance: mb3_timer_generate, and set properties
  set mb3_timer_generate [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconcat:2.1 mb3_timer_generate ]
  set_property -dict [ list \
CONFIG.NUM_PORTS {8} \
 ] $mb3_timer_generate

  # Create instance: mb3_timer_pwm, and set properties
  set mb3_timer_pwm [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconcat:2.1 mb3_timer_pwm ]
  set_property -dict [ list \
CONFIG.NUM_PORTS {6} \
 ] $mb3_timer_pwm

  # Create instance: mb3_timers_interrupt, and set properties
  set mb3_timers_interrupt [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconcat:2.1 mb3_timers_interrupt ]
  set_property -dict [ list \
CONFIG.NUM_PORTS {6} \
 ] $mb3_timers_interrupt

  # Create interface connections
  connect_bd_intf_net -intf_net Conn1 [get_bd_intf_pins S_AXI5] [get_bd_intf_pins mb3_timer_5/S_AXI]
  connect_bd_intf_net -intf_net microblaze_0_axi_periph_M09_AXI [get_bd_intf_pins S_AXI] [get_bd_intf_pins mb3_timer_0/S_AXI]
  connect_bd_intf_net -intf_net microblaze_0_axi_periph_M10_AXI [get_bd_intf_pins S_AXI1] [get_bd_intf_pins mb3_timer_1/S_AXI]
  connect_bd_intf_net -intf_net microblaze_0_axi_periph_M11_AXI [get_bd_intf_pins S_AXI2] [get_bd_intf_pins mb3_timer_2/S_AXI]
  connect_bd_intf_net -intf_net microblaze_0_axi_periph_M12_AXI [get_bd_intf_pins S_AXI3] [get_bd_intf_pins mb3_timer_3/S_AXI]
  connect_bd_intf_net -intf_net microblaze_0_axi_periph_M13_AXI [get_bd_intf_pins S_AXI4] [get_bd_intf_pins mb3_timer_4/S_AXI]

  # Create port connections
  connect_bd_net -net arduino_io_switch_0_timer_i_in [get_bd_pins capture_i] [get_bd_pins mb3_timer_capture_0/Din] [get_bd_pins mb3_timer_capture_1/Din] [get_bd_pins mb3_timer_capture_2/Din] [get_bd_pins mb3_timer_capture_3/Din] [get_bd_pins mb3_timer_capture_4/Din] [get_bd_pins mb3_timer_capture_5/Din] [get_bd_pins mb3_timer_capture_6/Din] [get_bd_pins mb3_timer_capture_7/Din]
  connect_bd_net -net mb3_timer_0_generateout0 [get_bd_pins mb3_timer_0/generateout0] [get_bd_pins mb3_timer_generate/In0]
  connect_bd_net -net mb3_timer_0_generateout1 [get_bd_pins mb3_timer_0/generateout1] [get_bd_pins mb3_timer_generate/In6]
  connect_bd_net -net mb3_timer_0_interrupt [get_bd_pins mb3_timer_0/interrupt] [get_bd_pins mb3_timers_interrupt/In0]
  connect_bd_net -net mb3_timer_0_pwm0 [get_bd_pins mb3_timer_0/pwm0] [get_bd_pins mb3_timer_pwm/In0]
  connect_bd_net -net mb3_timer_1_generateout0 [get_bd_pins mb3_timer_1/generateout0] [get_bd_pins mb3_timer_generate/In1]
  connect_bd_net -net mb3_timer_1_generateout1 [get_bd_pins mb3_timer_1/generateout1] [get_bd_pins mb3_timer_generate/In7]
  connect_bd_net -net mb3_timer_1_interrupt [get_bd_pins mb3_timer_1/interrupt] [get_bd_pins mb3_timers_interrupt/In1]
  connect_bd_net -net mb3_timer_1_pwm0 [get_bd_pins mb3_timer_1/pwm0] [get_bd_pins mb3_timer_pwm/In1]
  connect_bd_net -net mb3_timer_2_generateout0 [get_bd_pins mb3_timer_2/generateout0] [get_bd_pins mb3_timer_generate/In2]
  connect_bd_net -net mb3_timer_2_interrupt [get_bd_pins mb3_timer_2/interrupt] [get_bd_pins mb3_timers_interrupt/In2]
  connect_bd_net -net mb3_timer_2_pwm0 [get_bd_pins mb3_timer_2/pwm0] [get_bd_pins mb3_timer_pwm/In2]
  connect_bd_net -net mb3_timer_3_generateout0 [get_bd_pins mb3_timer_3/generateout0] [get_bd_pins mb3_timer_generate/In3]
  connect_bd_net -net mb3_timer_3_interrupt [get_bd_pins mb3_timer_3/interrupt] [get_bd_pins mb3_timers_interrupt/In3]
  connect_bd_net -net mb3_timer_3_pwm0 [get_bd_pins mb3_timer_3/pwm0] [get_bd_pins mb3_timer_pwm/In3]
  connect_bd_net -net mb3_timer_4_generateout0 [get_bd_pins mb3_timer_4/generateout0] [get_bd_pins mb3_timer_generate/In4]
  connect_bd_net -net mb3_timer_4_interrupt [get_bd_pins mb3_timer_4/interrupt] [get_bd_pins mb3_timers_interrupt/In4]
  connect_bd_net -net mb3_timer_4_pwm0 [get_bd_pins mb3_timer_4/pwm0] [get_bd_pins mb3_timer_pwm/In4]
  connect_bd_net -net mb3_timer_5_generateout0 [get_bd_pins mb3_timer_5/generateout0] [get_bd_pins mb3_timer_generate/In5]
  connect_bd_net -net mb3_timer_5_interrupt [get_bd_pins mb3_timer_5/interrupt] [get_bd_pins mb3_timers_interrupt/In5]
  connect_bd_net -net mb3_timer_5_pwm0 [get_bd_pins mb3_timer_5/pwm0] [get_bd_pins mb3_timer_pwm/In5]
  connect_bd_net -net mb3_timer_capture_0_Dout [get_bd_pins mb3_timer_0/capturetrig0] [get_bd_pins mb3_timer_capture_0/Dout]
  connect_bd_net -net mb3_timer_capture_1_Dout [get_bd_pins mb3_timer_1/capturetrig0] [get_bd_pins mb3_timer_capture_1/Dout]
  connect_bd_net -net mb3_timer_capture_2_Dout [get_bd_pins mb3_timer_2/capturetrig0] [get_bd_pins mb3_timer_capture_2/Dout]
  connect_bd_net -net mb3_timer_capture_3_Dout [get_bd_pins mb3_timer_3/capturetrig0] [get_bd_pins mb3_timer_capture_3/Dout]
  connect_bd_net -net mb3_timer_capture_4_Dout [get_bd_pins mb3_timer_4/capturetrig0] [get_bd_pins mb3_timer_capture_4/Dout]
  connect_bd_net -net mb3_timer_capture_5_Dout [get_bd_pins mb3_timer_5/capturetrig0] [get_bd_pins mb3_timer_capture_5/Dout]
  connect_bd_net -net mb3_timer_capture_6_Dout [get_bd_pins mb3_timer_0/capturetrig1] [get_bd_pins mb3_timer_capture_6/Dout]
  connect_bd_net -net mb3_timer_capture_7_Dout [get_bd_pins mb3_timer_1/capturetrig1] [get_bd_pins mb3_timer_capture_7/Dout]
  connect_bd_net -net mb3_timer_generate_dout [get_bd_pins generate_o] [get_bd_pins mb3_timer_generate/dout]
  connect_bd_net -net mb3_timer_pwm_dout [get_bd_pins pwm_o] [get_bd_pins mb3_timer_pwm/dout]
  connect_bd_net -net mb3_timers_interrupt_dout [get_bd_pins mb3_timer_interrupts] [get_bd_pins mb3_timers_interrupt/dout]
  connect_bd_net -net processing_system7_0_FCLK_CLK0 [get_bd_pins s_axi_aclk] [get_bd_pins mb3_timer_0/s_axi_aclk] [get_bd_pins mb3_timer_1/s_axi_aclk] [get_bd_pins mb3_timer_2/s_axi_aclk] [get_bd_pins mb3_timer_3/s_axi_aclk] [get_bd_pins mb3_timer_4/s_axi_aclk] [get_bd_pins mb3_timer_5/s_axi_aclk]
  connect_bd_net -net rst_clk_wiz_1_100M_peripheral_aresetn [get_bd_pins s_axi_aresetn] [get_bd_pins mb3_timer_0/s_axi_aresetn]
  connect_bd_net -net s_axi_aresetn_1 [get_bd_pins s_axi_aresetn1] [get_bd_pins mb3_timer_1/s_axi_aresetn] [get_bd_pins mb3_timer_2/s_axi_aresetn] [get_bd_pins mb3_timer_3/s_axi_aresetn] [get_bd_pins mb3_timer_4/s_axi_aresetn] [get_bd_pins mb3_timer_5/s_axi_aresetn]

  # Restore current instance
  current_bd_instance $oldCurInst
}

# Hierarchical cell: mb3_spi_subsystem
proc create_hier_cell_mb3_spi_subsystem { parentCell nameHier } {

  variable script_folder

  if { $parentCell eq "" || $nameHier eq "" } {
     catch {common::send_msg_id "BD_TCL-102" "ERROR" create_hier_cell_mb3_spi_subsystem() - Empty argument(s)!"}
     return
  }

  # Get object for parentCell
  set parentObj [get_bd_cells $parentCell]
  if { $parentObj == "" } {
     catch {common::send_msg_id "BD_TCL-100" "ERROR" "Unable to find parent cell <$parentCell>!"}
     return
  }

  # Make sure parentObj is hier blk
  set parentType [get_property TYPE $parentObj]
  if { $parentType ne "hier" } {
     catch {common::send_msg_id "BD_TCL-101" "ERROR" "Parent <$parentObj> has TYPE = <$parentType>. Expected to be <hier>."}
     return
  }

  # Save current instance; Restore later
  set oldCurInst [current_bd_instance .]

  # Set parent object as current
  current_bd_instance $parentObj

  # Create cell and set as current instance
  set hier_obj [create_bd_cell -type hier $nameHier]
  current_bd_instance $hier_obj

  # Create interface pins
  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 AXI_LITE
  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 AXI_LITE1
  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:spi_rtl:1.0 SPI_0
  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:spi_rtl:1.0 SPI_1

  # Create pins
  create_bd_pin -dir O -type intr ip2intc_irpt
  create_bd_pin -dir I -type clk s_axi_aclk
  create_bd_pin -dir I -from 0 -to 0 -type rst s_axi_aresetn
  create_bd_pin -dir I -from 0 -to 0 -type rst s_axi_aresetn1

  # Create instance: mb3_spi_pl_sw, and set properties
  set mb3_spi_pl_sw [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_quad_spi:3.2 mb3_spi_pl_sw ]
  set_property -dict [ list \
CONFIG.C_USE_STARTUP {0} \
 ] $mb3_spi_pl_sw

  # Create instance: mb3_spi_pl_sw_d13_d10, and set properties
  set mb3_spi_pl_sw_d13_d10 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_quad_spi:3.2 mb3_spi_pl_sw_d13_d10 ]
  set_property -dict [ list \
CONFIG.C_USE_STARTUP {0} \
CONFIG.C_USE_STARTUP_INT {0} \
 ] $mb3_spi_pl_sw_d13_d10

  # Create interface connections
  connect_bd_intf_net -intf_net mb3_spi_pl_sw_SPI_0 [get_bd_intf_pins SPI_0] [get_bd_intf_pins mb3_spi_pl_sw/SPI_0]
  connect_bd_intf_net -intf_net mb3_spi_pl_sw_d13_d10_SPI_0 [get_bd_intf_pins SPI_1] [get_bd_intf_pins mb3_spi_pl_sw_d13_d10/SPI_0]
  connect_bd_intf_net -intf_net microblaze_0_axi_periph_M00_AXI [get_bd_intf_pins AXI_LITE] [get_bd_intf_pins mb3_spi_pl_sw/AXI_LITE]
  connect_bd_intf_net -intf_net microblaze_0_axi_periph_M06_AXI [get_bd_intf_pins AXI_LITE1] [get_bd_intf_pins mb3_spi_pl_sw_d13_d10/AXI_LITE]

  # Create port connections
  connect_bd_net -net mb3_spi_ip2intc_irpt [get_bd_pins ip2intc_irpt] [get_bd_pins mb3_spi_pl_sw/ip2intc_irpt]
  connect_bd_net -net processing_system7_0_FCLK_CLK0 [get_bd_pins s_axi_aclk] [get_bd_pins mb3_spi_pl_sw/ext_spi_clk] [get_bd_pins mb3_spi_pl_sw/s_axi_aclk] [get_bd_pins mb3_spi_pl_sw_d13_d10/ext_spi_clk] [get_bd_pins mb3_spi_pl_sw_d13_d10/s_axi_aclk]
  connect_bd_net -net rst_clk_wiz_1_100M_peripheral_aresetn [get_bd_pins s_axi_aresetn] [get_bd_pins mb3_spi_pl_sw/s_axi_aresetn]
  connect_bd_net -net s_axi_aresetn_1 [get_bd_pins s_axi_aresetn1] [get_bd_pins mb3_spi_pl_sw_d13_d10/s_axi_aresetn]

  # Restore current instance
  current_bd_instance $oldCurInst
}

# Hierarchical cell: mb3_lmb
proc create_hier_cell_mb3_lmb { parentCell nameHier } {

  variable script_folder

  if { $parentCell eq "" || $nameHier eq "" } {
     catch {common::send_msg_id "BD_TCL-102" "ERROR" create_hier_cell_mb3_lmb() - Empty argument(s)!"}
     return
  }

  # Get object for parentCell
  set parentObj [get_bd_cells $parentCell]
  if { $parentObj == "" } {
     catch {common::send_msg_id "BD_TCL-100" "ERROR" "Unable to find parent cell <$parentCell>!"}
     return
  }

  # Make sure parentObj is hier blk
  set parentType [get_property TYPE $parentObj]
  if { $parentType ne "hier" } {
     catch {common::send_msg_id "BD_TCL-101" "ERROR" "Parent <$parentObj> has TYPE = <$parentType>. Expected to be <hier>."}
     return
  }

  # Save current instance; Restore later
  set oldCurInst [current_bd_instance .]

  # Set parent object as current
  current_bd_instance $parentObj

  # Create cell and set as current instance
  set hier_obj [create_bd_cell -type hier $nameHier]
  current_bd_instance $hier_obj

  # Create interface pins
  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:bram_rtl:1.0 BRAM_PORTB
  create_bd_intf_pin -mode MirroredMaster -vlnv xilinx.com:interface:lmb_rtl:1.0 DLMB
  create_bd_intf_pin -mode MirroredMaster -vlnv xilinx.com:interface:lmb_rtl:1.0 ILMB

  # Create pins
  create_bd_pin -dir I -type clk LMB_Clk
  create_bd_pin -dir I -from 0 -to 0 -type rst SYS_Rst

  # Create instance: dlmb_v10, and set properties
  set dlmb_v10 [ create_bd_cell -type ip -vlnv xilinx.com:ip:lmb_v10:3.0 dlmb_v10 ]

  # Create instance: ilmb_v10, and set properties
  set ilmb_v10 [ create_bd_cell -type ip -vlnv xilinx.com:ip:lmb_v10:3.0 ilmb_v10 ]

  # Create instance: lmb_bram, and set properties
  set lmb_bram [ create_bd_cell -type ip -vlnv xilinx.com:ip:blk_mem_gen:8.3 lmb_bram ]
  set_property -dict [ list \
CONFIG.Memory_Type {True_Dual_Port_RAM} \
CONFIG.use_bram_block {BRAM_Controller} \
 ] $lmb_bram

  # Create instance: lmb_bram_if_cntlr, and set properties
  set lmb_bram_if_cntlr [ create_bd_cell -type ip -vlnv xilinx.com:ip:lmb_bram_if_cntlr:4.0 lmb_bram_if_cntlr ]
  set_property -dict [ list \
CONFIG.C_ECC {0} \
CONFIG.C_NUM_LMB {2} \
 ] $lmb_bram_if_cntlr

  # Create interface connections
  connect_bd_intf_net -intf_net Conn [get_bd_intf_pins dlmb_v10/LMB_Sl_0] [get_bd_intf_pins lmb_bram_if_cntlr/SLMB1]
  connect_bd_intf_net -intf_net Conn1 [get_bd_intf_pins BRAM_PORTB] [get_bd_intf_pins lmb_bram/BRAM_PORTB]
  connect_bd_intf_net -intf_net lmb_bram_if_cntlr_BRAM_PORT [get_bd_intf_pins lmb_bram/BRAM_PORTA] [get_bd_intf_pins lmb_bram_if_cntlr/BRAM_PORT]
  connect_bd_intf_net -intf_net microblaze_0_dlmb [get_bd_intf_pins DLMB] [get_bd_intf_pins dlmb_v10/LMB_M]
  connect_bd_intf_net -intf_net microblaze_0_ilmb [get_bd_intf_pins ILMB] [get_bd_intf_pins ilmb_v10/LMB_M]
  connect_bd_intf_net -intf_net microblaze_0_ilmb_bus [get_bd_intf_pins ilmb_v10/LMB_Sl_0] [get_bd_intf_pins lmb_bram_if_cntlr/SLMB]

  # Create port connections
  connect_bd_net -net SYS_Rst_1 [get_bd_pins SYS_Rst] [get_bd_pins dlmb_v10/SYS_Rst] [get_bd_pins ilmb_v10/SYS_Rst] [get_bd_pins lmb_bram_if_cntlr/LMB_Rst]
  connect_bd_net -net microblaze_0_Clk [get_bd_pins LMB_Clk] [get_bd_pins dlmb_v10/LMB_Clk] [get_bd_pins ilmb_v10/LMB_Clk] [get_bd_pins lmb_bram_if_cntlr/LMB_Clk]

  # Restore current instance
  current_bd_instance $oldCurInst
}

# Hierarchical cell: mb3_iic_subsystem
proc create_hier_cell_mb3_iic_subsystem { parentCell nameHier } {

  variable script_folder

  if { $parentCell eq "" || $nameHier eq "" } {
     catch {common::send_msg_id "BD_TCL-102" "ERROR" create_hier_cell_mb3_iic_subsystem() - Empty argument(s)!"}
     return
  }

  # Get object for parentCell
  set parentObj [get_bd_cells $parentCell]
  if { $parentObj == "" } {
     catch {common::send_msg_id "BD_TCL-100" "ERROR" "Unable to find parent cell <$parentCell>!"}
     return
  }

  # Make sure parentObj is hier blk
  set parentType [get_property TYPE $parentObj]
  if { $parentType ne "hier" } {
     catch {common::send_msg_id "BD_TCL-101" "ERROR" "Parent <$parentObj> has TYPE = <$parentType>. Expected to be <hier>."}
     return
  }

  # Save current instance; Restore later
  set oldCurInst [current_bd_instance .]

  # Set parent object as current
  current_bd_instance $parentObj

  # Create cell and set as current instance
  set hier_obj [create_bd_cell -type hier $nameHier]
  current_bd_instance $hier_obj

  # Create interface pins
  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:iic_rtl:1.0 IIC
  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:iic_rtl:1.0 IIC1
  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S_AXI
  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S_AXI1

  # Create pins
  create_bd_pin -dir O -type intr iic2intc_irpt
  create_bd_pin -dir I -type clk s_axi_aclk
  create_bd_pin -dir I -from 0 -to 0 -type rst s_axi_aresetn
  create_bd_pin -dir I -from 0 -to 0 -type rst s_axi_aresetn1

  # Create instance: mb3_iic_pl_sw, and set properties
  set mb3_iic_pl_sw [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_iic:2.0 mb3_iic_pl_sw ]

  # Create instance: mb3_shared_iic_sw, and set properties
  set mb3_shared_iic_sw [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_iic:2.0 mb3_shared_iic_sw ]

  # Create interface connections
  connect_bd_intf_net -intf_net mb3_iic_pl_sw_IIC [get_bd_intf_pins IIC1] [get_bd_intf_pins mb3_iic_pl_sw/IIC]
  connect_bd_intf_net -intf_net mb3_shared_iic_sw_IIC [get_bd_intf_pins IIC] [get_bd_intf_pins mb3_shared_iic_sw/IIC]
  connect_bd_intf_net -intf_net microblaze_0_axi_periph_M01_AXI [get_bd_intf_pins S_AXI1] [get_bd_intf_pins mb3_iic_pl_sw/S_AXI]
  connect_bd_intf_net -intf_net microblaze_0_axi_periph_M07_AXI [get_bd_intf_pins S_AXI] [get_bd_intf_pins mb3_shared_iic_sw/S_AXI]

  # Create port connections
  connect_bd_net -net mb3_iic_iic2intc_irpt [get_bd_pins iic2intc_irpt] [get_bd_pins mb3_iic_pl_sw/iic2intc_irpt]
  connect_bd_net -net processing_system7_0_FCLK_CLK0 [get_bd_pins s_axi_aclk] [get_bd_pins mb3_iic_pl_sw/s_axi_aclk] [get_bd_pins mb3_shared_iic_sw/s_axi_aclk]
  connect_bd_net -net rst_clk_wiz_1_100M_peripheral_aresetn [get_bd_pins s_axi_aresetn1] [get_bd_pins mb3_iic_pl_sw/s_axi_aresetn]
  connect_bd_net -net s_axi_aresetn_1 [get_bd_pins s_axi_aresetn] [get_bd_pins mb3_shared_iic_sw/s_axi_aresetn]

  # Restore current instance
  current_bd_instance $oldCurInst
}

# Hierarchical cell: mb3_gpio_subsystem
proc create_hier_cell_mb3_gpio_subsystem { parentCell nameHier } {

  variable script_folder

  if { $parentCell eq "" || $nameHier eq "" } {
     catch {common::send_msg_id "BD_TCL-102" "ERROR" create_hier_cell_mb3_gpio_subsystem() - Empty argument(s)!"}
     return
  }

  # Get object for parentCell
  set parentObj [get_bd_cells $parentCell]
  if { $parentObj == "" } {
     catch {common::send_msg_id "BD_TCL-100" "ERROR" "Unable to find parent cell <$parentCell>!"}
     return
  }

  # Make sure parentObj is hier blk
  set parentType [get_property TYPE $parentObj]
  if { $parentType ne "hier" } {
     catch {common::send_msg_id "BD_TCL-101" "ERROR" "Parent <$parentObj> has TYPE = <$parentType>. Expected to be <hier>."}
     return
  }

  # Save current instance; Restore later
  set oldCurInst [current_bd_instance .]

  # Set parent object as current
  current_bd_instance $parentObj

  # Create cell and set as current instance
  set hier_obj [create_bd_cell -type hier $nameHier]
  current_bd_instance $hier_obj

  # Create interface pins
  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S_AXI
  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S_AXI1
  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:gpio_rtl:1.0 ck_gpio_d15_d0

  # Create pins
  create_bd_pin -dir O -from 5 -to 0 data_a5_a0
  create_bd_pin -dir O -from 11 -to 0 data_d13_d2
  create_bd_pin -dir O -from 1 -to 0 data_d1_d0
  create_bd_pin -dir I -from 11 -to 0 din_d13_d2
  create_bd_pin -dir I -from 1 -to 0 din_d1_d0
  create_bd_pin -dir I -from 5 -to 0 in_a5_a0
  create_bd_pin -dir I -type clk s_axi_aclk
  create_bd_pin -dir I -from 0 -to 0 -type rst s_axi_aresetn
  create_bd_pin -dir O -from 5 -to 0 tri_a5_a0
  create_bd_pin -dir O -from 11 -to 0 tri_d13_d2
  create_bd_pin -dir O -from 1 -to 0 tri_d1_d0

  # Create instance: mb3_arduino_gpio_d13_d0_a5_a0, and set properties
  set mb3_arduino_gpio_d13_d0_a5_a0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_gpio:2.0 mb3_arduino_gpio_d13_d0_a5_a0 ]
  set_property -dict [ list \
CONFIG.C_GPIO2_WIDTH {6} \
CONFIG.C_GPIO_WIDTH {14} \
CONFIG.C_IS_DUAL {1} \
 ] $mb3_arduino_gpio_d13_d0_a5_a0

  # Create instance: mb3_ck_gpio_d15_d0, and set properties
  set mb3_ck_gpio_d15_d0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_gpio:2.0 mb3_ck_gpio_d15_d0 ]
  set_property -dict [ list \
CONFIG.C_ALL_OUTPUTS_2 {0} \
CONFIG.C_GPIO2_WIDTH {32} \
CONFIG.C_GPIO_WIDTH {16} \
CONFIG.C_IS_DUAL {0} \
 ] $mb3_ck_gpio_d15_d0

  # Create instance: xlconcat_din_d13_d0, and set properties
  set xlconcat_din_d13_d0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconcat:2.1 xlconcat_din_d13_d0 ]

  # Create instance: xlslice_data_d13_d2, and set properties
  set xlslice_data_d13_d2 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice:1.0 xlslice_data_d13_d2 ]
  set_property -dict [ list \
CONFIG.DIN_FROM {13} \
CONFIG.DIN_TO {2} \
CONFIG.DIN_WIDTH {14} \
CONFIG.DOUT_WIDTH {12} \
 ] $xlslice_data_d13_d2

  # Create instance: xlslice_data_d1_d0, and set properties
  set xlslice_data_d1_d0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice:1.0 xlslice_data_d1_d0 ]
  set_property -dict [ list \
CONFIG.DIN_FROM {1} \
CONFIG.DIN_TO {0} \
CONFIG.DIN_WIDTH {14} \
CONFIG.DOUT_WIDTH {2} \
 ] $xlslice_data_d1_d0

  # Create instance: xlslice_tri_d13_d2, and set properties
  set xlslice_tri_d13_d2 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice:1.0 xlslice_tri_d13_d2 ]
  set_property -dict [ list \
CONFIG.DIN_FROM {13} \
CONFIG.DIN_TO {2} \
CONFIG.DIN_WIDTH {14} \
CONFIG.DOUT_WIDTH {12} \
 ] $xlslice_tri_d13_d2

  # Create instance: xlslice_tri_d1_d0, and set properties
  set xlslice_tri_d1_d0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice:1.0 xlslice_tri_d1_d0 ]
  set_property -dict [ list \
CONFIG.DIN_FROM {1} \
CONFIG.DIN_TO {0} \
CONFIG.DIN_WIDTH {14} \
CONFIG.DOUT_WIDTH {2} \
 ] $xlslice_tri_d1_d0

  # Create interface connections
  connect_bd_intf_net -intf_net Conn1 [get_bd_intf_pins ck_gpio_d15_d0] [get_bd_intf_pins mb3_ck_gpio_d15_d0/GPIO]
  connect_bd_intf_net -intf_net microblaze_0_axi_periph_M03_AXI [get_bd_intf_pins S_AXI1] [get_bd_intf_pins mb3_ck_gpio_d15_d0/S_AXI]
  connect_bd_intf_net -intf_net microblaze_0_axi_periph_M05_AXI [get_bd_intf_pins S_AXI] [get_bd_intf_pins mb3_arduino_gpio_d13_d0_a5_a0/S_AXI]

  # Create port connections
  connect_bd_net -net In0_1 [get_bd_pins din_d1_d0] [get_bd_pins xlconcat_din_d13_d0/In0]
  connect_bd_net -net In1_1 [get_bd_pins din_d13_d2] [get_bd_pins xlconcat_din_d13_d0/In1]
  connect_bd_net -net gpio2_io_i_1 [get_bd_pins in_a5_a0] [get_bd_pins mb3_arduino_gpio_d13_d0_a5_a0/gpio2_io_i]
  connect_bd_net -net mb3_arduino_gpio_d13_d0_a5_a0_gpio2_io_o [get_bd_pins data_a5_a0] [get_bd_pins mb3_arduino_gpio_d13_d0_a5_a0/gpio2_io_o]
  connect_bd_net -net mb3_arduino_gpio_d13_d0_a5_a0_gpio2_io_t [get_bd_pins tri_a5_a0] [get_bd_pins mb3_arduino_gpio_d13_d0_a5_a0/gpio2_io_t]
  connect_bd_net -net mb3_arduino_gpio_d13_d0_a5_a0_gpio_io_o [get_bd_pins mb3_arduino_gpio_d13_d0_a5_a0/gpio_io_o] [get_bd_pins xlslice_data_d13_d2/Din] [get_bd_pins xlslice_data_d1_d0/Din]
  connect_bd_net -net mb3_arduino_gpio_d13_d0_a5_a0_gpio_io_t [get_bd_pins mb3_arduino_gpio_d13_d0_a5_a0/gpio_io_t] [get_bd_pins xlslice_tri_d13_d2/Din] [get_bd_pins xlslice_tri_d1_d0/Din]
  connect_bd_net -net processing_system7_0_FCLK_CLK0 [get_bd_pins s_axi_aclk] [get_bd_pins mb3_arduino_gpio_d13_d0_a5_a0/s_axi_aclk] [get_bd_pins mb3_ck_gpio_d15_d0/s_axi_aclk]
  connect_bd_net -net rst_clk_wiz_1_100M_peripheral_aresetn [get_bd_pins s_axi_aresetn] [get_bd_pins mb3_arduino_gpio_d13_d0_a5_a0/s_axi_aresetn] [get_bd_pins mb3_ck_gpio_d15_d0/s_axi_aresetn]
  connect_bd_net -net xlconcat_din_d13_d0_dout [get_bd_pins mb3_arduino_gpio_d13_d0_a5_a0/gpio_io_i] [get_bd_pins xlconcat_din_d13_d0/dout]
  connect_bd_net -net xlslice_data_d13_d2_Dout [get_bd_pins data_d13_d2] [get_bd_pins xlslice_data_d13_d2/Dout]
  connect_bd_net -net xlslice_data_d1_d0_Dout [get_bd_pins data_d1_d0] [get_bd_pins xlslice_data_d1_d0/Dout]
  connect_bd_net -net xlslice_tri_d13_d2_Dout [get_bd_pins tri_d13_d2] [get_bd_pins xlslice_tri_d13_d2/Dout]
  connect_bd_net -net xlslice_tri_d1_d0_Dout [get_bd_pins tri_d1_d0] [get_bd_pins xlslice_tri_d1_d0/Dout]

  # Restore current instance
  current_bd_instance $oldCurInst
}

# Hierarchical cell: mb2_lmb
proc create_hier_cell_mb2_lmb { parentCell nameHier } {

  variable script_folder

  if { $parentCell eq "" || $nameHier eq "" } {
     catch {common::send_msg_id "BD_TCL-102" "ERROR" create_hier_cell_mb2_lmb() - Empty argument(s)!"}
     return
  }

  # Get object for parentCell
  set parentObj [get_bd_cells $parentCell]
  if { $parentObj == "" } {
     catch {common::send_msg_id "BD_TCL-100" "ERROR" "Unable to find parent cell <$parentCell>!"}
     return
  }

  # Make sure parentObj is hier blk
  set parentType [get_property TYPE $parentObj]
  if { $parentType ne "hier" } {
     catch {common::send_msg_id "BD_TCL-101" "ERROR" "Parent <$parentObj> has TYPE = <$parentType>. Expected to be <hier>."}
     return
  }

  # Save current instance; Restore later
  set oldCurInst [current_bd_instance .]

  # Set parent object as current
  current_bd_instance $parentObj

  # Create cell and set as current instance
  set hier_obj [create_bd_cell -type hier $nameHier]
  current_bd_instance $hier_obj

  # Create interface pins
  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:bram_rtl:1.0 BRAM_PORTB
  create_bd_intf_pin -mode MirroredMaster -vlnv xilinx.com:interface:lmb_rtl:1.0 DLMB
  create_bd_intf_pin -mode MirroredMaster -vlnv xilinx.com:interface:lmb_rtl:1.0 ILMB

  # Create pins
  create_bd_pin -dir I -type clk LMB_Clk
  create_bd_pin -dir I -from 0 -to 0 -type rst SYS_Rst

  # Create instance: dlmb_v10, and set properties
  set dlmb_v10 [ create_bd_cell -type ip -vlnv xilinx.com:ip:lmb_v10:3.0 dlmb_v10 ]

  # Create instance: ilmb_v10, and set properties
  set ilmb_v10 [ create_bd_cell -type ip -vlnv xilinx.com:ip:lmb_v10:3.0 ilmb_v10 ]

  # Create instance: lmb_bram, and set properties
  set lmb_bram [ create_bd_cell -type ip -vlnv xilinx.com:ip:blk_mem_gen:8.3 lmb_bram ]
  set_property -dict [ list \
CONFIG.Memory_Type {True_Dual_Port_RAM} \
CONFIG.use_bram_block {BRAM_Controller} \
 ] $lmb_bram

  # Create instance: lmb_bram_if_cntlr, and set properties
  set lmb_bram_if_cntlr [ create_bd_cell -type ip -vlnv xilinx.com:ip:lmb_bram_if_cntlr:4.0 lmb_bram_if_cntlr ]
  set_property -dict [ list \
CONFIG.C_ECC {0} \
CONFIG.C_NUM_LMB {2} \
 ] $lmb_bram_if_cntlr

  # Create interface connections
  connect_bd_intf_net -intf_net Conn [get_bd_intf_pins dlmb_v10/LMB_Sl_0] [get_bd_intf_pins lmb_bram_if_cntlr/SLMB1]
  connect_bd_intf_net -intf_net Conn1 [get_bd_intf_pins BRAM_PORTB] [get_bd_intf_pins lmb_bram/BRAM_PORTB]
  connect_bd_intf_net -intf_net lmb_bram_if_cntlr_BRAM_PORT [get_bd_intf_pins lmb_bram/BRAM_PORTA] [get_bd_intf_pins lmb_bram_if_cntlr/BRAM_PORT]
  connect_bd_intf_net -intf_net microblaze_0_dlmb [get_bd_intf_pins DLMB] [get_bd_intf_pins dlmb_v10/LMB_M]
  connect_bd_intf_net -intf_net microblaze_0_ilmb [get_bd_intf_pins ILMB] [get_bd_intf_pins ilmb_v10/LMB_M]
  connect_bd_intf_net -intf_net microblaze_0_ilmb_bus [get_bd_intf_pins ilmb_v10/LMB_Sl_0] [get_bd_intf_pins lmb_bram_if_cntlr/SLMB]

  # Create port connections
  connect_bd_net -net SYS_Rst_1 [get_bd_pins SYS_Rst] [get_bd_pins dlmb_v10/SYS_Rst] [get_bd_pins ilmb_v10/SYS_Rst] [get_bd_pins lmb_bram_if_cntlr/LMB_Rst]
  connect_bd_net -net microblaze_0_Clk [get_bd_pins LMB_Clk] [get_bd_pins dlmb_v10/LMB_Clk] [get_bd_pins ilmb_v10/LMB_Clk] [get_bd_pins lmb_bram_if_cntlr/LMB_Clk]

  # Restore current instance
  current_bd_instance $oldCurInst
}

# Hierarchical cell: mb1_lmb
proc create_hier_cell_mb1_lmb { parentCell nameHier } {

  variable script_folder

  if { $parentCell eq "" || $nameHier eq "" } {
     catch {common::send_msg_id "BD_TCL-102" "ERROR" create_hier_cell_mb1_lmb() - Empty argument(s)!"}
     return
  }

  # Get object for parentCell
  set parentObj [get_bd_cells $parentCell]
  if { $parentObj == "" } {
     catch {common::send_msg_id "BD_TCL-100" "ERROR" "Unable to find parent cell <$parentCell>!"}
     return
  }

  # Make sure parentObj is hier blk
  set parentType [get_property TYPE $parentObj]
  if { $parentType ne "hier" } {
     catch {common::send_msg_id "BD_TCL-101" "ERROR" "Parent <$parentObj> has TYPE = <$parentType>. Expected to be <hier>."}
     return
  }

  # Save current instance; Restore later
  set oldCurInst [current_bd_instance .]

  # Set parent object as current
  current_bd_instance $parentObj

  # Create cell and set as current instance
  set hier_obj [create_bd_cell -type hier $nameHier]
  current_bd_instance $hier_obj

  # Create interface pins
  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:bram_rtl:1.0 BRAM_PORTB
  create_bd_intf_pin -mode MirroredMaster -vlnv xilinx.com:interface:lmb_rtl:1.0 DLMB
  create_bd_intf_pin -mode MirroredMaster -vlnv xilinx.com:interface:lmb_rtl:1.0 ILMB

  # Create pins
  create_bd_pin -dir I -type clk LMB_Clk
  create_bd_pin -dir I -from 0 -to 0 -type rst SYS_Rst

  # Create instance: dlmb_v10, and set properties
  set dlmb_v10 [ create_bd_cell -type ip -vlnv xilinx.com:ip:lmb_v10:3.0 dlmb_v10 ]

  # Create instance: ilmb_v10, and set properties
  set ilmb_v10 [ create_bd_cell -type ip -vlnv xilinx.com:ip:lmb_v10:3.0 ilmb_v10 ]

  # Create instance: lmb_bram, and set properties
  set lmb_bram [ create_bd_cell -type ip -vlnv xilinx.com:ip:blk_mem_gen:8.3 lmb_bram ]
  set_property -dict [ list \
CONFIG.Memory_Type {True_Dual_Port_RAM} \
CONFIG.use_bram_block {BRAM_Controller} \
 ] $lmb_bram

  # Create instance: lmb_bram_if_cntlr, and set properties
  set lmb_bram_if_cntlr [ create_bd_cell -type ip -vlnv xilinx.com:ip:lmb_bram_if_cntlr:4.0 lmb_bram_if_cntlr ]
  set_property -dict [ list \
CONFIG.C_ECC {0} \
CONFIG.C_NUM_LMB {2} \
 ] $lmb_bram_if_cntlr

  # Create interface connections
  connect_bd_intf_net -intf_net Conn [get_bd_intf_pins dlmb_v10/LMB_Sl_0] [get_bd_intf_pins lmb_bram_if_cntlr/SLMB1]
  connect_bd_intf_net -intf_net Conn1 [get_bd_intf_pins BRAM_PORTB] [get_bd_intf_pins lmb_bram/BRAM_PORTB]
  connect_bd_intf_net -intf_net lmb_bram_if_cntlr_BRAM_PORT [get_bd_intf_pins lmb_bram/BRAM_PORTA] [get_bd_intf_pins lmb_bram_if_cntlr/BRAM_PORT]
  connect_bd_intf_net -intf_net microblaze_0_dlmb [get_bd_intf_pins DLMB] [get_bd_intf_pins dlmb_v10/LMB_M]
  connect_bd_intf_net -intf_net microblaze_0_ilmb [get_bd_intf_pins ILMB] [get_bd_intf_pins ilmb_v10/LMB_M]
  connect_bd_intf_net -intf_net microblaze_0_ilmb_bus [get_bd_intf_pins ilmb_v10/LMB_Sl_0] [get_bd_intf_pins lmb_bram_if_cntlr/SLMB]

  # Create port connections
  connect_bd_net -net SYS_Rst_1 [get_bd_pins SYS_Rst] [get_bd_pins dlmb_v10/SYS_Rst] [get_bd_pins ilmb_v10/SYS_Rst] [get_bd_pins lmb_bram_if_cntlr/LMB_Rst]
  connect_bd_net -net microblaze_0_Clk [get_bd_pins LMB_Clk] [get_bd_pins dlmb_v10/LMB_Clk] [get_bd_pins ilmb_v10/LMB_Clk] [get_bd_pins lmb_bram_if_cntlr/LMB_Clk]

  # Restore current instance
  current_bd_instance $oldCurInst
}

# Hierarchical cell: video
proc create_hier_cell_video { parentCell nameHier } {

  variable script_folder

  if { $parentCell eq "" || $nameHier eq "" } {
     catch {common::send_msg_id "BD_TCL-102" "ERROR" create_hier_cell_video() - Empty argument(s)!"}
     return
  }

  # Get object for parentCell
  set parentObj [get_bd_cells $parentCell]
  if { $parentObj == "" } {
     catch {common::send_msg_id "BD_TCL-100" "ERROR" "Unable to find parent cell <$parentCell>!"}
     return
  }

  # Make sure parentObj is hier blk
  set parentType [get_property TYPE $parentObj]
  if { $parentType ne "hier" } {
     catch {common::send_msg_id "BD_TCL-101" "ERROR" "Parent <$parentObj> has TYPE = <$parentType>. Expected to be <hier>."}
     return
  }

  # Save current instance; Restore later
  set oldCurInst [current_bd_instance .]

  # Set parent object as current
  current_bd_instance $parentObj

  # Create cell and set as current instance
  set hier_obj [create_bd_cell -type hier $nameHier]
  current_bd_instance $hier_obj

  # Create interface pins
  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:iic_rtl:1.0 DDC
  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 M00_AXI
  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S_AXI
  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S_AXI1
  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S_AXI_LITE
  create_bd_intf_pin -mode Slave -vlnv digilentinc.com:interface:tmds_rtl:1.0 TMDS
  create_bd_intf_pin -mode Master -vlnv digilentinc.com:interface:tmds_rtl:1.0 TMDS1
  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 ctrl
  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 ctrl1
  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 s00_axi

  # Create pins
  create_bd_pin -dir I ACLK
  create_bd_pin -dir I -from 0 -to 0 -type rst ARESETN
  create_bd_pin -dir I -from 0 -to 0 -type rst M00_ARESETN
  create_bd_pin -dir O -type clk PixelClk
  create_bd_pin -dir I -type clk RefClk
  create_bd_pin -dir I -type clk S00_ACLK
  create_bd_pin -dir O aPixelClkLckd
  create_bd_pin -dir O -from 5 -to 0 dout
  create_bd_pin -dir O -from 0 -to 0 gpio_io_o
  create_bd_pin -dir O -from 0 -to 0 gpio_io_o1
  create_bd_pin -dir I -from 0 -to 0 -type rst resetn
  create_bd_pin -dir I -from 0 -to 0 -type rst s00_axi_aresetn
  create_bd_pin -dir I -from 0 -to 0 -type rst vid_io_in_reset

  # Create instance: axi_dynclk_0, and set properties
  set axi_dynclk_0 [ create_bd_cell -type ip -vlnv digilentinc.com:ip:axi_dynclk:1.0 axi_dynclk_0 ]

  # Create instance: axi_gpio_video, and set properties
  set axi_gpio_video [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_gpio:2.0 axi_gpio_video ]
  set_property -dict [ list \
CONFIG.C_ALL_INPUTS_2 {1} \
CONFIG.C_ALL_OUTPUTS {1} \
CONFIG.C_GPIO2_WIDTH {1} \
CONFIG.C_GPIO_WIDTH {1} \
CONFIG.C_INTERRUPT_PRESENT {1} \
CONFIG.C_IS_DUAL {1} \
 ] $axi_gpio_video

  # Create instance: axi_mem_intercon, and set properties
  set axi_mem_intercon [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_interconnect:2.1 axi_mem_intercon ]
  set_property -dict [ list \
CONFIG.NUM_MI {1} \
CONFIG.NUM_SI {2} \
 ] $axi_mem_intercon

  # Create instance: axi_vdma_0, and set properties
  set axi_vdma_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_vdma:6.2 axi_vdma_0 ]
  set_property -dict [ list \
CONFIG.c_m_axi_mm2s_data_width {32} \
CONFIG.c_m_axis_mm2s_tdata_width {24} \
CONFIG.c_mm2s_genlock_mode {0} \
CONFIG.c_mm2s_linebuffer_depth {4096} \
CONFIG.c_mm2s_max_burst_length {32} \
CONFIG.c_s2mm_genlock_mode {0} \
CONFIG.c_s2mm_linebuffer_depth {4096} \
CONFIG.c_s2mm_max_burst_length {32} \
 ] $axi_vdma_0

  # Create instance: dvi2rgb_0, and set properties
  set dvi2rgb_0 [ create_bd_cell -type ip -vlnv digilentinc.com:ip:dvi2rgb:1.6 dvi2rgb_0 ]
  set_property -dict [ list \
CONFIG.kAddBUFG {false} \
CONFIG.kClkRange {1} \
CONFIG.kEdidFileName {720p_edid.txt} \
CONFIG.kRstActiveHigh {false} \
 ] $dvi2rgb_0

  # Create instance: hdmi_out_hpd_video, and set properties
  set hdmi_out_hpd_video [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_gpio:2.0 hdmi_out_hpd_video ]
  set_property -dict [ list \
CONFIG.C_ALL_OUTPUTS {1} \
CONFIG.C_GPIO_WIDTH {1} \
CONFIG.C_INTERRUPT_PRESENT {1} \
 ] $hdmi_out_hpd_video

  # Create instance: rgb2dvi_0, and set properties
  set rgb2dvi_0 [ create_bd_cell -type ip -vlnv digilentinc.com:ip:rgb2dvi:1.2 rgb2dvi_0 ]
  set_property -dict [ list \
CONFIG.kClkRange {2} \
CONFIG.kGenerateSerialClk {false} \
CONFIG.kRstActiveHigh {false} \
 ] $rgb2dvi_0

  # Create instance: v_axi4s_vid_out_0, and set properties
  set v_axi4s_vid_out_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:v_axi4s_vid_out:4.0 v_axi4s_vid_out_0 ]
  set_property -dict [ list \
CONFIG.C_ADDR_WIDTH {5} \
CONFIG.C_VTG_MASTER_SLAVE {1} \
 ] $v_axi4s_vid_out_0

  # Create instance: v_tc_0, and set properties
  set v_tc_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:v_tc:6.1 v_tc_0 ]
  set_property -dict [ list \
CONFIG.enable_detection {false} \
 ] $v_tc_0

  # Create instance: v_tc_1, and set properties
  set v_tc_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:v_tc:6.1 v_tc_1 ]
  set_property -dict [ list \
CONFIG.HAS_INTC_IF {true} \
CONFIG.enable_generation {false} \
CONFIG.horizontal_blank_detection {false} \
CONFIG.max_lines_per_frame {2048} \
CONFIG.vertical_blank_detection {false} \
 ] $v_tc_1

  # Create instance: v_vid_in_axi4s_0, and set properties
  set v_vid_in_axi4s_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:v_vid_in_axi4s:4.0 v_vid_in_axi4s_0 ]
  set_property -dict [ list \
CONFIG.C_ADDR_WIDTH {12} \
CONFIG.C_HAS_ASYNC_CLK {1} \
 ] $v_vid_in_axi4s_0

  # Create instance: xlconcat_0, and set properties
  set xlconcat_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconcat:2.1 xlconcat_0 ]
  set_property -dict [ list \
CONFIG.NUM_PORTS {6} \
 ] $xlconcat_0

  # Create interface connections
  connect_bd_intf_net -intf_net Conn1 [get_bd_intf_pins TMDS1] [get_bd_intf_pins rgb2dvi_0/TMDS]
  connect_bd_intf_net -intf_net Conn2 [get_bd_intf_pins ctrl] [get_bd_intf_pins v_tc_0/ctrl]
  connect_bd_intf_net -intf_net Conn3 [get_bd_intf_pins ctrl1] [get_bd_intf_pins v_tc_1/ctrl]
  connect_bd_intf_net -intf_net Conn4 [get_bd_intf_pins S_AXI_LITE] [get_bd_intf_pins axi_vdma_0/S_AXI_LITE]
  connect_bd_intf_net -intf_net axi_mem_intercon_M00_AXI [get_bd_intf_pins M00_AXI] [get_bd_intf_pins axi_mem_intercon/M00_AXI]
  connect_bd_intf_net -intf_net axi_vdma_0_M_AXIS_MM2S [get_bd_intf_pins axi_vdma_0/M_AXIS_MM2S] [get_bd_intf_pins v_axi4s_vid_out_0/video_in]
  connect_bd_intf_net -intf_net axi_vdma_0_M_AXI_MM2S [get_bd_intf_pins axi_mem_intercon/S01_AXI] [get_bd_intf_pins axi_vdma_0/M_AXI_MM2S]
  connect_bd_intf_net -intf_net axi_vdma_0_M_AXI_S2MM [get_bd_intf_pins axi_mem_intercon/S00_AXI] [get_bd_intf_pins axi_vdma_0/M_AXI_S2MM]
  connect_bd_intf_net -intf_net dvi2rgb_0_DDC [get_bd_intf_pins DDC] [get_bd_intf_pins dvi2rgb_0/DDC]
  connect_bd_intf_net -intf_net dvi2rgb_0_RGB [get_bd_intf_pins dvi2rgb_0/RGB] [get_bd_intf_pins v_vid_in_axi4s_0/vid_io_in]
  connect_bd_intf_net -intf_net hdmi_in_1 [get_bd_intf_pins TMDS] [get_bd_intf_pins dvi2rgb_0/TMDS]
  connect_bd_intf_net -intf_net processing_system7_0_axi_periph_M06_AXI [get_bd_intf_pins S_AXI] [get_bd_intf_pins hdmi_out_hpd_video/S_AXI]
  connect_bd_intf_net -intf_net processing_system7_0_axi_periph_M07_AXI [get_bd_intf_pins S_AXI1] [get_bd_intf_pins axi_gpio_video/S_AXI]
  connect_bd_intf_net -intf_net processing_system7_0_axi_periph_M08_AXI [get_bd_intf_pins s00_axi] [get_bd_intf_pins axi_dynclk_0/s00_axi]
  connect_bd_intf_net -intf_net v_axi4s_vid_out_0_vid_io_out [get_bd_intf_pins rgb2dvi_0/RGB] [get_bd_intf_pins v_axi4s_vid_out_0/vid_io_out]
  connect_bd_intf_net -intf_net v_tc_0_vtiming_out [get_bd_intf_pins v_axi4s_vid_out_0/vtiming_in] [get_bd_intf_pins v_tc_0/vtiming_out]
  connect_bd_intf_net -intf_net v_vid_in_axi4s_0_video_out [get_bd_intf_pins axi_vdma_0/S_AXIS_S2MM] [get_bd_intf_pins v_vid_in_axi4s_0/video_out]
  connect_bd_intf_net -intf_net v_vid_in_axi4s_0_vtiming_out [get_bd_intf_pins v_tc_1/vtiming_in] [get_bd_intf_pins v_vid_in_axi4s_0/vtiming_out]

  # Create port connections
  connect_bd_net -net Net [get_bd_pins S00_ACLK] [get_bd_pins axi_dynclk_0/REF_CLK_I] [get_bd_pins axi_dynclk_0/s00_axi_aclk] [get_bd_pins axi_gpio_video/s_axi_aclk] [get_bd_pins axi_vdma_0/s_axi_lite_aclk] [get_bd_pins hdmi_out_hpd_video/s_axi_aclk] [get_bd_pins v_tc_0/s_axi_aclk] [get_bd_pins v_tc_1/s_axi_aclk]
  connect_bd_net -net Net1 [get_bd_pins s00_axi_aresetn] [get_bd_pins axi_dynclk_0/s00_axi_aresetn] [get_bd_pins axi_gpio_video/s_axi_aresetn] [get_bd_pins axi_vdma_0/axi_resetn] [get_bd_pins dvi2rgb_0/aRst_n] [get_bd_pins hdmi_out_hpd_video/s_axi_aresetn] [get_bd_pins v_tc_0/s_axi_aresetn] [get_bd_pins v_tc_1/s_axi_aresetn]
  connect_bd_net -net RefClk_1 [get_bd_pins RefClk] [get_bd_pins dvi2rgb_0/RefClk]
  connect_bd_net -net aclk_1 [get_bd_pins ACLK] [get_bd_pins axi_mem_intercon/ACLK] [get_bd_pins axi_mem_intercon/M00_ACLK] [get_bd_pins axi_mem_intercon/S00_ACLK] [get_bd_pins axi_mem_intercon/S01_ACLK] [get_bd_pins axi_vdma_0/m_axi_mm2s_aclk] [get_bd_pins axi_vdma_0/m_axi_s2mm_aclk] [get_bd_pins axi_vdma_0/s_axis_s2mm_aclk] [get_bd_pins v_vid_in_axi4s_0/aclk]
  connect_bd_net -net axi_dynclk_0_LOCKED_O [get_bd_pins axi_dynclk_0/LOCKED_O] [get_bd_pins rgb2dvi_0/aRst_n]
  connect_bd_net -net axi_dynclk_0_PXL_CLK_5X_O [get_bd_pins axi_dynclk_0/PXL_CLK_5X_O] [get_bd_pins rgb2dvi_0/SerialClk]
  connect_bd_net -net axi_dynclk_0_PXL_CLK_O [get_bd_pins axi_dynclk_0/PXL_CLK_O] [get_bd_pins axi_vdma_0/m_axis_mm2s_aclk] [get_bd_pins rgb2dvi_0/PixelClk] [get_bd_pins v_axi4s_vid_out_0/aclk] [get_bd_pins v_tc_0/clk]
  connect_bd_net -net axi_gpio_video_gpio_io_o [get_bd_pins gpio_io_o1] [get_bd_pins axi_gpio_video/gpio_io_o]
  connect_bd_net -net axi_gpio_video_ip2intc_irpt [get_bd_pins axi_gpio_video/ip2intc_irpt] [get_bd_pins xlconcat_0/In4]
  connect_bd_net -net axi_vdma_0_mm2s_introut [get_bd_pins axi_vdma_0/mm2s_introut] [get_bd_pins xlconcat_0/In1]
  connect_bd_net -net axi_vdma_0_s2mm_introut [get_bd_pins axi_vdma_0/s2mm_introut] [get_bd_pins xlconcat_0/In0]
  connect_bd_net -net dvi2rgb_0_PixelClk [get_bd_pins PixelClk] [get_bd_pins dvi2rgb_0/PixelClk] [get_bd_pins v_tc_1/clk] [get_bd_pins v_vid_in_axi4s_0/vid_io_in_clk]
  connect_bd_net -net dvi2rgb_0_aPixelClkLckd [get_bd_pins aPixelClkLckd] [get_bd_pins axi_gpio_video/gpio2_io_i] [get_bd_pins dvi2rgb_0/aPixelClkLckd]
  connect_bd_net -net hdmi_out_hpd_video_gpio_io_o [get_bd_pins gpio_io_o] [get_bd_pins hdmi_out_hpd_video/gpio_io_o]
  connect_bd_net -net hdmi_out_hpd_video_ip2intc_irpt [get_bd_pins hdmi_out_hpd_video/ip2intc_irpt] [get_bd_pins xlconcat_0/In5]
  connect_bd_net -net resetn_1 [get_bd_pins resetn] [get_bd_pins v_tc_1/resetn]
  connect_bd_net -net rst_processing_system7_0_100M_interconnect_aresetn [get_bd_pins ARESETN] [get_bd_pins axi_mem_intercon/ARESETN]
  connect_bd_net -net rst_processing_system7_0_100M_peripheral_aresetn [get_bd_pins M00_ARESETN] [get_bd_pins axi_mem_intercon/M00_ARESETN] [get_bd_pins axi_mem_intercon/S00_ARESETN] [get_bd_pins axi_mem_intercon/S01_ARESETN]
  connect_bd_net -net v_tc_0_irq [get_bd_pins v_tc_0/irq] [get_bd_pins xlconcat_0/In2]
  connect_bd_net -net v_tc_1_irq [get_bd_pins v_tc_1/irq] [get_bd_pins xlconcat_0/In3]
  connect_bd_net -net vid_io_in_reset_1 [get_bd_pins vid_io_in_reset] [get_bd_pins v_vid_in_axi4s_0/vid_io_in_reset]
  connect_bd_net -net xlconcat_0_dout [get_bd_pins dout] [get_bd_pins xlconcat_0/dout]

  # Restore current instance
  current_bd_instance $oldCurInst
}

# Hierarchical cell: tracebuffer_pmods
proc create_hier_cell_tracebuffer_pmods { parentCell nameHier } {

  variable script_folder

  if { $parentCell eq "" || $nameHier eq "" } {
     catch {common::send_msg_id "BD_TCL-102" "ERROR" create_hier_cell_tracebuffer_pmods() - Empty argument(s)!"}
     return
  }

  # Get object for parentCell
  set parentObj [get_bd_cells $parentCell]
  if { $parentObj == "" } {
     catch {common::send_msg_id "BD_TCL-100" "ERROR" "Unable to find parent cell <$parentCell>!"}
     return
  }

  # Make sure parentObj is hier blk
  set parentType [get_property TYPE $parentObj]
  if { $parentType ne "hier" } {
     catch {common::send_msg_id "BD_TCL-101" "ERROR" "Parent <$parentObj> has TYPE = <$parentType>. Expected to be <hier>."}
     return
  }

  # Save current instance; Restore later
  set oldCurInst [current_bd_instance .]

  # Set parent object as current
  current_bd_instance $parentObj

  # Create cell and set as current instance
  set hier_obj [create_bd_cell -type hier $nameHier]
  current_bd_instance $hier_obj

  # Create interface pins
  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 M_AXI_S2MM
  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S_AXI
  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S_AXI_LITE

  # Create pins
  create_bd_pin -dir I -from 63 -to 0 A_TDATA
  create_bd_pin -dir I -from 0 -to 0 A_TVALID
  create_bd_pin -dir O -type intr s2mm_introut
  create_bd_pin -dir I -type clk s_axi_aclk
  create_bd_pin -dir I -from 0 -to 0 -type rst s_axi_aresetn

  # Create instance: axi_dma_0, and set properties
  set axi_dma_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_dma:7.1 axi_dma_0 ]
  set_property -dict [ list \
CONFIG.c_include_mm2s {0} \
CONFIG.c_include_sg {0} \
CONFIG.c_m_axi_s2mm_data_width {64} \
CONFIG.c_s2mm_burst_size {64} \
CONFIG.c_sg_include_stscntrl_strm {0} \
CONFIG.c_sg_length_width {23} \
 ] $axi_dma_0

  # Create instance: axis_data_fifo_0, and set properties
  set axis_data_fifo_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axis_data_fifo:1.1 axis_data_fifo_0 ]
  set_property -dict [ list \
CONFIG.FIFO_DEPTH {256} \
CONFIG.HAS_TKEEP {1} \
CONFIG.HAS_TLAST {1} \
CONFIG.HAS_TSTRB {1} \
CONFIG.TDATA_NUM_BYTES {8} \
CONFIG.TDEST_WIDTH {1} \
CONFIG.TID_WIDTH {5} \
CONFIG.TUSER_WIDTH {2} \
 ] $axis_data_fifo_0

  # Create instance: constant_tkeep_tstrb, and set properties
  set constant_tkeep_tstrb [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant:1.1 constant_tkeep_tstrb ]
  set_property -dict [ list \
CONFIG.CONST_VAL {255} \
CONFIG.CONST_WIDTH {8} \
 ] $constant_tkeep_tstrb

  # Create instance: trace_cntrl_0, and set properties
  set trace_cntrl_0 [ create_bd_cell -type ip -vlnv xilinx.com:hls:trace_cntrl:1.2 trace_cntrl_0 ]

  # Create interface connections
  connect_bd_intf_net -intf_net S_AXI_1 [get_bd_intf_pins S_AXI] [get_bd_intf_pins trace_cntrl_0/s_axi_trace_cntrl]
  connect_bd_intf_net -intf_net axi_dma_0_M_AXI_S2MM [get_bd_intf_pins M_AXI_S2MM] [get_bd_intf_pins axi_dma_0/M_AXI_S2MM]
  connect_bd_intf_net -intf_net axis_data_fifo_0_M_AXIS [get_bd_intf_pins axi_dma_0/S_AXIS_S2MM] [get_bd_intf_pins axis_data_fifo_0/M_AXIS]
  connect_bd_intf_net -intf_net processing_system7_0_axi_periph_1_M01_AXI [get_bd_intf_pins S_AXI_LITE] [get_bd_intf_pins axi_dma_0/S_AXI_LITE]
  connect_bd_intf_net -intf_net trace_cntrl_0_B [get_bd_intf_pins axis_data_fifo_0/S_AXIS] [get_bd_intf_pins trace_cntrl_0/B]

  # Create port connections
  connect_bd_net -net A_TDATA_1 [get_bd_pins A_TDATA] [get_bd_pins trace_cntrl_0/A_TDATA]
  connect_bd_net -net A_TVALID_1 [get_bd_pins A_TVALID] [get_bd_pins trace_cntrl_0/A_TVALID]
  connect_bd_net -net constant_tkeep_dout [get_bd_pins constant_tkeep_tstrb/dout] [get_bd_pins trace_cntrl_0/A_TKEEP] [get_bd_pins trace_cntrl_0/A_TSTRB]
  connect_bd_net -net processing_system7_0_FCLK_CLK3 [get_bd_pins s_axi_aclk] [get_bd_pins axi_dma_0/m_axi_s2mm_aclk] [get_bd_pins axi_dma_0/s_axi_lite_aclk] [get_bd_pins axis_data_fifo_0/s_axis_aclk] [get_bd_pins trace_cntrl_0/ap_clk]
  connect_bd_net -net rst_processing_system7_0_166M_peripheral_aresetn [get_bd_pins s_axi_aresetn] [get_bd_pins axi_dma_0/axi_resetn] [get_bd_pins axis_data_fifo_0/s_axis_aresetn] [get_bd_pins trace_cntrl_0/ap_rst_n]
  connect_bd_net -net tracebuffer_pmod_s2mm_introut [get_bd_pins s2mm_introut] [get_bd_pins axi_dma_0/s2mm_introut]

  # Restore current instance
  current_bd_instance $oldCurInst
}

# Hierarchical cell: tracebuffer_arduino
proc create_hier_cell_tracebuffer_arduino { parentCell nameHier } {

  variable script_folder

  if { $parentCell eq "" || $nameHier eq "" } {
     catch {common::send_msg_id "BD_TCL-102" "ERROR" create_hier_cell_tracebuffer_arduino() - Empty argument(s)!"}
     return
  }

  # Get object for parentCell
  set parentObj [get_bd_cells $parentCell]
  if { $parentObj == "" } {
     catch {common::send_msg_id "BD_TCL-100" "ERROR" "Unable to find parent cell <$parentCell>!"}
     return
  }

  # Make sure parentObj is hier blk
  set parentType [get_property TYPE $parentObj]
  if { $parentType ne "hier" } {
     catch {common::send_msg_id "BD_TCL-101" "ERROR" "Parent <$parentObj> has TYPE = <$parentType>. Expected to be <hier>."}
     return
  }

  # Save current instance; Restore later
  set oldCurInst [current_bd_instance .]

  # Set parent object as current
  current_bd_instance $parentObj

  # Create cell and set as current instance
  set hier_obj [create_bd_cell -type hier $nameHier]
  current_bd_instance $hier_obj

  # Create interface pins
  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 M_AXI_S2MM
  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S_AXI
  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S_AXI_LITE

  # Create pins
  create_bd_pin -dir I -from 63 -to 0 A_TDATA
  create_bd_pin -dir I -from 0 -to 0 A_TVALID
  create_bd_pin -dir O -type intr s2mm_introut
  create_bd_pin -dir I -type clk s_axi_aclk
  create_bd_pin -dir I -from 0 -to 0 -type rst s_axi_aresetn

  # Create instance: axi_dma_0, and set properties
  set axi_dma_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_dma:7.1 axi_dma_0 ]
  set_property -dict [ list \
CONFIG.c_include_mm2s {0} \
CONFIG.c_include_sg {0} \
CONFIG.c_m_axi_s2mm_data_width {64} \
CONFIG.c_s2mm_burst_size {64} \
CONFIG.c_sg_include_stscntrl_strm {0} \
CONFIG.c_sg_length_width {23} \
 ] $axi_dma_0

  # Create instance: axis_data_fifo_0, and set properties
  set axis_data_fifo_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axis_data_fifo:1.1 axis_data_fifo_0 ]
  set_property -dict [ list \
CONFIG.FIFO_DEPTH {256} \
CONFIG.HAS_TKEEP {1} \
CONFIG.HAS_TLAST {1} \
CONFIG.HAS_TSTRB {1} \
CONFIG.TDATA_NUM_BYTES {8} \
CONFIG.TDEST_WIDTH {1} \
CONFIG.TID_WIDTH {5} \
CONFIG.TUSER_WIDTH {2} \
 ] $axis_data_fifo_0

  # Create instance: constant_tkeep_tstrb, and set properties
  set constant_tkeep_tstrb [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant:1.1 constant_tkeep_tstrb ]
  set_property -dict [ list \
CONFIG.CONST_VAL {255} \
CONFIG.CONST_WIDTH {8} \
 ] $constant_tkeep_tstrb

  # Create instance: trace_cntrl_0, and set properties
  set trace_cntrl_0 [ create_bd_cell -type ip -vlnv xilinx.com:hls:trace_cntrl:1.2 trace_cntrl_0 ]

  # Create interface connections
  connect_bd_intf_net -intf_net S_AXI_1 [get_bd_intf_pins S_AXI] [get_bd_intf_pins trace_cntrl_0/s_axi_trace_cntrl]
  connect_bd_intf_net -intf_net axi_dma_0_M_AXI_S2MM_1 [get_bd_intf_pins M_AXI_S2MM] [get_bd_intf_pins axi_dma_0/M_AXI_S2MM]
  connect_bd_intf_net -intf_net axis_data_fifo_0_M_AXIS [get_bd_intf_pins axi_dma_0/S_AXIS_S2MM] [get_bd_intf_pins axis_data_fifo_0/M_AXIS]
  connect_bd_intf_net -intf_net processing_system7_0_axi_periph_1_M03_AXI [get_bd_intf_pins S_AXI_LITE] [get_bd_intf_pins axi_dma_0/S_AXI_LITE]
  connect_bd_intf_net -intf_net trace_cntrl_0_B [get_bd_intf_pins axis_data_fifo_0/S_AXIS] [get_bd_intf_pins trace_cntrl_0/B]

  # Create port connections
  connect_bd_net -net A_TDATA_1 [get_bd_pins A_TDATA] [get_bd_pins trace_cntrl_0/A_TDATA]
  connect_bd_net -net A_TVALID_1 [get_bd_pins A_TVALID] [get_bd_pins trace_cntrl_0/A_TVALID]
  connect_bd_net -net constant_tkeep_tstrb_dout [get_bd_pins constant_tkeep_tstrb/dout] [get_bd_pins trace_cntrl_0/A_TKEEP] [get_bd_pins trace_cntrl_0/A_TSTRB]
  connect_bd_net -net processing_system7_0_FCLK_CLK3 [get_bd_pins s_axi_aclk] [get_bd_pins axi_dma_0/m_axi_s2mm_aclk] [get_bd_pins axi_dma_0/s_axi_lite_aclk] [get_bd_pins axis_data_fifo_0/s_axis_aclk] [get_bd_pins trace_cntrl_0/ap_clk]
  connect_bd_net -net rst_processing_system7_0_166M_peripheral_aresetn [get_bd_pins s_axi_aresetn] [get_bd_pins axi_dma_0/axi_resetn] [get_bd_pins axis_data_fifo_0/s_axis_aresetn] [get_bd_pins trace_cntrl_0/ap_rst_n]
  connect_bd_net -net tracebuffer_arduino_s2mm_introut [get_bd_pins s2mm_introut] [get_bd_pins axi_dma_0/s2mm_introut]

  # Restore current instance
  current_bd_instance $oldCurInst
}

# Hierarchical cell: iop3
proc create_hier_cell_iop3 { parentCell nameHier } {

  variable script_folder

  if { $parentCell eq "" || $nameHier eq "" } {
     catch {common::send_msg_id "BD_TCL-102" "ERROR" create_hier_cell_iop3() - Empty argument(s)!"}
     return
  }

  # Get object for parentCell
  set parentObj [get_bd_cells $parentCell]
  if { $parentObj == "" } {
     catch {common::send_msg_id "BD_TCL-100" "ERROR" "Unable to find parent cell <$parentCell>!"}
     return
  }

  # Make sure parentObj is hier blk
  set parentType [get_property TYPE $parentObj]
  if { $parentType ne "hier" } {
     catch {common::send_msg_id "BD_TCL-101" "ERROR" "Parent <$parentObj> has TYPE = <$parentType>. Expected to be <hier>."}
     return
  }

  # Save current instance; Restore later
  set oldCurInst [current_bd_instance .]

  # Set parent object as current
  current_bd_instance $parentObj

  # Create cell and set as current instance
  set hier_obj [create_bd_cell -type hier $nameHier]
  current_bd_instance $hier_obj

  # Create interface pins
  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:bram_rtl:1.0 BRAM_PORTB
  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:mbdebug_rtl:3.0 DEBUG
  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 M18_AXI
  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:diff_analog_io_rtl:1.0 Vaux0
  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:diff_analog_io_rtl:1.0 Vaux1
  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:diff_analog_io_rtl:1.0 Vaux5
  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:diff_analog_io_rtl:1.0 Vaux6
  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:diff_analog_io_rtl:1.0 Vaux8
  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:diff_analog_io_rtl:1.0 Vaux9
  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:diff_analog_io_rtl:1.0 Vaux12
  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:diff_analog_io_rtl:1.0 Vaux13
  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:diff_analog_io_rtl:1.0 Vaux15
  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:diff_analog_io_rtl:1.0 Vp_Vn
  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:gpio_rtl:1.0 ck_io
  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:spi_rtl:1.0 spi_sw_shield

  # Create pins
  create_bd_pin -dir I -from 0 -to 0 -type rst aux_reset_in
  create_bd_pin -dir I -type clk clk
  create_bd_pin -dir I -from 0 -to 0 -type rst ext_reset_in
  create_bd_pin -dir I -from 0 -to 0 mb3_intr_ack
  create_bd_pin -dir O mb3_intr_req
  create_bd_pin -dir I -type rst mb_debug_sys_rst
  create_bd_pin -dir O -from 0 -to 0 -type rst peripheral_aresetn
  create_bd_pin -dir I -from 0 -to 0 -type rst s_axi_aresetn
  create_bd_pin -dir I -from 5 -to 0 shield2sw_data_in_a5_a0
  create_bd_pin -dir I -from 11 -to 0 shield2sw_data_in_d13_d2
  create_bd_pin -dir I -from 1 -to 0 shield2sw_data_in_d1_d0
  create_bd_pin -dir I shield2sw_scl_i_in
  create_bd_pin -dir I shield2sw_sda_i_in
  create_bd_pin -dir O -from 5 -to 0 sw2shield_data_out_a5_a0
  create_bd_pin -dir O -from 11 -to 0 sw2shield_data_out_d13_d2
  create_bd_pin -dir O -from 1 -to 0 sw2shield_data_out_d1_d0
  create_bd_pin -dir O sw2shield_scl_o_out
  create_bd_pin -dir O sw2shield_scl_t_out
  create_bd_pin -dir O sw2shield_sda_o_out
  create_bd_pin -dir O sw2shield_sda_t_out
  create_bd_pin -dir O -from 5 -to 0 sw2shield_tri_out_a5_a0
  create_bd_pin -dir O -from 11 -to 0 sw2shield_tri_out_d13_d2
  create_bd_pin -dir O -from 1 -to 0 sw2shield_tri_out_d1_d0

  # Create instance: arduino_io_switch_0, and set properties
  set arduino_io_switch_0 [ create_bd_cell -type ip -vlnv xilinx.com:user:arduino_io_switch:1.0 arduino_io_switch_0 ]

  # Create instance: dff_en_reset_0, and set properties
  set dff_en_reset_0 [ create_bd_cell -type ip -vlnv xilinx.com:XUP:dff_en_reset:1.0 dff_en_reset_0 ]

  # Create instance: logic_0, and set properties
  set logic_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant:1.1 logic_0 ]
  set_property -dict [ list \
CONFIG.CONST_VAL {0} \
 ] $logic_0

  # Create instance: logic_0_6bits, and set properties
  set logic_0_6bits [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant:1.1 logic_0_6bits ]
  set_property -dict [ list \
CONFIG.CONST_VAL {0} \
CONFIG.CONST_WIDTH {6} \
 ] $logic_0_6bits

  # Create instance: logic_1, and set properties
  set logic_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant:1.1 logic_1 ]

  # Create instance: mb, and set properties
  set mb [ create_bd_cell -type ip -vlnv xilinx.com:ip:microblaze:9.6 mb ]
  set_property -dict [ list \
CONFIG.C_DEBUG_ENABLED {1} \
CONFIG.C_D_AXI {1} \
CONFIG.C_D_LMB {1} \
CONFIG.C_I_LMB {1} \
 ] $mb

  # Create instance: mb3_concat, and set properties
  set mb3_concat [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconcat:2.1 mb3_concat ]
  set_property -dict [ list \
CONFIG.NUM_PORTS {7} \
 ] $mb3_concat

  # Create instance: mb3_gpio_subsystem
  create_hier_cell_mb3_gpio_subsystem $hier_obj mb3_gpio_subsystem

  # Create instance: mb3_iic_subsystem
  create_hier_cell_mb3_iic_subsystem $hier_obj mb3_iic_subsystem

  # Create instance: mb3_intc, and set properties
  set mb3_intc [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_intc:4.1 mb3_intc ]

  # Create instance: mb3_intr, and set properties
  set mb3_intr [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_gpio:2.0 mb3_intr ]
  set_property -dict [ list \
CONFIG.C_ALL_OUTPUTS {1} \
CONFIG.C_GPIO_WIDTH {1} \
 ] $mb3_intr

  # Create instance: mb3_lmb
  create_hier_cell_mb3_lmb $hier_obj mb3_lmb

  # Create instance: mb3_spi_subsystem
  create_hier_cell_mb3_spi_subsystem $hier_obj mb3_spi_subsystem

  # Create instance: mb3_timers_subsystem
  create_hier_cell_mb3_timers_subsystem $hier_obj mb3_timers_subsystem

  # Create instance: mb3_uartlite_d1_d0, and set properties
  set mb3_uartlite_d1_d0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_uartlite:2.0 mb3_uartlite_d1_d0 ]
  set_property -dict [ list \
CONFIG.C_S_AXI_ACLK_FREQ_HZ {100000000} \
 ] $mb3_uartlite_d1_d0

  # Need to retain value_src of defaults
  set_property -dict [ list \
CONFIG.C_S_AXI_ACLK_FREQ_HZ.VALUE_SRC {DEFAULT} \
 ] $mb3_uartlite_d1_d0

  # Create instance: mb3_xadc, and set properties
  set mb3_xadc [ create_bd_cell -type ip -vlnv xilinx.com:ip:xadc_wiz:3.3 mb3_xadc ]
  set_property -dict [ list \
CONFIG.ADC_CONVERSION_RATE {1000} \
CONFIG.AVERAGE_ENABLE_TEMPERATURE {true} \
CONFIG.AVERAGE_ENABLE_VAUXP0_VAUXN0 {true} \
CONFIG.AVERAGE_ENABLE_VAUXP12_VAUXN12 {true} \
CONFIG.AVERAGE_ENABLE_VAUXP13_VAUXN13 {true} \
CONFIG.AVERAGE_ENABLE_VAUXP15_VAUXN15 {true} \
CONFIG.AVERAGE_ENABLE_VAUXP1_VAUXN1 {true} \
CONFIG.AVERAGE_ENABLE_VAUXP5_VAUXN5 {true} \
CONFIG.AVERAGE_ENABLE_VAUXP6_VAUXN6 {true} \
CONFIG.AVERAGE_ENABLE_VAUXP8_VAUXN8 {true} \
CONFIG.AVERAGE_ENABLE_VAUXP9_VAUXN9 {true} \
CONFIG.AVERAGE_ENABLE_VP_VN {true} \
CONFIG.BIPOLAR_VAUXP0_VAUXN0 {true} \
CONFIG.BIPOLAR_VAUXP12_VAUXN12 {true} \
CONFIG.BIPOLAR_VAUXP8_VAUXN8 {true} \
CONFIG.CHANNEL_AVERAGING {16} \
CONFIG.CHANNEL_ENABLE_TEMPERATURE {true} \
CONFIG.CHANNEL_ENABLE_VAUXP0_VAUXN0 {true} \
CONFIG.CHANNEL_ENABLE_VAUXP12_VAUXN12 {true} \
CONFIG.CHANNEL_ENABLE_VAUXP13_VAUXN13 {true} \
CONFIG.CHANNEL_ENABLE_VAUXP15_VAUXN15 {true} \
CONFIG.CHANNEL_ENABLE_VAUXP1_VAUXN1 {true} \
CONFIG.CHANNEL_ENABLE_VAUXP5_VAUXN5 {true} \
CONFIG.CHANNEL_ENABLE_VAUXP6_VAUXN6 {true} \
CONFIG.CHANNEL_ENABLE_VAUXP8_VAUXN8 {true} \
CONFIG.CHANNEL_ENABLE_VAUXP9_VAUXN9 {true} \
CONFIG.CHANNEL_ENABLE_VP_VN {true} \
CONFIG.CHANNEL_ENABLE_VREFN {false} \
CONFIG.CHANNEL_ENABLE_VREFP {false} \
CONFIG.DCLK_FREQUENCY {100} \
CONFIG.ENABLE_RESET {false} \
CONFIG.ENABLE_VCCDDRO_ALARM {false} \
CONFIG.ENABLE_VCCPAUX_ALARM {false} \
CONFIG.ENABLE_VCCPINT_ALARM {false} \
CONFIG.EXTERNAL_MUX_CHANNEL {VP_VN} \
CONFIG.INTERFACE_SELECTION {Enable_AXI} \
CONFIG.OT_ALARM {false} \
CONFIG.SEQUENCER_MODE {Continuous} \
CONFIG.SINGLE_CHANNEL_SELECTION {TEMPERATURE} \
CONFIG.USER_TEMP_ALARM {false} \
CONFIG.VCCAUX_ALARM {false} \
CONFIG.VCCDDRO_ALARM_LOWER {1.2} \
CONFIG.VCCINT_ALARM {false} \
CONFIG.XADC_STARUP_SELECTION {channel_sequencer} \
 ] $mb3_xadc

  # Need to retain value_src of defaults
  set_property -dict [ list \
CONFIG.ADC_CONVERSION_RATE.VALUE_SRC {DEFAULT} \
CONFIG.DCLK_FREQUENCY.VALUE_SRC {DEFAULT} \
CONFIG.ENABLE_RESET.VALUE_SRC {DEFAULT} \
CONFIG.INTERFACE_SELECTION.VALUE_SRC {DEFAULT} \
CONFIG.VCCDDRO_ALARM_LOWER.VALUE_SRC {DEFAULT} \
 ] $mb3_xadc

  # Create instance: microblaze_0_axi_periph, and set properties
  set microblaze_0_axi_periph [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_interconnect:2.1 microblaze_0_axi_periph ]
  set_property -dict [ list \
CONFIG.NUM_MI {19} \
 ] $microblaze_0_axi_periph

  # Create instance: rst_clk_wiz_1_100M, and set properties
  set rst_clk_wiz_1_100M [ create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset:5.0 rst_clk_wiz_1_100M ]
  set_property -dict [ list \
CONFIG.C_AUX_RESET_HIGH {1} \
 ] $rst_clk_wiz_1_100M

  # Create interface connections
  connect_bd_intf_net -intf_net Conn1 [get_bd_intf_pins ck_io] [get_bd_intf_pins mb3_gpio_subsystem/ck_gpio_d15_d0]
  connect_bd_intf_net -intf_net Conn3 [get_bd_intf_pins M18_AXI] [get_bd_intf_pins microblaze_0_axi_periph/M18_AXI]
  connect_bd_intf_net -intf_net Conn4 [get_bd_intf_pins Vaux0] [get_bd_intf_pins mb3_xadc/Vaux0]
  connect_bd_intf_net -intf_net Conn5 [get_bd_intf_pins spi_sw_shield] [get_bd_intf_pins arduino_io_switch_0/spi_sw_shield]
  connect_bd_intf_net -intf_net Conn6 [get_bd_intf_pins Vaux8] [get_bd_intf_pins mb3_xadc/Vaux8]
  connect_bd_intf_net -intf_net Conn7 [get_bd_intf_pins Vp_Vn] [get_bd_intf_pins mb3_xadc/Vp_Vn]
  connect_bd_intf_net -intf_net Conn8 [get_bd_intf_pins Vaux1] [get_bd_intf_pins mb3_xadc/Vaux1]
  connect_bd_intf_net -intf_net Conn9 [get_bd_intf_pins Vaux5] [get_bd_intf_pins mb3_xadc/Vaux5]
  connect_bd_intf_net -intf_net Conn10 [get_bd_intf_pins Vaux6] [get_bd_intf_pins mb3_xadc/Vaux6]
  connect_bd_intf_net -intf_net Conn11 [get_bd_intf_pins Vaux9] [get_bd_intf_pins mb3_xadc/Vaux9]
  connect_bd_intf_net -intf_net Conn12 [get_bd_intf_pins Vaux13] [get_bd_intf_pins mb3_xadc/Vaux13]
  connect_bd_intf_net -intf_net Conn13 [get_bd_intf_pins Vaux15] [get_bd_intf_pins mb3_xadc/Vaux15]
  connect_bd_intf_net -intf_net Conn14 [get_bd_intf_pins Vaux12] [get_bd_intf_pins mb3_xadc/Vaux12]
  connect_bd_intf_net -intf_net mb3_iic_pl_sw_IIC [get_bd_intf_pins arduino_io_switch_0/iic_pl_sw] [get_bd_intf_pins mb3_iic_subsystem/IIC1]
  connect_bd_intf_net -intf_net mb3_intc_interrupt [get_bd_intf_pins mb/INTERRUPT] [get_bd_intf_pins mb3_intc/interrupt]
  connect_bd_intf_net -intf_net mb3_shared_iic_sw_IIC [get_bd_intf_pins arduino_io_switch_0/shared_iic_sw] [get_bd_intf_pins mb3_iic_subsystem/IIC]
  connect_bd_intf_net -intf_net mb3_spi_pl_sw_SPI_0 [get_bd_intf_pins arduino_io_switch_0/spi_pl_sw] [get_bd_intf_pins mb3_spi_subsystem/SPI_0]
  connect_bd_intf_net -intf_net mb3_spi_pl_sw_d13_d10_SPI_0 [get_bd_intf_pins arduino_io_switch_0/spi_pl_sw_d13_d10] [get_bd_intf_pins mb3_spi_subsystem/SPI_1]
  connect_bd_intf_net -intf_net mb3_uartlite_d1_d0_UART [get_bd_intf_pins arduino_io_switch_0/uart_d1_d0] [get_bd_intf_pins mb3_uartlite_d1_d0/UART]
  connect_bd_intf_net -intf_net mb_bram_ctrl_1_BRAM_PORTA [get_bd_intf_pins BRAM_PORTB] [get_bd_intf_pins mb3_lmb/BRAM_PORTB]
  connect_bd_intf_net -intf_net microblaze_0_M_AXI_DP [get_bd_intf_pins mb/M_AXI_DP] [get_bd_intf_pins microblaze_0_axi_periph/S00_AXI]
  connect_bd_intf_net -intf_net microblaze_0_axi_periph_M00_AXI [get_bd_intf_pins mb3_spi_subsystem/AXI_LITE] [get_bd_intf_pins microblaze_0_axi_periph/M00_AXI]
  connect_bd_intf_net -intf_net microblaze_0_axi_periph_M01_AXI [get_bd_intf_pins mb3_iic_subsystem/S_AXI1] [get_bd_intf_pins microblaze_0_axi_periph/M01_AXI]
  connect_bd_intf_net -intf_net microblaze_0_axi_periph_M02_AXI [get_bd_intf_pins arduino_io_switch_0/S_AXI] [get_bd_intf_pins microblaze_0_axi_periph/M02_AXI]
  connect_bd_intf_net -intf_net microblaze_0_axi_periph_M03_AXI [get_bd_intf_pins mb3_gpio_subsystem/S_AXI1] [get_bd_intf_pins microblaze_0_axi_periph/M03_AXI]
  connect_bd_intf_net -intf_net microblaze_0_axi_periph_M05_AXI [get_bd_intf_pins mb3_gpio_subsystem/S_AXI] [get_bd_intf_pins microblaze_0_axi_periph/M05_AXI]
  connect_bd_intf_net -intf_net microblaze_0_axi_periph_M06_AXI [get_bd_intf_pins mb3_spi_subsystem/AXI_LITE1] [get_bd_intf_pins microblaze_0_axi_periph/M06_AXI]
  connect_bd_intf_net -intf_net microblaze_0_axi_periph_M07_AXI [get_bd_intf_pins mb3_iic_subsystem/S_AXI] [get_bd_intf_pins microblaze_0_axi_periph/M07_AXI]
  connect_bd_intf_net -intf_net microblaze_0_axi_periph_M08_AXI [get_bd_intf_pins mb3_uartlite_d1_d0/S_AXI] [get_bd_intf_pins microblaze_0_axi_periph/M08_AXI]
  connect_bd_intf_net -intf_net microblaze_0_axi_periph_M09_AXI [get_bd_intf_pins mb3_timers_subsystem/S_AXI] [get_bd_intf_pins microblaze_0_axi_periph/M09_AXI]
  connect_bd_intf_net -intf_net microblaze_0_axi_periph_M10_AXI [get_bd_intf_pins mb3_timers_subsystem/S_AXI1] [get_bd_intf_pins microblaze_0_axi_periph/M10_AXI]
  connect_bd_intf_net -intf_net microblaze_0_axi_periph_M11_AXI [get_bd_intf_pins mb3_timers_subsystem/S_AXI2] [get_bd_intf_pins microblaze_0_axi_periph/M11_AXI]
  connect_bd_intf_net -intf_net microblaze_0_axi_periph_M12_AXI [get_bd_intf_pins mb3_timers_subsystem/S_AXI3] [get_bd_intf_pins microblaze_0_axi_periph/M12_AXI]
  connect_bd_intf_net -intf_net microblaze_0_axi_periph_M13_AXI [get_bd_intf_pins mb3_timers_subsystem/S_AXI4] [get_bd_intf_pins microblaze_0_axi_periph/M13_AXI]
  connect_bd_intf_net -intf_net microblaze_0_axi_periph_M14_AXI [get_bd_intf_pins mb3_intc/s_axi] [get_bd_intf_pins microblaze_0_axi_periph/M14_AXI]
  connect_bd_intf_net -intf_net microblaze_0_axi_periph_M15_AXI [get_bd_intf_pins mb3_xadc/s_axi_lite] [get_bd_intf_pins microblaze_0_axi_periph/M15_AXI]
  connect_bd_intf_net -intf_net microblaze_0_axi_periph_M16_AXI [get_bd_intf_pins mb3_timers_subsystem/S_AXI5] [get_bd_intf_pins microblaze_0_axi_periph/M16_AXI]
  connect_bd_intf_net -intf_net microblaze_0_axi_periph_M17_AXI [get_bd_intf_pins mb3_intr/S_AXI] [get_bd_intf_pins microblaze_0_axi_periph/M17_AXI]
  connect_bd_intf_net -intf_net microblaze_0_debug [get_bd_intf_pins DEBUG] [get_bd_intf_pins mb/DEBUG]
  connect_bd_intf_net -intf_net microblaze_0_dlmb_1 [get_bd_intf_pins mb/DLMB] [get_bd_intf_pins mb3_lmb/DLMB]
  connect_bd_intf_net -intf_net microblaze_0_ilmb_1 [get_bd_intf_pins mb/ILMB] [get_bd_intf_pins mb3_lmb/ILMB]

  # Create port connections
  connect_bd_net -net arduino_io_switch_0_interrupt_i_in_a5_a0 [get_bd_pins arduino_io_switch_0/interrupt_i_in_a5_a0] [get_bd_pins mb3_concat/In0]
  connect_bd_net -net arduino_io_switch_0_interrupt_i_in_d13_d2 [get_bd_pins arduino_io_switch_0/interrupt_i_in_d13_d2] [get_bd_pins mb3_concat/In2]
  connect_bd_net -net arduino_io_switch_0_interrupt_i_in_d1_d0 [get_bd_pins arduino_io_switch_0/interrupt_i_in_d1_d0] [get_bd_pins mb3_concat/In1]
  connect_bd_net -net arduino_io_switch_0_sw2pl_data_in_a5_a0 [get_bd_pins arduino_io_switch_0/sw2pl_data_in_a5_a0] [get_bd_pins mb3_gpio_subsystem/in_a5_a0]
  connect_bd_net -net arduino_io_switch_0_sw2pl_data_in_d13_d2 [get_bd_pins arduino_io_switch_0/sw2pl_data_in_d13_d2] [get_bd_pins mb3_gpio_subsystem/din_d13_d2]
  connect_bd_net -net arduino_io_switch_0_sw2pl_data_in_d1_d0 [get_bd_pins arduino_io_switch_0/sw2pl_data_in_d1_d0] [get_bd_pins mb3_gpio_subsystem/din_d1_d0]
  connect_bd_net -net arduino_io_switch_0_sw2shield_data_out_a5_a0 [get_bd_pins sw2shield_data_out_a5_a0] [get_bd_pins arduino_io_switch_0/sw2shield_data_out_a5_a0]
  connect_bd_net -net arduino_io_switch_0_sw2shield_data_out_d13_d2 [get_bd_pins sw2shield_data_out_d13_d2] [get_bd_pins arduino_io_switch_0/sw2shield_data_out_d13_d2]
  connect_bd_net -net arduino_io_switch_0_sw2shield_data_out_d1_d0 [get_bd_pins sw2shield_data_out_d1_d0] [get_bd_pins arduino_io_switch_0/sw2shield_data_out_d1_d0]
  connect_bd_net -net arduino_io_switch_0_sw2shield_scl_o_out [get_bd_pins sw2shield_scl_o_out] [get_bd_pins arduino_io_switch_0/sw2shield_scl_o_out]
  connect_bd_net -net arduino_io_switch_0_sw2shield_scl_t_out [get_bd_pins sw2shield_scl_t_out] [get_bd_pins arduino_io_switch_0/sw2shield_scl_t_out]
  connect_bd_net -net arduino_io_switch_0_sw2shield_sda_o_out [get_bd_pins sw2shield_sda_o_out] [get_bd_pins arduino_io_switch_0/sw2shield_sda_o_out]
  connect_bd_net -net arduino_io_switch_0_sw2shield_sda_t_out [get_bd_pins sw2shield_sda_t_out] [get_bd_pins arduino_io_switch_0/sw2shield_sda_t_out]
  connect_bd_net -net arduino_io_switch_0_sw2shield_tri_out_a5_a0 [get_bd_pins sw2shield_tri_out_a5_a0] [get_bd_pins arduino_io_switch_0/sw2shield_tri_out_a5_a0]
  connect_bd_net -net arduino_io_switch_0_sw2shield_tri_out_d13_d2 [get_bd_pins sw2shield_tri_out_d13_d2] [get_bd_pins arduino_io_switch_0/sw2shield_tri_out_d13_d2]
  connect_bd_net -net arduino_io_switch_0_sw2shield_tri_out_d1_d0 [get_bd_pins sw2shield_tri_out_d1_d0] [get_bd_pins arduino_io_switch_0/sw2shield_tri_out_d1_d0]
  connect_bd_net -net arduino_io_switch_0_timer_i_in [get_bd_pins arduino_io_switch_0/timer_i_in] [get_bd_pins mb3_timers_subsystem/capture_i]
  connect_bd_net -net dff_en_reset_0_q [get_bd_pins mb3_intr_req] [get_bd_pins dff_en_reset_0/q]
  connect_bd_net -net logic_0_6bits_dout [get_bd_pins arduino_io_switch_0/pwm_t_in] [get_bd_pins logic_0_6bits/dout]
  connect_bd_net -net logic_0_dout [get_bd_pins arduino_io_switch_0/tx_t_in_d1] [get_bd_pins logic_0/dout]
  connect_bd_net -net logic_1_dout [get_bd_pins ext_reset_in] [get_bd_pins rst_clk_wiz_1_100M/ext_reset_in]
  connect_bd_net -net logic_1_dout1 [get_bd_pins dff_en_reset_0/d] [get_bd_pins logic_1/dout]
  connect_bd_net -net mb3_concat_dout [get_bd_pins mb3_concat/dout] [get_bd_pins mb3_intc/intr]
  connect_bd_net -net mb3_gpio_subsystem_Dout [get_bd_pins arduino_io_switch_0/pl2sw_data_o_d13_d2] [get_bd_pins mb3_gpio_subsystem/data_d13_d2]
  connect_bd_net -net mb3_gpio_subsystem_Dout1 [get_bd_pins arduino_io_switch_0/pl2sw_tri_o_d13_d2] [get_bd_pins mb3_gpio_subsystem/tri_d13_d2]
  connect_bd_net -net mb3_gpio_subsystem_Dout2 [get_bd_pins arduino_io_switch_0/pl2sw_data_o_d1_d0] [get_bd_pins mb3_gpio_subsystem/data_d1_d0]
  connect_bd_net -net mb3_gpio_subsystem_Dout3 [get_bd_pins arduino_io_switch_0/pl2sw_tri_o_d1_d0] [get_bd_pins mb3_gpio_subsystem/tri_d1_d0]
  connect_bd_net -net mb3_gpio_subsystem_gpio2_io_o [get_bd_pins arduino_io_switch_0/pl2sw_data_o_a5_a0] [get_bd_pins mb3_gpio_subsystem/data_a5_a0]
  connect_bd_net -net mb3_gpio_subsystem_gpio2_io_t [get_bd_pins arduino_io_switch_0/pl2sw_tri_o_a5_a0] [get_bd_pins mb3_gpio_subsystem/tri_a5_a0]
  connect_bd_net -net mb3_iic_subsystem_iic2intc_irpt [get_bd_pins mb3_concat/In4] [get_bd_pins mb3_iic_subsystem/iic2intc_irpt]
  connect_bd_net -net mb3_intr_ack_1 [get_bd_pins mb3_intr_ack] [get_bd_pins dff_en_reset_0/reset]
  connect_bd_net -net mb3_intr_gpio_io_o [get_bd_pins dff_en_reset_0/en] [get_bd_pins mb3_intr/gpio_io_o]
  connect_bd_net -net mb3_spi_subsystem_ip2intc_irpt [get_bd_pins mb3_concat/In5] [get_bd_pins mb3_spi_subsystem/ip2intc_irpt]
  connect_bd_net -net mb3_timer_generate_dout [get_bd_pins arduino_io_switch_0/timer_o_in] [get_bd_pins mb3_timers_subsystem/generate_o]
  connect_bd_net -net mb3_timer_pwm_dout [get_bd_pins arduino_io_switch_0/pwm_o_in] [get_bd_pins mb3_timers_subsystem/pwm_o]
  connect_bd_net -net mb3_timers_subsystem_dout2 [get_bd_pins mb3_concat/In3] [get_bd_pins mb3_timers_subsystem/mb3_timer_interrupts]
  connect_bd_net -net mb3_uartlite_d1_d0_interrupt [get_bd_pins mb3_concat/In6] [get_bd_pins mb3_uartlite_d1_d0/interrupt]
  connect_bd_net -net mb_1_reset_Dout [get_bd_pins aux_reset_in] [get_bd_pins rst_clk_wiz_1_100M/aux_reset_in]
  connect_bd_net -net mdm_1_debug_sys_rst [get_bd_pins mb_debug_sys_rst] [get_bd_pins rst_clk_wiz_1_100M/mb_debug_sys_rst]
  connect_bd_net -net processing_system7_0_FCLK_CLK0 [get_bd_pins clk] [get_bd_pins arduino_io_switch_0/s_axi_aclk] [get_bd_pins dff_en_reset_0/clk] [get_bd_pins mb/Clk] [get_bd_pins mb3_gpio_subsystem/s_axi_aclk] [get_bd_pins mb3_iic_subsystem/s_axi_aclk] [get_bd_pins mb3_intc/s_axi_aclk] [get_bd_pins mb3_intr/s_axi_aclk] [get_bd_pins mb3_lmb/LMB_Clk] [get_bd_pins mb3_spi_subsystem/s_axi_aclk] [get_bd_pins mb3_timers_subsystem/s_axi_aclk] [get_bd_pins mb3_uartlite_d1_d0/s_axi_aclk] [get_bd_pins mb3_xadc/s_axi_aclk] [get_bd_pins microblaze_0_axi_periph/ACLK] [get_bd_pins microblaze_0_axi_periph/M00_ACLK] [get_bd_pins microblaze_0_axi_periph/M01_ACLK] [get_bd_pins microblaze_0_axi_periph/M02_ACLK] [get_bd_pins microblaze_0_axi_periph/M03_ACLK] [get_bd_pins microblaze_0_axi_periph/M04_ACLK] [get_bd_pins microblaze_0_axi_periph/M05_ACLK] [get_bd_pins microblaze_0_axi_periph/M06_ACLK] [get_bd_pins microblaze_0_axi_periph/M07_ACLK] [get_bd_pins microblaze_0_axi_periph/M08_ACLK] [get_bd_pins microblaze_0_axi_periph/M09_ACLK] [get_bd_pins microblaze_0_axi_periph/M10_ACLK] [get_bd_pins microblaze_0_axi_periph/M11_ACLK] [get_bd_pins microblaze_0_axi_periph/M12_ACLK] [get_bd_pins microblaze_0_axi_periph/M13_ACLK] [get_bd_pins microblaze_0_axi_periph/M14_ACLK] [get_bd_pins microblaze_0_axi_periph/M15_ACLK] [get_bd_pins microblaze_0_axi_periph/M16_ACLK] [get_bd_pins microblaze_0_axi_periph/M17_ACLK] [get_bd_pins microblaze_0_axi_periph/M18_ACLK] [get_bd_pins microblaze_0_axi_periph/S00_ACLK] [get_bd_pins rst_clk_wiz_1_100M/slowest_sync_clk]
  connect_bd_net -net rst_clk_wiz_1_100M_bus_struct_reset [get_bd_pins mb3_lmb/SYS_Rst] [get_bd_pins rst_clk_wiz_1_100M/bus_struct_reset]
  connect_bd_net -net rst_clk_wiz_1_100M_interconnect_aresetn [get_bd_pins microblaze_0_axi_periph/ARESETN] [get_bd_pins rst_clk_wiz_1_100M/interconnect_aresetn]
  connect_bd_net -net rst_clk_wiz_1_100M_mb_reset [get_bd_pins mb/Reset] [get_bd_pins rst_clk_wiz_1_100M/mb_reset]
  connect_bd_net -net rst_clk_wiz_1_100M_peripheral_aresetn [get_bd_pins peripheral_aresetn] [get_bd_pins arduino_io_switch_0/s_axi_aresetn] [get_bd_pins mb3_gpio_subsystem/s_axi_aresetn] [get_bd_pins mb3_iic_subsystem/s_axi_aresetn1] [get_bd_pins mb3_intc/s_axi_aresetn] [get_bd_pins mb3_spi_subsystem/s_axi_aresetn] [get_bd_pins mb3_timers_subsystem/s_axi_aresetn] [get_bd_pins microblaze_0_axi_periph/M00_ARESETN] [get_bd_pins microblaze_0_axi_periph/M01_ARESETN] [get_bd_pins microblaze_0_axi_periph/M02_ARESETN] [get_bd_pins microblaze_0_axi_periph/M03_ARESETN] [get_bd_pins microblaze_0_axi_periph/M04_ARESETN] [get_bd_pins microblaze_0_axi_periph/M05_ARESETN] [get_bd_pins microblaze_0_axi_periph/M06_ARESETN] [get_bd_pins microblaze_0_axi_periph/M07_ARESETN] [get_bd_pins microblaze_0_axi_periph/M10_ARESETN] [get_bd_pins microblaze_0_axi_periph/M11_ARESETN] [get_bd_pins microblaze_0_axi_periph/M12_ARESETN] [get_bd_pins microblaze_0_axi_periph/M13_ARESETN] [get_bd_pins microblaze_0_axi_periph/M15_ARESETN] [get_bd_pins microblaze_0_axi_periph/M17_ARESETN] [get_bd_pins microblaze_0_axi_periph/M18_ARESETN] [get_bd_pins microblaze_0_axi_periph/S00_ARESETN] [get_bd_pins rst_clk_wiz_1_100M/peripheral_aresetn]
  connect_bd_net -net s_axi_aresetn_1 [get_bd_pins s_axi_aresetn] [get_bd_pins mb3_iic_subsystem/s_axi_aresetn] [get_bd_pins mb3_intr/s_axi_aresetn] [get_bd_pins mb3_spi_subsystem/s_axi_aresetn1] [get_bd_pins mb3_timers_subsystem/s_axi_aresetn1] [get_bd_pins mb3_uartlite_d1_d0/s_axi_aresetn] [get_bd_pins mb3_xadc/s_axi_aresetn] [get_bd_pins microblaze_0_axi_periph/M08_ARESETN] [get_bd_pins microblaze_0_axi_periph/M09_ARESETN] [get_bd_pins microblaze_0_axi_periph/M14_ARESETN] [get_bd_pins microblaze_0_axi_periph/M16_ARESETN]
  connect_bd_net -net shield2sw_data_in_a5_a0_1 [get_bd_pins shield2sw_data_in_a5_a0] [get_bd_pins arduino_io_switch_0/shield2sw_data_in_a5_a0]
  connect_bd_net -net shield2sw_data_in_d13_d2_1 [get_bd_pins shield2sw_data_in_d13_d2] [get_bd_pins arduino_io_switch_0/shield2sw_data_in_d13_d2]
  connect_bd_net -net shield2sw_data_in_d1_d0_1 [get_bd_pins shield2sw_data_in_d1_d0] [get_bd_pins arduino_io_switch_0/shield2sw_data_in_d1_d0]
  connect_bd_net -net shield2sw_scl_i_in_1 [get_bd_pins shield2sw_scl_i_in] [get_bd_pins arduino_io_switch_0/shield2sw_scl_i_in]
  connect_bd_net -net shield2sw_sda_i_in_1 [get_bd_pins shield2sw_sda_i_in] [get_bd_pins arduino_io_switch_0/shield2sw_sda_i_in]

  # Restore current instance
  current_bd_instance $oldCurInst
}

# Hierarchical cell: iop2
proc create_hier_cell_iop2 { parentCell nameHier } {

  variable script_folder

  if { $parentCell eq "" || $nameHier eq "" } {
     catch {common::send_msg_id "BD_TCL-102" "ERROR" create_hier_cell_iop2() - Empty argument(s)!"}
     return
  }

  # Get object for parentCell
  set parentObj [get_bd_cells $parentCell]
  if { $parentObj == "" } {
     catch {common::send_msg_id "BD_TCL-100" "ERROR" "Unable to find parent cell <$parentCell>!"}
     return
  }

  # Make sure parentObj is hier blk
  set parentType [get_property TYPE $parentObj]
  if { $parentType ne "hier" } {
     catch {common::send_msg_id "BD_TCL-101" "ERROR" "Parent <$parentObj> has TYPE = <$parentType>. Expected to be <hier>."}
     return
  }

  # Save current instance; Restore later
  set oldCurInst [current_bd_instance .]

  # Set parent object as current
  current_bd_instance $parentObj

  # Create cell and set as current instance
  set hier_obj [create_bd_cell -type hier $nameHier]
  current_bd_instance $hier_obj

  # Create interface pins
  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:bram_rtl:1.0 BRAM_PORTB
  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:mbdebug_rtl:3.0 DEBUG
  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 M07_AXI

  # Create pins
  create_bd_pin -dir I -from 0 -to 0 -type rst aux_reset_in
  create_bd_pin -dir I -type clk clk
  create_bd_pin -dir I -from 0 -to 0 -type rst ext_reset_in
  create_bd_pin -dir I -from 0 -to 0 iop2_intr_ack
  create_bd_pin -dir O iop2_intr_req
  create_bd_pin -dir I -type rst mb_debug_sys_rst
  create_bd_pin -dir O -from 0 -to 0 -type rst peripheral_aresetn
  create_bd_pin -dir I -from 7 -to 0 pmod2sw_data_in
  create_bd_pin -dir I -from 0 -to 0 -type rst s_axi_aresetn
  create_bd_pin -dir O -from 7 -to 0 sw2pmod_data_out
  create_bd_pin -dir O -from 7 -to 0 sw2pmod_tri_out

  # Create instance: dff_en_reset_0, and set properties
  set dff_en_reset_0 [ create_bd_cell -type ip -vlnv xilinx.com:XUP:dff_en_reset:1.0 dff_en_reset_0 ]

  # Create instance: logic_0, and set properties
  set logic_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant:1.1 logic_0 ]
  set_property -dict [ list \
CONFIG.CONST_VAL {0} \
 ] $logic_0

  # Create instance: logic_1, and set properties
  set logic_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant:1.1 logic_1 ]

  # Create instance: mb, and set properties
  set mb [ create_bd_cell -type ip -vlnv xilinx.com:ip:microblaze:9.6 mb ]
  set_property -dict [ list \
CONFIG.C_DEBUG_ENABLED {1} \
CONFIG.C_D_AXI {1} \
CONFIG.C_D_LMB {1} \
CONFIG.C_I_LMB {1} \
 ] $mb

  # Create instance: mb2_concat, and set properties
  set mb2_concat [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconcat:2.1 mb2_concat ]
  set_property -dict [ list \
CONFIG.NUM_PORTS {3} \
 ] $mb2_concat

  # Create instance: mb2_gpio, and set properties
  set mb2_gpio [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_gpio:2.0 mb2_gpio ]
  set_property -dict [ list \
CONFIG.C_ALL_OUTPUTS_2 {1} \
CONFIG.C_GPIO2_WIDTH {1} \
CONFIG.C_GPIO_WIDTH {8} \
CONFIG.C_IS_DUAL {1} \
 ] $mb2_gpio

  # Create instance: mb2_iic, and set properties
  set mb2_iic [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_iic:2.0 mb2_iic ]

  # Create instance: mb2_intc, and set properties
  set mb2_intc [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_intc:4.1 mb2_intc ]

  # Create instance: mb2_intr, and set properties
  set mb2_intr [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_gpio:2.0 mb2_intr ]
  set_property -dict [ list \
CONFIG.C_ALL_OUTPUTS {1} \
CONFIG.C_GPIO_WIDTH {1} \
 ] $mb2_intr

  # Create instance: mb2_lmb
  create_hier_cell_mb2_lmb $hier_obj mb2_lmb

  # Create instance: mb2_pmod_io_switch, and set properties
  set mb2_pmod_io_switch [ create_bd_cell -type ip -vlnv xilinx.com:user:pmod_io_switch:1.0 mb2_pmod_io_switch ]

  # Create instance: mb2_spi, and set properties
  set mb2_spi [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_quad_spi:3.2 mb2_spi ]
  set_property -dict [ list \
CONFIG.C_USE_STARTUP {0} \
 ] $mb2_spi

  # Create instance: mb2_timer, and set properties
  set mb2_timer [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_timer:2.0 mb2_timer ]

  # Create instance: microblaze_0_axi_periph, and set properties
  set microblaze_0_axi_periph [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_interconnect:2.1 microblaze_0_axi_periph ]
  set_property -dict [ list \
CONFIG.NUM_MI {8} \
 ] $microblaze_0_axi_periph

  # Create instance: rst_clk_wiz_1_100M, and set properties
  set rst_clk_wiz_1_100M [ create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset:5.0 rst_clk_wiz_1_100M ]
  set_property -dict [ list \
CONFIG.C_AUX_RESET_HIGH {1} \
 ] $rst_clk_wiz_1_100M

  # Create interface connections
  connect_bd_intf_net -intf_net Conn1 [get_bd_intf_pins M07_AXI] [get_bd_intf_pins microblaze_0_axi_periph/M07_AXI]
  connect_bd_intf_net -intf_net mb2_intc_interrupt [get_bd_intf_pins mb/INTERRUPT] [get_bd_intf_pins mb2_intc/interrupt]
  connect_bd_intf_net -intf_net mb_bram_ctrl_1_BRAM_PORTA [get_bd_intf_pins BRAM_PORTB] [get_bd_intf_pins mb2_lmb/BRAM_PORTB]
  connect_bd_intf_net -intf_net microblaze_0_M_AXI_DP [get_bd_intf_pins mb/M_AXI_DP] [get_bd_intf_pins microblaze_0_axi_periph/S00_AXI]
  connect_bd_intf_net -intf_net microblaze_0_axi_periph_M00_AXI [get_bd_intf_pins mb2_spi/AXI_LITE] [get_bd_intf_pins microblaze_0_axi_periph/M00_AXI]
  connect_bd_intf_net -intf_net microblaze_0_axi_periph_M01_AXI [get_bd_intf_pins mb2_iic/S_AXI] [get_bd_intf_pins microblaze_0_axi_periph/M01_AXI]
  connect_bd_intf_net -intf_net microblaze_0_axi_periph_M02_AXI [get_bd_intf_pins mb2_pmod_io_switch/S00_AXI] [get_bd_intf_pins microblaze_0_axi_periph/M02_AXI]
  connect_bd_intf_net -intf_net microblaze_0_axi_periph_M03_AXI [get_bd_intf_pins mb2_gpio/S_AXI] [get_bd_intf_pins microblaze_0_axi_periph/M03_AXI]
  connect_bd_intf_net -intf_net microblaze_0_axi_periph_M04_AXI [get_bd_intf_pins mb2_timer/S_AXI] [get_bd_intf_pins microblaze_0_axi_periph/M04_AXI]
  connect_bd_intf_net -intf_net microblaze_0_axi_periph_M05_AXI [get_bd_intf_pins mb2_intc/s_axi] [get_bd_intf_pins microblaze_0_axi_periph/M05_AXI]
  connect_bd_intf_net -intf_net microblaze_0_axi_periph_M06_AXI [get_bd_intf_pins mb2_intr/S_AXI] [get_bd_intf_pins microblaze_0_axi_periph/M06_AXI]
  connect_bd_intf_net -intf_net microblaze_0_debug [get_bd_intf_pins DEBUG] [get_bd_intf_pins mb/DEBUG]
  connect_bd_intf_net -intf_net microblaze_0_dlmb_1 [get_bd_intf_pins mb/DLMB] [get_bd_intf_pins mb2_lmb/DLMB]
  connect_bd_intf_net -intf_net microblaze_0_ilmb_1 [get_bd_intf_pins mb/ILMB] [get_bd_intf_pins mb2_lmb/ILMB]

  # Create port connections
  connect_bd_net -net dff_en_reset_0_q [get_bd_pins iop2_intr_req] [get_bd_pins dff_en_reset_0/q]
  connect_bd_net -net iop2_intr_ack_1 [get_bd_pins iop2_intr_ack] [get_bd_pins dff_en_reset_0/reset]
  connect_bd_net -net iop2_intr_gpio_io_o [get_bd_pins dff_en_reset_0/en] [get_bd_pins mb2_intr/gpio_io_o]
  connect_bd_net -net logic_0_dout [get_bd_pins logic_0/dout] [get_bd_pins mb2_pmod_io_switch/pwm_t_in]
  connect_bd_net -net logic_1_dout [get_bd_pins ext_reset_in] [get_bd_pins rst_clk_wiz_1_100M/ext_reset_in]
  connect_bd_net -net logic_1_dout1 [get_bd_pins dff_en_reset_0/d] [get_bd_pins logic_1/dout]
  connect_bd_net -net mb2_concat_dout [get_bd_pins mb2_concat/dout] [get_bd_pins mb2_intc/intr]
  connect_bd_net -net mb2_gpio_gpio2_io_o [get_bd_pins mb2_gpio/gpio2_io_o] [get_bd_pins mb2_pmod_io_switch/gen0_t_in]
  connect_bd_net -net mb2_gpio_gpio_io_o [get_bd_pins mb2_gpio/gpio_io_o] [get_bd_pins mb2_pmod_io_switch/pl2sw_data_o]
  connect_bd_net -net mb2_gpio_gpio_io_t [get_bd_pins mb2_gpio/gpio_io_t] [get_bd_pins mb2_pmod_io_switch/pl2sw_tri_o]
  connect_bd_net -net mb2_iic_iic2intc_irpt [get_bd_pins mb2_concat/In0] [get_bd_pins mb2_iic/iic2intc_irpt]
  connect_bd_net -net mb2_iic_scl_o [get_bd_pins mb2_iic/scl_o] [get_bd_pins mb2_pmod_io_switch/scl_o_in]
  connect_bd_net -net mb2_iic_scl_t [get_bd_pins mb2_iic/scl_t] [get_bd_pins mb2_pmod_io_switch/scl_t_in]
  connect_bd_net -net mb2_iic_sda_o [get_bd_pins mb2_iic/sda_o] [get_bd_pins mb2_pmod_io_switch/sda_o_in]
  connect_bd_net -net mb2_iic_sda_t [get_bd_pins mb2_iic/sda_t] [get_bd_pins mb2_pmod_io_switch/sda_t_in]
  connect_bd_net -net mb2_pmod_io_switch_cap0_i_in [get_bd_pins mb2_pmod_io_switch/cap0_i_in] [get_bd_pins mb2_timer/capturetrig0]
  connect_bd_net -net mb2_spi_io0_o [get_bd_pins mb2_pmod_io_switch/mosi_o_in] [get_bd_pins mb2_spi/io0_o]
  connect_bd_net -net mb2_spi_io0_t [get_bd_pins mb2_pmod_io_switch/mosi_t_in] [get_bd_pins mb2_spi/io0_t]
  connect_bd_net -net mb2_spi_io1_o [get_bd_pins mb2_pmod_io_switch/miso_o_in] [get_bd_pins mb2_spi/io1_o]
  connect_bd_net -net mb2_spi_io1_t [get_bd_pins mb2_pmod_io_switch/miso_t_in] [get_bd_pins mb2_spi/io1_t]
  connect_bd_net -net mb2_spi_ip2intc_irpt [get_bd_pins mb2_concat/In1] [get_bd_pins mb2_spi/ip2intc_irpt]
  connect_bd_net -net mb2_spi_sck_o [get_bd_pins mb2_pmod_io_switch/spick_o_in] [get_bd_pins mb2_spi/sck_o]
  connect_bd_net -net mb2_spi_sck_t [get_bd_pins mb2_pmod_io_switch/spick_t_in] [get_bd_pins mb2_spi/sck_t]
  connect_bd_net -net mb2_spi_ss_o [get_bd_pins mb2_pmod_io_switch/ss_o_in] [get_bd_pins mb2_spi/ss_o]
  connect_bd_net -net mb2_spi_ss_t [get_bd_pins mb2_pmod_io_switch/ss_t_in] [get_bd_pins mb2_spi/ss_t]
  connect_bd_net -net mb2_timer_generateout0 [get_bd_pins mb2_pmod_io_switch/gen0_o_in] [get_bd_pins mb2_timer/generateout0]
  connect_bd_net -net mb2_timer_interrupt [get_bd_pins mb2_concat/In2] [get_bd_pins mb2_timer/interrupt]
  connect_bd_net -net mb2_timer_pwm0 [get_bd_pins mb2_pmod_io_switch/pwm_o_in] [get_bd_pins mb2_timer/pwm0]
  connect_bd_net -net mb_1_reset_Dout [get_bd_pins aux_reset_in] [get_bd_pins rst_clk_wiz_1_100M/aux_reset_in]
  connect_bd_net -net mdm_1_debug_sys_rst [get_bd_pins mb_debug_sys_rst] [get_bd_pins rst_clk_wiz_1_100M/mb_debug_sys_rst]
  connect_bd_net -net pmod2sw_data_in_1 [get_bd_pins pmod2sw_data_in] [get_bd_pins mb2_pmod_io_switch/pmod2sw_data_in]
  connect_bd_net -net pmod_io_switch_0_miso_i_in [get_bd_pins mb2_pmod_io_switch/miso_i_in] [get_bd_pins mb2_spi/io1_i]
  connect_bd_net -net pmod_io_switch_0_mosi_i_in [get_bd_pins mb2_pmod_io_switch/mosi_i_in] [get_bd_pins mb2_spi/io0_i]
  connect_bd_net -net pmod_io_switch_0_scl_i_in [get_bd_pins mb2_iic/scl_i] [get_bd_pins mb2_pmod_io_switch/scl_i_in]
  connect_bd_net -net pmod_io_switch_0_sda_i_in [get_bd_pins mb2_iic/sda_i] [get_bd_pins mb2_pmod_io_switch/sda_i_in]
  connect_bd_net -net pmod_io_switch_0_spick_i_in [get_bd_pins mb2_pmod_io_switch/spick_i_in] [get_bd_pins mb2_spi/sck_i]
  connect_bd_net -net pmod_io_switch_0_ss_i_in [get_bd_pins mb2_pmod_io_switch/ss_i_in] [get_bd_pins mb2_spi/ss_i]
  connect_bd_net -net pmod_io_switch_0_sw2pl_data_in [get_bd_pins mb2_gpio/gpio_io_i] [get_bd_pins mb2_pmod_io_switch/sw2pl_data_in]
  connect_bd_net -net pmod_io_switch_0_sw2pmod_data_out [get_bd_pins sw2pmod_data_out] [get_bd_pins mb2_pmod_io_switch/sw2pmod_data_out]
  connect_bd_net -net pmod_io_switch_0_sw2pmod_tri_out [get_bd_pins sw2pmod_tri_out] [get_bd_pins mb2_pmod_io_switch/sw2pmod_tri_out]
  connect_bd_net -net processing_system7_0_FCLK_CLK0 [get_bd_pins clk] [get_bd_pins dff_en_reset_0/clk] [get_bd_pins mb/Clk] [get_bd_pins mb2_gpio/s_axi_aclk] [get_bd_pins mb2_iic/s_axi_aclk] [get_bd_pins mb2_intc/s_axi_aclk] [get_bd_pins mb2_intr/s_axi_aclk] [get_bd_pins mb2_lmb/LMB_Clk] [get_bd_pins mb2_pmod_io_switch/s00_axi_aclk] [get_bd_pins mb2_spi/ext_spi_clk] [get_bd_pins mb2_spi/s_axi_aclk] [get_bd_pins mb2_timer/s_axi_aclk] [get_bd_pins microblaze_0_axi_periph/ACLK] [get_bd_pins microblaze_0_axi_periph/M00_ACLK] [get_bd_pins microblaze_0_axi_periph/M01_ACLK] [get_bd_pins microblaze_0_axi_periph/M02_ACLK] [get_bd_pins microblaze_0_axi_periph/M03_ACLK] [get_bd_pins microblaze_0_axi_periph/M04_ACLK] [get_bd_pins microblaze_0_axi_periph/M05_ACLK] [get_bd_pins microblaze_0_axi_periph/M06_ACLK] [get_bd_pins microblaze_0_axi_periph/M07_ACLK] [get_bd_pins microblaze_0_axi_periph/S00_ACLK] [get_bd_pins rst_clk_wiz_1_100M/slowest_sync_clk]
  connect_bd_net -net rst_clk_wiz_1_100M_bus_struct_reset [get_bd_pins mb2_lmb/SYS_Rst] [get_bd_pins rst_clk_wiz_1_100M/bus_struct_reset]
  connect_bd_net -net rst_clk_wiz_1_100M_interconnect_aresetn [get_bd_pins microblaze_0_axi_periph/ARESETN] [get_bd_pins rst_clk_wiz_1_100M/interconnect_aresetn]
  connect_bd_net -net rst_clk_wiz_1_100M_mb_reset [get_bd_pins mb/Reset] [get_bd_pins rst_clk_wiz_1_100M/mb_reset]
  connect_bd_net -net rst_clk_wiz_1_100M_peripheral_aresetn [get_bd_pins peripheral_aresetn] [get_bd_pins mb2_gpio/s_axi_aresetn] [get_bd_pins mb2_iic/s_axi_aresetn] [get_bd_pins mb2_intc/s_axi_aresetn] [get_bd_pins mb2_pmod_io_switch/s00_axi_aresetn] [get_bd_pins mb2_spi/s_axi_aresetn] [get_bd_pins mb2_timer/s_axi_aresetn] [get_bd_pins microblaze_0_axi_periph/M00_ARESETN] [get_bd_pins microblaze_0_axi_periph/M01_ARESETN] [get_bd_pins microblaze_0_axi_periph/M02_ARESETN] [get_bd_pins microblaze_0_axi_periph/M03_ARESETN] [get_bd_pins microblaze_0_axi_periph/M04_ARESETN] [get_bd_pins microblaze_0_axi_periph/M05_ARESETN] [get_bd_pins microblaze_0_axi_periph/M06_ARESETN] [get_bd_pins microblaze_0_axi_periph/M07_ARESETN] [get_bd_pins microblaze_0_axi_periph/S00_ARESETN] [get_bd_pins rst_clk_wiz_1_100M/peripheral_aresetn]
  connect_bd_net -net s_axi_aresetn_1 [get_bd_pins s_axi_aresetn] [get_bd_pins mb2_intr/s_axi_aresetn]

  # Restore current instance
  current_bd_instance $oldCurInst
}

# Hierarchical cell: iop1
proc create_hier_cell_iop1 { parentCell nameHier } {

  variable script_folder

  if { $parentCell eq "" || $nameHier eq "" } {
     catch {common::send_msg_id "BD_TCL-102" "ERROR" create_hier_cell_iop1() - Empty argument(s)!"}
     return
  }

  # Get object for parentCell
  set parentObj [get_bd_cells $parentCell]
  if { $parentObj == "" } {
     catch {common::send_msg_id "BD_TCL-100" "ERROR" "Unable to find parent cell <$parentCell>!"}
     return
  }

  # Make sure parentObj is hier blk
  set parentType [get_property TYPE $parentObj]
  if { $parentType ne "hier" } {
     catch {common::send_msg_id "BD_TCL-101" "ERROR" "Parent <$parentObj> has TYPE = <$parentType>. Expected to be <hier>."}
     return
  }

  # Save current instance; Restore later
  set oldCurInst [current_bd_instance .]

  # Set parent object as current
  current_bd_instance $parentObj

  # Create cell and set as current instance
  set hier_obj [create_bd_cell -type hier $nameHier]
  current_bd_instance $hier_obj

  # Create interface pins
  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:bram_rtl:1.0 BRAM_PORTB
  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:mbdebug_rtl:3.0 DEBUG
  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 M07_AXI

  # Create pins
  create_bd_pin -dir I -from 0 -to 0 -type rst aux_reset_in
  create_bd_pin -dir I -type clk clk
  create_bd_pin -dir I -from 0 -to 0 -type rst ext_reset_in
  create_bd_pin -dir I -from 0 -to 0 iop1_intr_ack
  create_bd_pin -dir O iop1_intr_req
  create_bd_pin -dir I -type rst mb_debug_sys_rst
  create_bd_pin -dir O -from 0 -to 0 -type rst peripheral_aresetn
  create_bd_pin -dir I -from 7 -to 0 pmod2sw_data_in
  create_bd_pin -dir I -from 0 -to 0 -type rst s_axi_aresetn
  create_bd_pin -dir O -from 7 -to 0 sw2pmod_data_out
  create_bd_pin -dir O -from 7 -to 0 sw2pmod_tri_out

  # Create instance: dff_en_reset_0, and set properties
  set dff_en_reset_0 [ create_bd_cell -type ip -vlnv xilinx.com:XUP:dff_en_reset:1.0 dff_en_reset_0 ]

  # Create instance: logic_0, and set properties
  set logic_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant:1.1 logic_0 ]
  set_property -dict [ list \
CONFIG.CONST_VAL {0} \
 ] $logic_0

  # Create instance: logic_1, and set properties
  set logic_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant:1.1 logic_1 ]

  # Create instance: mb, and set properties
  set mb [ create_bd_cell -type ip -vlnv xilinx.com:ip:microblaze:9.6 mb ]
  set_property -dict [ list \
CONFIG.C_DEBUG_ENABLED {1} \
CONFIG.C_D_AXI {1} \
CONFIG.C_D_LMB {1} \
CONFIG.C_I_LMB {1} \
 ] $mb

  # Create instance: mb1_gpio, and set properties
  set mb1_gpio [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_gpio:2.0 mb1_gpio ]
  set_property -dict [ list \
CONFIG.C_ALL_OUTPUTS_2 {1} \
CONFIG.C_GPIO2_WIDTH {1} \
CONFIG.C_GPIO_WIDTH {8} \
CONFIG.C_IS_DUAL {1} \
 ] $mb1_gpio

  # Create instance: mb1_iic, and set properties
  set mb1_iic [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_iic:2.0 mb1_iic ]

  # Create instance: mb1_intc, and set properties
  set mb1_intc [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_intc:4.1 mb1_intc ]

  # Create instance: mb1_interrupt_concat, and set properties
  set mb1_interrupt_concat [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconcat:2.1 mb1_interrupt_concat ]
  set_property -dict [ list \
CONFIG.NUM_PORTS {3} \
 ] $mb1_interrupt_concat

  # Create instance: mb1_intr, and set properties
  set mb1_intr [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_gpio:2.0 mb1_intr ]
  set_property -dict [ list \
CONFIG.C_ALL_OUTPUTS {1} \
CONFIG.C_GPIO_WIDTH {1} \
 ] $mb1_intr

  # Create instance: mb1_lmb
  create_hier_cell_mb1_lmb $hier_obj mb1_lmb

  # Create instance: mb1_pmod_io_switch, and set properties
  set mb1_pmod_io_switch [ create_bd_cell -type ip -vlnv xilinx.com:user:pmod_io_switch:1.0 mb1_pmod_io_switch ]

  # Create instance: mb1_spi, and set properties
  set mb1_spi [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_quad_spi:3.2 mb1_spi ]
  set_property -dict [ list \
CONFIG.C_USE_STARTUP {0} \
 ] $mb1_spi

  # Create instance: mb1_timer, and set properties
  set mb1_timer [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_timer:2.0 mb1_timer ]

  # Create instance: microblaze_0_axi_periph, and set properties
  set microblaze_0_axi_periph [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_interconnect:2.1 microblaze_0_axi_periph ]
  set_property -dict [ list \
CONFIG.NUM_MI {8} \
 ] $microblaze_0_axi_periph

  # Create instance: rst_clk_wiz_1_100M, and set properties
  set rst_clk_wiz_1_100M [ create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset:5.0 rst_clk_wiz_1_100M ]
  set_property -dict [ list \
CONFIG.C_AUX_RESET_HIGH {1} \
 ] $rst_clk_wiz_1_100M

  # Create interface connections
  connect_bd_intf_net -intf_net Conn1 [get_bd_intf_pins M07_AXI] [get_bd_intf_pins microblaze_0_axi_periph/M07_AXI]
  connect_bd_intf_net -intf_net mb1_intc_interrupt [get_bd_intf_pins mb/INTERRUPT] [get_bd_intf_pins mb1_intc/interrupt]
  connect_bd_intf_net -intf_net mb_bram_ctrl_1_BRAM_PORTA [get_bd_intf_pins BRAM_PORTB] [get_bd_intf_pins mb1_lmb/BRAM_PORTB]
  connect_bd_intf_net -intf_net microblaze_0_M_AXI_DP [get_bd_intf_pins mb/M_AXI_DP] [get_bd_intf_pins microblaze_0_axi_periph/S00_AXI]
  connect_bd_intf_net -intf_net microblaze_0_axi_periph_M00_AXI [get_bd_intf_pins mb1_spi/AXI_LITE] [get_bd_intf_pins microblaze_0_axi_periph/M00_AXI]
  connect_bd_intf_net -intf_net microblaze_0_axi_periph_M01_AXI [get_bd_intf_pins mb1_iic/S_AXI] [get_bd_intf_pins microblaze_0_axi_periph/M01_AXI]
  connect_bd_intf_net -intf_net microblaze_0_axi_periph_M02_AXI [get_bd_intf_pins mb1_pmod_io_switch/S00_AXI] [get_bd_intf_pins microblaze_0_axi_periph/M02_AXI]
  connect_bd_intf_net -intf_net microblaze_0_axi_periph_M03_AXI [get_bd_intf_pins mb1_gpio/S_AXI] [get_bd_intf_pins microblaze_0_axi_periph/M03_AXI]
  connect_bd_intf_net -intf_net microblaze_0_axi_periph_M04_AXI [get_bd_intf_pins mb1_timer/S_AXI] [get_bd_intf_pins microblaze_0_axi_periph/M04_AXI]
  connect_bd_intf_net -intf_net microblaze_0_axi_periph_M05_AXI [get_bd_intf_pins mb1_intc/s_axi] [get_bd_intf_pins microblaze_0_axi_periph/M05_AXI]
  connect_bd_intf_net -intf_net microblaze_0_axi_periph_M06_AXI [get_bd_intf_pins mb1_intr/S_AXI] [get_bd_intf_pins microblaze_0_axi_periph/M06_AXI]
  connect_bd_intf_net -intf_net microblaze_0_debug [get_bd_intf_pins DEBUG] [get_bd_intf_pins mb/DEBUG]
  connect_bd_intf_net -intf_net microblaze_0_dlmb_1 [get_bd_intf_pins mb/DLMB] [get_bd_intf_pins mb1_lmb/DLMB]
  connect_bd_intf_net -intf_net microblaze_0_ilmb_1 [get_bd_intf_pins mb/ILMB] [get_bd_intf_pins mb1_lmb/ILMB]

  # Create port connections
  connect_bd_net -net dff_en_reset_0_q [get_bd_pins iop1_intr_req] [get_bd_pins dff_en_reset_0/q]
  connect_bd_net -net iop1_intr_ack_1 [get_bd_pins iop1_intr_ack] [get_bd_pins dff_en_reset_0/reset]
  connect_bd_net -net iop1_intr_gpio_io_o [get_bd_pins dff_en_reset_0/en] [get_bd_pins mb1_intr/gpio_io_o]
  connect_bd_net -net logic_0_dout [get_bd_pins logic_0/dout] [get_bd_pins mb1_pmod_io_switch/pwm_t_in]
  connect_bd_net -net logic_1_dout [get_bd_pins ext_reset_in] [get_bd_pins rst_clk_wiz_1_100M/ext_reset_in]
  connect_bd_net -net logic_1_dout1 [get_bd_pins dff_en_reset_0/d] [get_bd_pins logic_1/dout]
  connect_bd_net -net mb1_gpio_gpio2_io_o [get_bd_pins mb1_gpio/gpio2_io_o] [get_bd_pins mb1_pmod_io_switch/gen0_t_in]
  connect_bd_net -net mb1_gpio_gpio_io_o [get_bd_pins mb1_gpio/gpio_io_o] [get_bd_pins mb1_pmod_io_switch/pl2sw_data_o]
  connect_bd_net -net mb1_gpio_gpio_io_t [get_bd_pins mb1_gpio/gpio_io_t] [get_bd_pins mb1_pmod_io_switch/pl2sw_tri_o]
  connect_bd_net -net mb1_iic_iic2intc_irpt [get_bd_pins mb1_iic/iic2intc_irpt] [get_bd_pins mb1_interrupt_concat/In0]
  connect_bd_net -net mb1_iic_scl_o [get_bd_pins mb1_iic/scl_o] [get_bd_pins mb1_pmod_io_switch/scl_o_in]
  connect_bd_net -net mb1_iic_scl_t [get_bd_pins mb1_iic/scl_t] [get_bd_pins mb1_pmod_io_switch/scl_t_in]
  connect_bd_net -net mb1_iic_sda_o [get_bd_pins mb1_iic/sda_o] [get_bd_pins mb1_pmod_io_switch/sda_o_in]
  connect_bd_net -net mb1_iic_sda_t [get_bd_pins mb1_iic/sda_t] [get_bd_pins mb1_pmod_io_switch/sda_t_in]
  connect_bd_net -net mb1_interrupt_concat_dout [get_bd_pins mb1_intc/intr] [get_bd_pins mb1_interrupt_concat/dout]
  connect_bd_net -net mb1_pmod_io_switch_cap0_i_in [get_bd_pins mb1_pmod_io_switch/cap0_i_in] [get_bd_pins mb1_timer/capturetrig0]
  connect_bd_net -net mb1_spi_io0_o [get_bd_pins mb1_pmod_io_switch/mosi_o_in] [get_bd_pins mb1_spi/io0_o]
  connect_bd_net -net mb1_spi_io0_t [get_bd_pins mb1_pmod_io_switch/mosi_t_in] [get_bd_pins mb1_spi/io0_t]
  connect_bd_net -net mb1_spi_io1_o [get_bd_pins mb1_pmod_io_switch/miso_o_in] [get_bd_pins mb1_spi/io1_o]
  connect_bd_net -net mb1_spi_io1_t [get_bd_pins mb1_pmod_io_switch/miso_t_in] [get_bd_pins mb1_spi/io1_t]
  connect_bd_net -net mb1_spi_ip2intc_irpt [get_bd_pins mb1_interrupt_concat/In1] [get_bd_pins mb1_spi/ip2intc_irpt]
  connect_bd_net -net mb1_spi_sck_o [get_bd_pins mb1_pmod_io_switch/spick_o_in] [get_bd_pins mb1_spi/sck_o]
  connect_bd_net -net mb1_spi_sck_t [get_bd_pins mb1_pmod_io_switch/spick_t_in] [get_bd_pins mb1_spi/sck_t]
  connect_bd_net -net mb1_spi_ss_o [get_bd_pins mb1_pmod_io_switch/ss_o_in] [get_bd_pins mb1_spi/ss_o]
  connect_bd_net -net mb1_spi_ss_t [get_bd_pins mb1_pmod_io_switch/ss_t_in] [get_bd_pins mb1_spi/ss_t]
  connect_bd_net -net mb1_timer_generateout0 [get_bd_pins mb1_pmod_io_switch/gen0_o_in] [get_bd_pins mb1_timer/generateout0]
  connect_bd_net -net mb1_timer_interrupt [get_bd_pins mb1_interrupt_concat/In2] [get_bd_pins mb1_timer/interrupt]
  connect_bd_net -net mb1_timer_pwm0 [get_bd_pins mb1_pmod_io_switch/pwm_o_in] [get_bd_pins mb1_timer/pwm0]
  connect_bd_net -net mb_1_reset_Dout [get_bd_pins aux_reset_in] [get_bd_pins rst_clk_wiz_1_100M/aux_reset_in]
  connect_bd_net -net mdm_1_debug_sys_rst [get_bd_pins mb_debug_sys_rst] [get_bd_pins rst_clk_wiz_1_100M/mb_debug_sys_rst]
  connect_bd_net -net pmod2sw_data_in_1 [get_bd_pins pmod2sw_data_in] [get_bd_pins mb1_pmod_io_switch/pmod2sw_data_in]
  connect_bd_net -net pmod_io_switch_0_miso_i_in [get_bd_pins mb1_pmod_io_switch/miso_i_in] [get_bd_pins mb1_spi/io1_i]
  connect_bd_net -net pmod_io_switch_0_mosi_i_in [get_bd_pins mb1_pmod_io_switch/mosi_i_in] [get_bd_pins mb1_spi/io0_i]
  connect_bd_net -net pmod_io_switch_0_scl_i_in [get_bd_pins mb1_iic/scl_i] [get_bd_pins mb1_pmod_io_switch/scl_i_in]
  connect_bd_net -net pmod_io_switch_0_sda_i_in [get_bd_pins mb1_iic/sda_i] [get_bd_pins mb1_pmod_io_switch/sda_i_in]
  connect_bd_net -net pmod_io_switch_0_spick_i_in [get_bd_pins mb1_pmod_io_switch/spick_i_in] [get_bd_pins mb1_spi/sck_i]
  connect_bd_net -net pmod_io_switch_0_ss_i_in [get_bd_pins mb1_pmod_io_switch/ss_i_in] [get_bd_pins mb1_spi/ss_i]
  connect_bd_net -net pmod_io_switch_0_sw2pl_data_in [get_bd_pins mb1_gpio/gpio_io_i] [get_bd_pins mb1_pmod_io_switch/sw2pl_data_in]
  connect_bd_net -net pmod_io_switch_0_sw2pmod_data_out [get_bd_pins sw2pmod_data_out] [get_bd_pins mb1_pmod_io_switch/sw2pmod_data_out]
  connect_bd_net -net pmod_io_switch_0_sw2pmod_tri_out [get_bd_pins sw2pmod_tri_out] [get_bd_pins mb1_pmod_io_switch/sw2pmod_tri_out]
  connect_bd_net -net processing_system7_0_FCLK_CLK0 [get_bd_pins clk] [get_bd_pins dff_en_reset_0/clk] [get_bd_pins mb/Clk] [get_bd_pins mb1_gpio/s_axi_aclk] [get_bd_pins mb1_iic/s_axi_aclk] [get_bd_pins mb1_intc/s_axi_aclk] [get_bd_pins mb1_intr/s_axi_aclk] [get_bd_pins mb1_lmb/LMB_Clk] [get_bd_pins mb1_pmod_io_switch/s00_axi_aclk] [get_bd_pins mb1_spi/ext_spi_clk] [get_bd_pins mb1_spi/s_axi_aclk] [get_bd_pins mb1_timer/s_axi_aclk] [get_bd_pins microblaze_0_axi_periph/ACLK] [get_bd_pins microblaze_0_axi_periph/M00_ACLK] [get_bd_pins microblaze_0_axi_periph/M01_ACLK] [get_bd_pins microblaze_0_axi_periph/M02_ACLK] [get_bd_pins microblaze_0_axi_periph/M03_ACLK] [get_bd_pins microblaze_0_axi_periph/M04_ACLK] [get_bd_pins microblaze_0_axi_periph/M05_ACLK] [get_bd_pins microblaze_0_axi_periph/M06_ACLK] [get_bd_pins microblaze_0_axi_periph/M07_ACLK] [get_bd_pins microblaze_0_axi_periph/S00_ACLK] [get_bd_pins rst_clk_wiz_1_100M/slowest_sync_clk]
  connect_bd_net -net rst_clk_wiz_1_100M_bus_struct_reset [get_bd_pins mb1_lmb/SYS_Rst] [get_bd_pins rst_clk_wiz_1_100M/bus_struct_reset]
  connect_bd_net -net rst_clk_wiz_1_100M_interconnect_aresetn [get_bd_pins microblaze_0_axi_periph/ARESETN] [get_bd_pins rst_clk_wiz_1_100M/interconnect_aresetn]
  connect_bd_net -net rst_clk_wiz_1_100M_mb_reset [get_bd_pins mb/Reset] [get_bd_pins rst_clk_wiz_1_100M/mb_reset]
  connect_bd_net -net rst_clk_wiz_1_100M_peripheral_aresetn [get_bd_pins peripheral_aresetn] [get_bd_pins mb1_gpio/s_axi_aresetn] [get_bd_pins mb1_iic/s_axi_aresetn] [get_bd_pins mb1_intc/s_axi_aresetn] [get_bd_pins mb1_pmod_io_switch/s00_axi_aresetn] [get_bd_pins mb1_spi/s_axi_aresetn] [get_bd_pins mb1_timer/s_axi_aresetn] [get_bd_pins microblaze_0_axi_periph/M00_ARESETN] [get_bd_pins microblaze_0_axi_periph/M01_ARESETN] [get_bd_pins microblaze_0_axi_periph/M02_ARESETN] [get_bd_pins microblaze_0_axi_periph/M03_ARESETN] [get_bd_pins microblaze_0_axi_periph/M04_ARESETN] [get_bd_pins microblaze_0_axi_periph/M05_ARESETN] [get_bd_pins microblaze_0_axi_periph/M06_ARESETN] [get_bd_pins microblaze_0_axi_periph/M07_ARESETN] [get_bd_pins microblaze_0_axi_periph/S00_ARESETN] [get_bd_pins rst_clk_wiz_1_100M/peripheral_aresetn]
  connect_bd_net -net s_axi_aresetn_1 [get_bd_pins s_axi_aresetn] [get_bd_pins mb1_intr/s_axi_aresetn]

  # Restore current instance
  current_bd_instance $oldCurInst
}

# Hierarchical cell: audio
proc create_hier_cell_audio { parentCell nameHier } {

  variable script_folder

  if { $parentCell eq "" || $nameHier eq "" } {
     catch {common::send_msg_id "BD_TCL-102" "ERROR" create_hier_cell_audio() - Empty argument(s)!"}
     return
  }

  # Get object for parentCell
  set parentObj [get_bd_cells $parentCell]
  if { $parentObj == "" } {
     catch {common::send_msg_id "BD_TCL-100" "ERROR" "Unable to find parent cell <$parentCell>!"}
     return
  }

  # Make sure parentObj is hier blk
  set parentType [get_property TYPE $parentObj]
  if { $parentType ne "hier" } {
     catch {common::send_msg_id "BD_TCL-101" "ERROR" "Parent <$parentObj> has TYPE = <$parentType>. Expected to be <hier>."}
     return
  }

  # Save current instance; Restore later
  set oldCurInst [current_bd_instance .]

  # Set parent object as current
  current_bd_instance $parentObj

  # Create cell and set as current instance
  set hier_obj [create_bd_cell -type hier $nameHier]
  current_bd_instance $hier_obj

  # Create interface pins
  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S_AXI_LITE

  # Create pins
  create_bd_pin -dir I clk_i
  create_bd_pin -dir I pdm_audio_i
  create_bd_pin -dir O -from 0 -to 0 pdm_audio_shutdown
  create_bd_pin -dir O -from 0 -to 0 pdm_m_clk
  create_bd_pin -dir O -from 0 -to 0 pwm_audio_o
  create_bd_pin -dir I -from 0 -to 0 -type rst s_axi_lite_aresetn
  create_bd_pin -dir I -from 0 -to 0 sel

  # Create instance: audio_direct_0, and set properties
  set audio_direct_0 [ create_bd_cell -type ip -vlnv xilinx.com:user:audio_direct:1.0 audio_direct_0 ]

  # Create instance: d_axi_pdm_1, and set properties
  set d_axi_pdm_1 [ create_bd_cell -type ip -vlnv xilinx.com:user:d_axi_pdm:1.2 d_axi_pdm_1 ]

  # Create instance: pdm_audio_shutdown_mux, and set properties
  set pdm_audio_shutdown_mux [ create_bd_cell -type ip -vlnv xilinx.com:XUP:xup_2_to_1_mux:1.0 pdm_audio_shutdown_mux ]

  # Create instance: pdm_m_clk_mux, and set properties
  set pdm_m_clk_mux [ create_bd_cell -type ip -vlnv xilinx.com:XUP:xup_2_to_1_mux:1.0 pdm_m_clk_mux ]

  # Create instance: pwm_audio_o_mux, and set properties
  set pwm_audio_o_mux [ create_bd_cell -type ip -vlnv xilinx.com:XUP:xup_2_to_1_mux:1.0 pwm_audio_o_mux ]

  # Create interface connections
  connect_bd_intf_net -intf_net S_AXI_LITE_1 [get_bd_intf_pins S_AXI_LITE] [get_bd_intf_pins d_axi_pdm_1/S_AXI]

  # Create port connections
  connect_bd_net -net audio_direct_0_pdm_m_clk_o [get_bd_pins audio_direct_0/pdm_m_clk_o] [get_bd_pins pdm_m_clk_mux/b]
  connect_bd_net -net audio_direct_0_pwm_audio_o [get_bd_pins audio_direct_0/pwm_audio_o] [get_bd_pins pwm_audio_o_mux/b]
  connect_bd_net -net audio_direct_0_pwm_audio_shutdown [get_bd_pins audio_direct_0/pwm_audio_shutdown] [get_bd_pins pdm_audio_shutdown_mux/b]
  connect_bd_net -net audio_path_sel_Dout [get_bd_pins sel] [get_bd_pins audio_direct_0/en_i] [get_bd_pins pdm_audio_shutdown_mux/sel] [get_bd_pins pdm_m_clk_mux/sel] [get_bd_pins pwm_audio_o_mux/sel]
  connect_bd_net -net d_axi_pdm_1_pdm_m_clk_o [get_bd_pins d_axi_pdm_1/pdm_m_clk_o] [get_bd_pins pdm_m_clk_mux/a]
  connect_bd_net -net d_axi_pdm_1_pwm_audio [get_bd_pins d_axi_pdm_1/pwm_audio] [get_bd_pins pwm_audio_o_mux/a]
  connect_bd_net -net d_axi_pdm_1_pwm_sdaudio_o [get_bd_pins d_axi_pdm_1/pwm_sdaudio_o] [get_bd_pins pdm_audio_shutdown_mux/a]
  connect_bd_net -net pdm_audio_i_1 [get_bd_pins pdm_audio_i] [get_bd_pins audio_direct_0/pdm_audio_i] [get_bd_pins d_axi_pdm_1/pdm_m_data_i]
  connect_bd_net -net pdm_audio_shutdown_mux_y [get_bd_pins pdm_audio_shutdown] [get_bd_pins pdm_audio_shutdown_mux/y]
  connect_bd_net -net pdm_m_clk_mux_y [get_bd_pins pdm_m_clk] [get_bd_pins pdm_m_clk_mux/y]
  connect_bd_net -net processing_system7_0_FCLK_CLK0 [get_bd_pins clk_i] [get_bd_pins audio_direct_0/clk_i] [get_bd_pins d_axi_pdm_1/s_axi_aclk]
  connect_bd_net -net pwm_audio_o_mux_y [get_bd_pins pwm_audio_o] [get_bd_pins pwm_audio_o_mux/y]
  connect_bd_net -net rst_processing_system7_0_100M_peripheral_aresetn [get_bd_pins s_axi_lite_aresetn] [get_bd_pins d_axi_pdm_1/s_axi_aresetn]

  # Restore current instance
  current_bd_instance $oldCurInst
}


# Procedure to create entire design; Provide argument to make
# procedure reusable. If parentCell is "", will use root.
proc create_root_design { parentCell } {

  variable script_folder

  if { $parentCell eq "" } {
     set parentCell [get_bd_cells /]
  }

  # Get object for parentCell
  set parentObj [get_bd_cells $parentCell]
  if { $parentObj == "" } {
     catch {common::send_msg_id "BD_TCL-100" "ERROR" "Unable to find parent cell <$parentCell>!"}
     return
  }

  # Make sure parentObj is hier blk
  set parentType [get_property TYPE $parentObj]
  if { $parentType ne "hier" } {
     catch {common::send_msg_id "BD_TCL-101" "ERROR" "Parent <$parentObj> has TYPE = <$parentType>. Expected to be <hier>."}
     return
  }

  # Save current instance; Restore later
  set oldCurInst [current_bd_instance .]

  # Set parent object as current
  current_bd_instance $parentObj


  # Create interface ports
  set DDR [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:ddrx_rtl:1.0 DDR ]
  set FIXED_IO [ create_bd_intf_port -mode Master -vlnv xilinx.com:display_processing_system7:fixedio_rtl:1.0 FIXED_IO ]
  set Vaux0 [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:diff_analog_io_rtl:1.0 Vaux0 ]
  set Vaux1 [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:diff_analog_io_rtl:1.0 Vaux1 ]
  set Vaux5 [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:diff_analog_io_rtl:1.0 Vaux5 ]
  set Vaux6 [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:diff_analog_io_rtl:1.0 Vaux6 ]
  set Vaux8 [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:diff_analog_io_rtl:1.0 Vaux8 ]
  set Vaux9 [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:diff_analog_io_rtl:1.0 Vaux9 ]
  set Vaux12 [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:diff_analog_io_rtl:1.0 Vaux12 ]
  set Vaux13 [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:diff_analog_io_rtl:1.0 Vaux13 ]
  set Vaux15 [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:diff_analog_io_rtl:1.0 Vaux15 ]
  set Vp_Vn [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:diff_analog_io_rtl:1.0 Vp_Vn ]
  set btns_4bits [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:gpio_rtl:1.0 btns_4bits ]
  set ck_gpio [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:gpio_rtl:1.0 ck_gpio ]
  set hdmi_in [ create_bd_intf_port -mode Slave -vlnv digilentinc.com:interface:tmds_rtl:1.0 hdmi_in ]
  set hdmi_in_ddc [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:iic_rtl:1.0 hdmi_in_ddc ]
  set hdmi_out [ create_bd_intf_port -mode Master -vlnv digilentinc.com:interface:tmds_rtl:1.0 hdmi_out ]
  set hdmi_out_ddc [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:iic_rtl:1.0 hdmi_out_ddc ]
  set leds_4bits [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:gpio_rtl:1.0 leds_4bits ]
  set rgbleds_6bits [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:gpio_rtl:1.0 rgbleds_6bits ]
  set spi_sw_shield [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:spi_rtl:1.0 spi_sw_shield ]
  set sws_2bits [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:gpio_rtl:1.0 sws_2bits ]

  # Create ports
  set hdmi_in_hpd [ create_bd_port -dir O -from 0 -to 0 hdmi_in_hpd ]
  set hdmi_out_hpd [ create_bd_port -dir O -from 0 -to 0 hdmi_out_hpd ]
  set pdm_audio_shutdown [ create_bd_port -dir O -from 0 -to 0 pdm_audio_shutdown ]
  set pdm_m_clk [ create_bd_port -dir O -from 0 -to 0 pdm_m_clk ]
  set pdm_m_data_i [ create_bd_port -dir I pdm_m_data_i ]
  set pmodJA_data_in [ create_bd_port -dir I -from 7 -to 0 pmodJA_data_in ]
  set pmodJA_data_out [ create_bd_port -dir O -from 7 -to 0 pmodJA_data_out ]
  set pmodJA_tri_out [ create_bd_port -dir O -from 7 -to 0 pmodJA_tri_out ]
  set pmodJB_data_in [ create_bd_port -dir I -from 7 -to 0 pmodJB_data_in ]
  set pmodJB_data_out [ create_bd_port -dir O -from 7 -to 0 pmodJB_data_out ]
  set pmodJB_tri_out [ create_bd_port -dir O -from 7 -to 0 pmodJB_tri_out ]
  set pwm_audio_o [ create_bd_port -dir O -from 0 -to 0 pwm_audio_o ]
  set shield2sw_data_in_a5_a0 [ create_bd_port -dir I -from 5 -to 0 shield2sw_data_in_a5_a0 ]
  set shield2sw_data_in_d13_d2 [ create_bd_port -dir I -from 11 -to 0 shield2sw_data_in_d13_d2 ]
  set shield2sw_data_in_d1_d0 [ create_bd_port -dir I -from 1 -to 0 shield2sw_data_in_d1_d0 ]
  set shield2sw_scl_i_in [ create_bd_port -dir I shield2sw_scl_i_in ]
  set shield2sw_sda_i_in [ create_bd_port -dir I shield2sw_sda_i_in ]
  set sw2shield_data_out_a5_a0 [ create_bd_port -dir O -from 5 -to 0 sw2shield_data_out_a5_a0 ]
  set sw2shield_data_out_d13_d2 [ create_bd_port -dir O -from 11 -to 0 sw2shield_data_out_d13_d2 ]
  set sw2shield_data_out_d1_d0 [ create_bd_port -dir O -from 1 -to 0 sw2shield_data_out_d1_d0 ]
  set sw2shield_scl_o_out [ create_bd_port -dir O sw2shield_scl_o_out ]
  set sw2shield_scl_t_out [ create_bd_port -dir O sw2shield_scl_t_out ]
  set sw2shield_sda_o_out [ create_bd_port -dir O sw2shield_sda_o_out ]
  set sw2shield_sda_t_out [ create_bd_port -dir O sw2shield_sda_t_out ]
  set sw2shield_tri_out_a5_a0 [ create_bd_port -dir O -from 5 -to 0 sw2shield_tri_out_a5_a0 ]
  set sw2shield_tri_out_d13_d2 [ create_bd_port -dir O -from 11 -to 0 sw2shield_tri_out_d13_d2 ]
  set sw2shield_tri_out_d1_d0 [ create_bd_port -dir O -from 1 -to 0 sw2shield_tri_out_d1_d0 ]

  # Create instance: audio
  create_hier_cell_audio [current_bd_instance .] audio

  # Create instance: audio_path_sel, and set properties
  set audio_path_sel [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice:1.0 audio_path_sel ]
  set_property -dict [ list \
CONFIG.DIN_FROM {3} \
CONFIG.DIN_TO {3} \
CONFIG.DIN_WIDTH {7} \
CONFIG.DOUT_WIDTH {1} \
 ] $audio_path_sel

  # Create instance: axi_interconnect_0, and set properties
  set axi_interconnect_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_interconnect:2.1 axi_interconnect_0 ]
  set_property -dict [ list \
CONFIG.NUM_MI {1} \
CONFIG.NUM_SI {3} \
 ] $axi_interconnect_0

  # Create instance: axi_mem_intercon, and set properties
  set axi_mem_intercon [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_interconnect:2.1 axi_mem_intercon ]
  set_property -dict [ list \
CONFIG.NUM_MI {1} \
CONFIG.NUM_SI {2} \
 ] $axi_mem_intercon

  # Create instance: btns_gpio, and set properties
  set btns_gpio [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_gpio:2.0 btns_gpio ]
  set_property -dict [ list \
CONFIG.C_ALL_INPUTS {1} \
CONFIG.C_GPIO_WIDTH {4} \
CONFIG.C_INTERRUPT_PRESENT {1} \
 ] $btns_gpio

  # Create instance: concat_arduino, and set properties
  set concat_arduino [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconcat:2.1 concat_arduino ]
  set_property -dict [ list \
CONFIG.NUM_PORTS {13} \
 ] $concat_arduino

  # Create instance: concat_interrupts, and set properties
  set concat_interrupts [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconcat:2.1 concat_interrupts ]
  set_property -dict [ list \
CONFIG.NUM_PORTS {6} \
 ] $concat_interrupts

  # Create instance: concat_pmods, and set properties
  set concat_pmods [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconcat:2.1 concat_pmods ]
  set_property -dict [ list \
CONFIG.NUM_PORTS {8} \
 ] $concat_pmods

  # Create instance: constant_8bit_0, and set properties
  set constant_8bit_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant:1.1 constant_8bit_0 ]
  set_property -dict [ list \
CONFIG.CONST_VAL {0} \
CONFIG.CONST_WIDTH {8} \
 ] $constant_8bit_0

  # Create instance: iop1
  create_hier_cell_iop1 [current_bd_instance .] iop1

  # Create instance: iop2
  create_hier_cell_iop2 [current_bd_instance .] iop2

  # Create instance: iop3
  create_hier_cell_iop3 [current_bd_instance .] iop3

  # Create instance: iop_interrupts, and set properties
  set iop_interrupts [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconcat:2.1 iop_interrupts ]
  set_property -dict [ list \
CONFIG.NUM_PORTS {3} \
 ] $iop_interrupts

  # Create instance: logic_1, and set properties
  set logic_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant:1.1 logic_1 ]

  # Create instance: mb_1_intr_ack, and set properties
  set mb_1_intr_ack [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice:1.0 mb_1_intr_ack ]
  set_property -dict [ list \
CONFIG.DIN_FROM {4} \
CONFIG.DIN_TO {4} \
CONFIG.DIN_WIDTH {7} \
CONFIG.DOUT_WIDTH {1} \
 ] $mb_1_intr_ack

  # Create instance: mb_1_reset, and set properties
  set mb_1_reset [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice:1.0 mb_1_reset ]
  set_property -dict [ list \
CONFIG.DIN_FROM {0} \
CONFIG.DIN_TO {0} \
CONFIG.DIN_WIDTH {7} \
CONFIG.DOUT_WIDTH {1} \
 ] $mb_1_reset

  # Create instance: mb_2_intr_ack, and set properties
  set mb_2_intr_ack [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice:1.0 mb_2_intr_ack ]
  set_property -dict [ list \
CONFIG.DIN_FROM {5} \
CONFIG.DIN_TO {5} \
CONFIG.DIN_WIDTH {7} \
CONFIG.DOUT_WIDTH {1} \
 ] $mb_2_intr_ack

  # Create instance: mb_2_reset, and set properties
  set mb_2_reset [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice:1.0 mb_2_reset ]
  set_property -dict [ list \
CONFIG.DIN_FROM {1} \
CONFIG.DIN_TO {1} \
CONFIG.DIN_WIDTH {7} \
CONFIG.DOUT_WIDTH {1} \
 ] $mb_2_reset

  # Create instance: mb_3_intr_ack, and set properties
  set mb_3_intr_ack [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice:1.0 mb_3_intr_ack ]
  set_property -dict [ list \
CONFIG.DIN_FROM {6} \
CONFIG.DIN_TO {6} \
CONFIG.DIN_WIDTH {7} \
CONFIG.DOUT_WIDTH {1} \
 ] $mb_3_intr_ack

  # Create instance: mb_3_reset, and set properties
  set mb_3_reset [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice:1.0 mb_3_reset ]
  set_property -dict [ list \
CONFIG.DIN_FROM {2} \
CONFIG.DIN_TO {2} \
CONFIG.DIN_WIDTH {7} \
CONFIG.DOUT_WIDTH {1} \
 ] $mb_3_reset

  # Create instance: mb_bram_ctrl_1, and set properties
  set mb_bram_ctrl_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_bram_ctrl:4.0 mb_bram_ctrl_1 ]
  set_property -dict [ list \
CONFIG.SINGLE_PORT_BRAM {1} \
 ] $mb_bram_ctrl_1

  # Create instance: mb_bram_ctrl_2, and set properties
  set mb_bram_ctrl_2 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_bram_ctrl:4.0 mb_bram_ctrl_2 ]
  set_property -dict [ list \
CONFIG.SINGLE_PORT_BRAM {1} \
 ] $mb_bram_ctrl_2

  # Create instance: mb_bram_ctrl_3, and set properties
  set mb_bram_ctrl_3 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_bram_ctrl:4.0 mb_bram_ctrl_3 ]
  set_property -dict [ list \
CONFIG.SINGLE_PORT_BRAM {1} \
 ] $mb_bram_ctrl_3

  # Create instance: mdm_1, and set properties
  set mdm_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:mdm:3.2 mdm_1 ]
  set_property -dict [ list \
CONFIG.C_MB_DBG_PORTS {3} \
 ] $mdm_1

  # Create instance: proc_sys_reset_142M, and set properties
  set proc_sys_reset_142M [ create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset:5.0 proc_sys_reset_142M ]

  # Create instance: proc_sys_reset_pixelclk, and set properties
  set proc_sys_reset_pixelclk [ create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset:5.0 proc_sys_reset_pixelclk ]

  # Create instance: processing_system7_0, and set properties
  set processing_system7_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:processing_system7:5.5 processing_system7_0 ]
  set_property -dict [ list \
CONFIG.PCW_ACT_APU_PERIPHERAL_FREQMHZ {650.000000} \
CONFIG.PCW_ACT_CAN0_PERIPHERAL_FREQMHZ {23.8095} \
CONFIG.PCW_ACT_CAN1_PERIPHERAL_FREQMHZ {23.8095} \
CONFIG.PCW_ACT_CAN_PERIPHERAL_FREQMHZ {10.000000} \
CONFIG.PCW_ACT_DCI_PERIPHERAL_FREQMHZ {10.096154} \
CONFIG.PCW_ACT_ENET0_PERIPHERAL_FREQMHZ {125.000000} \
CONFIG.PCW_ACT_ENET1_PERIPHERAL_FREQMHZ {10.000000} \
CONFIG.PCW_ACT_FPGA0_PERIPHERAL_FREQMHZ {100.000000} \
CONFIG.PCW_ACT_FPGA1_PERIPHERAL_FREQMHZ {142.857132} \
CONFIG.PCW_ACT_FPGA2_PERIPHERAL_FREQMHZ {200.000000} \
CONFIG.PCW_ACT_FPGA3_PERIPHERAL_FREQMHZ {166.666672} \
CONFIG.PCW_ACT_I2C_PERIPHERAL_FREQMHZ {50} \
CONFIG.PCW_ACT_PCAP_PERIPHERAL_FREQMHZ {200.000000} \
CONFIG.PCW_ACT_QSPI_PERIPHERAL_FREQMHZ {200.000000} \
CONFIG.PCW_ACT_SDIO_PERIPHERAL_FREQMHZ {50.000000} \
CONFIG.PCW_ACT_SMC_PERIPHERAL_FREQMHZ {10.000000} \
CONFIG.PCW_ACT_SPI_PERIPHERAL_FREQMHZ {10.000000} \
CONFIG.PCW_ACT_TPIU_PERIPHERAL_FREQMHZ {200.000000} \
CONFIG.PCW_ACT_TTC0_CLK0_PERIPHERAL_FREQMHZ {108.333336} \
CONFIG.PCW_ACT_TTC0_CLK1_PERIPHERAL_FREQMHZ {108.333336} \
CONFIG.PCW_ACT_TTC0_CLK2_PERIPHERAL_FREQMHZ {108.333336} \
CONFIG.PCW_ACT_TTC1_CLK0_PERIPHERAL_FREQMHZ {108.333336} \
CONFIG.PCW_ACT_TTC1_CLK1_PERIPHERAL_FREQMHZ {108.333336} \
CONFIG.PCW_ACT_TTC1_CLK2_PERIPHERAL_FREQMHZ {108.333336} \
CONFIG.PCW_ACT_TTC_PERIPHERAL_FREQMHZ {50} \
CONFIG.PCW_ACT_UART_PERIPHERAL_FREQMHZ {100.000000} \
CONFIG.PCW_ACT_USB0_PERIPHERAL_FREQMHZ {60} \
CONFIG.PCW_ACT_USB1_PERIPHERAL_FREQMHZ {60} \
CONFIG.PCW_ACT_WDT_PERIPHERAL_FREQMHZ {108.333336} \
CONFIG.PCW_APU_CLK_RATIO_ENABLE {6:2:1} \
CONFIG.PCW_APU_PERIPHERAL_FREQMHZ {650} \
CONFIG.PCW_ARMPLL_CTRL_FBDIV {26} \
CONFIG.PCW_CAN0_BASEADDR {0xE0008000} \
CONFIG.PCW_CAN0_CAN0_IO {<Select>} \
CONFIG.PCW_CAN0_GRP_CLK_ENABLE {0} \
CONFIG.PCW_CAN0_GRP_CLK_IO {<Select>} \
CONFIG.PCW_CAN0_HIGHADDR {0xE0008FFF} \
CONFIG.PCW_CAN0_PERIPHERAL_CLKSRC {External} \
CONFIG.PCW_CAN0_PERIPHERAL_ENABLE {0} \
CONFIG.PCW_CAN0_PERIPHERAL_FREQMHZ {-1} \
CONFIG.PCW_CAN1_BASEADDR {0xE0009000} \
CONFIG.PCW_CAN1_CAN1_IO {<Select>} \
CONFIG.PCW_CAN1_GRP_CLK_ENABLE {0} \
CONFIG.PCW_CAN1_GRP_CLK_IO {<Select>} \
CONFIG.PCW_CAN1_HIGHADDR {0xE0009FFF} \
CONFIG.PCW_CAN1_PERIPHERAL_CLKSRC {External} \
CONFIG.PCW_CAN1_PERIPHERAL_ENABLE {0} \
CONFIG.PCW_CAN1_PERIPHERAL_FREQMHZ {-1} \
CONFIG.PCW_CAN_PERIPHERAL_CLKSRC {IO PLL} \
CONFIG.PCW_CAN_PERIPHERAL_DIVISOR0 {1} \
CONFIG.PCW_CAN_PERIPHERAL_DIVISOR1 {1} \
CONFIG.PCW_CAN_PERIPHERAL_FREQMHZ {100} \
CONFIG.PCW_CAN_PERIPHERAL_VALID {0} \
CONFIG.PCW_CLK0_FREQ {100000000} \
CONFIG.PCW_CLK1_FREQ {142857132} \
CONFIG.PCW_CLK2_FREQ {200000000} \
CONFIG.PCW_CLK3_FREQ {166666672} \
CONFIG.PCW_CORE0_FIQ_INTR {0} \
CONFIG.PCW_CORE0_IRQ_INTR {0} \
CONFIG.PCW_CORE1_FIQ_INTR {0} \
CONFIG.PCW_CORE1_IRQ_INTR {0} \
CONFIG.PCW_CPU_CPU_6X4X_MAX_RANGE {667} \
CONFIG.PCW_CPU_CPU_PLL_FREQMHZ {1300.000} \
CONFIG.PCW_CPU_PERIPHERAL_CLKSRC {ARM PLL} \
CONFIG.PCW_CPU_PERIPHERAL_DIVISOR0 {2} \
CONFIG.PCW_CRYSTAL_PERIPHERAL_FREQMHZ {50} \
CONFIG.PCW_DCI_PERIPHERAL_CLKSRC {DDR PLL} \
CONFIG.PCW_DCI_PERIPHERAL_DIVISOR0 {52} \
CONFIG.PCW_DCI_PERIPHERAL_DIVISOR1 {2} \
CONFIG.PCW_DCI_PERIPHERAL_FREQMHZ {10.159} \
CONFIG.PCW_DDRPLL_CTRL_FBDIV {21} \
CONFIG.PCW_DDR_DDR_PLL_FREQMHZ {1050.000} \
CONFIG.PCW_DDR_HPRLPR_QUEUE_PARTITION {HPR(0)/LPR(32)} \
CONFIG.PCW_DDR_HPR_TO_CRITICAL_PRIORITY_LEVEL {15} \
CONFIG.PCW_DDR_LPR_TO_CRITICAL_PRIORITY_LEVEL {2} \
CONFIG.PCW_DDR_PERIPHERAL_CLKSRC {DDR PLL} \
CONFIG.PCW_DDR_PERIPHERAL_DIVISOR0 {2} \
CONFIG.PCW_DDR_PORT0_HPR_ENABLE {0} \
CONFIG.PCW_DDR_PORT1_HPR_ENABLE {0} \
CONFIG.PCW_DDR_PORT2_HPR_ENABLE {0} \
CONFIG.PCW_DDR_PORT3_HPR_ENABLE {0} \
CONFIG.PCW_DDR_PRIORITY_READPORT_0 {<Select>} \
CONFIG.PCW_DDR_PRIORITY_READPORT_1 {<Select>} \
CONFIG.PCW_DDR_PRIORITY_READPORT_2 {<Select>} \
CONFIG.PCW_DDR_PRIORITY_READPORT_3 {<Select>} \
CONFIG.PCW_DDR_PRIORITY_WRITEPORT_0 {<Select>} \
CONFIG.PCW_DDR_PRIORITY_WRITEPORT_1 {<Select>} \
CONFIG.PCW_DDR_PRIORITY_WRITEPORT_2 {<Select>} \
CONFIG.PCW_DDR_PRIORITY_WRITEPORT_3 {<Select>} \
CONFIG.PCW_DDR_RAM_BASEADDR {0x00100000} \
CONFIG.PCW_DDR_RAM_HIGHADDR {0x1FFFFFFF} \
CONFIG.PCW_DDR_WRITE_TO_CRITICAL_PRIORITY_LEVEL {2} \
CONFIG.PCW_DM_WIDTH {4} \
CONFIG.PCW_DQS_WIDTH {4} \
CONFIG.PCW_DQ_WIDTH {32} \
CONFIG.PCW_ENET0_BASEADDR {0xE000B000} \
CONFIG.PCW_ENET0_ENET0_IO {MIO 16 .. 27} \
CONFIG.PCW_ENET0_GRP_MDIO_ENABLE {1} \
CONFIG.PCW_ENET0_GRP_MDIO_IO {MIO 52 .. 53} \
CONFIG.PCW_ENET0_HIGHADDR {0xE000BFFF} \
CONFIG.PCW_ENET0_PERIPHERAL_CLKSRC {IO PLL} \
CONFIG.PCW_ENET0_PERIPHERAL_DIVISOR0 {8} \
CONFIG.PCW_ENET0_PERIPHERAL_DIVISOR1 {1} \
CONFIG.PCW_ENET0_PERIPHERAL_ENABLE {1} \
CONFIG.PCW_ENET0_PERIPHERAL_FREQMHZ {1000 Mbps} \
CONFIG.PCW_ENET0_RESET_ENABLE {0} \
CONFIG.PCW_ENET0_RESET_IO {<Select>} \
CONFIG.PCW_ENET1_BASEADDR {0xE000C000} \
CONFIG.PCW_ENET1_ENET1_IO {<Select>} \
CONFIG.PCW_ENET1_GRP_MDIO_ENABLE {0} \
CONFIG.PCW_ENET1_GRP_MDIO_IO {<Select>} \
CONFIG.PCW_ENET1_HIGHADDR {0xE000CFFF} \
CONFIG.PCW_ENET1_PERIPHERAL_CLKSRC {IO PLL} \
CONFIG.PCW_ENET1_PERIPHERAL_DIVISOR0 {1} \
CONFIG.PCW_ENET1_PERIPHERAL_DIVISOR1 {1} \
CONFIG.PCW_ENET1_PERIPHERAL_ENABLE {0} \
CONFIG.PCW_ENET1_PERIPHERAL_FREQMHZ {1000 Mbps} \
CONFIG.PCW_ENET1_RESET_ENABLE {0} \
CONFIG.PCW_ENET1_RESET_IO {<Select>} \
CONFIG.PCW_ENET_RESET_ENABLE {0} \
CONFIG.PCW_ENET_RESET_POLARITY {Active Low} \
CONFIG.PCW_ENET_RESET_SELECT {<Select>} \
CONFIG.PCW_EN_4K_TIMER {0} \
CONFIG.PCW_EN_CAN0 {0} \
CONFIG.PCW_EN_CAN1 {0} \
CONFIG.PCW_EN_CLK0_PORT {1} \
CONFIG.PCW_EN_CLK1_PORT {1} \
CONFIG.PCW_EN_CLK2_PORT {1} \
CONFIG.PCW_EN_CLK3_PORT {1} \
CONFIG.PCW_EN_CLKTRIG0_PORT {0} \
CONFIG.PCW_EN_CLKTRIG1_PORT {0} \
CONFIG.PCW_EN_CLKTRIG2_PORT {0} \
CONFIG.PCW_EN_CLKTRIG3_PORT {0} \
CONFIG.PCW_EN_DDR {1} \
CONFIG.PCW_EN_EMIO_CAN0 {0} \
CONFIG.PCW_EN_EMIO_CAN1 {0} \
CONFIG.PCW_EN_EMIO_CD_SDIO0 {0} \
CONFIG.PCW_EN_EMIO_CD_SDIO1 {0} \
CONFIG.PCW_EN_EMIO_ENET0 {0} \
CONFIG.PCW_EN_EMIO_ENET1 {0} \
CONFIG.PCW_EN_EMIO_GPIO {1} \
CONFIG.PCW_EN_EMIO_I2C0 {1} \
CONFIG.PCW_EN_EMIO_I2C1 {0} \
CONFIG.PCW_EN_EMIO_MODEM_UART0 {0} \
CONFIG.PCW_EN_EMIO_MODEM_UART1 {0} \
CONFIG.PCW_EN_EMIO_PJTAG {0} \
CONFIG.PCW_EN_EMIO_SDIO0 {0} \
CONFIG.PCW_EN_EMIO_SDIO1 {0} \
CONFIG.PCW_EN_EMIO_SPI0 {0} \
CONFIG.PCW_EN_EMIO_SPI1 {0} \
CONFIG.PCW_EN_EMIO_SRAM_INT {0} \
CONFIG.PCW_EN_EMIO_TRACE {0} \
CONFIG.PCW_EN_EMIO_TTC0 {0} \
CONFIG.PCW_EN_EMIO_TTC1 {0} \
CONFIG.PCW_EN_EMIO_UART0 {0} \
CONFIG.PCW_EN_EMIO_UART1 {0} \
CONFIG.PCW_EN_EMIO_WDT {0} \
CONFIG.PCW_EN_EMIO_WP_SDIO0 {0} \
CONFIG.PCW_EN_EMIO_WP_SDIO1 {0} \
CONFIG.PCW_EN_ENET0 {1} \
CONFIG.PCW_EN_ENET1 {0} \
CONFIG.PCW_EN_GPIO {0} \
CONFIG.PCW_EN_I2C0 {1} \
CONFIG.PCW_EN_I2C1 {0} \
CONFIG.PCW_EN_MODEM_UART0 {0} \
CONFIG.PCW_EN_MODEM_UART1 {0} \
CONFIG.PCW_EN_PJTAG {0} \
CONFIG.PCW_EN_PTP_ENET0 {0} \
CONFIG.PCW_EN_PTP_ENET1 {0} \
CONFIG.PCW_EN_QSPI {1} \
CONFIG.PCW_EN_RST0_PORT {1} \
CONFIG.PCW_EN_RST1_PORT {0} \
CONFIG.PCW_EN_RST2_PORT {0} \
CONFIG.PCW_EN_RST3_PORT {0} \
CONFIG.PCW_EN_SDIO0 {1} \
CONFIG.PCW_EN_SDIO1 {0} \
CONFIG.PCW_EN_SMC {0} \
CONFIG.PCW_EN_SPI0 {0} \
CONFIG.PCW_EN_SPI1 {0} \
CONFIG.PCW_EN_TRACE {0} \
CONFIG.PCW_EN_TTC0 {0} \
CONFIG.PCW_EN_TTC1 {0} \
CONFIG.PCW_EN_UART0 {1} \
CONFIG.PCW_EN_UART1 {0} \
CONFIG.PCW_EN_USB0 {1} \
CONFIG.PCW_EN_USB1 {0} \
CONFIG.PCW_EN_WDT {0} \
CONFIG.PCW_FCLK0_PERIPHERAL_CLKSRC {IO PLL} \
CONFIG.PCW_FCLK0_PERIPHERAL_DIVISOR0 {5} \
CONFIG.PCW_FCLK0_PERIPHERAL_DIVISOR1 {2} \
CONFIG.PCW_FCLK1_PERIPHERAL_CLKSRC {IO PLL} \
CONFIG.PCW_FCLK1_PERIPHERAL_DIVISOR0 {7} \
CONFIG.PCW_FCLK1_PERIPHERAL_DIVISOR1 {1} \
CONFIG.PCW_FCLK2_PERIPHERAL_CLKSRC {IO PLL} \
CONFIG.PCW_FCLK2_PERIPHERAL_DIVISOR0 {5} \
CONFIG.PCW_FCLK2_PERIPHERAL_DIVISOR1 {1} \
CONFIG.PCW_FCLK3_PERIPHERAL_CLKSRC {IO PLL} \
CONFIG.PCW_FCLK3_PERIPHERAL_DIVISOR0 {6} \
CONFIG.PCW_FCLK3_PERIPHERAL_DIVISOR1 {1} \
CONFIG.PCW_FCLK_CLK0_BUF {true} \
CONFIG.PCW_FCLK_CLK1_BUF {true} \
CONFIG.PCW_FCLK_CLK2_BUF {true} \
CONFIG.PCW_FCLK_CLK3_BUF {true} \
CONFIG.PCW_FPGA0_PERIPHERAL_FREQMHZ {100} \
CONFIG.PCW_FPGA1_PERIPHERAL_FREQMHZ {142} \
CONFIG.PCW_FPGA2_PERIPHERAL_FREQMHZ {200} \
CONFIG.PCW_FPGA3_PERIPHERAL_FREQMHZ {160} \
CONFIG.PCW_FPGA_FCLK0_ENABLE {1} \
CONFIG.PCW_FPGA_FCLK1_ENABLE {1} \
CONFIG.PCW_FPGA_FCLK2_ENABLE {1} \
CONFIG.PCW_FPGA_FCLK3_ENABLE {1} \
CONFIG.PCW_FTM_CTI_IN0 {<Select>} \
CONFIG.PCW_FTM_CTI_IN1 {<Select>} \
CONFIG.PCW_FTM_CTI_IN2 {<Select>} \
CONFIG.PCW_FTM_CTI_IN3 {<Select>} \
CONFIG.PCW_FTM_CTI_OUT0 {<Select>} \
CONFIG.PCW_FTM_CTI_OUT1 {<Select>} \
CONFIG.PCW_FTM_CTI_OUT2 {<Select>} \
CONFIG.PCW_FTM_CTI_OUT3 {<Select>} \
CONFIG.PCW_GPIO_BASEADDR {0xE000A000} \
CONFIG.PCW_GPIO_EMIO_GPIO_ENABLE {1} \
CONFIG.PCW_GPIO_EMIO_GPIO_IO {7} \
CONFIG.PCW_GPIO_EMIO_GPIO_WIDTH {7} \
CONFIG.PCW_GPIO_HIGHADDR {0xE000AFFF} \
CONFIG.PCW_GPIO_MIO_GPIO_ENABLE {0} \
CONFIG.PCW_GPIO_MIO_GPIO_IO {<Select>} \
CONFIG.PCW_GPIO_PERIPHERAL_ENABLE {0} \
CONFIG.PCW_I2C0_BASEADDR {0xE0004000} \
CONFIG.PCW_I2C0_GRP_INT_ENABLE {1} \
CONFIG.PCW_I2C0_GRP_INT_IO {EMIO} \
CONFIG.PCW_I2C0_HIGHADDR {0xE0004FFF} \
CONFIG.PCW_I2C0_I2C0_IO {EMIO} \
CONFIG.PCW_I2C0_PERIPHERAL_ENABLE {1} \
CONFIG.PCW_I2C0_RESET_ENABLE {0} \
CONFIG.PCW_I2C0_RESET_IO {<Select>} \
CONFIG.PCW_I2C1_BASEADDR {0xE0005000} \
CONFIG.PCW_I2C1_GRP_INT_ENABLE {0} \
CONFIG.PCW_I2C1_GRP_INT_IO {<Select>} \
CONFIG.PCW_I2C1_HIGHADDR {0xE0005FFF} \
CONFIG.PCW_I2C1_I2C1_IO {<Select>} \
CONFIG.PCW_I2C1_PERIPHERAL_ENABLE {0} \
CONFIG.PCW_I2C1_RESET_ENABLE {0} \
CONFIG.PCW_I2C1_RESET_IO {<Select>} \
CONFIG.PCW_I2C_PERIPHERAL_FREQMHZ {108.333336} \
CONFIG.PCW_I2C_RESET_ENABLE {0} \
CONFIG.PCW_I2C_RESET_POLARITY {Active Low} \
CONFIG.PCW_I2C_RESET_SELECT {<Select>} \
CONFIG.PCW_IMPORT_BOARD_PRESET {None} \
CONFIG.PCW_INCLUDE_ACP_TRANS_CHECK {0} \
CONFIG.PCW_INCLUDE_TRACE_BUFFER {0} \
CONFIG.PCW_IOPLL_CTRL_FBDIV {20} \
CONFIG.PCW_IO_IO_PLL_FREQMHZ {1000.000} \
CONFIG.PCW_IRQ_F2P_INTR {1} \
CONFIG.PCW_IRQ_F2P_MODE {DIRECT} \
CONFIG.PCW_MIO_0_DIRECTION {<Select>} \
CONFIG.PCW_MIO_0_IOTYPE {<Select>} \
CONFIG.PCW_MIO_0_PULLUP {<Select>} \
CONFIG.PCW_MIO_0_SLEW {<Select>} \
CONFIG.PCW_MIO_10_DIRECTION {<Select>} \
CONFIG.PCW_MIO_10_IOTYPE {<Select>} \
CONFIG.PCW_MIO_10_PULLUP {<Select>} \
CONFIG.PCW_MIO_10_SLEW {<Select>} \
CONFIG.PCW_MIO_11_DIRECTION {<Select>} \
CONFIG.PCW_MIO_11_IOTYPE {<Select>} \
CONFIG.PCW_MIO_11_PULLUP {<Select>} \
CONFIG.PCW_MIO_11_SLEW {<Select>} \
CONFIG.PCW_MIO_12_DIRECTION {<Select>} \
CONFIG.PCW_MIO_12_IOTYPE {<Select>} \
CONFIG.PCW_MIO_12_PULLUP {<Select>} \
CONFIG.PCW_MIO_12_SLEW {<Select>} \
CONFIG.PCW_MIO_13_DIRECTION {<Select>} \
CONFIG.PCW_MIO_13_IOTYPE {<Select>} \
CONFIG.PCW_MIO_13_PULLUP {<Select>} \
CONFIG.PCW_MIO_13_SLEW {<Select>} \
CONFIG.PCW_MIO_14_DIRECTION {in} \
CONFIG.PCW_MIO_14_IOTYPE {LVCMOS 3.3V} \
CONFIG.PCW_MIO_14_PULLUP {enabled} \
CONFIG.PCW_MIO_14_SLEW {slow} \
CONFIG.PCW_MIO_15_DIRECTION {out} \
CONFIG.PCW_MIO_15_IOTYPE {LVCMOS 3.3V} \
CONFIG.PCW_MIO_15_PULLUP {enabled} \
CONFIG.PCW_MIO_15_SLEW {slow} \
CONFIG.PCW_MIO_16_DIRECTION {out} \
CONFIG.PCW_MIO_16_IOTYPE {LVCMOS 1.8V} \
CONFIG.PCW_MIO_16_PULLUP {enabled} \
CONFIG.PCW_MIO_16_SLEW {slow} \
CONFIG.PCW_MIO_17_DIRECTION {out} \
CONFIG.PCW_MIO_17_IOTYPE {LVCMOS 1.8V} \
CONFIG.PCW_MIO_17_PULLUP {enabled} \
CONFIG.PCW_MIO_17_SLEW {slow} \
CONFIG.PCW_MIO_18_DIRECTION {out} \
CONFIG.PCW_MIO_18_IOTYPE {LVCMOS 1.8V} \
CONFIG.PCW_MIO_18_PULLUP {enabled} \
CONFIG.PCW_MIO_18_SLEW {slow} \
CONFIG.PCW_MIO_19_DIRECTION {out} \
CONFIG.PCW_MIO_19_IOTYPE {LVCMOS 1.8V} \
CONFIG.PCW_MIO_19_PULLUP {enabled} \
CONFIG.PCW_MIO_19_SLEW {slow} \
CONFIG.PCW_MIO_1_DIRECTION {out} \
CONFIG.PCW_MIO_1_IOTYPE {LVCMOS 3.3V} \
CONFIG.PCW_MIO_1_PULLUP {enabled} \
CONFIG.PCW_MIO_1_SLEW {slow} \
CONFIG.PCW_MIO_20_DIRECTION {out} \
CONFIG.PCW_MIO_20_IOTYPE {LVCMOS 1.8V} \
CONFIG.PCW_MIO_20_PULLUP {enabled} \
CONFIG.PCW_MIO_20_SLEW {slow} \
CONFIG.PCW_MIO_21_DIRECTION {out} \
CONFIG.PCW_MIO_21_IOTYPE {LVCMOS 1.8V} \
CONFIG.PCW_MIO_21_PULLUP {enabled} \
CONFIG.PCW_MIO_21_SLEW {slow} \
CONFIG.PCW_MIO_22_DIRECTION {in} \
CONFIG.PCW_MIO_22_IOTYPE {LVCMOS 1.8V} \
CONFIG.PCW_MIO_22_PULLUP {enabled} \
CONFIG.PCW_MIO_22_SLEW {slow} \
CONFIG.PCW_MIO_23_DIRECTION {in} \
CONFIG.PCW_MIO_23_IOTYPE {LVCMOS 1.8V} \
CONFIG.PCW_MIO_23_PULLUP {enabled} \
CONFIG.PCW_MIO_23_SLEW {slow} \
CONFIG.PCW_MIO_24_DIRECTION {in} \
CONFIG.PCW_MIO_24_IOTYPE {LVCMOS 1.8V} \
CONFIG.PCW_MIO_24_PULLUP {enabled} \
CONFIG.PCW_MIO_24_SLEW {slow} \
CONFIG.PCW_MIO_25_DIRECTION {in} \
CONFIG.PCW_MIO_25_IOTYPE {LVCMOS 1.8V} \
CONFIG.PCW_MIO_25_PULLUP {enabled} \
CONFIG.PCW_MIO_25_SLEW {slow} \
CONFIG.PCW_MIO_26_DIRECTION {in} \
CONFIG.PCW_MIO_26_IOTYPE {LVCMOS 1.8V} \
CONFIG.PCW_MIO_26_PULLUP {enabled} \
CONFIG.PCW_MIO_26_SLEW {slow} \
CONFIG.PCW_MIO_27_DIRECTION {in} \
CONFIG.PCW_MIO_27_IOTYPE {LVCMOS 1.8V} \
CONFIG.PCW_MIO_27_PULLUP {enabled} \
CONFIG.PCW_MIO_27_SLEW {slow} \
CONFIG.PCW_MIO_28_DIRECTION {inout} \
CONFIG.PCW_MIO_28_IOTYPE {LVCMOS 1.8V} \
CONFIG.PCW_MIO_28_PULLUP {enabled} \
CONFIG.PCW_MIO_28_SLEW {slow} \
CONFIG.PCW_MIO_29_DIRECTION {in} \
CONFIG.PCW_MIO_29_IOTYPE {LVCMOS 1.8V} \
CONFIG.PCW_MIO_29_PULLUP {enabled} \
CONFIG.PCW_MIO_29_SLEW {slow} \
CONFIG.PCW_MIO_2_DIRECTION {inout} \
CONFIG.PCW_MIO_2_IOTYPE {LVCMOS 3.3V} \
CONFIG.PCW_MIO_2_PULLUP {disabled} \
CONFIG.PCW_MIO_2_SLEW {slow} \
CONFIG.PCW_MIO_30_DIRECTION {out} \
CONFIG.PCW_MIO_30_IOTYPE {LVCMOS 1.8V} \
CONFIG.PCW_MIO_30_PULLUP {enabled} \
CONFIG.PCW_MIO_30_SLEW {slow} \
CONFIG.PCW_MIO_31_DIRECTION {in} \
CONFIG.PCW_MIO_31_IOTYPE {LVCMOS 1.8V} \
CONFIG.PCW_MIO_31_PULLUP {enabled} \
CONFIG.PCW_MIO_31_SLEW {slow} \
CONFIG.PCW_MIO_32_DIRECTION {inout} \
CONFIG.PCW_MIO_32_IOTYPE {LVCMOS 1.8V} \
CONFIG.PCW_MIO_32_PULLUP {enabled} \
CONFIG.PCW_MIO_32_SLEW {slow} \
CONFIG.PCW_MIO_33_DIRECTION {inout} \
CONFIG.PCW_MIO_33_IOTYPE {LVCMOS 1.8V} \
CONFIG.PCW_MIO_33_PULLUP {enabled} \
CONFIG.PCW_MIO_33_SLEW {slow} \
CONFIG.PCW_MIO_34_DIRECTION {inout} \
CONFIG.PCW_MIO_34_IOTYPE {LVCMOS 1.8V} \
CONFIG.PCW_MIO_34_PULLUP {enabled} \
CONFIG.PCW_MIO_34_SLEW {slow} \
CONFIG.PCW_MIO_35_DIRECTION {inout} \
CONFIG.PCW_MIO_35_IOTYPE {LVCMOS 1.8V} \
CONFIG.PCW_MIO_35_PULLUP {enabled} \
CONFIG.PCW_MIO_35_SLEW {slow} \
CONFIG.PCW_MIO_36_DIRECTION {in} \
CONFIG.PCW_MIO_36_IOTYPE {LVCMOS 1.8V} \
CONFIG.PCW_MIO_36_PULLUP {enabled} \
CONFIG.PCW_MIO_36_SLEW {slow} \
CONFIG.PCW_MIO_37_DIRECTION {inout} \
CONFIG.PCW_MIO_37_IOTYPE {LVCMOS 1.8V} \
CONFIG.PCW_MIO_37_PULLUP {enabled} \
CONFIG.PCW_MIO_37_SLEW {slow} \
CONFIG.PCW_MIO_38_DIRECTION {inout} \
CONFIG.PCW_MIO_38_IOTYPE {LVCMOS 1.8V} \
CONFIG.PCW_MIO_38_PULLUP {enabled} \
CONFIG.PCW_MIO_38_SLEW {slow} \
CONFIG.PCW_MIO_39_DIRECTION {inout} \
CONFIG.PCW_MIO_39_IOTYPE {LVCMOS 1.8V} \
CONFIG.PCW_MIO_39_PULLUP {enabled} \
CONFIG.PCW_MIO_39_SLEW {slow} \
CONFIG.PCW_MIO_3_DIRECTION {inout} \
CONFIG.PCW_MIO_3_IOTYPE {LVCMOS 3.3V} \
CONFIG.PCW_MIO_3_PULLUP {disabled} \
CONFIG.PCW_MIO_3_SLEW {slow} \
CONFIG.PCW_MIO_40_DIRECTION {inout} \
CONFIG.PCW_MIO_40_IOTYPE {LVCMOS 1.8V} \
CONFIG.PCW_MIO_40_PULLUP {enabled} \
CONFIG.PCW_MIO_40_SLEW {slow} \
CONFIG.PCW_MIO_41_DIRECTION {inout} \
CONFIG.PCW_MIO_41_IOTYPE {LVCMOS 1.8V} \
CONFIG.PCW_MIO_41_PULLUP {enabled} \
CONFIG.PCW_MIO_41_SLEW {slow} \
CONFIG.PCW_MIO_42_DIRECTION {inout} \
CONFIG.PCW_MIO_42_IOTYPE {LVCMOS 1.8V} \
CONFIG.PCW_MIO_42_PULLUP {enabled} \
CONFIG.PCW_MIO_42_SLEW {slow} \
CONFIG.PCW_MIO_43_DIRECTION {inout} \
CONFIG.PCW_MIO_43_IOTYPE {LVCMOS 1.8V} \
CONFIG.PCW_MIO_43_PULLUP {enabled} \
CONFIG.PCW_MIO_43_SLEW {slow} \
CONFIG.PCW_MIO_44_DIRECTION {inout} \
CONFIG.PCW_MIO_44_IOTYPE {LVCMOS 1.8V} \
CONFIG.PCW_MIO_44_PULLUP {enabled} \
CONFIG.PCW_MIO_44_SLEW {slow} \
CONFIG.PCW_MIO_45_DIRECTION {inout} \
CONFIG.PCW_MIO_45_IOTYPE {LVCMOS 1.8V} \
CONFIG.PCW_MIO_45_PULLUP {enabled} \
CONFIG.PCW_MIO_45_SLEW {slow} \
CONFIG.PCW_MIO_46_DIRECTION {<Select>} \
CONFIG.PCW_MIO_46_IOTYPE {<Select>} \
CONFIG.PCW_MIO_46_PULLUP {<Select>} \
CONFIG.PCW_MIO_46_SLEW {<Select>} \
CONFIG.PCW_MIO_47_DIRECTION {in} \
CONFIG.PCW_MIO_47_IOTYPE {LVCMOS 1.8V} \
CONFIG.PCW_MIO_47_PULLUP {enabled} \
CONFIG.PCW_MIO_47_SLEW {slow} \
CONFIG.PCW_MIO_48_DIRECTION {<Select>} \
CONFIG.PCW_MIO_48_IOTYPE {<Select>} \
CONFIG.PCW_MIO_48_PULLUP {<Select>} \
CONFIG.PCW_MIO_48_SLEW {<Select>} \
CONFIG.PCW_MIO_49_DIRECTION {<Select>} \
CONFIG.PCW_MIO_49_IOTYPE {<Select>} \
CONFIG.PCW_MIO_49_PULLUP {<Select>} \
CONFIG.PCW_MIO_49_SLEW {<Select>} \
CONFIG.PCW_MIO_4_DIRECTION {inout} \
CONFIG.PCW_MIO_4_IOTYPE {LVCMOS 3.3V} \
CONFIG.PCW_MIO_4_PULLUP {disabled} \
CONFIG.PCW_MIO_4_SLEW {slow} \
CONFIG.PCW_MIO_50_DIRECTION {<Select>} \
CONFIG.PCW_MIO_50_IOTYPE {<Select>} \
CONFIG.PCW_MIO_50_PULLUP {<Select>} \
CONFIG.PCW_MIO_50_SLEW {<Select>} \
CONFIG.PCW_MIO_51_DIRECTION {<Select>} \
CONFIG.PCW_MIO_51_IOTYPE {<Select>} \
CONFIG.PCW_MIO_51_PULLUP {<Select>} \
CONFIG.PCW_MIO_51_SLEW {<Select>} \
CONFIG.PCW_MIO_52_DIRECTION {out} \
CONFIG.PCW_MIO_52_IOTYPE {LVCMOS 1.8V} \
CONFIG.PCW_MIO_52_PULLUP {enabled} \
CONFIG.PCW_MIO_52_SLEW {slow} \
CONFIG.PCW_MIO_53_DIRECTION {inout} \
CONFIG.PCW_MIO_53_IOTYPE {LVCMOS 1.8V} \
CONFIG.PCW_MIO_53_PULLUP {enabled} \
CONFIG.PCW_MIO_53_SLEW {slow} \
CONFIG.PCW_MIO_5_DIRECTION {inout} \
CONFIG.PCW_MIO_5_IOTYPE {LVCMOS 3.3V} \
CONFIG.PCW_MIO_5_PULLUP {disabled} \
CONFIG.PCW_MIO_5_SLEW {slow} \
CONFIG.PCW_MIO_6_DIRECTION {out} \
CONFIG.PCW_MIO_6_IOTYPE {LVCMOS 3.3V} \
CONFIG.PCW_MIO_6_PULLUP {disabled} \
CONFIG.PCW_MIO_6_SLEW {slow} \
CONFIG.PCW_MIO_7_DIRECTION {<Select>} \
CONFIG.PCW_MIO_7_IOTYPE {<Select>} \
CONFIG.PCW_MIO_7_PULLUP {<Select>} \
CONFIG.PCW_MIO_7_SLEW {<Select>} \
CONFIG.PCW_MIO_8_DIRECTION {out} \
CONFIG.PCW_MIO_8_IOTYPE {LVCMOS 3.3V} \
CONFIG.PCW_MIO_8_PULLUP {disabled} \
CONFIG.PCW_MIO_8_SLEW {slow} \
CONFIG.PCW_MIO_9_DIRECTION {<Select>} \
CONFIG.PCW_MIO_9_IOTYPE {<Select>} \
CONFIG.PCW_MIO_9_PULLUP {<Select>} \
CONFIG.PCW_MIO_9_SLEW {<Select>} \
CONFIG.PCW_MIO_PRIMITIVE {54} \
CONFIG.PCW_MIO_TREE_PERIPHERALS {unassigned#Quad SPI Flash#Quad SPI Flash#Quad SPI Flash#Quad SPI Flash#Quad SPI Flash#Quad SPI Flash#unassigned#Quad SPI Flash#unassigned#unassigned#unassigned#unassigned#unassigned#UART 0#UART 0#Enet 0#Enet 0#Enet 0#Enet 0#Enet 0#Enet 0#Enet 0#Enet 0#Enet 0#Enet 0#Enet 0#Enet 0#USB 0#USB 0#USB 0#USB 0#USB 0#USB 0#USB 0#USB 0#USB 0#USB 0#USB 0#USB 0#SD 0#SD 0#SD 0#SD 0#SD 0#SD 0#unassigned#SD 0#unassigned#unassigned#unassigned#unassigned#Enet 0#Enet 0} \
CONFIG.PCW_MIO_TREE_SIGNALS {unassigned#qspi0_ss_b#qspi0_io[0]#qspi0_io[1]#qspi0_io[2]#qspi0_io[3]#qspi0_sclk#unassigned#qspi_fbclk#unassigned#unassigned#unassigned#unassigned#unassigned#rx#tx#tx_clk#txd[0]#txd[1]#txd[2]#txd[3]#tx_ctl#rx_clk#rxd[0]#rxd[1]#rxd[2]#rxd[3]#rx_ctl#data[4]#dir#stp#nxt#data[0]#data[1]#data[2]#data[3]#clk#data[5]#data[6]#data[7]#clk#cmd#data[0]#data[1]#data[2]#data[3]#unassigned#cd#unassigned#unassigned#unassigned#unassigned#mdc#mdio} \
CONFIG.PCW_M_AXI_GP0_ENABLE_STATIC_REMAP {0} \
CONFIG.PCW_M_AXI_GP0_FREQMHZ {10} \
CONFIG.PCW_M_AXI_GP0_ID_WIDTH {12} \
CONFIG.PCW_M_AXI_GP0_SUPPORT_NARROW_BURST {0} \
CONFIG.PCW_M_AXI_GP0_THREAD_ID_WIDTH {12} \
CONFIG.PCW_M_AXI_GP1_ENABLE_STATIC_REMAP {0} \
CONFIG.PCW_M_AXI_GP1_FREQMHZ {10} \
CONFIG.PCW_M_AXI_GP1_ID_WIDTH {12} \
CONFIG.PCW_M_AXI_GP1_SUPPORT_NARROW_BURST {0} \
CONFIG.PCW_M_AXI_GP1_THREAD_ID_WIDTH {12} \
CONFIG.PCW_NAND_CYCLES_T_AR {1} \
CONFIG.PCW_NAND_CYCLES_T_CLR {1} \
CONFIG.PCW_NAND_CYCLES_T_RC {11} \
CONFIG.PCW_NAND_CYCLES_T_REA {1} \
CONFIG.PCW_NAND_CYCLES_T_RR {1} \
CONFIG.PCW_NAND_CYCLES_T_WC {11} \
CONFIG.PCW_NAND_CYCLES_T_WP {1} \
CONFIG.PCW_NAND_GRP_D8_ENABLE {0} \
CONFIG.PCW_NAND_GRP_D8_IO {<Select>} \
CONFIG.PCW_NAND_NAND_IO {<Select>} \
CONFIG.PCW_NAND_PERIPHERAL_ENABLE {0} \
CONFIG.PCW_NOR_CS0_T_CEOE {1} \
CONFIG.PCW_NOR_CS0_T_PC {1} \
CONFIG.PCW_NOR_CS0_T_RC {11} \
CONFIG.PCW_NOR_CS0_T_TR {1} \
CONFIG.PCW_NOR_CS0_T_WC {11} \
CONFIG.PCW_NOR_CS0_T_WP {1} \
CONFIG.PCW_NOR_CS0_WE_TIME {0} \
CONFIG.PCW_NOR_CS1_T_CEOE {1} \
CONFIG.PCW_NOR_CS1_T_PC {1} \
CONFIG.PCW_NOR_CS1_T_RC {11} \
CONFIG.PCW_NOR_CS1_T_TR {1} \
CONFIG.PCW_NOR_CS1_T_WC {11} \
CONFIG.PCW_NOR_CS1_T_WP {1} \
CONFIG.PCW_NOR_CS1_WE_TIME {0} \
CONFIG.PCW_NOR_GRP_A25_ENABLE {0} \
CONFIG.PCW_NOR_GRP_A25_IO {<Select>} \
CONFIG.PCW_NOR_GRP_CS0_ENABLE {0} \
CONFIG.PCW_NOR_GRP_CS0_IO {<Select>} \
CONFIG.PCW_NOR_GRP_CS1_ENABLE {0} \
CONFIG.PCW_NOR_GRP_CS1_IO {<Select>} \
CONFIG.PCW_NOR_GRP_SRAM_CS0_ENABLE {0} \
CONFIG.PCW_NOR_GRP_SRAM_CS0_IO {<Select>} \
CONFIG.PCW_NOR_GRP_SRAM_CS1_ENABLE {0} \
CONFIG.PCW_NOR_GRP_SRAM_CS1_IO {<Select>} \
CONFIG.PCW_NOR_GRP_SRAM_INT_ENABLE {0} \
CONFIG.PCW_NOR_GRP_SRAM_INT_IO {<Select>} \
CONFIG.PCW_NOR_NOR_IO {<Select>} \
CONFIG.PCW_NOR_PERIPHERAL_ENABLE {0} \
CONFIG.PCW_NOR_SRAM_CS0_T_CEOE {1} \
CONFIG.PCW_NOR_SRAM_CS0_T_PC {1} \
CONFIG.PCW_NOR_SRAM_CS0_T_RC {11} \
CONFIG.PCW_NOR_SRAM_CS0_T_TR {1} \
CONFIG.PCW_NOR_SRAM_CS0_T_WC {11} \
CONFIG.PCW_NOR_SRAM_CS0_T_WP {1} \
CONFIG.PCW_NOR_SRAM_CS0_WE_TIME {0} \
CONFIG.PCW_NOR_SRAM_CS1_T_CEOE {1} \
CONFIG.PCW_NOR_SRAM_CS1_T_PC {1} \
CONFIG.PCW_NOR_SRAM_CS1_T_RC {11} \
CONFIG.PCW_NOR_SRAM_CS1_T_TR {1} \
CONFIG.PCW_NOR_SRAM_CS1_T_WC {11} \
CONFIG.PCW_NOR_SRAM_CS1_T_WP {1} \
CONFIG.PCW_NOR_SRAM_CS1_WE_TIME {0} \
CONFIG.PCW_OVERRIDE_BASIC_CLOCK {0} \
CONFIG.PCW_P2F_CAN0_INTR {0} \
CONFIG.PCW_P2F_CAN1_INTR {0} \
CONFIG.PCW_P2F_CTI_INTR {0} \
CONFIG.PCW_P2F_DMAC0_INTR {0} \
CONFIG.PCW_P2F_DMAC1_INTR {0} \
CONFIG.PCW_P2F_DMAC2_INTR {0} \
CONFIG.PCW_P2F_DMAC3_INTR {0} \
CONFIG.PCW_P2F_DMAC4_INTR {0} \
CONFIG.PCW_P2F_DMAC5_INTR {0} \
CONFIG.PCW_P2F_DMAC6_INTR {0} \
CONFIG.PCW_P2F_DMAC7_INTR {0} \
CONFIG.PCW_P2F_DMAC_ABORT_INTR {0} \
CONFIG.PCW_P2F_ENET0_INTR {0} \
CONFIG.PCW_P2F_ENET1_INTR {0} \
CONFIG.PCW_P2F_GPIO_INTR {0} \
CONFIG.PCW_P2F_I2C0_INTR {0} \
CONFIG.PCW_P2F_I2C1_INTR {0} \
CONFIG.PCW_P2F_QSPI_INTR {0} \
CONFIG.PCW_P2F_SDIO0_INTR {0} \
CONFIG.PCW_P2F_SDIO1_INTR {0} \
CONFIG.PCW_P2F_SMC_INTR {0} \
CONFIG.PCW_P2F_SPI0_INTR {0} \
CONFIG.PCW_P2F_SPI1_INTR {0} \
CONFIG.PCW_P2F_UART0_INTR {0} \
CONFIG.PCW_P2F_UART1_INTR {0} \
CONFIG.PCW_P2F_USB0_INTR {0} \
CONFIG.PCW_P2F_USB1_INTR {0} \
CONFIG.PCW_PACKAGE_DDR_BOARD_DELAY0 {0.223} \
CONFIG.PCW_PACKAGE_DDR_BOARD_DELAY1 {0.212} \
CONFIG.PCW_PACKAGE_DDR_BOARD_DELAY2 {0.085} \
CONFIG.PCW_PACKAGE_DDR_BOARD_DELAY3 {0.092} \
CONFIG.PCW_PACKAGE_DDR_DQS_TO_CLK_DELAY_0 {0.040} \
CONFIG.PCW_PACKAGE_DDR_DQS_TO_CLK_DELAY_1 {0.058} \
CONFIG.PCW_PACKAGE_DDR_DQS_TO_CLK_DELAY_2 {-0.009} \
CONFIG.PCW_PACKAGE_DDR_DQS_TO_CLK_DELAY_3 {-0.033} \
CONFIG.PCW_PACKAGE_NAME {clg400} \
CONFIG.PCW_PCAP_PERIPHERAL_CLKSRC {IO PLL} \
CONFIG.PCW_PCAP_PERIPHERAL_DIVISOR0 {5} \
CONFIG.PCW_PCAP_PERIPHERAL_FREQMHZ {200} \
CONFIG.PCW_PERIPHERAL_BOARD_PRESET {None} \
CONFIG.PCW_PJTAG_PERIPHERAL_ENABLE {0} \
CONFIG.PCW_PJTAG_PJTAG_IO {<Select>} \
CONFIG.PCW_PLL_BYPASSMODE_ENABLE {0} \
CONFIG.PCW_PRESET_BANK0_VOLTAGE {LVCMOS 3.3V} \
CONFIG.PCW_PRESET_BANK1_VOLTAGE {LVCMOS 1.8V} \
CONFIG.PCW_PS7_SI_REV {PRODUCTION} \
CONFIG.PCW_QSPI_GRP_FBCLK_ENABLE {1} \
CONFIG.PCW_QSPI_GRP_FBCLK_IO {MIO 8} \
CONFIG.PCW_QSPI_GRP_IO1_ENABLE {0} \
CONFIG.PCW_QSPI_GRP_IO1_IO {<Select>} \
CONFIG.PCW_QSPI_GRP_SINGLE_SS_ENABLE {1} \
CONFIG.PCW_QSPI_GRP_SINGLE_SS_IO {MIO 1 .. 6} \
CONFIG.PCW_QSPI_GRP_SS1_ENABLE {0} \
CONFIG.PCW_QSPI_GRP_SS1_IO {<Select>} \
CONFIG.PCW_QSPI_INTERNAL_HIGHADDRESS {0xFCFFFFFF} \
CONFIG.PCW_QSPI_PERIPHERAL_CLKSRC {IO PLL} \
CONFIG.PCW_QSPI_PERIPHERAL_DIVISOR0 {5} \
CONFIG.PCW_QSPI_PERIPHERAL_ENABLE {1} \
CONFIG.PCW_QSPI_PERIPHERAL_FREQMHZ {200} \
CONFIG.PCW_QSPI_QSPI_IO {MIO 1 .. 6} \
CONFIG.PCW_SD0_GRP_CD_ENABLE {1} \
CONFIG.PCW_SD0_GRP_CD_IO {MIO 47} \
CONFIG.PCW_SD0_GRP_POW_ENABLE {0} \
CONFIG.PCW_SD0_GRP_POW_IO {<Select>} \
CONFIG.PCW_SD0_GRP_WP_ENABLE {0} \
CONFIG.PCW_SD0_GRP_WP_IO {<Select>} \
CONFIG.PCW_SD0_PERIPHERAL_ENABLE {1} \
CONFIG.PCW_SD0_SD0_IO {MIO 40 .. 45} \
CONFIG.PCW_SD1_GRP_CD_ENABLE {0} \
CONFIG.PCW_SD1_GRP_CD_IO {<Select>} \
CONFIG.PCW_SD1_GRP_POW_ENABLE {0} \
CONFIG.PCW_SD1_GRP_POW_IO {<Select>} \
CONFIG.PCW_SD1_GRP_WP_ENABLE {0} \
CONFIG.PCW_SD1_GRP_WP_IO {<Select>} \
CONFIG.PCW_SD1_PERIPHERAL_ENABLE {0} \
CONFIG.PCW_SD1_SD1_IO {<Select>} \
CONFIG.PCW_SDIO0_BASEADDR {0xE0100000} \
CONFIG.PCW_SDIO0_HIGHADDR {0xE0100FFF} \
CONFIG.PCW_SDIO1_BASEADDR {0xE0101000} \
CONFIG.PCW_SDIO1_HIGHADDR {0xE0101FFF} \
CONFIG.PCW_SDIO_PERIPHERAL_CLKSRC {IO PLL} \
CONFIG.PCW_SDIO_PERIPHERAL_DIVISOR0 {20} \
CONFIG.PCW_SDIO_PERIPHERAL_FREQMHZ {50} \
CONFIG.PCW_SDIO_PERIPHERAL_VALID {1} \
CONFIG.PCW_SMC_CYCLE_T0 {NA} \
CONFIG.PCW_SMC_CYCLE_T1 {NA} \
CONFIG.PCW_SMC_CYCLE_T2 {NA} \
CONFIG.PCW_SMC_CYCLE_T3 {NA} \
CONFIG.PCW_SMC_CYCLE_T4 {NA} \
CONFIG.PCW_SMC_CYCLE_T5 {NA} \
CONFIG.PCW_SMC_CYCLE_T6 {NA} \
CONFIG.PCW_SMC_PERIPHERAL_CLKSRC {IO PLL} \
CONFIG.PCW_SMC_PERIPHERAL_DIVISOR0 {1} \
CONFIG.PCW_SMC_PERIPHERAL_FREQMHZ {100} \
CONFIG.PCW_SMC_PERIPHERAL_VALID {0} \
CONFIG.PCW_SPI0_BASEADDR {0xE0006000} \
CONFIG.PCW_SPI0_GRP_SS0_ENABLE {0} \
CONFIG.PCW_SPI0_GRP_SS0_IO {<Select>} \
CONFIG.PCW_SPI0_GRP_SS1_ENABLE {0} \
CONFIG.PCW_SPI0_GRP_SS1_IO {<Select>} \
CONFIG.PCW_SPI0_GRP_SS2_ENABLE {0} \
CONFIG.PCW_SPI0_GRP_SS2_IO {<Select>} \
CONFIG.PCW_SPI0_HIGHADDR {0xE0006FFF} \
CONFIG.PCW_SPI0_PERIPHERAL_ENABLE {0} \
CONFIG.PCW_SPI0_SPI0_IO {<Select>} \
CONFIG.PCW_SPI1_BASEADDR {0xE0007000} \
CONFIG.PCW_SPI1_GRP_SS0_ENABLE {0} \
CONFIG.PCW_SPI1_GRP_SS0_IO {<Select>} \
CONFIG.PCW_SPI1_GRP_SS1_ENABLE {0} \
CONFIG.PCW_SPI1_GRP_SS1_IO {<Select>} \
CONFIG.PCW_SPI1_GRP_SS2_ENABLE {0} \
CONFIG.PCW_SPI1_GRP_SS2_IO {<Select>} \
CONFIG.PCW_SPI1_HIGHADDR {0xE0007FFF} \
CONFIG.PCW_SPI1_PERIPHERAL_ENABLE {0} \
CONFIG.PCW_SPI1_SPI1_IO {<Select>} \
CONFIG.PCW_SPI_PERIPHERAL_CLKSRC {IO PLL} \
CONFIG.PCW_SPI_PERIPHERAL_DIVISOR0 {1} \
CONFIG.PCW_SPI_PERIPHERAL_FREQMHZ {166.666666} \
CONFIG.PCW_SPI_PERIPHERAL_VALID {0} \
CONFIG.PCW_S_AXI_ACP_ARUSER_VAL {31} \
CONFIG.PCW_S_AXI_ACP_AWUSER_VAL {31} \
CONFIG.PCW_S_AXI_ACP_FREQMHZ {10} \
CONFIG.PCW_S_AXI_ACP_ID_WIDTH {3} \
CONFIG.PCW_S_AXI_GP0_FREQMHZ {10} \
CONFIG.PCW_S_AXI_GP0_ID_WIDTH {6} \
CONFIG.PCW_S_AXI_GP1_FREQMHZ {10} \
CONFIG.PCW_S_AXI_GP1_ID_WIDTH {6} \
CONFIG.PCW_S_AXI_HP0_DATA_WIDTH {64} \
CONFIG.PCW_S_AXI_HP0_FREQMHZ {10} \
CONFIG.PCW_S_AXI_HP0_ID_WIDTH {6} \
CONFIG.PCW_S_AXI_HP1_DATA_WIDTH {64} \
CONFIG.PCW_S_AXI_HP1_FREQMHZ {10} \
CONFIG.PCW_S_AXI_HP1_ID_WIDTH {6} \
CONFIG.PCW_S_AXI_HP2_DATA_WIDTH {64} \
CONFIG.PCW_S_AXI_HP2_FREQMHZ {10} \
CONFIG.PCW_S_AXI_HP2_ID_WIDTH {6} \
CONFIG.PCW_S_AXI_HP3_DATA_WIDTH {64} \
CONFIG.PCW_S_AXI_HP3_FREQMHZ {10} \
CONFIG.PCW_S_AXI_HP3_ID_WIDTH {6} \
CONFIG.PCW_TPIU_PERIPHERAL_CLKSRC {External} \
CONFIG.PCW_TPIU_PERIPHERAL_DIVISOR0 {1} \
CONFIG.PCW_TPIU_PERIPHERAL_FREQMHZ {200} \
CONFIG.PCW_TRACE_BUFFER_CLOCK_DELAY {12} \
CONFIG.PCW_TRACE_BUFFER_FIFO_SIZE {128} \
CONFIG.PCW_TRACE_GRP_16BIT_ENABLE {0} \
CONFIG.PCW_TRACE_GRP_16BIT_IO {<Select>} \
CONFIG.PCW_TRACE_GRP_2BIT_ENABLE {0} \
CONFIG.PCW_TRACE_GRP_2BIT_IO {<Select>} \
CONFIG.PCW_TRACE_GRP_32BIT_ENABLE {0} \
CONFIG.PCW_TRACE_GRP_32BIT_IO {<Select>} \
CONFIG.PCW_TRACE_GRP_4BIT_ENABLE {0} \
CONFIG.PCW_TRACE_GRP_4BIT_IO {<Select>} \
CONFIG.PCW_TRACE_GRP_8BIT_ENABLE {0} \
CONFIG.PCW_TRACE_GRP_8BIT_IO {<Select>} \
CONFIG.PCW_TRACE_INTERNAL_WIDTH {2} \
CONFIG.PCW_TRACE_PERIPHERAL_ENABLE {0} \
CONFIG.PCW_TRACE_PIPELINE_WIDTH {8} \
CONFIG.PCW_TRACE_TRACE_IO {<Select>} \
CONFIG.PCW_TTC0_BASEADDR {0xE0104000} \
CONFIG.PCW_TTC0_CLK0_PERIPHERAL_CLKSRC {CPU_1X} \
CONFIG.PCW_TTC0_CLK0_PERIPHERAL_DIVISOR0 {1} \
CONFIG.PCW_TTC0_CLK0_PERIPHERAL_FREQMHZ {133.333333} \
CONFIG.PCW_TTC0_CLK1_PERIPHERAL_CLKSRC {CPU_1X} \
CONFIG.PCW_TTC0_CLK1_PERIPHERAL_DIVISOR0 {1} \
CONFIG.PCW_TTC0_CLK1_PERIPHERAL_FREQMHZ {133.333333} \
CONFIG.PCW_TTC0_CLK2_PERIPHERAL_CLKSRC {CPU_1X} \
CONFIG.PCW_TTC0_CLK2_PERIPHERAL_DIVISOR0 {1} \
CONFIG.PCW_TTC0_CLK2_PERIPHERAL_FREQMHZ {133.333333} \
CONFIG.PCW_TTC0_HIGHADDR {0xE0104fff} \
CONFIG.PCW_TTC0_PERIPHERAL_ENABLE {0} \
CONFIG.PCW_TTC0_TTC0_IO {<Select>} \
CONFIG.PCW_TTC1_BASEADDR {0xE0105000} \
CONFIG.PCW_TTC1_CLK0_PERIPHERAL_CLKSRC {CPU_1X} \
CONFIG.PCW_TTC1_CLK0_PERIPHERAL_DIVISOR0 {1} \
CONFIG.PCW_TTC1_CLK0_PERIPHERAL_FREQMHZ {133.333333} \
CONFIG.PCW_TTC1_CLK1_PERIPHERAL_CLKSRC {CPU_1X} \
CONFIG.PCW_TTC1_CLK1_PERIPHERAL_DIVISOR0 {1} \
CONFIG.PCW_TTC1_CLK1_PERIPHERAL_FREQMHZ {133.333333} \
CONFIG.PCW_TTC1_CLK2_PERIPHERAL_CLKSRC {CPU_1X} \
CONFIG.PCW_TTC1_CLK2_PERIPHERAL_DIVISOR0 {1} \
CONFIG.PCW_TTC1_CLK2_PERIPHERAL_FREQMHZ {133.333333} \
CONFIG.PCW_TTC1_HIGHADDR {0xE0105fff} \
CONFIG.PCW_TTC1_PERIPHERAL_ENABLE {0} \
CONFIG.PCW_TTC1_TTC1_IO {<Select>} \
CONFIG.PCW_TTC_PERIPHERAL_FREQMHZ {50} \
CONFIG.PCW_UART0_BASEADDR {0xE0000000} \
CONFIG.PCW_UART0_BAUD_RATE {115200} \
CONFIG.PCW_UART0_GRP_FULL_ENABLE {0} \
CONFIG.PCW_UART0_GRP_FULL_IO {<Select>} \
CONFIG.PCW_UART0_HIGHADDR {0xE0000FFF} \
CONFIG.PCW_UART0_PERIPHERAL_ENABLE {1} \
CONFIG.PCW_UART0_UART0_IO {MIO 14 .. 15} \
CONFIG.PCW_UART1_BASEADDR {0xE0001000} \
CONFIG.PCW_UART1_BAUD_RATE {115200} \
CONFIG.PCW_UART1_GRP_FULL_ENABLE {0} \
CONFIG.PCW_UART1_GRP_FULL_IO {<Select>} \
CONFIG.PCW_UART1_HIGHADDR {0xE0001FFF} \
CONFIG.PCW_UART1_PERIPHERAL_ENABLE {0} \
CONFIG.PCW_UART1_UART1_IO {<Select>} \
CONFIG.PCW_UART_PERIPHERAL_CLKSRC {IO PLL} \
CONFIG.PCW_UART_PERIPHERAL_DIVISOR0 {10} \
CONFIG.PCW_UART_PERIPHERAL_FREQMHZ {100} \
CONFIG.PCW_UART_PERIPHERAL_VALID {1} \
CONFIG.PCW_UIPARAM_ACT_DDR_FREQ_MHZ {525.000000} \
CONFIG.PCW_UIPARAM_DDR_ADV_ENABLE {0} \
CONFIG.PCW_UIPARAM_DDR_AL {0} \
CONFIG.PCW_UIPARAM_DDR_BANK_ADDR_COUNT {3} \
CONFIG.PCW_UIPARAM_DDR_BL {8} \
CONFIG.PCW_UIPARAM_DDR_BOARD_DELAY0 {0.223} \
CONFIG.PCW_UIPARAM_DDR_BOARD_DELAY1 {0.212} \
CONFIG.PCW_UIPARAM_DDR_BOARD_DELAY2 {0.085} \
CONFIG.PCW_UIPARAM_DDR_BOARD_DELAY3 {0.092} \
CONFIG.PCW_UIPARAM_DDR_BUS_WIDTH {16 Bit} \
CONFIG.PCW_UIPARAM_DDR_CL {7} \
CONFIG.PCW_UIPARAM_DDR_CLOCK_0_LENGTH_MM {25.8} \
CONFIG.PCW_UIPARAM_DDR_CLOCK_0_PACKAGE_LENGTH {80.4535} \
CONFIG.PCW_UIPARAM_DDR_CLOCK_0_PROPOGATION_DELAY {160} \
CONFIG.PCW_UIPARAM_DDR_CLOCK_1_LENGTH_MM {25.8} \
CONFIG.PCW_UIPARAM_DDR_CLOCK_1_PACKAGE_LENGTH {80.4535} \
CONFIG.PCW_UIPARAM_DDR_CLOCK_1_PROPOGATION_DELAY {160} \
CONFIG.PCW_UIPARAM_DDR_CLOCK_2_LENGTH_MM {0} \
CONFIG.PCW_UIPARAM_DDR_CLOCK_2_PACKAGE_LENGTH {80.4535} \
CONFIG.PCW_UIPARAM_DDR_CLOCK_2_PROPOGATION_DELAY {160} \
CONFIG.PCW_UIPARAM_DDR_CLOCK_3_LENGTH_MM {0} \
CONFIG.PCW_UIPARAM_DDR_CLOCK_3_PACKAGE_LENGTH {80.4535} \
CONFIG.PCW_UIPARAM_DDR_CLOCK_3_PROPOGATION_DELAY {160} \
CONFIG.PCW_UIPARAM_DDR_CLOCK_STOP_EN {0} \
CONFIG.PCW_UIPARAM_DDR_COL_ADDR_COUNT {10} \
CONFIG.PCW_UIPARAM_DDR_CWL {6} \
CONFIG.PCW_UIPARAM_DDR_DEVICE_CAPACITY {4096 MBits} \
CONFIG.PCW_UIPARAM_DDR_DQS_0_LENGTH_MM {15.6} \
CONFIG.PCW_UIPARAM_DDR_DQS_0_PACKAGE_LENGTH {105.056} \
CONFIG.PCW_UIPARAM_DDR_DQS_0_PROPOGATION_DELAY {160} \
CONFIG.PCW_UIPARAM_DDR_DQS_1_LENGTH_MM {18.8} \
CONFIG.PCW_UIPARAM_DDR_DQS_1_PACKAGE_LENGTH {66.904} \
CONFIG.PCW_UIPARAM_DDR_DQS_1_PROPOGATION_DELAY {160} \
CONFIG.PCW_UIPARAM_DDR_DQS_2_LENGTH_MM {0} \
CONFIG.PCW_UIPARAM_DDR_DQS_2_PACKAGE_LENGTH {89.1715} \
CONFIG.PCW_UIPARAM_DDR_DQS_2_PROPOGATION_DELAY {160} \
CONFIG.PCW_UIPARAM_DDR_DQS_3_LENGTH_MM {0} \
CONFIG.PCW_UIPARAM_DDR_DQS_3_PACKAGE_LENGTH {113.63} \
CONFIG.PCW_UIPARAM_DDR_DQS_3_PROPOGATION_DELAY {160} \
CONFIG.PCW_UIPARAM_DDR_DQS_TO_CLK_DELAY_0 {0.040} \
CONFIG.PCW_UIPARAM_DDR_DQS_TO_CLK_DELAY_1 {0.058} \
CONFIG.PCW_UIPARAM_DDR_DQS_TO_CLK_DELAY_2 {-0.009} \
CONFIG.PCW_UIPARAM_DDR_DQS_TO_CLK_DELAY_3 {-0.033} \
CONFIG.PCW_UIPARAM_DDR_DQ_0_LENGTH_MM {16.5} \
CONFIG.PCW_UIPARAM_DDR_DQ_0_PACKAGE_LENGTH {98.503} \
CONFIG.PCW_UIPARAM_DDR_DQ_0_PROPOGATION_DELAY {160} \
CONFIG.PCW_UIPARAM_DDR_DQ_1_LENGTH_MM {18} \
CONFIG.PCW_UIPARAM_DDR_DQ_1_PACKAGE_LENGTH {68.5855} \
CONFIG.PCW_UIPARAM_DDR_DQ_1_PROPOGATION_DELAY {160} \
CONFIG.PCW_UIPARAM_DDR_DQ_2_LENGTH_MM {0} \
CONFIG.PCW_UIPARAM_DDR_DQ_2_PACKAGE_LENGTH {90.295} \
CONFIG.PCW_UIPARAM_DDR_DQ_2_PROPOGATION_DELAY {160} \
CONFIG.PCW_UIPARAM_DDR_DQ_3_LENGTH_MM {0} \
CONFIG.PCW_UIPARAM_DDR_DQ_3_PACKAGE_LENGTH {103.977} \
CONFIG.PCW_UIPARAM_DDR_DQ_3_PROPOGATION_DELAY {160} \
CONFIG.PCW_UIPARAM_DDR_DRAM_WIDTH {16 Bits} \
CONFIG.PCW_UIPARAM_DDR_ECC {Disabled} \
CONFIG.PCW_UIPARAM_DDR_ENABLE {1} \
CONFIG.PCW_UIPARAM_DDR_FREQ_MHZ {525} \
CONFIG.PCW_UIPARAM_DDR_HIGH_TEMP {Normal (0-85)} \
CONFIG.PCW_UIPARAM_DDR_MEMORY_TYPE {DDR 3} \
CONFIG.PCW_UIPARAM_DDR_PARTNO {Custom} \
CONFIG.PCW_UIPARAM_DDR_ROW_ADDR_COUNT {15} \
CONFIG.PCW_UIPARAM_DDR_SPEED_BIN {DDR3_1066F} \
CONFIG.PCW_UIPARAM_DDR_TRAIN_DATA_EYE {1} \
CONFIG.PCW_UIPARAM_DDR_TRAIN_READ_GATE {1} \
CONFIG.PCW_UIPARAM_DDR_TRAIN_WRITE_LEVEL {1} \
CONFIG.PCW_UIPARAM_DDR_T_FAW {40.0} \
CONFIG.PCW_UIPARAM_DDR_T_RAS_MIN {35.0} \
CONFIG.PCW_UIPARAM_DDR_T_RC {50.625} \
CONFIG.PCW_UIPARAM_DDR_T_RCD {13.125} \
CONFIG.PCW_UIPARAM_DDR_T_RP {13.125} \
CONFIG.PCW_UIPARAM_DDR_USE_INTERNAL_VREF {0} \
CONFIG.PCW_UIPARAM_GENERATE_SUMMARY {NA} \
CONFIG.PCW_USB0_BASEADDR {0xE0102000} \
CONFIG.PCW_USB0_HIGHADDR {0xE0102fff} \
CONFIG.PCW_USB0_PERIPHERAL_ENABLE {1} \
CONFIG.PCW_USB0_PERIPHERAL_FREQMHZ {60} \
CONFIG.PCW_USB0_RESET_ENABLE {0} \
CONFIG.PCW_USB0_RESET_IO {<Select>} \
CONFIG.PCW_USB0_USB0_IO {MIO 28 .. 39} \
CONFIG.PCW_USB1_BASEADDR {0xE0103000} \
CONFIG.PCW_USB1_HIGHADDR {0xE0103fff} \
CONFIG.PCW_USB1_PERIPHERAL_ENABLE {0} \
CONFIG.PCW_USB1_PERIPHERAL_FREQMHZ {60} \
CONFIG.PCW_USB1_RESET_ENABLE {0} \
CONFIG.PCW_USB1_RESET_IO {<Select>} \
CONFIG.PCW_USB1_USB1_IO {<Select>} \
CONFIG.PCW_USB_RESET_ENABLE {0} \
CONFIG.PCW_USB_RESET_POLARITY {Active Low} \
CONFIG.PCW_USB_RESET_SELECT {<Select>} \
CONFIG.PCW_USE_AXI_FABRIC_IDLE {0} \
CONFIG.PCW_USE_AXI_NONSECURE {0} \
CONFIG.PCW_USE_CORESIGHT {0} \
CONFIG.PCW_USE_CROSS_TRIGGER {0} \
CONFIG.PCW_USE_CR_FABRIC {1} \
CONFIG.PCW_USE_DDR_BYPASS {0} \
CONFIG.PCW_USE_DEBUG {0} \
CONFIG.PCW_USE_DEFAULT_ACP_USER_VAL {0} \
CONFIG.PCW_USE_DMA0 {0} \
CONFIG.PCW_USE_DMA1 {0} \
CONFIG.PCW_USE_DMA2 {0} \
CONFIG.PCW_USE_DMA3 {0} \
CONFIG.PCW_USE_EXPANDED_IOP {0} \
CONFIG.PCW_USE_EXPANDED_PS_SLCR_REGISTERS {0} \
CONFIG.PCW_USE_FABRIC_INTERRUPT {1} \
CONFIG.PCW_USE_HIGH_OCM {0} \
CONFIG.PCW_USE_M_AXI_GP0 {1} \
CONFIG.PCW_USE_M_AXI_GP1 {1} \
CONFIG.PCW_USE_PROC_EVENT_BUS {0} \
CONFIG.PCW_USE_PS_SLCR_REGISTERS {0} \
CONFIG.PCW_USE_S_AXI_ACP {0} \
CONFIG.PCW_USE_S_AXI_GP0 {1} \
CONFIG.PCW_USE_S_AXI_GP1 {0} \
CONFIG.PCW_USE_S_AXI_HP0 {1} \
CONFIG.PCW_USE_S_AXI_HP1 {0} \
CONFIG.PCW_USE_S_AXI_HP2 {1} \
CONFIG.PCW_USE_S_AXI_HP3 {0} \
CONFIG.PCW_USE_TRACE {0} \
CONFIG.PCW_USE_TRACE_DATA_EDGE_DETECTOR {0} \
CONFIG.PCW_VALUE_SILVERSION {3} \
CONFIG.PCW_WDT_PERIPHERAL_CLKSRC {CPU_1X} \
CONFIG.PCW_WDT_PERIPHERAL_DIVISOR0 {1} \
CONFIG.PCW_WDT_PERIPHERAL_ENABLE {0} \
CONFIG.PCW_WDT_PERIPHERAL_FREQMHZ {133.333333} \
CONFIG.PCW_WDT_WDT_IO {<Select>} \
 ] $processing_system7_0

  # Create instance: processing_system7_0_axi_periph, and set properties
  set processing_system7_0_axi_periph [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_interconnect:2.1 processing_system7_0_axi_periph ]
  set_property -dict [ list \
CONFIG.NUM_MI {14} \
 ] $processing_system7_0_axi_periph

  # Create instance: processing_system7_0_axi_periph_1, and set properties
  set processing_system7_0_axi_periph_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_interconnect:2.1 processing_system7_0_axi_periph_1 ]
  set_property -dict [ list \
CONFIG.NUM_MI {4} \
 ] $processing_system7_0_axi_periph_1

  # Create instance: rgbleds_gpio, and set properties
  set rgbleds_gpio [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_gpio:2.0 rgbleds_gpio ]
  set_property -dict [ list \
CONFIG.C_ALL_OUTPUTS {1} \
CONFIG.C_GPIO_WIDTH {6} \
 ] $rgbleds_gpio

  # Create instance: rst_processing_system7_0_100M, and set properties
  set rst_processing_system7_0_100M [ create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset:5.0 rst_processing_system7_0_100M ]

  # Create instance: rst_processing_system7_0_166M, and set properties
  set rst_processing_system7_0_166M [ create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset:5.0 rst_processing_system7_0_166M ]

  # Create instance: swsleds_gpio, and set properties
  set swsleds_gpio [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_gpio:2.0 swsleds_gpio ]
  set_property -dict [ list \
CONFIG.C_ALL_INPUTS {1} \
CONFIG.C_ALL_OUTPUTS_2 {1} \
CONFIG.C_GPIO2_WIDTH {4} \
CONFIG.C_GPIO_WIDTH {2} \
CONFIG.C_INTERRUPT_PRESENT {1} \
CONFIG.C_IS_DUAL {1} \
 ] $swsleds_gpio

  # Create instance: system_interrupts, and set properties
  set system_interrupts [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_intc:4.1 system_interrupts ]

  # Create instance: tracebuffer_arduino
  create_hier_cell_tracebuffer_arduino [current_bd_instance .] tracebuffer_arduino

  # Create instance: tracebuffer_pmods
  create_hier_cell_tracebuffer_pmods [current_bd_instance .] tracebuffer_pmods

  # Create instance: video
  create_hier_cell_video [current_bd_instance .] video

  # Create interface connections
  connect_bd_intf_net -intf_net S00_AXI_2 [get_bd_intf_pins axi_interconnect_0/S00_AXI] [get_bd_intf_pins iop1/M07_AXI]
  connect_bd_intf_net -intf_net S01_AXI_1 [get_bd_intf_pins axi_mem_intercon/S01_AXI] [get_bd_intf_pins tracebuffer_arduino/M_AXI_S2MM]
  connect_bd_intf_net -intf_net S01_AXI_2 [get_bd_intf_pins axi_interconnect_0/S01_AXI] [get_bd_intf_pins iop2/M07_AXI]
  connect_bd_intf_net -intf_net S02_AXI_1 [get_bd_intf_pins axi_interconnect_0/S02_AXI] [get_bd_intf_pins iop3/M18_AXI]
  connect_bd_intf_net -intf_net S_AXI1_1 [get_bd_intf_pins processing_system7_0_axi_periph/M06_AXI] [get_bd_intf_pins video/S_AXI1]
  connect_bd_intf_net -intf_net S_AXI_1 [get_bd_intf_pins processing_system7_0_axi_periph/M05_AXI] [get_bd_intf_pins video/S_AXI]
  connect_bd_intf_net -intf_net S_AXI_LITE_1 [get_bd_intf_pins processing_system7_0_axi_periph/M10_AXI] [get_bd_intf_pins video/S_AXI_LITE]
  connect_bd_intf_net -intf_net Vaux0_1 [get_bd_intf_ports Vaux0] [get_bd_intf_pins iop3/Vaux0]
  connect_bd_intf_net -intf_net Vaux12_1 [get_bd_intf_ports Vaux12] [get_bd_intf_pins iop3/Vaux12]
  connect_bd_intf_net -intf_net Vaux13_1 [get_bd_intf_ports Vaux13] [get_bd_intf_pins iop3/Vaux13]
  connect_bd_intf_net -intf_net Vaux15_1 [get_bd_intf_ports Vaux15] [get_bd_intf_pins iop3/Vaux15]
  connect_bd_intf_net -intf_net Vaux1_1 [get_bd_intf_ports Vaux1] [get_bd_intf_pins iop3/Vaux1]
  connect_bd_intf_net -intf_net Vaux5_1 [get_bd_intf_ports Vaux5] [get_bd_intf_pins iop3/Vaux5]
  connect_bd_intf_net -intf_net Vaux6_1 [get_bd_intf_ports Vaux6] [get_bd_intf_pins iop3/Vaux6]
  connect_bd_intf_net -intf_net Vaux8_1 [get_bd_intf_ports Vaux8] [get_bd_intf_pins iop3/Vaux8]
  connect_bd_intf_net -intf_net Vaux9_1 [get_bd_intf_ports Vaux9] [get_bd_intf_pins iop3/Vaux9]
  connect_bd_intf_net -intf_net Vp_Vn_1 [get_bd_intf_ports Vp_Vn] [get_bd_intf_pins iop3/Vp_Vn]
  connect_bd_intf_net -intf_net axi_dma_0_M_AXI_S2MM [get_bd_intf_pins axi_mem_intercon/S00_AXI] [get_bd_intf_pins tracebuffer_pmods/M_AXI_S2MM]
  connect_bd_intf_net -intf_net axi_interconnect_0_M00_AXI [get_bd_intf_pins axi_interconnect_0/M00_AXI] [get_bd_intf_pins processing_system7_0/S_AXI_GP0]
  connect_bd_intf_net -intf_net axi_mem_intercon_M00_AXI [get_bd_intf_pins processing_system7_0/S_AXI_HP0] [get_bd_intf_pins video/M00_AXI]
  connect_bd_intf_net -intf_net axi_mem_intercon_M00_AXI1 [get_bd_intf_pins axi_mem_intercon/M00_AXI] [get_bd_intf_pins processing_system7_0/S_AXI_HP2]
  connect_bd_intf_net -intf_net btns_gpio_GPIO [get_bd_intf_ports btns_4bits] [get_bd_intf_pins btns_gpio/GPIO]
  connect_bd_intf_net -intf_net ctrl1_1 [get_bd_intf_pins processing_system7_0_axi_periph/M09_AXI] [get_bd_intf_pins video/ctrl1]
  connect_bd_intf_net -intf_net ctrl_1 [get_bd_intf_pins processing_system7_0_axi_periph/M08_AXI] [get_bd_intf_pins video/ctrl]
  connect_bd_intf_net -intf_net dvi2rgb_0_DDC [get_bd_intf_ports hdmi_in_ddc] [get_bd_intf_pins video/DDC]
  connect_bd_intf_net -intf_net hdmi_in_1 [get_bd_intf_ports hdmi_in] [get_bd_intf_pins video/TMDS]
  connect_bd_intf_net -intf_net iop3_GPIO [get_bd_intf_ports ck_gpio] [get_bd_intf_pins iop3/ck_io]
  connect_bd_intf_net -intf_net iop3_spi_sw_shield [get_bd_intf_ports spi_sw_shield] [get_bd_intf_pins iop3/spi_sw_shield]
  connect_bd_intf_net -intf_net mb_bram_ctrl_1_BRAM_PORTA [get_bd_intf_pins iop1/BRAM_PORTB] [get_bd_intf_pins mb_bram_ctrl_1/BRAM_PORTA]
  connect_bd_intf_net -intf_net mb_bram_ctrl_2_BRAM_PORTA [get_bd_intf_pins iop2/BRAM_PORTB] [get_bd_intf_pins mb_bram_ctrl_2/BRAM_PORTA]
  connect_bd_intf_net -intf_net mb_bram_ctrl_3_BRAM_PORTA [get_bd_intf_pins iop3/BRAM_PORTB] [get_bd_intf_pins mb_bram_ctrl_3/BRAM_PORTA]
  connect_bd_intf_net -intf_net mdm_1_MBDEBUG_1 [get_bd_intf_pins iop2/DEBUG] [get_bd_intf_pins mdm_1/MBDEBUG_1]
  connect_bd_intf_net -intf_net mdm_1_MBDEBUG_2 [get_bd_intf_pins iop3/DEBUG] [get_bd_intf_pins mdm_1/MBDEBUG_2]
  connect_bd_intf_net -intf_net microblaze_0_debug [get_bd_intf_pins iop1/DEBUG] [get_bd_intf_pins mdm_1/MBDEBUG_0]
  connect_bd_intf_net -intf_net processing_system7_0_DDR [get_bd_intf_ports DDR] [get_bd_intf_pins processing_system7_0/DDR]
  connect_bd_intf_net -intf_net processing_system7_0_FIXED_IO [get_bd_intf_ports FIXED_IO] [get_bd_intf_pins processing_system7_0/FIXED_IO]
  connect_bd_intf_net -intf_net processing_system7_0_IIC_0 [get_bd_intf_ports hdmi_out_ddc] [get_bd_intf_pins processing_system7_0/IIC_0]
  connect_bd_intf_net -intf_net processing_system7_0_M_AXI_GP0 [get_bd_intf_pins processing_system7_0/M_AXI_GP0] [get_bd_intf_pins processing_system7_0_axi_periph/S00_AXI]
  connect_bd_intf_net -intf_net processing_system7_0_M_AXI_GP1 [get_bd_intf_pins processing_system7_0/M_AXI_GP1] [get_bd_intf_pins processing_system7_0_axi_periph_1/S00_AXI]
  connect_bd_intf_net -intf_net processing_system7_0_axi_periph_1_M00_AXI [get_bd_intf_pins processing_system7_0_axi_periph_1/M00_AXI] [get_bd_intf_pins tracebuffer_pmods/S_AXI]
  connect_bd_intf_net -intf_net processing_system7_0_axi_periph_1_M01_AXI [get_bd_intf_pins processing_system7_0_axi_periph_1/M01_AXI] [get_bd_intf_pins tracebuffer_pmods/S_AXI_LITE]
  connect_bd_intf_net -intf_net processing_system7_0_axi_periph_1_M02_AXI [get_bd_intf_pins processing_system7_0_axi_periph_1/M02_AXI] [get_bd_intf_pins tracebuffer_arduino/S_AXI]
  connect_bd_intf_net -intf_net processing_system7_0_axi_periph_1_M03_AXI [get_bd_intf_pins processing_system7_0_axi_periph_1/M03_AXI] [get_bd_intf_pins tracebuffer_arduino/S_AXI_LITE]
  connect_bd_intf_net -intf_net processing_system7_0_axi_periph_M00_AXI [get_bd_intf_pins processing_system7_0_axi_periph/M00_AXI] [get_bd_intf_pins swsleds_gpio/S_AXI]
  connect_bd_intf_net -intf_net processing_system7_0_axi_periph_M01_AXI [get_bd_intf_pins btns_gpio/S_AXI] [get_bd_intf_pins processing_system7_0_axi_periph/M01_AXI]
  connect_bd_intf_net -intf_net processing_system7_0_axi_periph_M02_AXI [get_bd_intf_pins mb_bram_ctrl_1/S_AXI] [get_bd_intf_pins processing_system7_0_axi_periph/M02_AXI]
  connect_bd_intf_net -intf_net processing_system7_0_axi_periph_M03_AXI [get_bd_intf_pins mb_bram_ctrl_2/S_AXI] [get_bd_intf_pins processing_system7_0_axi_periph/M03_AXI]
  connect_bd_intf_net -intf_net processing_system7_0_axi_periph_M04_AXI [get_bd_intf_pins mb_bram_ctrl_3/S_AXI] [get_bd_intf_pins processing_system7_0_axi_periph/M04_AXI]
  connect_bd_intf_net -intf_net processing_system7_0_axi_periph_M11_AXI [get_bd_intf_pins audio/S_AXI_LITE] [get_bd_intf_pins processing_system7_0_axi_periph/M11_AXI]
  connect_bd_intf_net -intf_net processing_system7_0_axi_periph_M12_AXI [get_bd_intf_pins processing_system7_0_axi_periph/M12_AXI] [get_bd_intf_pins rgbleds_gpio/S_AXI]
  connect_bd_intf_net -intf_net processing_system7_0_axi_periph_M13_AXI [get_bd_intf_pins processing_system7_0_axi_periph/M13_AXI] [get_bd_intf_pins system_interrupts/s_axi]
  connect_bd_intf_net -intf_net rgbled_gpio_GPIO [get_bd_intf_ports rgbleds_6bits] [get_bd_intf_pins rgbleds_gpio/GPIO]
  connect_bd_intf_net -intf_net s00_axi_1 [get_bd_intf_pins processing_system7_0_axi_periph/M07_AXI] [get_bd_intf_pins video/s00_axi]
  connect_bd_intf_net -intf_net swsleds_gpio_GPIO [get_bd_intf_ports sws_2bits] [get_bd_intf_pins swsleds_gpio/GPIO]
  connect_bd_intf_net -intf_net swsleds_gpio_GPIO2 [get_bd_intf_ports leds_4bits] [get_bd_intf_pins swsleds_gpio/GPIO2]
  connect_bd_intf_net -intf_net video_TMDS1 [get_bd_intf_ports hdmi_out] [get_bd_intf_pins video/TMDS1]

  # Create port connections
  connect_bd_net -net S00_ARESETN_1 [get_bd_pins axi_interconnect_0/S00_ARESETN] [get_bd_pins iop1/peripheral_aresetn]
  connect_bd_net -net S01_ARESETN_1 [get_bd_pins axi_interconnect_0/S01_ARESETN] [get_bd_pins iop2/peripheral_aresetn]
  connect_bd_net -net S02_ARESETN_1 [get_bd_pins axi_interconnect_0/S02_ARESETN] [get_bd_pins iop3/peripheral_aresetn]
  connect_bd_net -net audio_path_sel_Dout [get_bd_pins audio/sel] [get_bd_pins audio_path_sel/Dout]
  connect_bd_net -net axi_gpio_video_gpio_io_o [get_bd_ports hdmi_in_hpd] [get_bd_pins video/gpio_io_o1]
  connect_bd_net -net btns_gpio_ip2intc_irpt [get_bd_pins btns_gpio/ip2intc_irpt] [get_bd_pins concat_interrupts/In4]
  connect_bd_net -net concat_arduino_dout [get_bd_pins concat_arduino/dout] [get_bd_pins tracebuffer_arduino/A_TDATA]
  connect_bd_net -net concat_interrupts_dout [get_bd_pins concat_interrupts/dout] [get_bd_pins system_interrupts/intr]
  connect_bd_net -net concat_pmods_dout [get_bd_pins concat_pmods/dout] [get_bd_pins tracebuffer_pmods/A_TDATA]
  connect_bd_net -net constant_8bit_0_dout [get_bd_pins concat_pmods/In3] [get_bd_pins concat_pmods/In7] [get_bd_pins constant_8bit_0/dout]
  connect_bd_net -net hdmi_out_hpd_video_gpio_io_o [get_bd_ports hdmi_out_hpd] [get_bd_pins video/gpio_io_o]
  connect_bd_net -net iop1_intr_ack_Dout [get_bd_pins iop1/iop1_intr_ack] [get_bd_pins mb_1_intr_ack/Dout]
  connect_bd_net -net iop1_iop1_intr_req [get_bd_pins iop1/iop1_intr_req] [get_bd_pins iop_interrupts/In0]
  connect_bd_net -net iop2_intr_ack_1 [get_bd_pins iop2/iop2_intr_ack] [get_bd_pins mb_2_intr_ack/Dout]
  connect_bd_net -net iop2_iop2_intr_req [get_bd_pins iop2/iop2_intr_req] [get_bd_pins iop_interrupts/In1]
  connect_bd_net -net iop3_mb3_intr_req [get_bd_pins iop3/mb3_intr_req] [get_bd_pins iop_interrupts/In2]
  connect_bd_net -net iop3_sw2shield_data_out_a5_a0 [get_bd_ports sw2shield_data_out_a5_a0] [get_bd_pins concat_arduino/In0] [get_bd_pins iop3/sw2shield_data_out_a5_a0]
  connect_bd_net -net iop3_sw2shield_data_out_d13_d2 [get_bd_ports sw2shield_data_out_d13_d2] [get_bd_pins concat_arduino/In2] [get_bd_pins iop3/sw2shield_data_out_d13_d2]
  connect_bd_net -net iop3_sw2shield_data_out_d1_d0 [get_bd_ports sw2shield_data_out_d1_d0] [get_bd_pins concat_arduino/In1] [get_bd_pins iop3/sw2shield_data_out_d1_d0]
  connect_bd_net -net iop3_sw2shield_scl_o_out [get_bd_ports sw2shield_scl_o_out] [get_bd_pins concat_arduino/In11] [get_bd_pins iop3/sw2shield_scl_o_out]
  connect_bd_net -net iop3_sw2shield_scl_t_out [get_bd_ports sw2shield_scl_t_out] [get_bd_pins concat_arduino/In12] [get_bd_pins iop3/sw2shield_scl_t_out]
  connect_bd_net -net iop3_sw2shield_sda_o_out [get_bd_ports sw2shield_sda_o_out] [get_bd_pins iop3/sw2shield_sda_o_out]
  connect_bd_net -net iop3_sw2shield_sda_t_out [get_bd_ports sw2shield_sda_t_out] [get_bd_pins iop3/sw2shield_sda_t_out]
  connect_bd_net -net iop3_sw2shield_tri_out_a5_a0 [get_bd_ports sw2shield_tri_out_a5_a0] [get_bd_pins concat_arduino/In8] [get_bd_pins iop3/sw2shield_tri_out_a5_a0]
  connect_bd_net -net iop3_sw2shield_tri_out_d13_d2 [get_bd_ports sw2shield_tri_out_d13_d2] [get_bd_pins concat_arduino/In10] [get_bd_pins iop3/sw2shield_tri_out_d13_d2]
  connect_bd_net -net iop3_sw2shield_tri_out_d1_d0 [get_bd_ports sw2shield_tri_out_d1_d0] [get_bd_pins concat_arduino/In9] [get_bd_pins iop3/sw2shield_tri_out_d1_d0]
  connect_bd_net -net iop_interrupts_irq [get_bd_pins processing_system7_0/IRQ_F2P] [get_bd_pins system_interrupts/irq]
  connect_bd_net -net logic_1_dout [get_bd_pins iop1/ext_reset_in] [get_bd_pins iop2/ext_reset_in] [get_bd_pins iop3/ext_reset_in] [get_bd_pins logic_1/dout] [get_bd_pins tracebuffer_arduino/A_TVALID] [get_bd_pins tracebuffer_pmods/A_TVALID]
  connect_bd_net -net mb3_intr_ack_1 [get_bd_pins iop3/mb3_intr_ack] [get_bd_pins mb_3_intr_ack/Dout]
  connect_bd_net -net mb_1_reset_Dout [get_bd_pins iop1/aux_reset_in] [get_bd_pins mb_1_reset/Dout]
  connect_bd_net -net mb_2_reset_Dout [get_bd_pins iop2/aux_reset_in] [get_bd_pins mb_2_reset/Dout]
  connect_bd_net -net mb_3_reset_Dout [get_bd_pins iop3/aux_reset_in] [get_bd_pins mb_3_reset/Dout]
  connect_bd_net -net mb_JB1_sw2pmod_data_out [get_bd_ports pmodJB_data_out] [get_bd_pins concat_pmods/In4] [get_bd_pins iop2/sw2pmod_data_out]
  connect_bd_net -net mb_JB1_sw2pmod_tri_out [get_bd_ports pmodJB_tri_out] [get_bd_pins concat_pmods/In6] [get_bd_pins iop2/sw2pmod_tri_out]
  connect_bd_net -net mdm_1_debug_sys_rst [get_bd_pins iop1/mb_debug_sys_rst] [get_bd_pins iop2/mb_debug_sys_rst] [get_bd_pins iop3/mb_debug_sys_rst] [get_bd_pins mdm_1/Debug_SYS_Rst]
  connect_bd_net -net pdm_audio_shutdown_mux_y [get_bd_ports pdm_audio_shutdown] [get_bd_pins audio/pdm_audio_shutdown]
  connect_bd_net -net pdm_m_clk_mux_y [get_bd_ports pdm_m_clk] [get_bd_pins audio/pdm_m_clk]
  connect_bd_net -net pdm_m_data_i_1 [get_bd_ports pdm_m_data_i] [get_bd_pins audio/pdm_audio_i]
  connect_bd_net -net pmod2sw_data_in_1 [get_bd_ports pmodJA_data_in] [get_bd_pins concat_pmods/In1] [get_bd_pins iop1/pmod2sw_data_in]
  connect_bd_net -net pmod2sw_data_in_2 [get_bd_ports pmodJB_data_in] [get_bd_pins concat_pmods/In5] [get_bd_pins iop2/pmod2sw_data_in]
  connect_bd_net -net pmod_io_switch_0_sw2pmod_data_out [get_bd_ports pmodJA_data_out] [get_bd_pins concat_pmods/In0] [get_bd_pins iop1/sw2pmod_data_out]
  connect_bd_net -net pmod_io_switch_0_sw2pmod_tri_out [get_bd_ports pmodJA_tri_out] [get_bd_pins concat_pmods/In2] [get_bd_pins iop1/sw2pmod_tri_out]
  connect_bd_net -net proc_sys_reset_0_peripheral_aresetn [get_bd_pins proc_sys_reset_pixelclk/peripheral_aresetn] [get_bd_pins video/resetn]
  connect_bd_net -net proc_sys_reset_0_peripheral_reset [get_bd_pins proc_sys_reset_pixelclk/peripheral_reset] [get_bd_pins video/vid_io_in_reset]
  connect_bd_net -net proc_sys_reset_142M_interconnect_aresetn [get_bd_pins proc_sys_reset_142M/interconnect_aresetn] [get_bd_pins video/ARESETN]
  connect_bd_net -net proc_sys_reset_142M_peripheral_aresetn [get_bd_pins proc_sys_reset_142M/peripheral_aresetn] [get_bd_pins video/M00_ARESETN]
  connect_bd_net -net processing_system7_0_FCLK_CLK0 [get_bd_pins audio/clk_i] [get_bd_pins axi_interconnect_0/ACLK] [get_bd_pins axi_interconnect_0/M00_ACLK] [get_bd_pins axi_interconnect_0/S00_ACLK] [get_bd_pins axi_interconnect_0/S01_ACLK] [get_bd_pins axi_interconnect_0/S02_ACLK] [get_bd_pins btns_gpio/s_axi_aclk] [get_bd_pins iop1/clk] [get_bd_pins iop2/clk] [get_bd_pins iop3/clk] [get_bd_pins mb_bram_ctrl_1/s_axi_aclk] [get_bd_pins mb_bram_ctrl_2/s_axi_aclk] [get_bd_pins mb_bram_ctrl_3/s_axi_aclk] [get_bd_pins processing_system7_0/FCLK_CLK0] [get_bd_pins processing_system7_0/M_AXI_GP0_ACLK] [get_bd_pins processing_system7_0/S_AXI_GP0_ACLK] [get_bd_pins processing_system7_0_axi_periph/ACLK] [get_bd_pins processing_system7_0_axi_periph/M00_ACLK] [get_bd_pins processing_system7_0_axi_periph/M01_ACLK] [get_bd_pins processing_system7_0_axi_periph/M02_ACLK] [get_bd_pins processing_system7_0_axi_periph/M03_ACLK] [get_bd_pins processing_system7_0_axi_periph/M04_ACLK] [get_bd_pins processing_system7_0_axi_periph/M05_ACLK] [get_bd_pins processing_system7_0_axi_periph/M06_ACLK] [get_bd_pins processing_system7_0_axi_periph/M07_ACLK] [get_bd_pins processing_system7_0_axi_periph/M08_ACLK] [get_bd_pins processing_system7_0_axi_periph/M09_ACLK] [get_bd_pins processing_system7_0_axi_periph/M10_ACLK] [get_bd_pins processing_system7_0_axi_periph/M11_ACLK] [get_bd_pins processing_system7_0_axi_periph/M12_ACLK] [get_bd_pins processing_system7_0_axi_periph/M13_ACLK] [get_bd_pins processing_system7_0_axi_periph/S00_ACLK] [get_bd_pins rgbleds_gpio/s_axi_aclk] [get_bd_pins rst_processing_system7_0_100M/slowest_sync_clk] [get_bd_pins swsleds_gpio/s_axi_aclk] [get_bd_pins system_interrupts/s_axi_aclk] [get_bd_pins video/S00_ACLK]
  connect_bd_net -net processing_system7_0_FCLK_CLK1 [get_bd_pins proc_sys_reset_142M/slowest_sync_clk] [get_bd_pins processing_system7_0/FCLK_CLK1] [get_bd_pins processing_system7_0/S_AXI_HP0_ACLK] [get_bd_pins video/ACLK]
  connect_bd_net -net processing_system7_0_FCLK_CLK2 [get_bd_pins processing_system7_0/FCLK_CLK2] [get_bd_pins video/RefClk]
  connect_bd_net -net processing_system7_0_FCLK_CLK3 [get_bd_pins axi_mem_intercon/ACLK] [get_bd_pins axi_mem_intercon/M00_ACLK] [get_bd_pins axi_mem_intercon/S00_ACLK] [get_bd_pins axi_mem_intercon/S01_ACLK] [get_bd_pins processing_system7_0/FCLK_CLK3] [get_bd_pins processing_system7_0/M_AXI_GP1_ACLK] [get_bd_pins processing_system7_0/S_AXI_HP2_ACLK] [get_bd_pins processing_system7_0_axi_periph_1/ACLK] [get_bd_pins processing_system7_0_axi_periph_1/M00_ACLK] [get_bd_pins processing_system7_0_axi_periph_1/M01_ACLK] [get_bd_pins processing_system7_0_axi_periph_1/M02_ACLK] [get_bd_pins processing_system7_0_axi_periph_1/M03_ACLK] [get_bd_pins processing_system7_0_axi_periph_1/S00_ACLK] [get_bd_pins rst_processing_system7_0_166M/slowest_sync_clk] [get_bd_pins tracebuffer_arduino/s_axi_aclk] [get_bd_pins tracebuffer_pmods/s_axi_aclk]
  connect_bd_net -net processing_system7_0_FCLK_RESET0_N [get_bd_pins proc_sys_reset_142M/ext_reset_in] [get_bd_pins proc_sys_reset_pixelclk/ext_reset_in] [get_bd_pins processing_system7_0/FCLK_RESET0_N] [get_bd_pins rst_processing_system7_0_100M/ext_reset_in] [get_bd_pins rst_processing_system7_0_166M/ext_reset_in]
  connect_bd_net -net processing_system7_0_GPIO_O [get_bd_pins audio_path_sel/Din] [get_bd_pins mb_1_intr_ack/Din] [get_bd_pins mb_1_reset/Din] [get_bd_pins mb_2_intr_ack/Din] [get_bd_pins mb_2_reset/Din] [get_bd_pins mb_3_intr_ack/Din] [get_bd_pins mb_3_reset/Din] [get_bd_pins processing_system7_0/GPIO_O]
  connect_bd_net -net pwm_audio_o_mux_y [get_bd_ports pwm_audio_o] [get_bd_pins audio/pwm_audio_o]
  connect_bd_net -net rst_processing_system7_0_100M_interconnect_aresetn [get_bd_pins axi_interconnect_0/ARESETN] [get_bd_pins processing_system7_0_axi_periph/ARESETN] [get_bd_pins rst_processing_system7_0_100M/interconnect_aresetn]
  connect_bd_net -net rst_processing_system7_0_100M_peripheral_aresetn [get_bd_pins audio/s_axi_lite_aresetn] [get_bd_pins axi_interconnect_0/M00_ARESETN] [get_bd_pins btns_gpio/s_axi_aresetn] [get_bd_pins iop1/s_axi_aresetn] [get_bd_pins iop2/s_axi_aresetn] [get_bd_pins iop3/s_axi_aresetn] [get_bd_pins mb_bram_ctrl_1/s_axi_aresetn] [get_bd_pins mb_bram_ctrl_2/s_axi_aresetn] [get_bd_pins mb_bram_ctrl_3/s_axi_aresetn] [get_bd_pins processing_system7_0_axi_periph/M00_ARESETN] [get_bd_pins processing_system7_0_axi_periph/M01_ARESETN] [get_bd_pins processing_system7_0_axi_periph/M02_ARESETN] [get_bd_pins processing_system7_0_axi_periph/M03_ARESETN] [get_bd_pins processing_system7_0_axi_periph/M04_ARESETN] [get_bd_pins processing_system7_0_axi_periph/M05_ARESETN] [get_bd_pins processing_system7_0_axi_periph/M06_ARESETN] [get_bd_pins processing_system7_0_axi_periph/M07_ARESETN] [get_bd_pins processing_system7_0_axi_periph/M08_ARESETN] [get_bd_pins processing_system7_0_axi_periph/M09_ARESETN] [get_bd_pins processing_system7_0_axi_periph/M10_ARESETN] [get_bd_pins processing_system7_0_axi_periph/M11_ARESETN] [get_bd_pins processing_system7_0_axi_periph/M12_ARESETN] [get_bd_pins processing_system7_0_axi_periph/M13_ARESETN] [get_bd_pins processing_system7_0_axi_periph/S00_ARESETN] [get_bd_pins rgbleds_gpio/s_axi_aresetn] [get_bd_pins rst_processing_system7_0_100M/peripheral_aresetn] [get_bd_pins swsleds_gpio/s_axi_aresetn] [get_bd_pins system_interrupts/s_axi_aresetn] [get_bd_pins video/s00_axi_aresetn]
  connect_bd_net -net rst_processing_system7_0_166M_interconnect_aresetn [get_bd_pins axi_mem_intercon/ARESETN] [get_bd_pins processing_system7_0_axi_periph_1/ARESETN] [get_bd_pins rst_processing_system7_0_166M/interconnect_aresetn]
  connect_bd_net -net rst_processing_system7_0_166M_peripheral_aresetn [get_bd_pins axi_mem_intercon/M00_ARESETN] [get_bd_pins axi_mem_intercon/S00_ARESETN] [get_bd_pins axi_mem_intercon/S01_ARESETN] [get_bd_pins processing_system7_0_axi_periph_1/M00_ARESETN] [get_bd_pins processing_system7_0_axi_periph_1/M01_ARESETN] [get_bd_pins processing_system7_0_axi_periph_1/M02_ARESETN] [get_bd_pins processing_system7_0_axi_periph_1/M03_ARESETN] [get_bd_pins processing_system7_0_axi_periph_1/S00_ARESETN] [get_bd_pins rst_processing_system7_0_166M/peripheral_aresetn] [get_bd_pins tracebuffer_arduino/s_axi_aresetn] [get_bd_pins tracebuffer_pmods/s_axi_aresetn]
  connect_bd_net -net shield2sw_data_in_a5_a0_1 [get_bd_ports shield2sw_data_in_a5_a0] [get_bd_pins concat_arduino/In3] [get_bd_pins iop3/shield2sw_data_in_a5_a0]
  connect_bd_net -net shield2sw_data_in_d13_d2_1 [get_bd_ports shield2sw_data_in_d13_d2] [get_bd_pins concat_arduino/In5] [get_bd_pins iop3/shield2sw_data_in_d13_d2]
  connect_bd_net -net shield2sw_data_in_d1_d0_1 [get_bd_ports shield2sw_data_in_d1_d0] [get_bd_pins concat_arduino/In4] [get_bd_pins iop3/shield2sw_data_in_d1_d0]
  connect_bd_net -net shield2sw_scl_i_in_1 [get_bd_ports shield2sw_scl_i_in] [get_bd_pins concat_arduino/In7] [get_bd_pins iop3/shield2sw_scl_i_in]
  connect_bd_net -net shield2sw_sda_i_in_1 [get_bd_ports shield2sw_sda_i_in] [get_bd_pins concat_arduino/In6] [get_bd_pins iop3/shield2sw_sda_i_in]
  connect_bd_net -net swsleds_gpio_ip2intc_irpt [get_bd_pins concat_interrupts/In5] [get_bd_pins swsleds_gpio/ip2intc_irpt]
  connect_bd_net -net tracebuffer_arduino_s2mm_introut [get_bd_pins concat_interrupts/In2] [get_bd_pins tracebuffer_arduino/s2mm_introut]
  connect_bd_net -net tracebuffer_pmod_s2mm_introut [get_bd_pins concat_interrupts/In1] [get_bd_pins tracebuffer_pmods/s2mm_introut]
  connect_bd_net -net video_PixelClk [get_bd_pins proc_sys_reset_pixelclk/slowest_sync_clk] [get_bd_pins video/PixelClk]
  connect_bd_net -net video_aPixelClkLckd [get_bd_pins proc_sys_reset_pixelclk/aux_reset_in] [get_bd_pins video/aPixelClkLckd]
  connect_bd_net -net video_dout [get_bd_pins concat_interrupts/In0] [get_bd_pins video/dout]
  connect_bd_net -net xlconcat_0_dout [get_bd_pins concat_interrupts/In3] [get_bd_pins iop_interrupts/dout]

  # Create address segments
  create_bd_addr_seg -range 0x00010000 -offset 0x80400000 [get_bd_addr_spaces processing_system7_0/Data] [get_bd_addr_segs tracebuffer_pmods/axi_dma_0/S_AXI_LITE/Reg] SEG_axi_dma_0_Reg
  create_bd_addr_seg -range 0x00010000 -offset 0x80410000 [get_bd_addr_spaces processing_system7_0/Data] [get_bd_addr_segs tracebuffer_arduino/axi_dma_0/S_AXI_LITE/Reg] SEG_axi_dma_0_Reg1
  create_bd_addr_seg -range 0x00010000 -offset 0x43C10000 [get_bd_addr_spaces processing_system7_0/Data] [get_bd_addr_segs video/axi_dynclk_0/s00_axi/reg0] SEG_axi_dynclk_0_reg0
  create_bd_addr_seg -range 0x00010000 -offset 0x41220000 [get_bd_addr_spaces processing_system7_0/Data] [get_bd_addr_segs video/axi_gpio_video/S_AXI/Reg] SEG_axi_gpio_video_Reg
  create_bd_addr_seg -range 0x00010000 -offset 0x43000000 [get_bd_addr_spaces processing_system7_0/Data] [get_bd_addr_segs video/axi_vdma_0/S_AXI_LITE/Reg] SEG_axi_vdma_0_Reg
  create_bd_addr_seg -range 0x00010000 -offset 0x41210000 [get_bd_addr_spaces processing_system7_0/Data] [get_bd_addr_segs btns_gpio/S_AXI/Reg] SEG_btns_gpio_Reg
  create_bd_addr_seg -range 0x00010000 -offset 0x43C00000 [get_bd_addr_spaces processing_system7_0/Data] [get_bd_addr_segs audio/d_axi_pdm_1/S_AXI/S_AXI_reg] SEG_d_axi_pdm_1_S_AXI_reg
  create_bd_addr_seg -range 0x00010000 -offset 0x41230000 [get_bd_addr_spaces processing_system7_0/Data] [get_bd_addr_segs video/hdmi_out_hpd_video/S_AXI/Reg] SEG_hdmi_out_hpd_video_Reg
  create_bd_addr_seg -range 0x00010000 -offset 0x40000000 [get_bd_addr_spaces processing_system7_0/Data] [get_bd_addr_segs mb_bram_ctrl_1/S_AXI/Mem0] SEG_mb_bram_ctrl_1_Mem0
  create_bd_addr_seg -range 0x00010000 -offset 0x42000000 [get_bd_addr_spaces processing_system7_0/Data] [get_bd_addr_segs mb_bram_ctrl_2/S_AXI/Mem0] SEG_mb_bram_ctrl_2_Mem0
  create_bd_addr_seg -range 0x00010000 -offset 0x44000000 [get_bd_addr_spaces processing_system7_0/Data] [get_bd_addr_segs mb_bram_ctrl_3/S_AXI/Mem0] SEG_mb_bram_ctrl_3_Mem0
  create_bd_addr_seg -range 0x00010000 -offset 0x41240000 [get_bd_addr_spaces processing_system7_0/Data] [get_bd_addr_segs rgbleds_gpio/S_AXI/Reg] SEG_rgbled_gpio_Reg
  create_bd_addr_seg -range 0x00010000 -offset 0x41200000 [get_bd_addr_spaces processing_system7_0/Data] [get_bd_addr_segs swsleds_gpio/S_AXI/Reg] SEG_swsleds_gpio_Reg
  create_bd_addr_seg -range 0x00010000 -offset 0x41800000 [get_bd_addr_spaces processing_system7_0/Data] [get_bd_addr_segs system_interrupts/s_axi/Reg] SEG_system_interrupts_Reg
  create_bd_addr_seg -range 0x00010000 -offset 0x83C00000 [get_bd_addr_spaces processing_system7_0/Data] [get_bd_addr_segs tracebuffer_arduino/trace_cntrl_0/s_axi_trace_cntrl/Reg] SEG_trace_cntrl_0_Reg
  create_bd_addr_seg -range 0x00010000 -offset 0x83C10000 [get_bd_addr_spaces processing_system7_0/Data] [get_bd_addr_segs tracebuffer_pmods/trace_cntrl_0/s_axi_trace_cntrl/Reg] SEG_trace_cntrl_0_Reg2
  create_bd_addr_seg -range 0x00010000 -offset 0x43C20000 [get_bd_addr_spaces processing_system7_0/Data] [get_bd_addr_segs video/v_tc_0/ctrl/Reg] SEG_v_tc_0_Reg
  create_bd_addr_seg -range 0x00010000 -offset 0x43C30000 [get_bd_addr_spaces processing_system7_0/Data] [get_bd_addr_segs video/v_tc_1/ctrl/Reg] SEG_v_tc_1_Reg
  create_bd_addr_seg -range 0x00010000 -offset 0x40000000 [get_bd_addr_spaces iop1/mb/Data] [get_bd_addr_segs iop1/mb1_gpio/S_AXI/Reg] SEG_axi_gpio_0_Reg
  create_bd_addr_seg -range 0x00010000 -offset 0x40800000 [get_bd_addr_spaces iop1/mb/Data] [get_bd_addr_segs iop1/mb1_iic/S_AXI/Reg] SEG_axi_iic_0_Reg
  create_bd_addr_seg -range 0x00010000 -offset 0x44A10000 [get_bd_addr_spaces iop1/mb/Data] [get_bd_addr_segs iop1/mb1_spi/AXI_LITE/Reg] SEG_axi_quad_spi_0_Reg
  create_bd_addr_seg -range 0x00010000 -offset 0x00000000 [get_bd_addr_spaces iop1/mb/Instruction] [get_bd_addr_segs iop1/mb1_lmb/lmb_bram_if_cntlr/SLMB/Mem] SEG_ilmb_bram_if_cntlr_Mem
  create_bd_addr_seg -range 0x00010000 -offset 0x40010000 [get_bd_addr_spaces iop1/mb/Data] [get_bd_addr_segs iop1/mb1_intr/S_AXI/Reg] SEG_iop1_intr_Reg
  create_bd_addr_seg -range 0x00010000 -offset 0x00000000 [get_bd_addr_spaces iop1/mb/Data] [get_bd_addr_segs iop1/mb1_lmb/lmb_bram_if_cntlr/SLMB1/Mem] SEG_lmb_bram_if_cntlr_Mem
  create_bd_addr_seg -range 0x00010000 -offset 0x41200000 [get_bd_addr_spaces iop1/mb/Data] [get_bd_addr_segs iop1/mb1_intc/s_axi/Reg] SEG_mb1_intc_Reg
  create_bd_addr_seg -range 0x00010000 -offset 0x41C00000 [get_bd_addr_spaces iop1/mb/Data] [get_bd_addr_segs iop1/mb1_timer/S_AXI/Reg] SEG_mb1_timer_Reg
  create_bd_addr_seg -range 0x00010000 -offset 0x44A00000 [get_bd_addr_spaces iop1/mb/Data] [get_bd_addr_segs iop1/mb1_pmod_io_switch/S00_AXI/S00_AXI_reg] SEG_pmod_io_switch_0_S00_AXI_reg
  create_bd_addr_seg -range 0x20000000 -offset 0x20000000 [get_bd_addr_spaces iop1/mb/Data] [get_bd_addr_segs processing_system7_0/S_AXI_GP0/GP0_DDR_LOWOCM] SEG_processing_system7_0_GP0_DDR_LOWOCM
  create_bd_addr_seg -range 0x00010000 -offset 0x40010000 [get_bd_addr_spaces iop2/mb/Data] [get_bd_addr_segs iop2/mb2_intr/S_AXI/Reg] SEG_iop2_intr_Reg
  create_bd_addr_seg -range 0x00010000 -offset 0x00000000 [get_bd_addr_spaces iop2/mb/Data] [get_bd_addr_segs iop2/mb2_lmb/lmb_bram_if_cntlr/SLMB1/Mem] SEG_lmb_bram_if_cntlr_Mem
  create_bd_addr_seg -range 0x00010000 -offset 0x00000000 [get_bd_addr_spaces iop2/mb/Instruction] [get_bd_addr_segs iop2/mb2_lmb/lmb_bram_if_cntlr/SLMB/Mem] SEG_lmb_bram_if_cntlr_Mem
  create_bd_addr_seg -range 0x00010000 -offset 0x40000000 [get_bd_addr_spaces iop2/mb/Data] [get_bd_addr_segs iop2/mb2_gpio/S_AXI/Reg] SEG_mb2_gpio_Reg
  create_bd_addr_seg -range 0x00010000 -offset 0x40800000 [get_bd_addr_spaces iop2/mb/Data] [get_bd_addr_segs iop2/mb2_iic/S_AXI/Reg] SEG_mb2_iic_Reg
  create_bd_addr_seg -range 0x00010000 -offset 0x41200000 [get_bd_addr_spaces iop2/mb/Data] [get_bd_addr_segs iop2/mb2_intc/s_axi/Reg] SEG_mb2_intc_Reg
  create_bd_addr_seg -range 0x00010000 -offset 0x44A00000 [get_bd_addr_spaces iop2/mb/Data] [get_bd_addr_segs iop2/mb2_pmod_io_switch/S00_AXI/S00_AXI_reg] SEG_mb2_pmod_io_switch_S00_AXI_reg
  create_bd_addr_seg -range 0x00010000 -offset 0x44A10000 [get_bd_addr_spaces iop2/mb/Data] [get_bd_addr_segs iop2/mb2_spi/AXI_LITE/Reg] SEG_mb2_spi_Reg
  create_bd_addr_seg -range 0x00010000 -offset 0x41C00000 [get_bd_addr_spaces iop2/mb/Data] [get_bd_addr_segs iop2/mb2_timer/S_AXI/Reg] SEG_mb2_timer_Reg
  create_bd_addr_seg -range 0x20000000 -offset 0x20000000 [get_bd_addr_spaces iop2/mb/Data] [get_bd_addr_segs processing_system7_0/S_AXI_GP0/GP0_DDR_LOWOCM] SEG_processing_system7_0_GP0_DDR_LOWOCM
  create_bd_addr_seg -range 0x00010000 -offset 0x44A20000 [get_bd_addr_spaces iop3/mb/Data] [get_bd_addr_segs iop3/arduino_io_switch_0/S_AXI/S_AXI_reg] SEG_arduino_io_switch_0_S_AXI_reg
  create_bd_addr_seg -range 0x00010000 -offset 0x00000000 [get_bd_addr_spaces iop3/mb/Instruction] [get_bd_addr_segs iop3/mb3_lmb/lmb_bram_if_cntlr/SLMB/Mem] SEG_lmb_bram_if_cntlr_Mem
  create_bd_addr_seg -range 0x00010000 -offset 0x00000000 [get_bd_addr_spaces iop3/mb/Data] [get_bd_addr_segs iop3/mb3_lmb/lmb_bram_if_cntlr/SLMB1/Mem] SEG_lmb_bram_if_cntlr_Mem
  create_bd_addr_seg -range 0x00010000 -offset 0x40000000 [get_bd_addr_spaces iop3/mb/Data] [get_bd_addr_segs iop3/mb3_gpio_subsystem/mb3_ck_gpio_d15_d0/S_AXI/Reg] SEG_mb2_gpio_Reg
  create_bd_addr_seg -range 0x00010000 -offset 0x40800000 [get_bd_addr_spaces iop3/mb/Data] [get_bd_addr_segs iop3/mb3_iic_subsystem/mb3_iic_pl_sw/S_AXI/Reg] SEG_mb2_iic_Reg
  create_bd_addr_seg -range 0x00010000 -offset 0x44A10000 [get_bd_addr_spaces iop3/mb/Data] [get_bd_addr_segs iop3/mb3_spi_subsystem/mb3_spi_pl_sw/AXI_LITE/Reg] SEG_mb2_spi_Reg
  create_bd_addr_seg -range 0x00010000 -offset 0x40020000 [get_bd_addr_spaces iop3/mb/Data] [get_bd_addr_segs iop3/mb3_gpio_subsystem/mb3_arduino_gpio_d13_d0_a5_a0/S_AXI/Reg] SEG_mb3_gpio_pl_sw_d13_d2_Reg
  create_bd_addr_seg -range 0x00010000 -offset 0x41200000 [get_bd_addr_spaces iop3/mb/Data] [get_bd_addr_segs iop3/mb3_intc/s_axi/Reg] SEG_mb3_intc_Reg
  create_bd_addr_seg -range 0x00010000 -offset 0x40010000 [get_bd_addr_spaces iop3/mb/Data] [get_bd_addr_segs iop3/mb3_intr/S_AXI/Reg] SEG_mb3_intr_Reg
  create_bd_addr_seg -range 0x00010000 -offset 0x40810000 [get_bd_addr_spaces iop3/mb/Data] [get_bd_addr_segs iop3/mb3_iic_subsystem/mb3_shared_iic_sw/S_AXI/Reg] SEG_mb3_shared_iic_sw_Reg
  create_bd_addr_seg -range 0x00010000 -offset 0x44A00000 [get_bd_addr_spaces iop3/mb/Data] [get_bd_addr_segs iop3/mb3_spi_subsystem/mb3_spi_pl_sw_d13_d10/AXI_LITE/Reg] SEG_mb3_spi_pl_sw_d13_d10_Reg
  create_bd_addr_seg -range 0x00010000 -offset 0x41C00000 [get_bd_addr_spaces iop3/mb/Data] [get_bd_addr_segs iop3/mb3_timers_subsystem/mb3_timer_0/S_AXI/Reg] SEG_mb3_timer_0_Reg
  create_bd_addr_seg -range 0x00010000 -offset 0x41C10000 [get_bd_addr_spaces iop3/mb/Data] [get_bd_addr_segs iop3/mb3_timers_subsystem/mb3_timer_1/S_AXI/Reg] SEG_mb3_timer_1_Reg
  create_bd_addr_seg -range 0x00010000 -offset 0x41C20000 [get_bd_addr_spaces iop3/mb/Data] [get_bd_addr_segs iop3/mb3_timers_subsystem/mb3_timer_2/S_AXI/Reg] SEG_mb3_timer_2_Reg
  create_bd_addr_seg -range 0x00010000 -offset 0x41C30000 [get_bd_addr_spaces iop3/mb/Data] [get_bd_addr_segs iop3/mb3_timers_subsystem/mb3_timer_3/S_AXI/Reg] SEG_mb3_timer_3_Reg
  create_bd_addr_seg -range 0x00010000 -offset 0x41C40000 [get_bd_addr_spaces iop3/mb/Data] [get_bd_addr_segs iop3/mb3_timers_subsystem/mb3_timer_4/S_AXI/Reg] SEG_mb3_timer_4_Reg
  create_bd_addr_seg -range 0x00010000 -offset 0x41C50000 [get_bd_addr_spaces iop3/mb/Data] [get_bd_addr_segs iop3/mb3_timers_subsystem/mb3_timer_5/S_AXI/Reg] SEG_mb3_timer_5_Reg
  create_bd_addr_seg -range 0x00010000 -offset 0x40600000 [get_bd_addr_spaces iop3/mb/Data] [get_bd_addr_segs iop3/mb3_uartlite_d1_d0/S_AXI/Reg] SEG_mb3_uartlite_d1_d0_Reg
  create_bd_addr_seg -range 0x00010000 -offset 0x44A30000 [get_bd_addr_spaces iop3/mb/Data] [get_bd_addr_segs iop3/mb3_xadc/s_axi_lite/Reg] SEG_mb3_xadc_Reg
  create_bd_addr_seg -range 0x20000000 -offset 0x20000000 [get_bd_addr_spaces iop3/mb/Data] [get_bd_addr_segs processing_system7_0/S_AXI_GP0/GP0_DDR_LOWOCM] SEG_processing_system7_0_GP0_DDR_LOWOCM
  create_bd_addr_seg -range 0x20000000 -offset 0x00000000 [get_bd_addr_spaces tracebuffer_arduino/axi_dma_0/Data_S2MM] [get_bd_addr_segs processing_system7_0/S_AXI_HP2/HP2_DDR_LOWOCM] SEG_processing_system7_0_HP2_DDR_LOWOCM
  create_bd_addr_seg -range 0x20000000 -offset 0x00000000 [get_bd_addr_spaces tracebuffer_pmods/axi_dma_0/Data_S2MM] [get_bd_addr_segs processing_system7_0/S_AXI_HP2/HP2_DDR_LOWOCM] SEG_processing_system7_0_HP2_DDR_LOWOCM
  create_bd_addr_seg -range 0x20000000 -offset 0x00000000 [get_bd_addr_spaces video/axi_vdma_0/Data_MM2S] [get_bd_addr_segs processing_system7_0/S_AXI_HP0/HP0_DDR_LOWOCM] SEG_processing_system7_0_HP0_DDR_LOWOCM
  create_bd_addr_seg -range 0x20000000 -offset 0x00000000 [get_bd_addr_spaces video/axi_vdma_0/Data_S2MM] [get_bd_addr_segs processing_system7_0/S_AXI_HP0/HP0_DDR_LOWOCM] SEG_processing_system7_0_HP0_DDR_LOWOCM

  # Perform GUI Layout
  regenerate_bd_layout -layout_string {
   guistr: "# # String gsaved with Nlview 6.5.12  2016-01-29 bk=1.3547 VDI=39 GEI=35 GUI=JA:1.6
#  -string -flagsOSRD
preplace port btns_4bits -pg 1 -y 950 -defaultsOSRD
preplace port DDR -pg 1 -y 320 -defaultsOSRD
preplace port shield2sw_scl_i_in -pg 1 -y 2840 -defaultsOSRD
preplace port sw2shield_scl_o_out -pg 1 -y 2600 -defaultsOSRD
preplace port hdmi_out_ddc -pg 1 -y 360 -defaultsOSRD
preplace port Vp_Vn -pg 1 -y 2560 -defaultsOSRD
preplace port shield2sw_sda_i_in -pg 1 -y 2820 -defaultsOSRD
preplace port spi_sw_shield -pg 1 -y 2480 -defaultsOSRD
preplace port sw2shield_sda_o_out -pg 1 -y 2640 -defaultsOSRD
preplace port Vaux0 -pg 1 -y 2580 -defaultsOSRD
preplace port Vaux1 -pg 1 -y 2440 -defaultsOSRD
preplace port leds_4bits -pg 1 -y 1080 -defaultsOSRD
preplace port sw2shield_scl_t_out -pg 1 -y 2620 -defaultsOSRD
preplace port ck_gpio -pg 1 -y 2500 -defaultsOSRD
preplace port Vaux12 -pg 1 -y 2620 -defaultsOSRD
preplace port hdmi_out -pg 1 -y 630 -defaultsOSRD
preplace port Vaux5 -pg 1 -y 2460 -defaultsOSRD
preplace port FIXED_IO -pg 1 -y 340 -defaultsOSRD
preplace port sws_2bits -pg 1 -y 1060 -defaultsOSRD
preplace port hdmi_in -pg 1 -y 550 -defaultsOSRD
preplace port Vaux13 -pg 1 -y 2520 -defaultsOSRD
preplace port Vaux6 -pg 1 -y 2480 -defaultsOSRD
preplace port rgbleds_6bits -pg 1 -y 1200 -defaultsOSRD
preplace port sw2shield_sda_t_out -pg 1 -y 2660 -defaultsOSRD
preplace port Vaux8 -pg 1 -y 2600 -defaultsOSRD
preplace port hdmi_in_ddc -pg 1 -y 590 -defaultsOSRD
preplace port Vaux15 -pg 1 -y 2540 -defaultsOSRD
preplace port pdm_m_data_i -pg 1 -y 2150 -defaultsOSRD
preplace port Vaux9 -pg 1 -y 2500 -defaultsOSRD
preplace portBus pmodJA_tri_out -pg 1 -y 2340 -defaultsOSRD
preplace portBus pmodJB_tri_out -pg 1 -y 2890 -defaultsOSRD
preplace portBus sw2shield_data_out_a5_a0 -pg 1 -y 2540 -defaultsOSRD
preplace portBus shield2sw_data_in_d1_d0 -pg 1 -y 2780 -defaultsOSRD
preplace portBus pdm_m_clk -pg 1 -y 2220 -defaultsOSRD
preplace portBus pmodJB_data_out -pg 1 -y 2320 -defaultsOSRD
preplace portBus pwm_audio_o -pg 1 -y 2240 -defaultsOSRD
preplace portBus sw2shield_tri_out_d13_d2 -pg 1 -y 2700 -defaultsOSRD
preplace portBus pmodJB_data_in -pg 1 -y 2330 -defaultsOSRD
preplace portBus sw2shield_data_out_d1_d0 -pg 1 -y 2580 -defaultsOSRD
preplace portBus shield2sw_data_in_a5_a0 -pg 1 -y 2760 -defaultsOSRD
preplace portBus sw2shield_data_out_d13_d2 -pg 1 -y 2560 -defaultsOSRD
preplace portBus hdmi_out_hpd -pg 1 -y 710 -defaultsOSRD
preplace portBus pdm_audio_shutdown -pg 1 -y 2200 -defaultsOSRD
preplace portBus sw2shield_tri_out_a5_a0 -pg 1 -y 2680 -defaultsOSRD
preplace portBus shield2sw_data_in_d13_d2 -pg 1 -y 2800 -defaultsOSRD
preplace portBus pmodJA_data_out -pg 1 -y 2300 -defaultsOSRD
preplace portBus pmodJA_data_in -pg 1 -y 2170 -defaultsOSRD
preplace portBus sw2shield_tri_out_d1_d0 -pg 1 -y 2720 -defaultsOSRD
preplace portBus hdmi_in_hpd -pg 1 -y 730 -defaultsOSRD
preplace inst tracebuffer_arduino -pg 1 -lvl 4 -y 400 -defaultsOSRD
preplace inst mb_2_reset -pg 1 -lvl 3 -y 2000 -defaultsOSRD
preplace inst constant_8bit_0 -pg 1 -lvl 2 -y 2280 -defaultsOSRD
preplace inst rst_processing_system7_0_166M -pg 1 -lvl 2 -y 190 -defaultsOSRD
preplace inst system_interrupts -pg 1 -lvl 3 -y 1240 -defaultsOSRD
preplace inst iop_interrupts -pg 1 -lvl 1 -y 1660 -defaultsOSRD
preplace inst tracebuffer_pmods -pg 1 -lvl 4 -y 190 -defaultsOSRD
preplace inst rst_processing_system7_0_100M -pg 1 -lvl 1 -y 790 -defaultsOSRD
preplace inst mb_3_reset -pg 1 -lvl 5 -y 2670 -defaultsOSRD
preplace inst swsleds_gpio -pg 1 -lvl 6 -y 1080 -defaultsOSRD
preplace inst proc_sys_reset_pixelclk -pg 1 -lvl 4 -y 870 -defaultsOSRD
preplace inst proc_sys_reset_142M -pg 1 -lvl 4 -y 660 -defaultsOSRD
preplace inst mb_1_reset -pg 1 -lvl 3 -y 1650 -defaultsOSRD
preplace inst iop1 -pg 1 -lvl 4 -y 1670 -defaultsOSRD
preplace inst audio -pg 1 -lvl 6 -y 2220 -defaultsOSRD
preplace inst iop2 -pg 1 -lvl 4 -y 1950 -defaultsOSRD
preplace inst concat_interrupts -pg 1 -lvl 2 -y 440 -defaultsOSRD
preplace inst rgbleds_gpio -pg 1 -lvl 6 -y 1200 -defaultsOSRD
preplace inst logic_1 -pg 1 -lvl 3 -y 430 -defaultsOSRD
preplace inst iop3 -pg 1 -lvl 6 -y 2620 -defaultsOSRD
preplace inst audio_path_sel -pg 1 -lvl 5 -y 2260 -defaultsOSRD
preplace inst concat_pmods -pg 1 -lvl 3 -y 2300 -defaultsOSRD
preplace inst iop2_intr_ack -pg 1 -lvl 3 -y 2080 -defaultsOSRD -resize 140 60
preplace inst mdm_1 -pg 1 -lvl 3 -y 1890 -defaultsOSRD
preplace inst btns_gpio -pg 1 -lvl 6 -y 960 -defaultsOSRD
preplace inst axi_interconnect_0 -pg 1 -lvl 5 -y 1750 -defaultsOSRD
preplace inst iop3_intr_ack -pg 1 -lvl 5 -y 2840 -defaultsOSRD -resize 140 60
preplace inst processing_system7_0_axi_periph_1 -pg 1 -lvl 3 -y 200 -defaultsOSRD
preplace inst mb_bram_ctrl_1 -pg 1 -lvl 3 -y 1390 -defaultsOSRD
preplace inst iop1_intr_ack -pg 1 -lvl 3 -y 1750 -defaultsOSRD -resize 140 60
preplace inst video -pg 1 -lvl 5 -y 660 -defaultsOSRD
preplace inst mb_bram_ctrl_2 -pg 1 -lvl 3 -y 1510 -defaultsOSRD
preplace inst concat_arduino -pg 1 -lvl 3 -y 2820 -defaultsOSRD
preplace inst mb_bram_ctrl_3 -pg 1 -lvl 5 -y 2040 -defaultsOSRD
preplace inst axi_mem_intercon -pg 1 -lvl 5 -y 290 -defaultsOSRD
preplace inst processing_system7_0_axi_periph -pg 1 -lvl 2 -y 1090 -defaultsOSRD
preplace inst processing_system7_0 -pg 1 -lvl 6 -y 400 -defaultsOSRD
preplace netloc Vaux5_1 1 0 6 NJ 2460 NJ 2460 NJ 2460 NJ 2460 NJ 2460 NJ
preplace netloc S00_AXI_2 1 4 1 N
preplace netloc pdm_m_clk_mux_y 1 6 1 NJ
preplace netloc video_dout 1 1 5 410 340 NJ 380 NJ 60 NJ 60 2150
preplace netloc pdm_audio_shutdown_mux_y 1 6 1 NJ
preplace netloc iop3_sw2shield_tri_out_d13_d2 1 2 5 830 3090 NJ 3090 NJ 3090 NJ 3090 2840
preplace netloc processing_system7_0_FIXED_IO 1 6 1 NJ
preplace netloc mb_3_reset_Dout 1 5 1 NJ
preplace netloc swsleds_gpio_GPIO2 1 6 1 NJ
preplace netloc video_aPixelClkLckd 1 3 3 1310 50 NJ 50 2160
preplace netloc hdmi_in_1 1 0 5 NJ 550 NJ 560 NJ 560 NJ 560 NJ
preplace netloc iop_interrupts_irq 1 3 3 NJ 30 NJ 30 2250
preplace netloc tracebuffer_pmod_s2mm_introut 1 1 4 380 550 NJ 510 NJ 510 1680
preplace netloc mb_2_reset_Dout 1 3 1 NJ
preplace netloc shield2sw_data_in_a5_a0_1 1 0 6 NJ 2760 NJ 2760 770 2990 NJ 2740 NJ 2740 N
preplace netloc iop3_sw2shield_scl_t_out 1 2 5 860 3060 NJ 3060 NJ 3060 NJ 3060 2790
preplace netloc processing_system7_0_axi_periph_1_M01_AXI 1 3 1 1210
preplace netloc axi_mem_intercon_M00_AXI1 1 5 1 2240
preplace netloc concat_interrupts_dout 1 2 1 820
preplace netloc xlconcat_0_dout 1 1 1 360
preplace netloc proc_sys_reset_0_peripheral_reset 1 4 1 1770
preplace netloc processing_system7_0_axi_periph_1_M03_AXI 1 3 1 1280
preplace netloc mb_bram_ctrl_2_BRAM_PORTA 1 3 1 1240
preplace netloc S_AXI_LITE_1 1 2 3 NJ 970 NJ 970 1740
preplace netloc S02_ARESETN_1 1 4 3 1830 2900 NJ 2900 2700
preplace netloc shield2sw_data_in_d1_d0_1 1 0 6 NJ 2780 NJ 2780 760 3000 NJ 2780 NJ 2780 N
preplace netloc shield2sw_scl_i_in_1 1 0 6 NJ 2840 NJ 2840 730 3010 NJ 2890 NJ 2890 2140
preplace netloc processing_system7_0_DDR 1 6 1 NJ
preplace netloc mb_bram_ctrl_3_BRAM_PORTA 1 5 1 2130
preplace netloc iop3_GPIO 1 6 1 NJ
preplace netloc dvi2rgb_0_DDC 1 5 2 NJ 590 NJ
preplace netloc S01_AXI_1 1 4 1 1690
preplace netloc Vaux12_1 1 0 6 NJ 2610 NJ 2610 NJ 2610 NJ 2610 NJ 2610 NJ
preplace netloc S01_AXI_2 1 4 1 1790
preplace netloc swsleds_gpio_ip2intc_irpt 1 1 6 400 580 NJ 580 NJ 40 NJ 40 NJ 40 2770
preplace netloc Vaux15_1 1 0 6 NJ 2540 NJ 2540 NJ 2540 NJ 2540 NJ 2540 NJ
preplace netloc processing_system7_0_axi_periph_1_M00_AXI 1 3 1 1170
preplace netloc mb_JB1_sw2pmod_data_out 1 2 5 830 2170 NJ 2080 1680 1970 NJ 1970 NJ
preplace netloc iop3_sw2shield_data_out_d1_d0 1 2 5 860 2470 NJ 2320 NJ 2320 NJ 2320 2810
preplace netloc hdmi_out_hpd_video_gpio_io_o 1 5 2 NJ 710 NJ
preplace netloc constant_8bit_0_dout 1 2 1 730
preplace netloc mdm_1_debug_sys_rst 1 3 3 1330 2570 NJ 2570 NJ
preplace netloc iop3_sw2shield_sda_t_out 1 6 1 NJ
preplace netloc tracebuffer_arduino_s2mm_introut 1 1 4 390 570 NJ 570 NJ 570 1670
preplace netloc processing_system7_0_FCLK_RESET0_N 1 0 7 10 640 350 640 NJ 640 1300 770 NJ 130 NJ 130 2730
preplace netloc shield2sw_data_in_d13_d2_1 1 0 6 NJ 2800 NJ 2800 750 3040 NJ 2760 NJ 2760 N
preplace netloc S02_AXI_1 1 4 3 1820 100 NJ 100 2780
preplace netloc S_AXI1_1 1 2 3 760 520 NJ 520 NJ
preplace netloc iop1_intr_ack_Dout 1 3 1 NJ
preplace netloc processing_system7_0_axi_periph_M03_AXI 1 2 1 790
preplace netloc processing_system7_0_axi_periph_M02_AXI 1 2 1 810
preplace netloc proc_sys_reset_0_peripheral_aresetn 1 4 1 1750
preplace netloc mb3_intr_ack_1 1 5 1 NJ
preplace netloc Vaux13_1 1 0 6 NJ 2520 NJ 2520 NJ 2520 NJ 2520 NJ 2520 NJ
preplace netloc mb_bram_ctrl_1_BRAM_PORTA 1 3 1 1250
preplace netloc iop3_sw2shield_data_out_d13_d2 1 2 5 740 2420 NJ 2330 NJ 2330 NJ 2330 2790
preplace netloc iop1_iop1_intr_req 1 0 5 10 1800 NJ 1800 NJ 1800 NJ 1800 1670
preplace netloc mb_JB1_sw2pmod_tri_out 1 2 5 810 2450 NJ 2450 1690 2450 NJ 2890 NJ
preplace netloc proc_sys_reset_142M_interconnect_aresetn 1 4 1 N
preplace netloc rst_processing_system7_0_166M_peripheral_aresetn 1 2 3 850 490 1210 290 1720
preplace netloc rgbled_gpio_GPIO 1 6 1 NJ
preplace netloc processing_system7_0_axi_periph_M11_AXI 1 2 4 NJ 1140 NJ 1140 NJ 1140 2190
preplace netloc iop3_sw2shield_sda_o_out 1 6 1 NJ
preplace netloc processing_system7_0_axi_periph_M13_AXI 1 2 1 860
preplace netloc ctrl_1 1 2 3 NJ 540 NJ 540 1760
preplace netloc axi_dma_0_M_AXI_S2MM 1 4 1 1780
preplace netloc S01_ARESETN_1 1 4 1 1800
preplace netloc processing_system7_0_IIC_0 1 6 1 NJ
preplace netloc Vp_Vn_1 1 0 6 NJ 2560 NJ 2560 NJ 2560 NJ 2560 NJ 2560 NJ
preplace netloc processing_system7_0_axi_periph_M12_AXI 1 2 4 NJ 1160 NJ 1160 NJ 1160 2180
preplace netloc processing_system7_0_axi_periph_M01_AXI 1 2 4 NJ 780 NJ 780 NJ 850 2200
preplace netloc Vaux0_1 1 0 6 NJ 2580 NJ 2580 NJ 2580 NJ 2580 NJ 2580 NJ
preplace netloc rst_processing_system7_0_166M_interconnect_aresetn 1 2 3 820 20 NJ 20 1810
preplace netloc pmod2sw_data_in_1 1 0 4 NJ 2170 NJ 2170 780 1700 1230
preplace netloc iop3_sw2shield_scl_o_out 1 2 5 790 2430 NJ 2340 NJ 2340 NJ 2340 2800
preplace netloc pmod2sw_data_in_2 1 0 4 NJ 2330 NJ 2330 750 2180 1310
preplace netloc processing_system7_0_FCLK_CLK0 1 0 7 30 880 400 1480 860 1320 1260 1320 1780 440 2220 600 2720
preplace netloc pdm_m_data_i_1 1 0 6 NJ 2150 NJ 2150 NJ 2150 NJ 2310 NJ 2310 NJ
preplace netloc btns_gpio_ip2intc_irpt 1 1 6 410 540 NJ 530 NJ 530 NJ 450 NJ 610 2700
preplace netloc microblaze_0_debug 1 3 1 1160
preplace netloc processing_system7_0_FCLK_CLK1 1 3 4 1330 760 1730 460 2260 580 2710
preplace netloc video_PixelClk 1 3 3 1320 70 NJ 70 2130
preplace netloc S00_ARESETN_1 1 4 1 1720
preplace netloc processing_system7_0_FCLK_CLK2 1 4 3 1830 120 NJ 120 2740
preplace netloc rst_processing_system7_0_100M_interconnect_aresetn 1 1 4 380 1470 NJ 1110 NJ 1110 NJ
preplace netloc concat_pmods_dout 1 3 1 1220
preplace netloc processing_system7_0_axi_periph_M00_AXI 1 2 4 NJ 960 NJ 960 NJ 960 2210
preplace netloc shield2sw_sda_i_in_1 1 0 6 NJ 2820 NJ 2820 740 3020 NJ 2790 NJ 2790 2130
preplace netloc processing_system7_0_FCLK_CLK3 1 1 6 350 100 830 480 1200 80 1730 110 2230 570 2700
preplace netloc Vaux8_1 1 0 6 NJ 2590 NJ 2590 NJ 2590 NJ 2590 NJ 2590 NJ
preplace netloc S_AXI_1 1 2 3 740 500 NJ 500 NJ
preplace netloc pwm_audio_o_mux_y 1 6 1 NJ
preplace netloc processing_system7_0_axi_periph_1_M02_AXI 1 3 1 1300
preplace netloc ctrl1_1 1 2 3 NJ 550 NJ 550 1750
preplace netloc mb_1_reset_Dout 1 3 1 NJ
preplace netloc Vaux6_1 1 0 6 NJ 2480 NJ 2480 NJ 2480 NJ 2480 NJ 2480 NJ
preplace netloc axi_gpio_video_gpio_io_o 1 5 2 NJ 730 NJ
preplace netloc iop3_sw2shield_data_out_a5_a0 1 2 5 850 3030 NJ 3030 NJ 3030 NJ 3030 2830
preplace netloc iop2_intr_ack_1 1 3 1 NJ
preplace netloc iop3_sw2shield_tri_out_d1_d0 1 2 5 810 3080 NJ 3080 NJ 3080 NJ 3080 2730
preplace netloc pmod_io_switch_0_sw2pmod_tri_out 1 2 5 810 2140 NJ 2140 1700 2110 NJ 2110 NJ
preplace netloc processing_system7_0_M_AXI_GP0 1 1 6 410 710 NJ 710 NJ 750 NJ 140 NJ 140 2710
preplace netloc audio_path_sel_Dout 1 5 1 NJ
preplace netloc processing_system7_0_M_AXI_GP1 1 2 5 830 10 NJ 10 NJ 10 NJ 10 2750
preplace netloc proc_sys_reset_142M_peripheral_aresetn 1 4 1 N
preplace netloc logic_1_dout 1 3 3 1170 2620 NJ 2620 NJ
preplace netloc iop3_mb3_intr_req 1 0 7 30 3050 NJ 3050 NJ 3050 NJ 3050 NJ 3050 NJ 3050 2710
preplace netloc Vaux1_1 1 0 6 NJ 2440 NJ 2440 NJ 2440 NJ 2440 NJ 2440 NJ
preplace netloc axi_mem_intercon_M00_AXI 1 5 1 2200
preplace netloc Vaux9_1 1 0 6 NJ 2500 NJ 2500 NJ 2500 NJ 2500 NJ 2500 NJ
preplace netloc concat_arduino_dout 1 3 1 1280
preplace netloc processing_system7_0_GPIO_O 1 2 5 850 1810 NJ 1810 1750 1550 NJ 1550 2760
preplace netloc swsleds_gpio_GPIO 1 6 1 NJ
preplace netloc iop3_spi_sw_shield 1 6 1 NJ
preplace netloc btns_gpio_GPIO 1 6 1 NJ
preplace netloc processing_system7_0_axi_periph_M04_AXI 1 2 3 N 1040 NJ 1040 NJ
preplace netloc mdm_1_MBDEBUG_1 1 3 1 1160
preplace netloc rst_processing_system7_0_100M_peripheral_aresetn 1 1 5 350 1490 760 1130 1270 1130 1810 980 2200
preplace netloc pmod_io_switch_0_sw2pmod_data_out 1 2 5 850 2160 NJ 2160 1710 2120 NJ 2120 NJ
preplace netloc video_TMDS1 1 5 2 NJ 630 NJ
preplace netloc axi_interconnect_0_M00_AXI 1 5 1 2170
preplace netloc s00_axi_1 1 2 3 NJ 1100 NJ 1100 1760
preplace netloc mdm_1_MBDEBUG_2 1 3 3 NJ 2420 NJ 2420 N
preplace netloc iop3_sw2shield_tri_out_a5_a0 1 2 5 800 3070 NJ 3070 NJ 3070 NJ 3070 2760
preplace netloc iop2_iop2_intr_req 1 0 5 20 2130 NJ 2130 NJ 2130 NJ 2130 1670
levelinfo -pg 1 -10 190 570 1010 1500 1980 2480 2860 -top 0 -bot 3100
",
}

  # Restore current instance
  current_bd_instance $oldCurInst

  save_bd_design
}
# End of create_root_design()



##################################################################
# MAIN FLOW
##################################################################

create_root_design ""

# Additional steps to get to bitstream
# generate toplevel wrapper files
make_wrapper -files [get_files ./base/base.srcs/sources_1/bd/system/system.bd] -top

add_files -norecurse ./base/base.srcs/sources_1/bd/system/hdl/system_wrapper.v
update_compile_order -fileset sources_1
update_compile_order -fileset sim_1
add_files -fileset constrs_1 -norecurse ./vivado_src/constraints/top.xdc

# replace top wrapper with custom top.v
add_files -norecurse ./vivado_src/top.v
update_compile_order -fileset sources_1
set_property top top [current_fileset]
update_compile_order -fileset sources_1

# call implement
launch_runs impl_1 -to_step write_bitstream -jobs 4
wait_on_run impl_1

# This hwardware definition file will be used for microblaze projects
file mkdir ./base/base.sdk
write_hwdef -force  -file ./base/base.sdk/base.hdf
file copy -force ./base/base.sdk/base.hdf .

# move and rename bitstream to final location
file copy -force ./base/base.runs/impl_1/top.bit base.bit


