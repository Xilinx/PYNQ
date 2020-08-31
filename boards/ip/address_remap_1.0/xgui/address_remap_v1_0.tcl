# Definitional proc to organize widgets for parameters.
proc init_gui { IPINST } {
  ipgui::add_param $IPINST -name "Component_Name"
  #Adding Page
  set Page_0 [ipgui::add_page $IPINST -name "Page 0"]
  ipgui::add_param $IPINST -name "C_M_AXI_out_TARGET_SLAVE_BASE_ADDR" -parent ${Page_0}
  ipgui::add_param $IPINST -name "C_M_AXI_out_BURST_LEN" -parent ${Page_0} -widget comboBox
  ipgui::add_param $IPINST -name "C_M_AXI_out_ID_WIDTH" -parent ${Page_0}
  ipgui::add_param $IPINST -name "C_M_AXI_out_ADDR_WIDTH" -parent ${Page_0}
  ipgui::add_param $IPINST -name "C_M_AXI_out_DATA_WIDTH" -parent ${Page_0} -widget comboBox
  ipgui::add_param $IPINST -name "C_M_AXI_out_AWUSER_WIDTH" -parent ${Page_0}
  ipgui::add_param $IPINST -name "C_M_AXI_out_ARUSER_WIDTH" -parent ${Page_0}
  ipgui::add_param $IPINST -name "C_M_AXI_out_WUSER_WIDTH" -parent ${Page_0}
  ipgui::add_param $IPINST -name "C_M_AXI_out_RUSER_WIDTH" -parent ${Page_0}
  ipgui::add_param $IPINST -name "C_M_AXI_out_BUSER_WIDTH" -parent ${Page_0}
  ipgui::add_param $IPINST -name "C_S_AXI_in_ID_WIDTH" -parent ${Page_0}
  ipgui::add_param $IPINST -name "C_S_AXI_in_DATA_WIDTH" -parent ${Page_0} -widget comboBox
  ipgui::add_param $IPINST -name "C_S_AXI_in_ADDR_WIDTH" -parent ${Page_0}
  ipgui::add_param $IPINST -name "C_S_AXI_in_AWUSER_WIDTH" -parent ${Page_0}
  ipgui::add_param $IPINST -name "C_S_AXI_in_ARUSER_WIDTH" -parent ${Page_0}
  ipgui::add_param $IPINST -name "C_S_AXI_in_WUSER_WIDTH" -parent ${Page_0}
  ipgui::add_param $IPINST -name "C_S_AXI_in_RUSER_WIDTH" -parent ${Page_0}
  ipgui::add_param $IPINST -name "C_S_AXI_in_BUSER_WIDTH" -parent ${Page_0}
  ipgui::add_param $IPINST -name "C_S_AXI_in_BASEADDR" -parent ${Page_0}
  ipgui::add_param $IPINST -name "C_S_AXI_in_HIGHADDR" -parent ${Page_0}


}

proc update_PARAM_VALUE.C_M_AXI_out_TARGET_SLAVE_BASE_ADDR { PARAM_VALUE.C_M_AXI_out_TARGET_SLAVE_BASE_ADDR } {
	# Procedure called to update C_M_AXI_out_TARGET_SLAVE_BASE_ADDR when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.C_M_AXI_out_TARGET_SLAVE_BASE_ADDR { PARAM_VALUE.C_M_AXI_out_TARGET_SLAVE_BASE_ADDR } {
	# Procedure called to validate C_M_AXI_out_TARGET_SLAVE_BASE_ADDR
	return true
}

proc update_PARAM_VALUE.C_M_AXI_out_BURST_LEN { PARAM_VALUE.C_M_AXI_out_BURST_LEN } {
	# Procedure called to update C_M_AXI_out_BURST_LEN when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.C_M_AXI_out_BURST_LEN { PARAM_VALUE.C_M_AXI_out_BURST_LEN } {
	# Procedure called to validate C_M_AXI_out_BURST_LEN
	return true
}

proc update_PARAM_VALUE.C_M_AXI_out_ID_WIDTH { PARAM_VALUE.C_M_AXI_out_ID_WIDTH } {
	# Procedure called to update C_M_AXI_out_ID_WIDTH when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.C_M_AXI_out_ID_WIDTH { PARAM_VALUE.C_M_AXI_out_ID_WIDTH } {
	# Procedure called to validate C_M_AXI_out_ID_WIDTH
	return true
}

proc update_PARAM_VALUE.C_M_AXI_out_ADDR_WIDTH { PARAM_VALUE.C_M_AXI_out_ADDR_WIDTH } {
	# Procedure called to update C_M_AXI_out_ADDR_WIDTH when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.C_M_AXI_out_ADDR_WIDTH { PARAM_VALUE.C_M_AXI_out_ADDR_WIDTH } {
	# Procedure called to validate C_M_AXI_out_ADDR_WIDTH
	return true
}

proc update_PARAM_VALUE.C_M_AXI_out_DATA_WIDTH { PARAM_VALUE.C_M_AXI_out_DATA_WIDTH } {
	# Procedure called to update C_M_AXI_out_DATA_WIDTH when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.C_M_AXI_out_DATA_WIDTH { PARAM_VALUE.C_M_AXI_out_DATA_WIDTH } {
	# Procedure called to validate C_M_AXI_out_DATA_WIDTH
	return true
}

proc update_PARAM_VALUE.C_M_AXI_out_AWUSER_WIDTH { PARAM_VALUE.C_M_AXI_out_AWUSER_WIDTH } {
	# Procedure called to update C_M_AXI_out_AWUSER_WIDTH when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.C_M_AXI_out_AWUSER_WIDTH { PARAM_VALUE.C_M_AXI_out_AWUSER_WIDTH } {
	# Procedure called to validate C_M_AXI_out_AWUSER_WIDTH
	return true
}

proc update_PARAM_VALUE.C_M_AXI_out_ARUSER_WIDTH { PARAM_VALUE.C_M_AXI_out_ARUSER_WIDTH } {
	# Procedure called to update C_M_AXI_out_ARUSER_WIDTH when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.C_M_AXI_out_ARUSER_WIDTH { PARAM_VALUE.C_M_AXI_out_ARUSER_WIDTH } {
	# Procedure called to validate C_M_AXI_out_ARUSER_WIDTH
	return true
}

proc update_PARAM_VALUE.C_M_AXI_out_WUSER_WIDTH { PARAM_VALUE.C_M_AXI_out_WUSER_WIDTH } {
	# Procedure called to update C_M_AXI_out_WUSER_WIDTH when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.C_M_AXI_out_WUSER_WIDTH { PARAM_VALUE.C_M_AXI_out_WUSER_WIDTH } {
	# Procedure called to validate C_M_AXI_out_WUSER_WIDTH
	return true
}

proc update_PARAM_VALUE.C_M_AXI_out_RUSER_WIDTH { PARAM_VALUE.C_M_AXI_out_RUSER_WIDTH } {
	# Procedure called to update C_M_AXI_out_RUSER_WIDTH when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.C_M_AXI_out_RUSER_WIDTH { PARAM_VALUE.C_M_AXI_out_RUSER_WIDTH } {
	# Procedure called to validate C_M_AXI_out_RUSER_WIDTH
	return true
}

proc update_PARAM_VALUE.C_M_AXI_out_BUSER_WIDTH { PARAM_VALUE.C_M_AXI_out_BUSER_WIDTH } {
	# Procedure called to update C_M_AXI_out_BUSER_WIDTH when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.C_M_AXI_out_BUSER_WIDTH { PARAM_VALUE.C_M_AXI_out_BUSER_WIDTH } {
	# Procedure called to validate C_M_AXI_out_BUSER_WIDTH
	return true
}

proc update_PARAM_VALUE.C_S_AXI_in_ID_WIDTH { PARAM_VALUE.C_S_AXI_in_ID_WIDTH } {
	# Procedure called to update C_S_AXI_in_ID_WIDTH when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.C_S_AXI_in_ID_WIDTH { PARAM_VALUE.C_S_AXI_in_ID_WIDTH } {
	# Procedure called to validate C_S_AXI_in_ID_WIDTH
	return true
}

proc update_PARAM_VALUE.C_S_AXI_in_DATA_WIDTH { PARAM_VALUE.C_S_AXI_in_DATA_WIDTH } {
	# Procedure called to update C_S_AXI_in_DATA_WIDTH when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.C_S_AXI_in_DATA_WIDTH { PARAM_VALUE.C_S_AXI_in_DATA_WIDTH } {
	# Procedure called to validate C_S_AXI_in_DATA_WIDTH
	return true
}

proc update_PARAM_VALUE.C_S_AXI_in_ADDR_WIDTH { PARAM_VALUE.C_S_AXI_in_ADDR_WIDTH } {
	# Procedure called to update C_S_AXI_in_ADDR_WIDTH when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.C_S_AXI_in_ADDR_WIDTH { PARAM_VALUE.C_S_AXI_in_ADDR_WIDTH } {
	# Procedure called to validate C_S_AXI_in_ADDR_WIDTH
	return true
}

proc update_PARAM_VALUE.C_S_AXI_in_AWUSER_WIDTH { PARAM_VALUE.C_S_AXI_in_AWUSER_WIDTH } {
	# Procedure called to update C_S_AXI_in_AWUSER_WIDTH when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.C_S_AXI_in_AWUSER_WIDTH { PARAM_VALUE.C_S_AXI_in_AWUSER_WIDTH } {
	# Procedure called to validate C_S_AXI_in_AWUSER_WIDTH
	return true
}

proc update_PARAM_VALUE.C_S_AXI_in_ARUSER_WIDTH { PARAM_VALUE.C_S_AXI_in_ARUSER_WIDTH } {
	# Procedure called to update C_S_AXI_in_ARUSER_WIDTH when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.C_S_AXI_in_ARUSER_WIDTH { PARAM_VALUE.C_S_AXI_in_ARUSER_WIDTH } {
	# Procedure called to validate C_S_AXI_in_ARUSER_WIDTH
	return true
}

proc update_PARAM_VALUE.C_S_AXI_in_WUSER_WIDTH { PARAM_VALUE.C_S_AXI_in_WUSER_WIDTH } {
	# Procedure called to update C_S_AXI_in_WUSER_WIDTH when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.C_S_AXI_in_WUSER_WIDTH { PARAM_VALUE.C_S_AXI_in_WUSER_WIDTH } {
	# Procedure called to validate C_S_AXI_in_WUSER_WIDTH
	return true
}

proc update_PARAM_VALUE.C_S_AXI_in_RUSER_WIDTH { PARAM_VALUE.C_S_AXI_in_RUSER_WIDTH } {
	# Procedure called to update C_S_AXI_in_RUSER_WIDTH when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.C_S_AXI_in_RUSER_WIDTH { PARAM_VALUE.C_S_AXI_in_RUSER_WIDTH } {
	# Procedure called to validate C_S_AXI_in_RUSER_WIDTH
	return true
}

proc update_PARAM_VALUE.C_S_AXI_in_BUSER_WIDTH { PARAM_VALUE.C_S_AXI_in_BUSER_WIDTH } {
	# Procedure called to update C_S_AXI_in_BUSER_WIDTH when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.C_S_AXI_in_BUSER_WIDTH { PARAM_VALUE.C_S_AXI_in_BUSER_WIDTH } {
	# Procedure called to validate C_S_AXI_in_BUSER_WIDTH
	return true
}

proc update_PARAM_VALUE.C_S_AXI_in_BASEADDR { PARAM_VALUE.C_S_AXI_in_BASEADDR } {
	# Procedure called to update C_S_AXI_in_BASEADDR when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.C_S_AXI_in_BASEADDR { PARAM_VALUE.C_S_AXI_in_BASEADDR } {
	# Procedure called to validate C_S_AXI_in_BASEADDR
	return true
}

proc update_PARAM_VALUE.C_S_AXI_in_HIGHADDR { PARAM_VALUE.C_S_AXI_in_HIGHADDR } {
	# Procedure called to update C_S_AXI_in_HIGHADDR when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.C_S_AXI_in_HIGHADDR { PARAM_VALUE.C_S_AXI_in_HIGHADDR } {
	# Procedure called to validate C_S_AXI_in_HIGHADDR
	return true
}


proc update_MODELPARAM_VALUE.C_M_AXI_out_TARGET_SLAVE_BASE_ADDR { MODELPARAM_VALUE.C_M_AXI_out_TARGET_SLAVE_BASE_ADDR PARAM_VALUE.C_M_AXI_out_TARGET_SLAVE_BASE_ADDR } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.C_M_AXI_out_TARGET_SLAVE_BASE_ADDR}] ${MODELPARAM_VALUE.C_M_AXI_out_TARGET_SLAVE_BASE_ADDR}
}

proc update_MODELPARAM_VALUE.C_M_AXI_out_BURST_LEN { MODELPARAM_VALUE.C_M_AXI_out_BURST_LEN PARAM_VALUE.C_M_AXI_out_BURST_LEN } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.C_M_AXI_out_BURST_LEN}] ${MODELPARAM_VALUE.C_M_AXI_out_BURST_LEN}
}

proc update_MODELPARAM_VALUE.C_M_AXI_out_ID_WIDTH { MODELPARAM_VALUE.C_M_AXI_out_ID_WIDTH PARAM_VALUE.C_M_AXI_out_ID_WIDTH } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.C_M_AXI_out_ID_WIDTH}] ${MODELPARAM_VALUE.C_M_AXI_out_ID_WIDTH}
}

proc update_MODELPARAM_VALUE.C_M_AXI_out_ADDR_WIDTH { MODELPARAM_VALUE.C_M_AXI_out_ADDR_WIDTH PARAM_VALUE.C_M_AXI_out_ADDR_WIDTH } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.C_M_AXI_out_ADDR_WIDTH}] ${MODELPARAM_VALUE.C_M_AXI_out_ADDR_WIDTH}
}

proc update_MODELPARAM_VALUE.C_M_AXI_out_DATA_WIDTH { MODELPARAM_VALUE.C_M_AXI_out_DATA_WIDTH PARAM_VALUE.C_M_AXI_out_DATA_WIDTH } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.C_M_AXI_out_DATA_WIDTH}] ${MODELPARAM_VALUE.C_M_AXI_out_DATA_WIDTH}
}

proc update_MODELPARAM_VALUE.C_M_AXI_out_AWUSER_WIDTH { MODELPARAM_VALUE.C_M_AXI_out_AWUSER_WIDTH PARAM_VALUE.C_M_AXI_out_AWUSER_WIDTH } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.C_M_AXI_out_AWUSER_WIDTH}] ${MODELPARAM_VALUE.C_M_AXI_out_AWUSER_WIDTH}
}

proc update_MODELPARAM_VALUE.C_M_AXI_out_ARUSER_WIDTH { MODELPARAM_VALUE.C_M_AXI_out_ARUSER_WIDTH PARAM_VALUE.C_M_AXI_out_ARUSER_WIDTH } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.C_M_AXI_out_ARUSER_WIDTH}] ${MODELPARAM_VALUE.C_M_AXI_out_ARUSER_WIDTH}
}

proc update_MODELPARAM_VALUE.C_M_AXI_out_WUSER_WIDTH { MODELPARAM_VALUE.C_M_AXI_out_WUSER_WIDTH PARAM_VALUE.C_M_AXI_out_WUSER_WIDTH } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.C_M_AXI_out_WUSER_WIDTH}] ${MODELPARAM_VALUE.C_M_AXI_out_WUSER_WIDTH}
}

proc update_MODELPARAM_VALUE.C_M_AXI_out_RUSER_WIDTH { MODELPARAM_VALUE.C_M_AXI_out_RUSER_WIDTH PARAM_VALUE.C_M_AXI_out_RUSER_WIDTH } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.C_M_AXI_out_RUSER_WIDTH}] ${MODELPARAM_VALUE.C_M_AXI_out_RUSER_WIDTH}
}

proc update_MODELPARAM_VALUE.C_M_AXI_out_BUSER_WIDTH { MODELPARAM_VALUE.C_M_AXI_out_BUSER_WIDTH PARAM_VALUE.C_M_AXI_out_BUSER_WIDTH } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.C_M_AXI_out_BUSER_WIDTH}] ${MODELPARAM_VALUE.C_M_AXI_out_BUSER_WIDTH}
}

proc update_MODELPARAM_VALUE.C_S_AXI_in_ID_WIDTH { MODELPARAM_VALUE.C_S_AXI_in_ID_WIDTH PARAM_VALUE.C_S_AXI_in_ID_WIDTH } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.C_S_AXI_in_ID_WIDTH}] ${MODELPARAM_VALUE.C_S_AXI_in_ID_WIDTH}
}

proc update_MODELPARAM_VALUE.C_S_AXI_in_DATA_WIDTH { MODELPARAM_VALUE.C_S_AXI_in_DATA_WIDTH PARAM_VALUE.C_S_AXI_in_DATA_WIDTH } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.C_S_AXI_in_DATA_WIDTH}] ${MODELPARAM_VALUE.C_S_AXI_in_DATA_WIDTH}
}

proc update_MODELPARAM_VALUE.C_S_AXI_in_ADDR_WIDTH { MODELPARAM_VALUE.C_S_AXI_in_ADDR_WIDTH PARAM_VALUE.C_S_AXI_in_ADDR_WIDTH } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.C_S_AXI_in_ADDR_WIDTH}] ${MODELPARAM_VALUE.C_S_AXI_in_ADDR_WIDTH}
}

proc update_MODELPARAM_VALUE.C_S_AXI_in_AWUSER_WIDTH { MODELPARAM_VALUE.C_S_AXI_in_AWUSER_WIDTH PARAM_VALUE.C_S_AXI_in_AWUSER_WIDTH } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.C_S_AXI_in_AWUSER_WIDTH}] ${MODELPARAM_VALUE.C_S_AXI_in_AWUSER_WIDTH}
}

proc update_MODELPARAM_VALUE.C_S_AXI_in_ARUSER_WIDTH { MODELPARAM_VALUE.C_S_AXI_in_ARUSER_WIDTH PARAM_VALUE.C_S_AXI_in_ARUSER_WIDTH } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.C_S_AXI_in_ARUSER_WIDTH}] ${MODELPARAM_VALUE.C_S_AXI_in_ARUSER_WIDTH}
}

proc update_MODELPARAM_VALUE.C_S_AXI_in_WUSER_WIDTH { MODELPARAM_VALUE.C_S_AXI_in_WUSER_WIDTH PARAM_VALUE.C_S_AXI_in_WUSER_WIDTH } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.C_S_AXI_in_WUSER_WIDTH}] ${MODELPARAM_VALUE.C_S_AXI_in_WUSER_WIDTH}
}

proc update_MODELPARAM_VALUE.C_S_AXI_in_RUSER_WIDTH { MODELPARAM_VALUE.C_S_AXI_in_RUSER_WIDTH PARAM_VALUE.C_S_AXI_in_RUSER_WIDTH } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.C_S_AXI_in_RUSER_WIDTH}] ${MODELPARAM_VALUE.C_S_AXI_in_RUSER_WIDTH}
}

proc update_MODELPARAM_VALUE.C_S_AXI_in_BUSER_WIDTH { MODELPARAM_VALUE.C_S_AXI_in_BUSER_WIDTH PARAM_VALUE.C_S_AXI_in_BUSER_WIDTH } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.C_S_AXI_in_BUSER_WIDTH}] ${MODELPARAM_VALUE.C_S_AXI_in_BUSER_WIDTH}
}

