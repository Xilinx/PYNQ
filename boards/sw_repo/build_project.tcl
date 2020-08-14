# This script will generate platforms/bsp's through xsct

if {$argc != 1} {
    puts "Usage: xsct build_project.tcl <xsa_file_path>"
    exit 1
}

proc connected_to {net ip} {
    set pins [hsi::get_pins -of $net]
    set candidates {}
    foreach pin $pins {
        if {[string equal $pin en]} {
            lappend candidates [hsi::get_cells -of $pin]
        }
    }
    return $candidates
}

proc find_interrupt_gpio {ips} {
    set interrupts {}
    foreach ip $ips {
        set pins [hsi::get_pins -of $ip]
        set pin_index [lsearch $pins gpio_io_o]
        if {$pin_index >= 0} {
            set pin [lindex $pins $pin_index]
            set nets [hsi::get_nets -of $pin]
            if {[llength $nets] > 0} {
                set connected [connected_to [hsi::get_nets -of $pin] $ip]
                foreach candidate $connected {
                    if {[hsi::get_property VLNV $candidate] == "xilinx.com:user:dff_en_reset_vector:1.0"} {
                        lappend interrupts $ip
                    }
                }
            }
        }
    }
    return $interrupts
}

proc find_ip {ips name} {
    return [hsi::get_cells -filter "IP_NAME == $name" $ips]
}

set xsa [lindex $argv 0]
if {![file exists $xsa]} {
    puts "Error: XSA path $xsa does not exist."
    exit 1
}
set hw_proj "hw_build"
if {[file exists [pwd]/$hw_proj]} {
    puts "Error: HW project $hw_proj already exists."
    exit 1
}
setws .
repo -set [pwd]
platform create -name $hw_proj -hw $xsa -proc ps7_cortexa9_0 -os standalone

set processors \
[hsi::get_cells -filter {IP_TYPE == PROCESSOR && IP_NAME == microblaze}]

foreach mb $processors {
    set bsp "bsp_${mb}"
    if {![file exists $bsp]} {
        puts "Creating new BSP ${bsp} ..."
        platform create -name $bsp -hw $xsa -proc $mb -os standalone
        bsp setlib -name pynqmb
        set ips [hsi::get_cells [hsi::get_property SLAVES $mb]]
        set interrupt [find_interrupt_gpio $ips]
        set brams [find_ip $ips lmb_bram_if_cntlr]
        set gpios [find_ip $ips axi_gpio]
        foreach gpio $gpios {
            if {[string equal $gpio $interrupt]} {
                bsp setdriver -ip $gpio -driver "intrgpio"
            } else {
                bsp setdriver -ip $gpio -driver "gpio"
            }
        }
        foreach bram $brams {
          bsp setdriver -ip $bram -driver "mailbox_bram"
        }
        # HACK: Assume that the first BRAM is the one we are
        # using to communicate with the ARM.
        set firstbram [lindex $brams 0]
        bsp config stdin $firstbram
        bsp config stdout $firstbram
        bsp config compiler_flags "-mcpu=v11.0 -mlittle-endian -mxl-soft-mul"
        bsp regenerate
        file copy "[pwd]/lscript.ld" $bsp/${mb}/standalone_domain/bsp
    } else {
        puts "Skipping existing BSP ${bsp} ..."
    }
}
