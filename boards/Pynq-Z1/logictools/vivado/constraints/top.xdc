#set_property -dict {PACKAGE_PIN R14 IOSTANDARD LVCMOS33} [get_ports LED[0]]
#set_property -dict {PACKAGE_PIN P14 IOSTANDARD LVCMOS33} [get_ports shield_gr_0_io[4]]

## Switches
#set_property -dict {PACKAGE_PIN M20 IOSTANDARD LVCMOS33} [get_ports {sw_input[0]}]
#set_property -dict {PACKAGE_PIN M19 IOSTANDARD LVCMOS33} [get_ports {sw_input[1]}]

##Buttons
set_property -dict {PACKAGE_PIN D19 IOSTANDARD LVCMOS33} [get_ports {pb_input[0]}]
set_property -dict {PACKAGE_PIN D20 IOSTANDARD LVCMOS33} [get_ports {pb_input[1]}]
set_property -dict {PACKAGE_PIN L20 IOSTANDARD LVCMOS33} [get_ports {pb_input[2]}]
set_property -dict {PACKAGE_PIN L19 IOSTANDARD LVCMOS33} [get_ports {pb_input[3]}]

##LEDs
set_property -dict {PACKAGE_PIN R14 IOSTANDARD LVCMOS33} [get_ports {LED[0]}]
set_property -dict {PACKAGE_PIN P14 IOSTANDARD LVCMOS33} [get_ports {LED[1]}]
set_property -dict {PACKAGE_PIN N16 IOSTANDARD LVCMOS33} [get_ports {LED[2]}]
set_property -dict {PACKAGE_PIN M14 IOSTANDARD LVCMOS33} [get_ports {LED[3]}]

##RGBLED1
#set_property -dict {PACKAGE_PIN G17 IOSTANDARD LVCMOS33} [get_ports {rgbled_0[0]}]
##RGBLED0
#set_property -dict {PACKAGE_PIN L14 IOSTANDARD LVCMOS33} [get_ports sig_debounced_out]

##Arduino shield digital io ar_shield
set_property -dict {PACKAGE_PIN T14 IOSTANDARD LVCMOS33 PULLUP true} [get_ports {ar_shield[0]}]
set_property -dict {PACKAGE_PIN U12 IOSTANDARD LVCMOS33 PULLUP true} [get_ports {ar_shield[1]}]
set_property -dict {PACKAGE_PIN U13 IOSTANDARD LVCMOS33 PULLUP true} [get_ports {ar_shield[2]}]
set_property -dict {PACKAGE_PIN V13 IOSTANDARD LVCMOS33 PULLUP true} [get_ports {ar_shield[3]}]
set_property -dict {PACKAGE_PIN V15 IOSTANDARD LVCMOS33 PULLUP true} [get_ports {ar_shield[4]}]

set_property -dict {PACKAGE_PIN T15 IOSTANDARD LVCMOS33 PULLUP true} [get_ports {ar_shield[5]}]
set_property -dict {PACKAGE_PIN R16 IOSTANDARD LVCMOS33 PULLUP true} [get_ports {ar_shield[6]}]
set_property -dict {PACKAGE_PIN U17 IOSTANDARD LVCMOS33 PULLUP true} [get_ports {ar_shield[7]}]
set_property -dict {PACKAGE_PIN V17 IOSTANDARD LVCMOS33 PULLUP true} [get_ports {ar_shield[8]}]
set_property -dict {PACKAGE_PIN V18 IOSTANDARD LVCMOS33 PULLUP true} [get_ports {ar_shield[9]}]

set_property -dict {PACKAGE_PIN T16 IOSTANDARD LVCMOS33 PULLUP true} [get_ports {ar_shield[10]}]
set_property -dict {PACKAGE_PIN R17 IOSTANDARD LVCMOS33 PULLUP true} [get_ports {ar_shield[11]}]
set_property -dict {PACKAGE_PIN P18 IOSTANDARD LVCMOS33 PULLUP true} [get_ports {ar_shield[12]}]
set_property -dict {PACKAGE_PIN N17 IOSTANDARD LVCMOS33 PULLUP true} [get_ports {ar_shield[13]}]
set_property -dict {PACKAGE_PIN Y11 IOSTANDARD LVCMOS33 PULLUP true} [get_ports {ar_shield[14]}]

set_property -dict {PACKAGE_PIN Y12 IOSTANDARD LVCMOS33 PULLUP true} [get_ports {ar_shield[15]}]
set_property -dict {PACKAGE_PIN W11 IOSTANDARD LVCMOS33 PULLUP true} [get_ports {ar_shield[16]}]
set_property -dict {PACKAGE_PIN V11 IOSTANDARD LVCMOS33 PULLUP true} [get_ports {ar_shield[17]}]
set_property -dict {PACKAGE_PIN T5 IOSTANDARD LVCMOS33 PULLUP true} [get_ports {ar_shield[18]}]
set_property -dict {PACKAGE_PIN U10 IOSTANDARD LVCMOS33 PULLUP true} [get_ports {ar_shield[19]}]

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

##pg_clk on Arduino SCL (left most pin of the top-row of header
set_property -dict {PACKAGE_PIN P16 IOSTANDARD LVCMOS33} [get_ports pg_clk]
