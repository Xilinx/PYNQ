# Copyright (C) 2021 Xilinx, Inc
#
# SPDX-License-Identifier: BSD-3-Clause

open_project color_convert
set_top color_convert
add_files color_convert/color_convert.cpp
add_files -tb color_convert/color_convert_test.cpp
open_solution "solution1"
set_part {xc7z020clg400-1}
create_clock -period 7
csynth_design
export_design -format ip_catalog -description "Color conversion for 24-bit AXI video stream" -display_name "Color Convert"
exit
