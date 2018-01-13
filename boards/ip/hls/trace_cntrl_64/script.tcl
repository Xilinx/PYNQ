open_project trace_cntrl_64
set_top trace_cntrl_64
add_files trace_cntrl_64/trace_cntrl_64.cpp
open_solution "solution1"
set_part {xc7z020clg484-1}
create_clock -period 10 -name default
csynth_design
export_design -format ip_catalog -description "Controller for the PYNQ Trace Analyser with 64 Bits data" -version "1.4" -display_name "Trace Analyser Controller with 64 Bits Data"
exit
