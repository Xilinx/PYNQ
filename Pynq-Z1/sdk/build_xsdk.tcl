# This script called from xsdk -batch will generate a SDK workspace here 
#   Additionally, will build a hw project and bsp

sdk setws .
if {![file exists "hw_def"]} {
    sdk createhw -name hw_def -hwspec ./base.hdf
}
if {![file exists "bsp_pmod"]} {
    sdk createbsp -name bsp_pmod -hwproject hw_def -proc iop1_mb -os standalone
}
if {![file exists "bsp_arduino"]} {
    sdk createbsp -name bsp_arduino -hwproject hw_def -proc iop3_mb -os standalone
}

sdk build all

puts "To use SDK, from this folder execute"
puts "    xsdk -workspace ."

exit