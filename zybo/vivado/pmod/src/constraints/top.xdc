##Switches
set_property PACKAGE_PIN G15 [get_ports {sws_4bits_tri_i[0]}]
set_property PACKAGE_PIN P15 [get_ports {sws_4bits_tri_i[1]}]
set_property PACKAGE_PIN W13 [get_ports {sws_4bits_tri_i[2]}]
set_property PACKAGE_PIN T16 [get_ports {sws_4bits_tri_i[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {sws_4bits_tri_i[*]}]

##Buttons
set_property PACKAGE_PIN R18 [get_ports {btns_4bits_tri_i[0]}]
set_property PACKAGE_PIN P16 [get_ports {btns_4bits_tri_i[1]}]
set_property PACKAGE_PIN V16 [get_ports {btns_4bits_tri_i[2]}]
set_property PACKAGE_PIN Y16 [get_ports {btns_4bits_tri_i[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {btns_4bits_tri_i[*]}]

##LEDs
set_property PACKAGE_PIN M14 [get_ports {leds_4bits_tri_o[0]}]
set_property PACKAGE_PIN M15 [get_ports {leds_4bits_tri_o[1]}]
set_property PACKAGE_PIN G14 [get_ports {leds_4bits_tri_o[2]}]
set_property PACKAGE_PIN D18 [get_ports {leds_4bits_tri_o[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {leds_4bits_tri_o[*]}]

##pmod Header JB
set_property PACKAGE_PIN T20 [get_ports {pmodJB[0]}]
set_property PACKAGE_PIN U20 [get_ports {pmodJB[1]}]
set_property PACKAGE_PIN V20 [get_ports {pmodJB[2]}]
set_property PACKAGE_PIN W20 [get_ports {pmodJB[3]}]
set_property PACKAGE_PIN Y18 [get_ports {pmodJB[4]}]
set_property PACKAGE_PIN Y19 [get_ports {pmodJB[5]}]
set_property PACKAGE_PIN W18 [get_ports {pmodJB[6]}]
set_property PACKAGE_PIN W19 [get_ports {pmodJB[7]}]
set_property IOSTANDARD LVCMOS33 [get_ports {pmodJB[*]}]
set_property PULLUP true [get_ports {pmodJB[*]}]

##pmod Header JC
set_property PACKAGE_PIN V15 [get_ports {pmodJC[0]}]
set_property PACKAGE_PIN W15 [get_ports {pmodJC[1]}]
set_property PACKAGE_PIN T11 [get_ports {pmodJC[2]}]
set_property PACKAGE_PIN T10 [get_ports {pmodJC[3]}]
set_property PACKAGE_PIN W14 [get_ports {pmodJC[4]}]
set_property PACKAGE_PIN Y14 [get_ports {pmodJC[5]}]
set_property PACKAGE_PIN T12 [get_ports {pmodJC[6]}]
set_property PACKAGE_PIN U12 [get_ports {pmodJC[7]}]
set_property IOSTANDARD LVCMOS33 [get_ports {pmodJC[*]}]
set_property PULLUP true [get_ports {pmodJC[*]}]

##pmod Header JD
set_property PACKAGE_PIN T14 [get_ports {pmodJD[0]}]
set_property PACKAGE_PIN T15 [get_ports {pmodJD[1]}]
set_property PACKAGE_PIN P14 [get_ports {pmodJD[2]}]
set_property PACKAGE_PIN R14 [get_ports {pmodJD[3]}]
set_property PACKAGE_PIN U14 [get_ports {pmodJD[4]}]
set_property PACKAGE_PIN U15 [get_ports {pmodJD[5]}]
set_property PACKAGE_PIN V17 [get_ports {pmodJD[6]}]
set_property PACKAGE_PIN V18 [get_ports {pmodJD[7]}]
set_property IOSTANDARD LVCMOS33 [get_ports {pmodJD[*]}]
set_property PULLUP true [get_ports {pmodJD[*]}]

##pmod Header JE
set_property PACKAGE_PIN V12 [get_ports {pmodJE[0]}]
set_property PACKAGE_PIN W16 [get_ports {pmodJE[1]}]
set_property PACKAGE_PIN J15 [get_ports {pmodJE[2]}]
set_property PACKAGE_PIN H15 [get_ports {pmodJE[3]}]
set_property PACKAGE_PIN V13 [get_ports {pmodJE[4]}]
set_property PACKAGE_PIN U17 [get_ports {pmodJE[5]}]
set_property PACKAGE_PIN T17 [get_ports {pmodJE[6]}]
set_property PACKAGE_PIN Y17 [get_ports {pmodJE[7]}]
set_property IOSTANDARD LVCMOS33 [get_ports {pmodJE[*]}]
set_property PULLUP true [get_ports {pmodJE[*]}]

##Pmod Header JA (XADC)
##IO_L21N_T3_DQS_AD14N_35
set_property PACKAGE_PIN N16 [get_ports {pmodJA1_n}]
set_property IOSTANDARD LVCMOS33 [get_ports {pmodJA1_n}]

##IO_L21P_T3_DQS_AD14P_35
set_property PACKAGE_PIN N15 [get_ports {pmodJA1_p}]
set_property IOSTANDARD LVCMOS33 [get_ports {pmodJA1_p}]

##IO_L22N_T3_AD7N_35
set_property PACKAGE_PIN L15 [get_ports {pmodJA2_n}]
set_property IOSTANDARD LVCMOS33 [get_ports {pmodJA2_n}]

##IO_L22P_T3_AD7P_35
set_property PACKAGE_PIN L14 [get_ports {pmodJA2_p}]
set_property IOSTANDARD LVCMOS33 [get_ports {pmodJA2_p}]

##IO_L24N_T3_AD15N_35
set_property PACKAGE_PIN J16 [get_ports {pmodJA3_n}]
set_property IOSTANDARD LVCMOS33 [get_ports {pmodJA3_n}]

##IO_L24P_T3_AD15P_35
set_property PACKAGE_PIN K16 [get_ports {pmodJA3_p}]
set_property IOSTANDARD LVCMOS33 [get_ports {pmodJA3_p}]

##IO_L20N_T3_AD6N_35
set_property PACKAGE_PIN J14 [get_ports {pmodJA4_n}]
set_property IOSTANDARD LVCMOS33 [get_ports {pmodJA4_n}]

##IO_L20P_T3_AD6P_35
set_property PACKAGE_PIN K14 [get_ports {pmodJA4_p}]
set_property IOSTANDARD LVCMOS33 [get_ports {pmodJA4_p}]

create_property BMM_INFO_PROCESSOR cell -type string
create_property BMM_INFO_ADDRESS_SPACE cell -type string
set_property BMM_INFO_PROCESSOR {microblaze-le > system mb_JB/mb1_lmb/lmb_bram_if_cntlr} [get_cells system_i/mb_JB/mb_1]
set_property BMM_INFO_ADDRESS_SPACE {byte 0x0 32 > system mb_JB/mb1_lmb/lmb_bram} [get_cells system_i/mb_JB/mb1_lmb/lmb_bram_if_cntlr]
set_property BMM_INFO_PROCESSOR {microblaze-le > system mb_JC/mb2_lmb/lmb_bram_if_cntlr} [get_cells system_i/mb_JC/mb_2]
set_property BMM_INFO_ADDRESS_SPACE {byte 0x0 32 > system mb_JC/mb2_lmb/lmb_bram} [get_cells system_i/mb_JC/mb2_lmb/lmb_bram_if_cntlr]
set_property BMM_INFO_PROCESSOR {microblaze-le > system mb_JD/mb3_lmb/lmb_bram_if_cntlr} [get_cells system_i/mb_JD/mb_3]
set_property BMM_INFO_ADDRESS_SPACE {byte 0x0 32 > system mb_JD/mb3_lmb/lmb_bram} [get_cells system_i/mb_JD/mb3_lmb/lmb_bram_if_cntlr]
set_property BMM_INFO_PROCESSOR {microblaze-le > system mb_JE/mb4_lmb/lmb_bram_if_cntlr} [get_cells system_i/mb_JE/mb_4]
set_property BMM_INFO_ADDRESS_SPACE {byte 0x0 32 > system mb_JE/mb4_lmb/lmb_bram} [get_cells system_i/mb_JE/mb4_lmb/lmb_bram_if_cntlr]


