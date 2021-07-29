# Copyright (C) 2021 Xilinx, Inc
#
# SPDX-License-Identifier: BSD-3-Clause

open_project trace_cntrl_64
set_top trace_cntrl_64
add_files trace_cntrl_64/trace_cntrl_64.cpp
open_solution "solution1"
set_part {xc7z020clg484-1}
create_clock -period 10
csynth_design
export_design -format ip_catalog -description "Controller for the trace analyzer with 64-bit data" -version "1.4" -display_name "Trace Analyzer Controller with 64 Bits Data"
exit
