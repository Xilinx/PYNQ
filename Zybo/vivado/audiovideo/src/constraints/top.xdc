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
#set_property PULLUP true [get_ports {pmodJB[*]}]
set_property PULLUP true [get_ports {pmodJB[2]}]
set_property PULLUP true [get_ports {pmodJB[3]}]
set_property PULLUP true [get_ports {pmodJB[6]}]
set_property PULLUP true [get_ports {pmodJB[7]}]

# Audio Related constraints
set_property PACKAGE_PIN K18 [get_ports BCLK]
set_property IOSTANDARD LVCMOS33 [get_ports BCLK]
set_property PACKAGE_PIN L17 [get_ports PBLRCLK]
set_property IOSTANDARD LVCMOS33 [get_ports PBLRCLK]
set_property PACKAGE_PIN M18 [get_ports RECLRCLK]
set_property IOSTANDARD LVCMOS33 [get_ports RECLRCLK]
set_property PACKAGE_PIN K17 [get_ports RECDAT]
set_property IOSTANDARD LVCMOS33 [get_ports RECDAT]
set_property PACKAGE_PIN M17 [get_ports PBDATA]
set_property IOSTANDARD LVCMOS33 [get_ports PBDATA]

#GPIO[0] output
set_property PACKAGE_PIN P18 [get_ports {codec_out[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {codec_out[0]}]

#MCLK
set_property PACKAGE_PIN T19 [get_ports FCLK_CLK3]
set_property IOSTANDARD LVCMOS33 [get_ports FCLK_CLK3]

#I2C 1 interface for audio codec
set_property PACKAGE_PIN N18 [get_ports iic_1_scl_io]
set_property IOSTANDARD LVCMOS33 [get_ports iic_1_scl_io]

#I2C 1 interface for audio codec
set_property PACKAGE_PIN N17 [get_ports iic_1_sda_io]
set_property IOSTANDARD LVCMOS33 [get_ports iic_1_sda_io]

#HDMI Signals
set_property IOSTANDARD TMDS_33 [get_ports TMDS_clk_n]
set_property PACKAGE_PIN H16 [get_ports TMDS_clk_p]
set_property IOSTANDARD TMDS_33 [get_ports TMDS_clk_p]
create_clock -period 8.334 -waveform {0.000 4.167} [get_ports TMDS_clk_p]
set_property IOSTANDARD TMDS_33 [get_ports {TMDS_data_n[0]}]
set_property PACKAGE_PIN D19 [get_ports {TMDS_data_p[0]}]
set_property IOSTANDARD TMDS_33 [get_ports {TMDS_data_p[0]}]
set_property IOSTANDARD TMDS_33 [get_ports {TMDS_data_n[1]}]
set_property PACKAGE_PIN C20 [get_ports {TMDS_data_p[1]}]
set_property IOSTANDARD TMDS_33 [get_ports {TMDS_data_p[1]}]
set_property IOSTANDARD TMDS_33 [get_ports {TMDS_data_n[2]}]
set_property PACKAGE_PIN B19 [get_ports {TMDS_data_p[2]}]
set_property IOSTANDARD TMDS_33 [get_ports {TMDS_data_p[2]}]

set_property PACKAGE_PIN E18 [get_ports {hdmi_hpd_tri_o[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {hdmi_hpd_tri_o[0]}]

#VGA Connector
set_property PACKAGE_PIN M19 [get_ports {vga_r[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {vga_r[0]}]
set_property PACKAGE_PIN L20 [get_ports {vga_r[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {vga_r[1]}]
set_property PACKAGE_PIN J20 [get_ports {vga_r[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {vga_r[2]}]
set_property PACKAGE_PIN G20 [get_ports {vga_r[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {vga_r[3]}]
set_property PACKAGE_PIN F19 [get_ports {vga_r[4]}]
set_property IOSTANDARD LVCMOS33 [get_ports {vga_r[4]}]

set_property PACKAGE_PIN H18 [get_ports {vga_g[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {vga_g[0]}]
set_property PACKAGE_PIN N20 [get_ports {vga_g[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {vga_g[1]}]
set_property PACKAGE_PIN L19 [get_ports {vga_g[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {vga_g[2]}]
set_property PACKAGE_PIN J19 [get_ports {vga_g[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {vga_g[3]}]
set_property PACKAGE_PIN H20 [get_ports {vga_g[4]}]
set_property IOSTANDARD LVCMOS33 [get_ports {vga_g[4]}]
set_property PACKAGE_PIN F20 [get_ports {vga_g[5]}]
set_property IOSTANDARD LVCMOS33 [get_ports {vga_g[5]}]

set_property PACKAGE_PIN P20 [get_ports {vga_b[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {vga_b[0]}]
set_property PACKAGE_PIN M20 [get_ports {vga_b[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {vga_b[1]}]
set_property PACKAGE_PIN K19 [get_ports {vga_b[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {vga_b[2]}]
set_property PACKAGE_PIN J18 [get_ports {vga_b[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {vga_b[3]}]
set_property PACKAGE_PIN G19 [get_ports {vga_b[4]}]
set_property IOSTANDARD LVCMOS33 [get_ports {vga_b[4]}]

set_property PACKAGE_PIN P19 [get_ports vga_hs]
set_property IOSTANDARD LVCMOS33 [get_ports vga_hs]
set_property PACKAGE_PIN R19 [get_ports vga_vs]
set_property IOSTANDARD LVCMOS33 [get_ports vga_vs]

set_property PACKAGE_PIN F17 [get_ports {HDMI_OEN[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {HDMI_OEN[0]}]

set_property PACKAGE_PIN G17 [get_ports ddc_scl_io]
set_property PACKAGE_PIN G18 [get_ports ddc_sda_io]
set_property IOSTANDARD LVCMOS33 [get_ports ddc_scl_io]
set_property IOSTANDARD LVCMOS33 [get_ports ddc_sda_io]
