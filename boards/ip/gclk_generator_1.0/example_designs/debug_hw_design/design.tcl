
proc create_ipi_design { offsetfile design_name } {

	create_bd_design $design_name
	open_bd_design $design_name

	# Create and configure Clock/Reset
	create_bd_cell -type ip -vlnv xilinx.com:ip:clk_wiz sys_clk_0
	create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset sys_reset_0

	#check if current_board is set, if true - figure out required clocks.
	set is_board_clock_found 0
	set is_board_reset_found 0
	set external_reset_port ""
	set external_clock_port ""

	if { [current_board_part -quiet] != "" } {

		#check if any reset interface exists in board.
		set board_reset [lindex [get_board_part_interfaces -filter { BUSDEF_NAME == reset_rtl && MODE == slave }] 0 ]
		if { $board_reset ne "" } {
			set is_board_reset_found 1
			apply_board_connection -board_interface $board_reset -ip_intf sys_clk_0/reset -diagram [current_bd_design]
			apply_board_connection -board_interface $board_reset -ip_intf sys_reset_0/ext_reset -diagram [current_bd_design]
			set external_rst [get_bd_ports -quiet -of_objects [get_bd_nets -quiet -of_objects [get_bd_pins -quiet sys_clk_0/reset]]]
			if { $external_rst ne "" } {
				set external_reset_port [get_property NAME $external_rst]
			}
		} else {
			send_msg "ptgen 51-200" WARNING "No reset interface found in current_board, Users may need to specify the location constraints manually."
		}

		# check for differential clock, exclude any special clocks which has TYPE property.
		set board_clock_busifs ""
		foreach busif [get_board_part_interfaces -filter "BUSDEF_NAME == diff_clock_rtl"] {
			set type [get_property PARAM.TYPE $busif]
			if { $type == "" } {
				set board_clock_busifs $busif
				break
			}
		}
		if { $board_clock_busifs ne "" } {
			apply_board_connection -board_interface $board_clock_busifs -ip_intf sys_clk_0/CLK_IN1_D -diagram [current_bd_design]
			set is_board_clock_found 1
		} else {
			# check for single ended clock
			set board_sclock_busifs [lindex [get_board_part_interfaces -filter "BUSDEF_NAME == clock_rtl"] 0 ]
			if { $board_sclock_busifs ne "" } {
			    apply_board_connection -board_interface $board_sclock_busifs -ip_intf sys_clk_0/clock_CLK_IN1 -diagram [current_bd_design]
				set external_clk [get_bd_ports -quiet -of_objects [get_bd_nets -quiet -of_objects [get_bd_pins -quiet sys_clk_0/clk_in1]]]
				if { $external_clk ne "" } {
					set external_clock_port [get_property NAME $external_clk]
				}
				set is_board_clock_found 1
			} else {
				send_msg "ptgen 51-200" WARNING "No clock interface found in current_board, Users may need to specify the location constraints manually."
			}
		}

	} else {
		send_msg "ptgen 51-201" WARNING "No board selected in current_project. Users may need to specify the location constraints manually."
	}

	#if there is no corresponding board interface found, assume constraints will be provided manually while pin planning.
	if { $is_board_reset_found == 0 } {
		create_bd_port -dir I -type rst reset_rtl
		set_property CONFIG.POLARITY [get_property CONFIG.POLARITY [get_bd_pins sys_clk_0/reset]] [get_bd_ports reset_rtl]
		connect_bd_net [get_bd_pins sys_reset_0/ext_reset_in] [get_bd_ports reset_rtl]
		connect_bd_net [get_bd_ports reset_rtl] [get_bd_pins sys_clk_0/reset]
		set external_reset_port reset_rtl
	}
	if { $is_board_clock_found == 0 } {
		create_bd_port -dir I -type clk clock_rtl
		connect_bd_net [get_bd_pins sys_clk_0/clk_in1] [get_bd_ports clock_rtl]
		set external_clock_port clock_rtl
	}

	#Avoid IPI DRC, make clock port synchronous to reset
	if { $external_clock_port ne "" && $external_reset_port ne "" } {
		set_property CONFIG.ASSOCIATED_RESET $external_reset_port [get_bd_ports $external_clock_port]
	}

	# Connect other sys_reset pins
	connect_bd_net [get_bd_pins sys_reset_0/slowest_sync_clk] [get_bd_pins sys_clk_0/clk_out1]
	connect_bd_net [get_bd_pins sys_clk_0/locked] [get_bd_pins sys_reset_0/dcm_locked]

	# Create instance: gclk_generator_0, and set properties
	set gclk_generator_0 [ create_bd_cell -type ip -vlnv xilinx.com:user:gclk_generator:1.0 gclk_generator_0 ]

	# Create instance: jtag_axi_0, and set properties
	set jtag_axi_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:jtag_axi jtag_axi_0 ]
	set_property -dict [list CONFIG.PROTOCOL {0}] [get_bd_cells jtag_axi_0]
	connect_bd_net [get_bd_pins jtag_axi_0/aclk] [get_bd_pins sys_clk_0/clk_out1]
	connect_bd_net [get_bd_pins jtag_axi_0/aresetn] [get_bd_pins sys_reset_0/peripheral_aresetn]

	# Create instance: axi_peri_interconnect, and set properties
	set axi_peri_interconnect [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_interconnect axi_peri_interconnect ]
	connect_bd_net [get_bd_pins axi_peri_interconnect/ACLK] [get_bd_pins sys_clk_0/clk_out1]
	connect_bd_net [get_bd_pins axi_peri_interconnect/ARESETN] [get_bd_pins sys_reset_0/interconnect_aresetn]
	set_property -dict [ list CONFIG.NUM_SI {1}  ] $axi_peri_interconnect
	connect_bd_net [get_bd_pins axi_peri_interconnect/S00_ACLK] [get_bd_pins sys_clk_0/clk_out1]
	connect_bd_net [get_bd_pins axi_peri_interconnect/S00_ARESETN] [get_bd_pins sys_reset_0/peripheral_aresetn]
	connect_bd_intf_net [get_bd_intf_pins jtag_axi_0/M_AXI] [get_bd_intf_pins axi_peri_interconnect/S00_AXI]

	set_property -dict [ list CONFIG.NUM_MI {1} ] $axi_peri_interconnect
	connect_bd_net [get_bd_pins axi_peri_interconnect/M00_ACLK] [get_bd_pins sys_clk_0/clk_out1]
	connect_bd_net [get_bd_pins axi_peri_interconnect/M00_ARESETN] [get_bd_pins sys_reset_0/peripheral_aresetn]

	# Connect all clock & reset of gclk_generator_0 slave interfaces..
	connect_bd_intf_net [get_bd_intf_pins axi_peri_interconnect/M00_AXI] [get_bd_intf_pins gclk_generator_0/S_AXI]
	connect_bd_net [get_bd_pins gclk_generator_0/s_axi_aclk] [get_bd_pins sys_clk_0/clk_out1]
	connect_bd_net [get_bd_pins gclk_generator_0/s_axi_aresetn] [get_bd_pins sys_reset_0/peripheral_aresetn]


	# Auto assign address
	assign_bd_address

	# Copy all address to gclk_generator_v1_0_include.tcl file
	set bd_path [get_property DIRECTORY [current_project]]/[current_project].srcs/[current_fileset]/bd
	upvar 1 $offsetfile offset_file
	set offset_file "${bd_path}/gclk_generator_v1_0_include.tcl"
	set fp [open $offset_file "w"]
	puts $fp "# Configuration address parameters"

	set offset [get_property OFFSET [get_bd_addr_segs /jtag_axi_0/Data/SEG_gclk_generator_0_S_AXI_* ]]
	puts $fp "set s_axi_addr ${offset}"

	close $fp
}

# Set IP Repository and Update IP Catalogue 
set ip_path [file dirname [file normalize [get_property XML_FILE_NAME [ipx::get_cores xilinx.com:user:gclk_generator:1.0]]]]
set hw_test_file ${ip_path}/example_designs/debug_hw_design/gclk_generator_v1_0_hw_test.tcl

set repo_paths [get_property ip_repo_paths [current_fileset]] 
if { [lsearch -exact -nocase $repo_paths $ip_path ] == -1 } {
	set_property ip_repo_paths "$ip_path [get_property ip_repo_paths [current_fileset]]" [current_fileset]
	update_ip_catalog
}

set design_name ""
set all_bd {}
set all_bd_files [get_files *.bd -quiet]
foreach file $all_bd_files {
set file_name [string range $file [expr {[string last "/" $file] + 1}] end]
set bd_name [string range $file_name 0 [expr {[string last "." $file_name] -1}]]
lappend all_bd $bd_name
}

for { set i 1 } { 1 } { incr i } {
	set design_name "gclk_generator_v1_0_hw_${i}"
	if { [lsearch -exact -nocase $all_bd $design_name ] == -1 } {
		break
	}
}

set intf_address_include_file ""
create_ipi_design intf_address_include_file ${design_name}
save_bd_design
validate_bd_design

set wrapper_file [make_wrapper -files [get_files ${design_name}.bd] -top -force]
import_files -force -norecurse $wrapper_file

puts "-------------------------------------------------------------------------------------------------"
puts "INFO NEXT STEPS : Until this stage, debug hardware design has been created, "
puts "   please perform following steps to test design in targeted board."
puts "1. Generate bitstream"
puts "2. Setup your targeted board, open hardware manager and open new(or existing) hardware target"
puts "3. Download generated bitstream"
puts "4. Run generated hardware test using below command, this invokes basic read/write operation"
puts "   to every interface present in the peripheral : xilinx.com:user:myip:1.0"
puts "   : source -notrace ${hw_test_file}"
puts "-------------------------------------------------------------------------------------------------"

