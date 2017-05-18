open_project color_convert
set_top color_convert
add_files color_convert/color_convert.cpp
add_files -tb color_convert/color_convert_test.cpp
open_solution "solution1"
set_part {xc7z020clg400-1} -tool vivado
create_clock -period 7 -name default
create_clock -period 10 -name control
#source "./color_convert/solution1/directives.tcl"
csim_design
csynth_design
# cosim_design -trace_level all -tool xsim
export_design -format ip_catalog -description "Color Conversion for 24-bit AXI video stream" -display_name "Color Convert"
exit
