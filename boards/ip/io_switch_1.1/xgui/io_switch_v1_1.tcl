
# Loading additional proc with user specified bodies to compute parameter values.
source [file join [file dirname [file dirname [info script]]] gui/io_switch_v1_1.gtcl]

# Definitional proc to organize widgets for parameters.
proc init_gui { IPINST } {
  ipgui::add_static_text $IPINST -name "Configurable IO Switch" -text {This switch is designed to support pmod, dual pmod, arduino, raspberrypi, and custom interfaces. 
UART1 is typically enabled when two pmods are used and two UARTs functionality is required.}
  ipgui::add_param $IPINST -name "Component_Name"
  ipgui::add_param $IPINST -name "C_INTERFACE_TYPE" -widget comboBox
  ipgui::add_param $IPINST -name "C_IO_SWITCH_WIDTH"
  ipgui::add_param $IPINST -name "INT_Enable"
  ipgui::add_param $IPINST -name "I2C0_Enable"
  ipgui::add_param $IPINST -name "I2C1_Enable"
  ipgui::add_param $IPINST -name "UART0_Enable"
  ipgui::add_param $IPINST -name "UART1_Enable"
  ipgui::add_param $IPINST -name "SPI0_Enable"
  ipgui::add_param $IPINST -name "C_NUM_SS" -widget comboBox
  ipgui::add_param $IPINST -name "SPI1_Enable"
  ipgui::add_param $IPINST -name "PWM_Enable"
  ipgui::add_param $IPINST -name "C_NUM_PWMS" -widget comboBox
  ipgui::add_param $IPINST -name "Timer_Enable"
  ipgui::add_param $IPINST -name "C_NUM_TIMERS" -widget comboBox

}

proc update_PARAM_VALUE.C_NUM_PWMS { PARAM_VALUE.C_NUM_PWMS PARAM_VALUE.PWM_Enable PARAM_VALUE.C_INTERFACE_TYPE} {
	# Procedure called to update C_NUM_PWMS when any of the dependent parameters in the arguments change
	
	set C_NUM_PWMS ${PARAM_VALUE.C_NUM_PWMS}
	set PWM_Enable ${PARAM_VALUE.PWM_Enable}
	set values(PWM_Enable) [get_property value $PWM_Enable]
	set C_INTERFACE_TYPE [get_property value ${PARAM_VALUE.C_INTERFACE_TYPE}]
	if { $C_INTERFACE_TYPE == 1 } {
		set_property value 1 ${PARAM_VALUE.C_NUM_PWMS}
	} elseif { $C_INTERFACE_TYPE == 2 } {
		set_property value 2 ${PARAM_VALUE.C_NUM_PWMS}
	} elseif { $C_INTERFACE_TYPE == 3 } {
		set_property value 6 ${PARAM_VALUE.C_NUM_PWMS}
	} elseif { $C_INTERFACE_TYPE == 4 } {
		set_property value 2 ${PARAM_VALUE.C_NUM_PWMS}
	} else {
		set_property value [get_property value ${PARAM_VALUE.C_NUM_PWMS}] ${PARAM_VALUE.C_NUM_PWMS}
	}
	if { [gen_USERPARAMETER_C_NUM_PWMS_ENABLEMENT $values(PWM_Enable)] } {
		set_property enabled true $C_NUM_PWMS
	} else {
		set_property enabled false $C_NUM_PWMS
	}
}

proc validate_PARAM_VALUE.C_NUM_PWMS { PARAM_VALUE.C_NUM_PWMS } {
	# Procedure called to validate C_NUM_PWMS
	return true
}

proc update_PARAM_VALUE.C_NUM_SS { PARAM_VALUE.C_NUM_SS PARAM_VALUE.SPI0_Enable PARAM_VALUE.C_INTERFACE_TYPE} {
	# Procedure called to update C_NUM_SS when any of the dependent parameters in the arguments change
	
	set C_NUM_SS ${PARAM_VALUE.C_NUM_SS}
	set SPI0_Enable ${PARAM_VALUE.SPI0_Enable}
	set values(SPI0_Enable) [get_property value $SPI0_Enable]
	set C_INTERFACE_TYPE [get_property value ${PARAM_VALUE.C_INTERFACE_TYPE}]
	if { $C_INTERFACE_TYPE == 1 } {
		set_property value 1 ${PARAM_VALUE.C_NUM_SS}
	} elseif { $C_INTERFACE_TYPE == 2 } {
		set_property value 2 ${PARAM_VALUE.C_NUM_SS}
	} elseif { $C_INTERFACE_TYPE == 3 } {
		set_property value 1 ${PARAM_VALUE.C_NUM_SS}
	} elseif { $C_INTERFACE_TYPE == 4 } {
		set_property value 2 ${PARAM_VALUE.C_NUM_SS}
	} else {
		set_property value [get_property value ${PARAM_VALUE.C_NUM_SS}] ${PARAM_VALUE.C_NUM_SS}
	}
	if { [gen_USERPARAMETER_C_NUM_SS_ENABLEMENT $values(SPI0_Enable)] } {
		set_property enabled true $C_NUM_SS
	} else {
		set_property enabled false $C_NUM_SS
	}
}

proc validate_PARAM_VALUE.C_NUM_SS { PARAM_VALUE.C_NUM_SS } {
	# Procedure called to validate C_NUM_SS
	return true
}

proc update_PARAM_VALUE.C_NUM_TIMERS { PARAM_VALUE.C_NUM_TIMERS PARAM_VALUE.Timer_Enable PARAM_VALUE.C_INTERFACE_TYPE} {
	# Procedure called to update C_NUM_TIMERS when any of the dependent parameters in the arguments change
	
	set C_NUM_TIMERS ${PARAM_VALUE.C_NUM_TIMERS}
	set Timer_Enable ${PARAM_VALUE.Timer_Enable}
	set values(Timer_Enable) [get_property value $Timer_Enable]
	set C_INTERFACE_TYPE [get_property value ${PARAM_VALUE.C_INTERFACE_TYPE}]
	if { $C_INTERFACE_TYPE == 1 } {
		set_property value 1 ${PARAM_VALUE.C_NUM_TIMERS}
	} elseif { $C_INTERFACE_TYPE == 2 } {
		set_property value 2 ${PARAM_VALUE.C_NUM_TIMERS}
	} elseif { $C_INTERFACE_TYPE == 3 } {
		set_property value 8 ${PARAM_VALUE.C_NUM_TIMERS}
	} elseif { $C_INTERFACE_TYPE == 4 } {
		set_property value 3 ${PARAM_VALUE.C_NUM_TIMERS}
	} else {
		set_property value [get_property value ${PARAM_VALUE.C_NUM_TIMERS}] ${PARAM_VALUE.C_NUM_TIMERS}
	}
	if { [gen_USERPARAMETER_C_NUM_TIMERS_ENABLEMENT $values(Timer_Enable)] } {
		set_property enabled true $C_NUM_TIMERS
	} else {
		set_property enabled false $C_NUM_TIMERS
	}
}

proc validate_PARAM_VALUE.C_NUM_TIMERS { PARAM_VALUE.C_NUM_TIMERS } {
	# Procedure called to validate C_NUM_TIMERS
	return true
}

proc update_PARAM_VALUE.C_INTERFACE_TYPE { PARAM_VALUE.C_INTERFACE_TYPE } {
	# Procedure called to update C_INTERFACE_TYPE when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.C_INTERFACE_TYPE { PARAM_VALUE.C_INTERFACE_TYPE } {
	# Procedure called to validate C_INTERFACE_TYPE
	return true
}

proc update_PARAM_VALUE.C_IO_SWITCH_WIDTH { PARAM_VALUE.C_IO_SWITCH_WIDTH PARAM_VALUE.C_INTERFACE_TYPE } {
	# Procedure called to update C_IO_SWITCH_WIDTH when any of the dependent parameters in the arguments change
	set C_INTERFACE_TYPE [get_property value ${PARAM_VALUE.C_INTERFACE_TYPE}]
	if { $C_INTERFACE_TYPE == 1 } {
		set_property value 8 ${PARAM_VALUE.C_IO_SWITCH_WIDTH}
	} elseif { $C_INTERFACE_TYPE == 2 } {
		set_property value 16 ${PARAM_VALUE.C_IO_SWITCH_WIDTH}
	} elseif { $C_INTERFACE_TYPE == 3 } {
		set_property value 20 ${PARAM_VALUE.C_IO_SWITCH_WIDTH}
	} elseif { $C_INTERFACE_TYPE == 4 } {
		set_property value 28 ${PARAM_VALUE.C_IO_SWITCH_WIDTH}
	} else {
		set_property value [get_property value ${PARAM_VALUE.C_IO_SWITCH_WIDTH}] ${PARAM_VALUE.C_IO_SWITCH_WIDTH}
	}
}

proc validate_PARAM_VALUE.C_IO_SWITCH_WIDTH { PARAM_VALUE.C_IO_SWITCH_WIDTH } {
	# Procedure called to validate C_IO_SWITCH_WIDTH
	return true
}

proc update_PARAM_VALUE.I2C0_Enable { PARAM_VALUE.I2C0_Enable } {
	# Procedure called to update I2C0_Enable when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.I2C0_Enable { PARAM_VALUE.I2C0_Enable } {
	# Procedure called to validate I2C0_Enable
	return true
}

proc update_PARAM_VALUE.I2C1_Enable { PARAM_VALUE.I2C1_Enable } {
	# Procedure called to update I2C1_Enable when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.I2C1_Enable { PARAM_VALUE.I2C1_Enable } {
	# Procedure called to validate I2C1_Enable
	return true
}

proc update_PARAM_VALUE.INT_Enable { PARAM_VALUE.INT_Enable } {
	# Procedure called to update INT_Enable when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.INT_Enable { PARAM_VALUE.INT_Enable } {
	# Procedure called to validate INT_Enable
	return true
}

proc update_PARAM_VALUE.PWM_Enable { PARAM_VALUE.PWM_Enable } {
	# Procedure called to update PWM_Enable when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.PWM_Enable { PARAM_VALUE.PWM_Enable } {
	# Procedure called to validate PWM_Enable
	return true
}

proc update_PARAM_VALUE.SPI0_Enable { PARAM_VALUE.SPI0_Enable } {
	# Procedure called to update SPI0_Enable when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.SPI0_Enable { PARAM_VALUE.SPI0_Enable } {
	# Procedure called to validate SPI0_Enable
	return true
}

proc update_PARAM_VALUE.SPI1_Enable { PARAM_VALUE.SPI1_Enable } {
	# Procedure called to update SPI1_Enable when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.SPI1_Enable { PARAM_VALUE.SPI1_Enable } {
	# Procedure called to validate SPI1_Enable
	return true
}

proc update_PARAM_VALUE.Timer_Enable { PARAM_VALUE.Timer_Enable } {
	# Procedure called to update Timer_Enable when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.Timer_Enable { PARAM_VALUE.Timer_Enable } {
	# Procedure called to validate Timer_Enable
	return true
}

proc update_PARAM_VALUE.UART0_Enable { PARAM_VALUE.UART0_Enable } {
	# Procedure called to update UART0_Enable when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.UART0_Enable { PARAM_VALUE.UART0_Enable } {
	# Procedure called to validate UART0_Enable
	return true
}

proc update_PARAM_VALUE.UART1_Enable { PARAM_VALUE.UART1_Enable } {
	# Procedure called to update UART1_Enable when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.UART1_Enable { PARAM_VALUE.UART1_Enable } {
	# Procedure called to validate UART1_Enable
	return true
}

proc update_PARAM_VALUE.C_S_AXI_DATA_WIDTH { PARAM_VALUE.C_S_AXI_DATA_WIDTH } {
	# Procedure called to update C_S_AXI_DATA_WIDTH when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.C_S_AXI_DATA_WIDTH { PARAM_VALUE.C_S_AXI_DATA_WIDTH } {
	# Procedure called to validate C_S_AXI_DATA_WIDTH
	return true
}

proc update_PARAM_VALUE.C_S_AXI_ADDR_WIDTH { PARAM_VALUE.C_S_AXI_ADDR_WIDTH } {
	# Procedure called to update C_S_AXI_ADDR_WIDTH when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.C_S_AXI_ADDR_WIDTH { PARAM_VALUE.C_S_AXI_ADDR_WIDTH } {
	# Procedure called to validate C_S_AXI_ADDR_WIDTH
	return true
}

proc update_PARAM_VALUE.C_S_AXI_BASEADDR { PARAM_VALUE.C_S_AXI_BASEADDR } {
	# Procedure called to update C_S_AXI_BASEADDR when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.C_S_AXI_BASEADDR { PARAM_VALUE.C_S_AXI_BASEADDR } {
	# Procedure called to validate C_S_AXI_BASEADDR
	return true
}

proc update_PARAM_VALUE.C_S_AXI_HIGHADDR { PARAM_VALUE.C_S_AXI_HIGHADDR } {
	# Procedure called to update C_S_AXI_HIGHADDR when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.C_S_AXI_HIGHADDR { PARAM_VALUE.C_S_AXI_HIGHADDR } {
	# Procedure called to validate C_S_AXI_HIGHADDR
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

proc update_MODELPARAM_VALUE.C_INTERFACE_TYPE { MODELPARAM_VALUE.C_INTERFACE_TYPE PARAM_VALUE.C_INTERFACE_TYPE } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.C_INTERFACE_TYPE}] ${MODELPARAM_VALUE.C_INTERFACE_TYPE}
}

proc update_MODELPARAM_VALUE.C_IO_SWITCH_WIDTH { MODELPARAM_VALUE.C_IO_SWITCH_WIDTH PARAM_VALUE.C_IO_SWITCH_WIDTH } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.C_IO_SWITCH_WIDTH}] ${MODELPARAM_VALUE.C_IO_SWITCH_WIDTH}
}

proc update_MODELPARAM_VALUE.C_NUM_PWMS { MODELPARAM_VALUE.C_NUM_PWMS PARAM_VALUE.C_NUM_PWMS } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.C_NUM_PWMS}] ${MODELPARAM_VALUE.C_NUM_PWMS}
}

proc update_MODELPARAM_VALUE.C_NUM_TIMERS { MODELPARAM_VALUE.C_NUM_TIMERS PARAM_VALUE.C_NUM_TIMERS } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.C_NUM_TIMERS}] ${MODELPARAM_VALUE.C_NUM_TIMERS}
}

proc update_MODELPARAM_VALUE.C_NUM_SS { MODELPARAM_VALUE.C_NUM_SS PARAM_VALUE.C_NUM_SS } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.C_NUM_SS}] ${MODELPARAM_VALUE.C_NUM_SS}
}

