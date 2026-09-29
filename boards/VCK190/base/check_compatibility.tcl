# Copyright (c) 2026, Advanced Micro Devices, Inc.
# SPDX-License-Identifier: BSD-3-Clause
#
# Check this overlay against the golden reference: the PS-PL boundary via
# pr_verify, and the parent-image UID that the PLM enforces when it loads a
# PL PDI. See ../golden/README.md.

set overlay_name "base"
set design_name "vck190_pynq"

set golden_dir "../golden"
set golden_dcp ${golden_dir}/golden_routed.dcp
set golden_boot ${golden_dir}/golden_boot.pdi
set overlay_pdi ./${overlay_name}.pdi

foreach f [list $golden_dcp $golden_boot $overlay_pdi] {
    if {![file exists $f]} {
        error "$f not found. Build the golden reference and the overlay first."
    }
}

set routed_dcps [glob -nocomplain ./${overlay_name}/${overlay_name}.runs/impl_1/*_routed.dcp]
if {[llength $routed_dcps] == 0} {
    error "No routed checkpoint found for ${overlay_name}."
}
set overlay_dcp [lindex $routed_dcps 0]

# Maps each image node id in a PDI to its unique_id and parent_unique_id.
# bootgen drops an optional_data.txt beside the image it reads, so clean it up.
proc pdi_image_ids {pdi} {
    set ids [dict create]
    set node ""
    set dump [exec bootgen -arch versal -read $pdi]
    file delete -force optional_data.txt \
        [file join [file dirname $pdi] optional_data.txt]
    foreach line [split $dump "\n"] {
        if {[regexp {id \(0x18\) : 0x([0-9a-fA-F]+).*unique_id \(0x24\) : 0x([0-9a-fA-F]+)} \
                 $line -> node uid]} {
            dict set ids $node uid $uid
        } elseif {[regexp {parent_unique_id \(0x28\) : 0x([0-9a-fA-F]+)} $line -> puid]} {
            if {$node ne ""} {
                dict set ids $node puid $puid
            }
        }
    }
    return $ids
}

set boot_ids [pdi_image_ids $golden_boot]
if {![dict exists $boot_ids 18700000 uid]} {
    error "No PL image (node 0x18700000) in ${golden_boot}."
}
set boot_uid [dict get $boot_ids 18700000 uid]

set pld_puid ""
dict for {node fields} [pdi_image_ids $overlay_pdi] {
    if {[string match 1870* $node] && [dict exists $fields puid]} {
        set pld_puid [dict get $fields puid]
    }
}
if {$pld_puid eq ""} {
    error "No parent_unique_id in ${overlay_pdi}."
}

puts "Golden boot image unique_id:   0x${boot_uid}"
puts "Overlay parent_unique_id:      0x${pld_puid}"

if {![string equal -nocase $boot_uid $pld_puid]} {
    error "Overlay was not built against this golden reference; the PLM will reject it."
}

open_project ./${overlay_name}/${overlay_name}.xpr
pr_verify -initial [file normalize $golden_dcp] -additional $overlay_dcp

puts "Overlay is compatible with the golden reference."
