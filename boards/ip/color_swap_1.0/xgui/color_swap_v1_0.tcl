# Definitional proc to organize widgets for parameters.
proc init_gui { IPINST } {
  ipgui::add_param $IPINST -name "Component_Name"
  #Adding Page
  set Page_0 [ipgui::add_page $IPINST -name "Page 0"]
  ipgui::add_param $IPINST -name "input_format" -parent ${Page_0} -widget comboBox
  ipgui::add_param $IPINST -name "output_format" -parent ${Page_0} -widget comboBox


}

proc update_PARAM_VALUE.input_format { PARAM_VALUE.input_format } {
	# Procedure called to update input_format when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.input_format { PARAM_VALUE.input_format } {
	# Procedure called to validate input_format
	return true
}

proc update_PARAM_VALUE.output_format { PARAM_VALUE.output_format } {
	# Procedure called to update output_format when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.output_format { PARAM_VALUE.output_format } {
	# Procedure called to validate output_format
	return true
}


proc update_MODELPARAM_VALUE.input_format { MODELPARAM_VALUE.input_format PARAM_VALUE.input_format } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.input_format}] ${MODELPARAM_VALUE.input_format}
}

proc update_MODELPARAM_VALUE.output_format { MODELPARAM_VALUE.output_format PARAM_VALUE.output_format } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.output_format}] ${MODELPARAM_VALUE.output_format}
}

