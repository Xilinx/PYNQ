#Definitional proc to organize widgets for parameters.
proc init_gui { IPINST } {
	set Page0 [ ipgui::add_page $IPINST  -name "Page 0" -layout vertical]
	set Component_Name [ ipgui::add_param  $IPINST  -parent  $Page0  -name Component_Name ]
}


proc update_MODELPARAM_VALUE.hor_s { MODELPARAM_VALUE.hor_s } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	# WARNING: There is no corresponding user parameter named "hor_s". Setting updated value from the model parameter.
set_property value 96 ${MODELPARAM_VALUE.hor_s}
}

proc update_MODELPARAM_VALUE.hor_bp { MODELPARAM_VALUE.hor_bp } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	# WARNING: There is no corresponding user parameter named "hor_bp". Setting updated value from the model parameter.
set_property value 48 ${MODELPARAM_VALUE.hor_bp}
}

proc update_MODELPARAM_VALUE.hor_d { MODELPARAM_VALUE.hor_d } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	# WARNING: There is no corresponding user parameter named "hor_d". Setting updated value from the model parameter.
set_property value 640 ${MODELPARAM_VALUE.hor_d}
}

proc update_MODELPARAM_VALUE.hor_fp { MODELPARAM_VALUE.hor_fp } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	# WARNING: There is no corresponding user parameter named "hor_fp". Setting updated value from the model parameter.
set_property value 16 ${MODELPARAM_VALUE.hor_fp}
}

proc update_MODELPARAM_VALUE.hor_pol { MODELPARAM_VALUE.hor_pol } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	# WARNING: There is no corresponding user parameter named "hor_pol". Setting updated value from the model parameter.
set_property value "0" ${MODELPARAM_VALUE.hor_pol}
}

proc update_MODELPARAM_VALUE.vert_s { MODELPARAM_VALUE.vert_s } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	# WARNING: There is no corresponding user parameter named "vert_s". Setting updated value from the model parameter.
set_property value 2 ${MODELPARAM_VALUE.vert_s}
}

proc update_MODELPARAM_VALUE.vert_bp { MODELPARAM_VALUE.vert_bp } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	# WARNING: There is no corresponding user parameter named "vert_bp". Setting updated value from the model parameter.
set_property value 33 ${MODELPARAM_VALUE.vert_bp}
}

proc update_MODELPARAM_VALUE.vert_d { MODELPARAM_VALUE.vert_d } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	# WARNING: There is no corresponding user parameter named "vert_d". Setting updated value from the model parameter.
set_property value 480 ${MODELPARAM_VALUE.vert_d}
}

proc update_MODELPARAM_VALUE.vert_fp { MODELPARAM_VALUE.vert_fp } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	# WARNING: There is no corresponding user parameter named "vert_fp". Setting updated value from the model parameter.
set_property value 10 ${MODELPARAM_VALUE.vert_fp}
}

proc update_MODELPARAM_VALUE.vert_pol { MODELPARAM_VALUE.vert_pol } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	# WARNING: There is no corresponding user parameter named "vert_pol". Setting updated value from the model parameter.
set_property value "0" ${MODELPARAM_VALUE.vert_pol}
}

