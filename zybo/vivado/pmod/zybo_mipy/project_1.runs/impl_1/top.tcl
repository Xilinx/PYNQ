proc start_step { step } {
  set stopFile ".stop.rst"
  if {[file isfile .stop.rst]} {
    puts ""
    puts "*** Halting run - EA reset detected ***"
    puts ""
    puts ""
    return -code error
  }
  set beginFile ".$step.begin.rst"
  set platform "$::tcl_platform(platform)"
  set user "$::tcl_platform(user)"
  set pid [pid]
  set host ""
  if { [string equal $platform unix] } {
    if { [info exist ::env(HOSTNAME)] } {
      set host $::env(HOSTNAME)
    }
  } else {
    if { [info exist ::env(COMPUTERNAME)] } {
      set host $::env(COMPUTERNAME)
    }
  }
  set ch [open $beginFile w]
  puts $ch "<?xml version=\"1.0\"?>"
  puts $ch "<ProcessHandle Version=\"1\" Minor=\"0\">"
  puts $ch "    <Process Command=\".planAhead.\" Owner=\"$user\" Host=\"$host\" Pid=\"$pid\">"
  puts $ch "    </Process>"
  puts $ch "</ProcessHandle>"
  close $ch
}

proc end_step { step } {
  set endFile ".$step.end.rst"
  set ch [open $endFile w]
  close $ch
}

proc step_failed { step } {
  set endFile ".$step.error.rst"
  set ch [open $endFile w]
  close $ch
}

set_msg_config -id {HDL 9-1061} -limit 100000
set_msg_config -id {HDL 9-1654} -limit 100000

start_step init_design
set rc [catch {
  create_msg_db init_design.pb
  set_property design_mode GateLvl [current_fileset]
  set_property webtalk.parent_dir /home/yunq/Zybo-MiPy-20151214/XilinxPythonProject/micropython/zybo/vivado/pmod/zybo_mipy/project_1.cache/wt [current_project]
  set_property parent.project_path /home/yunq/Zybo-MiPy-20151214/XilinxPythonProject/micropython/zybo/vivado/pmod/zybo_mipy/project_1.xpr [current_project]
  set_property ip_repo_paths {
  /home/yunq/Zybo-MiPy-20151214/XilinxPythonProject/micropython/zybo/vivado/pmod/zybo_mipy/project_1.cache/ip
  /home/yunq/Zybo-MiPy-20151214/XilinxPythonProject/micropython/zybo/vivado/pmod/src/ip
} [current_project]
  set_property ip_output_repo /home/yunq/Zybo-MiPy-20151214/XilinxPythonProject/micropython/zybo/vivado/pmod/zybo_mipy/project_1.cache/ip [current_project]
  add_files -quiet /home/yunq/Zybo-MiPy-20151214/XilinxPythonProject/micropython/zybo/vivado/pmod/zybo_mipy/project_1.runs/synth_1/top.dcp
  add_files /home/yunq/Zybo-MiPy-20151214/XilinxPythonProject/micropython/zybo/vivado/pmod/zybo_mipy/project_1.srcs/sources_1/bd/system/system.bmm
  set_property SCOPED_TO_REF system [get_files -all /home/yunq/Zybo-MiPy-20151214/XilinxPythonProject/micropython/zybo/vivado/pmod/zybo_mipy/project_1.srcs/sources_1/bd/system/system.bmm]
  set_property SCOPED_TO_CELLS {} [get_files -all /home/yunq/Zybo-MiPy-20151214/XilinxPythonProject/micropython/zybo/vivado/pmod/zybo_mipy/project_1.srcs/sources_1/bd/system/system.bmm]
  add_files /home/yunq/Zybo-MiPy-20151214/XilinxPythonProject/micropython/zybo/vivado/pmod/zybo_mipy/project_1.srcs/sources_1/bd/system/ipshared/xilinx.com/microblaze_v9_5/data/mb_bootloop_le.elf
  set_property SCOPED_TO_REF system [get_files -all /home/yunq/Zybo-MiPy-20151214/XilinxPythonProject/micropython/zybo/vivado/pmod/zybo_mipy/project_1.srcs/sources_1/bd/system/ipshared/xilinx.com/microblaze_v9_5/data/mb_bootloop_le.elf]
  set_property SCOPED_TO_CELLS {mb_JB/mb_1 mb_JC/mb_2 mb_JD/mb_3 mb_JE/mb_4} [get_files -all /home/yunq/Zybo-MiPy-20151214/XilinxPythonProject/micropython/zybo/vivado/pmod/zybo_mipy/project_1.srcs/sources_1/bd/system/ipshared/xilinx.com/microblaze_v9_5/data/mb_bootloop_le.elf]
  read_xdc -prop_thru_buffers -ref system_btns_gpio_0 -cells U0 /home/yunq/Zybo-MiPy-20151214/XilinxPythonProject/micropython/zybo/vivado/pmod/zybo_mipy/project_1.srcs/sources_1/bd/system/ip/system_btns_gpio_0/system_btns_gpio_0_board.xdc
  set_property processing_order EARLY [get_files /home/yunq/Zybo-MiPy-20151214/XilinxPythonProject/micropython/zybo/vivado/pmod/zybo_mipy/project_1.srcs/sources_1/bd/system/ip/system_btns_gpio_0/system_btns_gpio_0_board.xdc]
  read_xdc -ref system_btns_gpio_0 -cells U0 /home/yunq/Zybo-MiPy-20151214/XilinxPythonProject/micropython/zybo/vivado/pmod/zybo_mipy/project_1.srcs/sources_1/bd/system/ip/system_btns_gpio_0/system_btns_gpio_0.xdc
  set_property processing_order EARLY [get_files /home/yunq/Zybo-MiPy-20151214/XilinxPythonProject/micropython/zybo/vivado/pmod/zybo_mipy/project_1.srcs/sources_1/bd/system/ip/system_btns_gpio_0/system_btns_gpio_0.xdc]
  read_xdc -prop_thru_buffers -ref system_mb1_gpio_0 -cells U0 /home/yunq/Zybo-MiPy-20151214/XilinxPythonProject/micropython/zybo/vivado/pmod/zybo_mipy/project_1.srcs/sources_1/bd/system/ip/system_mb1_gpio_0/system_mb1_gpio_0_board.xdc
  set_property processing_order EARLY [get_files /home/yunq/Zybo-MiPy-20151214/XilinxPythonProject/micropython/zybo/vivado/pmod/zybo_mipy/project_1.srcs/sources_1/bd/system/ip/system_mb1_gpio_0/system_mb1_gpio_0_board.xdc]
  read_xdc -ref system_mb1_gpio_0 -cells U0 /home/yunq/Zybo-MiPy-20151214/XilinxPythonProject/micropython/zybo/vivado/pmod/zybo_mipy/project_1.srcs/sources_1/bd/system/ip/system_mb1_gpio_0/system_mb1_gpio_0.xdc
  set_property processing_order EARLY [get_files /home/yunq/Zybo-MiPy-20151214/XilinxPythonProject/micropython/zybo/vivado/pmod/zybo_mipy/project_1.srcs/sources_1/bd/system/ip/system_mb1_gpio_0/system_mb1_gpio_0.xdc]
  read_xdc -prop_thru_buffers -ref system_mb1_iic_0 /home/yunq/Zybo-MiPy-20151214/XilinxPythonProject/micropython/zybo/vivado/pmod/zybo_mipy/project_1.srcs/sources_1/bd/system/ip/system_mb1_iic_0/system_mb1_iic_0_board.xdc
  set_property processing_order EARLY [get_files /home/yunq/Zybo-MiPy-20151214/XilinxPythonProject/micropython/zybo/vivado/pmod/zybo_mipy/project_1.srcs/sources_1/bd/system/ip/system_mb1_iic_0/system_mb1_iic_0_board.xdc]
  read_xdc -ref system_dlmb_v10_0 -cells U0 /home/yunq/Zybo-MiPy-20151214/XilinxPythonProject/micropython/zybo/vivado/pmod/zybo_mipy/project_1.srcs/sources_1/bd/system/ip/system_dlmb_v10_0/system_dlmb_v10_0.xdc
  set_property processing_order EARLY [get_files /home/yunq/Zybo-MiPy-20151214/XilinxPythonProject/micropython/zybo/vivado/pmod/zybo_mipy/project_1.srcs/sources_1/bd/system/ip/system_dlmb_v10_0/system_dlmb_v10_0.xdc]
  read_xdc -ref system_ilmb_v10_0 -cells U0 /home/yunq/Zybo-MiPy-20151214/XilinxPythonProject/micropython/zybo/vivado/pmod/zybo_mipy/project_1.srcs/sources_1/bd/system/ip/system_ilmb_v10_0/system_ilmb_v10_0.xdc
  set_property processing_order EARLY [get_files /home/yunq/Zybo-MiPy-20151214/XilinxPythonProject/micropython/zybo/vivado/pmod/zybo_mipy/project_1.srcs/sources_1/bd/system/ip/system_ilmb_v10_0/system_ilmb_v10_0.xdc]
  read_xdc -prop_thru_buffers -ref system_mb1_spi_0 -cells U0 /home/yunq/Zybo-MiPy-20151214/XilinxPythonProject/micropython/zybo/vivado/pmod/zybo_mipy/project_1.srcs/sources_1/bd/system/ip/system_mb1_spi_0/system_mb1_spi_0_board.xdc
  set_property processing_order EARLY [get_files /home/yunq/Zybo-MiPy-20151214/XilinxPythonProject/micropython/zybo/vivado/pmod/zybo_mipy/project_1.srcs/sources_1/bd/system/ip/system_mb1_spi_0/system_mb1_spi_0_board.xdc]
  read_xdc -ref system_mb1_spi_0 -cells U0 /home/yunq/Zybo-MiPy-20151214/XilinxPythonProject/micropython/zybo/vivado/pmod/zybo_mipy/project_1.srcs/sources_1/bd/system/ip/system_mb1_spi_0/system_mb1_spi_0.xdc
  set_property processing_order EARLY [get_files /home/yunq/Zybo-MiPy-20151214/XilinxPythonProject/micropython/zybo/vivado/pmod/zybo_mipy/project_1.srcs/sources_1/bd/system/ip/system_mb1_spi_0/system_mb1_spi_0.xdc]
  read_xdc -ref system_mb_1_0 -cells U0 /home/yunq/Zybo-MiPy-20151214/XilinxPythonProject/micropython/zybo/vivado/pmod/zybo_mipy/project_1.srcs/sources_1/bd/system/ip/system_mb_1_0/system_mb_1_0.xdc
  set_property processing_order EARLY [get_files /home/yunq/Zybo-MiPy-20151214/XilinxPythonProject/micropython/zybo/vivado/pmod/zybo_mipy/project_1.srcs/sources_1/bd/system/ip/system_mb_1_0/system_mb_1_0.xdc]
  read_xdc -prop_thru_buffers -ref system_rst_clk_wiz_1_100M_0 /home/yunq/Zybo-MiPy-20151214/XilinxPythonProject/micropython/zybo/vivado/pmod/zybo_mipy/project_1.srcs/sources_1/bd/system/ip/system_rst_clk_wiz_1_100M_0/system_rst_clk_wiz_1_100M_0_board.xdc
  set_property processing_order EARLY [get_files /home/yunq/Zybo-MiPy-20151214/XilinxPythonProject/micropython/zybo/vivado/pmod/zybo_mipy/project_1.srcs/sources_1/bd/system/ip/system_rst_clk_wiz_1_100M_0/system_rst_clk_wiz_1_100M_0_board.xdc]
  read_xdc -ref system_rst_clk_wiz_1_100M_0 /home/yunq/Zybo-MiPy-20151214/XilinxPythonProject/micropython/zybo/vivado/pmod/zybo_mipy/project_1.srcs/sources_1/bd/system/ip/system_rst_clk_wiz_1_100M_0/system_rst_clk_wiz_1_100M_0.xdc
  set_property processing_order EARLY [get_files /home/yunq/Zybo-MiPy-20151214/XilinxPythonProject/micropython/zybo/vivado/pmod/zybo_mipy/project_1.srcs/sources_1/bd/system/ip/system_rst_clk_wiz_1_100M_0/system_rst_clk_wiz_1_100M_0.xdc]
  read_xdc -prop_thru_buffers -ref system_mb2_gpio_0 -cells U0 /home/yunq/Zybo-MiPy-20151214/XilinxPythonProject/micropython/zybo/vivado/pmod/zybo_mipy/project_1.srcs/sources_1/bd/system/ip/system_mb2_gpio_0/system_mb2_gpio_0_board.xdc
  set_property processing_order EARLY [get_files /home/yunq/Zybo-MiPy-20151214/XilinxPythonProject/micropython/zybo/vivado/pmod/zybo_mipy/project_1.srcs/sources_1/bd/system/ip/system_mb2_gpio_0/system_mb2_gpio_0_board.xdc]
  read_xdc -ref system_mb2_gpio_0 -cells U0 /home/yunq/Zybo-MiPy-20151214/XilinxPythonProject/micropython/zybo/vivado/pmod/zybo_mipy/project_1.srcs/sources_1/bd/system/ip/system_mb2_gpio_0/system_mb2_gpio_0.xdc
  set_property processing_order EARLY [get_files /home/yunq/Zybo-MiPy-20151214/XilinxPythonProject/micropython/zybo/vivado/pmod/zybo_mipy/project_1.srcs/sources_1/bd/system/ip/system_mb2_gpio_0/system_mb2_gpio_0.xdc]
  read_xdc -prop_thru_buffers -ref system_mb2_iic_0 /home/yunq/Zybo-MiPy-20151214/XilinxPythonProject/micropython/zybo/vivado/pmod/zybo_mipy/project_1.srcs/sources_1/bd/system/ip/system_mb2_iic_0/system_mb2_iic_0_board.xdc
  set_property processing_order EARLY [get_files /home/yunq/Zybo-MiPy-20151214/XilinxPythonProject/micropython/zybo/vivado/pmod/zybo_mipy/project_1.srcs/sources_1/bd/system/ip/system_mb2_iic_0/system_mb2_iic_0_board.xdc]
  read_xdc -ref system_dlmb_v10_1 -cells U0 /home/yunq/Zybo-MiPy-20151214/XilinxPythonProject/micropython/zybo/vivado/pmod/zybo_mipy/project_1.srcs/sources_1/bd/system/ip/system_dlmb_v10_1/system_dlmb_v10_1.xdc
  set_property processing_order EARLY [get_files /home/yunq/Zybo-MiPy-20151214/XilinxPythonProject/micropython/zybo/vivado/pmod/zybo_mipy/project_1.srcs/sources_1/bd/system/ip/system_dlmb_v10_1/system_dlmb_v10_1.xdc]
  read_xdc -ref system_ilmb_v10_1 -cells U0 /home/yunq/Zybo-MiPy-20151214/XilinxPythonProject/micropython/zybo/vivado/pmod/zybo_mipy/project_1.srcs/sources_1/bd/system/ip/system_ilmb_v10_1/system_ilmb_v10_1.xdc
  set_property processing_order EARLY [get_files /home/yunq/Zybo-MiPy-20151214/XilinxPythonProject/micropython/zybo/vivado/pmod/zybo_mipy/project_1.srcs/sources_1/bd/system/ip/system_ilmb_v10_1/system_ilmb_v10_1.xdc]
  read_xdc -prop_thru_buffers -ref system_mb2_spi_0 -cells U0 /home/yunq/Zybo-MiPy-20151214/XilinxPythonProject/micropython/zybo/vivado/pmod/zybo_mipy/project_1.srcs/sources_1/bd/system/ip/system_mb2_spi_0/system_mb2_spi_0_board.xdc
  set_property processing_order EARLY [get_files /home/yunq/Zybo-MiPy-20151214/XilinxPythonProject/micropython/zybo/vivado/pmod/zybo_mipy/project_1.srcs/sources_1/bd/system/ip/system_mb2_spi_0/system_mb2_spi_0_board.xdc]
  read_xdc -ref system_mb2_spi_0 -cells U0 /home/yunq/Zybo-MiPy-20151214/XilinxPythonProject/micropython/zybo/vivado/pmod/zybo_mipy/project_1.srcs/sources_1/bd/system/ip/system_mb2_spi_0/system_mb2_spi_0.xdc
  set_property processing_order EARLY [get_files /home/yunq/Zybo-MiPy-20151214/XilinxPythonProject/micropython/zybo/vivado/pmod/zybo_mipy/project_1.srcs/sources_1/bd/system/ip/system_mb2_spi_0/system_mb2_spi_0.xdc]
  read_xdc -ref system_mb_2_0 -cells U0 /home/yunq/Zybo-MiPy-20151214/XilinxPythonProject/micropython/zybo/vivado/pmod/zybo_mipy/project_1.srcs/sources_1/bd/system/ip/system_mb_2_0/system_mb_2_0.xdc
  set_property processing_order EARLY [get_files /home/yunq/Zybo-MiPy-20151214/XilinxPythonProject/micropython/zybo/vivado/pmod/zybo_mipy/project_1.srcs/sources_1/bd/system/ip/system_mb_2_0/system_mb_2_0.xdc]
  read_xdc -prop_thru_buffers -ref system_rst_clk_wiz_1_100M_1 /home/yunq/Zybo-MiPy-20151214/XilinxPythonProject/micropython/zybo/vivado/pmod/zybo_mipy/project_1.srcs/sources_1/bd/system/ip/system_rst_clk_wiz_1_100M_1/system_rst_clk_wiz_1_100M_1_board.xdc
  set_property processing_order EARLY [get_files /home/yunq/Zybo-MiPy-20151214/XilinxPythonProject/micropython/zybo/vivado/pmod/zybo_mipy/project_1.srcs/sources_1/bd/system/ip/system_rst_clk_wiz_1_100M_1/system_rst_clk_wiz_1_100M_1_board.xdc]
  read_xdc -ref system_rst_clk_wiz_1_100M_1 /home/yunq/Zybo-MiPy-20151214/XilinxPythonProject/micropython/zybo/vivado/pmod/zybo_mipy/project_1.srcs/sources_1/bd/system/ip/system_rst_clk_wiz_1_100M_1/system_rst_clk_wiz_1_100M_1.xdc
  set_property processing_order EARLY [get_files /home/yunq/Zybo-MiPy-20151214/XilinxPythonProject/micropython/zybo/vivado/pmod/zybo_mipy/project_1.srcs/sources_1/bd/system/ip/system_rst_clk_wiz_1_100M_1/system_rst_clk_wiz_1_100M_1.xdc]
  read_xdc -prop_thru_buffers -ref system_mb3_gpio_0 -cells U0 /home/yunq/Zybo-MiPy-20151214/XilinxPythonProject/micropython/zybo/vivado/pmod/zybo_mipy/project_1.srcs/sources_1/bd/system/ip/system_mb3_gpio_0/system_mb3_gpio_0_board.xdc
  set_property processing_order EARLY [get_files /home/yunq/Zybo-MiPy-20151214/XilinxPythonProject/micropython/zybo/vivado/pmod/zybo_mipy/project_1.srcs/sources_1/bd/system/ip/system_mb3_gpio_0/system_mb3_gpio_0_board.xdc]
  read_xdc -ref system_mb3_gpio_0 -cells U0 /home/yunq/Zybo-MiPy-20151214/XilinxPythonProject/micropython/zybo/vivado/pmod/zybo_mipy/project_1.srcs/sources_1/bd/system/ip/system_mb3_gpio_0/system_mb3_gpio_0.xdc
  set_property processing_order EARLY [get_files /home/yunq/Zybo-MiPy-20151214/XilinxPythonProject/micropython/zybo/vivado/pmod/zybo_mipy/project_1.srcs/sources_1/bd/system/ip/system_mb3_gpio_0/system_mb3_gpio_0.xdc]
  read_xdc -prop_thru_buffers -ref system_mb3_iic_0 /home/yunq/Zybo-MiPy-20151214/XilinxPythonProject/micropython/zybo/vivado/pmod/zybo_mipy/project_1.srcs/sources_1/bd/system/ip/system_mb3_iic_0/system_mb3_iic_0_board.xdc
  set_property processing_order EARLY [get_files /home/yunq/Zybo-MiPy-20151214/XilinxPythonProject/micropython/zybo/vivado/pmod/zybo_mipy/project_1.srcs/sources_1/bd/system/ip/system_mb3_iic_0/system_mb3_iic_0_board.xdc]
  read_xdc -ref system_dlmb_v10_2 -cells U0 /home/yunq/Zybo-MiPy-20151214/XilinxPythonProject/micropython/zybo/vivado/pmod/zybo_mipy/project_1.srcs/sources_1/bd/system/ip/system_dlmb_v10_2/system_dlmb_v10_2.xdc
  set_property processing_order EARLY [get_files /home/yunq/Zybo-MiPy-20151214/XilinxPythonProject/micropython/zybo/vivado/pmod/zybo_mipy/project_1.srcs/sources_1/bd/system/ip/system_dlmb_v10_2/system_dlmb_v10_2.xdc]
  read_xdc -ref system_ilmb_v10_2 -cells U0 /home/yunq/Zybo-MiPy-20151214/XilinxPythonProject/micropython/zybo/vivado/pmod/zybo_mipy/project_1.srcs/sources_1/bd/system/ip/system_ilmb_v10_2/system_ilmb_v10_2.xdc
  set_property processing_order EARLY [get_files /home/yunq/Zybo-MiPy-20151214/XilinxPythonProject/micropython/zybo/vivado/pmod/zybo_mipy/project_1.srcs/sources_1/bd/system/ip/system_ilmb_v10_2/system_ilmb_v10_2.xdc]
  read_xdc -prop_thru_buffers -ref system_mb3_spi_0 -cells U0 /home/yunq/Zybo-MiPy-20151214/XilinxPythonProject/micropython/zybo/vivado/pmod/zybo_mipy/project_1.srcs/sources_1/bd/system/ip/system_mb3_spi_0/system_mb3_spi_0_board.xdc
  set_property processing_order EARLY [get_files /home/yunq/Zybo-MiPy-20151214/XilinxPythonProject/micropython/zybo/vivado/pmod/zybo_mipy/project_1.srcs/sources_1/bd/system/ip/system_mb3_spi_0/system_mb3_spi_0_board.xdc]
  read_xdc -ref system_mb3_spi_0 -cells U0 /home/yunq/Zybo-MiPy-20151214/XilinxPythonProject/micropython/zybo/vivado/pmod/zybo_mipy/project_1.srcs/sources_1/bd/system/ip/system_mb3_spi_0/system_mb3_spi_0.xdc
  set_property processing_order EARLY [get_files /home/yunq/Zybo-MiPy-20151214/XilinxPythonProject/micropython/zybo/vivado/pmod/zybo_mipy/project_1.srcs/sources_1/bd/system/ip/system_mb3_spi_0/system_mb3_spi_0.xdc]
  read_xdc -ref system_mb_3_0 -cells U0 /home/yunq/Zybo-MiPy-20151214/XilinxPythonProject/micropython/zybo/vivado/pmod/zybo_mipy/project_1.srcs/sources_1/bd/system/ip/system_mb_3_0/system_mb_3_0.xdc
  set_property processing_order EARLY [get_files /home/yunq/Zybo-MiPy-20151214/XilinxPythonProject/micropython/zybo/vivado/pmod/zybo_mipy/project_1.srcs/sources_1/bd/system/ip/system_mb_3_0/system_mb_3_0.xdc]
  read_xdc -prop_thru_buffers -ref system_rst_clk_wiz_1_100M_2 /home/yunq/Zybo-MiPy-20151214/XilinxPythonProject/micropython/zybo/vivado/pmod/zybo_mipy/project_1.srcs/sources_1/bd/system/ip/system_rst_clk_wiz_1_100M_2/system_rst_clk_wiz_1_100M_2_board.xdc
  set_property processing_order EARLY [get_files /home/yunq/Zybo-MiPy-20151214/XilinxPythonProject/micropython/zybo/vivado/pmod/zybo_mipy/project_1.srcs/sources_1/bd/system/ip/system_rst_clk_wiz_1_100M_2/system_rst_clk_wiz_1_100M_2_board.xdc]
  read_xdc -ref system_rst_clk_wiz_1_100M_2 /home/yunq/Zybo-MiPy-20151214/XilinxPythonProject/micropython/zybo/vivado/pmod/zybo_mipy/project_1.srcs/sources_1/bd/system/ip/system_rst_clk_wiz_1_100M_2/system_rst_clk_wiz_1_100M_2.xdc
  set_property processing_order EARLY [get_files /home/yunq/Zybo-MiPy-20151214/XilinxPythonProject/micropython/zybo/vivado/pmod/zybo_mipy/project_1.srcs/sources_1/bd/system/ip/system_rst_clk_wiz_1_100M_2/system_rst_clk_wiz_1_100M_2.xdc]
  read_xdc -prop_thru_buffers -ref system_mb4_gpio_0 -cells U0 /home/yunq/Zybo-MiPy-20151214/XilinxPythonProject/micropython/zybo/vivado/pmod/zybo_mipy/project_1.srcs/sources_1/bd/system/ip/system_mb4_gpio_0/system_mb4_gpio_0_board.xdc
  set_property processing_order EARLY [get_files /home/yunq/Zybo-MiPy-20151214/XilinxPythonProject/micropython/zybo/vivado/pmod/zybo_mipy/project_1.srcs/sources_1/bd/system/ip/system_mb4_gpio_0/system_mb4_gpio_0_board.xdc]
  read_xdc -ref system_mb4_gpio_0 -cells U0 /home/yunq/Zybo-MiPy-20151214/XilinxPythonProject/micropython/zybo/vivado/pmod/zybo_mipy/project_1.srcs/sources_1/bd/system/ip/system_mb4_gpio_0/system_mb4_gpio_0.xdc
  set_property processing_order EARLY [get_files /home/yunq/Zybo-MiPy-20151214/XilinxPythonProject/micropython/zybo/vivado/pmod/zybo_mipy/project_1.srcs/sources_1/bd/system/ip/system_mb4_gpio_0/system_mb4_gpio_0.xdc]
  read_xdc -prop_thru_buffers -ref system_mb4_iic_0 /home/yunq/Zybo-MiPy-20151214/XilinxPythonProject/micropython/zybo/vivado/pmod/zybo_mipy/project_1.srcs/sources_1/bd/system/ip/system_mb4_iic_0/system_mb4_iic_0_board.xdc
  set_property processing_order EARLY [get_files /home/yunq/Zybo-MiPy-20151214/XilinxPythonProject/micropython/zybo/vivado/pmod/zybo_mipy/project_1.srcs/sources_1/bd/system/ip/system_mb4_iic_0/system_mb4_iic_0_board.xdc]
  read_xdc -ref system_dlmb_v10_3 -cells U0 /home/yunq/Zybo-MiPy-20151214/XilinxPythonProject/micropython/zybo/vivado/pmod/zybo_mipy/project_1.srcs/sources_1/bd/system/ip/system_dlmb_v10_3/system_dlmb_v10_3.xdc
  set_property processing_order EARLY [get_files /home/yunq/Zybo-MiPy-20151214/XilinxPythonProject/micropython/zybo/vivado/pmod/zybo_mipy/project_1.srcs/sources_1/bd/system/ip/system_dlmb_v10_3/system_dlmb_v10_3.xdc]
  read_xdc -ref system_ilmb_v10_3 -cells U0 /home/yunq/Zybo-MiPy-20151214/XilinxPythonProject/micropython/zybo/vivado/pmod/zybo_mipy/project_1.srcs/sources_1/bd/system/ip/system_ilmb_v10_3/system_ilmb_v10_3.xdc
  set_property processing_order EARLY [get_files /home/yunq/Zybo-MiPy-20151214/XilinxPythonProject/micropython/zybo/vivado/pmod/zybo_mipy/project_1.srcs/sources_1/bd/system/ip/system_ilmb_v10_3/system_ilmb_v10_3.xdc]
  read_xdc -prop_thru_buffers -ref system_mb4_spi_0 -cells U0 /home/yunq/Zybo-MiPy-20151214/XilinxPythonProject/micropython/zybo/vivado/pmod/zybo_mipy/project_1.srcs/sources_1/bd/system/ip/system_mb4_spi_0/system_mb4_spi_0_board.xdc
  set_property processing_order EARLY [get_files /home/yunq/Zybo-MiPy-20151214/XilinxPythonProject/micropython/zybo/vivado/pmod/zybo_mipy/project_1.srcs/sources_1/bd/system/ip/system_mb4_spi_0/system_mb4_spi_0_board.xdc]
  read_xdc -ref system_mb4_spi_0 -cells U0 /home/yunq/Zybo-MiPy-20151214/XilinxPythonProject/micropython/zybo/vivado/pmod/zybo_mipy/project_1.srcs/sources_1/bd/system/ip/system_mb4_spi_0/system_mb4_spi_0.xdc
  set_property processing_order EARLY [get_files /home/yunq/Zybo-MiPy-20151214/XilinxPythonProject/micropython/zybo/vivado/pmod/zybo_mipy/project_1.srcs/sources_1/bd/system/ip/system_mb4_spi_0/system_mb4_spi_0.xdc]
  read_xdc -ref system_mb_4_0 -cells U0 /home/yunq/Zybo-MiPy-20151214/XilinxPythonProject/micropython/zybo/vivado/pmod/zybo_mipy/project_1.srcs/sources_1/bd/system/ip/system_mb_4_0/system_mb_4_0.xdc
  set_property processing_order EARLY [get_files /home/yunq/Zybo-MiPy-20151214/XilinxPythonProject/micropython/zybo/vivado/pmod/zybo_mipy/project_1.srcs/sources_1/bd/system/ip/system_mb_4_0/system_mb_4_0.xdc]
  read_xdc -prop_thru_buffers -ref system_rst_clk_wiz_1_100M_3 /home/yunq/Zybo-MiPy-20151214/XilinxPythonProject/micropython/zybo/vivado/pmod/zybo_mipy/project_1.srcs/sources_1/bd/system/ip/system_rst_clk_wiz_1_100M_3/system_rst_clk_wiz_1_100M_3_board.xdc
  set_property processing_order EARLY [get_files /home/yunq/Zybo-MiPy-20151214/XilinxPythonProject/micropython/zybo/vivado/pmod/zybo_mipy/project_1.srcs/sources_1/bd/system/ip/system_rst_clk_wiz_1_100M_3/system_rst_clk_wiz_1_100M_3_board.xdc]
  read_xdc -ref system_rst_clk_wiz_1_100M_3 /home/yunq/Zybo-MiPy-20151214/XilinxPythonProject/micropython/zybo/vivado/pmod/zybo_mipy/project_1.srcs/sources_1/bd/system/ip/system_rst_clk_wiz_1_100M_3/system_rst_clk_wiz_1_100M_3.xdc
  set_property processing_order EARLY [get_files /home/yunq/Zybo-MiPy-20151214/XilinxPythonProject/micropython/zybo/vivado/pmod/zybo_mipy/project_1.srcs/sources_1/bd/system/ip/system_rst_clk_wiz_1_100M_3/system_rst_clk_wiz_1_100M_3.xdc]
  read_xdc -ref system_mdm_1_0 -cells U0 /home/yunq/Zybo-MiPy-20151214/XilinxPythonProject/micropython/zybo/vivado/pmod/zybo_mipy/project_1.srcs/sources_1/bd/system/ip/system_mdm_1_0/system_mdm_1_0.xdc
  set_property processing_order EARLY [get_files /home/yunq/Zybo-MiPy-20151214/XilinxPythonProject/micropython/zybo/vivado/pmod/zybo_mipy/project_1.srcs/sources_1/bd/system/ip/system_mdm_1_0/system_mdm_1_0.xdc]
  read_xdc -ref system_processing_system7_0_0 -cells inst /home/yunq/Zybo-MiPy-20151214/XilinxPythonProject/micropython/zybo/vivado/pmod/zybo_mipy/project_1.srcs/sources_1/bd/system/ip/system_processing_system7_0_0/system_processing_system7_0_0.xdc
  set_property processing_order EARLY [get_files /home/yunq/Zybo-MiPy-20151214/XilinxPythonProject/micropython/zybo/vivado/pmod/zybo_mipy/project_1.srcs/sources_1/bd/system/ip/system_processing_system7_0_0/system_processing_system7_0_0.xdc]
  read_xdc -prop_thru_buffers -ref system_rst_processing_system7_0_100M_0 /home/yunq/Zybo-MiPy-20151214/XilinxPythonProject/micropython/zybo/vivado/pmod/zybo_mipy/project_1.srcs/sources_1/bd/system/ip/system_rst_processing_system7_0_100M_0/system_rst_processing_system7_0_100M_0_board.xdc
  set_property processing_order EARLY [get_files /home/yunq/Zybo-MiPy-20151214/XilinxPythonProject/micropython/zybo/vivado/pmod/zybo_mipy/project_1.srcs/sources_1/bd/system/ip/system_rst_processing_system7_0_100M_0/system_rst_processing_system7_0_100M_0_board.xdc]
  read_xdc -ref system_rst_processing_system7_0_100M_0 /home/yunq/Zybo-MiPy-20151214/XilinxPythonProject/micropython/zybo/vivado/pmod/zybo_mipy/project_1.srcs/sources_1/bd/system/ip/system_rst_processing_system7_0_100M_0/system_rst_processing_system7_0_100M_0.xdc
  set_property processing_order EARLY [get_files /home/yunq/Zybo-MiPy-20151214/XilinxPythonProject/micropython/zybo/vivado/pmod/zybo_mipy/project_1.srcs/sources_1/bd/system/ip/system_rst_processing_system7_0_100M_0/system_rst_processing_system7_0_100M_0.xdc]
  read_xdc -prop_thru_buffers -ref system_swsleds_gpio_0 -cells U0 /home/yunq/Zybo-MiPy-20151214/XilinxPythonProject/micropython/zybo/vivado/pmod/zybo_mipy/project_1.srcs/sources_1/bd/system/ip/system_swsleds_gpio_0/system_swsleds_gpio_0_board.xdc
  set_property processing_order EARLY [get_files /home/yunq/Zybo-MiPy-20151214/XilinxPythonProject/micropython/zybo/vivado/pmod/zybo_mipy/project_1.srcs/sources_1/bd/system/ip/system_swsleds_gpio_0/system_swsleds_gpio_0_board.xdc]
  read_xdc -ref system_swsleds_gpio_0 -cells U0 /home/yunq/Zybo-MiPy-20151214/XilinxPythonProject/micropython/zybo/vivado/pmod/zybo_mipy/project_1.srcs/sources_1/bd/system/ip/system_swsleds_gpio_0/system_swsleds_gpio_0.xdc
  set_property processing_order EARLY [get_files /home/yunq/Zybo-MiPy-20151214/XilinxPythonProject/micropython/zybo/vivado/pmod/zybo_mipy/project_1.srcs/sources_1/bd/system/ip/system_swsleds_gpio_0/system_swsleds_gpio_0.xdc]
  read_xdc -ref system_xadc_wiz_0_0 -cells inst /home/yunq/Zybo-MiPy-20151214/XilinxPythonProject/micropython/zybo/vivado/pmod/zybo_mipy/project_1.srcs/sources_1/bd/system/ip/system_xadc_wiz_0_0/system_xadc_wiz_0_0.xdc
  set_property processing_order EARLY [get_files /home/yunq/Zybo-MiPy-20151214/XilinxPythonProject/micropython/zybo/vivado/pmod/zybo_mipy/project_1.srcs/sources_1/bd/system/ip/system_xadc_wiz_0_0/system_xadc_wiz_0_0.xdc]
  read_xdc /home/yunq/Zybo-MiPy-20151214/XilinxPythonProject/micropython/zybo/vivado/pmod/src/constraints/top.xdc
  read_xdc -ref system_mb1_spi_0 -cells U0 /home/yunq/Zybo-MiPy-20151214/XilinxPythonProject/micropython/zybo/vivado/pmod/zybo_mipy/project_1.srcs/sources_1/bd/system/ip/system_mb1_spi_0/system_mb1_spi_0_clocks.xdc
  set_property processing_order LATE [get_files /home/yunq/Zybo-MiPy-20151214/XilinxPythonProject/micropython/zybo/vivado/pmod/zybo_mipy/project_1.srcs/sources_1/bd/system/ip/system_mb1_spi_0/system_mb1_spi_0_clocks.xdc]
  read_xdc -ref system_mb2_spi_0 -cells U0 /home/yunq/Zybo-MiPy-20151214/XilinxPythonProject/micropython/zybo/vivado/pmod/zybo_mipy/project_1.srcs/sources_1/bd/system/ip/system_mb2_spi_0/system_mb2_spi_0_clocks.xdc
  set_property processing_order LATE [get_files /home/yunq/Zybo-MiPy-20151214/XilinxPythonProject/micropython/zybo/vivado/pmod/zybo_mipy/project_1.srcs/sources_1/bd/system/ip/system_mb2_spi_0/system_mb2_spi_0_clocks.xdc]
  read_xdc -ref system_mb3_spi_0 -cells U0 /home/yunq/Zybo-MiPy-20151214/XilinxPythonProject/micropython/zybo/vivado/pmod/zybo_mipy/project_1.srcs/sources_1/bd/system/ip/system_mb3_spi_0/system_mb3_spi_0_clocks.xdc
  set_property processing_order LATE [get_files /home/yunq/Zybo-MiPy-20151214/XilinxPythonProject/micropython/zybo/vivado/pmod/zybo_mipy/project_1.srcs/sources_1/bd/system/ip/system_mb3_spi_0/system_mb3_spi_0_clocks.xdc]
  read_xdc -ref system_mb4_spi_0 -cells U0 /home/yunq/Zybo-MiPy-20151214/XilinxPythonProject/micropython/zybo/vivado/pmod/zybo_mipy/project_1.srcs/sources_1/bd/system/ip/system_mb4_spi_0/system_mb4_spi_0_clocks.xdc
  set_property processing_order LATE [get_files /home/yunq/Zybo-MiPy-20151214/XilinxPythonProject/micropython/zybo/vivado/pmod/zybo_mipy/project_1.srcs/sources_1/bd/system/ip/system_mb4_spi_0/system_mb4_spi_0_clocks.xdc]
  link_design -top top -part xc7z010clg400-1
  close_msg_db -file init_design.pb
} RESULT]
if {$rc} {
  step_failed init_design
  return -code error $RESULT
} else {
  end_step init_design
}

start_step opt_design
set rc [catch {
  create_msg_db opt_design.pb
  catch {write_debug_probes -quiet -force debug_nets}
  opt_design 
  write_checkpoint -force top_opt.dcp
  report_drc -file top_drc_opted.rpt
  close_msg_db -file opt_design.pb
} RESULT]
if {$rc} {
  step_failed opt_design
  return -code error $RESULT
} else {
  end_step opt_design
}

start_step place_design
set rc [catch {
  create_msg_db place_design.pb
  catch {write_hwdef -file top.hwdef}
  place_design 
  write_checkpoint -force top_placed.dcp
  report_io -file top_io_placed.rpt
  report_utilization -file top_utilization_placed.rpt -pb top_utilization_placed.pb
  report_control_sets -verbose -file top_control_sets_placed.rpt
  close_msg_db -file place_design.pb
} RESULT]
if {$rc} {
  step_failed place_design
  return -code error $RESULT
} else {
  end_step place_design
}

start_step route_design
set rc [catch {
  create_msg_db route_design.pb
  route_design 
  write_checkpoint -force top_routed.dcp
  report_drc -file top_drc_routed.rpt -pb top_drc_routed.pb
  report_timing_summary -warn_on_violation -max_paths 10 -file top_timing_summary_routed.rpt -rpx top_timing_summary_routed.rpx
  report_power -file top_power_routed.rpt -pb top_power_summary_routed.pb
  report_route_status -file top_route_status.rpt -pb top_route_status.pb
  report_clock_utilization -file top_clock_utilization_routed.rpt
  close_msg_db -file route_design.pb
} RESULT]
if {$rc} {
  step_failed route_design
  return -code error $RESULT
} else {
  end_step route_design
}

start_step write_bitstream
set rc [catch {
  create_msg_db write_bitstream.pb
  catch { write_mem_info -force top.mmi }
  catch { write_bmm -force top_bd.bmm }
  write_bitstream -force top.bit 
  catch { write_sysdef -hwdef top.hwdef -bitfile top.bit -meminfo top.mmi -file top.sysdef }
  close_msg_db -file write_bitstream.pb
} RESULT]
if {$rc} {
  step_failed write_bitstream
  return -code error $RESULT
} else {
  end_step write_bitstream
}

