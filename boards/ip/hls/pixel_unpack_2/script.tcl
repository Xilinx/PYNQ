# Copyright (C) 2021 Xilinx, Inc
#
# SPDX-License-Identifier: BSD-3-Clause

open_project pixel_unpack_2
set_top pixel_unpack_2
add_files pixel_unpack_2/pixel_unpack.cpp
add_files -tb pixel_unpack_2/pixel_unpack_test.cpp
open_solution "solution1"
set_part {xczu7ev-ffvc1156-2-i}
create_clock -period 3.3
csynth_design
export_design -format ip_catalog -description "Pixel Unpacking from 64-bit to 48-bit" -display_name "Pixel Unpack (2ppc)"
exit
