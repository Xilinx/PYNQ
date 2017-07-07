open_project pixel_unpack
set_top pixel_unpack
add_files pixel_unpack/pixel_unpack.cpp
add_files -tb pixel_unpack/pixel_unpack_test.cpp
open_solution "solution1"
set_part {xc7z020clg400-1} -tool vivado
create_clock -period 7 -name default
create_clock -period 10 -name control
#source "./pixel_unpack2/solution1/directives.tcl"
csim_design
csynth_design
# cosim_design -trace_level port -tool xsim
export_design -format ip_catalog
exit
