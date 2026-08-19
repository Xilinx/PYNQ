#
# Copyright (c) 2026, Advanced Micro Devices, Inc.
# SPDX-License-Identifier: BSD-3-Clause
#

################################################################
# This is a generated script based on design: vck190_pynq
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
set scripts_vivado_version 2025.2
set current_vivado_version [version -short]

if { [string first $scripts_vivado_version $current_vivado_version] == -1 } {
   puts ""
   if { [string compare $scripts_vivado_version $current_vivado_version] > 0 } {
      catch {common::send_gid_msg -ssname BD::TCL -id 2042 -severity "ERROR" " This script was generated using Vivado <$scripts_vivado_version> and is being run in <$current_vivado_version> of Vivado. Sourcing the script failed since it was created with a future version of Vivado."}

   } else {
     catch {common::send_gid_msg -ssname BD::TCL -id 2041 -severity "ERROR" "This script was generated using Vivado <$scripts_vivado_version> and is being run in <$current_vivado_version> of Vivado. Please run the script in Vivado <$scripts_vivado_version> then open the design in Vivado <$current_vivado_version>. Upgrade the design by running \"Tools => Report => Report IP Status...\", then run write_bd_tcl to create an updated script."}

   }

   return 1
}

################################################################
# START
################################################################

# To test this script, run the following commands from Vivado Tcl console:
# source vck190_pynq_script.tcl

# If there is no project opened, this script will create a
# project, but make sure you do not have an existing project
# <./myproj/project_1.xpr> in the current working folder.

# Vivado ships the VCK190 board files. BOARD_STORE_PATH overrides them with a
# XilinxBoardStore checkout when it is set.
if {[info exists ::env(BOARD_STORE_PATH)]} {
   set board_store $::env(BOARD_STORE_PATH)/boards
   if {![file isdirectory $board_store]} {
      error "No boards directory under BOARD_STORE_PATH ($board_store)"
   }
   set_param board.repoPaths [list $board_store]
}

set overlay_name golden
set list_projs [get_projects -quiet]
if { $list_projs eq "" } {
   create_project ${overlay_name} ${overlay_name} -part xcvc1902-vsva2197-2MP-e-S
   set_property BOARD_PART xilinx.com:vck190:part0:3.4 [current_project]
}


# CHANGE DESIGN NAME HERE
variable design_name
set design_name vck190_pynq

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
      common::send_gid_msg -ssname BD::TCL -id 2001 -severity "INFO" "Changing value of <design_name> from <$design_name> to <$cur_design> since current design is empty."
      set design_name [get_property NAME $cur_design]
   }
   common::send_gid_msg -ssname BD::TCL -id 2002 -severity "INFO" "Constructing design in IPI design <$cur_design>..."

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

   common::send_gid_msg -ssname BD::TCL -id 2003 -severity "INFO" "Currently there is no design <$design_name> in project, so creating one..."

   create_bd_design $design_name

   common::send_gid_msg -ssname BD::TCL -id 2004 -severity "INFO" "Making design <$design_name> as current_bd_design."
   current_bd_design $design_name

}

common::send_gid_msg -ssname BD::TCL -id 2005 -severity "INFO" "Currently the variable <design_name> is equal to \"$design_name\"."

if { $nRet != 0 } {
   catch {common::send_gid_msg -ssname BD::TCL -id 2006 -severity "ERROR" $errMsg}
   return $nRet
}

set bCheckIPsPassed 1
##################################################################
# CHECK IPs
##################################################################
set bCheckIPs 1
if { $bCheckIPs == 1 } {
   set list_check_ips "\ 
xilinx.com:ip:versal_cips:3.4\
xilinx.com:ip:proc_sys_reset:5.0\
xilinx.com:ip:axi_noc:1.1\
xilinx.com:ip:axi_vip:1.1\
xilinx.com:ip:xlconstant:1.1\
"

   set list_ips_missing ""
   common::send_gid_msg -ssname BD::TCL -id 2011 -severity "INFO" "Checking if the following IPs exist in the project's IP catalog: $list_check_ips ."

   foreach ip_vlnv $list_check_ips {
      set ip_obj [get_ipdefs -all $ip_vlnv]
      if { $ip_obj eq "" } {
         lappend list_ips_missing $ip_vlnv
      }
   }

   if { $list_ips_missing ne "" } {
      catch {common::send_gid_msg -ssname BD::TCL -id 2012 -severity "ERROR" "The following IPs are not found in the IP Catalog:\n  $list_ips_missing\n\nResolution: Please add the repository containing the IP(s) to the project." }
      set bCheckIPsPassed 0
   }

}

if { $bCheckIPsPassed != 1 } {
  common::send_gid_msg -ssname BD::TCL -id 2023 -severity "WARNING" "Will not continue with creation of design due to the error(s) above."
  return 3
}

##################################################################
# DESIGN PROCs
##################################################################



# Procedure to create entire design; Provide argument to make
# procedure reusable. If parentCell is "", will use root.
proc create_root_design { parentCell } {

  variable script_folder
  variable design_name

  if { $parentCell eq "" } {
     set parentCell [get_bd_cells /]
  }

  # Get object for parentCell
  set parentObj [get_bd_cells $parentCell]
  if { $parentObj == "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2090 -severity "ERROR" "Unable to find parent cell <$parentCell>!"}
     return
  }

  # Make sure parentObj is hier blk
  set parentType [get_property TYPE $parentObj]
  if { $parentType ne "hier" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2091 -severity "ERROR" "Parent <$parentObj> has TYPE = <$parentType>. Expected to be <hier>."}
     return
  }

  # Save current instance; Restore later
  set oldCurInst [current_bd_instance .]

  # Set parent object as current
  current_bd_instance $parentObj


  # Create interface ports
  set ddr4_dimm1 [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:ddr4_rtl:1.0 ddr4_dimm1 ]

  set ddr4_dimm1_sma_clk [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:diff_clock_rtl:1.0 ddr4_dimm1_sma_clk ]
  set_property -dict [ list \
   CONFIG.FREQ_HZ {200000000} \
   ] $ddr4_dimm1_sma_clk


  # Create ports

  # Create instance: versal_cips_0, and set properties
  set versal_cips_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:versal_cips:3.4 versal_cips_0 ]
  set_property -dict [list \
    CONFIG.PS_BOARD_INTERFACE {ps_pmc_fixed_io} \
    CONFIG.PS_PMC_CONFIG { \
      DESIGN_MODE {1} \
      PMC_CRP_PL0_REF_CTRL_FREQMHZ {100} \
      PMC_CRP_PL1_REF_CTRL_FREQMHZ {200} \
      PMC_CRP_PL2_REF_CTRL_FREQMHZ {300} \
      PMC_CRP_PL3_REF_CTRL_FREQMHZ {334} \
      PMC_GPIO0_MIO_PERIPHERAL {{ENABLE 1} {IO {PMC_MIO 0 .. 25}}} \
      PMC_GPIO1_MIO_PERIPHERAL {{ENABLE 1} {IO {PMC_MIO 26 .. 51}}} \
      PMC_MIO37 {{AUX_IO 0} {DIRECTION out} {DRIVE_STRENGTH 8mA} {OUTPUT_DATA high} {PULL pullup} {SCHMITT 0} {SLEW slow} {USAGE GPIO}} \
      PMC_OSPI_PERIPHERAL {{ENABLE 0} {IO {PMC_MIO 0 .. 11}} {MODE Single}} \
      PMC_QSPI_COHERENCY {0} \
      PMC_QSPI_FBCLK {{ENABLE 1} {IO {PMC_MIO 6}}} \
      PMC_QSPI_PERIPHERAL_DATA_MODE {x4} \
      PMC_QSPI_PERIPHERAL_ENABLE {1} \
      PMC_QSPI_PERIPHERAL_MODE {Dual Parallel} \
      PMC_REF_CLK_FREQMHZ {33.3333} \
      PMC_SD1 {{CD_ENABLE 1} {CD_IO {PMC_MIO 28}} {POW_ENABLE 1} {POW_IO {PMC_MIO 51}} {RESET_ENABLE 0} {RESET_IO {PMC_MIO 12}} {WP_ENABLE 0} {WP_IO {PMC_MIO 1}}} \
      PMC_SD1_COHERENCY {0} \
      PMC_SD1_DATA_TRANSFER_MODE {8Bit} \
      PMC_SD1_PERIPHERAL {{CLK_100_SDR_OTAP_DLY 0x3} {CLK_200_SDR_OTAP_DLY 0x2} {CLK_50_DDR_ITAP_DLY 0x36} {CLK_50_DDR_OTAP_DLY 0x3} {CLK_50_SDR_ITAP_DLY 0x2C} {CLK_50_SDR_OTAP_DLY 0x4} {ENABLE 1} {IO\
{PMC_MIO 26 .. 36}}} \
      PMC_SD1_SLOT_TYPE {SD 3.0} \
      PMC_USE_PMC_NOC_AXI0 {1} \
      PS_BOARD_INTERFACE {ps_pmc_fixed_io} \
      PS_CAN1_PERIPHERAL {{ENABLE 1} {IO {PMC_MIO 40 .. 41}}} \
      PS_CRL_CAN1_REF_CTRL_FREQMHZ {160} \
      PS_ENET0_MDIO {{ENABLE 1} {IO {PS_MIO 24 .. 25}}} \
      PS_ENET0_PERIPHERAL {{ENABLE 1} {IO {PS_MIO 0 .. 11}}} \
      PS_ENET1_PERIPHERAL {{ENABLE 1} {IO {PS_MIO 12 .. 23}}} \
      PS_GEN_IPI0_ENABLE {1} \
      PS_GEN_IPI0_MASTER {A72} \
      PS_GEN_IPI1_ENABLE {1} \
      PS_GEN_IPI2_ENABLE {1} \
      PS_GEN_IPI3_ENABLE {1} \
      PS_GEN_IPI4_ENABLE {1} \
      PS_GEN_IPI5_ENABLE {1} \
      PS_GEN_IPI6_ENABLE {1} \
      PS_I2C0_PERIPHERAL {{ENABLE 1} {IO {PMC_MIO 46 .. 47}}} \
      PS_I2C1_PERIPHERAL {{ENABLE 1} {IO {PMC_MIO 44 .. 45}}} \
      PS_IRQ_USAGE {{CH0 1} {CH1 0} {CH10 0} {CH11 0} {CH12 0} {CH13 0} {CH14 0} {CH15 0} {CH2 0} {CH3 0} {CH4 0} {CH5 0} {CH6 0} {CH7 0} {CH8 0} {CH9 0}} \
      PS_MIO19 {{AUX_IO 0} {DIRECTION in} {DRIVE_STRENGTH 8mA} {OUTPUT_DATA default} {PULL disable} {SCHMITT 0} {SLEW slow} {USAGE Reserved}} \
      PS_MIO21 {{AUX_IO 0} {DIRECTION in} {DRIVE_STRENGTH 8mA} {OUTPUT_DATA default} {PULL disable} {SCHMITT 0} {SLEW slow} {USAGE Reserved}} \
      PS_MIO7 {{AUX_IO 0} {DIRECTION in} {DRIVE_STRENGTH 8mA} {OUTPUT_DATA default} {PULL disable} {SCHMITT 0} {SLEW slow} {USAGE Reserved}} \
      PS_MIO9 {{AUX_IO 0} {DIRECTION in} {DRIVE_STRENGTH 8mA} {OUTPUT_DATA default} {PULL disable} {SCHMITT 0} {SLEW slow} {USAGE Reserved}} \
      PS_NUM_F2P0_INTR_INPUTS {1} \
      PS_NUM_F2P1_INTR_INPUTS {1} \
      PS_NUM_FABRIC_RESETS {4} \
      PS_PCIE_EP_RESET1_IO {PMC_MIO 38} \
      PS_PCIE_EP_RESET2_IO {PMC_MIO 39} \
      PS_PCIE_RESET {ENABLE 1} \
      PS_UART0_PERIPHERAL {{ENABLE 1} {IO {PMC_MIO 42 .. 43}}} \
      PS_USB3_PERIPHERAL {{ENABLE 1} {IO {PMC_MIO 13 .. 25}}} \
      PS_USE_FPD_AXI_NOC0 {0} \
      PS_USE_FPD_CCI_NOC {1} \
      PS_USE_M_AXI_FPD {1} \
      PS_USE_M_AXI_LPD {1} \
      PS_USE_NOC_LPD_AXI0 {1} \
      PS_USE_PMCPL_CLK0 {1} \
      PS_USE_PMCPL_CLK1 {1} \
      PS_USE_PMCPL_CLK2 {1} \
      PS_USE_PMCPL_CLK3 {1} \
      SMON_ALARMS {Set_Alarms_On} \
      SMON_ENABLE_TEMP_AVERAGING {0} \
      SMON_TEMP_AVERAGING_SAMPLES {0} \
    } \
  ] $versal_cips_0


  set_property SELECTED_SIM_MODEL tlm  $versal_cips_0

  # Create instance: rst_pl0, and set properties
  set rst_pl0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset:5.0 rst_pl0 ]

  # Create instance: rst_pl1, and set properties
  set rst_pl1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset:5.0 rst_pl1 ]

  # Create instance: rst_pl2, and set properties
  set rst_pl2 [ create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset:5.0 rst_pl2 ]

  # Create instance: rst_pl3, and set properties
  set rst_pl3 [ create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset:5.0 rst_pl3 ]

  # Create instance: axi_noc_ps, and set properties
  set axi_noc_ps [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_noc:1.1 axi_noc_ps ]
  set_property -dict [list \
    CONFIG.CH0_DDR4_0_BOARD_INTERFACE {ddr4_dimm1} \
    CONFIG.MC_CHAN_REGION1 {DDR_LOW1} \
    CONFIG.MC_NETLIST_SIMULATION {true} \
    CONFIG.NUM_CLKS {7} \
    CONFIG.NUM_MC {1} \
    CONFIG.NUM_MCP {1} \
    CONFIG.NUM_MI {0} \
    CONFIG.NUM_NMI {0} \
    CONFIG.NUM_NSI {1} \
    CONFIG.NUM_SI {6} \
    CONFIG.sys_clk0_BOARD_INTERFACE {ddr4_dimm1_sma_clk} \
  ] $axi_noc_ps


  set_property SELECTED_SIM_MODEL tlm  $axi_noc_ps

  set_property -dict [ list \
   CONFIG.DATA_WIDTH {128} \
   CONFIG.REGION {0} \
   CONFIG.CONNECTIONS {MC_0 {read_bw {5} write_bw {5} read_avg_burst {4} write_avg_burst {4} initial_boot {true}}} \
   CONFIG.DEST_IDS {} \
   CONFIG.NOC_PARAMS {} \
   CONFIG.CATEGORY {ps_pmc} \
 ] [get_bd_intf_pins $axi_noc_ps/S00_AXI]

  set_property -dict [ list \
   CONFIG.CONNECTIONS {MC_0 {read_bw {500} write_bw {500}}} \
 ] [get_bd_intf_pins $axi_noc_ps/S00_INI]

  set_property -dict [ list \
   CONFIG.DATA_WIDTH {128} \
   CONFIG.REGION {0} \
   CONFIG.CONNECTIONS {MC_0 {read_bw {5} write_bw {5} read_avg_burst {4} write_avg_burst {4} initial_boot {true}}} \
   CONFIG.DEST_IDS {} \
   CONFIG.NOC_PARAMS {} \
   CONFIG.CATEGORY {ps_rpu} \
 ] [get_bd_intf_pins $axi_noc_ps/S01_AXI]

  set_property -dict [ list \
   CONFIG.DATA_WIDTH {128} \
   CONFIG.REGION {0} \
   CONFIG.CONNECTIONS {MC_0 {read_bw {5} write_bw {5} read_avg_burst {4} write_avg_burst {4} initial_boot {true}}} \
   CONFIG.DEST_IDS {} \
   CONFIG.NOC_PARAMS {} \
   CONFIG.CATEGORY {ps_cci} \
 ] [get_bd_intf_pins $axi_noc_ps/S02_AXI]

  set_property -dict [ list \
   CONFIG.DATA_WIDTH {128} \
   CONFIG.REGION {0} \
   CONFIG.CONNECTIONS {MC_0 {read_bw {5} write_bw {5} read_avg_burst {4} write_avg_burst {4} initial_boot {true}}} \
   CONFIG.DEST_IDS {} \
   CONFIG.NOC_PARAMS {} \
   CONFIG.CATEGORY {ps_cci} \
 ] [get_bd_intf_pins $axi_noc_ps/S03_AXI]

  set_property -dict [ list \
   CONFIG.DATA_WIDTH {128} \
   CONFIG.REGION {0} \
   CONFIG.CONNECTIONS {MC_0 {read_bw {5} write_bw {5} read_avg_burst {4} write_avg_burst {4} initial_boot {true}}} \
   CONFIG.DEST_IDS {} \
   CONFIG.NOC_PARAMS {} \
   CONFIG.CATEGORY {ps_cci} \
 ] [get_bd_intf_pins $axi_noc_ps/S04_AXI]

  set_property -dict [ list \
   CONFIG.DATA_WIDTH {128} \
   CONFIG.REGION {0} \
   CONFIG.CONNECTIONS {MC_0 {read_bw {5} write_bw {5} read_avg_burst {4} write_avg_burst {4} initial_boot {true}}} \
   CONFIG.DEST_IDS {} \
   CONFIG.NOC_PARAMS {} \
   CONFIG.CATEGORY {ps_cci} \
 ] [get_bd_intf_pins $axi_noc_ps/S05_AXI]

  set_property -dict [ list \
   CONFIG.ASSOCIATED_BUSIF {S00_AXI} \
 ] [get_bd_pins $axi_noc_ps/aclk0]

  set_property -dict [ list \
   CONFIG.ASSOCIATED_BUSIF {S01_AXI} \
 ] [get_bd_pins $axi_noc_ps/aclk1]

  set_property -dict [ list \
   CONFIG.ASSOCIATED_BUSIF {S02_AXI} \
 ] [get_bd_pins $axi_noc_ps/aclk2]

  set_property -dict [ list \
   CONFIG.ASSOCIATED_BUSIF {S03_AXI} \
 ] [get_bd_pins $axi_noc_ps/aclk3]

  set_property -dict [ list \
   CONFIG.ASSOCIATED_BUSIF {S04_AXI} \
 ] [get_bd_pins $axi_noc_ps/aclk4]

  set_property -dict [ list \
   CONFIG.ASSOCIATED_BUSIF {S05_AXI} \
 ] [get_bd_pins $axi_noc_ps/aclk5]

  set_property -dict [ list \
   CONFIG.ASSOCIATED_BUSIF {} \
 ] [get_bd_pins $axi_noc_ps/aclk6]

  # Create instance: axi_noc_pl, and set properties
  set axi_noc_pl [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_noc:1.1 axi_noc_pl ]
  set_property -dict [list \
    CONFIG.NUM_CLKS {1} \
    CONFIG.NUM_MC {0} \
    CONFIG.NUM_MI {0} \
    CONFIG.NUM_NMI {1} \
    CONFIG.NUM_NSI {0} \
    CONFIG.NUM_SI {2} \
  ] $axi_noc_pl


  set_property SELECTED_SIM_MODEL tlm  $axi_noc_pl

  set_property -dict [ list \
   CONFIG.DATA_WIDTH {128} \
   CONFIG.REGION {0} \
   CONFIG.CONNECTIONS {M00_INI {read_bw {500} write_bw {500}}} \
   CONFIG.DEST_IDS {} \
   CONFIG.NOC_PARAMS {} \
   CONFIG.CATEGORY {pl} \
 ] [get_bd_intf_pins $axi_noc_pl/S00_AXI]

  set_property -dict [ list \
   CONFIG.DATA_WIDTH {128} \
   CONFIG.REGION {0} \
   CONFIG.CONNECTIONS {M00_INI {read_bw {500} write_bw {500}}} \
   CONFIG.DEST_IDS {} \
   CONFIG.NOC_PARAMS {} \
   CONFIG.CATEGORY {pl} \
 ] [get_bd_intf_pins $axi_noc_pl/S01_AXI]

  set_property -dict [ list \
   CONFIG.ASSOCIATED_BUSIF {S00_AXI:S01_AXI} \
 ] [get_bd_pins $axi_noc_pl/aclk0]

  # Create instance: pl_tieoff_fpd, and set properties
  set pl_tieoff_fpd [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_vip:1.1 pl_tieoff_fpd ]
  set_property -dict [list \
    CONFIG.INTERFACE_MODE {SLAVE} \
    CONFIG.PROTOCOL {AXI4} \
  ] $pl_tieoff_fpd


  # Create instance: pl_tieoff_lpd, and set properties
  set pl_tieoff_lpd [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_vip:1.1 pl_tieoff_lpd ]
  set_property -dict [list \
    CONFIG.INTERFACE_MODE {SLAVE} \
    CONFIG.PROTOCOL {AXI4} \
  ] $pl_tieoff_lpd


  # Create instance: pl_tieoff_dma0, and set properties
  set pl_tieoff_dma0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_vip:1.1 pl_tieoff_dma0 ]
  set_property -dict [list \
    CONFIG.ADDR_WIDTH {64} \
    CONFIG.ARUSER_WIDTH {0} \
    CONFIG.AWUSER_WIDTH {0} \
    CONFIG.BUSER_WIDTH {0} \
    CONFIG.DATA_WIDTH {128} \
    CONFIG.HAS_BRESP {1} \
    CONFIG.HAS_BURST {1} \
    CONFIG.HAS_CACHE {1} \
    CONFIG.HAS_LOCK {1} \
    CONFIG.HAS_PROT {1} \
    CONFIG.HAS_QOS {1} \
    CONFIG.HAS_REGION {1} \
    CONFIG.HAS_RRESP {1} \
    CONFIG.HAS_WSTRB {1} \
    CONFIG.ID_WIDTH {0} \
    CONFIG.INTERFACE_MODE {MASTER} \
    CONFIG.PROTOCOL {AXI4} \
    CONFIG.READ_WRITE_MODE {READ_WRITE} \
    CONFIG.RUSER_WIDTH {0} \
    CONFIG.SUPPORTS_NARROW {1} \
    CONFIG.WUSER_WIDTH {0} \
  ] $pl_tieoff_dma0


  # Create instance: pl_tieoff_dma1, and set properties
  set pl_tieoff_dma1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_vip:1.1 pl_tieoff_dma1 ]
  set_property -dict [list \
    CONFIG.ADDR_WIDTH {64} \
    CONFIG.ARUSER_WIDTH {0} \
    CONFIG.AWUSER_WIDTH {0} \
    CONFIG.BUSER_WIDTH {0} \
    CONFIG.DATA_WIDTH {128} \
    CONFIG.HAS_BRESP {1} \
    CONFIG.HAS_BURST {1} \
    CONFIG.HAS_CACHE {1} \
    CONFIG.HAS_LOCK {1} \
    CONFIG.HAS_PROT {1} \
    CONFIG.HAS_QOS {1} \
    CONFIG.HAS_REGION {1} \
    CONFIG.HAS_RRESP {1} \
    CONFIG.HAS_WSTRB {1} \
    CONFIG.ID_WIDTH {0} \
    CONFIG.INTERFACE_MODE {MASTER} \
    CONFIG.PROTOCOL {AXI4} \
    CONFIG.READ_WRITE_MODE {READ_WRITE} \
    CONFIG.RUSER_WIDTH {0} \
    CONFIG.SUPPORTS_NARROW {1} \
    CONFIG.WUSER_WIDTH {0} \
  ] $pl_tieoff_dma1


  # Create instance: pl_tieoff_irq, and set properties
  set pl_tieoff_irq [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant:1.1 pl_tieoff_irq ]
  set_property -dict [list \
    CONFIG.CONST_VAL {0} \
    CONFIG.CONST_WIDTH {1} \
  ] $pl_tieoff_irq


  # Create interface connections
  connect_bd_intf_net -intf_net axi_noc_pl_M00_INI [get_bd_intf_pins axi_noc_pl/M00_INI] [get_bd_intf_pins axi_noc_ps/S00_INI]
  connect_bd_intf_net -intf_net axi_noc_ps_CH0_DDR4_0 [get_bd_intf_ports ddr4_dimm1] [get_bd_intf_pins axi_noc_ps/CH0_DDR4_0]
  connect_bd_intf_net -intf_net ddr4_dimm1_sma_clk_1 [get_bd_intf_ports ddr4_dimm1_sma_clk] [get_bd_intf_pins axi_noc_ps/sys_clk0]
  connect_bd_intf_net -intf_net pl_tieoff_dma0_M_AXI [get_bd_intf_pins pl_tieoff_dma0/M_AXI] [get_bd_intf_pins axi_noc_pl/S00_AXI]
  connect_bd_intf_net -intf_net pl_tieoff_dma1_M_AXI [get_bd_intf_pins pl_tieoff_dma1/M_AXI] [get_bd_intf_pins axi_noc_pl/S01_AXI]
  connect_bd_intf_net -intf_net versal_cips_0_FPD_CCI_NOC_0 [get_bd_intf_pins versal_cips_0/FPD_CCI_NOC_0] [get_bd_intf_pins axi_noc_ps/S02_AXI]
  connect_bd_intf_net -intf_net versal_cips_0_FPD_CCI_NOC_1 [get_bd_intf_pins versal_cips_0/FPD_CCI_NOC_1] [get_bd_intf_pins axi_noc_ps/S03_AXI]
  connect_bd_intf_net -intf_net versal_cips_0_FPD_CCI_NOC_2 [get_bd_intf_pins versal_cips_0/FPD_CCI_NOC_2] [get_bd_intf_pins axi_noc_ps/S04_AXI]
  connect_bd_intf_net -intf_net versal_cips_0_FPD_CCI_NOC_3 [get_bd_intf_pins versal_cips_0/FPD_CCI_NOC_3] [get_bd_intf_pins axi_noc_ps/S05_AXI]
  connect_bd_intf_net -intf_net versal_cips_0_LPD_AXI_NOC_0 [get_bd_intf_pins versal_cips_0/LPD_AXI_NOC_0] [get_bd_intf_pins axi_noc_ps/S01_AXI]
  connect_bd_intf_net -intf_net versal_cips_0_M_AXI_FPD [get_bd_intf_pins versal_cips_0/M_AXI_FPD] [get_bd_intf_pins pl_tieoff_fpd/S_AXI]
  connect_bd_intf_net -intf_net versal_cips_0_M_AXI_LPD [get_bd_intf_pins versal_cips_0/M_AXI_LPD] [get_bd_intf_pins pl_tieoff_lpd/S_AXI]
  connect_bd_intf_net -intf_net versal_cips_0_PMC_NOC_AXI_0 [get_bd_intf_pins versal_cips_0/PMC_NOC_AXI_0] [get_bd_intf_pins axi_noc_ps/S00_AXI]

  # Create port connections
  connect_bd_net -net pl_tieoff_irq_dout  [get_bd_pins pl_tieoff_irq/dout] \
  [get_bd_pins versal_cips_0/pl_ps_irq0]
  connect_bd_net -net rst_pl0_peripheral_aresetn  [get_bd_pins rst_pl0/peripheral_aresetn] \
  [get_bd_pins pl_tieoff_fpd/aresetn] \
  [get_bd_pins pl_tieoff_lpd/aresetn] \
  [get_bd_pins pl_tieoff_dma0/aresetn] \
  [get_bd_pins pl_tieoff_dma1/aresetn]
  connect_bd_net -net versal_cips_0_fpd_cci_noc_axi0_clk  [get_bd_pins versal_cips_0/fpd_cci_noc_axi0_clk] \
  [get_bd_pins axi_noc_ps/aclk2]
  connect_bd_net -net versal_cips_0_fpd_cci_noc_axi1_clk  [get_bd_pins versal_cips_0/fpd_cci_noc_axi1_clk] \
  [get_bd_pins axi_noc_ps/aclk3]
  connect_bd_net -net versal_cips_0_fpd_cci_noc_axi2_clk  [get_bd_pins versal_cips_0/fpd_cci_noc_axi2_clk] \
  [get_bd_pins axi_noc_ps/aclk4]
  connect_bd_net -net versal_cips_0_fpd_cci_noc_axi3_clk  [get_bd_pins versal_cips_0/fpd_cci_noc_axi3_clk] \
  [get_bd_pins axi_noc_ps/aclk5]
  connect_bd_net -net versal_cips_0_lpd_axi_noc_clk  [get_bd_pins versal_cips_0/lpd_axi_noc_clk] \
  [get_bd_pins axi_noc_ps/aclk1]
  connect_bd_net -net versal_cips_0_pl0_ref_clk  [get_bd_pins versal_cips_0/pl0_ref_clk] \
  [get_bd_pins axi_noc_ps/aclk6] \
  [get_bd_pins axi_noc_pl/aclk0] \
  [get_bd_pins rst_pl0/slowest_sync_clk] \
  [get_bd_pins versal_cips_0/m_axi_fpd_aclk] \
  [get_bd_pins versal_cips_0/m_axi_lpd_aclk] \
  [get_bd_pins pl_tieoff_fpd/aclk] \
  [get_bd_pins pl_tieoff_lpd/aclk] \
  [get_bd_pins pl_tieoff_dma0/aclk] \
  [get_bd_pins pl_tieoff_dma1/aclk]
  connect_bd_net -net versal_cips_0_pl0_resetn  [get_bd_pins versal_cips_0/pl0_resetn] \
  [get_bd_pins rst_pl0/ext_reset_in]
  connect_bd_net -net versal_cips_0_pl1_ref_clk  [get_bd_pins versal_cips_0/pl1_ref_clk] \
  [get_bd_pins rst_pl1/slowest_sync_clk]
  connect_bd_net -net versal_cips_0_pl1_resetn  [get_bd_pins versal_cips_0/pl1_resetn] \
  [get_bd_pins rst_pl1/ext_reset_in]
  connect_bd_net -net versal_cips_0_pl2_ref_clk  [get_bd_pins versal_cips_0/pl2_ref_clk] \
  [get_bd_pins rst_pl2/slowest_sync_clk]
  connect_bd_net -net versal_cips_0_pl2_resetn  [get_bd_pins versal_cips_0/pl2_resetn] \
  [get_bd_pins rst_pl2/ext_reset_in]
  connect_bd_net -net versal_cips_0_pl3_ref_clk  [get_bd_pins versal_cips_0/pl3_ref_clk] \
  [get_bd_pins rst_pl3/slowest_sync_clk]
  connect_bd_net -net versal_cips_0_pl3_resetn  [get_bd_pins versal_cips_0/pl3_resetn] \
  [get_bd_pins rst_pl3/ext_reset_in]
  connect_bd_net -net versal_cips_0_pmc_axi_noc_axi0_clk  [get_bd_pins versal_cips_0/pmc_axi_noc_axi0_clk] \
  [get_bd_pins axi_noc_ps/aclk0]

  # Create address segments
  assign_bd_address -offset 0x00000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces versal_cips_0/FPD_CCI_NOC_0] [get_bd_addr_segs axi_noc_ps/S02_AXI/C0_DDR_LOW0] -force
  assign_bd_address -offset 0x000800000000 -range 0x000180000000 -target_address_space [get_bd_addr_spaces versal_cips_0/FPD_CCI_NOC_0] [get_bd_addr_segs axi_noc_ps/S02_AXI/C0_DDR_LOW1] -force
  assign_bd_address -offset 0x00000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces versal_cips_0/FPD_CCI_NOC_1] [get_bd_addr_segs axi_noc_ps/S03_AXI/C0_DDR_LOW0] -force
  assign_bd_address -offset 0x000800000000 -range 0x000180000000 -target_address_space [get_bd_addr_spaces versal_cips_0/FPD_CCI_NOC_1] [get_bd_addr_segs axi_noc_ps/S03_AXI/C0_DDR_LOW1] -force
  assign_bd_address -offset 0x00000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces versal_cips_0/FPD_CCI_NOC_2] [get_bd_addr_segs axi_noc_ps/S04_AXI/C0_DDR_LOW0] -force
  assign_bd_address -offset 0x000800000000 -range 0x000180000000 -target_address_space [get_bd_addr_spaces versal_cips_0/FPD_CCI_NOC_2] [get_bd_addr_segs axi_noc_ps/S04_AXI/C0_DDR_LOW1] -force
  assign_bd_address -offset 0x00000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces versal_cips_0/FPD_CCI_NOC_3] [get_bd_addr_segs axi_noc_ps/S05_AXI/C0_DDR_LOW0] -force
  assign_bd_address -offset 0x000800000000 -range 0x000180000000 -target_address_space [get_bd_addr_spaces versal_cips_0/FPD_CCI_NOC_3] [get_bd_addr_segs axi_noc_ps/S05_AXI/C0_DDR_LOW1] -force
  assign_bd_address -offset 0x00000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces versal_cips_0/LPD_AXI_NOC_0] [get_bd_addr_segs axi_noc_ps/S01_AXI/C0_DDR_LOW0] -force
  assign_bd_address -offset 0x000800000000 -range 0x000180000000 -target_address_space [get_bd_addr_spaces versal_cips_0/LPD_AXI_NOC_0] [get_bd_addr_segs axi_noc_ps/S01_AXI/C0_DDR_LOW1] -force
  assign_bd_address -offset 0x00000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces versal_cips_0/PMC_NOC_AXI_0] [get_bd_addr_segs axi_noc_ps/S00_AXI/C0_DDR_LOW0] -force
  assign_bd_address -offset 0x000800000000 -range 0x000180000000 -target_address_space [get_bd_addr_spaces versal_cips_0/PMC_NOC_AXI_0] [get_bd_addr_segs axi_noc_ps/S00_AXI/C0_DDR_LOW1] -force
  assign_bd_address -offset 0x00000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces pl_tieoff_dma0/Master_AXI] [get_bd_addr_segs axi_noc_ps/S00_INI/C0_DDR_LOW0] -force
  assign_bd_address -offset 0x000800000000 -range 0x000180000000 -target_address_space [get_bd_addr_spaces pl_tieoff_dma0/Master_AXI] [get_bd_addr_segs axi_noc_ps/S00_INI/C0_DDR_LOW1] -force
  assign_bd_address -offset 0x00000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces pl_tieoff_dma1/Master_AXI] [get_bd_addr_segs axi_noc_ps/S00_INI/C0_DDR_LOW0] -force
  assign_bd_address -offset 0x000800000000 -range 0x000180000000 -target_address_space [get_bd_addr_spaces pl_tieoff_dma1/Master_AXI] [get_bd_addr_segs axi_noc_ps/S00_INI/C0_DDR_LOW1] -force


  # Restore current instance
  current_bd_instance $oldCurInst

  validate_bd_design
  save_bd_design
}
# End of create_root_design()


##################################################################
# MAIN FLOW
##################################################################

create_root_design ""


