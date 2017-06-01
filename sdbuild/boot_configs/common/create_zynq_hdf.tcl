set cur_dir [pwd]

create_project simple_pynq "${cur_dir}/simple_pynq" -part "$::env(BOARD_PART)"
add_files -fileset constrs_1 -norecurse "$::env(BOARD_CONSTRAINTS)"
create_bd_design "simple_bd"
create_bd_cell -type ip -vlnv xilinx.com:ip:processing_system7:5.5 ps7
set ps7 [get_bd_cells ps7]
apply_bd_automation -rule xilinx.com:bd_rule:processing_system7 -config {make_external "FIXED_IO, DDR" Master "Disable" Slave "Disable" } $ps7
source "$::env(PS_CONFIG_TCL)"
set_property -dict [apply_preset $ps7] $ps7
set_property -dict [list CONFIG.PCW_FPGA1_PERIPHERAL_FREQMHZ {142.86} CONFIG.PCW_FPGA2_PERIPHERAL_FREQMHZ {200} CONFIG.PCW_FPGA3_PERIPHERAL_FREQMHZ {166.67} CONFIG.PCW_EN_CLK1_PORT {1} CONFIG.PCW_EN_CLK2_PORT {1} CONFIG.PCW_EN_CLK3_PORT {1}] $ps7
add_files -norecurse [make_wrapper -files [get_files *.bd] -top]
update_compile_order -fileset sources_1
generate_target all [get_files  *.bd]
write_hwdef -force  -file "${cur_dir}/pynq.hdf"
close_project
