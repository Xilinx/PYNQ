# Definitional proc to organize widgets for parameters.
proc init_gui { IPINST } {
  ipgui::add_param $IPINST -name "Component_Name"
  #Adding Page
  set Page_0 [ipgui::add_page $IPINST -name "Page 0"]
  ipgui::add_param $IPINST -name "C_NUM_CHANNELS" -parent ${Page_0} -widget comboBox
  ipgui::add_param $IPINST -name "C_SIZE" -parent ${Page_0}
  ipgui::add_param $IPINST -name "DELAY" -parent ${Page_0}


}

proc update_PARAM_VALUE.C_NUM_CHANNELS { PARAM_VALUE.C_NUM_CHANNELS } {
	# Procedure called to update C_NUM_CHANNELS when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.C_NUM_CHANNELS { PARAM_VALUE.C_NUM_CHANNELS } {
	# Procedure called to validate C_NUM_CHANNELS
	return true
}

proc update_PARAM_VALUE.C_SIZE { PARAM_VALUE.C_SIZE } {
	# Procedure called to update C_SIZE when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.C_SIZE { PARAM_VALUE.C_SIZE } {
	# Procedure called to validate C_SIZE
	return true
}

proc update_PARAM_VALUE.DELAY { PARAM_VALUE.DELAY } {
	# Procedure called to update DELAY when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.DELAY { PARAM_VALUE.DELAY } {
	# Procedure called to validate DELAY
	return true
}


proc update_MODELPARAM_VALUE.C_SIZE { MODELPARAM_VALUE.C_SIZE PARAM_VALUE.C_SIZE } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.C_SIZE}] ${MODELPARAM_VALUE.C_SIZE}
}

proc update_MODELPARAM_VALUE.DELAY { MODELPARAM_VALUE.DELAY PARAM_VALUE.DELAY } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.DELAY}] ${MODELPARAM_VALUE.DELAY}
}

proc update_MODELPARAM_VALUE.C_NUM_CHANNELS { MODELPARAM_VALUE.C_NUM_CHANNELS PARAM_VALUE.C_NUM_CHANNELS } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.C_NUM_CHANNELS}] ${MODELPARAM_VALUE.C_NUM_CHANNELS}
}

