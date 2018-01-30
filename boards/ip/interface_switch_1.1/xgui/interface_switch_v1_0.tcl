# Definitional proc to organize widgets for parameters.
proc init_gui { IPINST } {
  ipgui::add_param $IPINST -name "Component_Name"
  #Adding Page
  set Page_0 [ipgui::add_page $IPINST -name "Page 0"]
  ipgui::add_param $IPINST -name "SIZE" -parent ${Page_0}

  ipgui::add_param $IPINST -name "Pattern_Generator"
  ipgui::add_param $IPINST -name "Boolean_Generator"
  ipgui::add_param $IPINST -name "FSM_Generator"

}

proc update_PARAM_VALUE.Boolean_Generator { PARAM_VALUE.Boolean_Generator } {
	# Procedure called to update Boolean_Generator when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.Boolean_Generator { PARAM_VALUE.Boolean_Generator } {
	# Procedure called to validate Boolean_Generator
	return true
}

proc update_PARAM_VALUE.FSM_Generator { PARAM_VALUE.FSM_Generator } {
	# Procedure called to update FSM_Generator when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.FSM_Generator { PARAM_VALUE.FSM_Generator } {
	# Procedure called to validate FSM_Generator
	return true
}

proc update_PARAM_VALUE.Pattern_Generator { PARAM_VALUE.Pattern_Generator } {
	# Procedure called to update Pattern_Generator when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.Pattern_Generator { PARAM_VALUE.Pattern_Generator } {
	# Procedure called to validate Pattern_Generator
	return true
}

proc update_PARAM_VALUE.SIZE { PARAM_VALUE.SIZE } {
	# Procedure called to update SIZE when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.SIZE { PARAM_VALUE.SIZE } {
	# Procedure called to validate SIZE
	return true
}


proc update_MODELPARAM_VALUE.SIZE { MODELPARAM_VALUE.SIZE PARAM_VALUE.SIZE } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.SIZE}] ${MODELPARAM_VALUE.SIZE}
}

