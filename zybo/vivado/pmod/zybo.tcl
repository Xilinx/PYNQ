
################################################################
# This is a generated script based on design: system
#
# Though there are limitations about the generated script,
# the main purpose of this utility is to make learning
# IP Integrator Tcl commands easier.
################################################################

################################################################
# Check if script is running in correct Vivado version.
################################################################
set scripts_vivado_version 2015.3
set current_vivado_version [version -short]

if { [string first $scripts_vivado_version $current_vivado_version] == -1 } {
   puts ""
   puts "ERROR: This script was generated using Vivado <$scripts_vivado_version> and is being run in <$current_vivado_version> of Vivado. Please run the script in Vivado <$scripts_vivado_version> then open the design in Vivado <$current_vivado_version>. Upgrade the design by running \"Tools => Report => Report IP Status...\", then run write_bd_tcl to create an updated script."

   return 1
}

################################################################
# START
################################################################

# To test this script, run the following commands from Vivado Tcl console:
# source system_script.tcl

# If you do not already have a project created,
# you can create a project using the following command:
#    create_project project_1 myproj -part xc7z010clg400-1

# CHECKING IF PROJECT EXISTS
if { [get_projects -quiet] eq "" } {
   create_project project_1 zybo -part xc7z010clg400-1
}

set_property  ip_repo_paths  ./src/ip [current_project]
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

   set errMsg "ERROR: Please set the variable <design_name> to a non-empty value."
   set nRet 1

} elseif { ${cur_design} ne "" && ${list_cells} eq "" } {
   # USE CASES:
   #    2): Current design opened AND is empty AND names same.
   #    3): Current design opened AND is empty AND names diff; design_name NOT in project.
   #    4): Current design opened AND is empty AND names diff; design_name exists in project.

   if { $cur_design ne $design_name } {
      puts "INFO: Changing value of <design_name> from <$design_name> to <$cur_design> since current design is empty."
      set design_name [get_property NAME $cur_design]
   }
   puts "INFO: Constructing design in IPI design <$cur_design>..."

} elseif { ${cur_design} ne "" && $list_cells ne "" && $cur_design eq $design_name } {
   # USE CASES:
   #    5) Current design opened AND has components AND same names.

   set errMsg "ERROR: Design <$design_name> already exists in your project, please set the variable <design_name> to another value."
   set nRet 1
} elseif { [get_files -quiet ${design_name}.bd] ne "" } {
   # USE CASES: 
   #    6) Current opened design, has components, but diff names, design_name exists in project.
   #    7) No opened design, design_name exists in project.

   set errMsg "ERROR: Design <$design_name> already exists in your project, please set the variable <design_name> to another value."
   set nRet 2

} else {
   # USE CASES:
   #    8) No opened design, design_name not in project.
   #    9) Current opened design, has components, but diff names, design_name not in project.

   puts "INFO: Currently there is no design <$design_name> in project, so creating one..."

   create_bd_design $design_name

   puts "INFO: Making design <$design_name> as current_bd_design."
   current_bd_design $design_name

}

puts "INFO: Currently the variable <design_name> is equal to \"$design_name\"."

if { $nRet != 0 } {
   puts $errMsg
   return $nRet
}

##################################################################
# DESIGN PROCs
##################################################################


# Hierarchical cell: mb4_lmb
proc create_hier_cell_mb4_lmb { parentCell nameHier } {

  if { $parentCell eq "" || $nameHier eq "" } {
     puts "ERROR: create_hier_cell_mb4_lmb() - Empty argument(s)!"
     return
  }

  # Get object for parentCell
  set parentObj [get_bd_cells $parentCell]
  if { $parentObj == "" } {
     puts "ERROR: Unable to find parent cell <$parentCell>!"
     return
  }

  # Make sure parentObj is hier blk
  set parentType [get_property TYPE $parentObj]
  if { $parentType ne "hier" } {
     puts "ERROR: Parent <$parentObj> has TYPE = <$parentType>. Expected to be <hier>."
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

# Hierarchical cell: mb3_lmb
proc create_hier_cell_mb3_lmb { parentCell nameHier } {

  if { $parentCell eq "" || $nameHier eq "" } {
     puts "ERROR: create_hier_cell_mb3_lmb() - Empty argument(s)!"
     return
  }

  # Get object for parentCell
  set parentObj [get_bd_cells $parentCell]
  if { $parentObj == "" } {
     puts "ERROR: Unable to find parent cell <$parentCell>!"
     return
  }

  # Make sure parentObj is hier blk
  set parentType [get_property TYPE $parentObj]
  if { $parentType ne "hier" } {
     puts "ERROR: Parent <$parentObj> has TYPE = <$parentType>. Expected to be <hier>."
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

# Hierarchical cell: mb2_lmb
proc create_hier_cell_mb2_lmb { parentCell nameHier } {

  if { $parentCell eq "" || $nameHier eq "" } {
     puts "ERROR: create_hier_cell_mb2_lmb() - Empty argument(s)!"
     return
  }

  # Get object for parentCell
  set parentObj [get_bd_cells $parentCell]
  if { $parentObj == "" } {
     puts "ERROR: Unable to find parent cell <$parentCell>!"
     return
  }

  # Make sure parentObj is hier blk
  set parentType [get_property TYPE $parentObj]
  if { $parentType ne "hier" } {
     puts "ERROR: Parent <$parentObj> has TYPE = <$parentType>. Expected to be <hier>."
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

  if { $parentCell eq "" || $nameHier eq "" } {
     puts "ERROR: create_hier_cell_mb1_lmb() - Empty argument(s)!"
     return
  }

  # Get object for parentCell
  set parentObj [get_bd_cells $parentCell]
  if { $parentObj == "" } {
     puts "ERROR: Unable to find parent cell <$parentCell>!"
     return
  }

  # Make sure parentObj is hier blk
  set parentType [get_property TYPE $parentObj]
  if { $parentType ne "hier" } {
     puts "ERROR: Parent <$parentObj> has TYPE = <$parentType>. Expected to be <hier>."
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

# Hierarchical cell: mb_JE
proc create_hier_cell_mb_JE { parentCell nameHier } {

  if { $parentCell eq "" || $nameHier eq "" } {
     puts "ERROR: create_hier_cell_mb_JE() - Empty argument(s)!"
     return
  }

  # Get object for parentCell
  set parentObj [get_bd_cells $parentCell]
  if { $parentObj == "" } {
     puts "ERROR: Unable to find parent cell <$parentCell>!"
     return
  }

  # Make sure parentObj is hier blk
  set parentType [get_property TYPE $parentObj]
  if { $parentType ne "hier" } {
     puts "ERROR: Parent <$parentObj> has TYPE = <$parentType>. Expected to be <hier>."
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
  create_bd_pin -dir I -from 0 -to 0 -type rst aux_reset_in
  create_bd_pin -dir I -type clk clk
  create_bd_pin -dir I -from 0 -to 0 -type rst ext_reset_in
  create_bd_pin -dir I -type rst mb_debug_sys_rst
  create_bd_pin -dir I -from 7 -to 0 pmod2sw_data_in
  create_bd_pin -dir O -from 7 -to 0 sw2pmod_data_out
  create_bd_pin -dir O -from 7 -to 0 sw2pmod_tri_out

  # Create instance: mb4_PMOD_IO_Switch_IP, and set properties
  set mb4_PMOD_IO_Switch_IP [ create_bd_cell -type ip -vlnv xilinx.com:user:PMOD_IO_Switch_IP:1.0 mb4_PMOD_IO_Switch_IP ]

  # Create instance: mb4_gpio, and set properties
  set mb4_gpio [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_gpio:2.0 mb4_gpio ]
  set_property -dict [ list \
CONFIG.C_GPIO_WIDTH {8} \
 ] $mb4_gpio

  # Create instance: mb4_iic, and set properties
  set mb4_iic [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_iic:2.0 mb4_iic ]

  # Create instance: mb4_lmb
  create_hier_cell_mb4_lmb $hier_obj mb4_lmb

  # Create instance: mb4_spi, and set properties
  set mb4_spi [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_quad_spi:3.2 mb4_spi ]
  set_property -dict [ list \
CONFIG.C_USE_STARTUP {0} \
 ] $mb4_spi

  # Create instance: mb_4, and set properties
  set mb_4 [ create_bd_cell -type ip -vlnv xilinx.com:ip:microblaze:9.5 mb_4 ]
  set_property -dict [ list \
CONFIG.C_DEBUG_ENABLED {1} \
CONFIG.C_D_AXI {1} \
CONFIG.C_D_LMB {1} \
CONFIG.C_I_LMB {1} \
 ] $mb_4

  # Create instance: microblaze_0_axi_periph, and set properties
  set microblaze_0_axi_periph [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_interconnect:2.1 microblaze_0_axi_periph ]
  set_property -dict [ list \
CONFIG.NUM_MI {4} \
 ] $microblaze_0_axi_periph

  # Create instance: rst_clk_wiz_1_100M, and set properties
  set rst_clk_wiz_1_100M [ create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset:5.0 rst_clk_wiz_1_100M ]
  set_property -dict [ list \
CONFIG.C_AUX_RESET_HIGH {1} \
 ] $rst_clk_wiz_1_100M

  # Create interface connections
  connect_bd_intf_net -intf_net axi_bram_ctrl_1_BRAM_PORTA [get_bd_intf_pins BRAM_PORTB] [get_bd_intf_pins mb4_lmb/BRAM_PORTB]
  connect_bd_intf_net -intf_net microblaze_0_M_AXI_DP [get_bd_intf_pins mb_4/M_AXI_DP] [get_bd_intf_pins microblaze_0_axi_periph/S00_AXI]
  connect_bd_intf_net -intf_net microblaze_0_axi_periph_M00_AXI [get_bd_intf_pins mb4_spi/AXI_LITE] [get_bd_intf_pins microblaze_0_axi_periph/M00_AXI]
  connect_bd_intf_net -intf_net microblaze_0_axi_periph_M01_AXI [get_bd_intf_pins mb4_iic/S_AXI] [get_bd_intf_pins microblaze_0_axi_periph/M01_AXI]
  connect_bd_intf_net -intf_net microblaze_0_axi_periph_M02_AXI [get_bd_intf_pins mb4_PMOD_IO_Switch_IP/S00_AXI] [get_bd_intf_pins microblaze_0_axi_periph/M02_AXI]
  connect_bd_intf_net -intf_net microblaze_0_axi_periph_M03_AXI [get_bd_intf_pins mb4_gpio/S_AXI] [get_bd_intf_pins microblaze_0_axi_periph/M03_AXI]
  connect_bd_intf_net -intf_net microblaze_0_debug [get_bd_intf_pins DEBUG] [get_bd_intf_pins mb_4/DEBUG]
  connect_bd_intf_net -intf_net microblaze_0_dlmb_1 [get_bd_intf_pins mb4_lmb/DLMB] [get_bd_intf_pins mb_4/DLMB]
  connect_bd_intf_net -intf_net microblaze_0_ilmb_1 [get_bd_intf_pins mb4_lmb/ILMB] [get_bd_intf_pins mb_4/ILMB]

  # Create port connections
  connect_bd_net -net PMOD_IO_Switch_IP_0_miso_i_in [get_bd_pins mb4_PMOD_IO_Switch_IP/miso_i_in] [get_bd_pins mb4_spi/io1_i]
  connect_bd_net -net PMOD_IO_Switch_IP_0_mosi_i_in [get_bd_pins mb4_PMOD_IO_Switch_IP/mosi_i_in] [get_bd_pins mb4_spi/io0_i]
  connect_bd_net -net PMOD_IO_Switch_IP_0_scl_i_in [get_bd_pins mb4_PMOD_IO_Switch_IP/scl_i_in] [get_bd_pins mb4_iic/scl_i]
  connect_bd_net -net PMOD_IO_Switch_IP_0_sda_i_in [get_bd_pins mb4_PMOD_IO_Switch_IP/sda_i_in] [get_bd_pins mb4_iic/sda_i]
  connect_bd_net -net PMOD_IO_Switch_IP_0_spick_i_in [get_bd_pins mb4_PMOD_IO_Switch_IP/spick_i_in] [get_bd_pins mb4_spi/sck_i]
  connect_bd_net -net PMOD_IO_Switch_IP_0_ss_i_in [get_bd_pins mb4_PMOD_IO_Switch_IP/ss_i_in] [get_bd_pins mb4_spi/ss_i]
  connect_bd_net -net PMOD_IO_Switch_IP_0_sw2pl_data_in [get_bd_pins mb4_PMOD_IO_Switch_IP/sw2pl_data_in] [get_bd_pins mb4_gpio/gpio_io_i]
  connect_bd_net -net PMOD_IO_Switch_IP_0_sw2pmod_data_out [get_bd_pins sw2pmod_data_out] [get_bd_pins mb4_PMOD_IO_Switch_IP/sw2pmod_data_out]
  connect_bd_net -net PMOD_IO_Switch_IP_0_sw2pmod_tri_out [get_bd_pins sw2pmod_tri_out] [get_bd_pins mb4_PMOD_IO_Switch_IP/sw2pmod_tri_out]
  connect_bd_net -net logic_1_dout [get_bd_pins ext_reset_in] [get_bd_pins rst_clk_wiz_1_100M/ext_reset_in]
  connect_bd_net -net mb1_gpio_gpio_io_o [get_bd_pins mb4_PMOD_IO_Switch_IP/pl2sw_data_o] [get_bd_pins mb4_gpio/gpio_io_o]
  connect_bd_net -net mb1_gpio_gpio_io_t [get_bd_pins mb4_PMOD_IO_Switch_IP/pl2sw_tri_o] [get_bd_pins mb4_gpio/gpio_io_t]
  connect_bd_net -net mb1_iic_scl_o [get_bd_pins mb4_PMOD_IO_Switch_IP/scl_o_in] [get_bd_pins mb4_iic/scl_o]
  connect_bd_net -net mb1_iic_scl_t [get_bd_pins mb4_PMOD_IO_Switch_IP/scl_t_in] [get_bd_pins mb4_iic/scl_t]
  connect_bd_net -net mb1_iic_sda_o [get_bd_pins mb4_PMOD_IO_Switch_IP/sda_o_in] [get_bd_pins mb4_iic/sda_o]
  connect_bd_net -net mb1_iic_sda_t [get_bd_pins mb4_PMOD_IO_Switch_IP/sda_t_in] [get_bd_pins mb4_iic/sda_t]
  connect_bd_net -net mb1_spi_io0_o [get_bd_pins mb4_PMOD_IO_Switch_IP/mosi_o_in] [get_bd_pins mb4_spi/io0_o]
  connect_bd_net -net mb1_spi_io0_t [get_bd_pins mb4_PMOD_IO_Switch_IP/mosi_t_in] [get_bd_pins mb4_spi/io0_t]
  connect_bd_net -net mb1_spi_io1_o [get_bd_pins mb4_PMOD_IO_Switch_IP/miso_o_in] [get_bd_pins mb4_spi/io1_o]
  connect_bd_net -net mb1_spi_io1_t [get_bd_pins mb4_PMOD_IO_Switch_IP/miso_t_in] [get_bd_pins mb4_spi/io1_t]
  connect_bd_net -net mb1_spi_sck_o [get_bd_pins mb4_PMOD_IO_Switch_IP/spick_o_in] [get_bd_pins mb4_spi/sck_o]
  connect_bd_net -net mb1_spi_sck_t [get_bd_pins mb4_PMOD_IO_Switch_IP/spick_t_in] [get_bd_pins mb4_spi/sck_t]
  connect_bd_net -net mb1_spi_ss_o [get_bd_pins mb4_PMOD_IO_Switch_IP/ss_o_in] [get_bd_pins mb4_spi/ss_o]
  connect_bd_net -net mb1_spi_ss_t [get_bd_pins mb4_PMOD_IO_Switch_IP/ss_t_in] [get_bd_pins mb4_spi/ss_t]
  connect_bd_net -net mb_1_reset_Dout [get_bd_pins aux_reset_in] [get_bd_pins rst_clk_wiz_1_100M/aux_reset_in]
  connect_bd_net -net mdm_1_debug_sys_rst [get_bd_pins mb_debug_sys_rst] [get_bd_pins rst_clk_wiz_1_100M/mb_debug_sys_rst]
  connect_bd_net -net pmod2sw_data_in_1 [get_bd_pins pmod2sw_data_in] [get_bd_pins mb4_PMOD_IO_Switch_IP/pmod2sw_data_in]
  connect_bd_net -net processing_system7_0_FCLK_CLK0 [get_bd_pins clk] [get_bd_pins mb4_PMOD_IO_Switch_IP/s00_axi_aclk] [get_bd_pins mb4_gpio/s_axi_aclk] [get_bd_pins mb4_iic/s_axi_aclk] [get_bd_pins mb4_lmb/LMB_Clk] [get_bd_pins mb4_spi/ext_spi_clk] [get_bd_pins mb4_spi/s_axi_aclk] [get_bd_pins mb_4/Clk] [get_bd_pins microblaze_0_axi_periph/ACLK] [get_bd_pins microblaze_0_axi_periph/M00_ACLK] [get_bd_pins microblaze_0_axi_periph/M01_ACLK] [get_bd_pins microblaze_0_axi_periph/M02_ACLK] [get_bd_pins microblaze_0_axi_periph/M03_ACLK] [get_bd_pins microblaze_0_axi_periph/S00_ACLK] [get_bd_pins rst_clk_wiz_1_100M/slowest_sync_clk]
  connect_bd_net -net rst_clk_wiz_1_100M_bus_struct_reset [get_bd_pins mb4_lmb/SYS_Rst] [get_bd_pins rst_clk_wiz_1_100M/bus_struct_reset]
  connect_bd_net -net rst_clk_wiz_1_100M_interconnect_aresetn [get_bd_pins microblaze_0_axi_periph/ARESETN] [get_bd_pins rst_clk_wiz_1_100M/interconnect_aresetn]
  connect_bd_net -net rst_clk_wiz_1_100M_mb_reset [get_bd_pins mb_4/Reset] [get_bd_pins rst_clk_wiz_1_100M/mb_reset]
  connect_bd_net -net rst_clk_wiz_1_100M_peripheral_aresetn [get_bd_pins mb4_PMOD_IO_Switch_IP/s00_axi_aresetn] [get_bd_pins mb4_gpio/s_axi_aresetn] [get_bd_pins mb4_iic/s_axi_aresetn] [get_bd_pins mb4_spi/s_axi_aresetn] [get_bd_pins microblaze_0_axi_periph/M00_ARESETN] [get_bd_pins microblaze_0_axi_periph/M01_ARESETN] [get_bd_pins microblaze_0_axi_periph/M02_ARESETN] [get_bd_pins microblaze_0_axi_periph/M03_ARESETN] [get_bd_pins microblaze_0_axi_periph/S00_ARESETN] [get_bd_pins rst_clk_wiz_1_100M/peripheral_aresetn]

  # Restore current instance
  current_bd_instance $oldCurInst
}

# Hierarchical cell: mb_JD
proc create_hier_cell_mb_JD { parentCell nameHier } {

  if { $parentCell eq "" || $nameHier eq "" } {
     puts "ERROR: create_hier_cell_mb_JD() - Empty argument(s)!"
     return
  }

  # Get object for parentCell
  set parentObj [get_bd_cells $parentCell]
  if { $parentObj == "" } {
     puts "ERROR: Unable to find parent cell <$parentCell>!"
     return
  }

  # Make sure parentObj is hier blk
  set parentType [get_property TYPE $parentObj]
  if { $parentType ne "hier" } {
     puts "ERROR: Parent <$parentObj> has TYPE = <$parentType>. Expected to be <hier>."
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
  create_bd_pin -dir I -from 0 -to 0 -type rst aux_reset_in
  create_bd_pin -dir I -type clk clk
  create_bd_pin -dir I -from 0 -to 0 -type rst ext_reset_in
  create_bd_pin -dir I -type rst mb_debug_sys_rst
  create_bd_pin -dir I -from 7 -to 0 pmod2sw_data_in
  create_bd_pin -dir O -from 7 -to 0 sw2pmod_data_out
  create_bd_pin -dir O -from 7 -to 0 sw2pmod_tri_out

  # Create instance: mb3_PMOD_IO_Switch_IP, and set properties
  set mb3_PMOD_IO_Switch_IP [ create_bd_cell -type ip -vlnv xilinx.com:user:PMOD_IO_Switch_IP:1.0 mb3_PMOD_IO_Switch_IP ]

  # Create instance: mb3_gpio, and set properties
  set mb3_gpio [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_gpio:2.0 mb3_gpio ]
  set_property -dict [ list \
CONFIG.C_GPIO_WIDTH {8} \
 ] $mb3_gpio

  # Create instance: mb3_iic, and set properties
  set mb3_iic [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_iic:2.0 mb3_iic ]

  # Create instance: mb3_lmb
  create_hier_cell_mb3_lmb $hier_obj mb3_lmb

  # Create instance: mb3_spi, and set properties
  set mb3_spi [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_quad_spi:3.2 mb3_spi ]
  set_property -dict [ list \
CONFIG.C_USE_STARTUP {0} \
 ] $mb3_spi

  # Create instance: mb_3, and set properties
  set mb_3 [ create_bd_cell -type ip -vlnv xilinx.com:ip:microblaze:9.5 mb_3 ]
  set_property -dict [ list \
CONFIG.C_DEBUG_ENABLED {1} \
CONFIG.C_D_AXI {1} \
CONFIG.C_D_LMB {1} \
CONFIG.C_I_LMB {1} \
 ] $mb_3

  # Create instance: microblaze_0_axi_periph, and set properties
  set microblaze_0_axi_periph [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_interconnect:2.1 microblaze_0_axi_periph ]
  set_property -dict [ list \
CONFIG.NUM_MI {4} \
 ] $microblaze_0_axi_periph

  # Create instance: rst_clk_wiz_1_100M, and set properties
  set rst_clk_wiz_1_100M [ create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset:5.0 rst_clk_wiz_1_100M ]
  set_property -dict [ list \
CONFIG.C_AUX_RESET_HIGH {1} \
 ] $rst_clk_wiz_1_100M

  # Create interface connections
  connect_bd_intf_net -intf_net axi_bram_ctrl_1_BRAM_PORTA [get_bd_intf_pins BRAM_PORTB] [get_bd_intf_pins mb3_lmb/BRAM_PORTB]
  connect_bd_intf_net -intf_net microblaze_0_M_AXI_DP [get_bd_intf_pins mb_3/M_AXI_DP] [get_bd_intf_pins microblaze_0_axi_periph/S00_AXI]
  connect_bd_intf_net -intf_net microblaze_0_axi_periph_M00_AXI [get_bd_intf_pins mb3_spi/AXI_LITE] [get_bd_intf_pins microblaze_0_axi_periph/M00_AXI]
  connect_bd_intf_net -intf_net microblaze_0_axi_periph_M01_AXI [get_bd_intf_pins mb3_iic/S_AXI] [get_bd_intf_pins microblaze_0_axi_periph/M01_AXI]
  connect_bd_intf_net -intf_net microblaze_0_axi_periph_M02_AXI [get_bd_intf_pins mb3_PMOD_IO_Switch_IP/S00_AXI] [get_bd_intf_pins microblaze_0_axi_periph/M02_AXI]
  connect_bd_intf_net -intf_net microblaze_0_axi_periph_M03_AXI [get_bd_intf_pins mb3_gpio/S_AXI] [get_bd_intf_pins microblaze_0_axi_periph/M03_AXI]
  connect_bd_intf_net -intf_net microblaze_0_debug [get_bd_intf_pins DEBUG] [get_bd_intf_pins mb_3/DEBUG]
  connect_bd_intf_net -intf_net microblaze_0_dlmb_1 [get_bd_intf_pins mb3_lmb/DLMB] [get_bd_intf_pins mb_3/DLMB]
  connect_bd_intf_net -intf_net microblaze_0_ilmb_1 [get_bd_intf_pins mb3_lmb/ILMB] [get_bd_intf_pins mb_3/ILMB]

  # Create port connections
  connect_bd_net -net PMOD_IO_Switch_IP_0_miso_i_in [get_bd_pins mb3_PMOD_IO_Switch_IP/miso_i_in] [get_bd_pins mb3_spi/io1_i]
  connect_bd_net -net PMOD_IO_Switch_IP_0_mosi_i_in [get_bd_pins mb3_PMOD_IO_Switch_IP/mosi_i_in] [get_bd_pins mb3_spi/io0_i]
  connect_bd_net -net PMOD_IO_Switch_IP_0_scl_i_in [get_bd_pins mb3_PMOD_IO_Switch_IP/scl_i_in] [get_bd_pins mb3_iic/scl_i]
  connect_bd_net -net PMOD_IO_Switch_IP_0_sda_i_in [get_bd_pins mb3_PMOD_IO_Switch_IP/sda_i_in] [get_bd_pins mb3_iic/sda_i]
  connect_bd_net -net PMOD_IO_Switch_IP_0_spick_i_in [get_bd_pins mb3_PMOD_IO_Switch_IP/spick_i_in] [get_bd_pins mb3_spi/sck_i]
  connect_bd_net -net PMOD_IO_Switch_IP_0_ss_i_in [get_bd_pins mb3_PMOD_IO_Switch_IP/ss_i_in] [get_bd_pins mb3_spi/ss_i]
  connect_bd_net -net PMOD_IO_Switch_IP_0_sw2pl_data_in [get_bd_pins mb3_PMOD_IO_Switch_IP/sw2pl_data_in] [get_bd_pins mb3_gpio/gpio_io_i]
  connect_bd_net -net PMOD_IO_Switch_IP_0_sw2pmod_data_out [get_bd_pins sw2pmod_data_out] [get_bd_pins mb3_PMOD_IO_Switch_IP/sw2pmod_data_out]
  connect_bd_net -net PMOD_IO_Switch_IP_0_sw2pmod_tri_out [get_bd_pins sw2pmod_tri_out] [get_bd_pins mb3_PMOD_IO_Switch_IP/sw2pmod_tri_out]
  connect_bd_net -net logic_1_dout [get_bd_pins ext_reset_in] [get_bd_pins rst_clk_wiz_1_100M/ext_reset_in]
  connect_bd_net -net mb1_gpio_gpio_io_o [get_bd_pins mb3_PMOD_IO_Switch_IP/pl2sw_data_o] [get_bd_pins mb3_gpio/gpio_io_o]
  connect_bd_net -net mb1_gpio_gpio_io_t [get_bd_pins mb3_PMOD_IO_Switch_IP/pl2sw_tri_o] [get_bd_pins mb3_gpio/gpio_io_t]
  connect_bd_net -net mb1_iic_scl_o [get_bd_pins mb3_PMOD_IO_Switch_IP/scl_o_in] [get_bd_pins mb3_iic/scl_o]
  connect_bd_net -net mb1_iic_scl_t [get_bd_pins mb3_PMOD_IO_Switch_IP/scl_t_in] [get_bd_pins mb3_iic/scl_t]
  connect_bd_net -net mb1_iic_sda_o [get_bd_pins mb3_PMOD_IO_Switch_IP/sda_o_in] [get_bd_pins mb3_iic/sda_o]
  connect_bd_net -net mb1_iic_sda_t [get_bd_pins mb3_PMOD_IO_Switch_IP/sda_t_in] [get_bd_pins mb3_iic/sda_t]
  connect_bd_net -net mb1_spi_io0_o [get_bd_pins mb3_PMOD_IO_Switch_IP/mosi_o_in] [get_bd_pins mb3_spi/io0_o]
  connect_bd_net -net mb1_spi_io0_t [get_bd_pins mb3_PMOD_IO_Switch_IP/mosi_t_in] [get_bd_pins mb3_spi/io0_t]
  connect_bd_net -net mb1_spi_io1_o [get_bd_pins mb3_PMOD_IO_Switch_IP/miso_o_in] [get_bd_pins mb3_spi/io1_o]
  connect_bd_net -net mb1_spi_io1_t [get_bd_pins mb3_PMOD_IO_Switch_IP/miso_t_in] [get_bd_pins mb3_spi/io1_t]
  connect_bd_net -net mb1_spi_sck_o [get_bd_pins mb3_PMOD_IO_Switch_IP/spick_o_in] [get_bd_pins mb3_spi/sck_o]
  connect_bd_net -net mb1_spi_sck_t [get_bd_pins mb3_PMOD_IO_Switch_IP/spick_t_in] [get_bd_pins mb3_spi/sck_t]
  connect_bd_net -net mb1_spi_ss_o [get_bd_pins mb3_PMOD_IO_Switch_IP/ss_o_in] [get_bd_pins mb3_spi/ss_o]
  connect_bd_net -net mb1_spi_ss_t [get_bd_pins mb3_PMOD_IO_Switch_IP/ss_t_in] [get_bd_pins mb3_spi/ss_t]
  connect_bd_net -net mb_1_reset_Dout [get_bd_pins aux_reset_in] [get_bd_pins rst_clk_wiz_1_100M/aux_reset_in]
  connect_bd_net -net mdm_1_debug_sys_rst [get_bd_pins mb_debug_sys_rst] [get_bd_pins rst_clk_wiz_1_100M/mb_debug_sys_rst]
  connect_bd_net -net pmod2sw_data_in_1 [get_bd_pins pmod2sw_data_in] [get_bd_pins mb3_PMOD_IO_Switch_IP/pmod2sw_data_in]
  connect_bd_net -net processing_system7_0_FCLK_CLK0 [get_bd_pins clk] [get_bd_pins mb3_PMOD_IO_Switch_IP/s00_axi_aclk] [get_bd_pins mb3_gpio/s_axi_aclk] [get_bd_pins mb3_iic/s_axi_aclk] [get_bd_pins mb3_lmb/LMB_Clk] [get_bd_pins mb3_spi/ext_spi_clk] [get_bd_pins mb3_spi/s_axi_aclk] [get_bd_pins mb_3/Clk] [get_bd_pins microblaze_0_axi_periph/ACLK] [get_bd_pins microblaze_0_axi_periph/M00_ACLK] [get_bd_pins microblaze_0_axi_periph/M01_ACLK] [get_bd_pins microblaze_0_axi_periph/M02_ACLK] [get_bd_pins microblaze_0_axi_periph/M03_ACLK] [get_bd_pins microblaze_0_axi_periph/S00_ACLK] [get_bd_pins rst_clk_wiz_1_100M/slowest_sync_clk]
  connect_bd_net -net rst_clk_wiz_1_100M_bus_struct_reset [get_bd_pins mb3_lmb/SYS_Rst] [get_bd_pins rst_clk_wiz_1_100M/bus_struct_reset]
  connect_bd_net -net rst_clk_wiz_1_100M_interconnect_aresetn [get_bd_pins microblaze_0_axi_periph/ARESETN] [get_bd_pins rst_clk_wiz_1_100M/interconnect_aresetn]
  connect_bd_net -net rst_clk_wiz_1_100M_mb_reset [get_bd_pins mb_3/Reset] [get_bd_pins rst_clk_wiz_1_100M/mb_reset]
  connect_bd_net -net rst_clk_wiz_1_100M_peripheral_aresetn [get_bd_pins mb3_PMOD_IO_Switch_IP/s00_axi_aresetn] [get_bd_pins mb3_gpio/s_axi_aresetn] [get_bd_pins mb3_iic/s_axi_aresetn] [get_bd_pins mb3_spi/s_axi_aresetn] [get_bd_pins microblaze_0_axi_periph/M00_ARESETN] [get_bd_pins microblaze_0_axi_periph/M01_ARESETN] [get_bd_pins microblaze_0_axi_periph/M02_ARESETN] [get_bd_pins microblaze_0_axi_periph/M03_ARESETN] [get_bd_pins microblaze_0_axi_periph/S00_ARESETN] [get_bd_pins rst_clk_wiz_1_100M/peripheral_aresetn]

  # Restore current instance
  current_bd_instance $oldCurInst
}

# Hierarchical cell: mb_JC
proc create_hier_cell_mb_JC { parentCell nameHier } {

  if { $parentCell eq "" || $nameHier eq "" } {
     puts "ERROR: create_hier_cell_mb_JC() - Empty argument(s)!"
     return
  }

  # Get object for parentCell
  set parentObj [get_bd_cells $parentCell]
  if { $parentObj == "" } {
     puts "ERROR: Unable to find parent cell <$parentCell>!"
     return
  }

  # Make sure parentObj is hier blk
  set parentType [get_property TYPE $parentObj]
  if { $parentType ne "hier" } {
     puts "ERROR: Parent <$parentObj> has TYPE = <$parentType>. Expected to be <hier>."
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
  create_bd_pin -dir I -from 0 -to 0 -type rst aux_reset_in
  create_bd_pin -dir I -type clk clk
  create_bd_pin -dir I -from 0 -to 0 -type rst ext_reset_in
  create_bd_pin -dir I -type rst mb_debug_sys_rst
  create_bd_pin -dir I -from 7 -to 0 pmod2sw_data_in
  create_bd_pin -dir O -from 7 -to 0 sw2pmod_data_out
  create_bd_pin -dir O -from 7 -to 0 sw2pmod_tri_out

  # Create instance: mb2_PMOD_IO_Switch_IP, and set properties
  set mb2_PMOD_IO_Switch_IP [ create_bd_cell -type ip -vlnv xilinx.com:user:PMOD_IO_Switch_IP:1.0 mb2_PMOD_IO_Switch_IP ]

  # Create instance: mb2_gpio, and set properties
  set mb2_gpio [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_gpio:2.0 mb2_gpio ]
  set_property -dict [ list \
CONFIG.C_GPIO_WIDTH {8} \
 ] $mb2_gpio

  # Create instance: mb2_iic, and set properties
  set mb2_iic [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_iic:2.0 mb2_iic ]

  # Create instance: mb2_lmb
  create_hier_cell_mb2_lmb $hier_obj mb2_lmb

  # Create instance: mb2_spi, and set properties
  set mb2_spi [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_quad_spi:3.2 mb2_spi ]
  set_property -dict [ list \
CONFIG.C_USE_STARTUP {0} \
 ] $mb2_spi

  # Create instance: mb_2, and set properties
  set mb_2 [ create_bd_cell -type ip -vlnv xilinx.com:ip:microblaze:9.5 mb_2 ]
  set_property -dict [ list \
CONFIG.C_DEBUG_ENABLED {1} \
CONFIG.C_D_AXI {1} \
CONFIG.C_D_LMB {1} \
CONFIG.C_I_LMB {1} \
 ] $mb_2

  # Create instance: microblaze_0_axi_periph, and set properties
  set microblaze_0_axi_periph [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_interconnect:2.1 microblaze_0_axi_periph ]
  set_property -dict [ list \
CONFIG.NUM_MI {4} \
 ] $microblaze_0_axi_periph

  # Create instance: rst_clk_wiz_1_100M, and set properties
  set rst_clk_wiz_1_100M [ create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset:5.0 rst_clk_wiz_1_100M ]
  set_property -dict [ list \
CONFIG.C_AUX_RESET_HIGH {1} \
 ] $rst_clk_wiz_1_100M

  # Create interface connections
  connect_bd_intf_net -intf_net axi_bram_ctrl_1_BRAM_PORTA [get_bd_intf_pins BRAM_PORTB] [get_bd_intf_pins mb2_lmb/BRAM_PORTB]
  connect_bd_intf_net -intf_net microblaze_0_M_AXI_DP [get_bd_intf_pins mb_2/M_AXI_DP] [get_bd_intf_pins microblaze_0_axi_periph/S00_AXI]
  connect_bd_intf_net -intf_net microblaze_0_axi_periph_M00_AXI [get_bd_intf_pins mb2_spi/AXI_LITE] [get_bd_intf_pins microblaze_0_axi_periph/M00_AXI]
  connect_bd_intf_net -intf_net microblaze_0_axi_periph_M01_AXI [get_bd_intf_pins mb2_iic/S_AXI] [get_bd_intf_pins microblaze_0_axi_periph/M01_AXI]
  connect_bd_intf_net -intf_net microblaze_0_axi_periph_M02_AXI [get_bd_intf_pins mb2_PMOD_IO_Switch_IP/S00_AXI] [get_bd_intf_pins microblaze_0_axi_periph/M02_AXI]
  connect_bd_intf_net -intf_net microblaze_0_axi_periph_M03_AXI [get_bd_intf_pins mb2_gpio/S_AXI] [get_bd_intf_pins microblaze_0_axi_periph/M03_AXI]
  connect_bd_intf_net -intf_net microblaze_0_debug [get_bd_intf_pins DEBUG] [get_bd_intf_pins mb_2/DEBUG]
  connect_bd_intf_net -intf_net microblaze_0_dlmb_1 [get_bd_intf_pins mb2_lmb/DLMB] [get_bd_intf_pins mb_2/DLMB]
  connect_bd_intf_net -intf_net microblaze_0_ilmb_1 [get_bd_intf_pins mb2_lmb/ILMB] [get_bd_intf_pins mb_2/ILMB]

  # Create port connections
  connect_bd_net -net PMOD_IO_Switch_IP_0_miso_i_in [get_bd_pins mb2_PMOD_IO_Switch_IP/miso_i_in] [get_bd_pins mb2_spi/io1_i]
  connect_bd_net -net PMOD_IO_Switch_IP_0_mosi_i_in [get_bd_pins mb2_PMOD_IO_Switch_IP/mosi_i_in] [get_bd_pins mb2_spi/io0_i]
  connect_bd_net -net PMOD_IO_Switch_IP_0_scl_i_in [get_bd_pins mb2_PMOD_IO_Switch_IP/scl_i_in] [get_bd_pins mb2_iic/scl_i]
  connect_bd_net -net PMOD_IO_Switch_IP_0_sda_i_in [get_bd_pins mb2_PMOD_IO_Switch_IP/sda_i_in] [get_bd_pins mb2_iic/sda_i]
  connect_bd_net -net PMOD_IO_Switch_IP_0_spick_i_in [get_bd_pins mb2_PMOD_IO_Switch_IP/spick_i_in] [get_bd_pins mb2_spi/sck_i]
  connect_bd_net -net PMOD_IO_Switch_IP_0_ss_i_in [get_bd_pins mb2_PMOD_IO_Switch_IP/ss_i_in] [get_bd_pins mb2_spi/ss_i]
  connect_bd_net -net PMOD_IO_Switch_IP_0_sw2pl_data_in [get_bd_pins mb2_PMOD_IO_Switch_IP/sw2pl_data_in] [get_bd_pins mb2_gpio/gpio_io_i]
  connect_bd_net -net PMOD_IO_Switch_IP_0_sw2pmod_data_out [get_bd_pins sw2pmod_data_out] [get_bd_pins mb2_PMOD_IO_Switch_IP/sw2pmod_data_out]
  connect_bd_net -net PMOD_IO_Switch_IP_0_sw2pmod_tri_out [get_bd_pins sw2pmod_tri_out] [get_bd_pins mb2_PMOD_IO_Switch_IP/sw2pmod_tri_out]
  connect_bd_net -net logic_1_dout [get_bd_pins ext_reset_in] [get_bd_pins rst_clk_wiz_1_100M/ext_reset_in]
  connect_bd_net -net mb1_gpio_gpio_io_o [get_bd_pins mb2_PMOD_IO_Switch_IP/pl2sw_data_o] [get_bd_pins mb2_gpio/gpio_io_o]
  connect_bd_net -net mb1_gpio_gpio_io_t [get_bd_pins mb2_PMOD_IO_Switch_IP/pl2sw_tri_o] [get_bd_pins mb2_gpio/gpio_io_t]
  connect_bd_net -net mb1_iic_scl_o [get_bd_pins mb2_PMOD_IO_Switch_IP/scl_o_in] [get_bd_pins mb2_iic/scl_o]
  connect_bd_net -net mb1_iic_scl_t [get_bd_pins mb2_PMOD_IO_Switch_IP/scl_t_in] [get_bd_pins mb2_iic/scl_t]
  connect_bd_net -net mb1_iic_sda_o [get_bd_pins mb2_PMOD_IO_Switch_IP/sda_o_in] [get_bd_pins mb2_iic/sda_o]
  connect_bd_net -net mb1_iic_sda_t [get_bd_pins mb2_PMOD_IO_Switch_IP/sda_t_in] [get_bd_pins mb2_iic/sda_t]
  connect_bd_net -net mb1_spi_io0_o [get_bd_pins mb2_PMOD_IO_Switch_IP/mosi_o_in] [get_bd_pins mb2_spi/io0_o]
  connect_bd_net -net mb1_spi_io0_t [get_bd_pins mb2_PMOD_IO_Switch_IP/mosi_t_in] [get_bd_pins mb2_spi/io0_t]
  connect_bd_net -net mb1_spi_io1_o [get_bd_pins mb2_PMOD_IO_Switch_IP/miso_o_in] [get_bd_pins mb2_spi/io1_o]
  connect_bd_net -net mb1_spi_io1_t [get_bd_pins mb2_PMOD_IO_Switch_IP/miso_t_in] [get_bd_pins mb2_spi/io1_t]
  connect_bd_net -net mb1_spi_sck_o [get_bd_pins mb2_PMOD_IO_Switch_IP/spick_o_in] [get_bd_pins mb2_spi/sck_o]
  connect_bd_net -net mb1_spi_sck_t [get_bd_pins mb2_PMOD_IO_Switch_IP/spick_t_in] [get_bd_pins mb2_spi/sck_t]
  connect_bd_net -net mb1_spi_ss_o [get_bd_pins mb2_PMOD_IO_Switch_IP/ss_o_in] [get_bd_pins mb2_spi/ss_o]
  connect_bd_net -net mb1_spi_ss_t [get_bd_pins mb2_PMOD_IO_Switch_IP/ss_t_in] [get_bd_pins mb2_spi/ss_t]
  connect_bd_net -net mb_1_reset_Dout [get_bd_pins aux_reset_in] [get_bd_pins rst_clk_wiz_1_100M/aux_reset_in]
  connect_bd_net -net mdm_1_debug_sys_rst [get_bd_pins mb_debug_sys_rst] [get_bd_pins rst_clk_wiz_1_100M/mb_debug_sys_rst]
  connect_bd_net -net pmod2sw_data_in_1 [get_bd_pins pmod2sw_data_in] [get_bd_pins mb2_PMOD_IO_Switch_IP/pmod2sw_data_in]
  connect_bd_net -net processing_system7_0_FCLK_CLK0 [get_bd_pins clk] [get_bd_pins mb2_PMOD_IO_Switch_IP/s00_axi_aclk] [get_bd_pins mb2_gpio/s_axi_aclk] [get_bd_pins mb2_iic/s_axi_aclk] [get_bd_pins mb2_lmb/LMB_Clk] [get_bd_pins mb2_spi/ext_spi_clk] [get_bd_pins mb2_spi/s_axi_aclk] [get_bd_pins mb_2/Clk] [get_bd_pins microblaze_0_axi_periph/ACLK] [get_bd_pins microblaze_0_axi_periph/M00_ACLK] [get_bd_pins microblaze_0_axi_periph/M01_ACLK] [get_bd_pins microblaze_0_axi_periph/M02_ACLK] [get_bd_pins microblaze_0_axi_periph/M03_ACLK] [get_bd_pins microblaze_0_axi_periph/S00_ACLK] [get_bd_pins rst_clk_wiz_1_100M/slowest_sync_clk]
  connect_bd_net -net rst_clk_wiz_1_100M_bus_struct_reset [get_bd_pins mb2_lmb/SYS_Rst] [get_bd_pins rst_clk_wiz_1_100M/bus_struct_reset]
  connect_bd_net -net rst_clk_wiz_1_100M_interconnect_aresetn [get_bd_pins microblaze_0_axi_periph/ARESETN] [get_bd_pins rst_clk_wiz_1_100M/interconnect_aresetn]
  connect_bd_net -net rst_clk_wiz_1_100M_mb_reset [get_bd_pins mb_2/Reset] [get_bd_pins rst_clk_wiz_1_100M/mb_reset]
  connect_bd_net -net rst_clk_wiz_1_100M_peripheral_aresetn [get_bd_pins mb2_PMOD_IO_Switch_IP/s00_axi_aresetn] [get_bd_pins mb2_gpio/s_axi_aresetn] [get_bd_pins mb2_iic/s_axi_aresetn] [get_bd_pins mb2_spi/s_axi_aresetn] [get_bd_pins microblaze_0_axi_periph/M00_ARESETN] [get_bd_pins microblaze_0_axi_periph/M01_ARESETN] [get_bd_pins microblaze_0_axi_periph/M02_ARESETN] [get_bd_pins microblaze_0_axi_periph/M03_ARESETN] [get_bd_pins microblaze_0_axi_periph/S00_ARESETN] [get_bd_pins rst_clk_wiz_1_100M/peripheral_aresetn]

  # Restore current instance
  current_bd_instance $oldCurInst
}

# Hierarchical cell: mb_JB
proc create_hier_cell_mb_JB { parentCell nameHier } {

  if { $parentCell eq "" || $nameHier eq "" } {
     puts "ERROR: create_hier_cell_mb_JB() - Empty argument(s)!"
     return
  }

  # Get object for parentCell
  set parentObj [get_bd_cells $parentCell]
  if { $parentObj == "" } {
     puts "ERROR: Unable to find parent cell <$parentCell>!"
     return
  }

  # Make sure parentObj is hier blk
  set parentType [get_property TYPE $parentObj]
  if { $parentType ne "hier" } {
     puts "ERROR: Parent <$parentObj> has TYPE = <$parentType>. Expected to be <hier>."
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
  create_bd_pin -dir I -from 0 -to 0 -type rst aux_reset_in
  create_bd_pin -dir I -type clk clk
  create_bd_pin -dir I -from 0 -to 0 -type rst ext_reset_in
  create_bd_pin -dir I -type rst mb_debug_sys_rst
  create_bd_pin -dir I -from 7 -to 0 pmod2sw_data_in
  create_bd_pin -dir O -from 7 -to 0 sw2pmod_data_out
  create_bd_pin -dir O -from 7 -to 0 sw2pmod_tri_out

  # Create instance: mb1_PMOD_IO_Switch_IP, and set properties
  set mb1_PMOD_IO_Switch_IP [ create_bd_cell -type ip -vlnv xilinx.com:user:PMOD_IO_Switch_IP:1.0 mb1_PMOD_IO_Switch_IP ]

  # Create instance: mb1_gpio, and set properties
  set mb1_gpio [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_gpio:2.0 mb1_gpio ]
  set_property -dict [ list \
CONFIG.C_GPIO_WIDTH {8} \
 ] $mb1_gpio

  # Create instance: mb1_iic, and set properties
  set mb1_iic [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_iic:2.0 mb1_iic ]

  # Create instance: mb1_lmb
  create_hier_cell_mb1_lmb $hier_obj mb1_lmb

  # Create instance: mb1_spi, and set properties
  set mb1_spi [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_quad_spi:3.2 mb1_spi ]
  set_property -dict [ list \
CONFIG.C_USE_STARTUP {0} \
 ] $mb1_spi

  # Create instance: mb_1, and set properties
  set mb_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:microblaze:9.5 mb_1 ]
  set_property -dict [ list \
CONFIG.C_DEBUG_ENABLED {1} \
CONFIG.C_D_AXI {1} \
CONFIG.C_D_LMB {1} \
CONFIG.C_I_LMB {1} \
 ] $mb_1

  # Create instance: microblaze_0_axi_periph, and set properties
  set microblaze_0_axi_periph [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_interconnect:2.1 microblaze_0_axi_periph ]
  set_property -dict [ list \
CONFIG.NUM_MI {4} \
 ] $microblaze_0_axi_periph

  # Create instance: rst_clk_wiz_1_100M, and set properties
  set rst_clk_wiz_1_100M [ create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset:5.0 rst_clk_wiz_1_100M ]
  set_property -dict [ list \
CONFIG.C_AUX_RESET_HIGH {1} \
 ] $rst_clk_wiz_1_100M

  # Create interface connections
  connect_bd_intf_net -intf_net axi_bram_ctrl_1_BRAM_PORTA [get_bd_intf_pins BRAM_PORTB] [get_bd_intf_pins mb1_lmb/BRAM_PORTB]
  connect_bd_intf_net -intf_net microblaze_0_M_AXI_DP [get_bd_intf_pins mb_1/M_AXI_DP] [get_bd_intf_pins microblaze_0_axi_periph/S00_AXI]
  connect_bd_intf_net -intf_net microblaze_0_axi_periph_M00_AXI [get_bd_intf_pins mb1_spi/AXI_LITE] [get_bd_intf_pins microblaze_0_axi_periph/M00_AXI]
  connect_bd_intf_net -intf_net microblaze_0_axi_periph_M01_AXI [get_bd_intf_pins mb1_iic/S_AXI] [get_bd_intf_pins microblaze_0_axi_periph/M01_AXI]
  connect_bd_intf_net -intf_net microblaze_0_axi_periph_M02_AXI [get_bd_intf_pins mb1_PMOD_IO_Switch_IP/S00_AXI] [get_bd_intf_pins microblaze_0_axi_periph/M02_AXI]
  connect_bd_intf_net -intf_net microblaze_0_axi_periph_M03_AXI [get_bd_intf_pins mb1_gpio/S_AXI] [get_bd_intf_pins microblaze_0_axi_periph/M03_AXI]
  connect_bd_intf_net -intf_net microblaze_0_debug [get_bd_intf_pins DEBUG] [get_bd_intf_pins mb_1/DEBUG]
  connect_bd_intf_net -intf_net microblaze_0_dlmb_1 [get_bd_intf_pins mb1_lmb/DLMB] [get_bd_intf_pins mb_1/DLMB]
  connect_bd_intf_net -intf_net microblaze_0_ilmb_1 [get_bd_intf_pins mb1_lmb/ILMB] [get_bd_intf_pins mb_1/ILMB]

  # Create port connections
  connect_bd_net -net PMOD_IO_Switch_IP_0_miso_i_in [get_bd_pins mb1_PMOD_IO_Switch_IP/miso_i_in] [get_bd_pins mb1_spi/io1_i]
  connect_bd_net -net PMOD_IO_Switch_IP_0_mosi_i_in [get_bd_pins mb1_PMOD_IO_Switch_IP/mosi_i_in] [get_bd_pins mb1_spi/io0_i]
  connect_bd_net -net PMOD_IO_Switch_IP_0_scl_i_in [get_bd_pins mb1_PMOD_IO_Switch_IP/scl_i_in] [get_bd_pins mb1_iic/scl_i]
  connect_bd_net -net PMOD_IO_Switch_IP_0_sda_i_in [get_bd_pins mb1_PMOD_IO_Switch_IP/sda_i_in] [get_bd_pins mb1_iic/sda_i]
  connect_bd_net -net PMOD_IO_Switch_IP_0_spick_i_in [get_bd_pins mb1_PMOD_IO_Switch_IP/spick_i_in] [get_bd_pins mb1_spi/sck_i]
  connect_bd_net -net PMOD_IO_Switch_IP_0_ss_i_in [get_bd_pins mb1_PMOD_IO_Switch_IP/ss_i_in] [get_bd_pins mb1_spi/ss_i]
  connect_bd_net -net PMOD_IO_Switch_IP_0_sw2pl_data_in [get_bd_pins mb1_PMOD_IO_Switch_IP/sw2pl_data_in] [get_bd_pins mb1_gpio/gpio_io_i]
  connect_bd_net -net PMOD_IO_Switch_IP_0_sw2pmod_data_out [get_bd_pins sw2pmod_data_out] [get_bd_pins mb1_PMOD_IO_Switch_IP/sw2pmod_data_out]
  connect_bd_net -net PMOD_IO_Switch_IP_0_sw2pmod_tri_out [get_bd_pins sw2pmod_tri_out] [get_bd_pins mb1_PMOD_IO_Switch_IP/sw2pmod_tri_out]
  connect_bd_net -net logic_1_dout [get_bd_pins ext_reset_in] [get_bd_pins rst_clk_wiz_1_100M/ext_reset_in]
  connect_bd_net -net mb1_gpio_gpio_io_o [get_bd_pins mb1_PMOD_IO_Switch_IP/pl2sw_data_o] [get_bd_pins mb1_gpio/gpio_io_o]
  connect_bd_net -net mb1_gpio_gpio_io_t [get_bd_pins mb1_PMOD_IO_Switch_IP/pl2sw_tri_o] [get_bd_pins mb1_gpio/gpio_io_t]
  connect_bd_net -net mb1_iic_scl_o [get_bd_pins mb1_PMOD_IO_Switch_IP/scl_o_in] [get_bd_pins mb1_iic/scl_o]
  connect_bd_net -net mb1_iic_scl_t [get_bd_pins mb1_PMOD_IO_Switch_IP/scl_t_in] [get_bd_pins mb1_iic/scl_t]
  connect_bd_net -net mb1_iic_sda_o [get_bd_pins mb1_PMOD_IO_Switch_IP/sda_o_in] [get_bd_pins mb1_iic/sda_o]
  connect_bd_net -net mb1_iic_sda_t [get_bd_pins mb1_PMOD_IO_Switch_IP/sda_t_in] [get_bd_pins mb1_iic/sda_t]
  connect_bd_net -net mb1_spi_io0_o [get_bd_pins mb1_PMOD_IO_Switch_IP/mosi_o_in] [get_bd_pins mb1_spi/io0_o]
  connect_bd_net -net mb1_spi_io0_t [get_bd_pins mb1_PMOD_IO_Switch_IP/mosi_t_in] [get_bd_pins mb1_spi/io0_t]
  connect_bd_net -net mb1_spi_io1_o [get_bd_pins mb1_PMOD_IO_Switch_IP/miso_o_in] [get_bd_pins mb1_spi/io1_o]
  connect_bd_net -net mb1_spi_io1_t [get_bd_pins mb1_PMOD_IO_Switch_IP/miso_t_in] [get_bd_pins mb1_spi/io1_t]
  connect_bd_net -net mb1_spi_sck_o [get_bd_pins mb1_PMOD_IO_Switch_IP/spick_o_in] [get_bd_pins mb1_spi/sck_o]
  connect_bd_net -net mb1_spi_sck_t [get_bd_pins mb1_PMOD_IO_Switch_IP/spick_t_in] [get_bd_pins mb1_spi/sck_t]
  connect_bd_net -net mb1_spi_ss_o [get_bd_pins mb1_PMOD_IO_Switch_IP/ss_o_in] [get_bd_pins mb1_spi/ss_o]
  connect_bd_net -net mb1_spi_ss_t [get_bd_pins mb1_PMOD_IO_Switch_IP/ss_t_in] [get_bd_pins mb1_spi/ss_t]
  connect_bd_net -net mb_1_reset_Dout [get_bd_pins aux_reset_in] [get_bd_pins rst_clk_wiz_1_100M/aux_reset_in]
  connect_bd_net -net mdm_1_debug_sys_rst [get_bd_pins mb_debug_sys_rst] [get_bd_pins rst_clk_wiz_1_100M/mb_debug_sys_rst]
  connect_bd_net -net pmod2sw_data_in_1 [get_bd_pins pmod2sw_data_in] [get_bd_pins mb1_PMOD_IO_Switch_IP/pmod2sw_data_in]
  connect_bd_net -net processing_system7_0_FCLK_CLK0 [get_bd_pins clk] [get_bd_pins mb1_PMOD_IO_Switch_IP/s00_axi_aclk] [get_bd_pins mb1_gpio/s_axi_aclk] [get_bd_pins mb1_iic/s_axi_aclk] [get_bd_pins mb1_lmb/LMB_Clk] [get_bd_pins mb1_spi/ext_spi_clk] [get_bd_pins mb1_spi/s_axi_aclk] [get_bd_pins mb_1/Clk] [get_bd_pins microblaze_0_axi_periph/ACLK] [get_bd_pins microblaze_0_axi_periph/M00_ACLK] [get_bd_pins microblaze_0_axi_periph/M01_ACLK] [get_bd_pins microblaze_0_axi_periph/M02_ACLK] [get_bd_pins microblaze_0_axi_periph/M03_ACLK] [get_bd_pins microblaze_0_axi_periph/S00_ACLK] [get_bd_pins rst_clk_wiz_1_100M/slowest_sync_clk]
  connect_bd_net -net rst_clk_wiz_1_100M_bus_struct_reset [get_bd_pins mb1_lmb/SYS_Rst] [get_bd_pins rst_clk_wiz_1_100M/bus_struct_reset]
  connect_bd_net -net rst_clk_wiz_1_100M_interconnect_aresetn [get_bd_pins microblaze_0_axi_periph/ARESETN] [get_bd_pins rst_clk_wiz_1_100M/interconnect_aresetn]
  connect_bd_net -net rst_clk_wiz_1_100M_mb_reset [get_bd_pins mb_1/Reset] [get_bd_pins rst_clk_wiz_1_100M/mb_reset]
  connect_bd_net -net rst_clk_wiz_1_100M_peripheral_aresetn [get_bd_pins mb1_PMOD_IO_Switch_IP/s00_axi_aresetn] [get_bd_pins mb1_gpio/s_axi_aresetn] [get_bd_pins mb1_iic/s_axi_aresetn] [get_bd_pins mb1_spi/s_axi_aresetn] [get_bd_pins microblaze_0_axi_periph/M00_ARESETN] [get_bd_pins microblaze_0_axi_periph/M01_ARESETN] [get_bd_pins microblaze_0_axi_periph/M02_ARESETN] [get_bd_pins microblaze_0_axi_periph/M03_ARESETN] [get_bd_pins microblaze_0_axi_periph/S00_ARESETN] [get_bd_pins rst_clk_wiz_1_100M/peripheral_aresetn]

  # Restore current instance
  current_bd_instance $oldCurInst
}


# Procedure to create entire design; Provide argument to make
# procedure reusable. If parentCell is "", will use root.
proc create_root_design { parentCell } {

  if { $parentCell eq "" } {
     set parentCell [get_bd_cells /]
  }

  # Get object for parentCell
  set parentObj [get_bd_cells $parentCell]
  if { $parentObj == "" } {
     puts "ERROR: Unable to find parent cell <$parentCell>!"
     return
  }

  # Make sure parentObj is hier blk
  set parentType [get_property TYPE $parentObj]
  if { $parentType ne "hier" } {
     puts "ERROR: Parent <$parentObj> has TYPE = <$parentType>. Expected to be <hier>."
     return
  }

  # Save current instance; Restore later
  set oldCurInst [current_bd_instance .]

  # Set parent object as current
  current_bd_instance $parentObj


  # Create interface ports
  set DDR [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:ddrx_rtl:1.0 DDR ]
  set FIXED_IO [ create_bd_intf_port -mode Master -vlnv xilinx.com:display_processing_system7:fixedio_rtl:1.0 FIXED_IO ]
  set IIC_1 [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:iic_rtl:1.0 IIC_1 ]
  set Vaux6 [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:diff_analog_io_rtl:1.0 Vaux6 ]
  set Vaux7 [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:diff_analog_io_rtl:1.0 Vaux7 ]
  set Vaux14 [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:diff_analog_io_rtl:1.0 Vaux14 ]
  set Vaux15 [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:diff_analog_io_rtl:1.0 Vaux15 ]
  set Vp_Vn [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:diff_analog_io_rtl:1.0 Vp_Vn ]
  set btns_4bits [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:gpio_rtl:1.0 btns_4bits ]
  set leds_4bits [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:gpio_rtl:1.0 leds_4bits ]
  set sws_4bits [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:gpio_rtl:1.0 sws_4bits ]

  # Create ports
  set pmodJB_data_in [ create_bd_port -dir I -from 7 -to 0 pmodJB_data_in ]
  set pmodJB_data_out [ create_bd_port -dir O -from 7 -to 0 pmodJB_data_out ]
  set pmodJB_tri_out [ create_bd_port -dir O -from 7 -to 0 pmodJB_tri_out ]
  set pmodJC_data_in [ create_bd_port -dir I -from 7 -to 0 pmodJC_data_in ]
  set pmodJC_data_out [ create_bd_port -dir O -from 7 -to 0 pmodJC_data_out ]
  set pmodJC_tri_out [ create_bd_port -dir O -from 7 -to 0 pmodJC_tri_out ]
  set pmodJD_data_in [ create_bd_port -dir I -from 7 -to 0 pmodJD_data_in ]
  set pmodJD_data_out [ create_bd_port -dir O -from 7 -to 0 pmodJD_data_out ]
  set pmodJD_tri_out [ create_bd_port -dir O -from 7 -to 0 pmodJD_tri_out ]
  set pmodJE_data_in [ create_bd_port -dir I -from 7 -to 0 pmodJE_data_in ]
  set pmodJE_data_out [ create_bd_port -dir O -from 7 -to 0 pmodJE_data_out ]
  set pmodJE_tri_out [ create_bd_port -dir O -from 7 -to 0 pmodJE_tri_out ]

  # Create instance: axi_bram_ctrl_1, and set properties
  set axi_bram_ctrl_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_bram_ctrl:4.0 axi_bram_ctrl_1 ]
  set_property -dict [ list \
CONFIG.SINGLE_PORT_BRAM {1} \
 ] $axi_bram_ctrl_1

  # Create instance: axi_bram_ctrl_2, and set properties
  set axi_bram_ctrl_2 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_bram_ctrl:4.0 axi_bram_ctrl_2 ]
  set_property -dict [ list \
CONFIG.SINGLE_PORT_BRAM {1} \
 ] $axi_bram_ctrl_2

  # Create instance: axi_bram_ctrl_3, and set properties
  set axi_bram_ctrl_3 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_bram_ctrl:4.0 axi_bram_ctrl_3 ]
  set_property -dict [ list \
CONFIG.SINGLE_PORT_BRAM {1} \
 ] $axi_bram_ctrl_3

  # Create instance: axi_bram_ctrl_4, and set properties
  set axi_bram_ctrl_4 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_bram_ctrl:4.0 axi_bram_ctrl_4 ]
  set_property -dict [ list \
CONFIG.SINGLE_PORT_BRAM {1} \
 ] $axi_bram_ctrl_4

  # Create instance: axi_traceBuffer_v1_0_0, and set properties
  set axi_traceBuffer_v1_0_0 [ create_bd_cell -type ip -vlnv xilinx.com:user:axi_traceBuffer_v1_0:1.0 axi_traceBuffer_v1_0_0 ]

  # Create instance: bit8_logic_0, and set properties
  set bit8_logic_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant:1.1 bit8_logic_0 ]
  set_property -dict [ list \
CONFIG.CONST_VAL {0} \
CONFIG.CONST_WIDTH {8} \
 ] $bit8_logic_0

  # Create instance: btns_gpio, and set properties
  set btns_gpio [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_gpio:2.0 btns_gpio ]
  set_property -dict [ list \
CONFIG.C_ALL_INPUTS {1} \
CONFIG.C_GPIO_WIDTH {4} \
 ] $btns_gpio

  # Create instance: logic_1, and set properties
  set logic_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant:1.1 logic_1 ]

  # Create instance: mb_1_reset, and set properties
  set mb_1_reset [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice:1.0 mb_1_reset ]
  set_property -dict [ list \
CONFIG.DIN_FROM {0} \
CONFIG.DIN_TO {0} \
CONFIG.DIN_WIDTH {6} \
 ] $mb_1_reset

  # Create instance: mb_2_reset, and set properties
  set mb_2_reset [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice:1.0 mb_2_reset ]
  set_property -dict [ list \
CONFIG.DIN_FROM {1} \
CONFIG.DIN_TO {1} \
CONFIG.DIN_WIDTH {6} \
CONFIG.DOUT_WIDTH {1} \
 ] $mb_2_reset

  # Create instance: mb_3_reset, and set properties
  set mb_3_reset [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice:1.0 mb_3_reset ]
  set_property -dict [ list \
CONFIG.DIN_FROM {2} \
CONFIG.DIN_TO {2} \
CONFIG.DIN_WIDTH {6} \
CONFIG.DOUT_WIDTH {1} \
 ] $mb_3_reset

  # Create instance: mb_4_reset, and set properties
  set mb_4_reset [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice:1.0 mb_4_reset ]
  set_property -dict [ list \
CONFIG.DIN_FROM {3} \
CONFIG.DIN_TO {3} \
CONFIG.DIN_WIDTH {6} \
CONFIG.DOUT_WIDTH {1} \
 ] $mb_4_reset

  # Create instance: mb_JB
  create_hier_cell_mb_JB [current_bd_instance .] mb_JB

  # Create instance: mb_JC
  create_hier_cell_mb_JC [current_bd_instance .] mb_JC

  # Create instance: mb_JD
  create_hier_cell_mb_JD [current_bd_instance .] mb_JD

  # Create instance: mb_JE
  create_hier_cell_mb_JE [current_bd_instance .] mb_JE

  # Create instance: mdm_1, and set properties
  set mdm_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:mdm:3.2 mdm_1 ]
  set_property -dict [ list \
CONFIG.C_MB_DBG_PORTS {4} \
 ] $mdm_1

  # Create instance: processing_system7_0, and set properties
  set processing_system7_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:processing_system7:5.5 processing_system7_0 ]
  set_property -dict [ list \
CONFIG.PCW_APU_PERIPHERAL_FREQMHZ {650} \
CONFIG.PCW_CRYSTAL_PERIPHERAL_FREQMHZ {50.000000} \
CONFIG.PCW_ENET0_ENET0_IO {MIO 16 .. 27} \
CONFIG.PCW_ENET0_GRP_MDIO_ENABLE {0} \
CONFIG.PCW_ENET0_PERIPHERAL_ENABLE {1} \
CONFIG.PCW_ENET0_RESET_ENABLE {0} \
CONFIG.PCW_FPGA0_PERIPHERAL_FREQMHZ {100} \
CONFIG.PCW_GPIO_EMIO_GPIO_ENABLE {1} \
CONFIG.PCW_GPIO_EMIO_GPIO_IO {6} \
CONFIG.PCW_GPIO_MIO_GPIO_ENABLE {0} \
CONFIG.PCW_I2C1_PERIPHERAL_ENABLE {1} \
CONFIG.PCW_MIO_0_PULLUP {<Select>} \
CONFIG.PCW_MIO_10_PULLUP {<Select>} \
CONFIG.PCW_MIO_11_PULLUP {<Select>} \
CONFIG.PCW_MIO_12_PULLUP {<Select>} \
CONFIG.PCW_MIO_16_IOTYPE {LVCMOS 1.8V} \
CONFIG.PCW_MIO_16_PULLUP {enabled} \
CONFIG.PCW_MIO_16_SLEW {slow} \
CONFIG.PCW_MIO_17_IOTYPE {LVCMOS 1.8V} \
CONFIG.PCW_MIO_17_PULLUP {enabled} \
CONFIG.PCW_MIO_17_SLEW {slow} \
CONFIG.PCW_MIO_18_IOTYPE {LVCMOS 1.8V} \
CONFIG.PCW_MIO_18_PULLUP {enabled} \
CONFIG.PCW_MIO_18_SLEW {slow} \
CONFIG.PCW_MIO_19_IOTYPE {LVCMOS 1.8V} \
CONFIG.PCW_MIO_19_PULLUP {enabled} \
CONFIG.PCW_MIO_19_SLEW {slow} \
CONFIG.PCW_MIO_1_PULLUP {disabled} \
CONFIG.PCW_MIO_1_SLEW {fast} \
CONFIG.PCW_MIO_20_IOTYPE {LVCMOS 1.8V} \
CONFIG.PCW_MIO_20_PULLUP {enabled} \
CONFIG.PCW_MIO_20_SLEW {slow} \
CONFIG.PCW_MIO_21_IOTYPE {LVCMOS 1.8V} \
CONFIG.PCW_MIO_21_PULLUP {enabled} \
CONFIG.PCW_MIO_21_SLEW {slow} \
CONFIG.PCW_MIO_22_IOTYPE {LVCMOS 1.8V} \
CONFIG.PCW_MIO_22_PULLUP {enabled} \
CONFIG.PCW_MIO_22_SLEW {slow} \
CONFIG.PCW_MIO_23_IOTYPE {LVCMOS 1.8V} \
CONFIG.PCW_MIO_23_PULLUP {enabled} \
CONFIG.PCW_MIO_23_SLEW {slow} \
CONFIG.PCW_MIO_24_IOTYPE {LVCMOS 1.8V} \
CONFIG.PCW_MIO_24_PULLUP {enabled} \
CONFIG.PCW_MIO_24_SLEW {slow} \
CONFIG.PCW_MIO_25_IOTYPE {LVCMOS 1.8V} \
CONFIG.PCW_MIO_25_PULLUP {enabled} \
CONFIG.PCW_MIO_25_SLEW {slow} \
CONFIG.PCW_MIO_26_IOTYPE {LVCMOS 1.8V} \
CONFIG.PCW_MIO_26_PULLUP {enabled} \
CONFIG.PCW_MIO_26_SLEW {slow} \
CONFIG.PCW_MIO_27_IOTYPE {LVCMOS 1.8V} \
CONFIG.PCW_MIO_27_PULLUP {enabled} \
CONFIG.PCW_MIO_27_SLEW {slow} \
CONFIG.PCW_MIO_28_PULLUP {enabled} \
CONFIG.PCW_MIO_28_SLEW {slow} \
CONFIG.PCW_MIO_29_PULLUP {enabled} \
CONFIG.PCW_MIO_29_SLEW {slow} \
CONFIG.PCW_MIO_2_SLEW {fast} \
CONFIG.PCW_MIO_30_PULLUP {enabled} \
CONFIG.PCW_MIO_30_SLEW {slow} \
CONFIG.PCW_MIO_31_PULLUP {enabled} \
CONFIG.PCW_MIO_31_SLEW {slow} \
CONFIG.PCW_MIO_32_PULLUP {enabled} \
CONFIG.PCW_MIO_32_SLEW {slow} \
CONFIG.PCW_MIO_33_PULLUP {enabled} \
CONFIG.PCW_MIO_33_SLEW {slow} \
CONFIG.PCW_MIO_34_PULLUP {enabled} \
CONFIG.PCW_MIO_34_SLEW {slow} \
CONFIG.PCW_MIO_35_PULLUP {enabled} \
CONFIG.PCW_MIO_35_SLEW {slow} \
CONFIG.PCW_MIO_36_PULLUP {enabled} \
CONFIG.PCW_MIO_36_SLEW {slow} \
CONFIG.PCW_MIO_37_PULLUP {enabled} \
CONFIG.PCW_MIO_37_SLEW {slow} \
CONFIG.PCW_MIO_38_PULLUP {enabled} \
CONFIG.PCW_MIO_38_SLEW {slow} \
CONFIG.PCW_MIO_39_PULLUP {enabled} \
CONFIG.PCW_MIO_39_SLEW {slow} \
CONFIG.PCW_MIO_3_SLEW {fast} \
CONFIG.PCW_MIO_40_PULLUP {disabled} \
CONFIG.PCW_MIO_40_SLEW {fast} \
CONFIG.PCW_MIO_41_PULLUP {disabled} \
CONFIG.PCW_MIO_41_SLEW {fast} \
CONFIG.PCW_MIO_42_PULLUP {disabled} \
CONFIG.PCW_MIO_42_SLEW {fast} \
CONFIG.PCW_MIO_43_PULLUP {disabled} \
CONFIG.PCW_MIO_43_SLEW {fast} \
CONFIG.PCW_MIO_44_PULLUP {disabled} \
CONFIG.PCW_MIO_44_SLEW {fast} \
CONFIG.PCW_MIO_45_PULLUP {disabled} \
CONFIG.PCW_MIO_45_SLEW {fast} \
CONFIG.PCW_MIO_47_PULLUP {disabled} \
CONFIG.PCW_MIO_48_PULLUP {disabled} \
CONFIG.PCW_MIO_49_PULLUP {disabled} \
CONFIG.PCW_MIO_4_SLEW {fast} \
CONFIG.PCW_MIO_50_DIRECTION {<Select>} \
CONFIG.PCW_MIO_50_PULLUP {<Select>} \
CONFIG.PCW_MIO_51_DIRECTION {<Select>} \
CONFIG.PCW_MIO_51_PULLUP {<Select>} \
CONFIG.PCW_MIO_52_PULLUP {<Select>} \
CONFIG.PCW_MIO_52_SLEW {<Select>} \
CONFIG.PCW_MIO_53_PULLUP {<Select>} \
CONFIG.PCW_MIO_53_SLEW {<Select>} \
CONFIG.PCW_MIO_5_SLEW {fast} \
CONFIG.PCW_MIO_6_SLEW {fast} \
CONFIG.PCW_MIO_8_SLEW {fast} \
CONFIG.PCW_MIO_9_PULLUP {<Select>} \
CONFIG.PCW_PRESET_BANK1_VOLTAGE {LVCMOS 1.8V} \
CONFIG.PCW_QSPI_GRP_FBCLK_ENABLE {1} \
CONFIG.PCW_QSPI_GRP_SINGLE_SS_ENABLE {1} \
CONFIG.PCW_QSPI_PERIPHERAL_ENABLE {1} \
CONFIG.PCW_SD0_GRP_CD_ENABLE {1} \
CONFIG.PCW_SD0_GRP_CD_IO {MIO 47} \
CONFIG.PCW_SD0_GRP_WP_ENABLE {1} \
CONFIG.PCW_SD0_PERIPHERAL_ENABLE {1} \
CONFIG.PCW_SDIO_PERIPHERAL_FREQMHZ {50} \
CONFIG.PCW_TTC0_PERIPHERAL_ENABLE {0} \
CONFIG.PCW_UART1_PERIPHERAL_ENABLE {1} \
CONFIG.PCW_UIPARAM_DDR_BOARD_DELAY0 {0.176} \
CONFIG.PCW_UIPARAM_DDR_BOARD_DELAY1 {0.159} \
CONFIG.PCW_UIPARAM_DDR_BOARD_DELAY2 {0.162} \
CONFIG.PCW_UIPARAM_DDR_BOARD_DELAY3 {0.187} \
CONFIG.PCW_UIPARAM_DDR_DQS_TO_CLK_DELAY_0 {-0.073} \
CONFIG.PCW_UIPARAM_DDR_DQS_TO_CLK_DELAY_1 {-0.034} \
CONFIG.PCW_UIPARAM_DDR_DQS_TO_CLK_DELAY_2 {-0.03} \
CONFIG.PCW_UIPARAM_DDR_DQS_TO_CLK_DELAY_3 {-0.082} \
CONFIG.PCW_UIPARAM_DDR_FREQ_MHZ {525} \
CONFIG.PCW_UIPARAM_DDR_PARTNO {MT41K128M16 JT-125} \
CONFIG.PCW_UIPARAM_DDR_TRAIN_DATA_EYE {1} \
CONFIG.PCW_UIPARAM_DDR_TRAIN_READ_GATE {1} \
CONFIG.PCW_UIPARAM_DDR_TRAIN_WRITE_LEVEL {1} \
CONFIG.PCW_USB0_PERIPHERAL_ENABLE {1} \
CONFIG.PCW_USB0_RESET_ENABLE {0} \
CONFIG.PCW_USB0_RESET_IO {<Select>} \
CONFIG.PCW_USB1_PERIPHERAL_ENABLE {0} \
 ] $processing_system7_0

  # Create instance: processing_system7_0_axi_periph, and set properties
  set processing_system7_0_axi_periph [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_interconnect:2.1 processing_system7_0_axi_periph ]
  set_property -dict [ list \
CONFIG.NUM_MI {8} \
 ] $processing_system7_0_axi_periph

  # Create instance: rst_processing_system7_0_100M, and set properties
  set rst_processing_system7_0_100M [ create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset:5.0 rst_processing_system7_0_100M ]

  # Create instance: swsleds_gpio, and set properties
  set swsleds_gpio [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_gpio:2.0 swsleds_gpio ]
  set_property -dict [ list \
CONFIG.C_ALL_INPUTS {1} \
CONFIG.C_ALL_OUTPUTS_2 {1} \
CONFIG.C_GPIO2_WIDTH {4} \
CONFIG.C_GPIO_WIDTH {4} \
CONFIG.C_IS_DUAL {1} \
 ] $swsleds_gpio

  # Create instance: tracebuffer_sel, and set properties
  set tracebuffer_sel [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice:1.0 tracebuffer_sel ]
  set_property -dict [ list \
CONFIG.DIN_FROM {5} \
CONFIG.DIN_TO {4} \
CONFIG.DIN_WIDTH {6} \
CONFIG.DOUT_WIDTH {2} \
 ] $tracebuffer_sel

  # Create instance: xadc_wiz_0, and set properties
  set xadc_wiz_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xadc_wiz:3.2 xadc_wiz_0 ]
  set_property -dict [ list \
CONFIG.AVERAGE_ENABLE_VAUXP14_VAUXN14 {true} \
CONFIG.AVERAGE_ENABLE_VAUXP15_VAUXN15 {true} \
CONFIG.AVERAGE_ENABLE_VAUXP6_VAUXN6 {true} \
CONFIG.AVERAGE_ENABLE_VAUXP7_VAUXN7 {true} \
CONFIG.AVERAGE_ENABLE_VP_VN {true} \
CONFIG.BIPOLAR_VAUXP6_VAUXN6 {true} \
CONFIG.BIPOLAR_VAUXP7_VAUXN7 {true} \
CONFIG.CHANNEL_AVERAGING {16} \
CONFIG.CHANNEL_ENABLE_VAUXP14_VAUXN14 {true} \
CONFIG.CHANNEL_ENABLE_VAUXP15_VAUXN15 {true} \
CONFIG.CHANNEL_ENABLE_VAUXP6_VAUXN6 {true} \
CONFIG.CHANNEL_ENABLE_VAUXP7_VAUXN7 {true} \
CONFIG.CHANNEL_ENABLE_VP_VN {true} \
CONFIG.ENABLE_VCCDDRO_ALARM {false} \
CONFIG.ENABLE_VCCPAUX_ALARM {false} \
CONFIG.ENABLE_VCCPINT_ALARM {false} \
CONFIG.EXTERNAL_MUX_CHANNEL {VP_VN} \
CONFIG.OT_ALARM {false} \
CONFIG.POWER_DOWN_ADCB {true} \
CONFIG.SEQUENCER_MODE {Continuous} \
CONFIG.SINGLE_CHANNEL_SELECTION {TEMPERATURE} \
CONFIG.USER_TEMP_ALARM {false} \
CONFIG.VCCAUX_ALARM {false} \
CONFIG.VCCINT_ALARM {false} \
CONFIG.XADC_STARUP_SELECTION {channel_sequencer} \
 ] $xadc_wiz_0

  # Create instance: xlconcat_0, and set properties
  set xlconcat_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconcat:2.1 xlconcat_0 ]
  set_property -dict [ list \
CONFIG.NUM_PORTS {4} \
 ] $xlconcat_0

  # Create instance: xup_mux_data_in, and set properties
  set xup_mux_data_in [ create_bd_cell -type ip -vlnv xilinx.com:XUP:xup_4_to_1_mux_vector:1.0 xup_mux_data_in ]
  set_property -dict [ list \
CONFIG.SIZE {8} \
 ] $xup_mux_data_in

  # Create instance: xup_mux_data_out, and set properties
  set xup_mux_data_out [ create_bd_cell -type ip -vlnv xilinx.com:XUP:xup_4_to_1_mux_vector:1.0 xup_mux_data_out ]
  set_property -dict [ list \
CONFIG.SIZE {8} \
 ] $xup_mux_data_out

  # Create instance: xup_mux_tri_out, and set properties
  set xup_mux_tri_out [ create_bd_cell -type ip -vlnv xilinx.com:XUP:xup_4_to_1_mux_vector:1.0 xup_mux_tri_out ]
  set_property -dict [ list \
CONFIG.SIZE {8} \
 ] $xup_mux_tri_out

  # Create interface connections
  connect_bd_intf_net -intf_net Vaux14_1 [get_bd_intf_ports Vaux14] [get_bd_intf_pins xadc_wiz_0/Vaux14]
  connect_bd_intf_net -intf_net Vaux15_1 [get_bd_intf_ports Vaux15] [get_bd_intf_pins xadc_wiz_0/Vaux15]
  connect_bd_intf_net -intf_net Vaux6_1 [get_bd_intf_ports Vaux6] [get_bd_intf_pins xadc_wiz_0/Vaux6]
  connect_bd_intf_net -intf_net Vaux7_1 [get_bd_intf_ports Vaux7] [get_bd_intf_pins xadc_wiz_0/Vaux7]
  connect_bd_intf_net -intf_net Vp_Vn_1 [get_bd_intf_ports Vp_Vn] [get_bd_intf_pins xadc_wiz_0/Vp_Vn]
  connect_bd_intf_net -intf_net axi_bram_ctrl_1_BRAM_PORTA [get_bd_intf_pins axi_bram_ctrl_1/BRAM_PORTA] [get_bd_intf_pins mb_JB/BRAM_PORTB]
  connect_bd_intf_net -intf_net axi_bram_ctrl_2_BRAM_PORTA [get_bd_intf_pins axi_bram_ctrl_2/BRAM_PORTA] [get_bd_intf_pins mb_JC/BRAM_PORTB]
  connect_bd_intf_net -intf_net axi_bram_ctrl_3_BRAM_PORTA [get_bd_intf_pins axi_bram_ctrl_3/BRAM_PORTA] [get_bd_intf_pins mb_JD/BRAM_PORTB]
  connect_bd_intf_net -intf_net axi_bram_ctrl_4_BRAM_PORTA [get_bd_intf_pins axi_bram_ctrl_4/BRAM_PORTA] [get_bd_intf_pins mb_JE/BRAM_PORTB]
  connect_bd_intf_net -intf_net btns_gpio_GPIO [get_bd_intf_ports btns_4bits] [get_bd_intf_pins btns_gpio/GPIO]
  connect_bd_intf_net -intf_net mdm_1_MBDEBUG_1 [get_bd_intf_pins mb_JC/DEBUG] [get_bd_intf_pins mdm_1/MBDEBUG_1]
  connect_bd_intf_net -intf_net mdm_1_MBDEBUG_2 [get_bd_intf_pins mb_JD/DEBUG] [get_bd_intf_pins mdm_1/MBDEBUG_2]
  connect_bd_intf_net -intf_net mdm_1_MBDEBUG_3 [get_bd_intf_pins mb_JE/DEBUG] [get_bd_intf_pins mdm_1/MBDEBUG_3]
  connect_bd_intf_net -intf_net microblaze_0_debug [get_bd_intf_pins mb_JB/DEBUG] [get_bd_intf_pins mdm_1/MBDEBUG_0]
  connect_bd_intf_net -intf_net processing_system7_0_DDR [get_bd_intf_ports DDR] [get_bd_intf_pins processing_system7_0/DDR]
  connect_bd_intf_net -intf_net processing_system7_0_FIXED_IO [get_bd_intf_ports FIXED_IO] [get_bd_intf_pins processing_system7_0/FIXED_IO]
  connect_bd_intf_net -intf_net processing_system7_0_IIC_1 [get_bd_intf_ports IIC_1] [get_bd_intf_pins processing_system7_0/IIC_1]
  connect_bd_intf_net -intf_net processing_system7_0_M_AXI_GP0 [get_bd_intf_pins processing_system7_0/M_AXI_GP0] [get_bd_intf_pins processing_system7_0_axi_periph/S00_AXI]
  connect_bd_intf_net -intf_net processing_system7_0_axi_periph_M00_AXI [get_bd_intf_pins processing_system7_0_axi_periph/M00_AXI] [get_bd_intf_pins swsleds_gpio/S_AXI]
  connect_bd_intf_net -intf_net processing_system7_0_axi_periph_M01_AXI [get_bd_intf_pins btns_gpio/S_AXI] [get_bd_intf_pins processing_system7_0_axi_periph/M01_AXI]
  connect_bd_intf_net -intf_net processing_system7_0_axi_periph_M02_AXI [get_bd_intf_pins axi_bram_ctrl_1/S_AXI] [get_bd_intf_pins processing_system7_0_axi_periph/M02_AXI]
  connect_bd_intf_net -intf_net processing_system7_0_axi_periph_M03_AXI [get_bd_intf_pins axi_bram_ctrl_2/S_AXI] [get_bd_intf_pins processing_system7_0_axi_periph/M03_AXI]
  connect_bd_intf_net -intf_net processing_system7_0_axi_periph_M04_AXI [get_bd_intf_pins axi_bram_ctrl_3/S_AXI] [get_bd_intf_pins processing_system7_0_axi_periph/M04_AXI]
  connect_bd_intf_net -intf_net processing_system7_0_axi_periph_M05_AXI [get_bd_intf_pins axi_bram_ctrl_4/S_AXI] [get_bd_intf_pins processing_system7_0_axi_periph/M05_AXI]
  connect_bd_intf_net -intf_net processing_system7_0_axi_periph_M06_AXI [get_bd_intf_pins axi_traceBuffer_v1_0_0/s00_axi] [get_bd_intf_pins processing_system7_0_axi_periph/M06_AXI]
  connect_bd_intf_net -intf_net processing_system7_0_axi_periph_M07_AXI [get_bd_intf_pins processing_system7_0_axi_periph/M07_AXI] [get_bd_intf_pins xadc_wiz_0/s_axi_lite]
  connect_bd_intf_net -intf_net swsleds_gpio_GPIO [get_bd_intf_ports sws_4bits] [get_bd_intf_pins swsleds_gpio/GPIO]
  connect_bd_intf_net -intf_net swsleds_gpio_GPIO2 [get_bd_intf_ports leds_4bits] [get_bd_intf_pins swsleds_gpio/GPIO2]

  # Create port connections
  connect_bd_net -net PMOD_IO_Switch_IP_0_sw2pmod_data_out [get_bd_ports pmodJB_data_out] [get_bd_pins mb_JB/sw2pmod_data_out] [get_bd_pins xup_mux_data_out/a]
  connect_bd_net -net PMOD_IO_Switch_IP_0_sw2pmod_tri_out [get_bd_ports pmodJB_tri_out] [get_bd_pins mb_JB/sw2pmod_tri_out] [get_bd_pins xup_mux_tri_out/a]
  connect_bd_net -net bit8_logic_0_dout [get_bd_pins bit8_logic_0/dout] [get_bd_pins xlconcat_0/In3]
  connect_bd_net -net logic_1_dout [get_bd_pins logic_1/dout] [get_bd_pins mb_JB/ext_reset_in] [get_bd_pins mb_JC/ext_reset_in] [get_bd_pins mb_JD/ext_reset_in] [get_bd_pins mb_JE/ext_reset_in]
  connect_bd_net -net mb_1_reset_Dout [get_bd_pins mb_1_reset/Dout] [get_bd_pins mb_JB/aux_reset_in]
  connect_bd_net -net mb_2_reset_Dout [get_bd_pins mb_2_reset/Dout] [get_bd_pins mb_JC/aux_reset_in]
  connect_bd_net -net mb_3_reset1_Dout [get_bd_pins mb_4_reset/Dout] [get_bd_pins mb_JE/aux_reset_in]
  connect_bd_net -net mb_3_reset_Dout [get_bd_pins mb_3_reset/Dout] [get_bd_pins mb_JD/aux_reset_in]
  connect_bd_net -net mb_JB1_sw2pmod_data_out [get_bd_ports pmodJC_data_out] [get_bd_pins mb_JC/sw2pmod_data_out] [get_bd_pins xup_mux_data_out/b]
  connect_bd_net -net mb_JB1_sw2pmod_tri_out [get_bd_ports pmodJC_tri_out] [get_bd_pins mb_JC/sw2pmod_tri_out] [get_bd_pins xup_mux_tri_out/b]
  connect_bd_net -net mb_JD_sw2pmod_data_out [get_bd_ports pmodJD_data_out] [get_bd_pins mb_JD/sw2pmod_data_out] [get_bd_pins xup_mux_data_out/c]
  connect_bd_net -net mb_JD_sw2pmod_tri_out [get_bd_ports pmodJD_tri_out] [get_bd_pins mb_JD/sw2pmod_tri_out] [get_bd_pins xup_mux_tri_out/c]
  connect_bd_net -net mb_JE_sw2pmod_data_out [get_bd_ports pmodJE_data_out] [get_bd_pins mb_JE/sw2pmod_data_out] [get_bd_pins xup_mux_data_out/d]
  connect_bd_net -net mb_JE_sw2pmod_tri_out [get_bd_ports pmodJE_tri_out] [get_bd_pins mb_JE/sw2pmod_tri_out] [get_bd_pins xup_mux_tri_out/d]
  connect_bd_net -net mdm_1_debug_sys_rst [get_bd_pins mb_JB/mb_debug_sys_rst] [get_bd_pins mb_JC/mb_debug_sys_rst] [get_bd_pins mb_JD/mb_debug_sys_rst] [get_bd_pins mb_JE/mb_debug_sys_rst] [get_bd_pins mdm_1/Debug_SYS_Rst]
  connect_bd_net -net pmod2sw_data_in_1 [get_bd_ports pmodJB_data_in] [get_bd_pins mb_JB/pmod2sw_data_in] [get_bd_pins xup_mux_data_in/a]
  connect_bd_net -net pmod2sw_data_in_2 [get_bd_ports pmodJC_data_in] [get_bd_pins mb_JC/pmod2sw_data_in] [get_bd_pins xup_mux_data_in/b]
  connect_bd_net -net pmod2sw_data_in_3 [get_bd_ports pmodJD_data_in] [get_bd_pins mb_JD/pmod2sw_data_in] [get_bd_pins xup_mux_data_in/c]
  connect_bd_net -net pmod2sw_data_in_4 [get_bd_ports pmodJE_data_in] [get_bd_pins mb_JE/pmod2sw_data_in] [get_bd_pins xup_mux_data_in/d]
  connect_bd_net -net processing_system7_0_FCLK_CLK0 [get_bd_pins axi_bram_ctrl_1/s_axi_aclk] [get_bd_pins axi_bram_ctrl_2/s_axi_aclk] [get_bd_pins axi_bram_ctrl_3/s_axi_aclk] [get_bd_pins axi_bram_ctrl_4/s_axi_aclk] [get_bd_pins axi_traceBuffer_v1_0_0/s00_axi_aclk] [get_bd_pins btns_gpio/s_axi_aclk] [get_bd_pins mb_JB/clk] [get_bd_pins mb_JC/clk] [get_bd_pins mb_JD/clk] [get_bd_pins mb_JE/clk] [get_bd_pins processing_system7_0/FCLK_CLK0] [get_bd_pins processing_system7_0/M_AXI_GP0_ACLK] [get_bd_pins processing_system7_0_axi_periph/ACLK] [get_bd_pins processing_system7_0_axi_periph/M00_ACLK] [get_bd_pins processing_system7_0_axi_periph/M01_ACLK] [get_bd_pins processing_system7_0_axi_periph/M02_ACLK] [get_bd_pins processing_system7_0_axi_periph/M03_ACLK] [get_bd_pins processing_system7_0_axi_periph/M04_ACLK] [get_bd_pins processing_system7_0_axi_periph/M05_ACLK] [get_bd_pins processing_system7_0_axi_periph/M06_ACLK] [get_bd_pins processing_system7_0_axi_periph/M07_ACLK] [get_bd_pins processing_system7_0_axi_periph/S00_ACLK] [get_bd_pins rst_processing_system7_0_100M/slowest_sync_clk] [get_bd_pins swsleds_gpio/s_axi_aclk] [get_bd_pins xadc_wiz_0/s_axi_aclk]
  connect_bd_net -net processing_system7_0_FCLK_RESET0_N [get_bd_pins processing_system7_0/FCLK_RESET0_N] [get_bd_pins rst_processing_system7_0_100M/ext_reset_in]
  connect_bd_net -net processing_system7_0_GPIO_O [get_bd_pins mb_1_reset/Din] [get_bd_pins mb_2_reset/Din] [get_bd_pins mb_3_reset/Din] [get_bd_pins mb_4_reset/Din] [get_bd_pins processing_system7_0/GPIO_O] [get_bd_pins tracebuffer_sel/Din]
  connect_bd_net -net rst_processing_system7_0_100M_interconnect_aresetn [get_bd_pins processing_system7_0_axi_periph/ARESETN] [get_bd_pins rst_processing_system7_0_100M/interconnect_aresetn]
  connect_bd_net -net rst_processing_system7_0_100M_peripheral_aresetn [get_bd_pins axi_bram_ctrl_1/s_axi_aresetn] [get_bd_pins axi_bram_ctrl_2/s_axi_aresetn] [get_bd_pins axi_bram_ctrl_3/s_axi_aresetn] [get_bd_pins axi_bram_ctrl_4/s_axi_aresetn] [get_bd_pins axi_traceBuffer_v1_0_0/s00_axi_aresetn] [get_bd_pins btns_gpio/s_axi_aresetn] [get_bd_pins processing_system7_0_axi_periph/M00_ARESETN] [get_bd_pins processing_system7_0_axi_periph/M01_ARESETN] [get_bd_pins processing_system7_0_axi_periph/M02_ARESETN] [get_bd_pins processing_system7_0_axi_periph/M03_ARESETN] [get_bd_pins processing_system7_0_axi_periph/M04_ARESETN] [get_bd_pins processing_system7_0_axi_periph/M05_ARESETN] [get_bd_pins processing_system7_0_axi_periph/M06_ARESETN] [get_bd_pins processing_system7_0_axi_periph/M07_ARESETN] [get_bd_pins processing_system7_0_axi_periph/S00_ARESETN] [get_bd_pins rst_processing_system7_0_100M/peripheral_aresetn] [get_bd_pins swsleds_gpio/s_axi_aresetn] [get_bd_pins xadc_wiz_0/s_axi_aresetn]
  connect_bd_net -net tracebuffer_sel_Dout [get_bd_pins tracebuffer_sel/Dout] [get_bd_pins xup_mux_data_in/sel] [get_bd_pins xup_mux_data_out/sel] [get_bd_pins xup_mux_tri_out/sel]
  connect_bd_net -net xlconcat_0_dout [get_bd_pins axi_traceBuffer_v1_0_0/MONITOR_DATAIN] [get_bd_pins xlconcat_0/dout]
  connect_bd_net -net xup_mux_data_in_y [get_bd_pins xlconcat_0/In2] [get_bd_pins xup_mux_data_in/y]
  connect_bd_net -net xup_mux_data_out_y [get_bd_pins xlconcat_0/In0] [get_bd_pins xup_mux_data_out/y]
  connect_bd_net -net xup_mux_tri_out_y [get_bd_pins xlconcat_0/In1] [get_bd_pins xup_mux_tri_out/y]

  # Create address segments
  create_bd_addr_seg -range 0x8000 -offset 0x40000000 [get_bd_addr_spaces processing_system7_0/Data] [get_bd_addr_segs axi_bram_ctrl_1/S_AXI/Mem0] SEG_axi_bram_ctrl_1_Mem0
  create_bd_addr_seg -range 0x8000 -offset 0x42000000 [get_bd_addr_spaces processing_system7_0/Data] [get_bd_addr_segs axi_bram_ctrl_2/S_AXI/Mem0] SEG_axi_bram_ctrl_2_Mem0
  create_bd_addr_seg -range 0x8000 -offset 0x44000000 [get_bd_addr_spaces processing_system7_0/Data] [get_bd_addr_segs axi_bram_ctrl_3/S_AXI/Mem0] SEG_axi_bram_ctrl_3_Mem0
  create_bd_addr_seg -range 0x8000 -offset 0x46000000 [get_bd_addr_spaces processing_system7_0/Data] [get_bd_addr_segs axi_bram_ctrl_4/S_AXI/Mem0] SEG_axi_bram_ctrl_4_Mem0
  create_bd_addr_seg -range 0x10000 -offset 0x43C00000 [get_bd_addr_spaces processing_system7_0/Data] [get_bd_addr_segs axi_traceBuffer_v1_0_0/s00_axi/reg0] SEG_axi_traceBuffer_v1_0_0_reg0
  create_bd_addr_seg -range 0x10000 -offset 0x41210000 [get_bd_addr_spaces processing_system7_0/Data] [get_bd_addr_segs btns_gpio/S_AXI/Reg] SEG_btns_gpio_Reg
  create_bd_addr_seg -range 0x10000 -offset 0x41200000 [get_bd_addr_spaces processing_system7_0/Data] [get_bd_addr_segs swsleds_gpio/S_AXI/Reg] SEG_swsleds_gpio_Reg
  create_bd_addr_seg -range 0x10000 -offset 0x43C10000 [get_bd_addr_spaces processing_system7_0/Data] [get_bd_addr_segs xadc_wiz_0/s_axi_lite/Reg] SEG_xadc_wiz_0_Reg
  create_bd_addr_seg -range 0x10000 -offset 0x44A00000 [get_bd_addr_spaces mb_JB/mb_1/Data] [get_bd_addr_segs mb_JB/mb1_PMOD_IO_Switch_IP/S00_AXI/S00_AXI_reg] SEG_PMOD_IO_Switch_IP_0_S00_AXI_reg
  create_bd_addr_seg -range 0x10000 -offset 0x40000000 [get_bd_addr_spaces mb_JB/mb_1/Data] [get_bd_addr_segs mb_JB/mb1_gpio/S_AXI/Reg] SEG_axi_gpio_0_Reg
  create_bd_addr_seg -range 0x10000 -offset 0x40800000 [get_bd_addr_spaces mb_JB/mb_1/Data] [get_bd_addr_segs mb_JB/mb1_iic/S_AXI/Reg] SEG_axi_iic_0_Reg
  create_bd_addr_seg -range 0x10000 -offset 0x44A10000 [get_bd_addr_spaces mb_JB/mb_1/Data] [get_bd_addr_segs mb_JB/mb1_spi/AXI_LITE/Reg] SEG_axi_quad_spi_0_Reg
  create_bd_addr_seg -range 0x8000 -offset 0x0 [get_bd_addr_spaces mb_JB/mb_1/Instruction] [get_bd_addr_segs mb_JB/mb1_lmb/lmb_bram_if_cntlr/SLMB/Mem] SEG_ilmb_bram_if_cntlr_Mem
  create_bd_addr_seg -range 0x8000 -offset 0x0 [get_bd_addr_spaces mb_JB/mb_1/Data] [get_bd_addr_segs mb_JB/mb1_lmb/lmb_bram_if_cntlr/SLMB1/Mem] SEG_lmb_bram_if_cntlr_Mem
  create_bd_addr_seg -range 0x8000 -offset 0x0 [get_bd_addr_spaces mb_JC/mb_2/Data] [get_bd_addr_segs mb_JC/mb2_lmb/lmb_bram_if_cntlr/SLMB1/Mem] SEG_lmb_bram_if_cntlr_Mem
  create_bd_addr_seg -range 0x8000 -offset 0x0 [get_bd_addr_spaces mb_JC/mb_2/Instruction] [get_bd_addr_segs mb_JC/mb2_lmb/lmb_bram_if_cntlr/SLMB/Mem] SEG_lmb_bram_if_cntlr_Mem
  create_bd_addr_seg -range 0x10000 -offset 0x44A00000 [get_bd_addr_spaces mb_JC/mb_2/Data] [get_bd_addr_segs mb_JC/mb2_PMOD_IO_Switch_IP/S00_AXI/S00_AXI_reg] SEG_mb2_PMOD_IO_Switch_IP_S00_AXI_reg
  create_bd_addr_seg -range 0x10000 -offset 0x40000000 [get_bd_addr_spaces mb_JC/mb_2/Data] [get_bd_addr_segs mb_JC/mb2_gpio/S_AXI/Reg] SEG_mb2_gpio_Reg
  create_bd_addr_seg -range 0x10000 -offset 0x40800000 [get_bd_addr_spaces mb_JC/mb_2/Data] [get_bd_addr_segs mb_JC/mb2_iic/S_AXI/Reg] SEG_mb2_iic_Reg
  create_bd_addr_seg -range 0x10000 -offset 0x44A10000 [get_bd_addr_spaces mb_JC/mb_2/Data] [get_bd_addr_segs mb_JC/mb2_spi/AXI_LITE/Reg] SEG_mb2_spi_Reg
  create_bd_addr_seg -range 0x8000 -offset 0x0 [get_bd_addr_spaces mb_JD/mb_3/Data] [get_bd_addr_segs mb_JD/mb3_lmb/lmb_bram_if_cntlr/SLMB1/Mem] SEG_lmb_bram_if_cntlr_Mem
  create_bd_addr_seg -range 0x8000 -offset 0x0 [get_bd_addr_spaces mb_JD/mb_3/Instruction] [get_bd_addr_segs mb_JD/mb3_lmb/lmb_bram_if_cntlr/SLMB/Mem] SEG_lmb_bram_if_cntlr_Mem
  create_bd_addr_seg -range 0x10000 -offset 0x44A00000 [get_bd_addr_spaces mb_JD/mb_3/Data] [get_bd_addr_segs mb_JD/mb3_PMOD_IO_Switch_IP/S00_AXI/S00_AXI_reg] SEG_mb2_PMOD_IO_Switch_IP_S00_AXI_reg
  create_bd_addr_seg -range 0x10000 -offset 0x40000000 [get_bd_addr_spaces mb_JD/mb_3/Data] [get_bd_addr_segs mb_JD/mb3_gpio/S_AXI/Reg] SEG_mb2_gpio_Reg
  create_bd_addr_seg -range 0x10000 -offset 0x40800000 [get_bd_addr_spaces mb_JD/mb_3/Data] [get_bd_addr_segs mb_JD/mb3_iic/S_AXI/Reg] SEG_mb2_iic_Reg
  create_bd_addr_seg -range 0x10000 -offset 0x44A10000 [get_bd_addr_spaces mb_JD/mb_3/Data] [get_bd_addr_segs mb_JD/mb3_spi/AXI_LITE/Reg] SEG_mb2_spi_Reg
  create_bd_addr_seg -range 0x8000 -offset 0x0 [get_bd_addr_spaces mb_JE/mb_4/Data] [get_bd_addr_segs mb_JE/mb4_lmb/lmb_bram_if_cntlr/SLMB1/Mem] SEG_lmb_bram_if_cntlr_Mem
  create_bd_addr_seg -range 0x8000 -offset 0x0 [get_bd_addr_spaces mb_JE/mb_4/Instruction] [get_bd_addr_segs mb_JE/mb4_lmb/lmb_bram_if_cntlr/SLMB/Mem] SEG_lmb_bram_if_cntlr_Mem
  create_bd_addr_seg -range 0x10000 -offset 0x44A00000 [get_bd_addr_spaces mb_JE/mb_4/Data] [get_bd_addr_segs mb_JE/mb4_PMOD_IO_Switch_IP/S00_AXI/S00_AXI_reg] SEG_mb3_PMOD_IO_Switch_IP_S00_AXI_reg
  create_bd_addr_seg -range 0x10000 -offset 0x40000000 [get_bd_addr_spaces mb_JE/mb_4/Data] [get_bd_addr_segs mb_JE/mb4_gpio/S_AXI/Reg] SEG_mb3_gpio_Reg
  create_bd_addr_seg -range 0x10000 -offset 0x40800000 [get_bd_addr_spaces mb_JE/mb_4/Data] [get_bd_addr_segs mb_JE/mb4_iic/S_AXI/Reg] SEG_mb3_iic_Reg
  create_bd_addr_seg -range 0x10000 -offset 0x44A10000 [get_bd_addr_spaces mb_JE/mb_4/Data] [get_bd_addr_segs mb_JE/mb4_spi/AXI_LITE/Reg] SEG_mb3_spi_Reg

  # Perform GUI Layout
  regenerate_bd_layout -layout_string {
   guistr: "# # String gsaved with Nlview 6.5.5  2015-06-26 bk=1.3371 VDI=38 GEI=35 GUI=JA:1.8
#  -string -flagsOSRD
preplace port btns_4bits -pg 1 -y 490 -defaultsOSRD
preplace port DDR -pg 1 -y 60 -defaultsOSRD
preplace port Vp_Vn -pg 1 -y 810 -defaultsOSRD
preplace port sws_4bits -pg 1 -y 600 -defaultsOSRD
preplace port leds_4bits -pg 1 -y 620 -defaultsOSRD
preplace port FIXED_IO -pg 1 -y 120 -defaultsOSRD
preplace port IIC_1 -pg 1 -y 100 -defaultsOSRD
preplace port Vaux6 -pg 1 -y 250 -defaultsOSRD
preplace port Vaux14 -pg 1 -y 770 -defaultsOSRD
preplace port Vaux7 -pg 1 -y 270 -defaultsOSRD
preplace port Vaux15 -pg 1 -y 790 -defaultsOSRD
preplace portBus pmodJE_data_in -pg 1 -y 1440 -defaultsOSRD
preplace portBus pmodJB_tri_out -pg 1 -y 1110 -defaultsOSRD
preplace portBus pmodJE_data_out -pg 1 -y 1360 -defaultsOSRD
preplace portBus pmodJD_data_in -pg 1 -y 1420 -defaultsOSRD
preplace portBus pmodJB_data_out -pg 1 -y 1090 -defaultsOSRD
preplace portBus pmodJB_data_in -pg 1 -y 1320 -defaultsOSRD
preplace portBus pmodJC_data_out -pg 1 -y 850 -defaultsOSRD
preplace portBus pmodJE_tri_out -pg 1 -y 1380 -defaultsOSRD
preplace portBus pmodJD_data_out -pg 1 -y 1130 -defaultsOSRD
preplace portBus pmodJC_tri_out -pg 1 -y 980 -defaultsOSRD
preplace portBus pmodJC_data_in -pg 1 -y 1360 -defaultsOSRD
preplace portBus pmodJD_tri_out -pg 1 -y 1340 -defaultsOSRD
preplace inst xup_mux_data_in -pg 1 -lvl 2 -y 1450 -defaultsOSRD -resize 220 140
preplace inst mb_4_reset -pg 1 -lvl 5 -y 1710 -defaultsOSRD -resize 140 60
preplace inst mb_2_reset -pg 1 -lvl 5 -y 1060 -defaultsOSRD -resize 140 60
preplace inst axi_bram_ctrl_2 -pg 1 -lvl 5 -y 660 -defaultsOSRD
preplace inst axi_bram_ctrl_3 -pg 1 -lvl 5 -y 800 -defaultsOSRD
preplace inst rst_processing_system7_0_100M -pg 1 -lvl 2 -y 360 -defaultsOSRD
preplace inst mb_3_reset -pg 1 -lvl 5 -y 1590 -defaultsOSRD -resize 140 60
preplace inst axi_bram_ctrl_4 -pg 1 -lvl 5 -y 940 -defaultsOSRD
preplace inst xadc_wiz_0 -pg 1 -lvl 4 -y 340 -defaultsOSRD
preplace inst swsleds_gpio -pg 1 -lvl 6 -y 610 -defaultsOSRD
preplace inst mb_1_reset -pg 1 -lvl 5 -y 1280 -defaultsOSRD
preplace inst bit8_logic_0 -pg 1 -lvl 2 -y 870 -defaultsOSRD
preplace inst xup_mux_tri_out -pg 1 -lvl 2 -y 1220 -defaultsOSRD -resize 220 140
preplace inst mb_JB -pg 1 -lvl 6 -y 1230 -defaultsOSRD
preplace inst xlconcat_0 -pg 1 -lvl 3 -y 900 -defaultsOSRD
preplace inst mb_JC -pg 1 -lvl 6 -y 970 -defaultsOSRD -resize 300 196
preplace inst logic_1 -pg 1 -lvl 5 -y 1140 -defaultsOSRD
preplace inst mb_JD -pg 1 -lvl 6 -y 1480 -defaultsOSRD -resize 300 196
preplace inst mdm_1 -pg 1 -lvl 5 -y 1450 -defaultsOSRD
preplace inst mb_JE -pg 1 -lvl 6 -y 1690 -defaultsOSRD -resize 300 196
preplace inst xup_mux_data_out -pg 1 -lvl 2 -y 1030 -defaultsOSRD
preplace inst btns_gpio -pg 1 -lvl 6 -y 490 -defaultsOSRD
preplace inst tracebuffer_sel -pg 1 -lvl 1 -y 1490 -defaultsOSRD
preplace inst processing_system7_0_axi_periph -pg 1 -lvl 3 -y 520 -defaultsOSRD
preplace inst processing_system7_0 -pg 1 -lvl 2 -y 110 -defaultsOSRD
preplace inst axi_traceBuffer_v1_0_0 -pg 1 -lvl 4 -y 590 -defaultsOSRD
preplace inst axi_bram_ctrl_1 -pg 1 -lvl 5 -y 540 -defaultsOSRD
preplace netloc btns_gpio_GPIO 1 6 1 NJ
preplace netloc Vaux6_1 1 0 4 NJ 250 NJ 250 NJ 240 NJ
preplace netloc processing_system7_0_DDR 1 2 5 NJ 60 NJ 60 NJ 60 NJ 60 NJ
preplace netloc xup_mux_tri_out_y 1 2 1 720
preplace netloc pmod2sw_data_in_3 1 0 6 NJ 1420 210 1540 NJ 1540 NJ 1540 NJ 1540 NJ
preplace netloc pmod2sw_data_in_4 1 0 6 NJ 1440 200 1550 NJ 1550 NJ 1550 NJ 1760 NJ
preplace netloc mb_JD_sw2pmod_data_out 1 1 6 280 1120 NJ 1120 NJ 1120 NJ 1200 NJ 1100 2300
preplace netloc processing_system7_0_axi_periph_M03_AXI 1 3 2 NJ 500 1520
preplace netloc processing_system7_0_axi_periph_M00_AXI 1 3 3 NJ 460 NJ 460 1920
preplace netloc xup_mux_data_out_y 1 2 1 710
preplace netloc processing_system7_0_GPIO_O 1 0 5 20 920 NJ 920 700 990 NJ 990 1520
preplace netloc Vaux7_1 1 0 4 NJ 270 NJ 270 NJ 230 NJ
preplace netloc processing_system7_0_axi_periph_M07_AXI 1 3 1 1150
preplace netloc processing_system7_0_M_AXI_GP0 1 2 1 740
preplace netloc mdm_1_MBDEBUG_1 1 5 1 1810
preplace netloc Vp_Vn_1 1 0 4 NJ 810 NJ 810 NJ 810 NJ
preplace netloc processing_system7_0_axi_periph_M05_AXI 1 3 2 1170 510 NJ
preplace netloc mdm_1_MBDEBUG_2 1 5 1 1940
preplace netloc processing_system7_0_FCLK_RESET0_N 1 1 2 250 260 660
preplace netloc mb_1_reset_Dout 1 5 1 NJ
preplace netloc PMOD_IO_Switch_IP_0_sw2pmod_data_out 1 1 6 250 940 NJ 980 NJ 980 NJ 1010 NJ 1090 2330
preplace netloc mdm_1_MBDEBUG_3 1 5 1 1810
preplace netloc axi_bram_ctrl_2_BRAM_PORTA 1 5 1 1920
preplace netloc processing_system7_0_IIC_1 1 2 5 NJ 100 NJ 100 NJ 100 NJ 100 NJ
preplace netloc swsleds_gpio_GPIO2 1 6 1 NJ
preplace netloc processing_system7_0_axi_periph_M02_AXI 1 3 2 NJ 490 1540
preplace netloc rst_processing_system7_0_100M_peripheral_aresetn 1 2 4 750 220 1200 480 1510 440 1930
preplace netloc mb_JB1_sw2pmod_tri_out 1 1 6 270 1310 NJ 1220 NJ 1220 NJ 1220 NJ 1080 2300
preplace netloc processing_system7_0_axi_periph_M06_AXI 1 3 1 1230
preplace netloc xup_mux_data_in_y 1 2 1 740
preplace netloc xlconcat_0_dout 1 3 1 1230
preplace netloc mb_JE_sw2pmod_tri_out 1 1 6 260 1360 NJ 1360 NJ 1360 NJ 1360 NJ 1360 2310
preplace netloc mb_2_reset_Dout 1 5 1 NJ
preplace netloc swsleds_gpio_GPIO 1 6 1 NJ
preplace netloc Vaux14_1 1 0 4 NJ 770 NJ 770 NJ 260 NJ
preplace netloc processing_system7_0_FIXED_IO 1 2 5 NJ 80 NJ 80 NJ 80 NJ 80 NJ
preplace netloc axi_bram_ctrl_3_BRAM_PORTA 1 5 1 1880
preplace netloc mb_JE_sw2pmod_data_out 1 1 6 250 1350 NJ 1350 NJ 1350 NJ 1350 NJ 1350 2320
preplace netloc logic_1_dout 1 5 1 1920
preplace netloc axi_bram_ctrl_4_BRAM_PORTA 1 5 1 1860
preplace netloc mb_JB1_sw2pmod_data_out 1 1 6 220 820 NJ 820 NJ 820 NJ 870 NJ 850 2300
preplace netloc rst_processing_system7_0_100M_interconnect_aresetn 1 2 1 690
preplace netloc processing_system7_0_FCLK_CLK0 1 1 5 220 450 720 210 1210 670 1530 450 1890
preplace netloc mb_3_reset_Dout 1 5 1 NJ
preplace netloc PMOD_IO_Switch_IP_0_sw2pmod_tri_out 1 1 6 280 1130 NJ 1130 NJ 1130 NJ 1190 NJ 1110 2310
preplace netloc microblaze_0_debug 1 5 1 1910
preplace netloc axi_bram_ctrl_1_BRAM_PORTA 1 5 1 1910
preplace netloc pmod2sw_data_in_1 1 0 6 NJ 1320 230 1330 NJ 1330 NJ 1330 NJ 1330 NJ
preplace netloc mdm_1_debug_sys_rst 1 5 1 1930
preplace netloc mb_JD_sw2pmod_tri_out 1 1 6 280 1340 NJ 1340 NJ 1340 NJ 1340 NJ 1340 2330
preplace netloc mb_3_reset1_Dout 1 5 1 NJ
preplace netloc bit8_logic_0_dout 1 2 1 NJ
preplace netloc Vaux15_1 1 0 4 NJ 790 NJ 790 NJ 790 NJ
preplace netloc processing_system7_0_axi_periph_M04_AXI 1 3 2 NJ 780 N
preplace netloc processing_system7_0_axi_periph_M01_AXI 1 3 3 NJ 470 NJ 470 N
preplace netloc tracebuffer_sel_Dout 1 1 1 220
preplace netloc pmod2sw_data_in_2 1 0 6 NJ 1360 240 1320 NJ 1230 NJ 1230 NJ 1230 1820
levelinfo -pg 1 0 110 470 990 1360 1670 2120 2350 -top -20 -bot 1800
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
make_wrapper -files [get_files ./zybo/project_1.srcs/sources_1/bd/system/system.bd] -top

# generate toplevel wrapper files
add_files -norecurse ./zybo/project_1.srcs/sources_1/bd/system/hdl/system_wrapper.v
update_compile_order -fileset sources_1
update_compile_order -fileset sim_1
add_files -fileset constrs_1 -norecurse ./src/constraints/top.xdc

# replace top wrapper with custom top.v
add_files -norecurse ./src/top.v
update_compile_order -fileset sources_1
set_property top top [current_fileset]
update_compile_order -fileset sources_1


# Can try this call but need way to know if still running/completed/hung/failed
launch_runs impl_1 -to_step write_bitstream -jobs 4
wait_on_run impl_1

#synth_design -top top -part xc7z020clg484-1
#synth_design
#opt_design
#power_opt_design
#place_design
#phys_opt_design
#route_design
#write_bitstream 

