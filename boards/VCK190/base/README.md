# VCK190 base overlay

A deliberately small PL design — LEDs, push buttons, DIP switches, a BRAM, an AXI
DMA with a stream loopback, a UART and two timers — that runs on a PYNQ VCK190
image.

Its second job is to be a worked example of an overlay that satisfies the golden
reference boundary. To build your own design, copy this directory and replace the
PL logic; the rules it has to obey are in
[`../golden/README.md`](../golden/README.md).

## What is in it

| IP | Address | Purpose |
|---|---|---|
| `axi_bram_ctrl_0` | `0xA400_0000` | 8 KB BRAM |
| `axi_dma_0` | `0xA600_0000` | AXI DMA, MM2S looped back to S2MM through a stream FIFO |
| `axi_gpio_dip_sw` | `0xA601_0000` | 4 DIP switches |
| `axi_gpio_led` | `0xA602_0000` | 4 LEDs |
| `axi_gpio_pb` | `0xA603_0000` | 4 push buttons |
| `axi_intc_0` | `0xA604_0000` | Interrupt controller |
| `axi_uartlite_0` | `0xA605_0000` | UART |
| `axi_timer_0` | `0xA606_0000` | Timer |
| `axi_timer_1` | `0xA607_0000` | Timer |

Everything is clocked by `pl0_ref_clk` at 100 MHz and reset by `rst_pl0`. Golden
also brings out 200, 300 and 333.33 MHz clocks with their own resets, which this
design does not use.

## Interrupts

Seven sources reach the PS on the single interrupt line golden exposes. They are
concatenated into `axi_intc_0`, whose output drives `pl_ps_irq0`:

| Index | Source |
|---|---|
| 0 | `axi_dma_0/mm2s_introut` |
| 1 | `axi_dma_0/s2mm_introut` |
| 2 | `axi_gpio_dip_sw/ip2intc_irpt` |
| 3 | `axi_gpio_pb/ip2intc_irpt` |
| 4 | `axi_uartlite_0/interrupt` |
| 5 | `axi_timer_0/interrupt` |
| 6 | `axi_timer_1/interrupt` |

PYNQ discovers this from the metadata, so each source is reachable by name:

```python
await base.axi_timer_0.interrupt.wait()
```

## Build

```bash
make
```

This produces `base.pdi` (load this at runtime), `base.hwh` and `base.xsa`, then
runs the timing and compatibility checks. It needs Vivado 2025.2, which ships the
VCK190 board files.

`base.tcl` is a Vivado `write_bd_tcl` export and is not hand-edited. The block
design is named `vck190_pynq`, which is required for the NoC solution to lock —
see the golden README.

The build needs golden's artifacts. If `../golden/golden_noc.ncr` is missing the
Makefile builds golden first, which is fine when you are bringing up a new image
but wrong if you are targeting an image that already exists: a rebuilt golden
produces a new `BOOT.BIN` and the PLM will reject overlays built against it.

## Use from PYNQ

```python
from pynq.overlays.base import BaseOverlay
base = BaseOverlay("base.pdi")

base.leds[0].on()
base.buttons[0].read()
base.switches[0].read()
```

`base.dma` is the AXI DMA; because MM2S is looped back into S2MM through a FIFO,
a buffer sent on `sendchannel` comes back on `recvchannel`, which makes it a
useful end-to-end check of the PL-to-DDR path.
