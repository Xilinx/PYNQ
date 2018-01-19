

proc generate {drv_handle} {
	xdefine_include_file $drv_handle "xparameters.h" "io_switch" "NUM_INSTANCES" "DEVICE_ID"  "C_S_AXI_BASEADDR" "C_S_AXI_HIGHADDR" "C_INTERFACE_TYPE" "C_IO_SWITCH_WIDTH" "C_NUM_PWMS" "C_NUM_TIMERS" "C_NUM_SS"
  ::hsi::utils::define_canonical_xpars $drv_handle "xparameters.h" "io_switch" "NUM_INSTANCES" "DEVICE_ID"  "C_S_AXI_BASEADDR" "C_S_AXI_HIGHADDR" "C_INTERFACE_TYPE" "C_IO_SWITCH_WIDTH" "C_NUM_PWMS" "C_NUM_TIMERS" "C_NUM_SS"
}
