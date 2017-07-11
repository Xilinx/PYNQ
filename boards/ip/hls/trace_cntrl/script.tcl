open_project trace_cntrl
set_top trace_cntrl
add_files trace_cntrl/trace_cntrl.cpp
open_solution "solution1"
set_part {xc7z020clg484-1}
create_clock -period 10 -name default
#source "./trace_cntrl/solution1/directives.tcl"
#csim_design
csynth_design
#cosim_design
export_design -format ip_catalog -description "Controller for the PYNQ Trace Analyser" -vendor "xilinx" -version "1.3" -display_name "Trace Analyser Controller"
exit
