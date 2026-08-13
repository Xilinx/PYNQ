# Copyright (c) 2026, Advanced Micro Devices, Inc.
# SPDX-License-Identifier: BSD-3-Clause
#
# Generic script for building user overlays on top of the VCK190 golden
# reference design.  This script automates the full flow:
#
#   1. Sources golden_ref.tcl (creates CIPS, PS NoC, PL NoC, tie-offs)
#   2. Removes PL tie-offs
#   3. Calls user's create_user_pl_design proc
#   4. Sets segmented_configuration, locks NoC solution
#   5. Runs implementation through write_device_image
#   6. Runs pr_verify against golden routed checkpoint
#   7. Copies PLD PDI to output
#
# Usage:
#   1. Create a TCL file defining proc create_user_pl_design {}
#   2. Source this script:
#        vivado -mode batch -source build_user_overlay.tcl \
#               -tclargs <user_design.tcl> <output_name>
#
# The user's create_user_pl_design proc receives the block design with
# golden reference (CIPS, NoC, clocks/resets) already created and
# tie-offs removed. It should:
#   - Add PL IPs
#   - Connect M_AXI_FPD, M_AXI_LPD to PL peripherals
#   - Connect DMA masters to axi_noc_pl/S00_AXI, S01_AXI
#   - Connect interrupts to versal_cips_0/pl_ps_irq*
#   - Assign addresses
#
# Available resources from golden reference:
#   - versal_cips_0: CIPS with M_AXI_FPD, M_AXI_LPD, pl0-3_ref_clk,
#                    pl0-3_resetn, pl_ps_irq0-15
#   - axi_noc_ps:   PS NoC with DDR (initial_boot), NSI_0 for PL DMA
#   - axi_noc_pl:   PL NoC with S00_AXI, S01_AXI (DMA -> DDR via NMI_0)
#   - rst_pl0..3:   proc_sys_reset for each PL clock domain

if {$argc < 2} {
    puts "Usage: vivado -mode batch -source build_user_overlay.tcl -tclargs <user_design.tcl> <output_name>"
    puts "  user_design.tcl: TCL file defining proc create_user_pl_design {}"
    puts "  output_name:     Name for the output overlay (e.g. 'mydesign')"
    exit 1
}

set user_design_tcl [lindex $argv 0]
set overlay_name    [lindex $argv 1]

if {![file exists $user_design_tcl]} {
    puts "ERROR: User design file not found: $user_design_tcl"
    exit 1
}

set script_dir [file dirname [file normalize [info script]]]
set golden_dir [file normalize [file join $script_dir golden]]

puts "============================================"
puts "PYNQ VCK190 User Overlay Build"
puts "  User design: $user_design_tcl"
puts "  Output name: $overlay_name"
puts "  Golden dir:  $golden_dir"
puts "============================================"

################################################################
# Step 1: Source golden reference design
################################################################
puts "\n--- Step 1: Creating golden reference design ---"
set design_name $overlay_name
source [file join $golden_dir golden_ref.tcl]

################################################################
# Step 2: Remove PL tie-offs
################################################################
puts "\n--- Step 2: Removing PL tie-offs ---"
delete_bd_objs [get_bd_cells pl_tieoff_fpd]
delete_bd_objs [get_bd_cells pl_tieoff_lpd]
delete_bd_objs [get_bd_cells pl_tieoff_dma0]
delete_bd_objs [get_bd_cells pl_tieoff_dma1]
delete_bd_objs [get_bd_cells pl_tieoff_irq]

################################################################
# Step 3: Source user design
################################################################
puts "\n--- Step 3: Applying user PL design ---"
source $user_design_tcl
create_user_pl_design

validate_bd_design
save_bd_design

################################################################
# Step 4: Build
################################################################
puts "\n--- Step 4: Building overlay ---"

make_wrapper -files [get_files [current_bd_design].bd] -top
set wrapper_files [glob -nocomplain \
    ./${overlay_name}/${overlay_name}.gen/sources_1/bd/${overlay_name}/hdl/${overlay_name}_wrapper.v \
    ./${overlay_name}/${overlay_name}.gen/sources_1/bd/${overlay_name}/hdl/${overlay_name}_wrapper.vhd]
if {[llength $wrapper_files] > 0} {
    catch {add_files -norecurse [lindex $wrapper_files 0]}
}

set_property top ${overlay_name}_wrapper [current_fileset]
update_compile_order -fileset sources_1

catch {reset_run synth_1}
catch {reset_run impl_1}

set_property platform.default_output_type "sd_card" [current_project]
set_property platform.design_intent.embedded "true" [current_project]
set_property segmented_configuration true [current_project]

# Lock NoC solution to golden reference
set golden_ncr [file join $golden_dir golden_noc.ncr]
if {[file exists $golden_ncr]} {
    puts "  Locking NoC solution to: $golden_ncr"
    set_property NOC_SOLUTION_FILE [file normalize $golden_ncr] [get_runs impl_1]
} else {
    puts "  WARNING: golden_noc.ncr not found, NoC will not be locked"
}

set num_jobs 4
if {[info exists ::env(VIVADO_JOBS)]} {
    set num_jobs $::env(VIVADO_JOBS)
}

launch_runs impl_1 -to_step write_device_image -jobs $num_jobs
wait_on_run impl_1

set impl_status [get_property STATUS [get_runs impl_1]]
if { [string match "*Complete*" $impl_status] == 0 } {
    puts "ERROR: Implementation failed (status: $impl_status)"
    exit 1
}

################################################################
# Step 5: Verify against golden reference
################################################################
puts "\n--- Step 5: Running pr_verify ---"

set golden_dcp [file join $golden_dir golden_routed.dcp]
if {[file exists $golden_dcp]} {
    set overlay_dcps [glob -nocomplain ./${overlay_name}/${overlay_name}.runs/impl_1/*_routed.dcp]
    if {[llength $overlay_dcps] > 0} {
        set result [catch {pr_verify [file normalize $golden_dcp] [lindex $overlay_dcps 0]} msg]
        if {$result != 0} {
            puts "FAIL: pr_verify detected incompatibility: $msg"
            puts "      Your overlay's NoC configuration does not match the golden reference."
            puts "      The PLD PDI may not work with the golden boot PDI."
        } else {
            puts "PASS: Overlay is compatible with golden reference"
        }
    }
} else {
    puts "WARNING: golden_routed.dcp not found, skipping pr_verify"
}

################################################################
# Step 6: Export artifacts
################################################################
puts "\n--- Step 6: Exporting artifacts ---"

write_hw_platform -fixed -include_bit -force ./${overlay_name}.xsa

set impl_dir "./${overlay_name}/${overlay_name}.runs/impl_1"
set pld_files [glob -nocomplain ${impl_dir}/*_pld.pdi]
if {[llength $pld_files] > 0} {
    file copy -force [lindex $pld_files 0] ${overlay_name}.pdi
    puts "  PLD PDI: ${overlay_name}.pdi"
} else {
    set pdi_files [glob -nocomplain ${impl_dir}/*.pdi]
    if {[llength $pdi_files] > 0} {
        file copy -force [lindex $pdi_files 0] ${overlay_name}.pdi
    } else {
        puts "ERROR: No PDI file found"
        exit 1
    }
}

set hwh_files [glob -nocomplain \
    ./${overlay_name}/${overlay_name}.gen/sources_1/bd/${overlay_name}/hw_handoff/*.hwh]
if {[llength $hwh_files] > 0} {
    file copy -force [lindex $hwh_files 0] ${overlay_name}.hwh
}

puts ""
puts "User overlay build complete:"
puts "  PDI: ${overlay_name}.pdi  (load via PYNQ Overlay class)"
puts "  XSA: ${overlay_name}.xsa"
puts "  HWH: ${overlay_name}.hwh"
