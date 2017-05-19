cat system.dts <(echo '/include/ "board.dtsi"') | dtc -I dts -O dtb
