# Copyright (C) 2021 Xilinx, Inc
#
# SPDX-License-Identifier: BSD-3-Clause

open_project pixel_unpack
set_top pixel_unpack
add_files pixel_unpack/pixel_unpack.cpp
add_files -tb pixel_unpack/pixel_unpack_test.cpp
open_solution "solution1"
set_part {xc7z020clg400-1}
create_clock -period 7
csynth_design
export_design -format ip_catalog -description "Pixel Unpacking from 32-bit to 24-bit" -display_name "Pixel Unpack"
exit
