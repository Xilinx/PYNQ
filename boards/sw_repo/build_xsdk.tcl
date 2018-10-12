# This script will generate SDK workspace, build a hw project and bsp

if {$argc != 2} {
    puts "Usage:\
    xsdk -batch -source build_xsdk.tcl <hdf_file_path> <hw_def_name>"
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

set hdf [lindex $argv 0]
if {![file exists $hdf]} {
    puts "Error: HDF path $hdf does not exist."
    exit 1
}
set hw_def [lindex $argv 1]
if {[file exists [pwd]/$hw_def]} {
    puts "Error: HW project $hw_def already exists."
    exit 1
}
setws .
repo -set [pwd]
createhw -name $hw_def -hwspec $hdf

set processors \
[hsi::get_cells -filter {IP_TYPE == PROCESSOR && IP_NAME == microblaze}]

foreach mb $processors {
    set bsp "bsp_${mb}"
    if {![file exists $bsp]} {
        puts "Creating new BSP ${bsp} ..."
        createbsp -name $bsp -proc $mb -hwproject $hw_def -os standalone
        setlib -bsp $bsp -lib pynqmb
        set ips [hsi::get_cells [hsi::get_property SLAVES $mb]]
        set interrupt [find_interrupt_gpio $ips]
        set brams [find_ip $ips lmb_bram_if_cntlr]
        set gpios [find_ip $ips axi_gpio]
        foreach gpio $gpios {
            if {[string equal $gpio $interrupt]} {
                setdriver -bsp $bsp -ip $gpio -driver "intrgpio"
            } else {
                setdriver -bsp $bsp -ip $gpio -driver "gpio"
            }
        }
        foreach bram $brams {
          setdriver -bsp $bsp -ip $bram -driver "mailbox_bram"
        }
        # HACK: Assume that the first BRAM is the one we are
        # using to communicate
        # with the ARM.
        set firstbram [lindex $brams 0]
        configbsp -bsp $bsp stdin $firstbram
        configbsp -bsp $bsp stdout $firstbram
        regenbsp -bsp $bsp
        file copy "[pwd]/lscript.ld" $bsp
    } else {
        puts "Skipping existing BSP ${bsp} ..."
    }
}

projects -build
