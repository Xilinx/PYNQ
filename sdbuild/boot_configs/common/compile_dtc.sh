cat system-top.dts <(echo '/include/ "board.dtsi"') | dtc -I dts -O dtb
