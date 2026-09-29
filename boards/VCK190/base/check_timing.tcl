# Copyright (c) 2026, Advanced Micro Devices, Inc.
# SPDX-License-Identifier: BSD-3-Clause
#
# Fail the build if the implemented overlay does not meet timing.

set overlay_name "base"

open_project ./${overlay_name}/${overlay_name}.xpr

set run [get_runs impl_1]
set wns [get_property STATS.WNS $run]
set whs [get_property STATS.WHS $run]

puts "Worst negative slack: ${wns} ns"
puts "Worst hold slack:     ${whs} ns"

if {$wns <= 0 || $whs <= 0} {
    puts "ERROR: ${overlay_name} does not meet timing."
    exit 1
}

puts "Timing constraints are met."
