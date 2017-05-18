open_project pixel_pack
set_top pixel_pack
add_files pixel_pack/pixel_pack.cpp
add_files -tb pixel_pack/pixel_pack_test.cpp
open_solution "solution1"
set_part {xc7z020clg400-1} -tool vivado
create_clock -period 7 -name default
create_clock -period 10 -name control
csim_design
csynth_design
# cosim_design -trace_level all -tool xsim
export_design -format ip_catalog
exit
