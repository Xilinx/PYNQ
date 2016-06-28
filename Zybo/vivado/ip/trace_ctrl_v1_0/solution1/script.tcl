############################################################
## This file is generated automatically by Vivado HLS.
## Please DO NOT edit it.
## Copyright (C) 2015 Xilinx Inc. All rights reserved.
############################################################
open_project trace_ip
set_top trace_controller
add_files trace_ip/trace_controller.cpp
open_solution "solution1"
set_part {xc7z020clg484-1}
create_clock -period 10 -name default
#source "./trace_ip/solution1/directives.tcl"
#csim_design
csynth_design
#cosim_design
export_design -format ip_catalog -display_name "trace_controller"
