# Definitional proc to organize widgets for parameters.
proc init_gui { IPINST } {
  ipgui::add_param $IPINST -name "Component_Name"
  #Adding Page
  set Page_0 [ipgui::add_page $IPINST -name "Page 0"]
  set ADD_BUFMR [ipgui::add_param $IPINST -name "ADD_BUFMR" -parent ${Page_0}]
  set_property tooltip {Add a BUFMR between the MMCM output and BUFIO/BUFR inputs to allow the MMCM to be placed in a different bank than the high-speed data bus. Useful if two high-speed data buses that require MMCMs are on the same bank.} ${ADD_BUFMR}


}

proc update_PARAM_VALUE.ADD_BUFMR { PARAM_VALUE.ADD_BUFMR } {
	# Procedure called to update ADD_BUFMR when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.ADD_BUFMR { PARAM_VALUE.ADD_BUFMR } {
	# Procedure called to validate ADD_BUFMR
	return true
}


proc update_MODELPARAM_VALUE.C_S00_AXI_DATA_WIDTH { MODELPARAM_VALUE.C_S00_AXI_DATA_WIDTH } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	# WARNING: There is no corresponding user parameter named "C_S00_AXI_DATA_WIDTH". Setting updated value from the model parameter.
set_property value 32 ${MODELPARAM_VALUE.C_S00_AXI_DATA_WIDTH}
}

proc update_MODELPARAM_VALUE.C_S00_AXI_ADDR_WIDTH { MODELPARAM_VALUE.C_S00_AXI_ADDR_WIDTH } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	# WARNING: There is no corresponding user parameter named "C_S00_AXI_ADDR_WIDTH". Setting updated value from the model parameter.
set_property value 5 ${MODELPARAM_VALUE.C_S00_AXI_ADDR_WIDTH}
}

proc update_MODELPARAM_VALUE.ADD_BUFMR { MODELPARAM_VALUE.ADD_BUFMR PARAM_VALUE.ADD_BUFMR } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.ADD_BUFMR}] ${MODELPARAM_VALUE.ADD_BUFMR}
}

