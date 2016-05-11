# This script called from xsdk -batch will generate a SDK workspace here 
#   Additionally, will build a hw project and bsp


sdk set_workspace .
if {![file exists "hw_def"]} {
    sdk create_hw_project -name hw_def -hwspec ./pmod.hdf
}
if {![file exists "bsp"]} {
    sdk create_bsp_project -name bsp -hwproject hw_def -proc iop1_mb -os standalone
}


if {![file exists "sdk_import"]} {
   file mkdir sdk_import
   file copy -force mailbox sdk_import
}

sdk import_project sdk_import/mailbox

#sdk build all

puts "To use SDK, from this folder execute"
puts "    xsdk -workspace ."

exit