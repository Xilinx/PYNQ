
##Buttons
set_property -dict {PACKAGE_PIN D19 IOSTANDARD LVCMOS33} [get_ports {pb_input[0]}]
set_property -dict {PACKAGE_PIN D20 IOSTANDARD LVCMOS33} [get_ports {pb_input[1]}]
set_property -dict {PACKAGE_PIN L20 IOSTANDARD LVCMOS33} [get_ports {pb_input[2]}]
set_property -dict {PACKAGE_PIN L19 IOSTANDARD LVCMOS33} [get_ports {pb_input[3]}]

##LEDs
set_property -dict {PACKAGE_PIN R14 IOSTANDARD LVCMOS33} [get_ports {led[0]}]
set_property -dict {PACKAGE_PIN P14 IOSTANDARD LVCMOS33} [get_ports {led[1]}]
set_property -dict {PACKAGE_PIN N16 IOSTANDARD LVCMOS33} [get_ports {led[2]}]
set_property -dict {PACKAGE_PIN M14 IOSTANDARD LVCMOS33} [get_ports {led[3]}]

##Arduino shield digital io ar_shield
set_property -dict {PACKAGE_PIN T14 IOSTANDARD LVCMOS33} [get_ports {ar_shield[0]}]
set_property -dict {PACKAGE_PIN U12 IOSTANDARD LVCMOS33} [get_ports {ar_shield[1]}]
set_property -dict {PACKAGE_PIN U13 IOSTANDARD LVCMOS33} [get_ports {ar_shield[2]}]
set_property -dict {PACKAGE_PIN V13 IOSTANDARD LVCMOS33} [get_ports {ar_shield[3]}]
set_property -dict {PACKAGE_PIN V15 IOSTANDARD LVCMOS33} [get_ports {ar_shield[4]}]

set_property -dict {PACKAGE_PIN T15 IOSTANDARD LVCMOS33} [get_ports {ar_shield[5]}]
set_property -dict {PACKAGE_PIN R16 IOSTANDARD LVCMOS33} [get_ports {ar_shield[6]}]
set_property -dict {PACKAGE_PIN U17 IOSTANDARD LVCMOS33} [get_ports {ar_shield[7]}]
set_property -dict {PACKAGE_PIN V17 IOSTANDARD LVCMOS33} [get_ports {ar_shield[8]}]
set_property -dict {PACKAGE_PIN V18 IOSTANDARD LVCMOS33} [get_ports {ar_shield[9]}]

set_property -dict {PACKAGE_PIN T16 IOSTANDARD LVCMOS33} [get_ports {ar_shield[10]}]
set_property -dict {PACKAGE_PIN R17 IOSTANDARD LVCMOS33} [get_ports {ar_shield[11]}]
set_property -dict {PACKAGE_PIN P18 IOSTANDARD LVCMOS33} [get_ports {ar_shield[12]}]
set_property -dict {PACKAGE_PIN N17 IOSTANDARD LVCMOS33} [get_ports {ar_shield[13]}]
set_property -dict {PACKAGE_PIN Y11 IOSTANDARD LVCMOS33} [get_ports {ar_shield[14]}]

set_property -dict {PACKAGE_PIN Y12 IOSTANDARD LVCMOS33} [get_ports {ar_shield[15]}]
set_property -dict {PACKAGE_PIN W11 IOSTANDARD LVCMOS33} [get_ports {ar_shield[16]}]
set_property -dict {PACKAGE_PIN V11 IOSTANDARD LVCMOS33} [get_ports {ar_shield[17]}]
set_property -dict {PACKAGE_PIN T5 IOSTANDARD LVCMOS33} [get_ports {ar_shield[18]}]
set_property -dict {PACKAGE_PIN U10 IOSTANDARD LVCMOS33} [get_ports {ar_shield[19]}]
set_property PULLUP true [get_ports {ar_shield[*]}] 

##pmod Header JA
##set_property -dict {PACKAGE_PIN Y19 IOSTANDARD LVCMOS33} [get_ports {pmodJA[1]}]
##set_property -dict {PACKAGE_PIN Y18 IOSTANDARD LVCMOS33} [get_ports {pmodJA[0]}]
##set_property -dict {PACKAGE_PIN Y17 IOSTANDARD LVCMOS33} [get_ports {pmodJA[3]}]
##set_property -dict {PACKAGE_PIN Y16 IOSTANDARD LVCMOS33} [get_ports {pmodJA[2]}]
##set_property -dict {PACKAGE_PIN U19 IOSTANDARD LVCMOS33} [get_ports {pmodJA[5]}]
##set_property -dict {PACKAGE_PIN U18 IOSTANDARD LVCMOS33} [get_ports {pmodJA[4]}]
##set_property -dict {PACKAGE_PIN W19 IOSTANDARD LVCMOS33} [get_ports {pmodJA[7]}]
##set_property -dict {PACKAGE_PIN W18 IOSTANDARD LVCMOS33} [get_ports {pmodJA[6]}]
##set_property PULLUP true [get_ports {pmodJA[2]}]
##set_property PULLUP true [get_ports {pmodJA[3]}]
##set_property PULLUP true [get_ports {pmodJA[6]}]
##set_property PULLUP true [get_ports {pmodJA[7]}]

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
set_property -dict {PACKAGE_PIN P16 IOSTANDARD LVCMOS33} [get_ports ar_pg_clk]

## Raspberry PI signals - 
##  RPI_IDE Pin#   |   RP Connector  | Schematic Name | Dual Functionality
##        1        |      3v3        |     NA
##        3        |      GPIO2      |     JA4_P      |    I2C1_SDA
##        5        |      GPIO3      |     JA4_N      |    I2C1_SCL
##        7        |      GPIO4      |     JA1_P      |    GCLK0
##        9        |      GROUND     |     NA
##        11       |      GPIO17     |     RP_IO17_R
##        13       |      GPIO27     |     RP_IO27_R
##        15       |      GPIO22     |     RP_IO22_R
##        17       |      3v3        |     NA
##        19       |      GPIO10     |     RP_IO10_R   |    SPIO0_MOSI
##        21       |      GPIO9      |     RP_IO09_R   |    SPIO0_MISO
##        23       |      GPIO11     |     RP_IO11_R   |    SPIO0_SCLK
##        25       |      GROUND     |     NA
##        27       |      GPIO0      |     JA2_P       |    I2C0_SDA ID EEPROM
##        29       |      GPIO5      |     JA1_N       |    GCLK1
##        31       |      GPIO6      |     JA3_P       |    GCLK2
##        33       |      GPIO13     |     RP_IO13_R   |    PWM1
##        35       |      GPIO19     |     RP_IO19_R   |    SPIO1_MISO
##        37       |      GPIO26     |     RP_IO26_R
##        39       |      GROUND     |     NA

##        2        |      5V         |     NA
##        4        |      5V         |     NA
##        6        |      GROUND     |     NA
##        8        |      GPIO14     |     RP_IO14_R   |    UART0_TXD
##        10       |      GPIO15     |     RP_IO15_R   |    UART0_RXD
##        12       |      GPIO18     |     RP_IO18_R   |    PCM_CLK
##        14       |      GROUND     |     NA
##        16       |      GPIO23     |     RP_IO23_R
##        18       |      GPIO24     |     RP_IO24_R 
##        20       |      GROUND     |     NA
##        22       |      GPIO25     |     RP_IO25_R
##        24       |      GPIO8      |     RP_IO08_R   |    SPIO0_CE0_N
##        26       |      GPIO7      |     JA3_N       |    SPIO0_CE1_N
##        28       |      GPIO1      |     JA2_N       |    I2C0_SDC ID EEPROM
##        30       |      GROUND     |     NA
##        32       |      GPIO12     |     RP_IO12_R   |    PWM0
##        34       |      GROUND     |     NA
##        36       |      GPIO16     |     RP_IO16_R   |    SPIO1_CE2_N
##        38       |      GPIO20     |     RP_IO20_R   |    SPIO1_MOSI
##        40       |      GPIO21     |     RP_IO21_R   |    SPIO1_SCLK

set_property -dict { PACKAGE_PIN Y16   IOSTANDARD LVCMOS33 } [get_ports { rp_gpio[0] }];   
set_property -dict { PACKAGE_PIN Y17   IOSTANDARD LVCMOS33 } [get_ports { rp_gpio[1] }];   
set_property -dict { PACKAGE_PIN W18   IOSTANDARD LVCMOS33 } [get_ports { rp_gpio[2] }];   
set_property -dict { PACKAGE_PIN W19   IOSTANDARD LVCMOS33 } [get_ports { rp_gpio[3] }];   
set_property -dict { PACKAGE_PIN Y18   IOSTANDARD LVCMOS33 } [get_ports { rp_gpio[4] }];   
set_property -dict { PACKAGE_PIN Y19   IOSTANDARD LVCMOS33 } [get_ports { rp_gpio[5] }];   
set_property -dict { PACKAGE_PIN U18   IOSTANDARD LVCMOS33 } [get_ports { rp_gpio[6] }];   
set_property -dict { PACKAGE_PIN U19   IOSTANDARD LVCMOS33 } [get_ports { rp_gpio[7] }];   

set_property -dict { PACKAGE_PIN F19   IOSTANDARD LVCMOS33 } [get_ports { rp_gpio[8] }];   
set_property -dict { PACKAGE_PIN V10   IOSTANDARD LVCMOS33 } [get_ports { rp_gpio[9] }];   
set_property -dict { PACKAGE_PIN V8    IOSTANDARD LVCMOS33 } [get_ports { rp_gpio[10] }];  
set_property -dict { PACKAGE_PIN W10   IOSTANDARD LVCMOS33 } [get_ports { rp_gpio[11] }];   
set_property -dict { PACKAGE_PIN B20   IOSTANDARD LVCMOS33 } [get_ports { rp_gpio[12] }];   
set_property -dict { PACKAGE_PIN W8    IOSTANDARD LVCMOS33 } [get_ports { rp_gpio[13] }];   
set_property -dict { PACKAGE_PIN V6    IOSTANDARD LVCMOS33 } [get_ports { rp_gpio[14] }];   
set_property -dict { PACKAGE_PIN Y6    IOSTANDARD LVCMOS33 } [get_ports { rp_gpio[15] }];  
set_property -dict { PACKAGE_PIN B19   IOSTANDARD LVCMOS33 } [get_ports { rp_gpio[16] }];   
set_property -dict { PACKAGE_PIN U7    IOSTANDARD LVCMOS33 } [get_ports { rp_gpio[17] }];   
set_property -dict { PACKAGE_PIN C20   IOSTANDARD LVCMOS33 } [get_ports { rp_gpio[18] }];   
set_property -dict { PACKAGE_PIN Y8    IOSTANDARD LVCMOS33 } [get_ports { rp_gpio[19] }];   
set_property -dict { PACKAGE_PIN A20   IOSTANDARD LVCMOS33 } [get_ports { rp_gpio[20] }];   
set_property -dict { PACKAGE_PIN Y9    IOSTANDARD LVCMOS33 } [get_ports { rp_gpio[21] }];   
set_property -dict { PACKAGE_PIN U8    IOSTANDARD LVCMOS33 } [get_ports { rp_gpio[22] }];   
set_property -dict { PACKAGE_PIN W6    IOSTANDARD LVCMOS33 } [get_ports { rp_gpio[23] }];   
set_property -dict { PACKAGE_PIN Y7    IOSTANDARD LVCMOS33 } [get_ports { rp_gpio[24] }];   
set_property -dict { PACKAGE_PIN F20   IOSTANDARD LVCMOS33 } [get_ports { rp_gpio[25] }];   


#set_property -dict { PACKAGE_PIN W9    IOSTANDARD LVCMOS33 } [get_ports { rp_gpio[26] }]; 
set_property PULLUP true [get_ports {rp_gpio[*]}]

#set_property -dict { PACKAGE_PIN V7    IOSTANDARD LVCMOS33 } [get_ports { rp_gpio[27] }]; 
set_property -dict { PACKAGE_PIN V7    IOSTANDARD LVCMOS33 } [get_ports { rp_pg_clk }];   

set_false_path -through [get_pins { system_i/debounced_pb/debounce_pb_*/inst/DB_PB_out_reg/* } ]
