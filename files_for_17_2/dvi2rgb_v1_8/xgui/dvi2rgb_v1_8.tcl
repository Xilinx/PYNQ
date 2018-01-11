
# Loading additional proc with user specified bodies to compute parameter values.
source [file join [file dirname [file dirname [info script]]] gui/dvi2rgb_v1_0.gtcl]

# Definitional proc to organize widgets for parameters.
proc init_gui { IPINST } {
  ipgui::add_param $IPINST -name "Component_Name"
  ipgui::add_param $IPINST -name "kEmulateDDC"
  ipgui::add_param $IPINST -name "kEnableSerialClkOutput"
  ipgui::add_param $IPINST -name "kAddBUFG"
  ipgui::add_param $IPINST -name "kRstActiveHigh"
  ipgui::add_param $IPINST -name "kClkRange"
  ipgui::add_param $IPINST -name "kEdidFileName"

}

proc update_PARAM_VALUE.kEdidFileName { PARAM_VALUE.kEdidFileName PARAM_VALUE.kEmulateDDC } {
	# Procedure called to update kEdidFileName when any of the dependent parameters in the arguments change
	
	set kEdidFileName ${PARAM_VALUE.kEdidFileName}
	set kEmulateDDC ${PARAM_VALUE.kEmulateDDC}
	set values(kEmulateDDC) [get_property value $kEmulateDDC]
	if { [gen_USERPARAMETER_kEdidFileName_ENABLEMENT $values(kEmulateDDC)] } {
		set_property enabled true $kEdidFileName
	} else {
		set_property enabled false $kEdidFileName
	}
}

proc validate_PARAM_VALUE.kEdidFileName { PARAM_VALUE.kEdidFileName } {
	# Procedure called to validate kEdidFileName
	return true
}

proc update_PARAM_VALUE.IIC_BOARD_INTERFACE { PARAM_VALUE.IIC_BOARD_INTERFACE } {
	# Procedure called to update IIC_BOARD_INTERFACE when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.IIC_BOARD_INTERFACE { PARAM_VALUE.IIC_BOARD_INTERFACE } {
	# Procedure called to validate IIC_BOARD_INTERFACE
	return true
}

proc update_PARAM_VALUE.TMDS_BOARD_INTERFACE { PARAM_VALUE.TMDS_BOARD_INTERFACE } {
	# Procedure called to update TMDS_BOARD_INTERFACE when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.TMDS_BOARD_INTERFACE { PARAM_VALUE.TMDS_BOARD_INTERFACE } {
	# Procedure called to validate TMDS_BOARD_INTERFACE
	return true
}

proc update_PARAM_VALUE.kAddBUFG { PARAM_VALUE.kAddBUFG } {
	# Procedure called to update kAddBUFG when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.kAddBUFG { PARAM_VALUE.kAddBUFG } {
	# Procedure called to validate kAddBUFG
	return true
}

proc update_PARAM_VALUE.kClkRange { PARAM_VALUE.kClkRange } {
	# Procedure called to update kClkRange when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.kClkRange { PARAM_VALUE.kClkRange } {
	# Procedure called to validate kClkRange
	return true
}

proc update_PARAM_VALUE.kEnableSerialClkOutput { PARAM_VALUE.kEnableSerialClkOutput } {
	# Procedure called to update kEnableSerialClkOutput when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.kEnableSerialClkOutput { PARAM_VALUE.kEnableSerialClkOutput } {
	# Procedure called to validate kEnableSerialClkOutput
	return true
}

proc update_PARAM_VALUE.kRstActiveHigh { PARAM_VALUE.kRstActiveHigh } {
	# Procedure called to update kRstActiveHigh when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.kRstActiveHigh { PARAM_VALUE.kRstActiveHigh } {
	# Procedure called to validate kRstActiveHigh
	return true
}

proc update_PARAM_VALUE.kEmulateDDC { PARAM_VALUE.kEmulateDDC } {
	# Procedure called to update kEmulateDDC when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.kEmulateDDC { PARAM_VALUE.kEmulateDDC } {
	# Procedure called to validate kEmulateDDC
	return true
}


proc update_MODELPARAM_VALUE.kEmulateDDC { MODELPARAM_VALUE.kEmulateDDC PARAM_VALUE.kEmulateDDC } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.kEmulateDDC}] ${MODELPARAM_VALUE.kEmulateDDC}
}

proc update_MODELPARAM_VALUE.kRstActiveHigh { MODELPARAM_VALUE.kRstActiveHigh PARAM_VALUE.kRstActiveHigh } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.kRstActiveHigh}] ${MODELPARAM_VALUE.kRstActiveHigh}
}

proc update_MODELPARAM_VALUE.kClkRange { MODELPARAM_VALUE.kClkRange PARAM_VALUE.kClkRange } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.kClkRange}] ${MODELPARAM_VALUE.kClkRange}
}

proc update_MODELPARAM_VALUE.kIDLY_TapValuePs { MODELPARAM_VALUE.kIDLY_TapValuePs } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	# WARNING: There is no corresponding user parameter named "kIDLY_TapValuePs". Setting updated value from the model parameter.
set_property value 78 ${MODELPARAM_VALUE.kIDLY_TapValuePs}
}

proc update_MODELPARAM_VALUE.kIDLY_TapWidth { MODELPARAM_VALUE.kIDLY_TapWidth } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	# WARNING: There is no corresponding user parameter named "kIDLY_TapWidth". Setting updated value from the model parameter.
set_property value 5 ${MODELPARAM_VALUE.kIDLY_TapWidth}
}

proc update_MODELPARAM_VALUE.kAddBUFG { MODELPARAM_VALUE.kAddBUFG PARAM_VALUE.kAddBUFG } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.kAddBUFG}] ${MODELPARAM_VALUE.kAddBUFG}
}

proc update_MODELPARAM_VALUE.kEdidFileName { MODELPARAM_VALUE.kEdidFileName PARAM_VALUE.kEdidFileName } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.kEdidFileName}] ${MODELPARAM_VALUE.kEdidFileName}
}

