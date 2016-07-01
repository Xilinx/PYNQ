
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
set scripts_vivado_version 2015.4
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
#    create_project <project name> -part xc7z010clg400-1

# CHECKING IF PROJECT EXISTS
if { [get_projects -quiet] eq "" } {
   create_project iop_trace . -part xc7z010clg400-1
}

 
set_property  ip_repo_paths  {../ip ./trace_ip/solution1/impl/ip} [current_project]
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

# Hierarchical cell: iop1
proc create_hier_cell_iop1 { parentCell nameHier } {

  if { $parentCell eq "" || $nameHier eq "" } {
     puts "ERROR: create_hier_cell_iop1() - Empty argument(s)!"
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

  # Create instance: logic_0, and set properties
  set logic_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant:1.1 logic_0 ]
  set_property -dict [ list \
CONFIG.CONST_VAL {0} \
 ] $logic_0

  # Create instance: mb, and set properties
  set mb [ create_bd_cell -type ip -vlnv xilinx.com:ip:microblaze:9.5 mb ]
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
CONFIG.NUM_MI {6} \
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
  connect_bd_intf_net -intf_net microblaze_0_debug [get_bd_intf_pins DEBUG] [get_bd_intf_pins mb/DEBUG]
  connect_bd_intf_net -intf_net microblaze_0_dlmb_1 [get_bd_intf_pins mb/DLMB] [get_bd_intf_pins mb1_lmb/DLMB]
  connect_bd_intf_net -intf_net microblaze_0_ilmb_1 [get_bd_intf_pins mb/ILMB] [get_bd_intf_pins mb1_lmb/ILMB]

  # Create port connections
  connect_bd_net -net logic_0_dout [get_bd_pins logic_0/dout] [get_bd_pins mb1_pmod_io_switch/pwm_t_in]
  connect_bd_net -net logic_1_dout [get_bd_pins ext_reset_in] [get_bd_pins rst_clk_wiz_1_100M/ext_reset_in]
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
  connect_bd_net -net processing_system7_0_FCLK_CLK0 [get_bd_pins clk] [get_bd_pins mb/Clk] [get_bd_pins mb1_gpio/s_axi_aclk] [get_bd_pins mb1_iic/s_axi_aclk] [get_bd_pins mb1_intc/s_axi_aclk] [get_bd_pins mb1_lmb/LMB_Clk] [get_bd_pins mb1_pmod_io_switch/s00_axi_aclk] [get_bd_pins mb1_spi/ext_spi_clk] [get_bd_pins mb1_spi/s_axi_aclk] [get_bd_pins mb1_timer/s_axi_aclk] [get_bd_pins microblaze_0_axi_periph/ACLK] [get_bd_pins microblaze_0_axi_periph/M00_ACLK] [get_bd_pins microblaze_0_axi_periph/M01_ACLK] [get_bd_pins microblaze_0_axi_periph/M02_ACLK] [get_bd_pins microblaze_0_axi_periph/M03_ACLK] [get_bd_pins microblaze_0_axi_periph/M04_ACLK] [get_bd_pins microblaze_0_axi_periph/M05_ACLK] [get_bd_pins microblaze_0_axi_periph/S00_ACLK] [get_bd_pins rst_clk_wiz_1_100M/slowest_sync_clk]
  connect_bd_net -net rst_clk_wiz_1_100M_bus_struct_reset [get_bd_pins mb1_lmb/SYS_Rst] [get_bd_pins rst_clk_wiz_1_100M/bus_struct_reset]
  connect_bd_net -net rst_clk_wiz_1_100M_interconnect_aresetn [get_bd_pins microblaze_0_axi_periph/ARESETN] [get_bd_pins rst_clk_wiz_1_100M/interconnect_aresetn]
  connect_bd_net -net rst_clk_wiz_1_100M_mb_reset [get_bd_pins mb/Reset] [get_bd_pins rst_clk_wiz_1_100M/mb_reset]
  connect_bd_net -net rst_clk_wiz_1_100M_peripheral_aresetn [get_bd_pins mb1_gpio/s_axi_aresetn] [get_bd_pins mb1_iic/s_axi_aresetn] [get_bd_pins mb1_intc/s_axi_aresetn] [get_bd_pins mb1_pmod_io_switch/s00_axi_aresetn] [get_bd_pins mb1_spi/s_axi_aresetn] [get_bd_pins mb1_timer/s_axi_aresetn] [get_bd_pins microblaze_0_axi_periph/M00_ARESETN] [get_bd_pins microblaze_0_axi_periph/M01_ARESETN] [get_bd_pins microblaze_0_axi_periph/M02_ARESETN] [get_bd_pins microblaze_0_axi_periph/M03_ARESETN] [get_bd_pins microblaze_0_axi_periph/M04_ARESETN] [get_bd_pins microblaze_0_axi_periph/M05_ARESETN] [get_bd_pins microblaze_0_axi_periph/S00_ARESETN] [get_bd_pins rst_clk_wiz_1_100M/peripheral_aresetn]

  # Restore current instance
  current_bd_instance $oldCurInst
}

# Hierarchical cell: hier_tracebuffer
proc create_hier_cell_hier_tracebuffer { parentCell nameHier } {

  if { $parentCell eq "" || $nameHier eq "" } {
     puts "ERROR: create_hier_cell_hier_tracebuffer() - Empty argument(s)!"
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
  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 M_AXI_S2MM
  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S_AXI
  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S_AXI_GPIO
  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S_AXI_LITE_DMA

  # Create pins
  create_bd_pin -dir I -type clk aclk_fastclk
  create_bd_pin -dir I -type clk aclk_slowclk
  create_bd_pin -dir I -from 0 -to 0 -type rst aresetn_fastclk
  create_bd_pin -dir I -from 0 -to 0 -type rst aresetn_slowclk
  create_bd_pin -dir O -type intr s2mm_introut
  create_bd_pin -dir I -from 31 -to 0 s_axis_tdata

  # Create instance: axi_dma_0, and set properties
  set axi_dma_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_dma:7.1 axi_dma_0 ]
  set_property -dict [ list \
CONFIG.c_include_mm2s {0} \
CONFIG.c_include_sg {0} \
CONFIG.c_s2mm_burst_size {64} \
CONFIG.c_sg_include_stscntrl_strm {0} \
CONFIG.c_sg_length_width {23} \
 ] $axi_dma_0

  # Create instance: axis_accelerator_adapter_0, and set properties
  set axis_accelerator_adapter_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axis_accelerator_adapter:2.1 axis_accelerator_adapter_0 ]
  set_property -dict [ list \
CONFIG.C_N_INPUT_ARGS {0} \
CONFIG.C_N_INPUT_SCALARS {2} \
CONFIG.C_N_OUTPUT_ARGS {0} \
CONFIG.C_OARG_HAS_BRAM {0} \
 ] $axis_accelerator_adapter_0

  # Create instance: axis_clock_converter_0, and set properties
  set axis_clock_converter_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axis_clock_converter:1.1 axis_clock_converter_0 ]
  set_property -dict [ list \
CONFIG.HAS_TLAST {1} \
 ] $axis_clock_converter_0

  # Create instance: axis_data_fifo_0, and set properties
  set axis_data_fifo_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axis_data_fifo:1.1 axis_data_fifo_0 ]
  set_property -dict [ list \
CONFIG.FIFO_DEPTH {128} \
CONFIG.HAS_TLAST {1} \
CONFIG.TDATA_NUM_BYTES {4} \
 ] $axis_data_fifo_0

  # Create instance: axis_dwidth_converter_0, and set properties
  set axis_dwidth_converter_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axis_dwidth_converter:1.1 axis_dwidth_converter_0 ]
  set_property -dict [ list \
CONFIG.HAS_MI_TKEEP {1} \
CONFIG.HAS_TLAST {1} \
CONFIG.M_TDATA_NUM_BYTES {8} \
 ] $axis_dwidth_converter_0

  # Create instance: axis_switch_0, and set properties
  set axis_switch_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axis_switch:1.1 axis_switch_0 ]
  set_property -dict [ list \
CONFIG.DECODER_REG {1} \
CONFIG.NUM_MI {2} \
CONFIG.NUM_SI {1} \
 ] $axis_switch_0

  # Create instance: ila_asis_tb2dma, and set properties
  set ila_asis_tb2dma [ create_bd_cell -type ip -vlnv xilinx.com:ip:ila:6.0 ila_asis_tb2dma ]
  set_property -dict [ list \
CONFIG.C_DATA_DEPTH {2048} \
CONFIG.C_ENABLE_ILA_AXI_MON {false} \
CONFIG.C_MONITOR_TYPE {Native} \
CONFIG.C_NUM_OF_PROBES {5} \
CONFIG.C_PROBE0_WIDTH {64} \
 ] $ila_asis_tb2dma

  # Create instance: ila_hls2switch, and set properties
  set ila_hls2switch [ create_bd_cell -type ip -vlnv xilinx.com:ip:ila:6.0 ila_hls2switch ]
  set_property -dict [ list \
CONFIG.C_ENABLE_ILA_AXI_MON {false} \
CONFIG.C_MONITOR_TYPE {Native} \
CONFIG.C_NUM_OF_PROBES {5} \
CONFIG.C_PROBE0_WIDTH {32} \
 ] $ila_hls2switch

  # Create instance: trace_controller_0, and set properties
  set trace_controller_0 [ create_bd_cell -type ip -vlnv xilinx.com:hls:trace_controller:1.0 trace_controller_0 ]

  # Create instance: xlconcat_2, and set properties
  set xlconcat_2 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconcat:2.1 xlconcat_2 ]

  # Create instance: xlconstant0_1b_1, and set properties
  set xlconstant0_1b_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant:1.1 xlconstant0_1b_1 ]
  set_property -dict [ list \
CONFIG.CONST_VAL {1} \
CONFIG.CONST_WIDTH {1} \
 ] $xlconstant0_1b_1

  # Create instance: xlconstant_1b_1, and set properties
  set xlconstant_1b_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant:1.1 xlconstant_1b_1 ]

  # Create interface connections
  connect_bd_intf_net -intf_net Conn1 [get_bd_intf_pins S_AXI] [get_bd_intf_pins axis_accelerator_adapter_0/S_AXI]
  connect_bd_intf_net -intf_net axi_dma_0_M_AXI_S2MM1 [get_bd_intf_pins M_AXI_S2MM] [get_bd_intf_pins axi_dma_0/M_AXI_S2MM]
  connect_bd_intf_net -intf_net axis_accelerator_adapter_0_AP_CTRL [get_bd_intf_pins axis_accelerator_adapter_0/AP_CTRL] [get_bd_intf_pins trace_controller_0/ap_ctrl]
  connect_bd_intf_net -intf_net axis_clock_converter_0_M_AXIS [get_bd_intf_pins axi_dma_0/S_AXIS_S2MM] [get_bd_intf_pins axis_clock_converter_0/M_AXIS]
  connect_bd_intf_net -intf_net axis_data_fifo_0_M_AXIS [get_bd_intf_pins axis_data_fifo_0/M_AXIS] [get_bd_intf_pins axis_dwidth_converter_0/S_AXIS]
  connect_bd_intf_net -intf_net axis_dwidth_converter_0_M_AXIS [get_bd_intf_pins axis_clock_converter_0/S_AXIS] [get_bd_intf_pins axis_dwidth_converter_0/M_AXIS]
  connect_bd_intf_net -intf_net axis_switch_0_M00_AXIS [get_bd_intf_pins axis_data_fifo_0/S_AXIS] [get_bd_intf_pins axis_switch_0/M00_AXIS]
  connect_bd_intf_net -intf_net processing_system7_0_axi_periph_M04_AXI [get_bd_intf_pins S_AXI_LITE_DMA] [get_bd_intf_pins axi_dma_0/S_AXI_LITE]
  connect_bd_intf_net -intf_net trace_controller_0_B [get_bd_intf_pins axis_switch_0/S00_AXIS] [get_bd_intf_pins trace_controller_0/B]

  # Create port connections
  connect_bd_net -net Net [get_bd_pins axi_dma_0/s_axis_s2mm_tready] [get_bd_pins axis_clock_converter_0/m_axis_tready] [get_bd_pins ila_asis_tb2dma/probe2]
  connect_bd_net -net Net1 [get_bd_pins axis_switch_0/s_axis_tdata] [get_bd_pins ila_hls2switch/probe0] [get_bd_pins trace_controller_0/B_TDATA]
  connect_bd_net -net Net2 [get_bd_pins axis_switch_0/s_axis_tvalid] [get_bd_pins ila_hls2switch/probe1] [get_bd_pins trace_controller_0/B_TVALID]
  connect_bd_net -net Net3 [get_bd_pins axis_switch_0/s_axis_tlast] [get_bd_pins ila_hls2switch/probe3] [get_bd_pins trace_controller_0/B_TLAST]
  connect_bd_net -net Net4 [get_bd_pins axis_switch_0/s_axis_tdest] [get_bd_pins ila_hls2switch/probe4] [get_bd_pins trace_controller_0/B_TDEST]
  connect_bd_net -net aresetn_fastclk_1 [get_bd_pins aresetn_fastclk] [get_bd_pins axis_clock_converter_0/m_axis_aresetn]
  connect_bd_net -net aresetn_slowclk_1 [get_bd_pins aresetn_slowclk] [get_bd_pins axi_dma_0/axi_resetn] [get_bd_pins axis_accelerator_adapter_0/s_axi_aresetn] [get_bd_pins axis_clock_converter_0/s_axis_aresetn] [get_bd_pins axis_data_fifo_0/s_axis_aresetn] [get_bd_pins axis_dwidth_converter_0/aresetn] [get_bd_pins axis_switch_0/aresetn]
  connect_bd_net -net axi_dma_0_s2mm_introut [get_bd_pins s2mm_introut] [get_bd_pins axi_dma_0/s2mm_introut] [get_bd_pins ila_asis_tb2dma/probe4]
  connect_bd_net -net axis_accelerator_adapter_0_ap_iscalar_0_dout [get_bd_pins axis_accelerator_adapter_0/ap_iscalar_0_dout] [get_bd_pins trace_controller_0/length_r]
  connect_bd_net -net axis_accelerator_adapter_0_ap_iscalar_1_dout [get_bd_pins axis_accelerator_adapter_0/ap_iscalar_1_dout] [get_bd_pins trace_controller_0/sample_rate]
  connect_bd_net -net axis_accelerator_adapter_0_aresetn [get_bd_pins axis_accelerator_adapter_0/aresetn] [get_bd_pins trace_controller_0/ap_rst_n]
  connect_bd_net -net axis_clock_converter_0_m_axis_tdata [get_bd_pins axi_dma_0/s_axis_s2mm_tdata] [get_bd_pins axis_clock_converter_0/m_axis_tdata] [get_bd_pins ila_asis_tb2dma/probe0]
  connect_bd_net -net axis_clock_converter_0_m_axis_tlast [get_bd_pins axi_dma_0/s_axis_s2mm_tlast] [get_bd_pins axis_clock_converter_0/m_axis_tlast] [get_bd_pins ila_asis_tb2dma/probe3]
  connect_bd_net -net axis_clock_converter_0_m_axis_tvalid [get_bd_pins axi_dma_0/s_axis_s2mm_tvalid] [get_bd_pins axis_clock_converter_0/m_axis_tvalid] [get_bd_pins ila_asis_tb2dma/probe1]
  connect_bd_net -net axis_data_fifo_0_s_axis_tready [get_bd_pins axis_data_fifo_0/s_axis_tready] [get_bd_pins xlconcat_2/In0]
  connect_bd_net -net axis_switch_0_s_axis_tready [get_bd_pins axis_switch_0/s_axis_tready] [get_bd_pins ila_hls2switch/probe2] [get_bd_pins trace_controller_0/B_TREADY]
  connect_bd_net -net processing_system7_0_FCLK_CLK0 [get_bd_pins aclk_slowclk] [get_bd_pins axi_dma_0/s_axi_lite_aclk] [get_bd_pins axis_accelerator_adapter_0/aclk] [get_bd_pins axis_accelerator_adapter_0/s_axi_aclk] [get_bd_pins axis_clock_converter_0/s_axis_aclk] [get_bd_pins axis_data_fifo_0/s_axis_aclk] [get_bd_pins axis_dwidth_converter_0/aclk] [get_bd_pins axis_switch_0/aclk] [get_bd_pins ila_hls2switch/clk] [get_bd_pins trace_controller_0/ap_clk]
  connect_bd_net -net processing_system7_0_FCLK_CLK2 [get_bd_pins aclk_fastclk] [get_bd_pins axi_dma_0/m_axi_s2mm_aclk] [get_bd_pins axis_clock_converter_0/m_axis_aclk] [get_bd_pins ila_asis_tb2dma/clk]
  connect_bd_net -net s_axis_tdata_1 [get_bd_pins s_axis_tdata] [get_bd_pins trace_controller_0/A_TDATA]
  connect_bd_net -net xlconcat_2_dout [get_bd_pins axis_switch_0/m_axis_tready] [get_bd_pins xlconcat_2/dout]
  connect_bd_net -net xlconstant0_1b_1_dout [get_bd_pins xlconcat_2/In1] [get_bd_pins xlconstant0_1b_1/dout]
  connect_bd_net -net xlconstant_1b_1_dout [get_bd_pins trace_controller_0/A_TVALID] [get_bd_pins xlconstant_1b_1/dout]

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

  # Create instance: axi_hp3_intercon, and set properties
  set axi_hp3_intercon [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_interconnect:2.1 axi_hp3_intercon ]
  set_property -dict [ list \
CONFIG.NUM_MI {1} \
CONFIG.NUM_SI {1} \
CONFIG.S00_HAS_REGSLICE {1} \
 ] $axi_hp3_intercon

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

  # Create instance: hier_tracebuffer
  create_hier_cell_hier_tracebuffer [current_bd_instance .] hier_tracebuffer

  # Create instance: ila_aximm_dma2hp3, and set properties
  set ila_aximm_dma2hp3 [ create_bd_cell -type ip -vlnv xilinx.com:ip:ila:6.0 ila_aximm_dma2hp3 ]

  # Create instance: iop1
  create_hier_cell_iop1 [current_bd_instance .] iop1

  # Create instance: logic_1, and set properties
  set logic_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant:1.1 logic_1 ]

  # Create instance: mb_1_reset, and set properties
  set mb_1_reset [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice:1.0 mb_1_reset ]
  set_property -dict [ list \
CONFIG.DIN_FROM {0} \
CONFIG.DIN_TO {0} \
CONFIG.DIN_WIDTH {6} \
 ] $mb_1_reset

  # Create instance: mb_bram_ctrl_1, and set properties
  set mb_bram_ctrl_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_bram_ctrl:4.0 mb_bram_ctrl_1 ]
  set_property -dict [ list \
CONFIG.SINGLE_PORT_BRAM {1} \
 ] $mb_bram_ctrl_1

  # Create instance: mdm_1, and set properties
  set mdm_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:mdm:3.2 mdm_1 ]
  set_property -dict [ list \
CONFIG.C_MB_DBG_PORTS {1} \
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
CONFIG.PCW_EN_CLK2_PORT {1} \
CONFIG.PCW_FPGA0_PERIPHERAL_FREQMHZ {100} \
CONFIG.PCW_FPGA2_PERIPHERAL_FREQMHZ {200} \
CONFIG.PCW_GPIO_EMIO_GPIO_ENABLE {1} \
CONFIG.PCW_GPIO_EMIO_GPIO_IO {6} \
CONFIG.PCW_GPIO_MIO_GPIO_ENABLE {0} \
CONFIG.PCW_I2C1_PERIPHERAL_ENABLE {1} \
CONFIG.PCW_IRQ_F2P_INTR {1} \
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
CONFIG.PCW_USE_FABRIC_INTERRUPT {1} \
CONFIG.PCW_USE_S_AXI_HP3 {1} \
 ] $processing_system7_0

  # Create instance: processing_system7_0_axi_periph, and set properties
  set processing_system7_0_axi_periph [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_interconnect:2.1 processing_system7_0_axi_periph ]
  set_property -dict [ list \
CONFIG.NUM_MI {8} \
 ] $processing_system7_0_axi_periph

  # Create instance: rst_processing_system7_0_100M, and set properties
  set rst_processing_system7_0_100M [ create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset:5.0 rst_processing_system7_0_100M ]

  # Create instance: rst_processing_system7_0_200M, and set properties
  set rst_processing_system7_0_200M [ create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset:5.0 rst_processing_system7_0_200M ]

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

  # Create instance: xlconcat_1, and set properties
  set xlconcat_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconcat:2.1 xlconcat_1 ]
  set_property -dict [ list \
CONFIG.IN0_WIDTH {8} \
CONFIG.IN1_WIDTH {8} \
CONFIG.IN2_WIDTH {8} \
CONFIG.IN3_WIDTH {8} \
CONFIG.NUM_PORTS {4} \
 ] $xlconcat_1

  # Create instance: xlconstant_8b_0, and set properties
  set xlconstant_8b_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant:1.1 xlconstant_8b_0 ]
  set_property -dict [ list \
CONFIG.CONST_VAL {0} \
CONFIG.CONST_WIDTH {8} \
 ] $xlconstant_8b_0

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
  connect_bd_intf_net -intf_net axi_mem_intercon_M00_AXI [get_bd_intf_pins axi_hp3_intercon/M00_AXI] [get_bd_intf_pins processing_system7_0/S_AXI_HP3]
  connect_bd_intf_net -intf_net btns_gpio_GPIO [get_bd_intf_ports btns_4bits] [get_bd_intf_pins btns_gpio/GPIO]
  connect_bd_intf_net -intf_net hier_tracebuffer_M_AXI_S2MM [get_bd_intf_pins axi_hp3_intercon/S00_AXI] [get_bd_intf_pins hier_tracebuffer/M_AXI_S2MM]
connect_bd_intf_net -intf_net [get_bd_intf_nets hier_tracebuffer_M_AXI_S2MM] [get_bd_intf_pins hier_tracebuffer/M_AXI_S2MM] [get_bd_intf_pins ila_aximm_dma2hp3/SLOT_0_AXI]
  connect_bd_intf_net -intf_net mb_bram_ctrl_1_BRAM_PORTA [get_bd_intf_pins iop1/BRAM_PORTB] [get_bd_intf_pins mb_bram_ctrl_1/BRAM_PORTA]
  connect_bd_intf_net -intf_net microblaze_0_debug [get_bd_intf_pins iop1/DEBUG] [get_bd_intf_pins mdm_1/MBDEBUG_0]
  connect_bd_intf_net -intf_net processing_system7_0_DDR [get_bd_intf_ports DDR] [get_bd_intf_pins processing_system7_0/DDR]
  connect_bd_intf_net -intf_net processing_system7_0_FIXED_IO [get_bd_intf_ports FIXED_IO] [get_bd_intf_pins processing_system7_0/FIXED_IO]
  connect_bd_intf_net -intf_net processing_system7_0_IIC_1 [get_bd_intf_ports IIC_1] [get_bd_intf_pins processing_system7_0/IIC_1]
  connect_bd_intf_net -intf_net processing_system7_0_M_AXI_GP0 [get_bd_intf_pins processing_system7_0/M_AXI_GP0] [get_bd_intf_pins processing_system7_0_axi_periph/S00_AXI]
  connect_bd_intf_net -intf_net processing_system7_0_axi_periph_M00_AXI [get_bd_intf_pins processing_system7_0_axi_periph/M00_AXI] [get_bd_intf_pins swsleds_gpio/S_AXI]
  connect_bd_intf_net -intf_net processing_system7_0_axi_periph_M01_AXI [get_bd_intf_pins btns_gpio/S_AXI] [get_bd_intf_pins processing_system7_0_axi_periph/M01_AXI]
  connect_bd_intf_net -intf_net processing_system7_0_axi_periph_M02_AXI [get_bd_intf_pins mb_bram_ctrl_1/S_AXI] [get_bd_intf_pins processing_system7_0_axi_periph/M02_AXI]
  connect_bd_intf_net -intf_net processing_system7_0_axi_periph_M03_AXI [get_bd_intf_pins hier_tracebuffer/S_AXI_GPIO] [get_bd_intf_pins processing_system7_0_axi_periph/M03_AXI]
  connect_bd_intf_net -intf_net processing_system7_0_axi_periph_M04_AXI [get_bd_intf_pins hier_tracebuffer/S_AXI_LITE_DMA] [get_bd_intf_pins processing_system7_0_axi_periph/M04_AXI]
  connect_bd_intf_net -intf_net processing_system7_0_axi_periph_M05_AXI [get_bd_intf_pins hier_tracebuffer/S_AXI] [get_bd_intf_pins processing_system7_0_axi_periph/M05_AXI]
  connect_bd_intf_net -intf_net processing_system7_0_axi_periph_M06_AXI [get_bd_intf_pins axi_traceBuffer_v1_0_0/s00_axi] [get_bd_intf_pins processing_system7_0_axi_periph/M06_AXI]
  connect_bd_intf_net -intf_net processing_system7_0_axi_periph_M07_AXI [get_bd_intf_pins processing_system7_0_axi_periph/M07_AXI] [get_bd_intf_pins xadc_wiz_0/s_axi_lite]
  connect_bd_intf_net -intf_net swsleds_gpio_GPIO [get_bd_intf_ports sws_4bits] [get_bd_intf_pins swsleds_gpio/GPIO]
  connect_bd_intf_net -intf_net swsleds_gpio_GPIO2 [get_bd_intf_ports leds_4bits] [get_bd_intf_pins swsleds_gpio/GPIO2]

  # Create port connections
  connect_bd_net -net ARESETN_1 [get_bd_pins axi_hp3_intercon/ARESETN] [get_bd_pins rst_processing_system7_0_200M/interconnect_aresetn]
  connect_bd_net -net M00_ARESETN_1 [get_bd_pins axi_hp3_intercon/M00_ARESETN] [get_bd_pins axi_hp3_intercon/S00_ARESETN] [get_bd_pins hier_tracebuffer/aresetn_fastclk] [get_bd_pins rst_processing_system7_0_200M/peripheral_aresetn]
  connect_bd_net -net bit8_logic_0_dout [get_bd_pins bit8_logic_0/dout] [get_bd_pins xlconcat_0/In2] [get_bd_pins xlconcat_0/In3] [get_bd_pins xup_mux_data_out/b] [get_bd_pins xup_mux_data_out/c] [get_bd_pins xup_mux_data_out/d] [get_bd_pins xup_mux_tri_out/b] [get_bd_pins xup_mux_tri_out/c] [get_bd_pins xup_mux_tri_out/d]
  connect_bd_net -net hier_tracebuffer_s2mm_introut [get_bd_pins hier_tracebuffer/s2mm_introut] [get_bd_pins processing_system7_0/IRQ_F2P]
  connect_bd_net -net logic_1_dout [get_bd_pins iop1/ext_reset_in] [get_bd_pins logic_1/dout]
  connect_bd_net -net mb_1_reset_Dout [get_bd_pins iop1/aux_reset_in] [get_bd_pins mb_1_reset/Dout]
  connect_bd_net -net mdm_1_debug_sys_rst [get_bd_pins iop1/mb_debug_sys_rst] [get_bd_pins mdm_1/Debug_SYS_Rst]
  connect_bd_net -net pmod2sw_data_in_1 [get_bd_ports pmodJB_data_in] [get_bd_pins iop1/pmod2sw_data_in] [get_bd_pins xlconcat_1/In1]
  connect_bd_net -net pmod_io_switch_0_sw2pmod_data_out [get_bd_ports pmodJB_data_out] [get_bd_pins iop1/sw2pmod_data_out] [get_bd_pins xlconcat_1/In0] [get_bd_pins xup_mux_data_out/a]
  connect_bd_net -net pmod_io_switch_0_sw2pmod_tri_out [get_bd_ports pmodJB_tri_out] [get_bd_pins iop1/sw2pmod_tri_out] [get_bd_pins xlconcat_1/In2] [get_bd_pins xup_mux_tri_out/a]
  connect_bd_net -net processing_system7_0_FCLK_CLK0 [get_bd_pins axi_traceBuffer_v1_0_0/s00_axi_aclk] [get_bd_pins btns_gpio/s_axi_aclk] [get_bd_pins hier_tracebuffer/aclk_slowclk] [get_bd_pins iop1/clk] [get_bd_pins mb_bram_ctrl_1/s_axi_aclk] [get_bd_pins processing_system7_0/FCLK_CLK0] [get_bd_pins processing_system7_0/M_AXI_GP0_ACLK] [get_bd_pins processing_system7_0_axi_periph/ACLK] [get_bd_pins processing_system7_0_axi_periph/M00_ACLK] [get_bd_pins processing_system7_0_axi_periph/M01_ACLK] [get_bd_pins processing_system7_0_axi_periph/M02_ACLK] [get_bd_pins processing_system7_0_axi_periph/M03_ACLK] [get_bd_pins processing_system7_0_axi_periph/M04_ACLK] [get_bd_pins processing_system7_0_axi_periph/M05_ACLK] [get_bd_pins processing_system7_0_axi_periph/M06_ACLK] [get_bd_pins processing_system7_0_axi_periph/M07_ACLK] [get_bd_pins processing_system7_0_axi_periph/S00_ACLK] [get_bd_pins rst_processing_system7_0_100M/slowest_sync_clk] [get_bd_pins swsleds_gpio/s_axi_aclk] [get_bd_pins xadc_wiz_0/s_axi_aclk]
  connect_bd_net -net processing_system7_0_FCLK_CLK2 [get_bd_pins axi_hp3_intercon/ACLK] [get_bd_pins axi_hp3_intercon/M00_ACLK] [get_bd_pins axi_hp3_intercon/S00_ACLK] [get_bd_pins hier_tracebuffer/aclk_fastclk] [get_bd_pins ila_aximm_dma2hp3/clk] [get_bd_pins processing_system7_0/FCLK_CLK2] [get_bd_pins processing_system7_0/S_AXI_HP3_ACLK] [get_bd_pins rst_processing_system7_0_200M/slowest_sync_clk]
  connect_bd_net -net processing_system7_0_FCLK_RESET0_N [get_bd_pins processing_system7_0/FCLK_RESET0_N] [get_bd_pins rst_processing_system7_0_100M/ext_reset_in] [get_bd_pins rst_processing_system7_0_200M/ext_reset_in]
  connect_bd_net -net processing_system7_0_GPIO_O [get_bd_pins mb_1_reset/Din] [get_bd_pins processing_system7_0/GPIO_O] [get_bd_pins tracebuffer_sel/Din]
  connect_bd_net -net rst_processing_system7_0_100M_interconnect_aresetn [get_bd_pins processing_system7_0_axi_periph/ARESETN] [get_bd_pins rst_processing_system7_0_100M/interconnect_aresetn]
  connect_bd_net -net rst_processing_system7_0_100M_peripheral_aresetn [get_bd_pins axi_traceBuffer_v1_0_0/s00_axi_aresetn] [get_bd_pins btns_gpio/s_axi_aresetn] [get_bd_pins hier_tracebuffer/aresetn_slowclk] [get_bd_pins mb_bram_ctrl_1/s_axi_aresetn] [get_bd_pins processing_system7_0_axi_periph/M00_ARESETN] [get_bd_pins processing_system7_0_axi_periph/M01_ARESETN] [get_bd_pins processing_system7_0_axi_periph/M02_ARESETN] [get_bd_pins processing_system7_0_axi_periph/M03_ARESETN] [get_bd_pins processing_system7_0_axi_periph/M04_ARESETN] [get_bd_pins processing_system7_0_axi_periph/M05_ARESETN] [get_bd_pins processing_system7_0_axi_periph/M06_ARESETN] [get_bd_pins processing_system7_0_axi_periph/M07_ARESETN] [get_bd_pins processing_system7_0_axi_periph/S00_ARESETN] [get_bd_pins rst_processing_system7_0_100M/peripheral_aresetn] [get_bd_pins swsleds_gpio/s_axi_aresetn] [get_bd_pins xadc_wiz_0/s_axi_aresetn]
  connect_bd_net -net tracebuffer_sel_Dout [get_bd_pins tracebuffer_sel/Dout] [get_bd_pins xup_mux_data_out/sel] [get_bd_pins xup_mux_tri_out/sel]
  connect_bd_net -net xlconcat_0_dout [get_bd_pins axi_traceBuffer_v1_0_0/MONITOR_DATAIN] [get_bd_pins xlconcat_0/dout]
  connect_bd_net -net xlconcat_1_dout [get_bd_pins hier_tracebuffer/s_axis_tdata] [get_bd_pins xlconcat_1/dout]
  connect_bd_net -net xlconstant_8b_0_dout [get_bd_pins xlconcat_1/In3] [get_bd_pins xlconstant_8b_0/dout]
  connect_bd_net -net xup_mux_data_out_y [get_bd_pins xlconcat_0/In0] [get_bd_pins xup_mux_data_out/y]
  connect_bd_net -net xup_mux_tri_out_y [get_bd_pins xlconcat_0/In1] [get_bd_pins xup_mux_tri_out/y]

  # Create address segments
  create_bd_addr_seg -range 0x10000 -offset 0x40400000 [get_bd_addr_spaces processing_system7_0/Data] [get_bd_addr_segs hier_tracebuffer/axi_dma_0/S_AXI_LITE/Reg] SEG_axi_dma_0_Reg
  create_bd_addr_seg -range 0x10000 -offset 0x43C00000 [get_bd_addr_spaces processing_system7_0/Data] [get_bd_addr_segs axi_traceBuffer_v1_0_0/s00_axi/reg0] SEG_axi_traceBuffer_v1_0_0_reg0
  create_bd_addr_seg -range 0x10000 -offset 0x43C20000 [get_bd_addr_spaces processing_system7_0/Data] [get_bd_addr_segs hier_tracebuffer/axis_accelerator_adapter_0/S_AXI/Reg] SEG_axis_accelerator_adapter_0_Reg
  create_bd_addr_seg -range 0x10000 -offset 0x41210000 [get_bd_addr_spaces processing_system7_0/Data] [get_bd_addr_segs btns_gpio/S_AXI/Reg] SEG_btns_gpio_Reg
  create_bd_addr_seg -range 0x8000 -offset 0x40000000 [get_bd_addr_spaces processing_system7_0/Data] [get_bd_addr_segs mb_bram_ctrl_1/S_AXI/Mem0] SEG_mb_bram_ctrl_1_Mem0
  create_bd_addr_seg -range 0x10000 -offset 0x41200000 [get_bd_addr_spaces processing_system7_0/Data] [get_bd_addr_segs swsleds_gpio/S_AXI/Reg] SEG_swsleds_gpio_Reg
  create_bd_addr_seg -range 0x10000 -offset 0x43C10000 [get_bd_addr_spaces processing_system7_0/Data] [get_bd_addr_segs xadc_wiz_0/s_axi_lite/Reg] SEG_xadc_wiz_0_Reg
  create_bd_addr_seg -range 0x20000000 -offset 0x0 [get_bd_addr_spaces hier_tracebuffer/axi_dma_0/Data_S2MM] [get_bd_addr_segs processing_system7_0/S_AXI_HP3/HP3_DDR_LOWOCM] SEG_processing_system7_0_HP3_DDR_LOWOCM
  create_bd_addr_seg -range 0x10000 -offset 0x40000000 [get_bd_addr_spaces iop1/mb/Data] [get_bd_addr_segs iop1/mb1_gpio/S_AXI/Reg] SEG_axi_gpio_0_Reg
  create_bd_addr_seg -range 0x10000 -offset 0x40800000 [get_bd_addr_spaces iop1/mb/Data] [get_bd_addr_segs iop1/mb1_iic/S_AXI/Reg] SEG_axi_iic_0_Reg
  create_bd_addr_seg -range 0x10000 -offset 0x44A10000 [get_bd_addr_spaces iop1/mb/Data] [get_bd_addr_segs iop1/mb1_spi/AXI_LITE/Reg] SEG_axi_quad_spi_0_Reg
  create_bd_addr_seg -range 0x8000 -offset 0x0 [get_bd_addr_spaces iop1/mb/Instruction] [get_bd_addr_segs iop1/mb1_lmb/lmb_bram_if_cntlr/SLMB/Mem] SEG_ilmb_bram_if_cntlr_Mem
  create_bd_addr_seg -range 0x8000 -offset 0x0 [get_bd_addr_spaces iop1/mb/Data] [get_bd_addr_segs iop1/mb1_lmb/lmb_bram_if_cntlr/SLMB1/Mem] SEG_lmb_bram_if_cntlr_Mem
  create_bd_addr_seg -range 0x10000 -offset 0x41200000 [get_bd_addr_spaces iop1/mb/Data] [get_bd_addr_segs iop1/mb1_intc/s_axi/Reg] SEG_mb1_intc_Reg
  create_bd_addr_seg -range 0x10000 -offset 0x41C00000 [get_bd_addr_spaces iop1/mb/Data] [get_bd_addr_segs iop1/mb1_timer/S_AXI/Reg] SEG_mb1_timer_Reg
  create_bd_addr_seg -range 0x10000 -offset 0x44A00000 [get_bd_addr_spaces iop1/mb/Data] [get_bd_addr_segs iop1/mb1_pmod_io_switch/S00_AXI/S00_AXI_reg] SEG_pmod_io_switch_0_S00_AXI_reg

  # Perform GUI Layout
  regenerate_bd_layout -layout_string {
   guistr: "# # String gsaved with Nlview 6.5.5  2015-06-26 bk=1.3371 VDI=38 GEI=35 GUI=JA:1.8
#  -string -flagsOSRD
preplace port btns_4bits -pg 1 -y 1340 -defaultsOSRD
preplace port DDR -pg 1 -y 80 -defaultsOSRD
preplace port Vp_Vn -pg 1 -y 980 -defaultsOSRD
preplace port sws_4bits -pg 1 -y 1010 -defaultsOSRD
preplace port leds_4bits -pg 1 -y 1030 -defaultsOSRD
preplace port FIXED_IO -pg 1 -y 100 -defaultsOSRD
preplace port Vaux6 -pg 1 -y 460 -defaultsOSRD
preplace port IIC_1 -pg 1 -y 120 -defaultsOSRD
preplace port Vaux14 -pg 1 -y 1020 -defaultsOSRD
preplace port Vaux7 -pg 1 -y 1000 -defaultsOSRD
preplace port Vaux15 -pg 1 -y 1040 -defaultsOSRD
preplace portBus pmodJB_tri_out -pg 1 -y 1620 -defaultsOSRD
preplace portBus pmodJB_data_out -pg 1 -y 1470 -defaultsOSRD
preplace portBus pmodJB_data_in -pg 1 -y 1960 -defaultsOSRD
preplace inst hier_tracebuffer -pg 1 -lvl 3 -y -240 -defaultsOSRD
preplace inst xlconstant_8b_0 -pg 1 -lvl 2 -y -1040 -defaultsOSRD
preplace inst rst_processing_system7_0_100M -pg 1 -lvl 6 -y 610 -defaultsOSRD
preplace inst hier_tracebuffer|xlconcat_2 -pg 1 -lvl 3 -y 160 -defaultsOSRD
preplace inst hier_tracebuffer|xlconstant0_1b_1 -pg 1 -lvl 3 -y -230 -defaultsOSRD
preplace inst hier_tracebuffer|xlconstant_1b_1 -pg 1 -lvl 1 -y -130 -defaultsOSRD
preplace inst hier_tracebuffer|axis_clock_converter_0 -pg 1 -lvl 6 -y 220 -defaultsOSRD
preplace inst rst_processing_system7_0_200M -pg 1 -lvl 6 -y 840 -defaultsOSRD
preplace inst xadc_wiz_0 -pg 1 -lvl 8 -y 1998 -defaultsOSRD
preplace inst swsleds_gpio -pg 1 -lvl 9 -y 1020 -defaultsOSRD
preplace inst mb_1_reset -pg 1 -lvl 9 -y 1770 -defaultsOSRD
preplace inst iop1 -pg 1 -lvl 9 -y 1580 -defaultsOSRD
preplace inst bit8_logic_0 -pg 1 -lvl 6 -y 1870 -defaultsOSRD
preplace inst xup_mux_tri_out -pg 1 -lvl 6 -y 2010 -defaultsOSRD -resize 220 140
preplace inst xlconcat_0 -pg 1 -lvl 7 -y 1670 -defaultsOSRD
preplace inst logic_1 -pg 1 -lvl 9 -y 1880 -defaultsOSRD
preplace inst xlconcat_1 -pg 1 -lvl 1 -y -890 -defaultsOSRD
preplace inst hier_tracebuffer|axis_accelerator_adapter_0 -pg 1 -lvl 1 -y 10 -defaultsOSRD
preplace inst hier_tracebuffer|axi_dma_0 -pg 1 -lvl 7 -y 190 -defaultsOSRD
preplace inst mdm_1 -pg 1 -lvl 9 -y 1990 -defaultsOSRD
preplace inst hier_tracebuffer|axis_switch_0 -pg 1 -lvl 3 -y -20 -defaultsOSRD
preplace inst hier_tracebuffer|axis_dwidth_converter_0 -pg 1 -lvl 5 -y 20 -defaultsOSRD
preplace inst xup_mux_data_out -pg 1 -lvl 6 -y 1650 -defaultsOSRD
preplace inst btns_gpio -pg 1 -lvl 9 -y 1340 -defaultsOSRD
preplace inst hier_tracebuffer|ila_hls2switch -pg 1 -lvl 4 -y -250 -defaultsOSRD
preplace inst hier_tracebuffer|ila_asis_tb2dma -pg 1 -lvl 8 -y 360 -defaultsOSRD
preplace inst mb_bram_ctrl_1 -pg 1 -lvl 9 -y 1150 -defaultsOSRD
preplace inst axi_hp3_intercon -pg 1 -lvl 4 -y -730 -defaultsOSRD
preplace inst tracebuffer_sel -pg 1 -lvl 5 -y 1710 -defaultsOSRD
preplace inst hier_tracebuffer|trace_controller_0 -pg 1 -lvl 2 -y -50 -defaultsOSRD
preplace inst ila_aximm_dma2hp3 -pg 1 -lvl 4 -y -550 -defaultsOSRD
preplace inst hier_tracebuffer|axis_data_fifo_0 -pg 1 -lvl 4 -y 110 -defaultsOSRD
preplace inst processing_system7_0_axi_periph -pg 1 -lvl 7 -y 440 -defaultsOSRD
preplace inst processing_system7_0 -pg 1 -lvl 3 -y 1160 -defaultsOSRD
preplace inst axi_traceBuffer_v1_0_0 -pg 1 -lvl 8 -y 2198 -defaultsOSRD
preplace netloc hier_tracebuffer|xlconcat_2_dout 1 3 1 1360
preplace netloc hier_tracebuffer|axis_clock_converter_0_m_axis_tlast 1 6 2 2390 390 NJ
preplace netloc xup_mux_data_out_y 1 6 1 NJ
preplace netloc processing_system7_0_FIXED_IO 1 3 7 NJ 100 NJ 100 NJ 100 NJ 100 NJ 100 NJ 100 NJ
preplace netloc hier_tracebuffer|axis_dwidth_converter_0_M_AXIS 1 5 1 2020
preplace netloc swsleds_gpio_GPIO2 1 9 1 N
preplace netloc hier_tracebuffer|axis_accelerator_adapter_0_ap_iscalar_1_dout 1 1 1 520
preplace netloc xlconcat_1_dout 1 1 2 NJ -890 -310
preplace netloc hier_tracebuffer|axis_accelerator_adapter_0_aresetn 1 1 1 520
preplace netloc hier_tracebuffer|axis_clock_converter_0_m_axis_tvalid 1 6 2 2350 350 NJ
preplace netloc xlconcat_0_dout 1 7 1 10320
preplace netloc bit8_logic_0_dout 1 5 2 NJ 1740 NJ
preplace netloc hier_tracebuffer|Conn1 1 0 1 180
preplace netloc processing_system7_0_axi_periph_M06_AXI 1 7 1 10380
preplace netloc processing_system7_0_DDR 1 3 7 NJ 80 NJ 80 NJ 80 NJ 80 NJ 80 NJ 80 NJ
preplace netloc hier_tracebuffer|processing_system7_0_FCLK_CLK0 1 0 7 200 -200 530 -170 940 -310 1400 -50 1800 -50 2010 100 NJ
preplace netloc hier_tracebuffer|processing_system7_0_FCLK_CLK2 1 0 8 NJ 260 NJ 260 NJ 220 NJ 480 NJ 260 2040 130 2360 320 NJ
preplace netloc Vaux15_1 1 0 8 NJ 1040 NJ 1040 NJ 1320 NJ 1320 NJ 1320 NJ 1320 NJ 1320 NJ
preplace netloc processing_system7_0_axi_periph_M05_AXI 1 2 6 NJ 530 NJ 160 NJ 160 NJ 160 NJ 160 10320
preplace netloc hier_tracebuffer|axis_clock_converter_0_M_AXIS 1 6 1 2370
preplace netloc mdm_1_debug_sys_rst 1 8 2 10730 1460 11140
preplace netloc hier_tracebuffer|Net1 1 2 2 930 -330 NJ
preplace netloc processing_system7_0_FCLK_RESET0_N 1 3 3 NJ 820 NJ 820 NJ
preplace netloc hier_tracebuffer|axi_dma_0_M_AXI_S2MM1 1 7 2 N 170 NJ
preplace netloc hier_tracebuffer|axis_switch_0_M00_AXIS 1 3 1 1370
preplace netloc hier_tracebuffer|axis_accelerator_adapter_0_ap_iscalar_0_dout 1 1 1 530
preplace netloc hier_tracebuffer|Net2 1 2 2 960 -320 NJ
preplace netloc hier_tracebuffer|Net3 1 2 2 920 -180 NJ
preplace netloc hier_tracebuffer|axis_clock_converter_0_m_axis_tdata 1 6 2 2410 330 NJ
preplace netloc processing_system7_0_axi_periph_M02_AXI 1 7 2 NJ 410 NJ
preplace netloc xlconstant_8b_0_dout 1 0 3 -690 -810 N -810 NJ
preplace netloc processing_system7_0_axi_periph_M03_AXI 1 2 6 NJ 540 NJ 130 NJ 130 NJ 130 NJ 130 10400
preplace netloc hier_tracebuffer|Net4 1 2 2 980 -170 NJ
preplace netloc hier_tracebuffer|s_axis_tdata_1 1 0 2 NJ -80 520
preplace netloc processing_system7_0_axi_periph_M07_AXI 1 7 1 10400
preplace netloc mb_bram_ctrl_1_BRAM_PORTA 1 8 2 10720 1220 11160
preplace netloc Vaux7_1 1 0 8 NJ 1000 NJ 1000 NJ 1000 NJ 1000 NJ 1000 NJ 1000 NJ 1000 NJ
preplace netloc hier_tracebuffer|axis_data_fifo_0_s_axis_tready 1 2 2 1000 -140 NJ
preplace netloc hier_tracebuffer|aresetn_fastclk_1 1 0 6 NJ -180 NJ -180 NJ -160 NJ -150 NJ -150 2030
preplace netloc hier_tracebuffer|Net 1 6 2 2420 370 NJ
preplace netloc hier_tracebuffer|trace_controller_0_B 1 2 1 910
preplace netloc Vp_Vn_1 1 0 8 NJ 980 NJ 980 NJ 980 NJ 980 NJ 980 NJ 980 NJ 980 NJ
preplace netloc processing_system7_0_axi_periph_M01_AXI 1 7 2 NJ 390 NJ
preplace netloc processing_system7_0_IIC_1 1 3 7 NJ 120 NJ 120 NJ 120 NJ 120 NJ 120 NJ 120 NJ
preplace netloc hier_tracebuffer_s2mm_introut 1 2 2 -240 570 3150
preplace netloc pmod2sw_data_in_1 1 0 9 NJ 1560 NJ 1560 NJ 1560 NJ 1560 NJ 1560 NJ 1560 NJ 1560 NJ 1560 NJ
preplace netloc hier_tracebuffer|axis_accelerator_adapter_0_AP_CTRL 1 1 1 510
preplace netloc processing_system7_0_FCLK_CLK0 1 2 7 NJ 590 NJ 590 NJ 590 9550 520 NJ 700 10360 1020 10710
preplace netloc microblaze_0_debug 1 8 2 10740 1690 11130
preplace netloc hier_tracebuffer_M_AXI_S2MM 1 3 1 3150
preplace netloc processing_system7_0_FCLK_CLK2 1 2 4 NJ 560 NJ 800 NJ 800 N
preplace netloc rst_processing_system7_0_100M_interconnect_aresetn 1 6 1 10000
preplace netloc hier_tracebuffer|aresetn_slowclk_1 1 0 7 190 -210 NJ -210 900 100 1370 270 1800 110 2050 110 NJ
preplace netloc processing_system7_0_axi_periph_M00_AXI 1 7 2 NJ 370 NJ
preplace netloc hier_tracebuffer|axis_switch_0_s_axis_tready 1 2 2 970 -280 NJ
preplace netloc hier_tracebuffer|xlconstant0_1b_1_dout 1 2 2 990 -300 1390
preplace netloc mb_1_reset_Dout 1 8 2 10750 1700 11120
preplace netloc Vaux6_1 1 0 8 NJ 460 NJ 460 NJ 510 NJ 180 NJ 180 NJ 180 NJ 180 NJ
preplace netloc hier_tracebuffer|processing_system7_0_axi_periph_M04_AXI 1 0 7 NJ -230 NJ -230 NJ -150 NJ -140 NJ -140 NJ -140 2410
preplace netloc hier_tracebuffer|xlconstant_1b_1_dout 1 1 1 NJ
preplace netloc M00_ARESETN_1 1 2 5 -270 -470 3230 -470 NJ -470 NJ -470 NJ
preplace netloc Vaux14_1 1 0 8 NJ 1020 NJ 1020 NJ 1310 NJ 1310 NJ 1310 NJ 1310 NJ 1310 NJ
preplace netloc hier_tracebuffer|axi_dma_0_s2mm_introut 1 7 2 2820 460 NJ
preplace netloc pmod_io_switch_0_sw2pmod_tri_out 1 0 10 -700 1450 N 1450 N 1450 N 1450 N 1450 NJ 1450 NJ 1450 NJ 1450 NJ 1450 NJ
preplace netloc processing_system7_0_M_AXI_GP0 1 3 4 NJ 240 NJ 240 NJ 240 NJ
preplace netloc hier_tracebuffer|axis_data_fifo_0_M_AXIS 1 4 1 1790
preplace netloc logic_1_dout 1 8 2 10760 1820 11120
preplace netloc tracebuffer_sel_Dout 1 5 1 NJ
preplace netloc axi_mem_intercon_M00_AXI 1 2 3 NJ -850 NJ -850 NJ
preplace netloc ARESETN_1 1 3 4 3250 -480 NJ -480 NJ -480 NJ
preplace netloc processing_system7_0_GPIO_O 1 3 6 NJ 1080 NJ 1770 NJ 1770 NJ 1770 NJ 1770 NJ
preplace netloc xup_mux_tri_out_y 1 6 1 9990
preplace netloc processing_system7_0_axi_periph_M04_AXI 1 2 6 NJ 520 NJ 150 NJ 150 NJ 150 NJ 150 10330
preplace netloc swsleds_gpio_GPIO 1 9 1 N
preplace netloc rst_processing_system7_0_100M_peripheral_aresetn 1 2 7 NJ 550 NJ 510 NJ 510 NJ 510 10020 710 10340 1040 10700
preplace netloc pmod_io_switch_0_sw2pmod_data_out 1 0 10 -710 1440 N 1440 N 1440 N 1440 N 1440 NJ 1440 NJ 1440 NJ 1440 NJ 1440 NJ
preplace netloc btns_gpio_GPIO 1 9 1 NJ
levelinfo -pg 1 -740 -590 -400 340 7128 9459 9807 10170 10550 10940 11180 -top -1080 -bot 2280
levelinfo -hier hier_tracebuffer * 360 720 1190 1610 1910 2200 2620 2920 *
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
make_wrapper -files [get_files ./iop_trace.srcs/sources_1/bd/system/system.bd] -top

# generate toplevel wrapper files
add_files -norecurse ./iop_trace.srcs/sources_1/bd/system/hdl/system.v
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

# move and rename bitstream to final location
file copy -force ./iop_trace.runs/impl_1/top.bit ../../../Zybo/bitstream/iop_trace.bit