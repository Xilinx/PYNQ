open_project trace_cntrl_64_2
set_top trace_cntrl_64_2
add_files trace_cntrl_64_2/trace_cntrl_64.cpp
open_solution "solution1"
set_part {xczu5eg-sfvc784-1-e} -tool vivado
create_clock -period 10 -name default
csynth_design
export_design -format ip_catalog -description "Controller for the trace analyzer with 64-bit data" -version "1.4" -display_name "Trace Analyzer Controller with 64 Bits Data"
exit
