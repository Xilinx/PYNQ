
proc create_ipi_design { offsetfile design_name } {

	create_bd_design $design_name
	open_bd_design $design_name

	# Create and configure Clock/Reset
	create_bd_cell -type ip -vlnv xilinx.com:ip:clk_wiz sys_clk_0
	create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset sys_reset_0

	#Constraints will be provided manually while pin planning.
		create_bd_port -dir I -type rst reset_rtl
		set_property CONFIG.POLARITY [get_property CONFIG.POLARITY [get_bd_pins sys_clk_0/reset]] [get_bd_ports reset_rtl]
		connect_bd_net [get_bd_pins sys_reset_0/ext_reset_in] [get_bd_ports reset_rtl]
		connect_bd_net [get_bd_ports reset_rtl] [get_bd_pins sys_clk_0/reset]
		set external_reset_port reset_rtl
		create_bd_port -dir I -type clk clock_rtl
		connect_bd_net [get_bd_pins sys_clk_0/clk_in1] [get_bd_ports clock_rtl]
		set external_clock_port clock_rtl
	
	#Avoid IPI DRC, make clock port synchronous to reset
	if { $external_clock_port ne "" && $external_reset_port ne "" } {
		set_property CONFIG.ASSOCIATED_RESET $external_reset_port [get_bd_ports $external_clock_port]
	}

	# Connect other sys_reset pins
	connect_bd_net [get_bd_pins sys_reset_0/slowest_sync_clk] [get_bd_pins sys_clk_0/clk_out1]
	connect_bd_net [get_bd_pins sys_clk_0/locked] [get_bd_pins sys_reset_0/dcm_locked]

	# Create instance: audio_direct_0, and set properties
	set audio_direct_0 [ create_bd_cell -type ip -vlnv xilinx.com:user:audio_direct:1.1 audio_direct_0 ]

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

	# Connect all clock & reset of audio_direct_0 slave interfaces..
	connect_bd_intf_net [get_bd_intf_pins axi_peri_interconnect/M00_AXI] [get_bd_intf_pins audio_direct_0/S_AXI]
	connect_bd_net [get_bd_pins audio_direct_0/s_axi_aclk] [get_bd_pins sys_clk_0/clk_out1]
	connect_bd_net [get_bd_pins audio_direct_0/s_axi_aresetn] [get_bd_pins sys_reset_0/peripheral_aresetn]


	# Auto assign address
	assign_bd_address

	# Copy all address to audio_direct_v1_1_include.tcl file
	set bd_path [get_property DIRECTORY [current_project]]/[current_project].srcs/[current_fileset]/bd
	upvar 1 $offsetfile offset_file
	set offset_file "${bd_path}/audio_direct_v1_1_include.tcl"
	set fp [open $offset_file "w"]
	puts $fp "# Configuration address parameters"

	set offset [get_property OFFSET [get_bd_addr_segs /jtag_axi_0/Data/SEG_audio_direct_0_S_AXI_* ]]
	puts $fp "set s_axi_addr ${offset}"

	close $fp
}

# Set IP Repository and Update IP Catalogue 
set ip_path [file dirname [file normalize [get_property XML_FILE_NAME [ipx::get_cores xilinx.com:user:audio_direct:1.1]]]]
set hw_test_file ${ip_path}/example_designs/debug_hw_design/audio_direct_v1_1_hw_test.tcl

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
	set design_name "audio_direct_v1_1_hw_${i}"
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

