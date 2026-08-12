#
# Copyright (C) 2025, Advanced Micro Devices, Inc. All rights reserved.
# SPDX-License-Identifier: BSD-3-Clause
#
# Golden Reference Design for VCK190 Segmented Configuration
#
# This script creates the static PS/NoC/DDR "contract" that all PL overlays
# must conform to.  It produces:
#   - CIPS with maximal PL-facing interfaces (clocks, resets, interrupts, AXI)
#   - axi_noc_ps: PS-only paths to DDR (initial_boot, goes in boot PDI)
#   - axi_noc_pl: PL-facing paths (DMA to DDR via inter-NoC, no initial_boot)
#   - All PL-facing ports tied off so the design is DRC-clean standalone
#
# Overlays source this script, delete the tie-offs, and connect their own PL
# logic.  The exported NoC solution (golden_noc.ncr) and routed checkpoint
# (golden_routed.dcp) are used by build_user_overlay.tcl to guarantee
# compatibility via read_noc_solution and pr_verify.
#
# Vivado version: 2025.2
#

namespace eval _tcl {
proc get_script_folder {} {
   set script_path [file normalize [info script]]
   set script_folder [file dirname $script_path]
   return $script_folder
}
}
variable script_folder
set script_folder [_tcl::get_script_folder]

set scripts_vivado_version 2025.2
set current_vivado_version [version -short]

if { [string first $scripts_vivado_version $current_vivado_version] == -1 } {
    catch {common::send_gid_msg -ssname BD::TCL -id 2041 -severity "WARNING" \
        "This script was generated using Vivado <$scripts_vivado_version> and is being run in <$current_vivado_version>."}
}

################################################################
# BOARD STORE
################################################################
# The XilinxBoardStore is mounted at /board_store inside Docker containers.
# Tell Vivado where to find board files so board automation rules work.
if {[file isdirectory /board_store/boards]} {
    set_param board.repoPaths [list /board_store/boards]
    puts "Board store: /board_store/boards"
} elseif {[info exists ::env(BOARD_STORE_PATH)] && [file isdirectory $::env(BOARD_STORE_PATH)/boards]} {
    set_param board.repoPaths [list $::env(BOARD_STORE_PATH)/boards]
    puts "Board store: $::env(BOARD_STORE_PATH)/boards"
}

################################################################
# PROJECT
################################################################

if {![info exists design_name] || $design_name eq ""} {
    set design_name golden
}

set list_projs [get_projects -quiet]
if { $list_projs eq "" } {
    create_project $design_name $design_name -part xcvc1902-vsva2197-2MP-e-S -force
    set_property BOARD_PART xilinx.com:vck190:part0:3.4 [current_project]
}

set cur_design [current_bd_design -quiet]
set list_cells [get_bd_cells -quiet]

if { ${design_name} eq "" } {
    set errMsg "Please set the variable to a non-empty value."
    return 1
} elseif { ${cur_design} ne "" && ${list_cells} eq "" } {
    if { $cur_design ne $design_name } {
        set design_name [get_property NAME $cur_design]
    }
} elseif { ${cur_design} ne "" && $list_cells ne "" && $cur_design eq $design_name } {
    set errMsg "Design <$design_name> already exists in your project."
    return 1
} elseif { [get_files -quiet ${design_name}.bd] ne "" } {
    set errMsg "Design <$design_name> already exists in your project."
    return 2
} else {
    create_bd_design $design_name
    current_bd_design $design_name
}

##################################################################
# HELPER: modify a key inside a flat {KEY VALUE KEY VALUE ...} list
##################################################################
proc dict_set_flat {listvar key value} {
    upvar $listvar L
    set idx [lsearch -exact $L $key]
    if {$idx >= 0} {
        set L [lreplace $L [expr {$idx+1}] [expr {$idx+1}] $value]
    } else {
        lappend L $key $value
    }
}

##################################################################
# DESIGN CREATION
##################################################################
proc create_root_design { parentCell } {
    global design_name

    if { $parentCell eq "" } { set parentCell [get_bd_cells /] }
    set parentObj [get_bd_cells $parentCell]
    set parentType [get_property TYPE $parentObj]

    set oldCurInst [current_bd_instance .]
    current_bd_instance $parentObj

    ################################################################
    # CIPS: Apply VCK190 board preset, then enable golden interfaces
    ################################################################
    set versal_cips_0 [create_bd_cell -type ip -vlnv xilinx.com:ip:versal_cips:3.4 versal_cips_0]

    # Apply VCK190 board preset via PS_BOARD_INTERFACE property.
    # NOTE: apply_bd_automation -rule xilinx.com:bd_rule:cips fails in Vivado
    # 2025.2 with "key mc_type not known in dictionary", so we apply the preset
    # directly.  Setting PS_BOARD_INTERFACE loads the board's default PS/PMC
    # configuration (peripherals, MIO, DDR mode, etc.).
    set_property CONFIG.PS_BOARD_INTERFACE ps_pmc_fixed_io $versal_cips_0

    set pmc_cfg [get_property CONFIG.PS_PMC_CONFIG $versal_cips_0]

    # PS-to-PL AXI masters
    dict_set_flat pmc_cfg PS_USE_M_AXI_FPD       {1}
    dict_set_flat pmc_cfg PS_USE_M_AXI_LPD       {1}

    # FPD_AXI_NOC0 is intentionally disabled: PL DMA uses axi_noc_pl, and PS
    # DDR access goes through the CCI ports.  Enable this only if you add a
    # dedicated SI on axi_noc_ps for PS non-coherent DMA.
    dict_set_flat pmc_cfg PS_USE_FPD_AXI_NOC0    {0}

    # Coherent CCI NoC ports (for PS-DDR boot paths)
    dict_set_flat pmc_cfg PS_USE_FPD_CCI_NOC      {1}

    # LPD and PMC NoC ports
    dict_set_flat pmc_cfg PS_USE_NOC_LPD_AXI0     {1}
    dict_set_flat pmc_cfg PMC_USE_PMC_NOC_AXI0     {1}

    # All 4 PL reference clocks
    dict_set_flat pmc_cfg PS_USE_PMCPL_CLK0       {1}
    dict_set_flat pmc_cfg PS_USE_PMCPL_CLK1       {1}
    dict_set_flat pmc_cfg PS_USE_PMCPL_CLK2       {1}
    dict_set_flat pmc_cfg PS_USE_PMCPL_CLK3       {1}

    # All 4 PL fabric resets
    dict_set_flat pmc_cfg PS_NUM_FABRIC_RESETS     {4}

    # All 16 PL-to-PS interrupt channels
    dict_set_flat pmc_cfg PS_IRQ_USAGE \
        {{CH0 1} {CH1 1} {CH2 1} {CH3 1} {CH4 1} {CH5 1} {CH6 1} {CH7 1} {CH8 1} {CH9 1} {CH10 1} {CH11 1} {CH12 1} {CH13 1} {CH14 1} {CH15 1}}
    dict_set_flat pmc_cfg PS_NUM_F2P0_INTR_INPUTS {8}
    dict_set_flat pmc_cfg PS_NUM_F2P1_INTR_INPUTS {8}

    set_property CONFIG.PS_PMC_CONFIG $pmc_cfg $versal_cips_0
    set_property SELECTED_SIM_MODEL tlm $versal_cips_0

    ################################################################
    # Clock / Reset infrastructure
    ################################################################

    # proc_sys_reset for pl0_ref_clk (333 MHz, primary PL clock)
    set rst_pl0 [create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset:5.0 rst_pl0]

    # proc_sys_reset for pl1_ref_clk
    set rst_pl1 [create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset:5.0 rst_pl1]

    # proc_sys_reset for pl2_ref_clk
    set rst_pl2 [create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset:5.0 rst_pl2]

    # proc_sys_reset for pl3_ref_clk
    set rst_pl3 [create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset:5.0 rst_pl3]

    ################################################################
    # PS NoC: DDR-only paths, all initial_boot (goes in boot PDI)
    ################################################################
    set axi_noc_ps [create_bd_cell -type ip -vlnv xilinx.com:ip:axi_noc:1.1 axi_noc_ps]
    set_property -dict [list \
        CONFIG.MC_CHAN_REGION1            {DDR_LOW1} \
        CONFIG.MC_NETLIST_SIMULATION      {true} \
        CONFIG.NUM_SI    {6} \
        CONFIG.NUM_MI    {0} \
        CONFIG.NUM_MC    {1} \
        CONFIG.NUM_MCP   {1} \
        CONFIG.NUM_NSI   {1} \
        CONFIG.NUM_NMI   {0} \
        CONFIG.NUM_CLKS  {7} \
    ] $axi_noc_ps

    # Apply board connections for DDR4 -- this sets all DDR timing parameters,
    # speed grade, clock frequency, and creates external ports automatically.
    apply_board_connection -board_interface "ddr4_dimm1" \
        -ip_intf "axi_noc_ps/CH0_DDR4_0" -diagram $design_name
    apply_board_connection -board_interface "ddr4_dimm1_sma_clk" \
        -ip_intf "axi_noc_ps/sys_clk0" -diagram $design_name
    set_property SELECTED_SIM_MODEL tlm $axi_noc_ps

    # S00_AXI: PMC_NOC_AXI_0 -> DDR (initial_boot)
    set_property -dict [list \
        CONFIG.DATA_WIDTH {128} CONFIG.REGION {0} \
        CONFIG.CONNECTIONS {MC_0 {read_bw {5} write_bw {5} read_avg_burst {4} write_avg_burst {4} initial_boot {true}}} \
        CONFIG.DEST_IDS {} CONFIG.NOC_PARAMS {} CONFIG.CATEGORY {ps_pmc} \
    ] [get_bd_intf_pins /axi_noc_ps/S00_AXI]

    # S01_AXI: LPD_AXI_NOC_0 -> DDR (initial_boot)
    set_property -dict [list \
        CONFIG.DATA_WIDTH {128} CONFIG.REGION {0} \
        CONFIG.CONNECTIONS {MC_0 {read_bw {5} write_bw {5} read_avg_burst {4} write_avg_burst {4} initial_boot {true}}} \
        CONFIG.DEST_IDS {} CONFIG.NOC_PARAMS {} CONFIG.CATEGORY {ps_rpu} \
    ] [get_bd_intf_pins /axi_noc_ps/S01_AXI]

    # S02-S05_AXI: FPD_CCI_NOC_0..3 -> DDR (initial_boot)
    foreach idx {2 3 4 5} cci {0 1 2 3} {
        set_property -dict [list \
            CONFIG.DATA_WIDTH {128} CONFIG.REGION {0} \
            CONFIG.CONNECTIONS {MC_0 {read_bw {5} write_bw {5} read_avg_burst {4} write_avg_burst {4} initial_boot {true}}} \
            CONFIG.DEST_IDS {} CONFIG.NOC_PARAMS {} CONFIG.CATEGORY {ps_cci} \
        ] [get_bd_intf_pins /axi_noc_ps/S0${idx}_AXI]
    }

    # S00_INI: incoming inter-NoC from PL NoC (for PL DMA -> DDR)
    set_property -dict [list \
        CONFIG.CONNECTIONS {MC_0 {read_bw {500} write_bw {500}}} \
    ] [get_bd_intf_pins /axi_noc_ps/S00_INI]

    # Clock associations for PS NoC
    set_property -dict [list CONFIG.ASSOCIATED_BUSIF {S00_AXI}] [get_bd_pins /axi_noc_ps/aclk0]
    set_property -dict [list CONFIG.ASSOCIATED_BUSIF {S01_AXI}] [get_bd_pins /axi_noc_ps/aclk1]
    set_property -dict [list CONFIG.ASSOCIATED_BUSIF {S02_AXI}] [get_bd_pins /axi_noc_ps/aclk2]
    set_property -dict [list CONFIG.ASSOCIATED_BUSIF {S03_AXI}] [get_bd_pins /axi_noc_ps/aclk3]
    set_property -dict [list CONFIG.ASSOCIATED_BUSIF {S04_AXI}] [get_bd_pins /axi_noc_ps/aclk4]
    set_property -dict [list CONFIG.ASSOCIATED_BUSIF {S05_AXI}] [get_bd_pins /axi_noc_ps/aclk5]
    set_property -dict [list CONFIG.ASSOCIATED_BUSIF {S00_INI}] [get_bd_pins /axi_noc_ps/aclk6]

    ################################################################
    # PL NoC: PL DMA paths to DDR via inter-NoC (no initial_boot)
    ################################################################
    set axi_noc_pl [create_bd_cell -type ip -vlnv xilinx.com:ip:axi_noc:1.1 axi_noc_pl]
    set_property -dict [list \
        CONFIG.NUM_SI    {2} \
        CONFIG.NUM_MI    {0} \
        CONFIG.NUM_MC    {0} \
        CONFIG.NUM_MCP   {0} \
        CONFIG.NUM_NMI   {1} \
        CONFIG.NUM_NSI   {0} \
        CONFIG.NUM_CLKS  {1} \
    ] $axi_noc_pl
    set_property SELECTED_SIM_MODEL tlm $axi_noc_pl

    # S00_AXI: PL DMA port 0 -> DDR via inter-NoC (M00_INI)
    set_property -dict [list \
        CONFIG.DATA_WIDTH {128} CONFIG.REGION {0} \
        CONFIG.CONNECTIONS {M00_INI {read_bw {500} write_bw {500}}} \
        CONFIG.DEST_IDS {} CONFIG.NOC_PARAMS {} CONFIG.CATEGORY {pl} \
    ] [get_bd_intf_pins /axi_noc_pl/S00_AXI]

    # S01_AXI: PL DMA port 1 -> DDR via inter-NoC (M00_INI)
    set_property -dict [list \
        CONFIG.DATA_WIDTH {128} CONFIG.REGION {0} \
        CONFIG.CONNECTIONS {M00_INI {read_bw {500} write_bw {500}}} \
        CONFIG.DEST_IDS {} CONFIG.NOC_PARAMS {} CONFIG.CATEGORY {pl} \
    ] [get_bd_intf_pins /axi_noc_pl/S01_AXI]

    set_property -dict [list CONFIG.ASSOCIATED_BUSIF {S00_AXI:S01_AXI}] [get_bd_pins /axi_noc_pl/aclk0]

    ################################################################
    # PL Interface Tie-offs (DRC-clean standalone)
    ################################################################

    # Tie-off for M_AXI_FPD (PS master -> PL slave)
    set pl_tieoff_fpd [create_bd_cell -type ip -vlnv xilinx.com:ip:axi_vip:1.1 pl_tieoff_fpd]
    set_property -dict [list \
        CONFIG.INTERFACE_MODE {SLAVE} \
        CONFIG.PROTOCOL {AXI4} \
    ] $pl_tieoff_fpd

    # Tie-off for M_AXI_LPD (PS master -> PL slave)
    set pl_tieoff_lpd [create_bd_cell -type ip -vlnv xilinx.com:ip:axi_vip:1.1 pl_tieoff_lpd]
    set_property -dict [list \
        CONFIG.INTERFACE_MODE {SLAVE} \
        CONFIG.PROTOCOL {AXI4} \
    ] $pl_tieoff_lpd

    # Tie-off for PL NoC S00_AXI (PL DMA port 0 -- needs an AXI master)
    set pl_tieoff_dma0 [create_bd_cell -type ip -vlnv xilinx.com:ip:axi_vip:1.1 pl_tieoff_dma0]
    set_property -dict [list \
        CONFIG.INTERFACE_MODE {MASTER} \
        CONFIG.PROTOCOL {AXI4} \
        CONFIG.DATA_WIDTH {128} \
        CONFIG.ADDR_WIDTH {64} \
    ] $pl_tieoff_dma0

    # Tie-off for PL NoC S01_AXI (PL DMA port 1 -- needs an AXI master)
    set pl_tieoff_dma1 [create_bd_cell -type ip -vlnv xilinx.com:ip:axi_vip:1.1 pl_tieoff_dma1]
    set_property -dict [list \
        CONFIG.INTERFACE_MODE {MASTER} \
        CONFIG.PROTOCOL {AXI4} \
        CONFIG.DATA_WIDTH {128} \
        CONFIG.ADDR_WIDTH {64} \
    ] $pl_tieoff_dma1

    # Tie-off for PL interrupts: constant 0
    set pl_tieoff_irq [create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant:1.1 pl_tieoff_irq]
    set_property -dict [list \
        CONFIG.CONST_VAL {0} \
        CONFIG.CONST_WIDTH {1} \
    ] $pl_tieoff_irq

    ################################################################
    # Interface connections
    ################################################################
    # (DDR4 external ports and connections created by apply_board_connection above)

    # PS -> NoC (DDR paths)
    connect_bd_intf_net [get_bd_intf_pins versal_cips_0/PMC_NOC_AXI_0]  [get_bd_intf_pins axi_noc_ps/S00_AXI]
    connect_bd_intf_net [get_bd_intf_pins versal_cips_0/LPD_AXI_NOC_0]  [get_bd_intf_pins axi_noc_ps/S01_AXI]
    connect_bd_intf_net [get_bd_intf_pins versal_cips_0/FPD_CCI_NOC_0]  [get_bd_intf_pins axi_noc_ps/S02_AXI]
    connect_bd_intf_net [get_bd_intf_pins versal_cips_0/FPD_CCI_NOC_1]  [get_bd_intf_pins axi_noc_ps/S03_AXI]
    connect_bd_intf_net [get_bd_intf_pins versal_cips_0/FPD_CCI_NOC_2]  [get_bd_intf_pins axi_noc_ps/S04_AXI]
    connect_bd_intf_net [get_bd_intf_pins versal_cips_0/FPD_CCI_NOC_3]  [get_bd_intf_pins axi_noc_ps/S05_AXI]

    # PL NoC inter-NoC connection (PL DMA -> DDR)
    connect_bd_intf_net [get_bd_intf_pins axi_noc_pl/M00_INI] [get_bd_intf_pins axi_noc_ps/S00_INI]

    # PS AXI masters -> tie-offs
    connect_bd_intf_net [get_bd_intf_pins versal_cips_0/M_AXI_FPD] [get_bd_intf_pins pl_tieoff_fpd/S_AXI]
    connect_bd_intf_net [get_bd_intf_pins versal_cips_0/M_AXI_LPD] [get_bd_intf_pins pl_tieoff_lpd/S_AXI]

    # PL NoC slave ports -> tie-off masters
    connect_bd_intf_net [get_bd_intf_pins pl_tieoff_dma0/M_AXI] [get_bd_intf_pins axi_noc_pl/S00_AXI]
    connect_bd_intf_net [get_bd_intf_pins pl_tieoff_dma1/M_AXI] [get_bd_intf_pins axi_noc_pl/S01_AXI]

    ################################################################
    # Clock connections
    ################################################################

    # PS NoC clocks from CIPS
    connect_bd_net [get_bd_pins versal_cips_0/pmc_axi_noc_axi0_clk]  [get_bd_pins axi_noc_ps/aclk0]
    connect_bd_net [get_bd_pins versal_cips_0/lpd_axi_noc_clk]       [get_bd_pins axi_noc_ps/aclk1]
    connect_bd_net [get_bd_pins versal_cips_0/fpd_cci_noc_axi0_clk]  [get_bd_pins axi_noc_ps/aclk2]
    connect_bd_net [get_bd_pins versal_cips_0/fpd_cci_noc_axi1_clk]  [get_bd_pins axi_noc_ps/aclk3]
    connect_bd_net [get_bd_pins versal_cips_0/fpd_cci_noc_axi2_clk]  [get_bd_pins axi_noc_ps/aclk4]
    connect_bd_net [get_bd_pins versal_cips_0/fpd_cci_noc_axi3_clk]  [get_bd_pins axi_noc_ps/aclk5]

    # PL clock (pl0_ref_clk) drives PL NoC, tie-offs, and reset
    connect_bd_net [get_bd_pins versal_cips_0/pl0_ref_clk] \
        [get_bd_pins axi_noc_ps/aclk6] \
        [get_bd_pins axi_noc_pl/aclk0] \
        [get_bd_pins rst_pl0/slowest_sync_clk] \
        [get_bd_pins versal_cips_0/m_axi_fpd_aclk] \
        [get_bd_pins versal_cips_0/m_axi_lpd_aclk] \
        [get_bd_pins pl_tieoff_fpd/aclk] \
        [get_bd_pins pl_tieoff_lpd/aclk] \
        [get_bd_pins pl_tieoff_dma0/aclk] \
        [get_bd_pins pl_tieoff_dma1/aclk]

    # PL resets -> proc_sys_reset
    connect_bd_net [get_bd_pins versal_cips_0/pl0_resetn] [get_bd_pins rst_pl0/ext_reset_in]
    connect_bd_net [get_bd_pins versal_cips_0/pl1_ref_clk] [get_bd_pins rst_pl1/slowest_sync_clk]
    connect_bd_net [get_bd_pins versal_cips_0/pl1_resetn]  [get_bd_pins rst_pl1/ext_reset_in]
    connect_bd_net [get_bd_pins versal_cips_0/pl2_ref_clk] [get_bd_pins rst_pl2/slowest_sync_clk]
    connect_bd_net [get_bd_pins versal_cips_0/pl2_resetn]  [get_bd_pins rst_pl2/ext_reset_in]
    connect_bd_net [get_bd_pins versal_cips_0/pl3_ref_clk] [get_bd_pins rst_pl3/slowest_sync_clk]
    connect_bd_net [get_bd_pins versal_cips_0/pl3_resetn]  [get_bd_pins rst_pl3/ext_reset_in]

    # Tie-off resets
    connect_bd_net [get_bd_pins rst_pl0/peripheral_aresetn] \
        [get_bd_pins pl_tieoff_fpd/aresetn] \
        [get_bd_pins pl_tieoff_lpd/aresetn] \
        [get_bd_pins pl_tieoff_dma0/aresetn] \
        [get_bd_pins pl_tieoff_dma1/aresetn]

    # Tie all interrupt inputs to 0
    foreach irq_pin [get_bd_pins versal_cips_0/pl_ps_irq*] {
        connect_bd_net [get_bd_pins pl_tieoff_irq/dout] $irq_pin
    }

    ################################################################
    # Address segments (PS -> DDR only in golden reference)
    ################################################################
    foreach ns {{PMC_NOC_AXI_0 S00} {LPD_AXI_NOC_0 S01} {FPD_CCI_NOC_0 S02} {FPD_CCI_NOC_1 S03} {FPD_CCI_NOC_2 S04} {FPD_CCI_NOC_3 S05}} {
        set master [lindex $ns 0]
        set slave  [lindex $ns 1]
        assign_bd_address -offset 0x00000000 -range 0x80000000 \
            -target_address_space [get_bd_addr_spaces versal_cips_0/${master}] \
            [get_bd_addr_segs axi_noc_ps/${slave}_AXI/C0_DDR_LOW0] -force
        assign_bd_address -offset 0x000800000000 -range 0x000180000000 \
            -target_address_space [get_bd_addr_spaces versal_cips_0/${master}] \
            [get_bd_addr_segs axi_noc_ps/${slave}_AXI/C0_DDR_LOW1] -force
    }

    # PL DMA -> DDR address assignments (through inter-NoC -> PS NoC)
    foreach idx {0 1} {
        assign_bd_address -offset 0x00000000 -range 0x80000000 \
            -target_address_space [get_bd_addr_spaces pl_tieoff_dma${idx}/Master_AXI] \
            [get_bd_addr_segs axi_noc_ps/S00_INI/C0_DDR_LOW0] -force
        assign_bd_address -offset 0x000800000000 -range 0x000180000000 \
            -target_address_space [get_bd_addr_spaces pl_tieoff_dma${idx}/Master_AXI] \
            [get_bd_addr_segs axi_noc_ps/S00_INI/C0_DDR_LOW1] -force
    }

    current_bd_instance $oldCurInst

    validate_bd_design
    save_bd_design
}

##################################################################
# MAIN FLOW
##################################################################
create_root_design ""
