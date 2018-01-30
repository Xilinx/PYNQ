# Definitional proc to organize widgets for parameters.
proc init_gui { IPINST } {
  ipgui::add_param $IPINST -name "Component_Name"
  ipgui::add_param $IPINST -name "C_CLK_PERIOD_NS"
  ipgui::add_param $IPINST -name "C_DEBOUNCE_TIME_MSEC"

}

proc update_PARAM_VALUE.C_CLK_PERIOD_NS { PARAM_VALUE.C_CLK_PERIOD_NS } {
	# Procedure called to update C_CLK_PERIOD_NS when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.C_CLK_PERIOD_NS { PARAM_VALUE.C_CLK_PERIOD_NS } {
	# Procedure called to validate C_CLK_PERIOD_NS
	return true
}

proc update_PARAM_VALUE.C_DEBOUNCE_TIME_MSEC { PARAM_VALUE.C_DEBOUNCE_TIME_MSEC } {
	# Procedure called to update C_DEBOUNCE_TIME_MSEC when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.C_DEBOUNCE_TIME_MSEC { PARAM_VALUE.C_DEBOUNCE_TIME_MSEC } {
	# Procedure called to validate C_DEBOUNCE_TIME_MSEC
	return true
}


proc update_MODELPARAM_VALUE.C_CLK_PERIOD_NS { MODELPARAM_VALUE.C_CLK_PERIOD_NS PARAM_VALUE.C_CLK_PERIOD_NS } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.C_CLK_PERIOD_NS}] ${MODELPARAM_VALUE.C_CLK_PERIOD_NS}
}

proc update_MODELPARAM_VALUE.C_DEBOUNCE_TIME_MSEC { MODELPARAM_VALUE.C_DEBOUNCE_TIME_MSEC PARAM_VALUE.C_DEBOUNCE_TIME_MSEC } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.C_DEBOUNCE_TIME_MSEC}] ${MODELPARAM_VALUE.C_DEBOUNCE_TIME_MSEC}
}

