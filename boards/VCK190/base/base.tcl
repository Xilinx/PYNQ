#
# Copyright (C) 2025, Advanced Micro Devices, Inc. All rights reserved.
# SPDX-License-Identifier: BSD-3-Clause
#
# VCK190 Base Overlay -- reference implementation on top of golden reference.
#
# This script:
#   1. Sources golden_ref.tcl (creates CIPS, PS NoC, PL NoC, tie-offs)
#   2. Removes PL tie-offs
#   3. Adds PL peripherals: GPIO (LEDs, buttons, DIP switches), BRAM,
#      UARTLite, AXI DMA with loopback FIFO
#   4. Routes DMA data through the PL NoC to DDR
#
# Vivado version: 2025.2
#

################################################################
# Step 1: Source the golden reference design
################################################################
# Pre-set design_name so golden_ref.tcl creates project/BD named "base"
set design_name "base"
source [file join [file dirname [info script]] ../golden/golden_ref.tcl]

################################################################
# Step 2: Remove PL tie-offs from the golden reference
################################################################
# The golden design has AXI VIP tie-offs and an xlconstant for interrupts.
# Remove them so we can connect real PL logic.
delete_bd_objs [get_bd_cells pl_tieoff_fpd]
delete_bd_objs [get_bd_cells pl_tieoff_lpd]
delete_bd_objs [get_bd_cells pl_tieoff_dma0]
delete_bd_objs [get_bd_cells pl_tieoff_dma1]
# Disconnect all IRQ nets before deleting the tie-off, otherwise the
# sink pins remain connected and cannot be re-driven.
foreach irq_pin [get_bd_pins versal_cips_0/pl_ps_irq*] {
    set net [get_bd_nets -of_objects $irq_pin -quiet]
    if {$net ne ""} { delete_bd_objs $net }
}
delete_bd_objs [get_bd_cells pl_tieoff_irq]

################################################################
# Step 3: PL Peripherals -- Control Path (M_AXI_FPD via SmartConnect)
################################################################

# SmartConnect: fan-out M_AXI_FPD to 6 PL slaves
set axi_smc [create_bd_cell -type ip -vlnv xilinx.com:ip:smartconnect:1.0 axi_smc]
set_property -dict [list CONFIG.NUM_MI {6} CONFIG.NUM_SI {1}] $axi_smc

# GPIO: LEDs (4-bit, output)
set axi_gpio_led [create_bd_cell -type ip -vlnv xilinx.com:ip:axi_gpio:2.0 axi_gpio_led]
set_property -dict [list \
    CONFIG.C_INTERRUPT_PRESENT {0} \
    CONFIG.GPIO_BOARD_INTERFACE {gpio_led} \
    CONFIG.USE_BOARD_FLOW {true} \
] $axi_gpio_led

# GPIO: Push buttons (width set by board interface, input, interrupts enabled)
set axi_gpio_pb [create_bd_cell -type ip -vlnv xilinx.com:ip:axi_gpio:2.0 axi_gpio_pb]
 set_property -dict [list \
    CONFIG.C_INTERRUPT_PRESENT {1} \
    CONFIG.GPIO_BOARD_INTERFACE {gpio_pb} \
    CONFIG.USE_BOARD_FLOW {true} \
] $axi_gpio_pb

# GPIO: DIP switches (4-bit, input, interrupts enabled)
set axi_gpio_dip_sw [create_bd_cell -type ip -vlnv xilinx.com:ip:axi_gpio:2.0 axi_gpio_dip_sw]
 set_property -dict [list \
 CONFIG.C_INTERRUPT_PRESENT {1} \
 CONFIG.GPIO_BOARD_INTERFACE {gpio_dp} \
 CONFIG.USE_BOARD_FLOW {true} \
 ] $axi_gpio_dip_sw

# BRAM: 8KB read/write test memory
set axi_bram_ctrl_0 [create_bd_cell -type ip -vlnv xilinx.com:ip:axi_bram_ctrl:4.1 axi_bram_ctrl_0]
set axi_bram_ctrl_0_bram [create_bd_cell -type ip -vlnv xilinx.com:ip:emb_mem_gen:1.0 axi_bram_ctrl_0_bram]
set_property CONFIG.MEMORY_TYPE {True_Dual_Port_RAM} $axi_bram_ctrl_0_bram

# DMA: AXI DMA engine with MM2S and S2MM (simple mode, no scatter-gather)
# c_addr_width 64 so the DMA can reach DDR_LOW1 (above 4 GB); the default 32
# would truncate physical addresses and silently access the wrong memory.
set axi_dma_0 [create_bd_cell -type ip -vlnv xilinx.com:ip:axi_dma:7.1 axi_dma_0]
 set_property -dict [list \
    CONFIG.c_include_sg {0} \
    CONFIG.c_sg_include_stscntrl_strm {0} \
    CONFIG.c_addr_width {64} \
    CONFIG.c_m_axi_mm2s_data_width {128} \
    CONFIG.c_m_axi_s2mm_data_width {128} \
    CONFIG.c_m_axis_mm2s_tdata_width {128} \
    CONFIG.c_s_axis_s2mm_tdata_width {128} \
    CONFIG.c_mm2s_burst_size {256} \
    CONFIG.c_s2mm_burst_size {256} \
] $axi_dma_0

################################################################
# Step 3b: DMA Loopback via AXI Stream FIFO
################################################################

# AXI Stream Data FIFO: connects DMA MM2S output back to S2MM input
set axis_data_fifo_0 [create_bd_cell -type ip -vlnv xilinx.com:ip:axis_data_fifo:2.0 axis_data_fifo_0]
 set_property -dict [list \
    CONFIG.FIFO_DEPTH {1024} \
    CONFIG.TDATA_NUM_BYTES {16} \
] $axis_data_fifo_0

################################################################
# Step 3c: UART (routed through axi_smc M05_AXI)
################################################################

set axi_uartlite_0 [create_bd_cell -type ip -vlnv xilinx.com:ip:axi_uartlite:2.0 axi_uartlite_0]
 set_property -dict [list \
 CONFIG.C_S_AXI_ACLK_FREQ_HZ {333329987} \
 CONFIG.UARTLITE_BOARD_INTERFACE {uart2_bank306} \
 CONFIG.USE_BOARD_FLOW {true} \
 ] $axi_uartlite_0

################################################################
# Step 4: External board interfaces (GPIO, UART)
################################################################
create_bd_intf_port -mode Master -vlnv xilinx.com:interface:gpio_rtl:1.0 gpio_led
create_bd_intf_port -mode Master -vlnv xilinx.com:interface:gpio_rtl:1.0 gpio_pb
create_bd_intf_port -mode Master -vlnv xilinx.com:interface:gpio_rtl:1.0 gpio_dp
create_bd_intf_port -mode Master -vlnv xilinx.com:interface:uart_rtl:1.0 uart2_bank306

################################################################
# Step 5: Reconfigure PL NoC for base overlay
################################################################
# The golden axi_noc_pl has 2 SI (tied off), 0 MI, 1 NMI.
# For the base overlay we need:
#   - S00_AXI: DMA M_AXI_MM2S -> DDR (read channel)
#   - S01_AXI: DMA M_AXI_S2MM -> DDR (write channel)
#   - M00_INI remains connected to axi_noc_ps/S00_INI
# No changes needed -- the 2 SI / 1 NMI topology matches our needs.

# Also need M_AXI_FPD connection via SmartConnect (was going to tie-off)
# and M_AXI_LPD (we leave LPD unused for now, just connect a VIP)
set pl_lpd_tieoff [create_bd_cell -type ip -vlnv xilinx.com:ip:axi_vip:1.1 pl_lpd_tieoff]
set_property -dict [list CONFIG.INTERFACE_MODE {SLAVE} CONFIG.PROTOCOL {AXI4}] $pl_lpd_tieoff

################################################################
# Step 6: Interface connections
################################################################

# BRAM
connect_bd_intf_net [get_bd_intf_pins axi_bram_ctrl_0/BRAM_PORTA] [get_bd_intf_pins axi_bram_ctrl_0_bram/BRAM_PORTA]
connect_bd_intf_net [get_bd_intf_pins axi_bram_ctrl_0/BRAM_PORTB] [get_bd_intf_pins axi_bram_ctrl_0_bram/BRAM_PORTB]

# GPIO board connections
connect_bd_intf_net [get_bd_intf_ports gpio_led] [get_bd_intf_pins axi_gpio_led/GPIO]
connect_bd_intf_net [get_bd_intf_ports gpio_pb]  [get_bd_intf_pins axi_gpio_pb/GPIO]
connect_bd_intf_net [get_bd_intf_ports gpio_dp]  [get_bd_intf_pins axi_gpio_dip_sw/GPIO]

# UART board connection
connect_bd_intf_net [get_bd_intf_ports uart2_bank306] [get_bd_intf_pins axi_uartlite_0/UART]

# M_AXI_FPD -> SmartConnect -> {GPIO_DIP, GPIO_LED, GPIO_PB, BRAM, DMA_LITE, UART}
connect_bd_intf_net [get_bd_intf_pins versal_cips_0/M_AXI_FPD] [get_bd_intf_pins axi_smc/S00_AXI]
connect_bd_intf_net [get_bd_intf_pins axi_smc/M00_AXI] [get_bd_intf_pins axi_gpio_dip_sw/S_AXI]
connect_bd_intf_net [get_bd_intf_pins axi_smc/M01_AXI] [get_bd_intf_pins axi_gpio_led/S_AXI]
connect_bd_intf_net [get_bd_intf_pins axi_smc/M02_AXI] [get_bd_intf_pins axi_gpio_pb/S_AXI]
connect_bd_intf_net [get_bd_intf_pins axi_smc/M03_AXI] [get_bd_intf_pins axi_bram_ctrl_0/S_AXI]
connect_bd_intf_net [get_bd_intf_pins axi_smc/M04_AXI] [get_bd_intf_pins axi_dma_0/S_AXI_LITE]
connect_bd_intf_net [get_bd_intf_pins axi_smc/M05_AXI] [get_bd_intf_pins axi_uartlite_0/S_AXI]

# M_AXI_LPD -> tie-off (unused in base overlay)
connect_bd_intf_net [get_bd_intf_pins versal_cips_0/M_AXI_LPD] [get_bd_intf_pins pl_lpd_tieoff/S_AXI]

# DMA data ports -> PL NoC (to DDR)
connect_bd_intf_net [get_bd_intf_pins axi_dma_0/M_AXI_MM2S] [get_bd_intf_pins axi_noc_pl/S00_AXI]
connect_bd_intf_net [get_bd_intf_pins axi_dma_0/M_AXI_S2MM] [get_bd_intf_pins axi_noc_pl/S01_AXI]

# DMA loopback: MM2S stream -> FIFO -> S2MM stream
connect_bd_intf_net [get_bd_intf_pins axi_dma_0/M_AXIS_MM2S]     [get_bd_intf_pins axis_data_fifo_0/S_AXIS]
connect_bd_intf_net [get_bd_intf_pins axis_data_fifo_0/M_AXIS]    [get_bd_intf_pins axi_dma_0/S_AXIS_S2MM]


################################################################
# Step 7: Clock connections
################################################################

# pl0_ref_clk drives new PL peripherals (golden_ref.tcl already connected
# pl0_ref_clk to CIPS aclk pins, NoC clocks, and rst_pl0)
connect_bd_net [get_bd_pins versal_cips_0/pl0_ref_clk] \
    [get_bd_pins axi_smc/aclk] \
    [get_bd_pins axi_gpio_dip_sw/s_axi_aclk] \
    [get_bd_pins axi_gpio_led/s_axi_aclk] \
    [get_bd_pins axi_gpio_pb/s_axi_aclk] \
    [get_bd_pins axi_bram_ctrl_0/s_axi_aclk] \
    [get_bd_pins axi_dma_0/s_axi_lite_aclk] \
    [get_bd_pins axi_dma_0/m_axi_mm2s_aclk] \
    [get_bd_pins axi_dma_0/m_axi_s2mm_aclk] \
    [get_bd_pins axis_data_fifo_0/s_axis_aclk] \
    [get_bd_pins axi_uartlite_0/s_axi_aclk] \
    [get_bd_pins pl_lpd_tieoff/aclk]

################################################################
# Step 8: Reset connections
################################################################

connect_bd_net [get_bd_pins rst_pl0/peripheral_aresetn] \
    [get_bd_pins axi_smc/aresetn] \
    [get_bd_pins axi_gpio_dip_sw/s_axi_aresetn] \
    [get_bd_pins axi_gpio_led/s_axi_aresetn] \
    [get_bd_pins axi_gpio_pb/s_axi_aresetn] \
    [get_bd_pins axi_bram_ctrl_0/s_axi_aresetn] \
    [get_bd_pins axi_dma_0/axi_resetn] \
    [get_bd_pins axis_data_fifo_0/s_axis_aresetn] \
    [get_bd_pins axi_uartlite_0/s_axi_aresetn] \
    [get_bd_pins pl_lpd_tieoff/aresetn]

################################################################
# Step 9: Interrupt connections
################################################################

connect_bd_net [get_bd_pins axi_dma_0/mm2s_introut]        [get_bd_pins versal_cips_0/pl_ps_irq0]
connect_bd_net [get_bd_pins axi_dma_0/s2mm_introut]         [get_bd_pins versal_cips_0/pl_ps_irq1]
connect_bd_net [get_bd_pins axi_gpio_dip_sw/ip2intc_irpt]   [get_bd_pins versal_cips_0/pl_ps_irq8]
connect_bd_net [get_bd_pins axi_gpio_pb/ip2intc_irpt]        [get_bd_pins versal_cips_0/pl_ps_irq9]
connect_bd_net [get_bd_pins axi_uartlite_0/interrupt]        [get_bd_pins versal_cips_0/pl_ps_irq10]

# Tie-off unused IRQ inputs to constant 0
set irq_tieoff [create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant:1.1 irq_tieoff]
set_property -dict [list CONFIG.CONST_VAL {0} CONFIG.CONST_WIDTH {1}] $irq_tieoff
foreach idx {2 3 4 5 6 7 11 12 13 14 15} {
    connect_bd_net [get_bd_pins irq_tieoff/dout] [get_bd_pins versal_cips_0/pl_ps_irq${idx}]
}

################################################################
# Step 10: Address assignments
################################################################

# M_AXI_FPD address space (via SmartConnect)
assign_bd_address -offset 0xA4000000 -range 0x00002000 \
    -target_address_space [get_bd_addr_spaces versal_cips_0/M_AXI_FPD] \
    [get_bd_addr_segs axi_bram_ctrl_0/S_AXI/Mem0] -force

assign_bd_address -offset 0xA4010000 -range 0x00010000 \
    -target_address_space [get_bd_addr_spaces versal_cips_0/M_AXI_FPD] \
    [get_bd_addr_segs axi_gpio_dip_sw/S_AXI/Reg] -force

assign_bd_address -offset 0xA4020000 -range 0x00010000 \
    -target_address_space [get_bd_addr_spaces versal_cips_0/M_AXI_FPD] \
    [get_bd_addr_segs axi_gpio_led/S_AXI/Reg] -force

assign_bd_address -offset 0xA4030000 -range 0x00010000 \
    -target_address_space [get_bd_addr_spaces versal_cips_0/M_AXI_FPD] \
    [get_bd_addr_segs axi_gpio_pb/S_AXI/Reg] -force

assign_bd_address -offset 0xA4040000 -range 0x00010000 \
    -target_address_space [get_bd_addr_spaces versal_cips_0/M_AXI_FPD] \
    [get_bd_addr_segs axi_dma_0/S_AXI_LITE/Reg] -force

assign_bd_address -offset 0xA4050000 -range 0x00010000 \
    -target_address_space [get_bd_addr_spaces versal_cips_0/M_AXI_FPD] \
    [get_bd_addr_segs axi_uartlite_0/S_AXI/Reg] -force

# DMA data paths: MM2S and S2MM -> DDR via PL NoC
# Map both DDR_LOW0 (0-2 GB) and DDR_LOW1 (32-38 GB) so the DMA can reach
# any buffer the kernel's CMA allocator may hand out.
assign_bd_address -offset 0x00000000 -range 0x80000000 \
    -target_address_space [get_bd_addr_spaces axi_dma_0/Data_MM2S] \
    [get_bd_addr_segs axi_noc_ps/S00_INI/C0_DDR_LOW0] -force

assign_bd_address -offset 0x000800000000 -range 0x180000000 \
    -target_address_space [get_bd_addr_spaces axi_dma_0/Data_MM2S] \
    [get_bd_addr_segs axi_noc_ps/S00_INI/C0_DDR_LOW1] -force

assign_bd_address -offset 0x00000000 -range 0x80000000 \
    -target_address_space [get_bd_addr_spaces axi_dma_0/Data_S2MM] \
    [get_bd_addr_segs axi_noc_ps/S00_INI/C0_DDR_LOW0] -force

assign_bd_address -offset 0x000800000000 -range 0x180000000 \
    -target_address_space [get_bd_addr_spaces axi_dma_0/Data_S2MM] \
    [get_bd_addr_segs axi_noc_ps/S00_INI/C0_DDR_LOW1] -force

################################################################
# Step 11: Validate and save
################################################################

 validate_bd_design
 save_bd_design