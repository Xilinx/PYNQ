# `xrfclk` Package

This is a package implementing the drivers to configure RF reference clocks
for the Xilinx Zynq RFSoC boards (e.g., ZCU111).

## Boards and Chips

For simple (safe) use, refer to `set_ref_clks()`.

For RFSoC experts, you can specify custom clock frequencies, assuming you
know what you're doing. In that case, you can leverage the following methods:

1. `set_lmk04208_clks()` for boards with LMK04208.
2. `set_lmk04832_clks()` for boards with LMK04832.
3. `set_lmx2594_clks()` for boards with LMX2594.

For example, checking ZCU111 schematic, you should be able to find that the
ZCU111 board has LMK04208 and LMX2594 chips. 

For other boards you may also need to adjust the I2C and SPI addresses 
specified in `src/xrfdc_clk.h`.

## Register Values

The register values in this package (stored in `*.txt`) are generated using
the [TICS Pro software](https://www.ti.com/tool/TICSPRO-SW).

Users can specify their own register values. To do this, simply put the
exported `*.txt` output from [TICS Pro software](https://www.ti.com/tool/TICSPRO-SW)
into the folder `xrfclk`. You may have noticed that there are already
a few `*.txt` files put in this folder. Just make sure to rename your own file
with the convention `<CHIPNAME>_<freq>.txt`.

For example, suppose you have enabled 100MHz clock on LMK04208. You can rename
the TICS Pro software output as `LMK04208_100.0.txt` and put it under folder
`xrfclk`. Then in your Python terminal or Jupyter cell, simply call

```python
from xrfclk import set_ref_clks
set_ref_clks(lmk_freq=100)
```

You can also see [this forum post](https://forums.xilinx.com/t5/Evaluation-Boards/How-to-setup-ZCU111-RFSoC-DAC-clock/td-p/896221)
for additional information on how to generate custom register values.

Copyright (C) 2021 Xilinx, Inc

SPDX-License-Identifier: BSD-3-Clause
