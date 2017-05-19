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
 # @file interface.tcl
 #
 # Vivado tcl script to generate the bitstream interface.bit.
 # Supporting combinational function generator, pattern generator, etc. on 
 # Arduino interface.
 #
 # <pre>
 # MODIFICATION HISTORY:
 #
 # Ver   Who  Date     Changes
 # ----- --- -------- -----------------------------------------------
 # 1.00a yrq 02/21/2017 initial release
 # 1.00b yrq 03/30/2017 fixed names, fixed interrupt connection
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
# <./interface/interface.xpr> in the current working folder.

set list_projs [get_projects -quiet]
if { $list_projs eq "" } {
   create_project interface interface -part xc7z020clg400-1
}

set_property  ip_repo_paths  ../ip [current_project]
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


# Hierarchical cell: pg
proc create_hier_cell_pg { parentCell nameHier } {

  variable script_folder

  if { $parentCell eq "" || $nameHier eq "" } {
     catch {common::send_msg_id "BD_TCL-102" "ERROR" create_hier_cell_pg() - Empty argument(s)!"}
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

  # Create pins
  create_bd_pin -dir O -from 17 -to 0 addrB
  create_bd_pin -dir O enb
  create_bd_pin -dir O enb_1d
  create_bd_pin -dir O -from 19 -to 0 gpio_io_o
  create_bd_pin -dir I -type clk s_axi_aclk
  create_bd_pin -dir I -from 0 -to 0 -type rst s_axi_aresetn
  create_bd_pin -dir I -type clk sync_clk

  # Create instance: axi_gpio_pg_nsamples_single, and set properties
  set axi_gpio_pg_nsamples_single [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_gpio:2.0 axi_gpio_pg_nsamples_single ]
  set_property -dict [ list \
CONFIG.C_ALL_OUTPUTS {0} \
CONFIG.C_ALL_OUTPUTS_2 {0} \
CONFIG.C_GPIO2_WIDTH {1} \
CONFIG.C_GPIO_WIDTH {18} \
CONFIG.C_IS_DUAL {1} \
 ] $axi_gpio_pg_nsamples_single

  # Create instance: axi_gpio_pg_tri_control, and set properties
  set axi_gpio_pg_tri_control [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_gpio:2.0 axi_gpio_pg_tri_control ]
  set_property -dict [ list \
CONFIG.C_ALL_OUTPUTS {0} \
CONFIG.C_ALL_OUTPUTS_2 {0} \
CONFIG.C_GPIO2_WIDTH {3} \
CONFIG.C_GPIO_WIDTH {20} \
CONFIG.C_IS_DUAL {1} \
 ] $axi_gpio_pg_tri_control

  # Create instance: pg_fsm_0, and set properties
  set pg_fsm_0 [ create_bd_cell -type ip -vlnv xilinx.com:user:pg_fsm:1.0 pg_fsm_0 ]

  # Create interface connections
  connect_bd_intf_net -intf_net mb_axi_periph_M04_AXI [get_bd_intf_pins S_AXI] [get_bd_intf_pins axi_gpio_pg_tri_control/S_AXI]
  connect_bd_intf_net -intf_net mb_axi_periph_M05_AXI [get_bd_intf_pins S_AXI1] [get_bd_intf_pins axi_gpio_pg_nsamples_single/S_AXI]

  # Create port connections
  connect_bd_net -net S00_ARESETN_1 [get_bd_pins s_axi_aresetn] [get_bd_pins axi_gpio_pg_nsamples_single/s_axi_aresetn] [get_bd_pins axi_gpio_pg_tri_control/s_axi_aresetn] [get_bd_pins pg_fsm_0/reset_n]
  connect_bd_net -net axi_gpio_pg_nsamples_single_gpio2_io_o [get_bd_pins axi_gpio_pg_nsamples_single/gpio2_io_i] [get_bd_pins axi_gpio_pg_nsamples_single/gpio2_io_o] [get_bd_pins pg_fsm_0/single_b]
  connect_bd_net -net axi_gpio_pg_nsamples_single_gpio_io_o [get_bd_pins axi_gpio_pg_nsamples_single/gpio_io_i] [get_bd_pins axi_gpio_pg_nsamples_single/gpio_io_o] [get_bd_pins pg_fsm_0/numSample]
  connect_bd_net -net axi_gpio_pg_tri_control_gpio2_io_o [get_bd_pins axi_gpio_pg_tri_control/gpio2_io_i] [get_bd_pins axi_gpio_pg_tri_control/gpio2_io_o] [get_bd_pins pg_fsm_0/gpio_control]
  connect_bd_net -net axi_gpio_pg_tri_control_gpio_io_o [get_bd_pins gpio_io_o] [get_bd_pins axi_gpio_pg_tri_control/gpio_io_i] [get_bd_pins axi_gpio_pg_tri_control/gpio_io_o]
  connect_bd_net -net pg_fsm_0_addrB [get_bd_pins addrB] [get_bd_pins pg_fsm_0/addrB]
  connect_bd_net -net pg_fsm_0_enb [get_bd_pins enb] [get_bd_pins pg_fsm_0/enb]
  connect_bd_net -net pg_fsm_0_enb_1d [get_bd_pins enb_1d] [get_bd_pins pg_fsm_0/enb_1d]
  connect_bd_net -net processing_system7_0_FCLK_CLK0 [get_bd_pins s_axi_aclk] [get_bd_pins axi_gpio_pg_nsamples_single/s_axi_aclk] [get_bd_pins axi_gpio_pg_tri_control/s_axi_aclk]
  connect_bd_net -net sync_clk_1 [get_bd_pins sync_clk] [get_bd_pins pg_fsm_0/clk]

  # Perform GUI Layout
  regenerate_bd_layout -hierarchy [get_bd_cells /iop3/pg_o/pg] -layout_string {
   guistr: "# # String gsaved with Nlview 6.5.12  2016-01-29 bk=1.3547 VDI=39 GEI=35 GUI=JA:1.6
#  -string -flagsOSRD
preplace port s_axi_aclk -pg 1 -y 90 -defaultsOSRD
preplace port sync_clk -pg 1 -y 190 -defaultsOSRD
preplace port enb_1d -pg 1 -y 230 -defaultsOSRD
preplace port S_AXI -pg 1 -y 70 -defaultsOSRD
preplace port enb -pg 1 -y 250 -defaultsOSRD
preplace port S_AXI1 -pg 1 -y 270 -defaultsOSRD
preplace portBus addrB -pg 1 -y 210 -defaultsOSRD
preplace portBus s_axi_aresetn -pg 1 -y 110 -defaultsOSRD
preplace portBus gpio_io_o -pg 1 -y 60 -defaultsOSRD
preplace inst pg_fsm_0 -pg 1 -lvl 2 -y 210 -defaultsOSRD
preplace inst axi_gpio_pg_nsamples_single -pg 1 -lvl 1 -y 300 -defaultsOSRD
preplace inst axi_gpio_pg_tri_control -pg 1 -lvl 1 -y 90 -defaultsOSRD
preplace netloc axi_gpio_pg_tri_control_gpio_io_o 1 1 2 580 60 NJ
preplace netloc pg_fsm_0_addrB 1 2 1 840
preplace netloc mb_axi_periph_M04_AXI 1 0 1 NJ
preplace netloc axi_gpio_pg_nsamples_single_gpio_io_o 1 1 1 570
preplace netloc pg_fsm_0_enb 1 2 1 820
preplace netloc mb_axi_periph_M05_AXI 1 0 1 NJ
preplace netloc pg_fsm_0_enb_1d 1 2 1 830
preplace netloc processing_system7_0_FCLK_CLK0 1 0 1 40
preplace netloc sync_clk_1 1 0 2 NJ 190 560
preplace netloc S00_ARESETN_1 1 0 2 20 200 NJ
preplace netloc axi_gpio_pg_nsamples_single_gpio2_io_o 1 1 1 580
preplace netloc axi_gpio_pg_tri_control_gpio2_io_o 1 1 1 580
levelinfo -pg 1 0 430 700 860 -top -130 -bot 400
",
}

  # Restore current instance
  current_bd_instance $oldCurInst
}

# Hierarchical cell: smg_0
proc create_hier_cell_smg_0 { parentCell nameHier } {

  variable script_folder

  if { $parentCell eq "" || $nameHier eq "" } {
     catch {common::send_msg_id "BD_TCL-102" "ERROR" create_hier_cell_smg_0() - Empty argument(s)!"}
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
  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S00_AXI
  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S_AXI
  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S_AXI1
  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S_AXI2

  # Create pins
  create_bd_pin -dir I clkb
  create_bd_pin -dir I -from 0 -to 0 probe10
  create_bd_pin -dir I -type clk s_axi_aclk
  create_bd_pin -dir I -from 0 -to 0 -type rst s_axi_aresetn
  create_bd_pin -dir O -from 0 -to 0 smg_enb_1d
  create_bd_pin -dir O -from 19 -to 0 smgdata2sw
  create_bd_pin -dir O -from 19 -to 0 smgtri2sw
  create_bd_pin -dir I -from 19 -to 0 sw2smg

  # Create instance: axi_bram_ctrl_0, and set properties
  set axi_bram_ctrl_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_bram_ctrl:4.0 axi_bram_ctrl_0 ]
  set_property -dict [ list \
CONFIG.SINGLE_PORT_BRAM {1} \
 ] $axi_bram_ctrl_0

  # Create instance: axi_bram_ctrl_1, and set properties
  set axi_bram_ctrl_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_bram_ctrl:4.0 axi_bram_ctrl_1 ]
  set_property -dict [ list \
CONFIG.SINGLE_PORT_BRAM {1} \
 ] $axi_bram_ctrl_1

  # Create instance: concat_addrB, and set properties
  set concat_addrB [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconcat:2.1 concat_addrB ]
  set_property -dict [ list \
CONFIG.NUM_PORTS {4} \
 ] $concat_addrB

  # Create instance: concat_fsmout, and set properties
  set concat_fsmout [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconcat:2.1 concat_fsmout ]

  # Create instance: constant_17bit_0, and set properties
  set constant_17bit_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant:1.1 constant_17bit_0 ]
  set_property -dict [ list \
CONFIG.CONST_VAL {0} \
CONFIG.CONST_WIDTH {17} \
 ] $constant_17bit_0

  # Create instance: constant_32bit_0, and set properties
  set constant_32bit_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant:1.1 constant_32bit_0 ]
  set_property -dict [ list \
CONFIG.CONST_VAL {0} \
CONFIG.CONST_WIDTH {32} \
 ] $constant_32bit_0

  # Create instance: dff_en_reset_0, and set properties
  set dff_en_reset_0 [ create_bd_cell -type ip -vlnv xilinx.com:XUP:dff_en_reset:1.0 dff_en_reset_0 ]

  # Create instance: logic_0, and set properties
  set logic_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant:1.1 logic_0 ]
  set_property -dict [ list \
CONFIG.CONST_VAL {0} \
 ] $logic_0

  # Create instance: logic_1, and set properties
  set logic_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant:1.1 logic_1 ]

  # Create instance: logic_2bit_0, and set properties
  set logic_2bit_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant:1.1 logic_2bit_0 ]
  set_property -dict [ list \
CONFIG.CONST_VAL {0} \
CONFIG.CONST_WIDTH {2} \
 ] $logic_2bit_0

  # Create instance: logic_4bit_0, and set properties
  set logic_4bit_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant:1.1 logic_4bit_0 ]
  set_property -dict [ list \
CONFIG.CONST_VAL {0} \
CONFIG.CONST_WIDTH {4} \
 ] $logic_4bit_0

  # Create instance: slice_dout_31_13, and set properties
  set slice_dout_31_13 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice:1.0 slice_dout_31_13 ]
  set_property -dict [ list \
CONFIG.DIN_FROM {31} \
CONFIG.DIN_TO {13} \
CONFIG.DOUT_WIDTH {19} \
 ] $slice_dout_31_13

  # Create instance: slice_dout_4_0, and set properties
  set slice_dout_4_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice:1.0 slice_dout_4_0 ]
  set_property -dict [ list \
CONFIG.DIN_FROM {4} \
CONFIG.DOUT_WIDTH {5} \
 ] $slice_dout_4_0

  # Create instance: slice_dout_8_5, and set properties
  set slice_dout_8_5 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice:1.0 slice_dout_8_5 ]
  set_property -dict [ list \
CONFIG.DIN_FROM {8} \
CONFIG.DIN_TO {5} \
CONFIG.DOUT_WIDTH {4} \
 ] $slice_dout_8_5

  # Create instance: slice_enb, and set properties
  set slice_enb [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice:1.0 slice_enb ]
  set_property -dict [ list \
CONFIG.DIN_FROM {1} \
CONFIG.DIN_TO {1} \
CONFIG.DIN_WIDTH {2} \
CONFIG.DOUT_WIDTH {1} \
 ] $slice_enb

  # Create instance: slice_rstb, and set properties
  set slice_rstb [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice:1.0 slice_rstb ]
  set_property -dict [ list \
CONFIG.DIN_FROM {0} \
CONFIG.DIN_TO {0} \
CONFIG.DIN_WIDTH {2} \
CONFIG.DOUT_WIDTH {1} \
 ] $slice_rstb

  # Create instance: smg_blk_mem_gen, and set properties
  set smg_blk_mem_gen [ create_bd_cell -type ip -vlnv xilinx.com:ip:blk_mem_gen:8.3 smg_blk_mem_gen ]
  set_property -dict [ list \
CONFIG.Enable_B {Use_ENB_Pin} \
CONFIG.Memory_Type {True_Dual_Port_RAM} \
CONFIG.Port_B_Clock {100} \
CONFIG.Port_B_Enable_Rate {100} \
CONFIG.Port_B_Write_Rate {50} \
CONFIG.Use_RSTB_Pin {true} \
CONFIG.use_bram_block {BRAM_Controller} \
 ] $smg_blk_mem_gen

  # Need to retain value_src of defaults
  set_property -dict [ list \
CONFIG.use_bram_block.VALUE_SRC {DEFAULT} \
 ] $smg_blk_mem_gen

  # Create instance: smg_bram_enb_rstb, and set properties
  set smg_bram_enb_rstb [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_gpio:2.0 smg_bram_enb_rstb ]
  set_property -dict [ list \
CONFIG.C_ALL_OUTPUTS {1} \
CONFIG.C_GPIO_WIDTH {2} \
 ] $smg_bram_enb_rstb

  # Create instance: smg_io_switch_0, and set properties
  set smg_io_switch_0 [ create_bd_cell -type ip -vlnv xilinx.com:user:smg_io_switch:1.0 smg_io_switch_0 ]

  # Create interface connections
  connect_bd_intf_net -intf_net Conn1 [get_bd_intf_pins S_AXI1] [get_bd_intf_pins axi_bram_ctrl_0/S_AXI]
  connect_bd_intf_net -intf_net Conn2 [get_bd_intf_pins S_AXI2] [get_bd_intf_pins axi_bram_ctrl_1/S_AXI]
  connect_bd_intf_net -intf_net S00_AXI_1 [get_bd_intf_pins S00_AXI] [get_bd_intf_pins smg_io_switch_0/S00_AXI]
  connect_bd_intf_net -intf_net axi_bram_ctrl_0_BRAM_PORTA [get_bd_intf_pins axi_bram_ctrl_0/BRAM_PORTA] [get_bd_intf_pins smg_blk_mem_gen/BRAM_PORTB]
  connect_bd_intf_net -intf_net axi_bram_ctrl_1_BRAM_PORTA [get_bd_intf_pins axi_bram_ctrl_1/BRAM_PORTA] [get_bd_intf_pins smg_blk_mem_gen/BRAM_PORTA]
  connect_bd_intf_net -intf_net mb_axi_periph_M09_AXI [get_bd_intf_pins S_AXI] [get_bd_intf_pins smg_bram_enb_rstb/S_AXI]

  # Create port connections
  connect_bd_net -net S00_ARESETN_1 [get_bd_pins s_axi_aresetn] [get_bd_pins axi_bram_ctrl_0/s_axi_aresetn] [get_bd_pins axi_bram_ctrl_1/s_axi_aresetn] [get_bd_pins smg_bram_enb_rstb/s_axi_aresetn] [get_bd_pins smg_io_switch_0/s00_axi_aresetn]
  connect_bd_net -net clk1_1 [get_bd_pins clkb] [get_bd_pins dff_en_reset_0/clk] [get_bd_pins smg_blk_mem_gen/clkb]
  connect_bd_net -net concat_addrB_dout [get_bd_pins concat_addrB/dout] [get_bd_pins smg_blk_mem_gen/addrb]
  connect_bd_net -net constant_17bit_0_dout [get_bd_pins concat_addrB/In3] [get_bd_pins constant_17bit_0/dout]
  connect_bd_net -net constant_32bit_0_dout [get_bd_pins constant_32bit_0/dout] [get_bd_pins smg_blk_mem_gen/dinb]
  connect_bd_net -net fsm_io_switch_0_fsminput [get_bd_pins concat_addrB/In2] [get_bd_pins smg_io_switch_0/smginput]
  connect_bd_net -net logic_1_dout [get_bd_pins dff_en_reset_0/en] [get_bd_pins logic_1/dout]
  connect_bd_net -net logic_2bit_0_dout [get_bd_pins concat_addrB/In0] [get_bd_pins logic_2bit_0/dout]
  connect_bd_net -net logic_4bit_0_dout [get_bd_pins logic_4bit_0/dout] [get_bd_pins smg_blk_mem_gen/web]
#  connect_bd_net -net probe10_1 [get_bd_pins probe10] [get_bd_pins ila_0/probe10]
  connect_bd_net -net processing_system7_0_FCLK_CLK0 [get_bd_pins s_axi_aclk] [get_bd_pins axi_bram_ctrl_0/s_axi_aclk] [get_bd_pins axi_bram_ctrl_1/s_axi_aclk] [get_bd_pins smg_bram_enb_rstb/s_axi_aclk] [get_bd_pins smg_io_switch_0/s00_axi_aclk]
  connect_bd_net -net slice_dout_31_13_Dout [get_bd_pins concat_fsmout/In0] [get_bd_pins slice_dout_31_13/Dout]
  connect_bd_net -net slice_dout_4_0_Dout [get_bd_pins concat_addrB/In1] [get_bd_pins slice_dout_4_0/Dout]
  connect_bd_net -net slice_dout_8_5_Dout [get_bd_pins slice_dout_8_5/Dout] [get_bd_pins smg_io_switch_0/smg_ns_out_8_5]
  connect_bd_net -net slice_enb_Dout [get_bd_pins dff_en_reset_0/d] [get_bd_pins slice_enb/Dout] [get_bd_pins smg_blk_mem_gen/enb]
  connect_bd_net -net slice_rstb_Dout [get_bd_pins slice_rstb/Dout] [get_bd_pins smg_blk_mem_gen/rstb]
  connect_bd_net -net smg_blk_mem_gen_doutb [get_bd_pins slice_dout_31_13/Din] [get_bd_pins slice_dout_4_0/Din] [get_bd_pins slice_dout_8_5/Din] [get_bd_pins smg_blk_mem_gen/doutb]
  connect_bd_net -net smg_bram_enab_rstb_gpio_io_o [get_bd_pins slice_enb/Din] [get_bd_pins slice_rstb/Din] [get_bd_pins smg_bram_enb_rstb/gpio_io_o]
  connect_bd_net -net smg_enb_1d [get_bd_pins smg_enb_1d] [get_bd_pins dff_en_reset_0/q] 
  connect_bd_net -net smg_io_switch_0_smgdata2sw [get_bd_pins smgdata2sw] [get_bd_pins smg_io_switch_0/smgdata2sw]
  connect_bd_net -net smg_io_switch_0_smgtri2sw [get_bd_pins smgtri2sw] [get_bd_pins smg_io_switch_0/smgtri2sw]
  connect_bd_net -net sw2fsm_1 [get_bd_pins sw2smg] [get_bd_pins smg_io_switch_0/sw2smg]
  connect_bd_net -net xlconcat_0_dout [get_bd_pins concat_fsmout/dout] [get_bd_pins smg_io_switch_0/smgout]
  connect_bd_net -net xlconstant_0_dout [get_bd_pins concat_fsmout/In1] [get_bd_pins dff_en_reset_0/reset] [get_bd_pins logic_0/dout]

  # Restore current instance
  current_bd_instance $oldCurInst
}

# Hierarchical cell: pg_o
proc create_hier_cell_pg_o { parentCell nameHier } {

  variable script_folder

  if { $parentCell eq "" || $nameHier eq "" } {
     catch {common::send_msg_id "BD_TCL-102" "ERROR" create_hier_cell_pg_o() - Empty argument(s)!"}
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
  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 M00_AXI
  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S_AXI
  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S_AXI1
  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S_AXI2
  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S_AXI3
  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S_AXI_LITE
  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 s_axi_trace_cntrl

  # Create pins
  create_bd_pin -dir I -from 0 -to 0 -type rst ARESETN
  create_bd_pin -dir O -from 19 -to 0 Dout
  create_bd_pin -dir I -from 19 -to 0 In0
  create_bd_pin -dir I -from 19 -to 0 In1
  create_bd_pin -dir I -from 19 -to 0 In3
  create_bd_pin -dir I -from 0 -to 0 -type rst axi_resetn
  create_bd_pin -dir O enb_1d
  create_bd_pin -dir O -from 19 -to 0 gpio_io_o
  create_bd_pin -dir I -type clk m_axi_s2mm_aclk
  create_bd_pin -dir I -type clk s_axi_aclk
  create_bd_pin -dir I -from 0 -to 0 -type rst s_axi_aresetn
  create_bd_pin -dir I -from 0 -to 0 smg_enb_1d

  # Create instance: axi_bram_ctrl_0, and set properties
  set axi_bram_ctrl_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_bram_ctrl:4.0 axi_bram_ctrl_0 ]
  set_property -dict [ list \
CONFIG.SINGLE_PORT_BRAM {1} \
 ] $axi_bram_ctrl_0

  # Create instance: axi_bram_ctrl_1, and set properties
  set axi_bram_ctrl_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_bram_ctrl:4.0 axi_bram_ctrl_1 ]
  set_property -dict [ list \
CONFIG.SINGLE_PORT_BRAM {1} \
 ] $axi_bram_ctrl_1

  # Create instance: axi_dma_0, and set properties
  set axi_dma_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_dma:7.1 axi_dma_0 ]
  set_property -dict [ list \
CONFIG.c_include_mm2s {0} \
CONFIG.c_include_s2mm_dre {1} \
CONFIG.c_include_sg {0} \
CONFIG.c_m_axi_s2mm_data_width {64} \
CONFIG.c_s2mm_burst_size {256} \
CONFIG.c_sg_include_stscntrl_strm {0} \
CONFIG.c_sg_length_width {23} \
 ] $axi_dma_0

  # Create instance: axi_mem_intercon_1, and set properties
  set axi_mem_intercon_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_interconnect:2.1 axi_mem_intercon_1 ]
  set_property -dict [ list \
CONFIG.NUM_MI {1} \
 ] $axi_mem_intercon_1

  # Create instance: axis_data_fifo_0, and set properties
  set axis_data_fifo_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axis_data_fifo:1.1 axis_data_fifo_0 ]
  set_property -dict [ list \
CONFIG.FIFO_DEPTH {2048} \
CONFIG.HAS_TKEEP {1} \
CONFIG.HAS_TLAST {1} \
CONFIG.HAS_TSTRB {1} \
CONFIG.TDATA_NUM_BYTES {8} \
CONFIG.TDEST_WIDTH {1} \
CONFIG.TID_WIDTH {5} \
CONFIG.TUSER_WIDTH {2} \
 ] $axis_data_fifo_0

  # Create instance: blk_mem_gen_0, and set properties
  set blk_mem_gen_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:blk_mem_gen:8.3 blk_mem_gen_0 ]
  set_property -dict [ list \
CONFIG.Enable_B {Use_ENB_Pin} \
CONFIG.Memory_Type {True_Dual_Port_RAM} \
CONFIG.Port_B_Clock {100} \
CONFIG.Port_B_Enable_Rate {100} \
CONFIG.Port_B_Write_Rate {50} \
CONFIG.Use_RSTB_Pin {true} \
CONFIG.use_bram_block {BRAM_Controller} \
 ] $blk_mem_gen_0

  # Need to retain value_src of defaults
  set_property -dict [ list \
CONFIG.use_bram_block.VALUE_SRC {DEFAULT} \
 ] $blk_mem_gen_0

  # Create instance: concat_addrB, and set properties
  set concat_addrB [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconcat:2.1 concat_addrB ]
  set_property -dict [ list \
CONFIG.NUM_PORTS {3} \
 ] $concat_addrB

  # Create instance: concat_arduino, and set properties
  set concat_arduino [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconcat:2.1 concat_arduino ]
  set_property -dict [ list \
CONFIG.NUM_PORTS {5} \
 ] $concat_arduino

  # Create instance: concat_tkeep, and set properties
  set concat_tkeep [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconcat:2.1 concat_tkeep ]
  set_property -dict [ list \
CONFIG.NUM_PORTS {8} \
 ] $concat_tkeep

  # Create instance: constant_12bit_0, and set properties
  set constant_12bit_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant:1.1 constant_12bit_0 ]
  set_property -dict [ list \
CONFIG.CONST_VAL {0} \
CONFIG.CONST_WIDTH {12} \
 ] $constant_12bit_0

  # Create instance: constant_2bit_0, and set properties
  set constant_2bit_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant:1.1 constant_2bit_0 ]
  set_property -dict [ list \
CONFIG.CONST_VAL {0} \
CONFIG.CONST_WIDTH {2} \
 ] $constant_2bit_0

  # Create instance: constant_2bits_0, and set properties
  set constant_2bits_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant:1.1 constant_2bits_0 ]
  set_property -dict [ list \
CONFIG.CONST_VAL {0} \
CONFIG.CONST_WIDTH {2} \
 ] $constant_2bits_0

  # Create instance: constant_32bit_0, and set properties
  set constant_32bit_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant:1.1 constant_32bit_0 ]
  set_property -dict [ list \
CONFIG.CONST_VAL {0} \
CONFIG.CONST_WIDTH {32} \
 ] $constant_32bit_0

  # Create instance: constant_4bit_0, and set properties
  set constant_4bit_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant:1.1 constant_4bit_0 ]
  set_property -dict [ list \
CONFIG.CONST_VAL {0} \
CONFIG.CONST_WIDTH {4} \
 ] $constant_4bit_0

  # Create instance: constant_tstrb, and set properties
  set constant_tstrb [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant:1.1 constant_tstrb ]
  set_property -dict [ list \
CONFIG.CONST_VAL {255} \
CONFIG.CONST_WIDTH {8} \
 ] $constant_tstrb

  # Create instance: logic_0, and set properties
  set logic_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant:1.1 logic_0 ]
  set_property -dict [ list \
CONFIG.CONST_VAL {0} \
 ] $logic_0

  # Create instance: pg
  create_hier_cell_pg $hier_obj pg

  # Create instance: slice_pg_data, and set properties
  set slice_pg_data [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice:1.0 slice_pg_data ]
  set_property -dict [ list \
CONFIG.DIN_FROM {19} \
CONFIG.DOUT_WIDTH {20} \
 ] $slice_pg_data

  # Create instance: trace_cntrl_0, and set properties
  set trace_cntrl_0 [ create_bd_cell -type ip -vlnv xilinx:hls:trace_cntrl:1.3 trace_cntrl_0 ]

  # Create interface connections
  connect_bd_intf_net -intf_net Conn1 [get_bd_intf_pins M00_AXI] [get_bd_intf_pins axi_mem_intercon_1/M00_AXI]
  connect_bd_intf_net -intf_net Conn2 [get_bd_intf_pins S_AXI3] [get_bd_intf_pins axi_bram_ctrl_0/S_AXI]
  connect_bd_intf_net -intf_net axi_bram_ctrl_0_BRAM_PORTA [get_bd_intf_pins axi_bram_ctrl_0/BRAM_PORTA] [get_bd_intf_pins blk_mem_gen_0/BRAM_PORTB]
  connect_bd_intf_net -intf_net axi_bram_ctrl_1_BRAM_PORTA [get_bd_intf_pins axi_bram_ctrl_1/BRAM_PORTA] [get_bd_intf_pins blk_mem_gen_0/BRAM_PORTA]
  connect_bd_intf_net -intf_net axi_dma_0_M_AXI_S2MM [get_bd_intf_pins axi_dma_0/M_AXI_S2MM] [get_bd_intf_pins axi_mem_intercon_1/S00_AXI]
  connect_bd_intf_net -intf_net axi_mem_intercon_M00_AXI [get_bd_intf_pins S_AXI] [get_bd_intf_pins axi_bram_ctrl_1/S_AXI]
  connect_bd_intf_net -intf_net axis_data_fifo_0_M_AXIS [get_bd_intf_pins axi_dma_0/S_AXIS_S2MM] [get_bd_intf_pins axis_data_fifo_0/M_AXIS]
  connect_bd_intf_net -intf_net mb_axi_periph_M04_AXI [get_bd_intf_pins S_AXI1] [get_bd_intf_pins pg/S_AXI]
  connect_bd_intf_net -intf_net mb_axi_periph_M05_AXI [get_bd_intf_pins S_AXI2] [get_bd_intf_pins pg/S_AXI1]
  connect_bd_intf_net -intf_net mb_axi_periph_M07_AXI [get_bd_intf_pins s_axi_trace_cntrl] [get_bd_intf_pins trace_cntrl_0/s_axi_trace_cntrl]
  connect_bd_intf_net -intf_net mb_axi_periph_M08_AXI [get_bd_intf_pins S_AXI_LITE] [get_bd_intf_pins axi_dma_0/S_AXI_LITE]
  connect_bd_intf_net -intf_net trace_cntrl_0_B [get_bd_intf_pins axis_data_fifo_0/S_AXIS] [get_bd_intf_pins trace_cntrl_0/B]

  # Create port connections
  connect_bd_net -net ARESETN_2 [get_bd_pins ARESETN] [get_bd_pins axi_mem_intercon_1/ARESETN]
  connect_bd_net -net S00_ARESETN_1 [get_bd_pins s_axi_aresetn] [get_bd_pins axi_bram_ctrl_0/s_axi_aresetn] [get_bd_pins axi_bram_ctrl_1/s_axi_aresetn] [get_bd_pins pg/s_axi_aresetn]
  connect_bd_net -net ap_rst_n_1 [get_bd_pins axi_resetn] [get_bd_pins axi_dma_0/axi_resetn] [get_bd_pins axi_mem_intercon_1/M00_ARESETN] [get_bd_pins axi_mem_intercon_1/S00_ARESETN] [get_bd_pins axis_data_fifo_0/s_axis_aresetn] [get_bd_pins trace_cntrl_0/ap_rst_n]
  connect_bd_net -net ar2sw_data_i_1 [get_bd_pins In1] [get_bd_pins concat_arduino/In1]
  connect_bd_net -net axi_gpio_pg_tri_control_gpio_io_o [get_bd_pins gpio_io_o] [get_bd_pins pg/gpio_io_o]
  connect_bd_net -net blk_mem_gen_0_doutb [get_bd_pins blk_mem_gen_0/doutb] [get_bd_pins slice_pg_data/Din]
  connect_bd_net -net clk1_1 [get_bd_pins m_axi_s2mm_aclk] [get_bd_pins axi_dma_0/m_axi_s2mm_aclk] [get_bd_pins axi_dma_0/s_axi_lite_aclk] [get_bd_pins axi_mem_intercon_1/ACLK] [get_bd_pins axi_mem_intercon_1/M00_ACLK] [get_bd_pins axi_mem_intercon_1/S00_ACLK] [get_bd_pins axis_data_fifo_0/s_axis_aclk] [get_bd_pins blk_mem_gen_0/clkb] [get_bd_pins pg/sync_clk] [get_bd_pins trace_cntrl_0/ap_clk]
  connect_bd_net -net concat_addrB_dout [get_bd_pins blk_mem_gen_0/addrb] [get_bd_pins concat_addrB/dout]
  connect_bd_net -net concat_arduino_dout [get_bd_pins concat_arduino/dout] [get_bd_pins trace_cntrl_0/A_TDATA]
  connect_bd_net -net concat_tkeep_dout [get_bd_pins concat_tkeep/dout] [get_bd_pins trace_cntrl_0/A_TKEEP]
  connect_bd_net -net constant_12bit_0_dout [get_bd_pins concat_addrB/In2] [get_bd_pins constant_12bit_0/dout]
  connect_bd_net -net constant_2bit_0_dout [get_bd_pins concat_addrB/In0] [get_bd_pins constant_2bit_0/dout]
  connect_bd_net -net constant_2bits_0_dout [get_bd_pins concat_arduino/In2] [get_bd_pins concat_arduino/In4] [get_bd_pins constant_2bits_0/dout]
  connect_bd_net -net constant_32bit_0_dout [get_bd_pins blk_mem_gen_0/dinb] [get_bd_pins constant_32bit_0/dout]
  connect_bd_net -net constant_4bit_0_dout [get_bd_pins blk_mem_gen_0/web] [get_bd_pins constant_4bit_0/dout]
  connect_bd_net -net constant_tkeep_tstrb_dout [get_bd_pins constant_tstrb/dout] [get_bd_pins trace_cntrl_0/A_TSTRB]
  connect_bd_net -net interface_switch_0_sw2ar_data_o [get_bd_pins In0] [get_bd_pins concat_arduino/In0]
  connect_bd_net -net interface_switch_0_sw2ar_tri_o [get_bd_pins In3] [get_bd_pins concat_arduino/In3]
  connect_bd_net -net logic_0_dout [get_bd_pins blk_mem_gen_0/rstb] [get_bd_pins logic_0/dout]
  connect_bd_net -net pg_addrB [get_bd_pins concat_addrB/In1] [get_bd_pins pg/addrB]
  connect_bd_net -net pg_enb [get_bd_pins blk_mem_gen_0/enb] [get_bd_pins pg/enb]
  connect_bd_net -net pg_enb_1d [get_bd_pins enb_1d] [get_bd_pins concat_tkeep/In0] [get_bd_pins concat_tkeep/In1] [get_bd_pins concat_tkeep/In2] [get_bd_pins concat_tkeep/In3] [get_bd_pins concat_tkeep/In4] [get_bd_pins concat_tkeep/In5] [get_bd_pins concat_tkeep/In6] [get_bd_pins concat_tkeep/In7] [get_bd_pins pg/enb_1d] [get_bd_pins trace_cntrl_0/A_TVALID]
  connect_bd_net -net processing_system7_0_FCLK_CLK0 [get_bd_pins s_axi_aclk] [get_bd_pins axi_bram_ctrl_0/s_axi_aclk] [get_bd_pins axi_bram_ctrl_1/s_axi_aclk] [get_bd_pins pg/s_axi_aclk]
  connect_bd_net -net slice_pg_data_Dout [get_bd_pins Dout] [get_bd_pins slice_pg_data/Dout]

  # Perform GUI Layout
  regenerate_bd_layout -hierarchy [get_bd_cells /iop3/pg_o] -layout_string {
   guistr: "# # String gsaved with Nlview 6.5.12  2016-01-29 bk=1.3547 VDI=39 GEI=35 GUI=JA:1.6
#  -string -flagsOSRD
preplace port s_axi_aclk -pg 1 -y 1020 -defaultsOSRD
preplace port S_AXI3 -pg 1 -y 980 -defaultsOSRD
preplace port S_AXI_LITE -pg 1 -y 630 -defaultsOSRD
preplace port enb_1d -pg 1 -y 1010 -defaultsOSRD
preplace port m_axi_s2mm_aclk -pg 1 -y 1040 -defaultsOSRD
preplace port s_axi_trace_cntrl -pg 1 -y 700 -defaultsOSRD
preplace port S_AXI -pg 1 -y 900 -defaultsOSRD
preplace port S_AXI1 -pg 1 -y 940 -defaultsOSRD
preplace port S_AXI2 -pg 1 -y 960 -defaultsOSRD
preplace port M00_AXI -pg 1 -y 710 -defaultsOSRD
preplace portBus In0 -pg 1 -y 40 -defaultsOSRD
preplace portBus In1 -pg 1 -y 60 -defaultsOSRD
preplace portBus Dout -pg 1 -y 80 -defaultsOSRD
preplace portBus In3 -pg 1 -y 160 -defaultsOSRD
preplace portBus ARESETN -pg 1 -y 580 -defaultsOSRD
preplace portBus smg_enb_1d -pg 1 -y 20 -defaultsOSRD
preplace portBus axi_resetn -pg 1 -y 880 -defaultsOSRD
preplace portBus s_axi_aresetn -pg 1 -y 1000 -defaultsOSRD
preplace portBus gpio_io_o -pg 1 -y 990 -defaultsOSRD
preplace inst pg|axi_gpio_pg_nsamples_single -pg 1 -lvl 1 -y 1020 -defaultsOSRD
preplace inst constant_12bit_0 -pg 1 -lvl 5 -y 310 -defaultsOSRD
preplace inst axi_dma_0 -pg 1 -lvl 6 -y 670 -defaultsOSRD
preplace inst axi_mem_intercon_1 -pg 1 -lvl 7 -y 710 -defaultsOSRD
preplace inst pg|axi_gpio_pg_tri_control -pg 1 -lvl 1 -y 1220 -defaultsOSRD
preplace inst slice_pg_data -pg 1 -lvl 7 -y 80 -defaultsOSRD
preplace inst logic_0 -pg 1 -lvl 6 -y 450 -defaultsOSRD
preplace inst pg -pg 1 -lvl 2 -y 1000 -defaultsOSRD
preplace inst concat_addrB -pg 1 -lvl 6 -y 250 -defaultsOSRD
preplace inst blk_mem_gen_0 -pg 1 -lvl 7 -y 240 -defaultsOSRD
preplace inst trace_cntrl_0 -pg 1 -lvl 4 -y 770 -defaultsOSRD
preplace inst constant_tstrb -pg 1 -lvl 3 -y 800 -defaultsOSRD
preplace inst constant_4bit_0 -pg 1 -lvl 6 -y 530 -defaultsOSRD
preplace inst pg|pg_fsm_0 -pg 1 -lvl 1 -y 1420 -defaultsOSRD
preplace inst constant_2bits_0 -pg 1 -lvl 2 -y 110 -defaultsOSRD
preplace inst concat_tkeep -pg 1 -lvl 3 -y 1090 -defaultsOSRD
preplace inst concat_arduino -pg 1 -lvl 3 -y 80 -defaultsOSRD
preplace inst constant_32bit_0 -pg 1 -lvl 6 -y 370 -defaultsOSRD
preplace inst axi_bram_ctrl_0 -pg 1 -lvl 2 -y 1580 -defaultsOSRD
preplace inst constant_2bit_0 -pg 1 -lvl 5 -y 230 -defaultsOSRD
preplace inst axi_bram_ctrl_1 -pg 1 -lvl 6 -y 920 -defaultsOSRD
preplace inst axis_data_fifo_0 -pg 1 -lvl 5 -y 720 -defaultsOSRD
preplace netloc pg|S00_ARESETN_1 1 0 1 320
preplace netloc Conn1 1 7 1 NJ
preplace netloc axi_gpio_pg_tri_control_gpio_io_o 1 2 6 NJ 970 NJ 970 NJ 970 NJ 990 NJ 990 NJ
preplace netloc pg_addrB 1 2 4 NJ 360 NJ 360 NJ 360 NJ
preplace netloc constant_4bit_0_dout 1 6 1 NJ
preplace netloc logic_0_dout 1 6 1 NJ
preplace netloc Conn2 1 0 2 NJ 980 10
preplace netloc ar2sw_data_i_1 1 0 3 NJ 60 NJ 60 NJ
preplace netloc constant_12bit_0_dout 1 5 1 NJ
preplace netloc constant_tkeep_tstrb_dout 1 3 1 NJ
preplace netloc ap_rst_n_1 1 0 7 NJ 850 NJ 850 NJ 850 1050 640 1400 640 1750 770 2170
preplace netloc constant_2bit_0_dout 1 5 1 NJ
preplace netloc mb_axi_periph_M04_AXI 1 0 2 NJ 940 60
preplace netloc mb_axi_periph_M07_AXI 1 0 4 NJ 700 NJ 700 NJ 700 NJ
preplace netloc axi_bram_ctrl_0_BRAM_PORTA 1 2 5 NJ 180 NJ 180 NJ 180 NJ 180 NJ
preplace netloc constant_32bit_0_dout 1 6 1 NJ
preplace netloc pg|processing_system7_0_FCLK_CLK0 1 0 1 340
preplace netloc pg|axi_gpio_pg_nsamples_single_gpio2_io_o 1 0 2 360 1320 640
preplace netloc clk1_1 1 0 7 NJ 1040 NJ 750 NJ 750 1090 650 1410 630 1770 760 2150
preplace netloc pg_enb_1d 1 2 6 830 930 NJ 930 NJ 930 NJ 1010 NJ 1010 N
preplace netloc pg|pg_fsm_0_enb_1d 1 1 1 640
preplace netloc pg|pg_fsm_0_addrB 1 1 1 N
preplace netloc pg|axi_gpio_pg_tri_control_gpio_io_o 1 1 1 650
preplace netloc axi_mem_intercon_M00_AXI 1 0 6 NJ 900 NJ 900 NJ 900 NJ 900 NJ 900 NJ
preplace netloc ARESETN_2 1 0 7 NJ 580 NJ 580 NJ 580 NJ 580 NJ 580 NJ 580 NJ
preplace netloc concat_arduino_dout 1 3 1 1080
preplace netloc pg|mb_axi_periph_M04_AXI 1 0 1 330
preplace netloc pg|pg_fsm_0_enb 1 1 1 N
preplace netloc pg|axi_gpio_pg_nsamples_single_gpio_io_o 1 0 2 350 1120 650
preplace netloc mb_axi_periph_M05_AXI 1 0 2 NJ 960 40
preplace netloc slice_pg_data_Dout 1 7 1 NJ
preplace netloc pg|axi_gpio_pg_tri_control_gpio2_io_o 1 0 2 370 1330 630
preplace netloc axi_dma_0_M_AXI_S2MM 1 6 1 N
preplace netloc interface_switch_0_sw2ar_tri_o 1 0 3 NJ 30 NJ 30 NJ
preplace netloc pg_enb 1 2 5 NJ 370 NJ 370 NJ 370 NJ 320 NJ
preplace netloc pg|mb_axi_periph_M05_AXI 1 0 1 N
preplace netloc pg|sync_clk_1 1 0 1 N
preplace netloc axis_data_fifo_0_M_AXIS 1 5 1 1760
preplace netloc blk_mem_gen_0_doutb 1 6 1 2160
preplace netloc processing_system7_0_FCLK_CLK0 1 0 6 NJ 1020 NJ 890 NJ 890 NJ 920 NJ 920 NJ
preplace netloc mb_axi_periph_M08_AXI 1 0 6 NJ 620 NJ 620 NJ 620 NJ 620 NJ 620 NJ
preplace netloc axi_bram_ctrl_1_BRAM_PORTA 1 6 1 2130
preplace netloc interface_switch_0_sw2ar_data_o 1 0 3 NJ 40 NJ 40 NJ
preplace netloc constant_2bits_0_dout 1 2 1 830
preplace netloc trace_cntrl_0_B 1 4 1 1420
preplace netloc S00_ARESETN_1 1 0 6 NJ 1000 NJ 880 NJ 880 NJ 890 NJ 890 NJ
preplace netloc concat_addrB_dout 1 6 1 2100
preplace netloc concat_tkeep_dout 1 3 1 1080
levelinfo -pg 1 -50 -10 430 960 1250 1600 1940 2320 2490 -top 0 -bot 1650
levelinfo -hier pg * 500 *
",
}

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

# Hierarchical cell: cfg_0
proc create_hier_cell_cfg_0 { parentCell nameHier } {

  variable script_folder

  if { $parentCell eq "" || $nameHier eq "" } {
     catch {common::send_msg_id "BD_TCL-102" "ERROR" create_hier_cell_cfg_0() - Empty argument(s)!"}
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
  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S00_AXI

  # Create pins
  create_bd_pin -dir I -from 19 -to 0 Din
  create_bd_pin -dir O cfg2led_gr_0
  create_bd_pin -dir O cfg2led_gr_1
  create_bd_pin -dir O cfg2led_gr_2
  create_bd_pin -dir O cfg2led_gr_3
  create_bd_pin -dir O cfg2led_gr_4
  create_bd_pin -dir O -from 19 -to 0 dout
  create_bd_pin -dir O -from 19 -to 0 dout1
  create_bd_pin -dir I -from 3 -to 0 pb_in
  create_bd_pin -dir I -type clk s00_axi_aclk
  create_bd_pin -dir I -from 0 -to 0 -type rst s00_axi_aresetn

  # Create instance: cfg_0, and set properties
  set cfg_0 [ create_bd_cell -type ip -vlnv xilinx.com:user:cfg:1.0 cfg_0 ]

  # Create instance: concat_cfglut_data_o, and set properties
  set concat_cfglut_data_o [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconcat:2.1 concat_cfglut_data_o ]
  set_property -dict [ list \
CONFIG.NUM_PORTS {8} \
 ] $concat_cfglut_data_o

  # Create instance: concat_cfglut_tri_out, and set properties
  set concat_cfglut_tri_out [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconcat:2.1 concat_cfglut_tri_out ]
  set_property -dict [ list \
CONFIG.NUM_PORTS {8} \
 ] $concat_cfglut_tri_out

  # Create instance: constant_4bits_0, and set properties
  set constant_4bits_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant:1.1 constant_4bits_0 ]
  set_property -dict [ list \
CONFIG.CONST_VAL {0} \
CONFIG.CONST_WIDTH {4} \
 ] $constant_4bits_0

  # Create instance: slice_gr_0, and set properties
  set slice_gr_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice:1.0 slice_gr_0 ]
  set_property -dict [ list \
CONFIG.DIN_FROM {3} \
CONFIG.DIN_TO {0} \
CONFIG.DIN_WIDTH {20} \
CONFIG.DOUT_WIDTH {4} \
 ] $slice_gr_0

  # Create instance: slice_gr_1, and set properties
  set slice_gr_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice:1.0 slice_gr_1 ]
  set_property -dict [ list \
CONFIG.DIN_FROM {8} \
CONFIG.DIN_TO {5} \
CONFIG.DIN_WIDTH {20} \
CONFIG.DOUT_WIDTH {4} \
 ] $slice_gr_1

  # Create instance: slice_gr_2, and set properties
  set slice_gr_2 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice:1.0 slice_gr_2 ]
  set_property -dict [ list \
CONFIG.DIN_FROM {13} \
CONFIG.DIN_TO {10} \
CONFIG.DIN_WIDTH {20} \
CONFIG.DOUT_WIDTH {4} \
 ] $slice_gr_2

  # Create instance: slice_gr_3, and set properties
  set slice_gr_3 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice:1.0 slice_gr_3 ]
  set_property -dict [ list \
CONFIG.DIN_FROM {18} \
CONFIG.DIN_TO {15} \
CONFIG.DIN_WIDTH {20} \
CONFIG.DOUT_WIDTH {4} \
 ] $slice_gr_3

  # Create interface connections
  connect_bd_intf_net -intf_net mb_axi_periph_M00_AXI [get_bd_intf_pins S00_AXI] [get_bd_intf_pins cfg_0/S00_AXI]

  # Create port connections
  connect_bd_net -net S00_ARESETN_1 [get_bd_pins s00_axi_aresetn] [get_bd_pins cfg_0/s00_axi_aresetn]
  connect_bd_net -net cfg_0_cfg2led_gr_0 [get_bd_pins cfg2led_gr_0] [get_bd_pins cfg_0/cfg2led_gr_0]
  connect_bd_net -net cfg_0_cfg2led_gr_1 [get_bd_pins cfg2led_gr_1] [get_bd_pins cfg_0/cfg2led_gr_1]
  connect_bd_net -net cfg_0_cfg2led_gr_3 [get_bd_pins cfg2led_gr_3] [get_bd_pins cfg_0/cfg2led_gr_3]
  connect_bd_net -net cfg_0_cfg2led_gr_4 [get_bd_pins cfg2led_gr_4] [get_bd_pins cfg_0/cfg2led_gr_4]
  connect_bd_net -net cfg_0_cfg2shield_gr_0_data_o [get_bd_pins cfg_0/cfg2shield_gr_0_data_o] [get_bd_pins concat_cfglut_data_o/In1]
  connect_bd_net -net cfg_0_cfg2shield_gr_0_tri_o [get_bd_pins cfg_0/cfg2shield_gr_0_tri_o] [get_bd_pins concat_cfglut_tri_out/In1]
  connect_bd_net -net cfg_0_cfg2shield_gr_0_tri_out [get_bd_pins cfg_0/cfg2shield_gr_0_tri_out] [get_bd_pins concat_cfglut_tri_out/In0]
  connect_bd_net -net cfg_0_cfg2shield_gr_1_data_o [get_bd_pins cfg_0/cfg2shield_gr_1_data_o] [get_bd_pins concat_cfglut_data_o/In3]
  connect_bd_net -net cfg_0_cfg2shield_gr_1_tri_o [get_bd_pins cfg_0/cfg2shield_gr_1_tri_o] [get_bd_pins concat_cfglut_tri_out/In3]
  connect_bd_net -net cfg_0_cfg2shield_gr_1_tri_out [get_bd_pins cfg_0/cfg2shield_gr_1_tri_out] [get_bd_pins concat_cfglut_tri_out/In2]
  connect_bd_net -net cfg_0_cfg2shield_gr_2_data_o [get_bd_pins cfg_0/cfg2shield_gr_2_data_o] [get_bd_pins concat_cfglut_data_o/In5]
  connect_bd_net -net cfg_0_cfg2shield_gr_2_tri_o [get_bd_pins cfg_0/cfg2shield_gr_2_tri_o] [get_bd_pins concat_cfglut_tri_out/In5]
  connect_bd_net -net cfg_0_cfg2shield_gr_2_tri_out [get_bd_pins cfg_0/cfg2shield_gr_2_tri_out] [get_bd_pins concat_cfglut_tri_out/In4]
  connect_bd_net -net cfg_0_cfg2shield_gr_3_data_o [get_bd_pins cfg_0/cfg2shield_gr_3_data_o] [get_bd_pins concat_cfglut_data_o/In7]
  connect_bd_net -net cfg_0_cfg2shield_gr_3_tri_o [get_bd_pins cfg_0/cfg2shield_gr_3_tri_o] [get_bd_pins concat_cfglut_tri_out/In7]
  connect_bd_net -net cfg_0_cfg2shield_gr_3_tri_out [get_bd_pins cfg_0/cfg2shield_gr_3_tri_out] [get_bd_pins concat_cfglut_tri_out/In6]
  connect_bd_net -net concat_cfglut_data_o_dout [get_bd_pins dout] [get_bd_pins concat_cfglut_data_o/dout]
  connect_bd_net -net concat_cfglut_tri_out_dout [get_bd_pins dout1] [get_bd_pins concat_cfglut_tri_out/dout]
  connect_bd_net -net constant_4bits_0_dout [get_bd_pins concat_cfglut_data_o/In0] [get_bd_pins concat_cfglut_data_o/In2] [get_bd_pins concat_cfglut_data_o/In4] [get_bd_pins concat_cfglut_data_o/In6] [get_bd_pins constant_4bits_0/dout]
  connect_bd_net -net interface_switch_0_sw2cfg_data_i [get_bd_pins Din] [get_bd_pins slice_gr_0/Din] [get_bd_pins slice_gr_1/Din] [get_bd_pins slice_gr_2/Din] [get_bd_pins slice_gr_3/Din]
  connect_bd_net -net led_2 [get_bd_pins cfg2led_gr_2] [get_bd_pins cfg_0/cfg2led_gr_2]
  connect_bd_net -net processing_system7_0_FCLK_CLK0 [get_bd_pins s00_axi_aclk] [get_bd_pins cfg_0/s00_axi_aclk]
  connect_bd_net -net shield2cfg_gr_4_data_in_1 [get_bd_pins pb_in] [get_bd_pins cfg_0/pb_in]
  connect_bd_net -net slice_gr_0_Dout [get_bd_pins cfg_0/shield2cfg_gr_0_data_in] [get_bd_pins slice_gr_0/Dout]
  connect_bd_net -net slice_gr_1_Dout [get_bd_pins cfg_0/shield2cfg_gr_1_data_in] [get_bd_pins slice_gr_1/Dout]
  connect_bd_net -net slice_gr_2_Dout [get_bd_pins cfg_0/shield2cfg_gr_2_data_in] [get_bd_pins slice_gr_2/Dout]
  connect_bd_net -net slice_gr_3_Dout [get_bd_pins cfg_0/shield2cfg_gr_3_data_in] [get_bd_pins slice_gr_3/Dout]

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
  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 M00_AXI
  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 M01_AXI

  # Create pins
  create_bd_pin -dir I -from 0 -to 0 -type rst ARESETN
  create_bd_pin -dir I -from 0 -to 0 -type rst M10_ARESETN
  create_bd_pin -dir I -from 0 -to 0 -type rst ap_rst_n
  create_bd_pin -dir I -from 19 -to 0 ar2sw_data_i
  create_bd_pin -dir I -from 0 -to 0 -type rst aux_reset_in
  create_bd_pin -dir O cfg2led_gr_2
  create_bd_pin -dir I -type clk clk
  create_bd_pin -dir I -from 0 -to 0 -type rst ext_reset_in
  create_bd_pin -dir I -from 0 -to 0 mb_3_intr_ack
  create_bd_pin -dir O -type intr iop3_intr_req
  create_bd_pin -dir O led_0
  create_bd_pin -dir O led_1
  create_bd_pin -dir O led_3
  create_bd_pin -dir I -type rst mb_debug_sys_rst
  create_bd_pin -dir I -from 3 -to 0 pb_in
  create_bd_pin -dir I -type clk pg_tracebuffer_clk
  create_bd_pin -dir O rgbled_0
  create_bd_pin -dir O -from 19 -to 0 sw2ar_data_o
  create_bd_pin -dir O -from 19 -to 0 sw2ar_tri_o

  # Create instance: axi_cdma_0, and set properties
  set axi_cdma_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_cdma:4.1 axi_cdma_0 ]
  set_property -dict [ list \
CONFIG.C_INCLUDE_SG {0} \
CONFIG.C_M_AXI_DATA_WIDTH {64} \
CONFIG.C_M_AXI_MAX_BURST_LEN {8} \
 ] $axi_cdma_0

  # Create instance: axi_intc_0, and set properties
  set axi_intc_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_intc:4.1 axi_intc_0 ]

  # Create instance: axi_mem_intercon, and set properties
  set axi_mem_intercon [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_interconnect:2.1 axi_mem_intercon ]
  set_property -dict [ list \
CONFIG.NUM_MI {3} \
 ] $axi_mem_intercon

  # Create instance: cfg_0
  create_hier_cell_cfg_0 $hier_obj cfg_0

  # Create instance: constant_20bit_0, and set properties
  set constant_20bit_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant:1.1 constant_20bit_0 ]
  set_property -dict [ list \
CONFIG.CONST_VAL {0} \
CONFIG.CONST_WIDTH {20} \
 ] $constant_20bit_0

  # Create instance: dff_en_reset_0, and set properties
  set dff_en_reset_0 [ create_bd_cell -type ip -vlnv xilinx.com:XUP:dff_en_reset:1.0 dff_en_reset_0 ]

  # Create instance: function_sel, and set properties
  set function_sel [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_gpio:2.0 function_sel ]
  set_property -dict [ list \
CONFIG.C_ALL_OUTPUTS {0} \
CONFIG.C_GPIO_WIDTH {2} \
 ] $function_sel

  # Create instance: interface_switch_0, and set properties
  set interface_switch_0 [ create_bd_cell -type ip -vlnv xilinx.com:user:interface_switch:1.0 interface_switch_0 ]

  # Create instance: iop3_intr, and set properties
  set iop3_intr [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_gpio:2.0 iop3_intr ]
  set_property -dict [ list \
CONFIG.C_ALL_OUTPUTS {1} \
CONFIG.C_GPIO_WIDTH {1} \
 ] $iop3_intr

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

  # Create instance: mb3_lmb
  create_hier_cell_mb3_lmb $hier_obj mb3_lmb

  # Create instance: mb_axi_periph, and set properties
  set mb_axi_periph [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_interconnect:2.1 mb_axi_periph ]
  set_property -dict [ list \
CONFIG.NUM_MI {13} \
 ] $mb_axi_periph

  # Create instance: pg_o
  create_hier_cell_pg_o $hier_obj pg_o

  # Create instance: rst_clk_wiz_1_100M, and set properties
  set rst_clk_wiz_1_100M [ create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset:5.0 rst_clk_wiz_1_100M ]
  set_property -dict [ list \
CONFIG.C_AUX_RESET_HIGH {1} \
 ] $rst_clk_wiz_1_100M

  # Create instance: smg_0
  create_hier_cell_smg_0 $hier_obj smg_0

  # Create interface connections
  connect_bd_intf_net -intf_net Conn1 [get_bd_intf_pins M00_AXI] [get_bd_intf_pins pg_o/M00_AXI]
  connect_bd_intf_net -intf_net axi_cdma_0_M_AXI [get_bd_intf_pins axi_cdma_0/M_AXI] [get_bd_intf_pins axi_mem_intercon/S00_AXI]
  connect_bd_intf_net -intf_net axi_intc_0_interrupt [get_bd_intf_pins axi_intc_0/interrupt] [get_bd_intf_pins mb/INTERRUPT]
  connect_bd_intf_net -intf_net axi_mem_intercon_M00_AXI [get_bd_intf_pins axi_mem_intercon/M00_AXI] [get_bd_intf_pins pg_o/S_AXI]
  connect_bd_intf_net -intf_net axi_mem_intercon_M01_AXI [get_bd_intf_pins M01_AXI] [get_bd_intf_pins axi_mem_intercon/M01_AXI]
  connect_bd_intf_net -intf_net axi_mem_intercon_M02_AXI [get_bd_intf_pins axi_mem_intercon/M02_AXI] [get_bd_intf_pins smg_0/S_AXI2]
  connect_bd_intf_net -intf_net mb_M_AXI_DP [get_bd_intf_pins mb/M_AXI_DP] [get_bd_intf_pins mb_axi_periph/S00_AXI]
  connect_bd_intf_net -intf_net mb_axi_periph_M00_AXI [get_bd_intf_pins cfg_0/S00_AXI] [get_bd_intf_pins mb_axi_periph/M00_AXI]
  connect_bd_intf_net -intf_net mb_axi_periph_M01_AXI [get_bd_intf_pins axi_cdma_0/S_AXI_LITE] [get_bd_intf_pins mb_axi_periph/M01_AXI]
  connect_bd_intf_net -intf_net mb_axi_periph_M02_AXI [get_bd_intf_pins mb_axi_periph/M02_AXI] [get_bd_intf_pins pg_o/S_AXI3]
  connect_bd_intf_net -intf_net mb_axi_periph_M03_AXI [get_bd_intf_pins axi_intc_0/s_axi] [get_bd_intf_pins mb_axi_periph/M03_AXI]
  connect_bd_intf_net -intf_net mb_axi_periph_M04_AXI [get_bd_intf_pins mb_axi_periph/M04_AXI] [get_bd_intf_pins pg_o/S_AXI1]
  connect_bd_intf_net -intf_net mb_axi_periph_M05_AXI [get_bd_intf_pins mb_axi_periph/M05_AXI] [get_bd_intf_pins pg_o/S_AXI2]
  connect_bd_intf_net -intf_net mb_axi_periph_M06_AXI [get_bd_intf_pins function_sel/S_AXI] [get_bd_intf_pins mb_axi_periph/M06_AXI]
  connect_bd_intf_net -intf_net mb_axi_periph_M07_AXI [get_bd_intf_pins mb_axi_periph/M07_AXI] [get_bd_intf_pins pg_o/s_axi_trace_cntrl]
  connect_bd_intf_net -intf_net mb_axi_periph_M08_AXI [get_bd_intf_pins mb_axi_periph/M08_AXI] [get_bd_intf_pins pg_o/S_AXI_LITE]
  connect_bd_intf_net -intf_net mb_axi_periph_M09_AXI [get_bd_intf_pins mb_axi_periph/M09_AXI] [get_bd_intf_pins smg_0/S_AXI]
  connect_bd_intf_net -intf_net mb_axi_periph_M10_AXI [get_bd_intf_pins mb_axi_periph/M10_AXI] [get_bd_intf_pins smg_0/S_AXI1]
  connect_bd_intf_net -intf_net mb_axi_periph_M11_AXI [get_bd_intf_pins mb_axi_periph/M11_AXI] [get_bd_intf_pins smg_0/S00_AXI]
  connect_bd_intf_net -intf_net mb_axi_periph_M12_AXI [get_bd_intf_pins iop3_intr/S_AXI] [get_bd_intf_pins mb_axi_periph/M12_AXI]
  connect_bd_intf_net -intf_net mb_bram_ctrl_1_BRAM_PORTA [get_bd_intf_pins BRAM_PORTB] [get_bd_intf_pins mb3_lmb/BRAM_PORTB]
  connect_bd_intf_net -intf_net microblaze_0_debug [get_bd_intf_pins DEBUG] [get_bd_intf_pins mb/DEBUG]
  connect_bd_intf_net -intf_net microblaze_0_dlmb_1 [get_bd_intf_pins mb/DLMB] [get_bd_intf_pins mb3_lmb/DLMB]
  connect_bd_intf_net -intf_net microblaze_0_ilmb_1 [get_bd_intf_pins mb/ILMB] [get_bd_intf_pins mb3_lmb/ILMB]

  # Create port connections
  connect_bd_net -net ARESETN_1 [get_bd_pins axi_mem_intercon/ARESETN] [get_bd_pins iop3_intr/s_axi_aresetn] [get_bd_pins mb_axi_periph/ARESETN] [get_bd_pins mb_axi_periph/M00_ARESETN] [get_bd_pins mb_axi_periph/M01_ARESETN] [get_bd_pins mb_axi_periph/M02_ARESETN] [get_bd_pins mb_axi_periph/M03_ARESETN] [get_bd_pins mb_axi_periph/M04_ARESETN] [get_bd_pins mb_axi_periph/M05_ARESETN] [get_bd_pins mb_axi_periph/M06_ARESETN] [get_bd_pins mb_axi_periph/S00_ARESETN] [get_bd_pins rst_clk_wiz_1_100M/interconnect_aresetn]
  connect_bd_net -net ARESETN_2 [get_bd_pins ARESETN] [get_bd_pins pg_o/ARESETN]
  connect_bd_net -net Din_1 [get_bd_pins cfg_0/Din] [get_bd_pins interface_switch_0/sw2cfg_data_i]
  connect_bd_net -net M10_ARESETN_1 [get_bd_pins M10_ARESETN] [get_bd_pins axi_mem_intercon/M02_ARESETN] [get_bd_pins mb_axi_periph/M10_ARESETN] [get_bd_pins mb_axi_periph/M11_ARESETN] [get_bd_pins mb_axi_periph/M12_ARESETN]
  connect_bd_net -net S00_ARESETN_1 [get_bd_pins axi_cdma_0/s_axi_lite_aresetn] [get_bd_pins axi_intc_0/s_axi_aresetn] [get_bd_pins axi_mem_intercon/M00_ARESETN] [get_bd_pins axi_mem_intercon/M01_ARESETN] [get_bd_pins axi_mem_intercon/S00_ARESETN] [get_bd_pins cfg_0/s00_axi_aresetn] [get_bd_pins function_sel/s_axi_aresetn] [get_bd_pins mb_axi_periph/M09_ARESETN] [get_bd_pins pg_o/s_axi_aresetn] [get_bd_pins rst_clk_wiz_1_100M/peripheral_aresetn] [get_bd_pins smg_0/s_axi_aresetn]
  connect_bd_net -net ap_rst_n_1 [get_bd_pins ap_rst_n] [get_bd_pins mb_axi_periph/M07_ARESETN] [get_bd_pins mb_axi_periph/M08_ARESETN] [get_bd_pins pg_o/axi_resetn]
  connect_bd_net -net ar2sw_data_i_1 [get_bd_pins ar2sw_data_i] [get_bd_pins interface_switch_0/ar2sw_data_i] [get_bd_pins pg_o/In1]
  connect_bd_net -net axi_cdma_0_cdma_introut [get_bd_pins axi_cdma_0/cdma_introut] [get_bd_pins axi_intc_0/intr]
  connect_bd_net -net axi_gpio_pg_tri_control_gpio_io_o [get_bd_pins interface_switch_0/pg2sw_tri_o] [get_bd_pins pg_o/gpio_io_o]
  connect_bd_net -net cfg_0_cfg2led_gr_0 [get_bd_pins led_0] [get_bd_pins cfg_0/cfg2led_gr_0]
  connect_bd_net -net cfg_0_cfg2led_gr_1 [get_bd_pins led_1] [get_bd_pins cfg_0/cfg2led_gr_1]
  connect_bd_net -net cfg_0_cfg2led_gr_3 [get_bd_pins led_3] [get_bd_pins cfg_0/cfg2led_gr_3]
  connect_bd_net -net cfg_0_cfg2led_gr_4 [get_bd_pins rgbled_0] [get_bd_pins cfg_0/cfg2led_gr_4]
  connect_bd_net -net clk1_1 [get_bd_pins pg_tracebuffer_clk] [get_bd_pins mb_axi_periph/M07_ACLK] [get_bd_pins mb_axi_periph/M08_ACLK] [get_bd_pins pg_o/m_axi_s2mm_aclk] [get_bd_pins smg_0/clkb]
  connect_bd_net -net concat_cfglut_data_o_dout [get_bd_pins cfg_0/dout] [get_bd_pins interface_switch_0/cfg2sw_data_o]
  connect_bd_net -net concat_cfglut_tri_out_dout [get_bd_pins cfg_0/dout1] [get_bd_pins interface_switch_0/cfg2sw_tri_o]
  connect_bd_net -net constant_20bit_0_dout [get_bd_pins constant_20bit_0/dout] [get_bd_pins interface_switch_0/asm2sw_data_o] [get_bd_pins interface_switch_0/asm2sw_tri_o]
  connect_bd_net -net dff_en_reset_0_q [get_bd_pins iop3_intr_req] [get_bd_pins dff_en_reset_0/q]
  connect_bd_net -net function_sel_gpio_io_o [get_bd_pins function_sel/gpio_io_i] [get_bd_pins function_sel/gpio_io_o] [get_bd_pins interface_switch_0/sel]
  connect_bd_net -net interface_switch_0_sw2ar_data_o [get_bd_pins sw2ar_data_o] [get_bd_pins interface_switch_0/sw2ar_data_o] [get_bd_pins pg_o/In0]
  connect_bd_net -net interface_switch_0_sw2ar_tri_o [get_bd_pins sw2ar_tri_o] [get_bd_pins interface_switch_0/sw2ar_tri_o] [get_bd_pins pg_o/In3]
  connect_bd_net -net iop3_intr_gpio_io_o [get_bd_pins dff_en_reset_0/en] [get_bd_pins iop3_intr/gpio_io_o]
  connect_bd_net -net led_2 [get_bd_pins cfg2led_gr_2] [get_bd_pins cfg_0/cfg2led_gr_2]
  connect_bd_net -net logic_1_dout [get_bd_pins ext_reset_in] [get_bd_pins rst_clk_wiz_1_100M/ext_reset_in]
  connect_bd_net -net logic_1_dout1 [get_bd_pins dff_en_reset_0/d] [get_bd_pins logic_1/dout]
  connect_bd_net -net mb_1_reset_Dout [get_bd_pins aux_reset_in] [get_bd_pins rst_clk_wiz_1_100M/aux_reset_in]
  connect_bd_net -net mdm_1_debug_sys_rst [get_bd_pins mb_debug_sys_rst] [get_bd_pins rst_clk_wiz_1_100M/mb_debug_sys_rst]
  connect_bd_net -net pg_o_Dout [get_bd_pins interface_switch_0/pg2sw_data_o] [get_bd_pins pg_o/Dout]
  connect_bd_net -net pg_o_enb_1d [get_bd_pins pg_o/enb_1d] [get_bd_pins smg_0/probe10]
  connect_bd_net -net processing_system7_0_FCLK_CLK0 [get_bd_pins clk] [get_bd_pins axi_cdma_0/m_axi_aclk] [get_bd_pins axi_cdma_0/s_axi_lite_aclk] [get_bd_pins axi_intc_0/s_axi_aclk] [get_bd_pins axi_mem_intercon/ACLK] [get_bd_pins axi_mem_intercon/M00_ACLK] [get_bd_pins axi_mem_intercon/M01_ACLK] [get_bd_pins axi_mem_intercon/M02_ACLK] [get_bd_pins axi_mem_intercon/S00_ACLK] [get_bd_pins cfg_0/s00_axi_aclk] [get_bd_pins dff_en_reset_0/clk] [get_bd_pins function_sel/s_axi_aclk] [get_bd_pins iop3_intr/s_axi_aclk] [get_bd_pins mb/Clk] [get_bd_pins mb3_lmb/LMB_Clk] [get_bd_pins mb_axi_periph/ACLK] [get_bd_pins mb_axi_periph/M00_ACLK] [get_bd_pins mb_axi_periph/M01_ACLK] [get_bd_pins mb_axi_periph/M02_ACLK] [get_bd_pins mb_axi_periph/M03_ACLK] [get_bd_pins mb_axi_periph/M04_ACLK] [get_bd_pins mb_axi_periph/M05_ACLK] [get_bd_pins mb_axi_periph/M06_ACLK] [get_bd_pins mb_axi_periph/M09_ACLK] [get_bd_pins mb_axi_periph/M10_ACLK] [get_bd_pins mb_axi_periph/M11_ACLK] [get_bd_pins mb_axi_periph/M12_ACLK] [get_bd_pins mb_axi_periph/S00_ACLK] [get_bd_pins pg_o/s_axi_aclk] [get_bd_pins rst_clk_wiz_1_100M/slowest_sync_clk] [get_bd_pins smg_0/s_axi_aclk]
  connect_bd_net -net reset_1 [get_bd_pins mb_3_intr_ack] [get_bd_pins dff_en_reset_0/reset]
  connect_bd_net -net rst_clk_wiz_1_100M_bus_struct_reset [get_bd_pins mb3_lmb/SYS_Rst] [get_bd_pins rst_clk_wiz_1_100M/bus_struct_reset]
  connect_bd_net -net rst_clk_wiz_1_100M_mb_reset [get_bd_pins mb/Reset] [get_bd_pins rst_clk_wiz_1_100M/mb_reset]
  connect_bd_net -net shield2cfg_gr_4_data_in_1 [get_bd_pins pb_in] [get_bd_pins cfg_0/pb_in]
  connect_bd_net -net smg_0_fsm2sw [get_bd_pins interface_switch_0/smg2sw_data_o] [get_bd_pins smg_0/smgdata2sw]
  connect_bd_net -net smg_0_tri2sw [get_bd_pins interface_switch_0/smg2sw_tri_o] [get_bd_pins smg_0/smgtri2sw]
  connect_bd_net -net smg_enb_1d [get_bd_pins pg_o/smg_enb_1d] [get_bd_pins smg_0/smg_enb_1d]
  connect_bd_net -net sw2smg_1 [get_bd_pins interface_switch_0/sw2smg_data_i] [get_bd_pins smg_0/sw2smg]

  # Perform GUI Layout
  regenerate_bd_layout -hierarchy [get_bd_cells /iop3] -layout_string {
   guistr: "# # String gsaved with Nlview 6.5.12  2016-01-29 bk=1.3547 VDI=39 GEI=35 GUI=JA:1.6
#  -string -flagsOSRD
preplace port pg_tracebuffer_clk -pg 1 -y 840 -defaultsOSRD
preplace port iop3_intr_req -pg 1 -y -90 -defaultsOSRD
preplace port cfg2led_gr_2 -pg 1 -y 960 -defaultsOSRD
preplace port mb_debug_sys_rst -pg 1 -y 770 -defaultsOSRD
preplace port M01_AXI -pg 1 -y 500 -defaultsOSRD
preplace port DEBUG -pg 1 -y 910 -defaultsOSRD
preplace port led_0 -pg 1 -y 920 -defaultsOSRD
preplace port led_1 -pg 1 -y 940 -defaultsOSRD
preplace port led_3 -pg 1 -y 980 -defaultsOSRD
preplace port clk -pg 1 -y 660 -defaultsOSRD
preplace port rgbled_0 -pg 1 -y 1000 -defaultsOSRD
preplace port M00_AXI -pg 1 -y 270 -defaultsOSRD
preplace port BRAM_PORTB -pg 1 -y 940 -defaultsOSRD
preplace portBus M10_ARESETN -pg 1 -y 600 -defaultsOSRD
preplace portBus sw2ar_data_o -pg 1 -y 1070 -defaultsOSRD
preplace portBus ar2sw_data_i -pg 1 -y 960 -defaultsOSRD
preplace portBus ARESETN -pg 1 -y 20 -defaultsOSRD
preplace portBus sw2ar_tri_o -pg 1 -y 1090 -defaultsOSRD
preplace portBus aux_reset_in -pg 1 -y 750 -defaultsOSRD
preplace portBus pb_in -pg 1 -y 1130 -defaultsOSRD
preplace portBus ap_rst_n -pg 1 -y 40 -defaultsOSRD
preplace portBus mb_3_intr_ack -pg 1 -y -60 -defaultsOSRD
preplace portBus ext_reset_in -pg 1 -y 730 -defaultsOSRD
preplace inst axi_intc_0 -pg 1 -lvl 6 -y 830 -defaultsOSRD
preplace inst constant_20bit_0 -pg 1 -lvl 9 -y 1060 -defaultsOSRD
preplace inst mb -pg 1 -lvl 7 -y 910 -defaultsOSRD
preplace inst cfg_0 -pg 1 -lvl 13 -y 1120 -defaultsOSRD
preplace inst axi_cdma_0 -pg 1 -lvl 11 -y 560 -defaultsOSRD
preplace inst logic_1 -pg 1 -lvl 2 -y -170 -defaultsOSRD
preplace inst function_sel -pg 1 -lvl 6 -y 1040 -defaultsOSRD
preplace inst pg_o -pg 1 -lvl 13 -y 290 -defaultsOSRD
preplace inst mb3_lmb -pg 1 -lvl 8 -y 980 -defaultsOSRD
preplace inst dff_en_reset_0 -pg 1 -lvl 3 -y -90 -defaultsOSRD
preplace inst mb_axi_periph -pg 1 -lvl 5 -y 360 -defaultsOSRD
preplace inst iop3_intr -pg 1 -lvl 1 -y -210 -defaultsOSRD
preplace inst smg_0 -pg 1 -lvl 13 -y 870 -defaultsOSRD
preplace inst rst_clk_wiz_1_100M -pg 1 -lvl 4 -y 750 -defaultsOSRD
preplace inst axi_mem_intercon -pg 1 -lvl 12 -y 460 -defaultsOSRD
preplace inst interface_switch_0 -pg 1 -lvl 10 -y 960 -defaultsOSRD
preplace netloc Conn1 1 13 1 NJ
preplace netloc axi_mem_intercon_M01_AXI 1 12 2 NJ 90 NJ
preplace netloc axi_intc_0_interrupt 1 6 1 1800
preplace netloc mb_M_AXI_DP 1 4 4 1090 730 NJ 730 NJ 730 2250
preplace netloc iop3_intr_gpio_io_o 1 1 2 NJ -220 430
preplace netloc axi_gpio_pg_tri_control_gpio_io_o 1 9 5 NJ 40 NJ 40 NJ 40 NJ 40 4520
preplace netloc mb_axi_periph_M02_AXI 1 5 8 NJ 250 NJ 250 NJ 250 NJ 250 NJ 250 NJ 250 NJ 250 NJ
preplace netloc axi_cdma_0_M_AXI 1 11 1 3670
preplace netloc sw2smg_1 1 10 3 NJ 930 NJ 930 NJ
preplace netloc ar2sw_data_i_1 1 0 13 NJ 960 NJ 960 NJ 960 NJ 960 NJ 960 NJ 960 NJ 1000 NJ 870 NJ 870 2750 200 NJ 200 NJ 200 NJ
preplace netloc mb_axi_periph_M10_AXI 1 5 8 NJ 290 NJ 290 NJ 290 NJ 290 NJ 290 NJ 290 NJ 290 4090
preplace netloc M10_ARESETN_1 1 0 12 NJ 600 NJ 600 NJ 600 NJ 600 1050 740 NJ 660 NJ 660 NJ 660 NJ 660 NJ 660 NJ 660 NJ
preplace netloc ap_rst_n_1 1 0 13 NJ 40 NJ 40 NJ 40 NJ 40 1080 0 NJ 0 NJ 0 NJ 0 NJ 0 NJ 0 NJ 0 NJ 0 NJ
preplace netloc constant_20bit_0_dout 1 9 1 NJ
preplace netloc function_sel_gpio_io_o 1 6 4 1790 1020 NJ 880 NJ 880 NJ
preplace netloc mb_bram_ctrl_1_BRAM_PORTA 1 0 8 NJ 940 NJ 940 NJ 940 NJ 940 NJ 940 NJ 940 NJ 990 NJ
preplace netloc mb_axi_periph_M07_AXI 1 5 8 NJ 180 NJ 180 NJ 180 NJ 180 NJ 180 NJ 180 NJ 180 NJ
preplace netloc mb_axi_periph_M04_AXI 1 5 8 1390 210 NJ 210 NJ 210 NJ 210 NJ 210 NJ 210 NJ 210 NJ
preplace netloc mb_axi_periph_M00_AXI 1 5 8 NJ 240 NJ 240 NJ 240 NJ 240 NJ 240 NJ 240 NJ 240 4060
preplace netloc Din_1 1 10 3 NJ 910 NJ 910 NJ
preplace netloc smg_0_fsm2sw 1 9 5 NJ 740 NJ 740 NJ 740 NJ 730 4500
preplace netloc clk1_1 1 0 13 NJ 840 NJ 840 NJ 840 NJ 840 1070 770 NJ 710 NJ 710 NJ 710 NJ 710 NJ 710 NJ 710 NJ 710 4130
preplace netloc shield2cfg_gr_4_data_in_1 1 0 13 NJ 1120 NJ 1120 NJ 1120 NJ 1120 NJ 1120 NJ 1120 NJ 1120 NJ 1120 NJ 1120 NJ 1120 NJ 1120 NJ 1120 NJ
preplace netloc mb_1_reset_Dout 1 0 4 NJ 750 NJ 750 NJ 750 N
preplace netloc ARESETN_1 1 0 12 -60 -10 NJ -10 NJ -10 NJ -10 1010 -20 NJ -20 NJ -20 NJ -20 NJ -20 NJ -20 NJ -20 NJ
preplace netloc mb_axi_periph_M11_AXI 1 5 8 NJ 300 NJ 300 NJ 300 NJ 300 NJ 300 NJ 300 NJ 300 4100
preplace netloc mb_axi_periph_M06_AXI 1 5 1 1450
preplace netloc axi_mem_intercon_M00_AXI 1 12 1 4080
preplace netloc microblaze_0_ilmb_1 1 7 1 2280
preplace netloc pg_o_enb_1d 1 12 2 4210 80 4500
preplace netloc smg_0_tri2sw 1 9 5 NJ 730 NJ 700 NJ 700 NJ 700 4510
preplace netloc ARESETN_2 1 0 13 NJ 0 NJ 0 NJ 0 NJ 0 NJ -10 NJ -10 NJ -10 NJ -10 NJ -10 NJ -10 NJ -10 NJ -10 NJ
preplace netloc cfg_0_cfg2led_gr_0 1 13 1 NJ
preplace netloc mb_axi_periph_M12_AXI 1 0 6 -70 660 NJ 660 NJ 660 NJ 660 NJ 720 1400
preplace netloc axi_mem_intercon_M02_AXI 1 12 1 4020
preplace netloc logic_1_dout1 1 2 1 420
preplace netloc concat_cfglut_data_o_dout 1 9 5 NJ 720 NJ 720 NJ 720 NJ 720 4520
preplace netloc cfg_0_cfg2led_gr_1 1 13 1 NJ
preplace netloc axi_cdma_0_cdma_introut 1 5 7 1520 1110 NJ 1110 NJ 1110 NJ 1110 NJ 1110 NJ 1110 3650
preplace netloc mb_axi_periph_M05_AXI 1 5 8 NJ 220 NJ 220 NJ 220 NJ 220 NJ 220 NJ 220 NJ 220 NJ
preplace netloc concat_cfglut_tri_out_dout 1 9 5 NJ 680 NJ 680 NJ 680 NJ 680 4530
preplace netloc rst_clk_wiz_1_100M_bus_struct_reset 1 4 4 NJ 750 NJ 720 NJ 720 2300
preplace netloc mb_axi_periph_M03_AXI 1 5 1 1470
preplace netloc smg_enb_1d 1 12 2 4200 70 4540
preplace netloc cfg_0_cfg2led_gr_3 1 13 1 NJ
preplace netloc rst_clk_wiz_1_100M_mb_reset 1 4 3 NJ 760 NJ 750 NJ
preplace netloc logic_1_dout 1 0 4 NJ 730 NJ 730 NJ 730 N
preplace netloc interface_switch_0_sw2ar_tri_o 1 10 4 3400 730 NJ 730 4140 710 NJ
preplace netloc cfg_0_cfg2led_gr_4 1 13 1 NJ
preplace netloc led_2 1 13 1 NJ
preplace netloc microblaze_0_dlmb_1 1 7 1 2320
preplace netloc processing_system7_0_FCLK_CLK0 1 0 13 -90 480 NJ 480 440 480 690 480 1060 820 1480 920 1800 1010 2290 570 NJ 570 NJ 570 3390 480 3650 260 4040
preplace netloc microblaze_0_debug 1 0 7 NJ 910 NJ 910 NJ 910 NJ 910 NJ 910 NJ 910 NJ
preplace netloc mb_axi_periph_M09_AXI 1 5 8 NJ 270 NJ 270 NJ 270 NJ 270 NJ 270 NJ 270 NJ 270 4110
preplace netloc mb_axi_periph_M08_AXI 1 5 8 NJ 170 NJ 170 NJ 170 NJ 170 NJ 170 NJ 170 NJ 170 NJ
preplace netloc mb_axi_periph_M01_AXI 1 5 6 NJ 260 NJ 260 NJ 260 NJ 260 NJ 260 3380
preplace netloc dff_en_reset_0_q 1 3 11 NJ -90 NJ -90 NJ -90 NJ -90 NJ -90 NJ -90 NJ -90 NJ -90 NJ -90 NJ -90 NJ
preplace netloc reset_1 1 0 3 NJ -60 NJ -60 NJ
preplace netloc interface_switch_0_sw2ar_data_o 1 10 4 NJ 990 NJ 990 4160 1000 NJ
preplace netloc mdm_1_debug_sys_rst 1 0 4 NJ 770 NJ 770 NJ 770 N
preplace netloc pg_o_Dout 1 9 5 NJ 60 NJ 60 NJ 60 NJ 60 4510
preplace netloc S00_ARESETN_1 1 4 9 1080 780 1500 700 NJ 700 NJ 700 NJ 700 NJ 700 3380 640 3660 230 4050
levelinfo -pg 1 -110 70 360 620 850 1240 1660 2030 2410 2670 3220 3530 3870 4360 4620 -top -270 -bot 1230
",
}

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

  # Create pins
  create_bd_pin -dir I -from 0 -to 0 -type rst M06_ARESETN
  create_bd_pin -dir I -from 0 -to 0 -type rst aux_reset_in
  create_bd_pin -dir I -type clk clk
  create_bd_pin -dir I -from 0 -to 0 -type rst ext_reset_in
  create_bd_pin -dir I -from 0 -to 0 mb_2_intr_ack
  create_bd_pin -dir O -type intr iop2_intr_req
  create_bd_pin -dir I -type rst mb_debug_sys_rst
  create_bd_pin -dir I -from 7 -to 0 pmod2sw_data_in
  create_bd_pin -dir O -from 7 -to 0 sw2pmod_data_out
  create_bd_pin -dir O -from 7 -to 0 sw2pmod_tri_out

  # Create instance: dff_en_reset_0, and set properties
  set dff_en_reset_0 [ create_bd_cell -type ip -vlnv xilinx.com:XUP:dff_en_reset:1.0 dff_en_reset_0 ]

  # Create instance: iop2_intr, and set properties
  set iop2_intr [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_gpio:2.0 iop2_intr ]
  set_property -dict [ list \
CONFIG.C_ALL_OUTPUTS {1} \
CONFIG.C_GPIO_WIDTH {1} \
 ] $iop2_intr

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
CONFIG.NUM_MI {7} \
 ] $microblaze_0_axi_periph

  # Create instance: rst_clk_wiz_1_100M, and set properties
  set rst_clk_wiz_1_100M [ create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset:5.0 rst_clk_wiz_1_100M ]
  set_property -dict [ list \
CONFIG.C_AUX_RESET_HIGH {1} \
 ] $rst_clk_wiz_1_100M

  # Create interface connections
  connect_bd_intf_net -intf_net mb2_intc_interrupt [get_bd_intf_pins mb/INTERRUPT] [get_bd_intf_pins mb2_intc/interrupt]
  connect_bd_intf_net -intf_net mb_bram_ctrl_1_BRAM_PORTA [get_bd_intf_pins BRAM_PORTB] [get_bd_intf_pins mb2_lmb/BRAM_PORTB]
  connect_bd_intf_net -intf_net microblaze_0_M_AXI_DP [get_bd_intf_pins mb/M_AXI_DP] [get_bd_intf_pins microblaze_0_axi_periph/S00_AXI]
  connect_bd_intf_net -intf_net microblaze_0_axi_periph_M00_AXI [get_bd_intf_pins mb2_spi/AXI_LITE] [get_bd_intf_pins microblaze_0_axi_periph/M00_AXI]
  connect_bd_intf_net -intf_net microblaze_0_axi_periph_M01_AXI [get_bd_intf_pins mb2_iic/S_AXI] [get_bd_intf_pins microblaze_0_axi_periph/M01_AXI]
  connect_bd_intf_net -intf_net microblaze_0_axi_periph_M02_AXI [get_bd_intf_pins mb2_pmod_io_switch/S00_AXI] [get_bd_intf_pins microblaze_0_axi_periph/M02_AXI]
  connect_bd_intf_net -intf_net microblaze_0_axi_periph_M03_AXI [get_bd_intf_pins mb2_gpio/S_AXI] [get_bd_intf_pins microblaze_0_axi_periph/M03_AXI]
  connect_bd_intf_net -intf_net microblaze_0_axi_periph_M04_AXI [get_bd_intf_pins mb2_timer/S_AXI] [get_bd_intf_pins microblaze_0_axi_periph/M04_AXI]
  connect_bd_intf_net -intf_net microblaze_0_axi_periph_M05_AXI [get_bd_intf_pins mb2_intc/s_axi] [get_bd_intf_pins microblaze_0_axi_periph/M05_AXI]
  connect_bd_intf_net -intf_net microblaze_0_axi_periph_M06_AXI [get_bd_intf_pins iop2_intr/S_AXI] [get_bd_intf_pins microblaze_0_axi_periph/M06_AXI]
  connect_bd_intf_net -intf_net microblaze_0_debug [get_bd_intf_pins DEBUG] [get_bd_intf_pins mb/DEBUG]
  connect_bd_intf_net -intf_net microblaze_0_dlmb_1 [get_bd_intf_pins mb/DLMB] [get_bd_intf_pins mb2_lmb/DLMB]
  connect_bd_intf_net -intf_net microblaze_0_ilmb_1 [get_bd_intf_pins mb/ILMB] [get_bd_intf_pins mb2_lmb/ILMB]

  # Create port connections
  connect_bd_net -net M06_ARESETN_1 [get_bd_pins M06_ARESETN] [get_bd_pins microblaze_0_axi_periph/M06_ARESETN]
  connect_bd_net -net dff_en_reset_0_q [get_bd_pins iop2_intr_req] [get_bd_pins dff_en_reset_0/q]
  connect_bd_net -net iop2_intr_gpio_io_o [get_bd_pins dff_en_reset_0/en] [get_bd_pins iop2_intr/gpio_io_o]
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
  connect_bd_net -net processing_system7_0_FCLK_CLK0 [get_bd_pins clk] [get_bd_pins dff_en_reset_0/clk] [get_bd_pins iop2_intr/s_axi_aclk] [get_bd_pins mb/Clk] [get_bd_pins mb2_gpio/s_axi_aclk] [get_bd_pins mb2_iic/s_axi_aclk] [get_bd_pins mb2_intc/s_axi_aclk] [get_bd_pins mb2_lmb/LMB_Clk] [get_bd_pins mb2_pmod_io_switch/s00_axi_aclk] [get_bd_pins mb2_spi/ext_spi_clk] [get_bd_pins mb2_spi/s_axi_aclk] [get_bd_pins mb2_timer/s_axi_aclk] [get_bd_pins microblaze_0_axi_periph/ACLK] [get_bd_pins microblaze_0_axi_periph/M00_ACLK] [get_bd_pins microblaze_0_axi_periph/M01_ACLK] [get_bd_pins microblaze_0_axi_periph/M02_ACLK] [get_bd_pins microblaze_0_axi_periph/M03_ACLK] [get_bd_pins microblaze_0_axi_periph/M04_ACLK] [get_bd_pins microblaze_0_axi_periph/M05_ACLK] [get_bd_pins microblaze_0_axi_periph/M06_ACLK] [get_bd_pins microblaze_0_axi_periph/S00_ACLK] [get_bd_pins rst_clk_wiz_1_100M/slowest_sync_clk]
  connect_bd_net -net reset_1 [get_bd_pins mb_2_intr_ack] [get_bd_pins dff_en_reset_0/reset]
  connect_bd_net -net rst_clk_wiz_1_100M_bus_struct_reset [get_bd_pins mb2_lmb/SYS_Rst] [get_bd_pins rst_clk_wiz_1_100M/bus_struct_reset]
  connect_bd_net -net rst_clk_wiz_1_100M_interconnect_aresetn [get_bd_pins microblaze_0_axi_periph/ARESETN] [get_bd_pins rst_clk_wiz_1_100M/interconnect_aresetn]
  connect_bd_net -net rst_clk_wiz_1_100M_mb_reset [get_bd_pins mb/Reset] [get_bd_pins rst_clk_wiz_1_100M/mb_reset]
  connect_bd_net -net rst_clk_wiz_1_100M_peripheral_aresetn [get_bd_pins iop2_intr/s_axi_aresetn] [get_bd_pins mb2_gpio/s_axi_aresetn] [get_bd_pins mb2_iic/s_axi_aresetn] [get_bd_pins mb2_intc/s_axi_aresetn] [get_bd_pins mb2_pmod_io_switch/s00_axi_aresetn] [get_bd_pins mb2_spi/s_axi_aresetn] [get_bd_pins mb2_timer/s_axi_aresetn] [get_bd_pins microblaze_0_axi_periph/M00_ARESETN] [get_bd_pins microblaze_0_axi_periph/M01_ARESETN] [get_bd_pins microblaze_0_axi_periph/M02_ARESETN] [get_bd_pins microblaze_0_axi_periph/M03_ARESETN] [get_bd_pins microblaze_0_axi_periph/M04_ARESETN] [get_bd_pins microblaze_0_axi_periph/M05_ARESETN] [get_bd_pins microblaze_0_axi_periph/S00_ARESETN] [get_bd_pins rst_clk_wiz_1_100M/peripheral_aresetn]

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

  # Create pins
  create_bd_pin -dir I -from 0 -to 0 -type rst M06_ARESETN
  create_bd_pin -dir I -from 0 -to 0 -type rst aux_reset_in
  create_bd_pin -dir I -type clk clk
  create_bd_pin -dir I -from 0 -to 0 -type rst ext_reset_in
  create_bd_pin -dir I -from 0 -to 0 mb_1_intr_ack
  create_bd_pin -dir O -type intr iop1_intr_req
  create_bd_pin -dir I -type rst mb_debug_sys_rst
  create_bd_pin -dir I -from 7 -to 0 pmod2sw_data_in
  create_bd_pin -dir O -from 7 -to 0 sw2pmod_data_out
  create_bd_pin -dir O -from 7 -to 0 sw2pmod_tri_out

  # Create instance: dff_en_reset_0, and set properties
  set dff_en_reset_0 [ create_bd_cell -type ip -vlnv xilinx.com:XUP:dff_en_reset:1.0 dff_en_reset_0 ]

  # Create instance: iop1_intr, and set properties
  set iop1_intr [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_gpio:2.0 iop1_intr ]
  set_property -dict [ list \
CONFIG.C_ALL_OUTPUTS {1} \
CONFIG.C_GPIO_WIDTH {1} \
 ] $iop1_intr

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
CONFIG.NUM_MI {7} \
 ] $microblaze_0_axi_periph

  # Create instance: rst_clk_wiz_1_100M, and set properties
  set rst_clk_wiz_1_100M [ create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset:5.0 rst_clk_wiz_1_100M ]
  set_property -dict [ list \
CONFIG.C_AUX_RESET_HIGH {1} \
 ] $rst_clk_wiz_1_100M

  # Create interface connections
  connect_bd_intf_net -intf_net mb1_intc_interrupt [get_bd_intf_pins mb/INTERRUPT] [get_bd_intf_pins mb1_intc/interrupt]
  connect_bd_intf_net -intf_net mb_bram_ctrl_1_BRAM_PORTA [get_bd_intf_pins BRAM_PORTB] [get_bd_intf_pins mb1_lmb/BRAM_PORTB]
  connect_bd_intf_net -intf_net microblaze_0_M_AXI_DP [get_bd_intf_pins mb/M_AXI_DP] [get_bd_intf_pins microblaze_0_axi_periph/S00_AXI]
  connect_bd_intf_net -intf_net microblaze_0_axi_periph_M00_AXI [get_bd_intf_pins mb1_spi/AXI_LITE] [get_bd_intf_pins microblaze_0_axi_periph/M00_AXI]
  connect_bd_intf_net -intf_net microblaze_0_axi_periph_M01_AXI [get_bd_intf_pins mb1_iic/S_AXI] [get_bd_intf_pins microblaze_0_axi_periph/M01_AXI]
  connect_bd_intf_net -intf_net microblaze_0_axi_periph_M02_AXI [get_bd_intf_pins mb1_pmod_io_switch/S00_AXI] [get_bd_intf_pins microblaze_0_axi_periph/M02_AXI]
  connect_bd_intf_net -intf_net microblaze_0_axi_periph_M03_AXI [get_bd_intf_pins mb1_gpio/S_AXI] [get_bd_intf_pins microblaze_0_axi_periph/M03_AXI]
  connect_bd_intf_net -intf_net microblaze_0_axi_periph_M04_AXI [get_bd_intf_pins mb1_timer/S_AXI] [get_bd_intf_pins microblaze_0_axi_periph/M04_AXI]
  connect_bd_intf_net -intf_net microblaze_0_axi_periph_M05_AXI [get_bd_intf_pins mb1_intc/s_axi] [get_bd_intf_pins microblaze_0_axi_periph/M05_AXI]
  connect_bd_intf_net -intf_net microblaze_0_axi_periph_M06_AXI [get_bd_intf_pins iop1_intr/S_AXI] [get_bd_intf_pins microblaze_0_axi_periph/M06_AXI]
  connect_bd_intf_net -intf_net microblaze_0_debug [get_bd_intf_pins DEBUG] [get_bd_intf_pins mb/DEBUG]
  connect_bd_intf_net -intf_net microblaze_0_dlmb_1 [get_bd_intf_pins mb/DLMB] [get_bd_intf_pins mb1_lmb/DLMB]
  connect_bd_intf_net -intf_net microblaze_0_ilmb_1 [get_bd_intf_pins mb/ILMB] [get_bd_intf_pins mb1_lmb/ILMB]

  # Create port connections
  connect_bd_net -net M06_ARESETN_1 [get_bd_pins M06_ARESETN] [get_bd_pins microblaze_0_axi_periph/M06_ARESETN]
  connect_bd_net -net dff_en_reset_0_q [get_bd_pins iop1_intr_req] [get_bd_pins dff_en_reset_0/q]
  connect_bd_net -net iop1_intr_gpio_io_o [get_bd_pins dff_en_reset_0/en] [get_bd_pins iop1_intr/gpio_io_o]
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
  connect_bd_net -net processing_system7_0_FCLK_CLK0 [get_bd_pins clk] [get_bd_pins dff_en_reset_0/clk] [get_bd_pins iop1_intr/s_axi_aclk] [get_bd_pins mb/Clk] [get_bd_pins mb1_gpio/s_axi_aclk] [get_bd_pins mb1_iic/s_axi_aclk] [get_bd_pins mb1_intc/s_axi_aclk] [get_bd_pins mb1_lmb/LMB_Clk] [get_bd_pins mb1_pmod_io_switch/s00_axi_aclk] [get_bd_pins mb1_spi/ext_spi_clk] [get_bd_pins mb1_spi/s_axi_aclk] [get_bd_pins mb1_timer/s_axi_aclk] [get_bd_pins microblaze_0_axi_periph/ACLK] [get_bd_pins microblaze_0_axi_periph/M00_ACLK] [get_bd_pins microblaze_0_axi_periph/M01_ACLK] [get_bd_pins microblaze_0_axi_periph/M02_ACLK] [get_bd_pins microblaze_0_axi_periph/M03_ACLK] [get_bd_pins microblaze_0_axi_periph/M04_ACLK] [get_bd_pins microblaze_0_axi_periph/M05_ACLK] [get_bd_pins microblaze_0_axi_periph/M06_ACLK] [get_bd_pins microblaze_0_axi_periph/S00_ACLK] [get_bd_pins rst_clk_wiz_1_100M/slowest_sync_clk]
  connect_bd_net -net reset_1 [get_bd_pins mb_1_intr_ack] [get_bd_pins dff_en_reset_0/reset]
  connect_bd_net -net rst_clk_wiz_1_100M_bus_struct_reset [get_bd_pins mb1_lmb/SYS_Rst] [get_bd_pins rst_clk_wiz_1_100M/bus_struct_reset]
  connect_bd_net -net rst_clk_wiz_1_100M_interconnect_aresetn [get_bd_pins microblaze_0_axi_periph/ARESETN] [get_bd_pins rst_clk_wiz_1_100M/interconnect_aresetn]
  connect_bd_net -net rst_clk_wiz_1_100M_mb_reset [get_bd_pins mb/Reset] [get_bd_pins rst_clk_wiz_1_100M/mb_reset]
  connect_bd_net -net rst_clk_wiz_1_100M_peripheral_aresetn [get_bd_pins iop1_intr/s_axi_aresetn] [get_bd_pins mb1_gpio/s_axi_aresetn] [get_bd_pins mb1_iic/s_axi_aresetn] [get_bd_pins mb1_intc/s_axi_aresetn] [get_bd_pins mb1_pmod_io_switch/s00_axi_aresetn] [get_bd_pins mb1_spi/s_axi_aresetn] [get_bd_pins mb1_timer/s_axi_aresetn] [get_bd_pins microblaze_0_axi_periph/M00_ARESETN] [get_bd_pins microblaze_0_axi_periph/M01_ARESETN] [get_bd_pins microblaze_0_axi_periph/M02_ARESETN] [get_bd_pins microblaze_0_axi_periph/M03_ARESETN] [get_bd_pins microblaze_0_axi_periph/M04_ARESETN] [get_bd_pins microblaze_0_axi_periph/M05_ARESETN] [get_bd_pins microblaze_0_axi_periph/S00_ARESETN] [get_bd_pins rst_clk_wiz_1_100M/peripheral_aresetn]

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

  # Create ports
  set ar2sw_data_i [ create_bd_port -dir I -from 19 -to 0 ar2sw_data_i ]
  set led_0 [ create_bd_port -dir O led_0 ]
  set led_1 [ create_bd_port -dir O led_1 ]
  set led_2 [ create_bd_port -dir O led_2 ]
  set led_3 [ create_bd_port -dir O led_3 ]
  set pb_in [ create_bd_port -dir I -from 3 -to 0 pb_in ]
  set pmodJA_data_in [ create_bd_port -dir I -from 7 -to 0 pmodJA_data_in ]
  set pmodJA_data_out [ create_bd_port -dir O -from 7 -to 0 pmodJA_data_out ]
  set pmodJA_tri_out [ create_bd_port -dir O -from 7 -to 0 pmodJA_tri_out ]
  set pmodJB_data_in [ create_bd_port -dir I -from 7 -to 0 pmodJB_data_in ]
  set pmodJB_data_out [ create_bd_port -dir O -from 7 -to 0 pmodJB_data_out ]
  set pmodJB_tri_out [ create_bd_port -dir O -from 7 -to 0 pmodJB_tri_out ]
  set rgbled_0 [ create_bd_port -dir O rgbled_0 ]
  set sw2ar_data_o [ create_bd_port -dir O -from 19 -to 0 sw2ar_data_o ]
  set sw2ar_tri_o [ create_bd_port -dir O -from 19 -to 0 sw2ar_tri_o ]

  # Create instance: iop1
  create_hier_cell_iop1 [current_bd_instance .] iop1

  # Create instance: mb_1_intr_ack, and set properties
  set mb_1_intr_ack [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice:1.0 mb_1_intr_ack ]
  set_property -dict [ list \
CONFIG.DIN_FROM {4} \
CONFIG.DIN_TO {4} \
CONFIG.DIN_WIDTH {7} \
CONFIG.DOUT_WIDTH {1} \
 ] $mb_1_intr_ack

  # Create instance: iop2
  create_hier_cell_iop2 [current_bd_instance .] iop2

  # Create instance: mb_2_intr_ack, and set properties
  set mb_2_intr_ack [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice:1.0 mb_2_intr_ack ]
  set_property -dict [ list \
CONFIG.DIN_FROM {5} \
CONFIG.DIN_TO {5} \
CONFIG.DIN_WIDTH {7} \
CONFIG.DOUT_WIDTH {1} \
 ] $mb_2_intr_ack

  # Create instance: iop3
  create_hier_cell_iop3 [current_bd_instance .] iop3

  # Create instance: mb_3_intr_ack, and set properties
  set mb_3_intr_ack [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice:1.0 mb_3_intr_ack ]
  set_property -dict [ list \
CONFIG.DIN_FROM {6} \
CONFIG.DIN_TO {6} \
CONFIG.DIN_WIDTH {7} \
CONFIG.DOUT_WIDTH {1} \
 ] $mb_3_intr_ack

  # Create instance: iop_interrupts, and set properties
  set iop_interrupts [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconcat:2.1 iop_interrupts ]
  set_property -dict [ list \
CONFIG.NUM_PORTS {3} \
 ] $iop_interrupts

  # Create instance: logic_1, and set properties
  set logic_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant:1.1 logic_1 ]

  # Create instance: mb_1_reset, and set properties
  set mb_1_reset [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice:1.0 mb_1_reset ]
  set_property -dict [ list \
CONFIG.DIN_FROM {0} \
CONFIG.DIN_TO {0} \
CONFIG.DIN_WIDTH {7} \
CONFIG.DOUT_WIDTH {1} \
 ] $mb_1_reset

  # Create instance: mb_2_reset, and set properties
  set mb_2_reset [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice:1.0 mb_2_reset ]
  set_property -dict [ list \
CONFIG.DIN_FROM {1} \
CONFIG.DIN_TO {1} \
CONFIG.DIN_WIDTH {7} \
CONFIG.DOUT_WIDTH {1} \
 ] $mb_2_reset

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
CONFIG.PCW_ACT_FPGA1_PERIPHERAL_FREQMHZ {100.000000} \
CONFIG.PCW_ACT_FPGA2_PERIPHERAL_FREQMHZ {10.000000} \
CONFIG.PCW_ACT_FPGA3_PERIPHERAL_FREQMHZ {10.000000} \
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
CONFIG.PCW_CLK1_FREQ {100000000} \
CONFIG.PCW_CLK2_FREQ {10000000} \
CONFIG.PCW_CLK3_FREQ {10000000} \
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
CONFIG.PCW_EN_CLK2_PORT {0} \
CONFIG.PCW_EN_CLK3_PORT {0} \
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
CONFIG.PCW_EN_EMIO_I2C0 {0} \
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
CONFIG.PCW_EN_I2C0 {0} \
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
CONFIG.PCW_FCLK1_PERIPHERAL_DIVISOR0 {5} \
CONFIG.PCW_FCLK1_PERIPHERAL_DIVISOR1 {2} \
CONFIG.PCW_FCLK2_PERIPHERAL_CLKSRC {IO PLL} \
CONFIG.PCW_FCLK2_PERIPHERAL_DIVISOR0 {1} \
CONFIG.PCW_FCLK2_PERIPHERAL_DIVISOR1 {1} \
CONFIG.PCW_FCLK3_PERIPHERAL_CLKSRC {IO PLL} \
CONFIG.PCW_FCLK3_PERIPHERAL_DIVISOR0 {1} \
CONFIG.PCW_FCLK3_PERIPHERAL_DIVISOR1 {1} \
CONFIG.PCW_FCLK_CLK0_BUF {true} \
CONFIG.PCW_FCLK_CLK1_BUF {true} \
CONFIG.PCW_FCLK_CLK2_BUF {false} \
CONFIG.PCW_FCLK_CLK3_BUF {false} \
CONFIG.PCW_FPGA0_PERIPHERAL_FREQMHZ {100} \
CONFIG.PCW_FPGA1_PERIPHERAL_FREQMHZ {100} \
CONFIG.PCW_FPGA2_PERIPHERAL_FREQMHZ {100} \
CONFIG.PCW_FPGA3_PERIPHERAL_FREQMHZ {160} \
CONFIG.PCW_FPGA_FCLK0_ENABLE {1} \
CONFIG.PCW_FPGA_FCLK1_ENABLE {1} \
CONFIG.PCW_FPGA_FCLK2_ENABLE {0} \
CONFIG.PCW_FPGA_FCLK3_ENABLE {0} \
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
CONFIG.PCW_I2C0_GRP_INT_ENABLE {0} \
CONFIG.PCW_I2C0_GRP_INT_IO {<Select>} \
CONFIG.PCW_I2C0_HIGHADDR {0xE0004FFF} \
CONFIG.PCW_I2C0_I2C0_IO {<Select>} \
CONFIG.PCW_I2C0_PERIPHERAL_ENABLE {0} \
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
CONFIG.PCW_I2C_PERIPHERAL_FREQMHZ {25} \
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
CONFIG.PCW_USE_M_AXI_GP1 {0} \
CONFIG.PCW_USE_PROC_EVENT_BUS {0} \
CONFIG.PCW_USE_PS_SLCR_REGISTERS {0} \
CONFIG.PCW_USE_S_AXI_ACP {0} \
CONFIG.PCW_USE_S_AXI_GP0 {0} \
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
CONFIG.NUM_MI {4} \
 ] $processing_system7_0_axi_periph

  # Create instance: rst_processing_system7_0_100M, and set properties
  set rst_processing_system7_0_100M [ create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset:5.0 rst_processing_system7_0_100M ]

  # Create instance: rst_processing_system7_0_200M, and set properties
  set rst_processing_system7_0_200M [ create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset:5.0 rst_processing_system7_0_200M ]

  # Create instance: system_interrupts, and set properties
  set system_interrupts [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_intc:4.1 system_interrupts ]

  # Create interface connections
  connect_bd_intf_net -intf_net iop3_M00_AXI [get_bd_intf_pins iop3/M00_AXI] [get_bd_intf_pins processing_system7_0/S_AXI_HP2]
  connect_bd_intf_net -intf_net iop3_M01_AXI [get_bd_intf_pins iop3/M01_AXI] [get_bd_intf_pins processing_system7_0/S_AXI_HP0]
  connect_bd_intf_net -intf_net mb_bram_ctrl_1_BRAM_PORTA [get_bd_intf_pins iop1/BRAM_PORTB] [get_bd_intf_pins mb_bram_ctrl_1/BRAM_PORTA]
  connect_bd_intf_net -intf_net mb_bram_ctrl_2_BRAM_PORTA [get_bd_intf_pins iop2/BRAM_PORTB] [get_bd_intf_pins mb_bram_ctrl_2/BRAM_PORTA]
  connect_bd_intf_net -intf_net mb_bram_ctrl_3_BRAM_PORTA [get_bd_intf_pins iop3/BRAM_PORTB] [get_bd_intf_pins mb_bram_ctrl_3/BRAM_PORTA]
  connect_bd_intf_net -intf_net mdm_1_MBDEBUG_1 [get_bd_intf_pins iop2/DEBUG] [get_bd_intf_pins mdm_1/MBDEBUG_1]
  connect_bd_intf_net -intf_net mdm_1_MBDEBUG_2 [get_bd_intf_pins iop3/DEBUG] [get_bd_intf_pins mdm_1/MBDEBUG_2]
  connect_bd_intf_net -intf_net microblaze_0_debug [get_bd_intf_pins iop1/DEBUG] [get_bd_intf_pins mdm_1/MBDEBUG_0]
  connect_bd_intf_net -intf_net processing_system7_0_DDR [get_bd_intf_ports DDR] [get_bd_intf_pins processing_system7_0/DDR]
  connect_bd_intf_net -intf_net processing_system7_0_FIXED_IO [get_bd_intf_ports FIXED_IO] [get_bd_intf_pins processing_system7_0/FIXED_IO]
  connect_bd_intf_net -intf_net processing_system7_0_M_AXI_GP0 [get_bd_intf_pins processing_system7_0/M_AXI_GP0] [get_bd_intf_pins processing_system7_0_axi_periph/S00_AXI]
  connect_bd_intf_net -intf_net processing_system7_0_axi_periph_M00_AXI [get_bd_intf_pins mb_bram_ctrl_1/S_AXI] [get_bd_intf_pins processing_system7_0_axi_periph/M00_AXI]
  connect_bd_intf_net -intf_net processing_system7_0_axi_periph_M01_AXI [get_bd_intf_pins mb_bram_ctrl_2/S_AXI] [get_bd_intf_pins processing_system7_0_axi_periph/M01_AXI]
  connect_bd_intf_net -intf_net processing_system7_0_axi_periph_M02_AXI [get_bd_intf_pins mb_bram_ctrl_3/S_AXI] [get_bd_intf_pins processing_system7_0_axi_periph/M02_AXI]
  connect_bd_intf_net -intf_net processing_system7_0_axi_periph_M03_AXI [get_bd_intf_pins processing_system7_0_axi_periph/M03_AXI] [get_bd_intf_pins system_interrupts/s_axi]

  # Create port connections
  connect_bd_net -net ar2sw_data_i_1 [get_bd_ports ar2sw_data_i] [get_bd_pins iop3/ar2sw_data_i]
  connect_bd_net -net mb_1_intr_ack_Dout [get_bd_pins iop1/mb_1_intr_ack] [get_bd_pins mb_1_intr_ack/Dout]
  connect_bd_net -net iop1_q [get_bd_pins iop1/iop1_intr_req] [get_bd_pins iop_interrupts/In0]
  connect_bd_net -net mb_2_intr_ack_Dout [get_bd_pins iop2/mb_2_intr_ack] [get_bd_pins mb_2_intr_ack/Dout]
  connect_bd_net -net iop2_q [get_bd_pins iop2/iop2_intr_req] [get_bd_pins iop_interrupts/In1]
  connect_bd_net -net iop3_cfg2led_gr_0 [get_bd_ports led_0] [get_bd_pins iop3/led_0]
  connect_bd_net -net iop3_cfg2led_gr_1 [get_bd_ports led_1] [get_bd_pins iop3/led_1]
  connect_bd_net -net iop3_cfg2led_gr_2 [get_bd_ports led_2] [get_bd_pins iop3/cfg2led_gr_2]
  connect_bd_net -net iop3_cfg2led_gr_3 [get_bd_ports led_3] [get_bd_pins iop3/led_3]
  connect_bd_net -net iop3_cfg2led_gr_4 [get_bd_ports rgbled_0] [get_bd_pins iop3/rgbled_0]
  connect_bd_net -net mb_3_intr_ack_Dout [get_bd_pins iop3/mb_3_intr_ack] [get_bd_pins mb_3_intr_ack/Dout]
  connect_bd_net -net iop3_q [get_bd_pins iop3/iop3_intr_req] [get_bd_pins iop_interrupts/In2]
  connect_bd_net -net iop3_sw2ar_data_o [get_bd_ports sw2ar_data_o] [get_bd_pins iop3/sw2ar_data_o]
  connect_bd_net -net iop3_sw2ar_tri_o [get_bd_ports sw2ar_tri_o] [get_bd_pins iop3/sw2ar_tri_o]
  connect_bd_net -net iop_interrupts_dout [get_bd_pins iop_interrupts/dout] [get_bd_pins system_interrupts/intr]
  connect_bd_net -net logic_1_dout [get_bd_pins iop1/ext_reset_in] [get_bd_pins iop2/ext_reset_in] [get_bd_pins iop3/ext_reset_in] [get_bd_pins logic_1/dout]
  connect_bd_net -net mb_1_reset_Dout [get_bd_pins iop1/aux_reset_in] [get_bd_pins mb_1_reset/Dout]
  connect_bd_net -net mb_2_reset_Dout [get_bd_pins iop2/aux_reset_in] [get_bd_pins mb_2_reset/Dout]
  connect_bd_net -net mb_3_reset_Dout [get_bd_pins iop3/aux_reset_in] [get_bd_pins mb_3_reset/Dout]
  connect_bd_net -net mb_JB1_sw2pmod_data_out [get_bd_ports pmodJB_data_out] [get_bd_pins iop2/sw2pmod_data_out]
  connect_bd_net -net mb_JB1_sw2pmod_tri_out [get_bd_ports pmodJB_tri_out] [get_bd_pins iop2/sw2pmod_tri_out]
  connect_bd_net -net mdm_1_debug_sys_rst [get_bd_pins iop1/mb_debug_sys_rst] [get_bd_pins iop2/mb_debug_sys_rst] [get_bd_pins iop3/mb_debug_sys_rst] [get_bd_pins mdm_1/Debug_SYS_Rst]
  connect_bd_net -net pb_in_1 [get_bd_ports pb_in] [get_bd_pins iop3/pb_in]
  connect_bd_net -net pmod2sw_data_in_1 [get_bd_ports pmodJA_data_in] [get_bd_pins iop1/pmod2sw_data_in]
  connect_bd_net -net pmod2sw_data_in_2 [get_bd_ports pmodJB_data_in] [get_bd_pins iop2/pmod2sw_data_in]
  connect_bd_net -net pmod_io_switch_0_sw2pmod_data_out [get_bd_ports pmodJA_data_out] [get_bd_pins iop1/sw2pmod_data_out]
  connect_bd_net -net pmod_io_switch_0_sw2pmod_tri_out [get_bd_ports pmodJA_tri_out] [get_bd_pins iop1/sw2pmod_tri_out]
  connect_bd_net -net processing_system7_0_FCLK_CLK0 [get_bd_pins iop1/clk] [get_bd_pins iop2/clk] [get_bd_pins iop3/clk] [get_bd_pins mb_bram_ctrl_1/s_axi_aclk] [get_bd_pins mb_bram_ctrl_2/s_axi_aclk] [get_bd_pins mb_bram_ctrl_3/s_axi_aclk] [get_bd_pins processing_system7_0/FCLK_CLK0] [get_bd_pins processing_system7_0/M_AXI_GP0_ACLK] [get_bd_pins processing_system7_0/S_AXI_HP0_ACLK] [get_bd_pins processing_system7_0_axi_periph/ACLK] [get_bd_pins processing_system7_0_axi_periph/M00_ACLK] [get_bd_pins processing_system7_0_axi_periph/M01_ACLK] [get_bd_pins processing_system7_0_axi_periph/M02_ACLK] [get_bd_pins processing_system7_0_axi_periph/M03_ACLK] [get_bd_pins processing_system7_0_axi_periph/S00_ACLK] [get_bd_pins rst_processing_system7_0_100M/slowest_sync_clk] [get_bd_pins system_interrupts/s_axi_aclk]
  connect_bd_net -net processing_system7_0_FCLK_CLK1 [get_bd_pins iop3/pg_tracebuffer_clk] [get_bd_pins processing_system7_0/FCLK_CLK1] [get_bd_pins processing_system7_0/S_AXI_HP2_ACLK] [get_bd_pins rst_processing_system7_0_200M/slowest_sync_clk]
  connect_bd_net -net processing_system7_0_FCLK_RESET0_N [get_bd_pins processing_system7_0/FCLK_RESET0_N] [get_bd_pins rst_processing_system7_0_100M/ext_reset_in] [get_bd_pins rst_processing_system7_0_200M/ext_reset_in]
  connect_bd_net -net processing_system7_0_GPIO_O [get_bd_pins mb_1_intr_ack/Din] [get_bd_pins mb_2_intr_ack/Din] [get_bd_pins mb_3_intr_ack/Din] [get_bd_pins mb_1_reset/Din] [get_bd_pins mb_2_reset/Din] [get_bd_pins mb_3_reset/Din] [get_bd_pins processing_system7_0/GPIO_O]
  connect_bd_net -net rst_processing_system7_0_100M_interconnect_aresetn [get_bd_pins processing_system7_0_axi_periph/ARESETN] [get_bd_pins rst_processing_system7_0_100M/interconnect_aresetn]
  connect_bd_net -net rst_processing_system7_0_100M_peripheral_aresetn [get_bd_pins iop1/M06_ARESETN] [get_bd_pins iop2/M06_ARESETN] [get_bd_pins iop3/M10_ARESETN] [get_bd_pins mb_bram_ctrl_1/s_axi_aresetn] [get_bd_pins mb_bram_ctrl_2/s_axi_aresetn] [get_bd_pins mb_bram_ctrl_3/s_axi_aresetn] [get_bd_pins processing_system7_0_axi_periph/M00_ARESETN] [get_bd_pins processing_system7_0_axi_periph/M01_ARESETN] [get_bd_pins processing_system7_0_axi_periph/M02_ARESETN] [get_bd_pins processing_system7_0_axi_periph/M03_ARESETN] [get_bd_pins processing_system7_0_axi_periph/S00_ARESETN] [get_bd_pins rst_processing_system7_0_100M/peripheral_aresetn] [get_bd_pins system_interrupts/s_axi_aresetn]
  connect_bd_net -net rst_processing_system7_0_200M_interconnect_aresetn [get_bd_pins iop3/ARESETN] [get_bd_pins rst_processing_system7_0_200M/interconnect_aresetn]
  connect_bd_net -net rst_processing_system7_0_200M_peripheral_aresetn [get_bd_pins iop3/ap_rst_n] [get_bd_pins rst_processing_system7_0_200M/peripheral_aresetn]
  connect_bd_net -net system_interrupts_irq [get_bd_pins processing_system7_0/IRQ_F2P] [get_bd_pins system_interrupts/irq]

  # Create address segments
  create_bd_addr_seg -range 0x00010000 -offset 0x40000000 [get_bd_addr_spaces processing_system7_0/Data] [get_bd_addr_segs mb_bram_ctrl_1/S_AXI/Mem0] SEG_mb_bram_ctrl_1_Mem0
  create_bd_addr_seg -range 0x00010000 -offset 0x42000000 [get_bd_addr_spaces processing_system7_0/Data] [get_bd_addr_segs mb_bram_ctrl_2/S_AXI/Mem0] SEG_mb_bram_ctrl_2_Mem0
  create_bd_addr_seg -range 0x00010000 -offset 0x44000000 [get_bd_addr_spaces processing_system7_0/Data] [get_bd_addr_segs mb_bram_ctrl_3/S_AXI/Mem0] SEG_mb_bram_ctrl_3_Mem0
  create_bd_addr_seg -range 0x00010000 -offset 0x41800000 [get_bd_addr_spaces processing_system7_0/Data] [get_bd_addr_segs system_interrupts/s_axi/Reg] SEG_system_interrupts_Reg
  create_bd_addr_seg -range 0x00010000 -offset 0x40000000 [get_bd_addr_spaces iop1/mb/Data] [get_bd_addr_segs iop1/mb1_gpio/S_AXI/Reg] SEG_axi_gpio_0_Reg
  create_bd_addr_seg -range 0x00010000 -offset 0x40800000 [get_bd_addr_spaces iop1/mb/Data] [get_bd_addr_segs iop1/mb1_iic/S_AXI/Reg] SEG_axi_iic_0_Reg
  create_bd_addr_seg -range 0x00010000 -offset 0x44A10000 [get_bd_addr_spaces iop1/mb/Data] [get_bd_addr_segs iop1/mb1_spi/AXI_LITE/Reg] SEG_axi_quad_spi_0_Reg
  create_bd_addr_seg -range 0x00010000 -offset 0x00000000 [get_bd_addr_spaces iop1/mb/Instruction] [get_bd_addr_segs iop1/mb1_lmb/lmb_bram_if_cntlr/SLMB/Mem] SEG_ilmb_bram_if_cntlr_Mem
  create_bd_addr_seg -range 0x00010000 -offset 0x40010000 [get_bd_addr_spaces iop1/mb/Data] [get_bd_addr_segs iop1/iop1_intr/S_AXI/Reg] SEG_iop1_intr_Reg
  create_bd_addr_seg -range 0x00010000 -offset 0x00000000 [get_bd_addr_spaces iop1/mb/Data] [get_bd_addr_segs iop1/mb1_lmb/lmb_bram_if_cntlr/SLMB1/Mem] SEG_lmb_bram_if_cntlr_Mem
  create_bd_addr_seg -range 0x00010000 -offset 0x41200000 [get_bd_addr_spaces iop1/mb/Data] [get_bd_addr_segs iop1/mb1_intc/s_axi/Reg] SEG_mb1_intc_Reg
  create_bd_addr_seg -range 0x00010000 -offset 0x41C00000 [get_bd_addr_spaces iop1/mb/Data] [get_bd_addr_segs iop1/mb1_timer/S_AXI/Reg] SEG_mb1_timer_Reg
  create_bd_addr_seg -range 0x00010000 -offset 0x44A00000 [get_bd_addr_spaces iop1/mb/Data] [get_bd_addr_segs iop1/mb1_pmod_io_switch/S00_AXI/S00_AXI_reg] SEG_pmod_io_switch_0_S00_AXI_reg
  create_bd_addr_seg -range 0x00010000 -offset 0x40010000 [get_bd_addr_spaces iop2/mb/Data] [get_bd_addr_segs iop2/iop2_intr/S_AXI/Reg] SEG_iop2_intr_Reg
  create_bd_addr_seg -range 0x00010000 -offset 0x00000000 [get_bd_addr_spaces iop2/mb/Data] [get_bd_addr_segs iop2/mb2_lmb/lmb_bram_if_cntlr/SLMB1/Mem] SEG_lmb_bram_if_cntlr_Mem
  create_bd_addr_seg -range 0x00010000 -offset 0x00000000 [get_bd_addr_spaces iop2/mb/Instruction] [get_bd_addr_segs iop2/mb2_lmb/lmb_bram_if_cntlr/SLMB/Mem] SEG_lmb_bram_if_cntlr_Mem
  create_bd_addr_seg -range 0x00010000 -offset 0x40000000 [get_bd_addr_spaces iop2/mb/Data] [get_bd_addr_segs iop2/mb2_gpio/S_AXI/Reg] SEG_mb2_gpio_Reg
  create_bd_addr_seg -range 0x00010000 -offset 0x40800000 [get_bd_addr_spaces iop2/mb/Data] [get_bd_addr_segs iop2/mb2_iic/S_AXI/Reg] SEG_mb2_iic_Reg
  create_bd_addr_seg -range 0x00010000 -offset 0x41200000 [get_bd_addr_spaces iop2/mb/Data] [get_bd_addr_segs iop2/mb2_intc/s_axi/Reg] SEG_mb2_intc_Reg
  create_bd_addr_seg -range 0x00010000 -offset 0x44A00000 [get_bd_addr_spaces iop2/mb/Data] [get_bd_addr_segs iop2/mb2_pmod_io_switch/S00_AXI/S00_AXI_reg] SEG_mb2_pmod_io_switch_S00_AXI_reg
  create_bd_addr_seg -range 0x00010000 -offset 0x44A10000 [get_bd_addr_spaces iop2/mb/Data] [get_bd_addr_segs iop2/mb2_spi/AXI_LITE/Reg] SEG_mb2_spi_Reg
  create_bd_addr_seg -range 0x00010000 -offset 0x41C00000 [get_bd_addr_spaces iop2/mb/Data] [get_bd_addr_segs iop2/mb2_timer/S_AXI/Reg] SEG_mb2_timer_Reg
  create_bd_addr_seg -range 0x00040000 -offset 0x10000000 [get_bd_addr_spaces iop3/axi_cdma_0/Data] [get_bd_addr_segs iop3/pg_o/axi_bram_ctrl_1/S_AXI/Mem0] SEG_axi_bram_ctrl_1_Mem0
  create_bd_addr_seg -range 0x00008000 -offset 0xC0000000 [get_bd_addr_spaces iop3/axi_cdma_0/Data] [get_bd_addr_segs iop3/smg_0/axi_bram_ctrl_1/S_AXI/Mem0] SEG_axi_bram_ctrl_1_Mem01
  create_bd_addr_seg -range 0x20000000 -offset 0x20000000 [get_bd_addr_spaces iop3/axi_cdma_0/Data] [get_bd_addr_segs processing_system7_0/S_AXI_HP0/HP0_DDR_LOWOCM] SEG_processing_system7_0_HP0_DDR_LOWOCM
  create_bd_addr_seg -range 0x00040000 -offset 0x10000000 [get_bd_addr_spaces iop3/mb/Data] [get_bd_addr_segs iop3/pg_o/axi_bram_ctrl_0/S_AXI/Mem0] SEG_axi_bram_ctrl_0_Mem0
  create_bd_addr_seg -range 0x00008000 -offset 0xC0000000 [get_bd_addr_spaces iop3/mb/Data] [get_bd_addr_segs iop3/smg_0/axi_bram_ctrl_0/S_AXI/Mem0] SEG_axi_bram_ctrl_1_Mem0
  create_bd_addr_seg -range 0x00010000 -offset 0x44A10000 [get_bd_addr_spaces iop3/mb/Data] [get_bd_addr_segs iop3/axi_cdma_0/S_AXI_LITE/Reg] SEG_axi_cdma_0_Reg
  create_bd_addr_seg -range 0x00010000 -offset 0x41E00000 [get_bd_addr_spaces iop3/mb/Data] [get_bd_addr_segs iop3/pg_o/axi_dma_0/S_AXI_LITE/Reg] SEG_axi_dma_0_Reg
  create_bd_addr_seg -range 0x00010000 -offset 0x40010000 [get_bd_addr_spaces iop3/mb/Data] [get_bd_addr_segs iop3/pg_o/pg/axi_gpio_pg_nsamples_single/S_AXI/Reg] SEG_axi_gpio_pg_nsamples_single_Reg
  create_bd_addr_seg -range 0x00010000 -offset 0x40000000 [get_bd_addr_spaces iop3/mb/Data] [get_bd_addr_segs iop3/pg_o/pg/axi_gpio_pg_tri_control/S_AXI/Reg] SEG_axi_gpio_pg_tri_control_Reg
  create_bd_addr_seg -range 0x00010000 -offset 0x41200000 [get_bd_addr_spaces iop3/mb/Data] [get_bd_addr_segs iop3/axi_intc_0/s_axi/Reg] SEG_axi_intc_0_Reg
  create_bd_addr_seg -range 0x00010000 -offset 0x44A00000 [get_bd_addr_spaces iop3/mb/Data] [get_bd_addr_segs iop3/cfg_0/cfg_0/S00_AXI/S00_AXI_reg] SEG_cfg_0_S00_AXI_reg
  create_bd_addr_seg -range 0x00010000 -offset 0x40020000 [get_bd_addr_spaces iop3/mb/Data] [get_bd_addr_segs iop3/function_sel/S_AXI/Reg] SEG_function_sel_Reg
  create_bd_addr_seg -range 0x00010000 -offset 0x40040000 [get_bd_addr_spaces iop3/mb/Data] [get_bd_addr_segs iop3/iop3_intr/S_AXI/Reg] SEG_iop3_intr_Reg
  create_bd_addr_seg -range 0x00010000 -offset 0x00000000 [get_bd_addr_spaces iop3/mb/Data] [get_bd_addr_segs iop3/mb3_lmb/lmb_bram_if_cntlr/SLMB1/Mem] SEG_lmb_bram_if_cntlr_Mem
  create_bd_addr_seg -range 0x00010000 -offset 0x00000000 [get_bd_addr_spaces iop3/mb/Instruction] [get_bd_addr_segs iop3/mb3_lmb/lmb_bram_if_cntlr/SLMB/Mem] SEG_lmb_bram_if_cntlr_Mem
  create_bd_addr_seg -range 0x00010000 -offset 0x40030000 [get_bd_addr_spaces iop3/mb/Data] [get_bd_addr_segs iop3/smg_0/smg_bram_enb_rstb/S_AXI/Reg] SEG_smg_bram_enab_rstb_Reg
  create_bd_addr_seg -range 0x00010000 -offset 0x44A30000 [get_bd_addr_spaces iop3/mb/Data] [get_bd_addr_segs iop3/smg_0/smg_io_switch_0/S00_AXI/S00_AXI_reg] SEG_smg_io_switch_0_S00_AXI_reg
  create_bd_addr_seg -range 0x00010000 -offset 0x44A20000 [get_bd_addr_spaces iop3/mb/Data] [get_bd_addr_segs iop3/pg_o/trace_cntrl_0/s_axi_trace_cntrl/Reg] SEG_trace_cntrl_0_Reg
  create_bd_addr_seg -range 0x20000000 -offset 0x20000000 [get_bd_addr_spaces iop3/pg_o/axi_dma_0/Data_S2MM] [get_bd_addr_segs processing_system7_0/S_AXI_HP2/HP2_DDR_LOWOCM] SEG_processing_system7_0_HP2_DDR_LOWOCM

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
make_wrapper -files [get_files ./interface/interface.srcs/sources_1/bd/system/system.bd] -top

# generate toplevel wrapper files
add_files -norecurse ./interface/interface.srcs/sources_1/bd/system/hdl/system_wrapper.v
update_compile_order -fileset sources_1
update_compile_order -fileset sim_1
add_files -fileset constrs_1 -norecurse ./src/constraints/top.xdc

# replace top wrapper with custom top.v
add_files -norecurse ./src/top.v
update_compile_order -fileset sources_1
set_property top top [current_fileset]
update_compile_order -fileset sources_1

# call implement
launch_runs impl_1 -to_step write_bitstream -jobs 4
wait_on_run impl_1

# This hardware definition file will be used for microblaze projects
file mkdir ./interface/interface.sdk
write_hwdef -force  -file ./interface/interface.sdk/interface.hdf
file copy -force ./interface/interface.sdk/interface.hdf ../../sdk/

# move and rename bitstream to final location
file copy -force ./interface/interface.runs/impl_1/top.bit ../../bitstream/interface.bit


