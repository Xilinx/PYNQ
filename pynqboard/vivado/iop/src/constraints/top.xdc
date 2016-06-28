create_property BMM_INFO_PROCESSOR cell -type string
create_property BMM_INFO_ADDRESS_SPACE cell -type string
##Switches
set_property -dict { PACKAGE_PIN M20   IOSTANDARD LVCMOS33 } [get_ports { sws_2bits_tri_i[0] }]; #IO_L7N_T1_AD2N_35 Sch=sw[0]
set_property -dict { PACKAGE_PIN M19   IOSTANDARD LVCMOS33 } [get_ports { sws_2bits_tri_i[1] }]; #IO_L7P_T1_AD2P_35 Sch=sw[1]
# set_property IOSTANDARD LVCMOS33 [get_ports {sws_2bits_tri_i[*]}]

##Buttons
set_property -dict { PACKAGE_PIN D19   IOSTANDARD LVCMOS33 } [get_ports { btns_4bits_tri_i[0] }]; #IO_L4P_T0_35 Sch=btn[0]
set_property -dict { PACKAGE_PIN D20   IOSTANDARD LVCMOS33 } [get_ports { btns_4bits_tri_i[1] }]; #IO_L4N_T0_35 Sch=btn[1]
set_property -dict { PACKAGE_PIN L20   IOSTANDARD LVCMOS33 } [get_ports { btns_4bits_tri_i[2] }]; #IO_L9N_T1_DQS_AD3N_35 Sch=btn[2]
set_property -dict { PACKAGE_PIN L19   IOSTANDARD LVCMOS33 } [get_ports { btns_4bits_tri_i[3] }]; #IO_L9P_T1_DQS_AD3P_35 Sch=btn[3]
# set_property IOSTANDARD LVCMOS33 [get_ports {btns_4bits_tri_i[*]}]

##LEDs
set_property -dict { PACKAGE_PIN R14   IOSTANDARD LVCMOS33 } [get_ports { leds_4bits_tri_o[0] }]; #IO_L6N_T0_VREF_34 Sch=led[0]
set_property -dict { PACKAGE_PIN P14   IOSTANDARD LVCMOS33 } [get_ports { leds_4bits_tri_o[1] }]; #IO_L6P_T0_34 Sch=led[1]
set_property -dict { PACKAGE_PIN N16   IOSTANDARD LVCMOS33 } [get_ports { leds_4bits_tri_o[2] }]; #IO_L21N_T3_DQS_AD14N_35 Sch=led[2]
set_property -dict { PACKAGE_PIN M14   IOSTANDARD LVCMOS33 } [get_ports { leds_4bits_tri_o[3] }]; #IO_L23P_T3_35 Sch=led[3]
# set_property IOSTANDARD LVCMOS33 [get_ports {leds_4bits_tri_o[*]}]

##pmod Header JB
set_property -dict { PACKAGE_PIN Y19   IOSTANDARD LVCMOS33     } [get_ports { pmodJB[1] }]; #IO_L17N_T2_34 Sch=ja_n[1]
set_property -dict { PACKAGE_PIN Y18   IOSTANDARD LVCMOS33     } [get_ports { pmodJB[0] }]; #IO_L17P_T2_34 Sch=ja_p[1]
set_property -dict { PACKAGE_PIN Y17   IOSTANDARD LVCMOS33     } [get_ports { pmodJB[3] }]; #IO_L7N_T1_34 Sch=ja_n[2]
set_property -dict { PACKAGE_PIN Y16   IOSTANDARD LVCMOS33     } [get_ports { pmodJB[2] }]; #IO_L7P_T1_34 Sch=ja_p[2]
set_property -dict { PACKAGE_PIN U19   IOSTANDARD LVCMOS33     } [get_ports { pmodJB[5] }]; #IO_L12N_T1_MRCC_34 Sch=ja_n[3]
set_property -dict { PACKAGE_PIN U18   IOSTANDARD LVCMOS33     } [get_ports { pmodJB[4] }]; #IO_L12P_T1_MRCC_34 Sch=ja_p[3]
set_property -dict { PACKAGE_PIN W19   IOSTANDARD LVCMOS33     } [get_ports { pmodJB[7] }]; #IO_L22N_T3_34 Sch=ja_n[4]
set_property -dict { PACKAGE_PIN W18   IOSTANDARD LVCMOS33     } [get_ports { pmodJB[6] }]; #IO_L22P_T3_34 Sch=ja_p[4]
# set_property IOSTANDARD LVCMOS33 [get_ports {pmodJB[*]}]
set_property PULLUP true [get_ports {pmodJB[2]}]
set_property PULLUP true [get_ports {pmodJB[3]}]
set_property PULLUP true [get_ports {pmodJB[6]}]
set_property PULLUP true [get_ports {pmodJB[7]}]

##pmod Header JC
set_property -dict { PACKAGE_PIN Y14   IOSTANDARD LVCMOS33     } [get_ports { pmodJC[1] }]; #IO_L8N_T1_34 Sch=jb_n[1]
set_property -dict { PACKAGE_PIN W14   IOSTANDARD LVCMOS33     } [get_ports { pmodJC[0] }]; #IO_L8P_T1_34 Sch=jb_p[1]
set_property -dict { PACKAGE_PIN T10   IOSTANDARD LVCMOS33     } [get_ports { pmodJC[3] }]; #IO_L1N_T0_34 Sch=jb_n[2]
set_property -dict { PACKAGE_PIN T11   IOSTANDARD LVCMOS33     } [get_ports { pmodJC[2] }]; #IO_L1P_T0_34 Sch=jb_p[2]
set_property -dict { PACKAGE_PIN W16   IOSTANDARD LVCMOS33     } [get_ports { pmodJC[5] }]; #IO_L18N_T2_34 Sch=jb_n[3]
set_property -dict { PACKAGE_PIN V16   IOSTANDARD LVCMOS33     } [get_ports { pmodJC[4] }]; #IO_L18P_T2_34 Sch=jb_p[3]
set_property -dict { PACKAGE_PIN W13   IOSTANDARD LVCMOS33     } [get_ports { pmodJC[7] }]; #IO_L4N_T0_34 Sch=jb_n[4]
set_property -dict { PACKAGE_PIN V12   IOSTANDARD LVCMOS33     } [get_ports { pmodJC[6] }]; #IO_L4P_T0_34 Sch=jb_p[4]
# set_property IOSTANDARD LVCMOS33 [get_ports {pmodJC[*]}]
set_property PULLUP true [get_ports {pmodJC[2]}]
set_property PULLUP true [get_ports {pmodJC[3]}]
set_property PULLUP true [get_ports {pmodJC[6]}]
set_property PULLUP true [get_ports {pmodJC[7]}]

##pmod Header JD - place holder
set_property -dict { PACKAGE_PIN T14   IOSTANDARD LVCMOS33 } [get_ports { pmodJD[0] }]; #IO_L5P_T0_34 Sch=ck_io[0]
set_property -dict { PACKAGE_PIN U12   IOSTANDARD LVCMOS33 } [get_ports { pmodJD[1] }]; #IO_L2N_T0_34 Sch=ck_io[1]
set_property -dict { PACKAGE_PIN U13   IOSTANDARD LVCMOS33 } [get_ports { pmodJD[2] }]; #IO_L3P_T0_DQS_PUDC_B_34 Sch=ck_io[2]
set_property -dict { PACKAGE_PIN V13   IOSTANDARD LVCMOS33 } [get_ports { pmodJD[3] }]; #IO_L3N_T0_DQS_34 Sch=ck_io[3]
set_property -dict { PACKAGE_PIN V15   IOSTANDARD LVCMOS33 } [get_ports { pmodJD[4] }]; #IO_L10P_T1_34 Sch=ck_io[4]
set_property -dict { PACKAGE_PIN T15   IOSTANDARD LVCMOS33 } [get_ports { pmodJD[5] }]; #IO_L5N_T0_34 Sch=ck_io[5]
set_property -dict { PACKAGE_PIN R16   IOSTANDARD LVCMOS33 } [get_ports { pmodJD[6] }]; #IO_L19P_T3_34 Sch=ck_io[6]
set_property -dict { PACKAGE_PIN U17   IOSTANDARD LVCMOS33 } [get_ports { pmodJD[7] }]; #IO_L9N_T1_DQS_34 Sch=ck_io[7]

