set overlay_name "base"
set design_name "base"

# open project and block design
open_project -quiet ./${overlay_name}/${overlay_name}.xpr
open_bd_design ./${overlay_name}/${overlay_name}.srcs/sources_1/bd/${design_name}/${design_name}.bd

# set sdx platform properties
set_property PFM_NAME "xilinx.com:xd:${overlay_name}:1.0" \
        [get_files ./${overlay_name}/${overlay_name}.srcs/sources_1/bd/${design_name}/${design_name}.bd]
set_property PFM.CLOCK { \
    pl_clk0 {id "0" is_default "true" proc_sys_reset "proc_sys_reset_0" } \
    pl_clk1 {id "1" is_default "false" proc_sys_reset "proc_sys_reset_1" } \
    pl_clk2 {id "2" is_default "false" proc_sys_reset "proc_sys_reset_2" } \
    pl_clk3 {id "3" is_default "false" proc_sys_reset "proc_sys_reset_3" } \
    } [get_bd_cells /ps_e_0]
set_property PFM.AXI_PORT { \
    M_AXI_HPM0_FPD {memport "M_AXI_GP"} \
    M_AXI_HPM1_FPD {memport "M_AXI_GP"} \
    S_AXI_HPC0_FPD {memport "S_AXI_HPC"} \
    S_AXI_HPC1_FPD {memport "S_AXI_HPC"} \
    S_AXI_HP1_FPD {memport "S_AXI_HP"} \
    S_AXI_HP3_FPD {memport "S_AXI_HP"} \
    S_AXI_LPD {memport "S_AXI_HP"} \
    } [get_bd_cells /ps_e_0]
set intVar []
for {set i 1} {$i < 8} {incr i} {
    lappend intVar In$i {}
}
set_property PFM.IRQ $intVar [get_bd_cells /xlconcat_0]

# generate dsa
write_dsa -force ./${overlay_name}.dsa
validate_dsa ./${overlay_name}.dsa