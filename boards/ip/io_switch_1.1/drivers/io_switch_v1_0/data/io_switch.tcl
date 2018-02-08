
proc driving_cell {input_pin} {
	set net [hsi::get_nets -of $input_pin]
	set output_pin [hsi::get_pins -of $net -filter {DIRECTION == O}]
	return [hsi::get_cells -of $output_pin]
}

proc write_address_param {file_handle periph canon name cell} {
	set addr [common::get_property "CONFIG.C_BASEADDR" $cell]
	puts $file_handle "#define [::hsi::utils::get_ip_param_name $periph $name] $addr"
	puts $file_handle "#define ${canon}_$name $addr"
}

proc write_address_conditional {file_handle periph canon pin config name} {
	if {[common::get_property "CONFIG.$config" $periph]} {
		set cell [driving_cell [hsi::get_pins -of $periph $pin]]
		write_address_param $file_handle $periph $canon $name $cell
	}
}

proc generate {drv_handle} {
	xdefine_include_file $drv_handle "xparameters.h" "io_switch" "NUM_INSTANCES" "DEVICE_ID"  "C_S_AXI_BASEADDR" "C_S_AXI_HIGHADDR" "C_INTERFACE_TYPE" "C_IO_SWITCH_WIDTH" "C_NUM_PWMS" "C_NUM_TIMERS" "C_NUM_SS"
  ::hsi::utils::define_canonical_xpars $drv_handle "xparameters.h" "io_switch" "DEVICE_ID"  "C_S_AXI_BASEADDR" "C_S_AXI_HIGHADDR" "C_INTERFACE_TYPE" "C_IO_SWITCH_WIDTH" "C_NUM_PWMS" "C_NUM_TIMERS" "C_NUM_SS"

	set file_handle [::hsi::utils::open_include_file "xparameters.h"]
	puts $file_handle "/******* PARAMETERS RELATED TO IPs CONNECTED TO IO_SWITCH *******/"
	set periphs [::hsi::utils::get_common_driver_ips $drv_handle]
	set device_id 0
	foreach periph $periphs {
		set canon "XPAR_IO_SWITCH_${device_id}"
		set gpio [driving_cell [hsi::get_pins -of $periph gpio_data_o]]
		write_address_param $file_handle $periph $canon "GPIO_BASEADDR" $gpio
		write_address_conditional $file_handle $periph $canon "uart0_tx_o" "UART0_Enable" "UART0_BASEADDR"
		write_address_conditional $file_handle $periph $canon "uart1_tx_o" "UART1_Enable" "UART1_BASEADDR"
		write_address_conditional $file_handle $periph $canon "sda0_o" "I2C0_Enable" "I2C0_BASEADDR"
		write_address_conditional $file_handle $periph $canon "sda1_o" "I2C1_Enable" "I2C1_BASEADDR"
		write_address_conditional $file_handle $periph $canon "sck0_o" "SPI0_Enable" "SPI0_BASEADDR"
		write_address_conditional $file_handle $periph $canon "sck1_o" "SPI1_Enable" "SPI1_BASEADDR"
		if {[common::get_property "CONFIG.PWM_Enable" $periph]} {
			set num_pwms [common::get_property "CONFIG.C_NUM_PWMS" $periph]
			if {$num_pwms == 1} {
				set pwm [driving_cell [hsi::get_pins -of $periph pwm_o]]
				write_address_param $file_handle $periph $canon "PWM0_BASEADDR" $pwm
			} else {
				set concat_block [driving_cell [hsi::get_pins -of $periph pwm_o]]
				for {set i 0} { $i < $num_pwms } { incr i } {
					set pwm [driving_cell [hsi::get_pins -of $concat_block "In$i"]]
					write_address_param $file_handle $periph $canon "PWM${i}_BASEADDR" $pwm
				}
			}
		}
		if {[common::get_property "CONFIG.Timer_Enable" $periph]} {
			set num_timers [common::get_property "CONFIG.C_NUM_TIMERS" $periph]
			if {$num_timers == 1} {
				set timers [driving_cell [hsi::get_pins -of $periph timer_o]]
				write_address_param $file_handle $periph $canon "TIMER0_BASEADDR" $timers
			} else {
				set concat_block [driving_cell [hsi::get_pins -of $periph timer_o]]
				for {set i 0} { $i < $num_timers } { incr i } {
					set timers [driving_cell [hsi::get_pins -of $concat_block "In$i"]]
					write_address_param $file_handle $periph $canon "TIMER${i}_BASEADDR" $timers
				}
			}
		}
		incr device_id
	}

        close $file_handle
}
