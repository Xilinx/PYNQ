## Switches
set_property -dict {PACKAGE_PIN M20 IOSTANDARD LVCMOS33} [get_ports {sws_2bits_tri_i[0]}]
set_property -dict {PACKAGE_PIN M19 IOSTANDARD LVCMOS33} [get_ports {sws_2bits_tri_i[1]}]

##Buttons
set_property -dict {PACKAGE_PIN D19 IOSTANDARD LVCMOS33} [get_ports {btns_4bits_tri_i[0]}]
set_property -dict {PACKAGE_PIN D20 IOSTANDARD LVCMOS33} [get_ports {btns_4bits_tri_i[1]}]
set_property -dict {PACKAGE_PIN L20 IOSTANDARD LVCMOS33} [get_ports {btns_4bits_tri_i[2]}]
set_property -dict {PACKAGE_PIN L19 IOSTANDARD LVCMOS33} [get_ports {btns_4bits_tri_i[3]}]

##LEDs
set_property -dict {PACKAGE_PIN R14 IOSTANDARD LVCMOS33} [get_ports {leds_4bits_tri_o[0]}]
set_property -dict {PACKAGE_PIN P14 IOSTANDARD LVCMOS33} [get_ports {leds_4bits_tri_o[1]}]
set_property -dict {PACKAGE_PIN N16 IOSTANDARD LVCMOS33} [get_ports {leds_4bits_tri_o[2]}]
set_property -dict {PACKAGE_PIN M14 IOSTANDARD LVCMOS33} [get_ports {leds_4bits_tri_o[3]}]

##RGBLEDs
set_property -dict { PACKAGE_PIN L15   IOSTANDARD LVCMOS33 } [get_ports { rgbleds_6bits_tri_o[0] }]; 
set_property -dict { PACKAGE_PIN G17   IOSTANDARD LVCMOS33 } [get_ports { rgbleds_6bits_tri_o[1] }]; 
set_property -dict { PACKAGE_PIN N15   IOSTANDARD LVCMOS33 } [get_ports { rgbleds_6bits_tri_o[2] }]; 
set_property -dict { PACKAGE_PIN G14   IOSTANDARD LVCMOS33 } [get_ports { rgbleds_6bits_tri_o[3] }];
set_property -dict { PACKAGE_PIN L14   IOSTANDARD LVCMOS33 } [get_ports { rgbleds_6bits_tri_o[4] }]; 
set_property -dict { PACKAGE_PIN M15   IOSTANDARD LVCMOS33 } [get_ports { rgbleds_6bits_tri_o[5] }]; 

## Audio signals
## MIC
set_property -dict {PACKAGE_PIN F17 IOSTANDARD LVCMOS33} [get_ports {pdm_m_clk[0]}]
set_property -dict {PACKAGE_PIN G18 IOSTANDARD LVCMOS33} [get_ports pdm_m_data_i]
## Mono Audio out
set_property -dict {PACKAGE_PIN R18 IOSTANDARD LVCMOS33} [get_ports {pwm_audio_o[0]}]
set_property -dict {PACKAGE_PIN T17 IOSTANDARD LVCMOS33} [get_ports {pdm_audio_shutdown[0]}]

#HDMI Signals
create_clock -period 8.334 -waveform {0.000 4.167} [get_ports hdmi_in_clk_p]
#create_clock -period 8.000 -waveform {0.000 4.000} [get_ports hdmi_in_clk_p]

#set_property -dict { PACKAGE_PIN G15   IOSTANDARD LVCMOS33 } [get_ports { hdmi_rx_cec }]; #IO_L19N_T3_VREF_35 Sch=hdmi_rx_cec
# Following pins are for HDMI RX on Rev B board
set_property -dict {PACKAGE_PIN P19 IOSTANDARD TMDS_33} [get_ports hdmi_in_clk_n]
set_property -dict {PACKAGE_PIN N18 IOSTANDARD TMDS_33} [get_ports hdmi_in_clk_p]
set_property -dict {PACKAGE_PIN W20 IOSTANDARD TMDS_33} [get_ports {hdmi_in_data_n[0]}]
set_property -dict {PACKAGE_PIN V20 IOSTANDARD TMDS_33} [get_ports {hdmi_in_data_p[0]}]
set_property -dict {PACKAGE_PIN U20 IOSTANDARD TMDS_33} [get_ports {hdmi_in_data_n[1]}]
set_property -dict {PACKAGE_PIN T20 IOSTANDARD TMDS_33} [get_ports {hdmi_in_data_p[1]}]
set_property -dict {PACKAGE_PIN P20 IOSTANDARD TMDS_33} [get_ports {hdmi_in_data_n[2]}]
set_property -dict {PACKAGE_PIN N20 IOSTANDARD TMDS_33} [get_ports {hdmi_in_data_p[2]}]
set_property -dict {PACKAGE_PIN T19 IOSTANDARD LVCMOS33} [get_ports {hdmi_in_hpd[0]}]
set_property -dict {PACKAGE_PIN U14 IOSTANDARD LVCMOS33} [get_ports hdmi_in_ddc_scl_io]
set_property -dict {PACKAGE_PIN U15 IOSTANDARD LVCMOS33} [get_ports hdmi_in_ddc_sda_io]

# Following pins are for HDMI RX on Rev A board
#set_property -dict {PACKAGE_PIN L17 IOSTANDARD TMDS_33} [get_ports hdmi_in_clk_n]
#set_property -dict {PACKAGE_PIN L16 IOSTANDARD TMDS_33} [get_ports hdmi_in_clk_p]
#set_property -dict {PACKAGE_PIN K18 IOSTANDARD TMDS_33} [get_ports {hdmi_in_data_n[0]}]
#set_property -dict {PACKAGE_PIN K17 IOSTANDARD TMDS_33} [get_ports {hdmi_in_data_p[0]}]
#set_property -dict {PACKAGE_PIN J19 IOSTANDARD TMDS_33} [get_ports {hdmi_in_data_n[1]}]
#set_property -dict {PACKAGE_PIN K19 IOSTANDARD TMDS_33} [get_ports {hdmi_in_data_p[1]}]
#set_property -dict {PACKAGE_PIN H18 IOSTANDARD TMDS_33} [get_ports {hdmi_in_data_n[2]}]
#set_property -dict {PACKAGE_PIN J18 IOSTANDARD TMDS_33} [get_ports {hdmi_in_data_p[2]}]
#set_property -dict {PACKAGE_PIN R19 IOSTANDARD LVCMOS33} [get_ports {hdmi_in_hpd[0]}]
#set_property -dict {PACKAGE_PIN M17 IOSTANDARD LVCMOS33} [get_ports hdmi_in_ddc_scl_io]
#set_property -dict {PACKAGE_PIN M18 IOSTANDARD LVCMOS33} [get_ports hdmi_in_ddc_sda_io]

#set_property -dict { PACKAGE_PIN H17   IOSTANDARD LVCMOS33 } [get_ports { hdmi_tx_cec }]; #IO_L13N_T2_MRCC_35 Sch=hdmi_tx_cec
# Following pins are for HDMI TX on Rev B board
set_property -dict {PACKAGE_PIN L17 IOSTANDARD TMDS_33} [get_ports hdmi_out_clk_n]
set_property -dict {PACKAGE_PIN L16 IOSTANDARD TMDS_33} [get_ports hdmi_out_clk_p]
set_property -dict {PACKAGE_PIN K18 IOSTANDARD TMDS_33} [get_ports {hdmi_out_data_n[0]}]
set_property -dict {PACKAGE_PIN K17 IOSTANDARD TMDS_33} [get_ports {hdmi_out_data_p[0]}]
set_property -dict {PACKAGE_PIN J19 IOSTANDARD TMDS_33} [get_ports {hdmi_out_data_n[1]}]
set_property -dict {PACKAGE_PIN K19 IOSTANDARD TMDS_33} [get_ports {hdmi_out_data_p[1]}]
set_property -dict {PACKAGE_PIN H18 IOSTANDARD TMDS_33} [get_ports {hdmi_out_data_n[2]}]
set_property -dict {PACKAGE_PIN J18 IOSTANDARD TMDS_33} [get_ports {hdmi_out_data_p[2]}]
set_property -dict {PACKAGE_PIN R19 IOSTANDARD LVCMOS33} [get_ports {hdmi_out_hpd[0]}]
set_property -dict {PACKAGE_PIN M17 IOSTANDARD LVCMOS33} [get_ports hdmi_out_ddc_scl_io]
set_property -dict {PACKAGE_PIN M18 IOSTANDARD LVCMOS33} [get_ports hdmi_out_ddc_sda_io]

# Following pins are for HDMI TX on Rev A board
#set_property -dict {PACKAGE_PIN P19 IOSTANDARD TMDS_33} [get_ports hdmi_out_clk_n]
#set_property -dict {PACKAGE_PIN N18 IOSTANDARD TMDS_33} [get_ports hdmi_out_clk_p]
#set_property -dict {PACKAGE_PIN W20 IOSTANDARD TMDS_33} [get_ports {hdmi_out_data_n[0]}]
#set_property -dict {PACKAGE_PIN V20 IOSTANDARD TMDS_33} [get_ports {hdmi_out_data_p[0]}]
#set_property -dict {PACKAGE_PIN U20 IOSTANDARD TMDS_33} [get_ports {hdmi_out_data_n[1]}]
#set_property -dict {PACKAGE_PIN T20 IOSTANDARD TMDS_33} [get_ports {hdmi_out_data_p[1]}]
#set_property -dict {PACKAGE_PIN P20 IOSTANDARD TMDS_33} [get_ports {hdmi_out_data_n[2]}]
#set_property -dict {PACKAGE_PIN N20 IOSTANDARD TMDS_33} [get_ports {hdmi_out_data_p[2]}]
#set_property -dict {PACKAGE_PIN T19 IOSTANDARD LVCMOS33} [get_ports {hdmi_out_hpd[0]}]
#set_property -dict {PACKAGE_PIN U14 IOSTANDARD LVCMOS33} [get_ports hdmi_out_ddc_scl_io]
#set_property -dict {PACKAGE_PIN U15 IOSTANDARD LVCMOS33} [get_ports hdmi_out_ddc_sda_io]

##pmod Header JA
set_property -dict {PACKAGE_PIN Y19 IOSTANDARD LVCMOS33} [get_ports {pmodJA[1]}]
set_property -dict {PACKAGE_PIN Y18 IOSTANDARD LVCMOS33} [get_ports {pmodJA[0]}]
set_property -dict {PACKAGE_PIN Y17 IOSTANDARD LVCMOS33} [get_ports {pmodJA[3]}]
set_property -dict {PACKAGE_PIN Y16 IOSTANDARD LVCMOS33} [get_ports {pmodJA[2]}]
set_property -dict {PACKAGE_PIN U19 IOSTANDARD LVCMOS33} [get_ports {pmodJA[5]}]
set_property -dict {PACKAGE_PIN U18 IOSTANDARD LVCMOS33} [get_ports {pmodJA[4]}]
set_property -dict {PACKAGE_PIN W19 IOSTANDARD LVCMOS33} [get_ports {pmodJA[7]}]
set_property -dict {PACKAGE_PIN W18 IOSTANDARD LVCMOS33} [get_ports {pmodJA[6]}]
set_property PULLUP true [get_ports {pmodJA[2]}]
set_property PULLUP true [get_ports {pmodJA[3]}]
set_property PULLUP true [get_ports {pmodJA[6]}]
set_property PULLUP true [get_ports {pmodJA[7]}]

##pmod Header JB
set_property -dict {PACKAGE_PIN Y14 IOSTANDARD LVCMOS33} [get_ports {pmodJB[1]}]
set_property -dict {PACKAGE_PIN W14 IOSTANDARD LVCMOS33} [get_ports {pmodJB[0]}]
set_property -dict {PACKAGE_PIN T10 IOSTANDARD LVCMOS33} [get_ports {pmodJB[3]}]
set_property -dict {PACKAGE_PIN T11 IOSTANDARD LVCMOS33} [get_ports {pmodJB[2]}]
set_property -dict {PACKAGE_PIN W16 IOSTANDARD LVCMOS33} [get_ports {pmodJB[5]}]
set_property -dict {PACKAGE_PIN V16 IOSTANDARD LVCMOS33} [get_ports {pmodJB[4]}]
set_property -dict {PACKAGE_PIN W13 IOSTANDARD LVCMOS33} [get_ports {pmodJB[7]}]
set_property -dict {PACKAGE_PIN V12 IOSTANDARD LVCMOS33} [get_ports {pmodJB[6]}]
set_property PULLUP true [get_ports {pmodJB[2]}]
set_property PULLUP true [get_ports {pmodJB[3]}]
set_property PULLUP true [get_ports {pmodJB[6]}]
set_property PULLUP true [get_ports {pmodJB[7]}]

##Arduino shield digital io
set_property -dict {PACKAGE_PIN T14 IOSTANDARD LVCMOS33} [get_ports {gpio_shield_sw_d1_d0_tri_io[0]}]
set_property -dict {PACKAGE_PIN U12 IOSTANDARD LVCMOS33} [get_ports {gpio_shield_sw_d1_d0_tri_io[1]}]
set_property -dict {PACKAGE_PIN U13 IOSTANDARD LVCMOS33} [get_ports {gpio_shield_sw_d13_d2_tri_io[0]}]
set_property -dict {PACKAGE_PIN V13 IOSTANDARD LVCMOS33} [get_ports {gpio_shield_sw_d13_d2_tri_io[1]}]
set_property -dict {PACKAGE_PIN V15 IOSTANDARD LVCMOS33} [get_ports {gpio_shield_sw_d13_d2_tri_io[2]}]
set_property -dict {PACKAGE_PIN T15 IOSTANDARD LVCMOS33} [get_ports {gpio_shield_sw_d13_d2_tri_io[3]}]
set_property -dict {PACKAGE_PIN R16 IOSTANDARD LVCMOS33} [get_ports {gpio_shield_sw_d13_d2_tri_io[4]}]
set_property -dict {PACKAGE_PIN U17 IOSTANDARD LVCMOS33} [get_ports {gpio_shield_sw_d13_d2_tri_io[5]}]
set_property -dict {PACKAGE_PIN V17 IOSTANDARD LVCMOS33} [get_ports {gpio_shield_sw_d13_d2_tri_io[6]}]
set_property -dict {PACKAGE_PIN V18 IOSTANDARD LVCMOS33} [get_ports {gpio_shield_sw_d13_d2_tri_io[7]}]
set_property -dict {PACKAGE_PIN T16 IOSTANDARD LVCMOS33} [get_ports {gpio_shield_sw_d13_d2_tri_io[8]}]
set_property -dict {PACKAGE_PIN R17 IOSTANDARD LVCMOS33} [get_ports {gpio_shield_sw_d13_d2_tri_io[9]}]
set_property -dict {PACKAGE_PIN P18 IOSTANDARD LVCMOS33} [get_ports {gpio_shield_sw_d13_d2_tri_io[10]}]
set_property -dict {PACKAGE_PIN N17 IOSTANDARD LVCMOS33} [get_ports {gpio_shield_sw_d13_d2_tri_io[11]}]
##Arduino shield dedicated I2C
set_property -dict {PACKAGE_PIN P16 IOSTANDARD LVCMOS33} [get_ports iic_sw_shield_scl_io]
set_property -dict {PACKAGE_PIN P15 IOSTANDARD LVCMOS33} [get_ports iic_sw_shield_sda_io]
##Arduino shield dedicated SPI
set_property -dict {PACKAGE_PIN W15 IOSTANDARD LVCMOS33} [get_ports spi_sw_shield_io1_io]
set_property -dict {PACKAGE_PIN T12 IOSTANDARD LVCMOS33} [get_ports spi_sw_shield_io0_io]
set_property -dict {PACKAGE_PIN H15 IOSTANDARD LVCMOS33} [get_ports spi_sw_shield_sck_io]
set_property -dict {PACKAGE_PIN F16 IOSTANDARD LVCMOS33} [get_ports spi_sw_shield_ss_io]
# Arduino Analog Channels 0 to 5
set_property -dict {PACKAGE_PIN D18 IOSTANDARD LVCMOS33} [get_ports Vaux1_v_n]
set_property -dict {PACKAGE_PIN E17 IOSTANDARD LVCMOS33} [get_ports Vaux1_v_p]
set_property -dict {PACKAGE_PIN E19 IOSTANDARD LVCMOS33} [get_ports Vaux9_v_n]
set_property -dict {PACKAGE_PIN E18 IOSTANDARD LVCMOS33} [get_ports Vaux9_v_p]
set_property -dict {PACKAGE_PIN J14 IOSTANDARD LVCMOS33} [get_ports Vaux6_v_n]
set_property -dict {PACKAGE_PIN K14 IOSTANDARD LVCMOS33} [get_ports Vaux6_v_p]
set_property -dict {PACKAGE_PIN J16 IOSTANDARD LVCMOS33} [get_ports Vaux15_v_n]
set_property -dict {PACKAGE_PIN K16 IOSTANDARD LVCMOS33} [get_ports Vaux15_v_p]
set_property -dict {PACKAGE_PIN H20 IOSTANDARD LVCMOS33} [get_ports Vaux5_v_n]
set_property -dict {PACKAGE_PIN J20 IOSTANDARD LVCMOS33} [get_ports Vaux5_v_p]
set_property -dict {PACKAGE_PIN G20 IOSTANDARD LVCMOS33} [get_ports Vaux13_v_n]
set_property -dict {PACKAGE_PIN G19 IOSTANDARD LVCMOS33} [get_ports Vaux13_v_p]

# a5..a0 as digital io for gpio_shield_sw_a5_a0_tri_io[5:0]
set_property -dict {PACKAGE_PIN U10 IOSTANDARD LVCMOS33} [get_ports {gpio_shield_sw_a5_a0_tri_io[5]}]
set_property -dict {PACKAGE_PIN T5 IOSTANDARD LVCMOS33} [get_ports {gpio_shield_sw_a5_a0_tri_io[4]}]
set_property -dict {PACKAGE_PIN V11 IOSTANDARD LVCMOS33} [get_ports {gpio_shield_sw_a5_a0_tri_io[3]}]
set_property -dict {PACKAGE_PIN W11 IOSTANDARD LVCMOS33} [get_ports {gpio_shield_sw_a5_a0_tri_io[2]}]
set_property -dict {PACKAGE_PIN Y12 IOSTANDARD LVCMOS33} [get_ports {gpio_shield_sw_a5_a0_tri_io[1]}]
set_property -dict {PACKAGE_PIN Y11 IOSTANDARD LVCMOS33} [get_ports {gpio_shield_sw_a5_a0_tri_io[0]}]
##Arduino shield shared I2C related pullup
set_property PULLUP true [get_ports {gpio_shield_sw_a5_a0_tri_io[5]}]
set_property PULLUP true [get_ports {gpio_shield_sw_a5_a0_tri_io[4]}]

