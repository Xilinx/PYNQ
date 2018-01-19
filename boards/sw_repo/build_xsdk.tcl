# This script will generate SDK workspace, build a hw project and bsp

if {$argc != 2} {
    puts "Usage:\
    xsdk -batch -source build_xsdk.tcl <hdf_file_path> <hw_def_name>"
    exit 1
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
        regenbsp -bsp $bsp
    } else {
        puts "Skipping existing BSP ${bsp} ..."
    }
}

projects -build
