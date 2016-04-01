
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
#    set_property BOARD_PART digilentinc.com:zybo:part0:1.0 [current_project]

# CHECKING IF PROJECT EXISTS
if { [get_projects -quiet] eq "" } {
   create_project project_1 zybo_mipy -part xc7z010clg400-1
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


# Hierarchical cell: mb2_local_memory
proc create_hier_cell_mb2_local_memory { parentCell nameHier } {

  if { $parentCell eq "" || $nameHier eq "" } {
     puts "ERROR: create_hier_cell_mb2_local_memory() - Empty argument(s)!"
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

# Hierarchical cell: mb1_local_memory
proc create_hier_cell_mb1_local_memory { parentCell nameHier } {

  if { $parentCell eq "" || $nameHier eq "" } {
     puts "ERROR: create_hier_cell_mb1_local_memory() - Empty argument(s)!"
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

# Hierarchical cell: video
proc create_hier_cell_video { parentCell nameHier } {

  if { $parentCell eq "" || $nameHier eq "" } {
     puts "ERROR: create_hier_cell_video() - Empty argument(s)!"
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
  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:iic_rtl:1.0 DDC
  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:gpio_rtl:1.0 GPIO
  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 M00_AXI
  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S_AXI
  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S_AXI_LITE
  create_bd_intf_pin -mode Slave -vlnv digilentinc.com:interface:tmds_rtl:1.0 TMDS
  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 ctrl
  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 ctrl1
  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 s00_axi

  # Create pins
  create_bd_pin -dir I -from 0 -to 0 -type rst ARESETN
  create_bd_pin -dir I -type clk REF_CLK_I
  create_bd_pin -dir I -type clk RefClk
  create_bd_pin -dir I -from 0 -to 0 -type rst S01_ARESETN
  create_bd_pin -dir I -from 0 -to 0 -type rst aRst_n
  create_bd_pin -dir O -from 4 -to 0 dout
  create_bd_pin -dir O -from 0 -to 0 dout1
  create_bd_pin -dir I -type clk m_axi_s2mm_aclk
  create_bd_pin -dir O -from 4 -to 0 vga_pBlue
  create_bd_pin -dir O -from 5 -to 0 vga_pGreen
  create_bd_pin -dir O vga_pHSync
  create_bd_pin -dir O -from 4 -to 0 vga_pRed
  create_bd_pin -dir O vga_pVSync

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
CONFIG.c_num_fstores {3} \
CONFIG.c_s2mm_genlock_mode {0} \
CONFIG.c_s2mm_linebuffer_depth {4096} \
CONFIG.c_s2mm_max_burst_length {32} \
CONFIG.c_use_s2mm_fsync {2} \
 ] $axi_vdma_0

  # Create instance: dvi2rgb_0, and set properties
  set dvi2rgb_0 [ create_bd_cell -type ip -vlnv digilentinc.com:ip:dvi2rgb:1.4 dvi2rgb_0 ]
  set_property -dict [ list \
CONFIG.kClkRange {2} \
CONFIG.kRstActiveHigh {false} \
 ] $dvi2rgb_0

  # Create instance: rgb2vga_0, and set properties
  set rgb2vga_0 [ create_bd_cell -type ip -vlnv digilentinc.com:ip:rgb2vga:1.0 rgb2vga_0 ]
  set_property -dict [ list \
CONFIG.VID_IN_DATA_WIDTH {24} \
 ] $rgb2vga_0

  # Create instance: v_axi4s_vid_out_0, and set properties
  set v_axi4s_vid_out_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:v_axi4s_vid_out:4.0 v_axi4s_vid_out_0 ]
  set_property -dict [ list \
CONFIG.C_S_AXIS_VIDEO_DATA_WIDTH {8} \
CONFIG.C_S_AXIS_VIDEO_FORMAT {2} \
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
CONFIG.VIDEO_MODE {1280x1024p} \
CONFIG.enable_generation {false} \
CONFIG.horizontal_blank_detection {false} \
CONFIG.max_lines_per_frame {2048} \
CONFIG.vertical_blank_detection {false} \
 ] $v_tc_1

  # Create instance: v_vid_in_axi4s_0, and set properties
  set v_vid_in_axi4s_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:v_vid_in_axi4s:4.0 v_vid_in_axi4s_0 ]

  # Create instance: xlconcat_0, and set properties
  set xlconcat_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconcat:2.1 xlconcat_0 ]
  set_property -dict [ list \
CONFIG.NUM_PORTS {5} \
 ] $xlconcat_0

  # Create instance: xlconstant_0, and set properties
  set xlconstant_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant:1.1 xlconstant_0 ]
  set_property -dict [ list \
CONFIG.CONST_VAL {0} \
 ] $xlconstant_0

  # Create instance: xlslice_0, and set properties
  set xlslice_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice:1.0 xlslice_0 ]
  set_property -dict [ list \
CONFIG.DIN_FROM {8} \
CONFIG.DIN_TO {8} \
 ] $xlslice_0

  # Create interface connections
  connect_bd_intf_net -intf_net Conn1 [get_bd_intf_pins TMDS] [get_bd_intf_pins dvi2rgb_0/TMDS]
  connect_bd_intf_net -intf_net axi_gpio_0_GPIO2 [get_bd_intf_pins GPIO] [get_bd_intf_pins axi_gpio_video/GPIO]
  connect_bd_intf_net -intf_net axi_mem_intercon_M00_AXI [get_bd_intf_pins M00_AXI] [get_bd_intf_pins axi_mem_intercon/M00_AXI]
  connect_bd_intf_net -intf_net axi_vdma_0_M_AXIS_MM2S [get_bd_intf_pins axi_vdma_0/M_AXIS_MM2S] [get_bd_intf_pins v_axi4s_vid_out_0/video_in]
  connect_bd_intf_net -intf_net axi_vdma_0_M_AXI_MM2S [get_bd_intf_pins axi_mem_intercon/S01_AXI] [get_bd_intf_pins axi_vdma_0/M_AXI_MM2S]
  connect_bd_intf_net -intf_net axi_vdma_0_M_AXI_S2MM [get_bd_intf_pins axi_mem_intercon/S00_AXI] [get_bd_intf_pins axi_vdma_0/M_AXI_S2MM]
  connect_bd_intf_net -intf_net dvi2rgb_0_DDC [get_bd_intf_pins DDC] [get_bd_intf_pins dvi2rgb_0/DDC]
  connect_bd_intf_net -intf_net dvi2rgb_0_RGB [get_bd_intf_pins dvi2rgb_0/RGB] [get_bd_intf_pins v_vid_in_axi4s_0/vid_io_in]
  connect_bd_intf_net -intf_net processing_system7_0_axi_periph_M03_AXI [get_bd_intf_pins ctrl1] [get_bd_intf_pins v_tc_0/ctrl]
  connect_bd_intf_net -intf_net processing_system7_0_axi_periph_M04_AXI [get_bd_intf_pins s00_axi] [get_bd_intf_pins axi_dynclk_0/s00_axi]
  connect_bd_intf_net -intf_net processing_system7_0_axi_periph_M05_AXI [get_bd_intf_pins S_AXI_LITE] [get_bd_intf_pins axi_vdma_0/S_AXI_LITE]
  connect_bd_intf_net -intf_net processing_system7_0_axi_periph_M06_AXI [get_bd_intf_pins ctrl] [get_bd_intf_pins v_tc_1/ctrl]
  connect_bd_intf_net -intf_net processing_system7_0_axi_periph_M07_AXI [get_bd_intf_pins S_AXI] [get_bd_intf_pins axi_gpio_video/S_AXI]
  connect_bd_intf_net -intf_net v_axi4s_vid_out_0_vid_io_out [get_bd_intf_pins rgb2vga_0/vid_in] [get_bd_intf_pins v_axi4s_vid_out_0/vid_io_out]
  connect_bd_intf_net -intf_net v_tc_0_vtiming_out [get_bd_intf_pins v_axi4s_vid_out_0/vtiming_in] [get_bd_intf_pins v_tc_0/vtiming_out]
  connect_bd_intf_net -intf_net v_vid_in_axi4s_0_video_out [get_bd_intf_pins axi_vdma_0/S_AXIS_S2MM] [get_bd_intf_pins v_vid_in_axi4s_0/video_out]
  connect_bd_intf_net -intf_net v_vid_in_axi4s_0_vtiming_out [get_bd_intf_pins v_tc_1/vtiming_in] [get_bd_intf_pins v_vid_in_axi4s_0/vtiming_out]

  # Create port connections
  connect_bd_net -net axi_dynclk_0_PXL_CLK_O [get_bd_pins axi_dynclk_0/PXL_CLK_O] [get_bd_pins axi_vdma_0/m_axis_mm2s_aclk] [get_bd_pins rgb2vga_0/PixelClk] [get_bd_pins v_axi4s_vid_out_0/aclk] [get_bd_pins v_axi4s_vid_out_0/vid_io_out_clk] [get_bd_pins v_tc_0/clk]
  connect_bd_net -net axi_gpio_video_ip2intc_irpt [get_bd_pins axi_gpio_video/ip2intc_irpt] [get_bd_pins xlconcat_0/In4]
  connect_bd_net -net axi_vdma_0_mm2s_introut [get_bd_pins axi_vdma_0/mm2s_introut] [get_bd_pins xlconcat_0/In1]
  connect_bd_net -net axi_vdma_0_s2mm_introut [get_bd_pins axi_vdma_0/s2mm_introut] [get_bd_pins xlconcat_0/In0]
  connect_bd_net -net dvi2rgb_0_PixelClk [get_bd_pins dvi2rgb_0/PixelClk] [get_bd_pins v_tc_1/clk] [get_bd_pins v_vid_in_axi4s_0/vid_io_in_clk]
  connect_bd_net -net dvi2rgb_0_aPixelClkLckd [get_bd_pins axi_gpio_video/gpio2_io_i] [get_bd_pins dvi2rgb_0/aPixelClkLckd] [get_bd_pins v_tc_1/clken]
  connect_bd_net -net processing_system7_0_FCLK_CLK0 [get_bd_pins REF_CLK_I] [get_bd_pins axi_dynclk_0/REF_CLK_I] [get_bd_pins axi_dynclk_0/s00_axi_aclk] [get_bd_pins axi_gpio_video/s_axi_aclk] [get_bd_pins axi_vdma_0/s_axi_lite_aclk] [get_bd_pins v_tc_0/s_axi_aclk] [get_bd_pins v_tc_1/s_axi_aclk]
  connect_bd_net -net processing_system7_0_FCLK_CLK1 [get_bd_pins m_axi_s2mm_aclk] [get_bd_pins axi_mem_intercon/ACLK] [get_bd_pins axi_mem_intercon/M00_ACLK] [get_bd_pins axi_mem_intercon/S00_ACLK] [get_bd_pins axi_mem_intercon/S01_ACLK] [get_bd_pins axi_vdma_0/m_axi_mm2s_aclk] [get_bd_pins axi_vdma_0/m_axi_s2mm_aclk] [get_bd_pins axi_vdma_0/s_axis_s2mm_aclk] [get_bd_pins v_vid_in_axi4s_0/aclk]
  connect_bd_net -net processing_system7_0_FCLK_CLK2 [get_bd_pins RefClk] [get_bd_pins dvi2rgb_0/RefClk]
  connect_bd_net -net rgb2vga_0_vga_pBlue [get_bd_pins vga_pBlue] [get_bd_pins rgb2vga_0/vga_pBlue]
  connect_bd_net -net rgb2vga_0_vga_pGreen [get_bd_pins vga_pGreen] [get_bd_pins rgb2vga_0/vga_pGreen]
  connect_bd_net -net rgb2vga_0_vga_pHSync [get_bd_pins vga_pHSync] [get_bd_pins rgb2vga_0/vga_pHSync]
  connect_bd_net -net rgb2vga_0_vga_pRed [get_bd_pins vga_pRed] [get_bd_pins rgb2vga_0/vga_pRed]
  connect_bd_net -net rgb2vga_0_vga_pVSync [get_bd_pins vga_pVSync] [get_bd_pins rgb2vga_0/vga_pVSync]
  connect_bd_net -net rst_processing_system7_0_100M_peripheral_aresetn [get_bd_pins aRst_n] [get_bd_pins axi_dynclk_0/s00_axi_aresetn] [get_bd_pins axi_gpio_video/s_axi_aresetn] [get_bd_pins axi_vdma_0/axi_resetn] [get_bd_pins dvi2rgb_0/aRst_n] [get_bd_pins v_tc_0/s_axi_aresetn] [get_bd_pins v_tc_1/s_axi_aresetn]
  connect_bd_net -net rst_processing_system7_0_150M_interconnect_aresetn [get_bd_pins ARESETN] [get_bd_pins axi_mem_intercon/ARESETN]
  connect_bd_net -net rst_processing_system7_0_150M_peripheral_aresetn [get_bd_pins S01_ARESETN] [get_bd_pins axi_mem_intercon/M00_ARESETN] [get_bd_pins axi_mem_intercon/S00_ARESETN] [get_bd_pins axi_mem_intercon/S01_ARESETN]
  connect_bd_net -net v_tc_0_irq [get_bd_pins v_tc_0/irq] [get_bd_pins xlconcat_0/In2]
  connect_bd_net -net v_tc_1_intc_if [get_bd_pins v_tc_1/intc_if] [get_bd_pins xlslice_0/Din]
  connect_bd_net -net v_tc_1_irq [get_bd_pins v_tc_1/irq] [get_bd_pins xlconcat_0/In3]
  connect_bd_net -net xlconcat_0_dout [get_bd_pins dout] [get_bd_pins xlconcat_0/dout]
  connect_bd_net -net xlconstant_0_dout [get_bd_pins dout1] [get_bd_pins xlconstant_0/dout]
  connect_bd_net -net xlslice_0_Dout [get_bd_pins v_vid_in_axi4s_0/axis_enable] [get_bd_pins xlslice_0/Dout]

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
  create_bd_pin -dir I -type clk Clk
  create_bd_pin -dir I -from 0 -to 0 -type rst aux_reset_in
  create_bd_pin -dir I -from 0 -to 0 -type rst ext_reset_in
  create_bd_pin -dir I -type rst mb_debug_sys_rst
  create_bd_pin -dir I -from 7 -to 0 pmodJC_data_in
  create_bd_pin -dir O -from 7 -to 0 pmodJC_data_out
  create_bd_pin -dir O -from 7 -to 0 pmodJC_tri_out

  # Create instance: mb2_PMOD_IO_Switch_IP, and set properties
  set mb2_PMOD_IO_Switch_IP [ create_bd_cell -type ip -vlnv xilinx.com:user:PMOD_IO_Switch_IP:1.0 mb2_PMOD_IO_Switch_IP ]

  # Create instance: mb2_gpio, and set properties
  set mb2_gpio [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_gpio:2.0 mb2_gpio ]
  set_property -dict [ list \
CONFIG.C_GPIO_WIDTH {8} \
 ] $mb2_gpio

  # Create instance: mb2_iic, and set properties
  set mb2_iic [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_iic:2.0 mb2_iic ]

  # Create instance: mb2_local_memory
  create_hier_cell_mb2_local_memory $hier_obj mb2_local_memory

  # Create instance: mb2_spi, and set properties
  set mb2_spi [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_quad_spi:3.2 mb2_spi ]
  set_property -dict [ list \
CONFIG.C_USE_STARTUP {0} \
CONFIG.C_USE_STARTUP_INT {0} \
 ] $mb2_spi

  # Create instance: mb_2, and set properties
  set mb_2 [ create_bd_cell -type ip -vlnv xilinx.com:ip:microblaze:9.5 mb_2 ]
  set_property -dict [ list \
CONFIG.C_AREA_OPTIMIZED {1} \
CONFIG.C_CACHE_BYTE_SIZE {4096} \
CONFIG.C_DCACHE_BYTE_SIZE {4096} \
CONFIG.C_DEBUG_ENABLED {1} \
CONFIG.C_D_AXI {1} \
CONFIG.C_D_LMB {1} \
CONFIG.C_I_LMB {1} \
CONFIG.C_MMU_DTLB_SIZE {2} \
CONFIG.C_MMU_ITLB_SIZE {1} \
CONFIG.C_MMU_ZONES {2} \
CONFIG.C_NUMBER_OF_PC_BRK {0} \
CONFIG.C_USE_REORDER_INSTR {1} \
CONFIG.G_TEMPLATE_LIST {1} \
 ] $mb_2

  # Create instance: mb_2_axi_periph, and set properties
  set mb_2_axi_periph [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_interconnect:2.1 mb_2_axi_periph ]
  set_property -dict [ list \
CONFIG.NUM_MI {4} \
 ] $mb_2_axi_periph

  # Create instance: proc_sys_reset_0, and set properties
  set proc_sys_reset_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset:5.0 proc_sys_reset_0 ]
  set_property -dict [ list \
CONFIG.C_AUX_RESET_HIGH {1} \
 ] $proc_sys_reset_0

  # Create interface connections
  connect_bd_intf_net -intf_net axi_bram_ctrl_1_BRAM_PORTA [get_bd_intf_pins BRAM_PORTB] [get_bd_intf_pins mb2_local_memory/BRAM_PORTB]
  connect_bd_intf_net -intf_net mb_1_M_AXI_DP [get_bd_intf_pins mb_2/M_AXI_DP] [get_bd_intf_pins mb_2_axi_periph/S00_AXI]
  connect_bd_intf_net -intf_net mb_1_axi_periph_M00_AXI [get_bd_intf_pins mb2_spi/AXI_LITE] [get_bd_intf_pins mb_2_axi_periph/M00_AXI]
  connect_bd_intf_net -intf_net mb_1_axi_periph_M01_AXI [get_bd_intf_pins mb2_iic/S_AXI] [get_bd_intf_pins mb_2_axi_periph/M01_AXI]
  connect_bd_intf_net -intf_net mb_1_axi_periph_M02_AXI [get_bd_intf_pins mb2_PMOD_IO_Switch_IP/S00_AXI] [get_bd_intf_pins mb_2_axi_periph/M02_AXI]
  connect_bd_intf_net -intf_net mb_1_axi_periph_M03_AXI [get_bd_intf_pins mb2_gpio/S_AXI] [get_bd_intf_pins mb_2_axi_periph/M03_AXI]
  connect_bd_intf_net -intf_net microblaze_0_debug [get_bd_intf_pins DEBUG] [get_bd_intf_pins mb_2/DEBUG]
  connect_bd_intf_net -intf_net microblaze_0_dlmb_1 [get_bd_intf_pins mb2_local_memory/DLMB] [get_bd_intf_pins mb_2/DLMB]
  connect_bd_intf_net -intf_net microblaze_0_ilmb_1 [get_bd_intf_pins mb2_local_memory/ILMB] [get_bd_intf_pins mb_2/ILMB]

  # Create port connections
  connect_bd_net -net logic_1_dout [get_bd_pins ext_reset_in] [get_bd_pins proc_sys_reset_0/ext_reset_in]
  connect_bd_net -net mb1_PMOD_IO_Switch_IP_miso_i_in [get_bd_pins mb2_PMOD_IO_Switch_IP/miso_i_in] [get_bd_pins mb2_spi/io1_i]
  connect_bd_net -net mb1_PMOD_IO_Switch_IP_mosi_i_in [get_bd_pins mb2_PMOD_IO_Switch_IP/mosi_i_in] [get_bd_pins mb2_spi/io0_i]
  connect_bd_net -net mb1_PMOD_IO_Switch_IP_scl_i_in [get_bd_pins mb2_PMOD_IO_Switch_IP/scl_i_in] [get_bd_pins mb2_iic/scl_i]
  connect_bd_net -net mb1_PMOD_IO_Switch_IP_sda_i_in [get_bd_pins mb2_PMOD_IO_Switch_IP/sda_i_in] [get_bd_pins mb2_iic/sda_i]
  connect_bd_net -net mb1_PMOD_IO_Switch_IP_spick_i_in [get_bd_pins mb2_PMOD_IO_Switch_IP/spick_i_in] [get_bd_pins mb2_spi/sck_i]
  connect_bd_net -net mb1_PMOD_IO_Switch_IP_ss_i_in [get_bd_pins mb2_PMOD_IO_Switch_IP/ss_i_in] [get_bd_pins mb2_spi/ss_i]
  connect_bd_net -net mb1_PMOD_IO_Switch_IP_sw2pl_data_in [get_bd_pins mb2_PMOD_IO_Switch_IP/sw2pl_data_in] [get_bd_pins mb2_gpio/gpio_io_i]
  connect_bd_net -net mb1_PMOD_IO_Switch_IP_sw2pmod_data_out [get_bd_pins pmodJC_data_out] [get_bd_pins mb2_PMOD_IO_Switch_IP/sw2pmod_data_out]
  connect_bd_net -net mb1_PMOD_IO_Switch_IP_sw2pmod_tri_out [get_bd_pins pmodJC_tri_out] [get_bd_pins mb2_PMOD_IO_Switch_IP/sw2pmod_tri_out]
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
  connect_bd_net -net mb_1_reset_Dout [get_bd_pins aux_reset_in] [get_bd_pins proc_sys_reset_0/aux_reset_in]
  connect_bd_net -net mdm_1_Debug_SYS_Rst [get_bd_pins mb_debug_sys_rst] [get_bd_pins proc_sys_reset_0/mb_debug_sys_rst]
  connect_bd_net -net microblaze_0_Clk [get_bd_pins Clk] [get_bd_pins mb2_PMOD_IO_Switch_IP/s00_axi_aclk] [get_bd_pins mb2_gpio/s_axi_aclk] [get_bd_pins mb2_iic/s_axi_aclk] [get_bd_pins mb2_local_memory/LMB_Clk] [get_bd_pins mb2_spi/ext_spi_clk] [get_bd_pins mb2_spi/s_axi_aclk] [get_bd_pins mb_2/Clk] [get_bd_pins mb_2_axi_periph/ACLK] [get_bd_pins mb_2_axi_periph/M00_ACLK] [get_bd_pins mb_2_axi_periph/M01_ACLK] [get_bd_pins mb_2_axi_periph/M02_ACLK] [get_bd_pins mb_2_axi_periph/M03_ACLK] [get_bd_pins mb_2_axi_periph/S00_ACLK] [get_bd_pins proc_sys_reset_0/slowest_sync_clk]
  connect_bd_net -net pmod2sw_data_in_1 [get_bd_pins pmodJC_data_in] [get_bd_pins mb2_PMOD_IO_Switch_IP/pmod2sw_data_in]
  connect_bd_net -net proc_sys_reset_0_bus_struct_reset [get_bd_pins mb2_local_memory/SYS_Rst] [get_bd_pins proc_sys_reset_0/bus_struct_reset]
  connect_bd_net -net proc_sys_reset_0_interconnect_aresetn [get_bd_pins mb_2_axi_periph/ARESETN] [get_bd_pins proc_sys_reset_0/interconnect_aresetn]
  connect_bd_net -net proc_sys_reset_0_mb_reset [get_bd_pins mb_2/Reset] [get_bd_pins proc_sys_reset_0/mb_reset]
  connect_bd_net -net proc_sys_reset_0_peripheral_aresetn [get_bd_pins mb2_PMOD_IO_Switch_IP/s00_axi_aresetn] [get_bd_pins mb2_gpio/s_axi_aresetn] [get_bd_pins mb2_iic/s_axi_aresetn] [get_bd_pins mb2_spi/s_axi_aresetn] [get_bd_pins mb_2_axi_periph/M00_ARESETN] [get_bd_pins mb_2_axi_periph/M01_ARESETN] [get_bd_pins mb_2_axi_periph/M02_ARESETN] [get_bd_pins mb_2_axi_periph/M03_ARESETN] [get_bd_pins mb_2_axi_periph/S00_ARESETN] [get_bd_pins proc_sys_reset_0/peripheral_aresetn]

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
  create_bd_pin -dir I -type clk Clk
  create_bd_pin -dir I -from 0 -to 0 -type rst aux_reset_in
  create_bd_pin -dir I -from 0 -to 0 -type rst ext_reset_in
  create_bd_pin -dir I -type rst mb_debug_sys_rst
  create_bd_pin -dir I -from 7 -to 0 pmodJB_data_in
  create_bd_pin -dir O -from 7 -to 0 pmodJB_data_out
  create_bd_pin -dir O -from 7 -to 0 pmodJB_tri_out

  # Create instance: mb1_PMOD_IO_Switch_IP, and set properties
  set mb1_PMOD_IO_Switch_IP [ create_bd_cell -type ip -vlnv xilinx.com:user:PMOD_IO_Switch_IP:1.0 mb1_PMOD_IO_Switch_IP ]

  # Create instance: mb1_gpio, and set properties
  set mb1_gpio [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_gpio:2.0 mb1_gpio ]
  set_property -dict [ list \
CONFIG.C_GPIO_WIDTH {8} \
 ] $mb1_gpio

  # Create instance: mb1_iic, and set properties
  set mb1_iic [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_iic:2.0 mb1_iic ]

  # Create instance: mb1_local_memory
  create_hier_cell_mb1_local_memory $hier_obj mb1_local_memory

  # Create instance: mb1_spi, and set properties
  set mb1_spi [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_quad_spi:3.2 mb1_spi ]
  set_property -dict [ list \
CONFIG.C_USE_STARTUP {0} \
CONFIG.C_USE_STARTUP_INT {0} \
 ] $mb1_spi

  # Create instance: mb_1, and set properties
  set mb_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:microblaze:9.5 mb_1 ]
  set_property -dict [ list \
CONFIG.C_AREA_OPTIMIZED {1} \
CONFIG.C_CACHE_BYTE_SIZE {4096} \
CONFIG.C_DCACHE_BYTE_SIZE {4096} \
CONFIG.C_DEBUG_ENABLED {1} \
CONFIG.C_D_AXI {1} \
CONFIG.C_D_LMB {1} \
CONFIG.C_I_LMB {1} \
CONFIG.C_MMU_DTLB_SIZE {2} \
CONFIG.C_MMU_ITLB_SIZE {1} \
CONFIG.C_MMU_ZONES {2} \
CONFIG.C_NUMBER_OF_PC_BRK {0} \
CONFIG.C_USE_REORDER_INSTR {1} \
CONFIG.G_TEMPLATE_LIST {1} \
 ] $mb_1

  # Create instance: mb_1_axi_periph, and set properties
  set mb_1_axi_periph [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_interconnect:2.1 mb_1_axi_periph ]
  set_property -dict [ list \
CONFIG.NUM_MI {4} \
 ] $mb_1_axi_periph

  # Create instance: proc_sys_reset_0, and set properties
  set proc_sys_reset_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset:5.0 proc_sys_reset_0 ]
  set_property -dict [ list \
CONFIG.C_AUX_RESET_HIGH {1} \
 ] $proc_sys_reset_0

  # Create interface connections
  connect_bd_intf_net -intf_net axi_bram_ctrl_1_BRAM_PORTA [get_bd_intf_pins BRAM_PORTB] [get_bd_intf_pins mb1_local_memory/BRAM_PORTB]
  connect_bd_intf_net -intf_net mb_1_M_AXI_DP [get_bd_intf_pins mb_1/M_AXI_DP] [get_bd_intf_pins mb_1_axi_periph/S00_AXI]
  connect_bd_intf_net -intf_net mb_1_axi_periph_M00_AXI [get_bd_intf_pins mb1_spi/AXI_LITE] [get_bd_intf_pins mb_1_axi_periph/M00_AXI]
  connect_bd_intf_net -intf_net mb_1_axi_periph_M01_AXI [get_bd_intf_pins mb1_iic/S_AXI] [get_bd_intf_pins mb_1_axi_periph/M01_AXI]
  connect_bd_intf_net -intf_net mb_1_axi_periph_M02_AXI [get_bd_intf_pins mb1_PMOD_IO_Switch_IP/S00_AXI] [get_bd_intf_pins mb_1_axi_periph/M02_AXI]
  connect_bd_intf_net -intf_net mb_1_axi_periph_M03_AXI [get_bd_intf_pins mb1_gpio/S_AXI] [get_bd_intf_pins mb_1_axi_periph/M03_AXI]
  connect_bd_intf_net -intf_net microblaze_0_debug [get_bd_intf_pins DEBUG] [get_bd_intf_pins mb_1/DEBUG]
  connect_bd_intf_net -intf_net microblaze_0_dlmb_1 [get_bd_intf_pins mb1_local_memory/DLMB] [get_bd_intf_pins mb_1/DLMB]
  connect_bd_intf_net -intf_net microblaze_0_ilmb_1 [get_bd_intf_pins mb1_local_memory/ILMB] [get_bd_intf_pins mb_1/ILMB]

  # Create port connections
  connect_bd_net -net logic_1_dout [get_bd_pins ext_reset_in] [get_bd_pins proc_sys_reset_0/ext_reset_in]
  connect_bd_net -net mb1_PMOD_IO_Switch_IP_miso_i_in [get_bd_pins mb1_PMOD_IO_Switch_IP/miso_i_in] [get_bd_pins mb1_spi/io1_i]
  connect_bd_net -net mb1_PMOD_IO_Switch_IP_mosi_i_in [get_bd_pins mb1_PMOD_IO_Switch_IP/mosi_i_in] [get_bd_pins mb1_spi/io0_i]
  connect_bd_net -net mb1_PMOD_IO_Switch_IP_scl_i_in [get_bd_pins mb1_PMOD_IO_Switch_IP/scl_i_in] [get_bd_pins mb1_iic/scl_i]
  connect_bd_net -net mb1_PMOD_IO_Switch_IP_sda_i_in [get_bd_pins mb1_PMOD_IO_Switch_IP/sda_i_in] [get_bd_pins mb1_iic/sda_i]
  connect_bd_net -net mb1_PMOD_IO_Switch_IP_spick_i_in [get_bd_pins mb1_PMOD_IO_Switch_IP/spick_i_in] [get_bd_pins mb1_spi/sck_i]
  connect_bd_net -net mb1_PMOD_IO_Switch_IP_ss_i_in [get_bd_pins mb1_PMOD_IO_Switch_IP/ss_i_in] [get_bd_pins mb1_spi/ss_i]
  connect_bd_net -net mb1_PMOD_IO_Switch_IP_sw2pl_data_in [get_bd_pins mb1_PMOD_IO_Switch_IP/sw2pl_data_in] [get_bd_pins mb1_gpio/gpio_io_i]
  connect_bd_net -net mb1_PMOD_IO_Switch_IP_sw2pmod_data_out [get_bd_pins pmodJB_data_out] [get_bd_pins mb1_PMOD_IO_Switch_IP/sw2pmod_data_out]
  connect_bd_net -net mb1_PMOD_IO_Switch_IP_sw2pmod_tri_out [get_bd_pins pmodJB_tri_out] [get_bd_pins mb1_PMOD_IO_Switch_IP/sw2pmod_tri_out]
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
  connect_bd_net -net mb_1_reset_Dout [get_bd_pins aux_reset_in] [get_bd_pins proc_sys_reset_0/aux_reset_in]
  connect_bd_net -net mdm_1_Debug_SYS_Rst [get_bd_pins mb_debug_sys_rst] [get_bd_pins proc_sys_reset_0/mb_debug_sys_rst]
  connect_bd_net -net microblaze_0_Clk [get_bd_pins Clk] [get_bd_pins mb1_PMOD_IO_Switch_IP/s00_axi_aclk] [get_bd_pins mb1_gpio/s_axi_aclk] [get_bd_pins mb1_iic/s_axi_aclk] [get_bd_pins mb1_local_memory/LMB_Clk] [get_bd_pins mb1_spi/ext_spi_clk] [get_bd_pins mb1_spi/s_axi_aclk] [get_bd_pins mb_1/Clk] [get_bd_pins mb_1_axi_periph/ACLK] [get_bd_pins mb_1_axi_periph/M00_ACLK] [get_bd_pins mb_1_axi_periph/M01_ACLK] [get_bd_pins mb_1_axi_periph/M02_ACLK] [get_bd_pins mb_1_axi_periph/M03_ACLK] [get_bd_pins mb_1_axi_periph/S00_ACLK] [get_bd_pins proc_sys_reset_0/slowest_sync_clk]
  connect_bd_net -net pmod2sw_data_in_1 [get_bd_pins pmodJB_data_in] [get_bd_pins mb1_PMOD_IO_Switch_IP/pmod2sw_data_in]
  connect_bd_net -net proc_sys_reset_0_bus_struct_reset [get_bd_pins mb1_local_memory/SYS_Rst] [get_bd_pins proc_sys_reset_0/bus_struct_reset]
  connect_bd_net -net proc_sys_reset_0_interconnect_aresetn [get_bd_pins mb_1_axi_periph/ARESETN] [get_bd_pins proc_sys_reset_0/interconnect_aresetn]
  connect_bd_net -net proc_sys_reset_0_mb_reset [get_bd_pins mb_1/Reset] [get_bd_pins proc_sys_reset_0/mb_reset]
  connect_bd_net -net proc_sys_reset_0_peripheral_aresetn [get_bd_pins mb1_PMOD_IO_Switch_IP/s00_axi_aresetn] [get_bd_pins mb1_gpio/s_axi_aresetn] [get_bd_pins mb1_iic/s_axi_aresetn] [get_bd_pins mb1_spi/s_axi_aresetn] [get_bd_pins mb_1_axi_periph/M00_ARESETN] [get_bd_pins mb_1_axi_periph/M01_ARESETN] [get_bd_pins mb_1_axi_periph/M02_ARESETN] [get_bd_pins mb_1_axi_periph/M03_ARESETN] [get_bd_pins mb_1_axi_periph/S00_ARESETN] [get_bd_pins proc_sys_reset_0/peripheral_aresetn]

  # Restore current instance
  current_bd_instance $oldCurInst
}

# Hierarchical cell: audio
proc create_hier_cell_audio { parentCell nameHier } {

  if { $parentCell eq "" || $nameHier eq "" } {
     puts "ERROR: create_hier_cell_audio() - Empty argument(s)!"
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
  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S_AXI1

  # Create pins
  create_bd_pin -dir O BCLK
  create_bd_pin -dir I -from 2 -to 0 Din
  create_bd_pin -dir O -from 0 -to 0 Dout
  create_bd_pin -dir O PBDATA
  create_bd_pin -dir O PBLRCLK
  create_bd_pin -dir I RECDAT
  create_bd_pin -dir O RECLRCLK
  create_bd_pin -dir I -from 0 -to 0 -type rst S_AXI_ARESETN1
  create_bd_pin -dir I -type clk s_axi_aclk

  # Create instance: codec_ctrl, and set properties
  set codec_ctrl [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice:1.0 codec_ctrl ]
  set_property -dict [ list \
CONFIG.DIN_FROM {2} \
CONFIG.DIN_TO {2} \
CONFIG.DIN_WIDTH {3} \
CONFIG.DOUT_WIDTH {1} \
 ] $codec_ctrl

  # Create instance: zybo_audio_ctrl_0, and set properties
  set zybo_audio_ctrl_0 [ create_bd_cell -type ip -vlnv xilinx.com:xilinx:zybo_audio_ctrl:1.0 zybo_audio_ctrl_0 ]

  # Create interface connections
  connect_bd_intf_net -intf_net Conn1 [get_bd_intf_pins S_AXI1] [get_bd_intf_pins zybo_audio_ctrl_0/S_AXI]

  # Create port connections
  connect_bd_net -net RECDAT_1 [get_bd_pins RECDAT] [get_bd_pins zybo_audio_ctrl_0/RECDAT]
  connect_bd_net -net S_AXI_ARESETN1_1 [get_bd_pins S_AXI_ARESETN1] [get_bd_pins zybo_audio_ctrl_0/S_AXI_ARESETN]
  connect_bd_net -net microblaze_0_Clk [get_bd_pins s_axi_aclk] [get_bd_pins zybo_audio_ctrl_0/S_AXI_ACLK]
  connect_bd_net -net processing_system7_0_GPIO_O [get_bd_pins Din] [get_bd_pins codec_ctrl/Din]
  connect_bd_net -net xlslice_1_Dout [get_bd_pins Dout] [get_bd_pins codec_ctrl/Dout]
  connect_bd_net -net zybo_audio_ctrl_0_BCLK [get_bd_pins BCLK] [get_bd_pins zybo_audio_ctrl_0/BCLK]
  connect_bd_net -net zybo_audio_ctrl_0_PBDATA [get_bd_pins PBDATA] [get_bd_pins zybo_audio_ctrl_0/PBDATA]
  connect_bd_net -net zybo_audio_ctrl_0_PBLRCLK [get_bd_pins PBLRCLK] [get_bd_pins zybo_audio_ctrl_0/PBLRCLK]
  connect_bd_net -net zybo_audio_ctrl_0_RECLRCLK [get_bd_pins RECLRCLK] [get_bd_pins zybo_audio_ctrl_0/RECLRCLK]

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
  set DDC [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:iic_rtl:1.0 DDC ]
  set DDR [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:ddrx_rtl:1.0 DDR ]
  set FIXED_IO [ create_bd_intf_port -mode Master -vlnv xilinx.com:display_processing_system7:fixedio_rtl:1.0 FIXED_IO ]
  set IIC_1 [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:iic_rtl:1.0 IIC_1 ]
  set TMDS [ create_bd_intf_port -mode Slave -vlnv digilentinc.com:interface:tmds_rtl:1.0 TMDS ]
  set btns_4bits [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:gpio_rtl:1.0 btns_4bits ]
  set hdmi_hpd [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:gpio_rtl:1.0 hdmi_hpd ]
  set leds_4bits [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:gpio_rtl:1.0 leds_4bits ]
  set sws_4bits [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:gpio_rtl:1.0 sws_4bits ]

  # Create ports
  set BCLK [ create_bd_port -dir O BCLK ]
  set FCLK_CLK3 [ create_bd_port -dir O -type clk FCLK_CLK3 ]
  set HDMI_OEN [ create_bd_port -dir O -from 0 -to 0 HDMI_OEN ]
  set PBDATA [ create_bd_port -dir O PBDATA ]
  set PBLRCLK [ create_bd_port -dir O PBLRCLK ]
  set RECDAT [ create_bd_port -dir I RECDAT ]
  set RECLRCLK [ create_bd_port -dir O RECLRCLK ]
  set codec_out [ create_bd_port -dir O -from 0 -to 0 codec_out ]
  set pmodJB_data_in [ create_bd_port -dir I -from 7 -to 0 pmodJB_data_in ]
  set pmodJB_data_out [ create_bd_port -dir O -from 7 -to 0 pmodJB_data_out ]
  set pmodJB_tri_out [ create_bd_port -dir O -from 7 -to 0 pmodJB_tri_out ]
  set pmodJC_data_in [ create_bd_port -dir I -from 7 -to 0 pmodJC_data_in ]
  set pmodJC_data_out [ create_bd_port -dir O -from 7 -to 0 pmodJC_data_out ]
  set pmodJC_tri_out [ create_bd_port -dir O -from 7 -to 0 pmodJC_tri_out ]
  set vga_b [ create_bd_port -dir O -from 4 -to 0 vga_b ]
  set vga_g [ create_bd_port -dir O -from 5 -to 0 vga_g ]
  set vga_hs [ create_bd_port -dir O vga_hs ]
  set vga_r [ create_bd_port -dir O -from 4 -to 0 vga_r ]
  set vga_vs [ create_bd_port -dir O vga_vs ]

  # Create instance: audio
  create_hier_cell_audio [current_bd_instance .] audio

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

  # Create instance: btns_gpio, and set properties
  set btns_gpio [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_gpio:2.0 btns_gpio ]
  set_property -dict [ list \
CONFIG.C_ALL_INPUTS {1} \
CONFIG.C_GPIO_WIDTH {4} \
CONFIG.GPIO_BOARD_INTERFACE {Custom} \
CONFIG.USE_BOARD_FLOW {true} \
 ] $btns_gpio

  # Create instance: logic_1, and set properties
  set logic_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant:1.1 logic_1 ]

  # Create instance: mb_1_reset, and set properties
  set mb_1_reset [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice:1.0 mb_1_reset ]
  set_property -dict [ list \
CONFIG.DIN_FROM {0} \
CONFIG.DIN_TO {0} \
CONFIG.DIN_WIDTH {3} \
CONFIG.DOUT_WIDTH {1} \
 ] $mb_1_reset

  # Create instance: mb_2_reset, and set properties
  set mb_2_reset [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice:1.0 mb_2_reset ]
  set_property -dict [ list \
CONFIG.DIN_FROM {1} \
CONFIG.DIN_TO {1} \
CONFIG.DIN_WIDTH {3} \
CONFIG.DOUT_WIDTH {1} \
 ] $mb_2_reset

  # Create instance: mb_JB
  create_hier_cell_mb_JB [current_bd_instance .] mb_JB

  # Create instance: mb_JC
  create_hier_cell_mb_JC [current_bd_instance .] mb_JC

  # Create instance: mdm_1, and set properties
  set mdm_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:mdm:3.2 mdm_1 ]
  set_property -dict [ list \
CONFIG.C_MB_DBG_PORTS {2} \
 ] $mdm_1

  # Create instance: processing_system7_0, and set properties
  set processing_system7_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:processing_system7:5.5 processing_system7_0 ]
  set_property -dict [ list \
CONFIG.PCW_APU_PERIPHERAL_FREQMHZ {650} \
CONFIG.PCW_CRYSTAL_PERIPHERAL_FREQMHZ {50.000000} \
CONFIG.PCW_ENET0_ENET0_IO {MIO 16 .. 27} \
CONFIG.PCW_ENET0_GRP_MDIO_ENABLE {1} \
CONFIG.PCW_ENET0_PERIPHERAL_ENABLE {1} \
CONFIG.PCW_ENET0_RESET_ENABLE {0} \
CONFIG.PCW_EN_CLK1_PORT {1} \
CONFIG.PCW_EN_CLK2_PORT {1} \
CONFIG.PCW_EN_CLK3_PORT {1} \
CONFIG.PCW_FCLK1_PERIPHERAL_CLKSRC {DDR PLL} \
CONFIG.PCW_FPGA0_PERIPHERAL_FREQMHZ {100} \
CONFIG.PCW_FPGA1_PERIPHERAL_FREQMHZ {150} \
CONFIG.PCW_FPGA2_PERIPHERAL_FREQMHZ {200} \
CONFIG.PCW_FPGA3_PERIPHERAL_FREQMHZ {12.288} \
CONFIG.PCW_GPIO_EMIO_GPIO_ENABLE {1} \
CONFIG.PCW_GPIO_EMIO_GPIO_IO {3} \
CONFIG.PCW_GPIO_MIO_GPIO_ENABLE {1} \
CONFIG.PCW_I2C0_PERIPHERAL_ENABLE {0} \
CONFIG.PCW_I2C1_PERIPHERAL_ENABLE {1} \
CONFIG.PCW_IRQ_F2P_INTR {1} \
CONFIG.PCW_MIO_0_PULLUP {enabled} \
CONFIG.PCW_MIO_10_PULLUP {enabled} \
CONFIG.PCW_MIO_11_PULLUP {enabled} \
CONFIG.PCW_MIO_12_PULLUP {enabled} \
CONFIG.PCW_MIO_16_IOTYPE {HSTL 1.8V} \
CONFIG.PCW_MIO_16_PULLUP {disabled} \
CONFIG.PCW_MIO_16_SLEW {fast} \
CONFIG.PCW_MIO_17_IOTYPE {HSTL 1.8V} \
CONFIG.PCW_MIO_17_PULLUP {disabled} \
CONFIG.PCW_MIO_17_SLEW {fast} \
CONFIG.PCW_MIO_18_IOTYPE {HSTL 1.8V} \
CONFIG.PCW_MIO_18_PULLUP {disabled} \
CONFIG.PCW_MIO_18_SLEW {fast} \
CONFIG.PCW_MIO_19_IOTYPE {HSTL 1.8V} \
CONFIG.PCW_MIO_19_PULLUP {disabled} \
CONFIG.PCW_MIO_19_SLEW {fast} \
CONFIG.PCW_MIO_1_PULLUP {disabled} \
CONFIG.PCW_MIO_1_SLEW {fast} \
CONFIG.PCW_MIO_20_IOTYPE {HSTL 1.8V} \
CONFIG.PCW_MIO_20_PULLUP {disabled} \
CONFIG.PCW_MIO_20_SLEW {fast} \
CONFIG.PCW_MIO_21_IOTYPE {HSTL 1.8V} \
CONFIG.PCW_MIO_21_PULLUP {disabled} \
CONFIG.PCW_MIO_21_SLEW {fast} \
CONFIG.PCW_MIO_22_IOTYPE {HSTL 1.8V} \
CONFIG.PCW_MIO_22_PULLUP {disabled} \
CONFIG.PCW_MIO_22_SLEW {fast} \
CONFIG.PCW_MIO_23_IOTYPE {HSTL 1.8V} \
CONFIG.PCW_MIO_23_PULLUP {disabled} \
CONFIG.PCW_MIO_23_SLEW {fast} \
CONFIG.PCW_MIO_24_IOTYPE {HSTL 1.8V} \
CONFIG.PCW_MIO_24_PULLUP {disabled} \
CONFIG.PCW_MIO_24_SLEW {fast} \
CONFIG.PCW_MIO_25_IOTYPE {HSTL 1.8V} \
CONFIG.PCW_MIO_25_PULLUP {disabled} \
CONFIG.PCW_MIO_25_SLEW {fast} \
CONFIG.PCW_MIO_26_IOTYPE {HSTL 1.8V} \
CONFIG.PCW_MIO_26_PULLUP {disabled} \
CONFIG.PCW_MIO_26_SLEW {fast} \
CONFIG.PCW_MIO_27_IOTYPE {HSTL 1.8V} \
CONFIG.PCW_MIO_27_PULLUP {disabled} \
CONFIG.PCW_MIO_27_SLEW {fast} \
CONFIG.PCW_MIO_28_PULLUP {disabled} \
CONFIG.PCW_MIO_28_SLEW {fast} \
CONFIG.PCW_MIO_29_PULLUP {disabled} \
CONFIG.PCW_MIO_29_SLEW {fast} \
CONFIG.PCW_MIO_2_SLEW {fast} \
CONFIG.PCW_MIO_30_PULLUP {disabled} \
CONFIG.PCW_MIO_30_SLEW {fast} \
CONFIG.PCW_MIO_31_PULLUP {disabled} \
CONFIG.PCW_MIO_31_SLEW {fast} \
CONFIG.PCW_MIO_32_PULLUP {disabled} \
CONFIG.PCW_MIO_32_SLEW {fast} \
CONFIG.PCW_MIO_33_PULLUP {disabled} \
CONFIG.PCW_MIO_33_SLEW {fast} \
CONFIG.PCW_MIO_34_PULLUP {disabled} \
CONFIG.PCW_MIO_34_SLEW {fast} \
CONFIG.PCW_MIO_35_PULLUP {disabled} \
CONFIG.PCW_MIO_35_SLEW {fast} \
CONFIG.PCW_MIO_36_PULLUP {disabled} \
CONFIG.PCW_MIO_36_SLEW {fast} \
CONFIG.PCW_MIO_37_PULLUP {disabled} \
CONFIG.PCW_MIO_37_SLEW {fast} \
CONFIG.PCW_MIO_38_PULLUP {disabled} \
CONFIG.PCW_MIO_38_SLEW {fast} \
CONFIG.PCW_MIO_39_PULLUP {disabled} \
CONFIG.PCW_MIO_39_SLEW {fast} \
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
CONFIG.PCW_MIO_50_PULLUP {disabled} \
CONFIG.PCW_MIO_51_PULLUP {disabled} \
CONFIG.PCW_MIO_52_PULLUP {disabled} \
CONFIG.PCW_MIO_52_SLEW {slow} \
CONFIG.PCW_MIO_53_PULLUP {disabled} \
CONFIG.PCW_MIO_53_SLEW {slow} \
CONFIG.PCW_MIO_5_SLEW {fast} \
CONFIG.PCW_MIO_6_SLEW {fast} \
CONFIG.PCW_MIO_8_SLEW {fast} \
CONFIG.PCW_MIO_9_PULLUP {enabled} \
CONFIG.PCW_PRESET_BANK1_VOLTAGE {LVCMOS 1.8V} \
CONFIG.PCW_QSPI_GRP_FBCLK_ENABLE {1} \
CONFIG.PCW_QSPI_GRP_SINGLE_SS_ENABLE {1} \
CONFIG.PCW_QSPI_PERIPHERAL_ENABLE {1} \
CONFIG.PCW_SD0_GRP_CD_ENABLE {1} \
CONFIG.PCW_SD0_GRP_CD_IO {MIO 47} \
CONFIG.PCW_SD0_GRP_WP_ENABLE {1} \
CONFIG.PCW_SD0_PERIPHERAL_ENABLE {1} \
CONFIG.PCW_SDIO_PERIPHERAL_FREQMHZ {50} \
CONFIG.PCW_TTC0_PERIPHERAL_ENABLE {1} \
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
CONFIG.PCW_USB0_RESET_ENABLE {1} \
CONFIG.PCW_USB0_RESET_IO {MIO 46} \
CONFIG.PCW_USE_FABRIC_INTERRUPT {1} \
CONFIG.PCW_USE_S_AXI_HP0 {1} \
CONFIG.preset {Default} \
 ] $processing_system7_0

  # Create instance: processing_system7_0_axi_periph, and set properties
  set processing_system7_0_axi_periph [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_interconnect:2.1 processing_system7_0_axi_periph ]
  set_property -dict [ list \
CONFIG.NUM_MI {10} \
 ] $processing_system7_0_axi_periph

  # Create instance: rst_processing_system7_0_100M, and set properties
  set rst_processing_system7_0_100M [ create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset:5.0 rst_processing_system7_0_100M ]

  # Create instance: rst_processing_system7_0_150M, and set properties
  set rst_processing_system7_0_150M [ create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset:5.0 rst_processing_system7_0_150M ]

  # Create instance: swsleds_gpio, and set properties
  set swsleds_gpio [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_gpio:2.0 swsleds_gpio ]
  set_property -dict [ list \
CONFIG.C_ALL_INPUTS {1} \
CONFIG.C_ALL_OUTPUTS_2 {1} \
CONFIG.C_GPIO2_WIDTH {4} \
CONFIG.C_GPIO_WIDTH {4} \
CONFIG.C_IS_DUAL {1} \
CONFIG.GPIO2_BOARD_INTERFACE {Custom} \
CONFIG.GPIO_BOARD_INTERFACE {Custom} \
CONFIG.USE_BOARD_FLOW {true} \
 ] $swsleds_gpio

  # Create instance: video
  create_hier_cell_video [current_bd_instance .] video

  # Create interface connections
  connect_bd_intf_net -intf_net TMDS_1 [get_bd_intf_ports TMDS] [get_bd_intf_pins video/TMDS]
  connect_bd_intf_net -intf_net axi_bram_ctrl_1_BRAM_PORTA [get_bd_intf_pins axi_bram_ctrl_1/BRAM_PORTA] [get_bd_intf_pins mb_JB/BRAM_PORTB]
  connect_bd_intf_net -intf_net axi_bram_ctrl_2_BRAM_PORTA [get_bd_intf_pins axi_bram_ctrl_2/BRAM_PORTA] [get_bd_intf_pins mb_JC/BRAM_PORTB]
  connect_bd_intf_net -intf_net axi_gpio_0_GPIO [get_bd_intf_ports btns_4bits] [get_bd_intf_pins btns_gpio/GPIO]
  connect_bd_intf_net -intf_net axi_gpio_0_GPIO2 [get_bd_intf_ports hdmi_hpd] [get_bd_intf_pins video/GPIO]
  connect_bd_intf_net -intf_net axi_mem_intercon_M00_AXI [get_bd_intf_pins processing_system7_0/S_AXI_HP0] [get_bd_intf_pins video/M00_AXI]
  connect_bd_intf_net -intf_net dvi2rgb_0_DDC [get_bd_intf_ports DDC] [get_bd_intf_pins video/DDC]
  connect_bd_intf_net -intf_net mdm_1_MBDEBUG_1 [get_bd_intf_pins mb_JC/DEBUG] [get_bd_intf_pins mdm_1/MBDEBUG_1]
  connect_bd_intf_net -intf_net microblaze_0_debug [get_bd_intf_pins mb_JB/DEBUG] [get_bd_intf_pins mdm_1/MBDEBUG_0]
  connect_bd_intf_net -intf_net processing_system7_0_DDR [get_bd_intf_ports DDR] [get_bd_intf_pins processing_system7_0/DDR]
  connect_bd_intf_net -intf_net processing_system7_0_FIXED_IO [get_bd_intf_ports FIXED_IO] [get_bd_intf_pins processing_system7_0/FIXED_IO]
  connect_bd_intf_net -intf_net processing_system7_0_IIC_1 [get_bd_intf_ports IIC_1] [get_bd_intf_pins processing_system7_0/IIC_1]
  connect_bd_intf_net -intf_net processing_system7_0_M_AXI_GP0 [get_bd_intf_pins processing_system7_0/M_AXI_GP0] [get_bd_intf_pins processing_system7_0_axi_periph/S00_AXI]
  connect_bd_intf_net -intf_net processing_system7_0_axi_periph_M00_AXI [get_bd_intf_pins processing_system7_0_axi_periph/M00_AXI] [get_bd_intf_pins swsleds_gpio/S_AXI]
  connect_bd_intf_net -intf_net processing_system7_0_axi_periph_M01_AXI [get_bd_intf_pins btns_gpio/S_AXI] [get_bd_intf_pins processing_system7_0_axi_periph/M01_AXI]
  connect_bd_intf_net -intf_net processing_system7_0_axi_periph_M02_AXI [get_bd_intf_pins audio/S_AXI1] [get_bd_intf_pins processing_system7_0_axi_periph/M02_AXI]
  connect_bd_intf_net -intf_net processing_system7_0_axi_periph_M03_AXI [get_bd_intf_pins processing_system7_0_axi_periph/M03_AXI] [get_bd_intf_pins video/ctrl1]
  connect_bd_intf_net -intf_net processing_system7_0_axi_periph_M04_AXI [get_bd_intf_pins processing_system7_0_axi_periph/M04_AXI] [get_bd_intf_pins video/s00_axi]
  connect_bd_intf_net -intf_net processing_system7_0_axi_periph_M05_AXI [get_bd_intf_pins processing_system7_0_axi_periph/M05_AXI] [get_bd_intf_pins video/S_AXI_LITE]
  connect_bd_intf_net -intf_net processing_system7_0_axi_periph_M06_AXI [get_bd_intf_pins processing_system7_0_axi_periph/M06_AXI] [get_bd_intf_pins video/ctrl]
  connect_bd_intf_net -intf_net processing_system7_0_axi_periph_M07_AXI [get_bd_intf_pins processing_system7_0_axi_periph/M07_AXI] [get_bd_intf_pins video/S_AXI]
  connect_bd_intf_net -intf_net processing_system7_0_axi_periph_M08_AXI [get_bd_intf_pins axi_bram_ctrl_1/S_AXI] [get_bd_intf_pins processing_system7_0_axi_periph/M08_AXI]
  connect_bd_intf_net -intf_net processing_system7_0_axi_periph_M09_AXI [get_bd_intf_pins axi_bram_ctrl_2/S_AXI] [get_bd_intf_pins processing_system7_0_axi_periph/M09_AXI]
  connect_bd_intf_net -intf_net swsleds_gpio_GPIO [get_bd_intf_ports sws_4bits] [get_bd_intf_pins swsleds_gpio/GPIO]
  connect_bd_intf_net -intf_net swsleds_gpio_GPIO2 [get_bd_intf_ports leds_4bits] [get_bd_intf_pins swsleds_gpio/GPIO2]

  # Create port connections
  connect_bd_net -net RECDAT_1 [get_bd_ports RECDAT] [get_bd_pins audio/RECDAT]
  connect_bd_net -net audio_BCLK [get_bd_ports BCLK] [get_bd_pins audio/BCLK]
  connect_bd_net -net audio_PBDATA [get_bd_ports PBDATA] [get_bd_pins audio/PBDATA]
  connect_bd_net -net audio_PBLRCLK [get_bd_ports PBLRCLK] [get_bd_pins audio/PBLRCLK]
  connect_bd_net -net audio_RECLRCLK [get_bd_ports RECLRCLK] [get_bd_pins audio/RECLRCLK]
  connect_bd_net -net aux_reset_in_1 [get_bd_pins mb_2_reset/Dout] [get_bd_pins mb_JC/aux_reset_in]
  connect_bd_net -net logic_1_dout [get_bd_pins logic_1/dout] [get_bd_pins mb_JB/ext_reset_in] [get_bd_pins mb_JC/ext_reset_in]
  connect_bd_net -net mb_1_reset_Dout [get_bd_pins mb_1_reset/Dout] [get_bd_pins mb_JB/aux_reset_in]
  connect_bd_net -net mb_JB_sw2pmod_data_out [get_bd_ports pmodJB_data_out] [get_bd_pins mb_JB/pmodJB_data_out]
  connect_bd_net -net mb_JB_sw2pmod_tri_out [get_bd_ports pmodJB_tri_out] [get_bd_pins mb_JB/pmodJB_tri_out]
  connect_bd_net -net mb_JC_pmodJC_data_out [get_bd_ports pmodJC_data_out] [get_bd_pins mb_JC/pmodJC_data_out]
  connect_bd_net -net mb_JC_pmodJC_tri_out [get_bd_ports pmodJC_tri_out] [get_bd_pins mb_JC/pmodJC_tri_out]
  connect_bd_net -net mdm_1_Debug_SYS_Rst [get_bd_pins mb_JB/mb_debug_sys_rst] [get_bd_pins mb_JC/mb_debug_sys_rst] [get_bd_pins mdm_1/Debug_SYS_Rst]
  connect_bd_net -net microblaze_0_Clk [get_bd_pins audio/s_axi_aclk] [get_bd_pins axi_bram_ctrl_1/s_axi_aclk] [get_bd_pins axi_bram_ctrl_2/s_axi_aclk] [get_bd_pins btns_gpio/s_axi_aclk] [get_bd_pins mb_JB/Clk] [get_bd_pins mb_JC/Clk] [get_bd_pins processing_system7_0/FCLK_CLK0] [get_bd_pins processing_system7_0/M_AXI_GP0_ACLK] [get_bd_pins processing_system7_0_axi_periph/ACLK] [get_bd_pins processing_system7_0_axi_periph/M00_ACLK] [get_bd_pins processing_system7_0_axi_periph/M01_ACLK] [get_bd_pins processing_system7_0_axi_periph/M02_ACLK] [get_bd_pins processing_system7_0_axi_periph/M03_ACLK] [get_bd_pins processing_system7_0_axi_periph/M04_ACLK] [get_bd_pins processing_system7_0_axi_periph/M05_ACLK] [get_bd_pins processing_system7_0_axi_periph/M06_ACLK] [get_bd_pins processing_system7_0_axi_periph/M07_ACLK] [get_bd_pins processing_system7_0_axi_periph/M08_ACLK] [get_bd_pins processing_system7_0_axi_periph/M09_ACLK] [get_bd_pins processing_system7_0_axi_periph/S00_ACLK] [get_bd_pins rst_processing_system7_0_100M/slowest_sync_clk] [get_bd_pins swsleds_gpio/s_axi_aclk] [get_bd_pins video/REF_CLK_I]
  connect_bd_net -net pmod2sw_data_in_1 [get_bd_ports pmodJB_data_in] [get_bd_pins mb_JB/pmodJB_data_in]
  connect_bd_net -net pmodJC_data_in_1 [get_bd_ports pmodJC_data_in] [get_bd_pins mb_JC/pmodJC_data_in]
  connect_bd_net -net processing_system7_0_FCLK_CLK1 [get_bd_pins processing_system7_0/FCLK_CLK1] [get_bd_pins processing_system7_0/S_AXI_HP0_ACLK] [get_bd_pins rst_processing_system7_0_150M/slowest_sync_clk] [get_bd_pins video/m_axi_s2mm_aclk]
  connect_bd_net -net processing_system7_0_FCLK_CLK2 [get_bd_pins processing_system7_0/FCLK_CLK2] [get_bd_pins video/RefClk]
  connect_bd_net -net processing_system7_0_FCLK_CLK3 [get_bd_ports FCLK_CLK3] [get_bd_pins processing_system7_0/FCLK_CLK3]
  connect_bd_net -net processing_system7_0_FCLK_RESET0_N [get_bd_pins processing_system7_0/FCLK_RESET0_N] [get_bd_pins rst_processing_system7_0_100M/ext_reset_in] [get_bd_pins rst_processing_system7_0_150M/ext_reset_in]
  connect_bd_net -net processing_system7_0_GPIO_O [get_bd_pins audio/Din] [get_bd_pins mb_1_reset/Din] [get_bd_pins mb_2_reset/Din] [get_bd_pins processing_system7_0/GPIO_O]
  connect_bd_net -net rgb2vga_0_vga_pBlue [get_bd_ports vga_b] [get_bd_pins video/vga_pBlue]
  connect_bd_net -net rgb2vga_0_vga_pGreen [get_bd_ports vga_g] [get_bd_pins video/vga_pGreen]
  connect_bd_net -net rgb2vga_0_vga_pHSync [get_bd_ports vga_hs] [get_bd_pins video/vga_pHSync]
  connect_bd_net -net rgb2vga_0_vga_pRed [get_bd_ports vga_r] [get_bd_pins video/vga_pRed]
  connect_bd_net -net rgb2vga_0_vga_pVSync [get_bd_ports vga_vs] [get_bd_pins video/vga_pVSync]
  connect_bd_net -net rst_processing_system7_0_100M_interconnect_aresetn [get_bd_pins audio/S_AXI_ARESETN1] [get_bd_pins processing_system7_0_axi_periph/ARESETN] [get_bd_pins rst_processing_system7_0_100M/interconnect_aresetn]
  connect_bd_net -net rst_processing_system7_0_100M_peripheral_aresetn [get_bd_pins axi_bram_ctrl_1/s_axi_aresetn] [get_bd_pins axi_bram_ctrl_2/s_axi_aresetn] [get_bd_pins btns_gpio/s_axi_aresetn] [get_bd_pins processing_system7_0_axi_periph/M00_ARESETN] [get_bd_pins processing_system7_0_axi_periph/M01_ARESETN] [get_bd_pins processing_system7_0_axi_periph/M02_ARESETN] [get_bd_pins processing_system7_0_axi_periph/M03_ARESETN] [get_bd_pins processing_system7_0_axi_periph/M04_ARESETN] [get_bd_pins processing_system7_0_axi_periph/M05_ARESETN] [get_bd_pins processing_system7_0_axi_periph/M06_ARESETN] [get_bd_pins processing_system7_0_axi_periph/M07_ARESETN] [get_bd_pins processing_system7_0_axi_periph/M08_ARESETN] [get_bd_pins processing_system7_0_axi_periph/M09_ARESETN] [get_bd_pins processing_system7_0_axi_periph/S00_ARESETN] [get_bd_pins rst_processing_system7_0_100M/peripheral_aresetn] [get_bd_pins swsleds_gpio/s_axi_aresetn] [get_bd_pins video/aRst_n]
  connect_bd_net -net rst_processing_system7_0_150M_interconnect_aresetn [get_bd_pins rst_processing_system7_0_150M/interconnect_aresetn] [get_bd_pins video/ARESETN]
  connect_bd_net -net rst_processing_system7_0_150M_peripheral_aresetn [get_bd_pins rst_processing_system7_0_150M/peripheral_aresetn] [get_bd_pins video/S01_ARESETN]
  connect_bd_net -net xlconcat_0_dout [get_bd_pins processing_system7_0/IRQ_F2P] [get_bd_pins video/dout]
  connect_bd_net -net xlconstant_0_dout [get_bd_ports HDMI_OEN] [get_bd_pins video/dout1]
  connect_bd_net -net xlslice_1_Dout [get_bd_ports codec_out] [get_bd_pins audio/Dout]

  # Create address segments
  create_bd_addr_seg -range 0x8000 -offset 0x40000000 [get_bd_addr_spaces processing_system7_0/Data] [get_bd_addr_segs axi_bram_ctrl_1/S_AXI/Mem0] SEG_axi_bram_ctrl_1_Mem0
  create_bd_addr_seg -range 0x8000 -offset 0x42000000 [get_bd_addr_spaces processing_system7_0/Data] [get_bd_addr_segs axi_bram_ctrl_2/S_AXI/Mem0] SEG_axi_bram_ctrl_2_Mem0
  create_bd_addr_seg -range 0x10000 -offset 0x43C10000 [get_bd_addr_spaces processing_system7_0/Data] [get_bd_addr_segs video/axi_dynclk_0/s00_axi/reg0] SEG_axi_dynclk_0_reg0
  create_bd_addr_seg -range 0x10000 -offset 0x41210000 [get_bd_addr_spaces processing_system7_0/Data] [get_bd_addr_segs btns_gpio/S_AXI/Reg] SEG_axi_gpio_btn_Reg
  create_bd_addr_seg -range 0x10000 -offset 0x41230000 [get_bd_addr_spaces processing_system7_0/Data] [get_bd_addr_segs video/axi_gpio_video/S_AXI/Reg] SEG_axi_gpio_hpd_Reg
  create_bd_addr_seg -range 0x10000 -offset 0x41200000 [get_bd_addr_spaces processing_system7_0/Data] [get_bd_addr_segs swsleds_gpio/S_AXI/Reg] SEG_axi_gpio_led_Reg
  create_bd_addr_seg -range 0x10000 -offset 0x43000000 [get_bd_addr_spaces processing_system7_0/Data] [get_bd_addr_segs video/axi_vdma_0/S_AXI_LITE/Reg] SEG_axi_vdma_0_Reg
  create_bd_addr_seg -range 0x10000 -offset 0x43C00000 [get_bd_addr_spaces processing_system7_0/Data] [get_bd_addr_segs video/v_tc_0/ctrl/Reg] SEG_v_tc_0_Reg
  create_bd_addr_seg -range 0x10000 -offset 0x43C20000 [get_bd_addr_spaces processing_system7_0/Data] [get_bd_addr_segs video/v_tc_1/ctrl/Reg] SEG_v_tc_1_Reg
  create_bd_addr_seg -range 0x10000 -offset 0x60000000 [get_bd_addr_spaces processing_system7_0/Data] [get_bd_addr_segs audio/zybo_audio_ctrl_0/S_AXI/reg0] SEG_zybo_audio_ctrl_0_reg0
  create_bd_addr_seg -range 0x8000 -offset 0x0 [get_bd_addr_spaces mb_JB/mb_1/Instruction] [get_bd_addr_segs mb_JB/mb1_local_memory/lmb_bram_if_cntlr/SLMB/Mem] SEG_ilmb_bram_if_cntlr_Mem
  create_bd_addr_seg -range 0x8000 -offset 0x0 [get_bd_addr_spaces mb_JB/mb_1/Data] [get_bd_addr_segs mb_JB/mb1_local_memory/lmb_bram_if_cntlr/SLMB1/Mem] SEG_lmb_bram_if_cntlr_Mem
  create_bd_addr_seg -range 0x10000 -offset 0x44A00000 [get_bd_addr_spaces mb_JB/mb_1/Data] [get_bd_addr_segs mb_JB/mb1_PMOD_IO_Switch_IP/S00_AXI/S00_AXI_reg] SEG_mb1_PMOD_IO_Switch_IP_S00_AXI_reg
  create_bd_addr_seg -range 0x10000 -offset 0x40000000 [get_bd_addr_spaces mb_JB/mb_1/Data] [get_bd_addr_segs mb_JB/mb1_gpio/S_AXI/Reg] SEG_mb1_gpio_Reg
  create_bd_addr_seg -range 0x10000 -offset 0x40800000 [get_bd_addr_spaces mb_JB/mb_1/Data] [get_bd_addr_segs mb_JB/mb1_iic/S_AXI/Reg] SEG_mb1_iic_Reg
  create_bd_addr_seg -range 0x10000 -offset 0x44A10000 [get_bd_addr_spaces mb_JB/mb_1/Data] [get_bd_addr_segs mb_JB/mb1_spi/AXI_LITE/Reg] SEG_mb1_spi_Reg
  create_bd_addr_seg -range 0x8000 -offset 0x0 [get_bd_addr_spaces mb_JC/mb_2/Data] [get_bd_addr_segs mb_JC/mb2_local_memory/lmb_bram_if_cntlr/SLMB1/Mem] SEG_lmb_bram_if_cntlr_Mem
  create_bd_addr_seg -range 0x8000 -offset 0x0 [get_bd_addr_spaces mb_JC/mb_2/Instruction] [get_bd_addr_segs mb_JC/mb2_local_memory/lmb_bram_if_cntlr/SLMB/Mem] SEG_lmb_bram_if_cntlr_Mem
  create_bd_addr_seg -range 0x10000 -offset 0x44A00000 [get_bd_addr_spaces mb_JC/mb_2/Data] [get_bd_addr_segs mb_JC/mb2_PMOD_IO_Switch_IP/S00_AXI/S00_AXI_reg] SEG_mb2_PMOD_IO_Switch_IP_S00_AXI_reg
  create_bd_addr_seg -range 0x10000 -offset 0x40000000 [get_bd_addr_spaces mb_JC/mb_2/Data] [get_bd_addr_segs mb_JC/mb2_gpio/S_AXI/Reg] SEG_mb2_gpio_Reg
  create_bd_addr_seg -range 0x10000 -offset 0x40800000 [get_bd_addr_spaces mb_JC/mb_2/Data] [get_bd_addr_segs mb_JC/mb2_iic/S_AXI/Reg] SEG_mb2_iic_Reg
  create_bd_addr_seg -range 0x10000 -offset 0x44A10000 [get_bd_addr_spaces mb_JC/mb_2/Data] [get_bd_addr_segs mb_JC/mb2_spi/AXI_LITE/Reg] SEG_mb2_spi_Reg
  create_bd_addr_seg -range 0x20000000 -offset 0x0 [get_bd_addr_spaces video/axi_vdma_0/Data_MM2S] [get_bd_addr_segs processing_system7_0/S_AXI_HP0/HP0_DDR_LOWOCM] SEG_processing_system7_0_HP0_DDR_LOWOCM
  create_bd_addr_seg -range 0x20000000 -offset 0x0 [get_bd_addr_spaces video/axi_vdma_0/Data_S2MM] [get_bd_addr_segs processing_system7_0/S_AXI_HP0/HP0_DDR_LOWOCM] SEG_processing_system7_0_HP0_DDR_LOWOCM

  # Perform GUI Layout
  regenerate_bd_layout -layout_string {
   DisplayTieOff: "1",
   guistr: "# # String gsaved with Nlview 6.5.5  2015-06-26 bk=1.3371 VDI=38 GEI=35 GUI=JA:1.6
#  -string -flagsOSRD
preplace port FCLK_CLK3 -pg 1 -y 820 -defaultsOSRD
preplace port btns_4bits -pg 1 -y 60 -defaultsOSRD
preplace port DDR -pg 1 -y 760 -defaultsOSRD
preplace port PBLRCLK -pg 1 -y 940 -defaultsOSRD
preplace port TMDS -pg 1 -y 650 -defaultsOSRD
preplace port hdmi_hpd -pg 1 -y 480 -defaultsOSRD
preplace port vga_hs -pg 1 -y 580 -defaultsOSRD
preplace port sws_4bits -pg 1 -y 1050 -defaultsOSRD
preplace port BCLK -pg 1 -y 960 -defaultsOSRD
preplace port leds_4bits -pg 1 -y 1070 -defaultsOSRD
preplace port RECDAT -pg 1 -y 1090 -defaultsOSRD
preplace port FIXED_IO -pg 1 -y 780 -defaultsOSRD
preplace port IIC_1 -pg 1 -y 800 -defaultsOSRD
preplace port PBDATA -pg 1 -y 920 -defaultsOSRD
preplace port vga_vs -pg 1 -y 600 -defaultsOSRD
preplace port RECLRCLK -pg 1 -y 900 -defaultsOSRD
preplace port DDC -pg 1 -y 460 -defaultsOSRD
preplace portBus pmodJB_tri_out -pg 1 -y 1450 -defaultsOSRD
preplace portBus vga_b -pg 1 -y 560 -defaultsOSRD
preplace portBus pmodJB_data_out -pg 1 -y 1430 -defaultsOSRD
preplace portBus pmodJB_data_in -pg 1 -y 1590 -defaultsOSRD
preplace portBus vga_r -pg 1 -y 520 -defaultsOSRD
preplace portBus pmodJC_data_out -pg 1 -y 1220 -defaultsOSRD
preplace portBus codec_out -pg 1 -y 880 -defaultsOSRD
preplace portBus vga_g -pg 1 -y 540 -defaultsOSRD
preplace portBus pmodJC_tri_out -pg 1 -y 1240 -defaultsOSRD
preplace portBus pmodJC_data_in -pg 1 -y 1290 -defaultsOSRD
preplace portBus HDMI_OEN -pg 1 -y 640 -defaultsOSRD
preplace inst mb_2_reset -pg 1 -lvl 3 -y 1240 -defaultsOSRD -resize 140 60
preplace inst rst_processing_system7_0_100M -pg 1 -lvl 1 -y 1200 -defaultsOSRD
preplace inst swsleds_gpio -pg 1 -lvl 4 -y 1060 -defaultsOSRD
preplace inst audio -pg 1 -lvl 4 -y 920 -defaultsOSRD
preplace inst mb_1_reset -pg 1 -lvl 3 -y 1340 -defaultsOSRD -resize 140 60
preplace inst mb_JB -pg 1 -lvl 4 -y 1440 -defaultsOSRD
preplace inst mb_JC -pg 1 -lvl 4 -y 1230 -defaultsOSRD -resize 280 196
preplace inst logic_1 -pg 1 -lvl 3 -y 1540 -defaultsOSRD
preplace inst mdm_1 -pg 1 -lvl 3 -y 1440 -defaultsOSRD
preplace inst btns_gpio -pg 1 -lvl 4 -y 60 -defaultsOSRD
preplace inst video -pg 1 -lvl 4 -y 550 -defaultsOSRD
preplace inst axi_bram_ctrl_1 -pg 1 -lvl 3 -y 1140 -defaultsOSRD
preplace inst axi_bram_ctrl_2 -pg 1 -lvl 3 -y 1020 -defaultsOSRD
preplace inst rst_processing_system7_0_150M -pg 1 -lvl 3 -y 660 -defaultsOSRD
preplace inst processing_system7_0_axi_periph -pg 1 -lvl 2 -y 430 -defaultsOSRD
preplace inst processing_system7_0 -pg 1 -lvl 1 -y 860 -defaultsOSRD
preplace netloc processing_system7_0_DDR 1 1 4 NJ 760 NJ 760 NJ 760 NJ
preplace netloc processing_system7_0_axi_periph_M09_AXI 1 2 1 900
preplace netloc mb_JB_sw2pmod_tri_out 1 4 1 NJ
preplace netloc processing_system7_0_FCLK_CLK3 1 1 4 NJ 810 NJ 810 NJ 810 NJ
preplace netloc rgb2vga_0_vga_pRed 1 4 1 NJ
preplace netloc xlslice_1_Dout 1 4 1 NJ
preplace netloc processing_system7_0_axi_periph_M00_AXI 1 2 2 NJ 340 1350
preplace netloc processing_system7_0_axi_periph_M08_AXI 1 2 1 910
preplace netloc processing_system7_0_axi_periph_M03_AXI 1 2 2 NJ 400 1390
preplace netloc mb_JB_sw2pmod_data_out 1 4 1 NJ
preplace netloc processing_system7_0_GPIO_O 1 1 3 NJ 740 880 920 NJ
preplace netloc rgb2vga_0_vga_pGreen 1 4 1 NJ
preplace netloc TMDS_1 1 0 4 NJ 650 NJ 730 NJ 540 NJ
preplace netloc mdm_1_MBDEBUG_1 1 3 1 1360
preplace netloc axi_bram_ctrl_1_BRAM_PORTA 1 3 1 1310
preplace netloc processing_system7_0_axi_periph_M07_AXI 1 2 2 NJ 480 N
preplace netloc processing_system7_0_M_AXI_GP0 1 1 1 480
preplace netloc audio_PBLRCLK 1 4 1 NJ
preplace netloc rst_processing_system7_0_150M_peripheral_aresetn 1 3 1 1320
preplace netloc microblaze_0_Clk 1 0 4 20 1100 500 930 930 930 1330
preplace netloc processing_system7_0_axi_periph_M05_AXI 1 2 2 NJ 440 1280
preplace netloc mb_JC_pmodJC_tri_out 1 4 1 NJ
preplace netloc mb_1_reset_Dout 1 3 1 NJ
preplace netloc processing_system7_0_FCLK_RESET0_N 1 0 3 40 1110 560 790 940
preplace netloc axi_mem_intercon_M00_AXI 1 0 5 20 130 NJ 130 NJ 130 NJ 130 1860
preplace netloc processing_system7_0_IIC_1 1 1 4 NJ 800 NJ 800 NJ 800 NJ
preplace netloc swsleds_gpio_GPIO2 1 4 1 NJ
preplace netloc processing_system7_0_axi_periph_M02_AXI 1 2 2 N 380 NJ
preplace netloc rst_processing_system7_0_150M_interconnect_aresetn 1 3 1 1280
preplace netloc rst_processing_system7_0_100M_peripheral_aresetn 1 1 3 540 950 890 950 1360
preplace netloc dvi2rgb_0_DDC 1 4 1 NJ
preplace netloc processing_system7_0_axi_periph_M06_AXI 1 2 2 NJ 450 1310
preplace netloc mb_JC_pmodJC_data_out 1 4 1 NJ
preplace netloc xlconcat_0_dout 1 0 5 40 1080 NJ 820 NJ 820 NJ 820 1860
preplace netloc xlconstant_0_dout 1 4 1 NJ
preplace netloc axi_gpio_0_GPIO2 1 4 1 NJ
preplace netloc swsleds_gpio_GPIO 1 4 1 NJ
preplace netloc processing_system7_0_FIXED_IO 1 1 4 NJ 780 NJ 780 NJ 780 NJ
preplace netloc audio_BCLK 1 4 1 NJ
preplace netloc logic_1_dout 1 3 1 1380
preplace netloc rgb2vga_0_vga_pVSync 1 4 1 NJ
preplace netloc rgb2vga_0_vga_pHSync 1 4 1 NJ
preplace netloc axi_gpio_0_GPIO 1 4 1 NJ
preplace netloc audio_PBDATA 1 4 1 NJ
preplace netloc mdm_1_Debug_SYS_Rst 1 3 1 1290
preplace netloc rst_processing_system7_0_100M_interconnect_aresetn 1 1 3 530 940 NJ 940 NJ
preplace netloc axi_bram_ctrl_2_BRAM_PORTA 1 3 1 1320
preplace netloc microblaze_0_debug 1 3 1 1280
preplace netloc audio_RECLRCLK 1 4 1 NJ
preplace netloc pmodJC_data_in_1 1 0 4 NJ 1290 NJ 1290 NJ 1290 NJ
preplace netloc pmod2sw_data_in_1 1 0 4 NJ 1590 NJ 1590 NJ 1590 NJ
preplace netloc processing_system7_0_FCLK_CLK1 1 0 4 30 1070 510 750 930 750 1310
preplace netloc processing_system7_0_axi_periph_M04_AXI 1 2 2 NJ 420 1370
preplace netloc processing_system7_0_axi_periph_M01_AXI 1 2 2 940 40 NJ
preplace netloc RECDAT_1 1 0 4 NJ 1090 NJ 910 NJ 910 NJ
preplace netloc aux_reset_in_1 1 3 1 NJ
preplace netloc processing_system7_0_FCLK_CLK2 1 1 3 NJ 770 NJ 570 1340
preplace netloc rgb2vga_0_vga_pBlue 1 4 1 NJ
levelinfo -pg 1 0 260 730 1120 1700 1890 -top 0 -bot 1610
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
make_wrapper -files [get_files ./zybo_mipy/project_1.srcs/sources_1/bd/system/system.bd] -top

# generate toplevel wrapper files
add_files -norecurse ./zybo_mipy/project_1.srcs/sources_1/bd/system/hdl/system_wrapper.v
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

# Transform the .bit file into .bin file
write_cfgmem -format BIN -interface SMAPx32 -disablebitswap -loadbit "up 0 ./zybo_mipy/project_1.runs/impl_1/top.bit" ./zybo_mipy/project_1.runs/impl_1/audiovideo.bit.bin
