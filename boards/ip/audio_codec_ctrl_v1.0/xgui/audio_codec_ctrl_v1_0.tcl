# Definitional proc to organize widgets for parameters.
proc init_gui { IPINST } {
  ipgui::add_param $IPINST -name "Component_Name"
  set C_CODEC_ADDRESS [ipgui::add_param $IPINST -name "C_CODEC_ADDRESS" -widget comboBox]
  set_property tooltip {Two bit address} ${C_CODEC_ADDRESS}

}

proc update_PARAM_VALUE.C_BASEADDR { PARAM_VALUE.C_BASEADDR } {
	# Procedure called to update C_BASEADDR when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.C_BASEADDR { PARAM_VALUE.C_BASEADDR } {
	# Procedure called to validate C_BASEADDR
	return true
}

proc update_PARAM_VALUE.C_CODEC_ADDRESS { PARAM_VALUE.C_CODEC_ADDRESS } {
	# Procedure called to update C_CODEC_ADDRESS when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.C_CODEC_ADDRESS { PARAM_VALUE.C_CODEC_ADDRESS } {
	# Procedure called to validate C_CODEC_ADDRESS
	return true
}

proc update_PARAM_VALUE.C_DPHASE_TIMEOUT { PARAM_VALUE.C_DPHASE_TIMEOUT } {
	# Procedure called to update C_DPHASE_TIMEOUT when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.C_DPHASE_TIMEOUT { PARAM_VALUE.C_DPHASE_TIMEOUT } {
	# Procedure called to validate C_DPHASE_TIMEOUT
	return true
}

proc update_PARAM_VALUE.C_HIGHADDR { PARAM_VALUE.C_HIGHADDR } {
	# Procedure called to update C_HIGHADDR when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.C_HIGHADDR { PARAM_VALUE.C_HIGHADDR } {
	# Procedure called to validate C_HIGHADDR
	return true
}

proc update_PARAM_VALUE.C_NUM_MEM { PARAM_VALUE.C_NUM_MEM } {
	# Procedure called to update C_NUM_MEM when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.C_NUM_MEM { PARAM_VALUE.C_NUM_MEM } {
	# Procedure called to validate C_NUM_MEM
	return true
}

proc update_PARAM_VALUE.C_NUM_REG { PARAM_VALUE.C_NUM_REG } {
	# Procedure called to update C_NUM_REG when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.C_NUM_REG { PARAM_VALUE.C_NUM_REG } {
	# Procedure called to validate C_NUM_REG
	return true
}

proc update_PARAM_VALUE.C_SLV_AWIDTH { PARAM_VALUE.C_SLV_AWIDTH } {
	# Procedure called to update C_SLV_AWIDTH when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.C_SLV_AWIDTH { PARAM_VALUE.C_SLV_AWIDTH } {
	# Procedure called to validate C_SLV_AWIDTH
	return true
}

proc update_PARAM_VALUE.C_SLV_DWIDTH { PARAM_VALUE.C_SLV_DWIDTH } {
	# Procedure called to update C_SLV_DWIDTH when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.C_SLV_DWIDTH { PARAM_VALUE.C_SLV_DWIDTH } {
	# Procedure called to validate C_SLV_DWIDTH
	return true
}

proc update_PARAM_VALUE.C_S_AXI_ADDR_WIDTH { PARAM_VALUE.C_S_AXI_ADDR_WIDTH } {
	# Procedure called to update C_S_AXI_ADDR_WIDTH when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.C_S_AXI_ADDR_WIDTH { PARAM_VALUE.C_S_AXI_ADDR_WIDTH } {
	# Procedure called to validate C_S_AXI_ADDR_WIDTH
	return true
}

proc update_PARAM_VALUE.C_S_AXI_DATA_WIDTH { PARAM_VALUE.C_S_AXI_DATA_WIDTH } {
	# Procedure called to update C_S_AXI_DATA_WIDTH when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.C_S_AXI_DATA_WIDTH { PARAM_VALUE.C_S_AXI_DATA_WIDTH } {
	# Procedure called to validate C_S_AXI_DATA_WIDTH
	return true
}

proc update_PARAM_VALUE.C_S_AXI_MIN_SIZE { PARAM_VALUE.C_S_AXI_MIN_SIZE } {
	# Procedure called to update C_S_AXI_MIN_SIZE when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.C_S_AXI_MIN_SIZE { PARAM_VALUE.C_S_AXI_MIN_SIZE } {
	# Procedure called to validate C_S_AXI_MIN_SIZE
	return true
}

proc update_PARAM_VALUE.C_USE_WSTRB { PARAM_VALUE.C_USE_WSTRB } {
	# Procedure called to update C_USE_WSTRB when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.C_USE_WSTRB { PARAM_VALUE.C_USE_WSTRB } {
	# Procedure called to validate C_USE_WSTRB
	return true
}


proc update_MODELPARAM_VALUE.C_S_AXI_DATA_WIDTH { MODELPARAM_VALUE.C_S_AXI_DATA_WIDTH PARAM_VALUE.C_S_AXI_DATA_WIDTH } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.C_S_AXI_DATA_WIDTH}] ${MODELPARAM_VALUE.C_S_AXI_DATA_WIDTH}
}

proc update_MODELPARAM_VALUE.C_S_AXI_ADDR_WIDTH { MODELPARAM_VALUE.C_S_AXI_ADDR_WIDTH PARAM_VALUE.C_S_AXI_ADDR_WIDTH } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.C_S_AXI_ADDR_WIDTH}] ${MODELPARAM_VALUE.C_S_AXI_ADDR_WIDTH}
}

proc update_MODELPARAM_VALUE.C_S_AXI_MIN_SIZE { MODELPARAM_VALUE.C_S_AXI_MIN_SIZE PARAM_VALUE.C_S_AXI_MIN_SIZE } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.C_S_AXI_MIN_SIZE}] ${MODELPARAM_VALUE.C_S_AXI_MIN_SIZE}
}

proc update_MODELPARAM_VALUE.C_USE_WSTRB { MODELPARAM_VALUE.C_USE_WSTRB PARAM_VALUE.C_USE_WSTRB } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.C_USE_WSTRB}] ${MODELPARAM_VALUE.C_USE_WSTRB}
}

proc update_MODELPARAM_VALUE.C_DPHASE_TIMEOUT { MODELPARAM_VALUE.C_DPHASE_TIMEOUT PARAM_VALUE.C_DPHASE_TIMEOUT } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.C_DPHASE_TIMEOUT}] ${MODELPARAM_VALUE.C_DPHASE_TIMEOUT}
}

proc update_MODELPARAM_VALUE.C_BASEADDR { MODELPARAM_VALUE.C_BASEADDR PARAM_VALUE.C_BASEADDR } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.C_BASEADDR}] ${MODELPARAM_VALUE.C_BASEADDR}
}

proc update_MODELPARAM_VALUE.C_HIGHADDR { MODELPARAM_VALUE.C_HIGHADDR PARAM_VALUE.C_HIGHADDR } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.C_HIGHADDR}] ${MODELPARAM_VALUE.C_HIGHADDR}
}

proc update_MODELPARAM_VALUE.C_NUM_REG { MODELPARAM_VALUE.C_NUM_REG PARAM_VALUE.C_NUM_REG } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.C_NUM_REG}] ${MODELPARAM_VALUE.C_NUM_REG}
}

proc update_MODELPARAM_VALUE.C_NUM_MEM { MODELPARAM_VALUE.C_NUM_MEM PARAM_VALUE.C_NUM_MEM } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.C_NUM_MEM}] ${MODELPARAM_VALUE.C_NUM_MEM}
}

proc update_MODELPARAM_VALUE.C_SLV_AWIDTH { MODELPARAM_VALUE.C_SLV_AWIDTH PARAM_VALUE.C_SLV_AWIDTH } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.C_SLV_AWIDTH}] ${MODELPARAM_VALUE.C_SLV_AWIDTH}
}

proc update_MODELPARAM_VALUE.C_SLV_DWIDTH { MODELPARAM_VALUE.C_SLV_DWIDTH PARAM_VALUE.C_SLV_DWIDTH } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.C_SLV_DWIDTH}] ${MODELPARAM_VALUE.C_SLV_DWIDTH}
}

proc update_MODELPARAM_VALUE.C_CODEC_ADDRESS { MODELPARAM_VALUE.C_CODEC_ADDRESS PARAM_VALUE.C_CODEC_ADDRESS } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.C_CODEC_ADDRESS}] ${MODELPARAM_VALUE.C_CODEC_ADDRESS}
}

