# Copyright (c) 2026, Advanced Micro Devices, Inc.
# SPDX-License-Identifier: BSD-3-Clause
#
# Build the golden reference design: synth, impl, write_device_image,
# export NoC solution, routed checkpoint, and hardware platform (XSA).
#
# Segmented configuration produces boot.pdi (PS/DDR, loaded by PLM)
# and pld.pdi (PL tie-offs, not used at runtime -- overlays replace it).

set overlay_name "golden"
set design_name  "golden"

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

# Export NoC solution for overlay consistency verification
open_run impl_1
write_noc_solution -file golden_noc.ncr -force
puts "Exported NoC solution: golden_noc.ncr"

# Save routed checkpoint for pr_verify
set routed_dcps [glob -nocomplain ./${overlay_name}/${overlay_name}.runs/impl_1/*_routed.dcp]
if {[llength $routed_dcps] > 0} {
    file copy -force [lindex $routed_dcps 0] golden_routed.dcp
    puts "Exported routed checkpoint: golden_routed.dcp"
} else {
    puts "WARNING: No routed DCP found"
}

# Export boot PDI
set impl_dir "./${overlay_name}/${overlay_name}.runs/impl_1"
set boot_files [glob -nocomplain ${impl_dir}/*_boot.pdi]
if {[llength $boot_files] > 0} {
    file copy -force [lindex $boot_files 0] golden_boot.pdi
    puts "Exported boot PDI: golden_boot.pdi"
}

# Export XSA for EDF/BOOT.BIN generation
write_hw_platform -fixed -include_bit -force ./${overlay_name}.xsa
validate_hw_platform ./${overlay_name}.xsa

puts ""
puts "Golden reference build complete:"
puts "  XSA:          ${overlay_name}.xsa  (for EDF BOOT.BIN generation)"
puts "  Boot PDI:     golden_boot.pdi      (PS/DDR boot image)"
puts "  NoC solution: golden_noc.ncr       (overlay consistency contract)"
puts "  Routed DCP:   golden_routed.dcp    (for pr_verify)"
