# This script called from xsdk -batch will generate a SDK workspace here 
#   Additionally, will build a hw project and bsp


sdk setws .
if {![file exists "hw_def"]} {
    sdk createhw -name hw_def -hwspec ./iop.hdf
}
if {![file exists "bsp"]} {
    sdk createbsp -name bsp -hwproject hw_def -proc iop1_mb -os standalone
}

sdk build all

puts "To use SDK, from this folder execute"
puts "    xsdk -workspace ."

exit