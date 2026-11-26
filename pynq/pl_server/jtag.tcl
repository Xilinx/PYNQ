# Copyright (C) 2026 Advanced Micro Devices, Inc.
# SPDX-License-Identifier: BSD-3-Clause

proc pynq_request {id operation args} {
    if {[catch {
        switch -- $operation {
            connect {
                open_hw_manager
                connect_hw_server -url localhost:3121
                set targets [get_hw_targets]
                set requested [encoding convertfrom utf-8 [binary decode hex [lindex $args 0]]]
                if {$requested eq ""} {
                    if {[llength $targets] != 1} {
                        error "Expected one JTAG target; found: $targets"
                    }
                    set selected [lindex $targets 0]
                } else {
                    set selected [lsearch -exact -inline $targets $requested]
                    if {$selected eq ""} {
                        error "JTAG target $requested not found; available: $targets"
                    }
                }
                current_hw_target $selected
                open_hw_target
                set devices [get_hw_devices -filter {PROGRAM.IS_SUPPORTED == 1}]
                if {[llength $devices] != 1} {
                    error "Expected one FPGA; found: $devices"
                }
                current_hw_device [lindex $devices 0]
                set result [join [list $selected [current_hw_device] [get_property PART [current_hw_device]]] "\n"]
            }
            program {
                set file [encoding convertfrom utf-8 [binary decode hex [lindex $args 0]]]
                set_property PROGRAM.FILE $file [current_hw_device]
                program_hw_devices [current_hw_device]
                refresh_hw_device [current_hw_device]
                set axes [get_hw_axis]
                if {[llength $axes] != 1} {
                    error "Expected one JTAG AXI master; found: $axes"
                }
                set ::pynq_axi [lindex $axes 0]
                reset_hw_axi $::pynq_axi
                set result ok
            }
            read {
                set address [lindex $args 0]
                set count [lindex $args 1]
                set txn [create_hw_axi_txn pynq_read $::pynq_axi -force -type READ -address $address -len $count]
                if {[catch {run_hw_axi $txn; set result [get_property DATA $txn]} err]} {
                    delete_hw_axi_txn $txn
                    error $err
                }
                delete_hw_axi_txn $txn
            }
            write {
                set address [lindex $args 0]
                set count [lindex $args 1]
                set data [lindex $args 2]
                set txn [create_hw_axi_txn pynq_write $::pynq_axi -force -type WRITE -address $address -len $count -data $data]
                if {[catch {run_hw_axi $txn} err]} {
                    delete_hw_axi_txn $txn
                    error $err
                }
                delete_hw_axi_txn $txn
                set result ok
            }
            default {error "Unknown operation"}
        }
    } message]} {
        puts "@@PYNQ@@ $id ERROR [binary encode hex [encoding convertto utf-8 $message]]"
    } else {
        puts "@@PYNQ@@ $id OK [binary encode hex [encoding convertto utf-8 $result]]"
    }
    flush stdout
}

while {[gets stdin request] >= 0} {
    uplevel #0 $request
}
