# This constraints file contains default clock frequencies to be used during 
# out-of-context flows such as OOC Synthesis and Hierarchical Designs. For 
# best results the frequencies should be modified to match the target 
# frequencies. This constraints file is not used in normal top-down 
# synthesis (the default flow of Vivado)

create_clock -period 33.333 [get_ports Dbg_Clk]
create_clock -period 33.333 [get_ports Dbg_Update]
set_clock_groups -asynchronous -group [get_clocks -of_objects [get_ports Dbg_Clk]]
set_clock_groups -asynchronous -group [get_clocks -of_objects [get_ports Dbg_Update]]
set_clock_groups -logically_exclusive \
  -group [get_clocks -of_objects [get_ports Dbg_Clk]] \
  -group [get_clocks -of_objects [get_ports Dbg_Update]]
