# Copyright (C) 2021 Xilinx, Inc
#
# SPDX-License-Identifier: BSD-3-Clause

open_project pixel_pack
set_top pixel_pack
add_files pixel_pack/pixel_pack.cpp
add_files -tb pixel_pack/pixel_pack_test.cpp
open_solution "solution1"
set_part {xc7z020clg400-1}
create_clock -period 7
csynth_design
export_design -format ip_catalog -description "Pixel Packing from 24-bit to 32-bit" -display_name "Pixel Pack"
exit
