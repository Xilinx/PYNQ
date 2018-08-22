open_project pixel_pack_2
set_top pixel_pack_2
add_files pixel_pack_2/pixel_pack.cpp
add_files -tb pixel_pack_2/pixel_pack_test.cpp
open_solution "solution1"
set_part {xczu7ev-ffvc1156-2-i-es2} -tool vivado
create_clock -period 3.3 -name default
csynth_design
export_design -format ip_catalog -description "Pixel Packing from 24-bit to 32-bit" -display_name "Pixel Pack (2 ppc)"
exit
