# `xrfclk` Package

This is a package implementing the drivers to configure RF reference clocks
for the Xilinx Zynq RFSoC boards (e.g., ZCU111).


## Instructions
The LMKxxxxx and LMXxxxx clocking configurations are set via the `set_ref_clks()` command:
```python
from xrfclk import set_ref_clks
set_ref_clks(lmk_freq=122.88, lmx_freq=409.6)
```

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
