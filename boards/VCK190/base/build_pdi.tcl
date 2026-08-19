# Copyright (c) 2026, Advanced Micro Devices, Inc.
# SPDX-License-Identifier: BSD-3-Clause
#
# Build PDI and export hardware platform for VCK190 base overlay.
# Uses Segmented Configuration: produces boot.pdi + pld.pdi
#
# The NoC solution is locked to the golden reference (golden_noc.ncr).
# check_compatibility.tcl verifies the result against the golden reference.

set overlay_name "base"
set design_name "vck190_pynq"

open_project ./${overlay_name}/${overlay_name}.xpr

open_bd_design ./${overlay_name}/${overlay_name}.srcs/sources_1/bd/${design_name}/${design_name}.bd
set locked_ips [get_ips -filter {IS_LOCKED == 1}]
if {[llength $locked_ips] > 0} {
    puts "Upgrading [llength $locked_ips] locked IP(s)..."
    upgrade_ip $locked_ips
    validate_bd_design
    save_bd_design
}

make_wrapper -files [get_files ./${overlay_name}/${overlay_name}.srcs/sources_1/bd/${design_name}/${design_name}.bd] -top

set wrapper_files [glob -nocomplain \
    ./${overlay_name}/${overlay_name}.gen/sources_1/bd/${design_name}/hdl/${design_name}_wrapper.v \
    ./${overlay_name}/${overlay_name}.gen/sources_1/bd/${design_name}/hdl/${design_name}_wrapper.vhd \
    ./${overlay_name}/${overlay_name}.srcs/sources_1/bd/${design_name}/hdl/${design_name}_wrapper.v]
if {[llength $wrapper_files] > 0} {
    catch {add_files -norecurse [lindex $wrapper_files 0]}
} else {
    catch {add_files -norecurse ./${overlay_name}/${overlay_name}.gen/sources_1/bd/${design_name}/hdl/${design_name}_wrapper.v}
}

set_property top ${design_name}_wrapper [current_fileset]
update_compile_order -fileset sources_1

catch {reset_run synth_1}
catch {reset_run impl_1}

set_property platform.default_output_type "sd_card" [current_project]
set_property platform.design_intent.embedded "true" [current_project]
set_property platform.design_intent.server_managed "false" [current_project]
set_property platform.design_intent.external_host "false" [current_project]
set_property platform.design_intent.datacenter "false" [current_project]

set_property segmented_configuration true [current_project]

# Lock NoC solution to match golden reference
set golden_ncr "../golden/golden_noc.ncr"
if {[file exists $golden_ncr]} {
    puts "Locking NoC solution to golden reference: $golden_ncr"
    set_property NOC_SOLUTION_FILE [file normalize $golden_ncr] [get_runs impl_1]
} else {
    puts "WARNING: Golden NoC solution not found at $golden_ncr"
    puts "         Overlay will use its own NoC solution (may differ from boot PDI)"
}

set num_jobs 4
if {[info exists ::env(VIVADO_JOBS)]} {
    set num_jobs $::env(VIVADO_JOBS)
}

launch_runs impl_1 -to_step write_device_image -jobs $num_jobs
wait_on_run impl_1

set impl_status [get_property STATUS [get_runs impl_1]]
puts "Implementation status: $impl_status"

if { [string match "*Complete*" $impl_status] == 0 } {
    puts "ERROR: Implementation did not complete successfully (status: $impl_status)"
    exit 1
}

write_hw_platform -fixed -include_bit -force ./${overlay_name}.xsa
validate_hw_platform ./${overlay_name}.xsa

# Extract PLD PDI
set impl_dir "./${overlay_name}/${overlay_name}.runs/impl_1"

set pld_files [glob -nocomplain ${impl_dir}/*_pld.pdi]
if {[llength $pld_files] > 0} {
    file copy -force [lindex $pld_files 0] ${overlay_name}.pdi
    puts "Copied PLD PDI: [lindex $pld_files 0] -> ${overlay_name}.pdi"
} else {
    set pdi_files [glob -nocomplain ${impl_dir}/*.pdi]
    if {[llength $pdi_files] > 0} {
        file copy -force [lindex $pdi_files 0] ${overlay_name}.pdi
        puts "Copied PDI (non-segmented): [lindex $pdi_files 0] -> ${overlay_name}.pdi"
    } else {
        puts "ERROR: No PDI file found in implementation results"
        exit 1
    }
}

set boot_files [glob -nocomplain ${impl_dir}/*_boot.pdi]
if {[llength $boot_files] > 0} {
    file copy -force [lindex $boot_files 0] ${overlay_name}_boot.pdi
    puts "Copied Boot PDI: [lindex $boot_files 0] -> ${overlay_name}_boot.pdi"
}

# Copy HWH
set hwh_files [glob -nocomplain \
    ./${overlay_name}/${overlay_name}.gen/sources_1/bd/${design_name}/hw_handoff/${design_name}.hwh \
    ./${overlay_name}/${overlay_name}.gen/sources_1/bd/${design_name}/hw_handoff/*.hwh]
if {[llength $hwh_files] > 0} {
    file copy -force [lindex $hwh_files 0] ${overlay_name}.hwh
} else {
    puts "WARNING: No HWH file found, check XSA for hardware metadata"
}

puts ""
puts "VCK190 base overlay built successfully (Segmented Configuration):"
puts "  PLD PDI: ${overlay_name}.pdi (load this at runtime via PYNQ)"
if {[llength $boot_files] > 0} {
    puts "  Boot PDI: ${overlay_name}_boot.pdi (reference only, golden provides boot)"
}
puts "  HWH:     ${overlay_name}.hwh"
puts "  XSA:     ${overlay_name}.xsa"
