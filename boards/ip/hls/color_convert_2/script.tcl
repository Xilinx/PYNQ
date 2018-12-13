open_project color_convert_2
set_top color_convert_2
add_files color_convert_2/color_convert.cpp
add_files -tb color_convert_2/color_convert_test.cpp
open_solution "solution1"
set_part {xczu7ev-ffvc1156-2-i} -tool vivado
create_clock -period 3.3 -name default
csynth_design
export_design -format ip_catalog -description "Color conversion for 24-bit AXI video stream" -display_name "Color Convert (2 ppc)"
exit
