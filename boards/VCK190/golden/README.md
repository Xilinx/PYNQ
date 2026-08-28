# VCK190 golden reference design

The golden reference is the processor half of every VCK190 PYNQ design. It
contains the CIPS block, the two NoC instances, the DDR memory controller, the
PL clocks and resets, and tie-offs on every port that faces the programmable
logic. It contains no user logic of its own.

The VCK190 image boots from this design. Every overlay loaded on that image has
to plug into the same processor boundary.

## Segmented configuration

The VCK190 uses segmented configuration. The device is configured in two stages:

- `boot.pdi` brings up the processors, the NoC and DDR. Linux boots from it
  before the programmable logic exists. It is written to the SD card as part of
  `BOOT.BIN` and does not change unless the image is rebuilt.
- `pld.pdi` configures the fabric afterwards and can be reloaded at runtime.
  This is what PYNQ writes every time you construct an `Overlay`.

Because the processor part is already running from `boot.pdi`, an overlay cannot
redefine it. The PLM compares an identifier in the PL image against the running
boot image and refuses a mismatch:

```
Image is not compatible with Parent Image
PLM Error Status: 0x03530000
```

## Build outputs

| File | Purpose |
|---|---|
| `golden.xsa` | Input to sdbuild's EDF flow, which generates `BOOT.BIN`. |
| `golden_boot.pdi` | The boot image itself (PS, NoC, DDR). |
| `golden_noc.ncr` | The solved NoC routing. Overlays lock their implementation run to it so the boot-image NoC paths come out identical. |
| `golden_routed.dcp` | Reference for `pr_verify`, which compares an overlay's implemented boundary against golden's. |

These files are not distributed with PYNQ. Build golden before building any
overlay for the VCK190.

## Overlay rules

The following are fixed by the boot image:

- The block design name, `vck190_pynq`. The NoC solution records instance
  paths that include it, so a renamed design cannot lock to `golden_noc.ncr`.
- The `versal_cips_0` configuration.
- `axi_noc_ps` and its DDR paths.
- The number and type of `axi_noc_pl` slave ports.
- The four PL reference clocks and their frequencies.
- The four fabric resets, `rst_pl0` to `rst_pl3`.
- One PL-to-PS interrupt, `pl_ps_irq0`.
- The PS-PL address apertures.

Use a subset of this boundary, never a superset. Leaving a clock, reset or NoC
port unused is fine. Adding a PS-PL connection that golden does not have is not,
because there is nothing in the boot image for it to connect to.

Do not reconfigure `versal_cips_0`, `axi_noc_ps` or `axi_noc_pl` in an overlay.
Everything an overlay needs is reachable without changing them.

## PL clocks

Four clocks are brought out so a design has options for meeting timing. All four
are driven by the boot image.

| Clock | Frequency | Reset |
|---|---|---|
| `pl0_ref_clk` | 100 MHz | `rst_pl0` |
| `pl1_ref_clk` | 200 MHz | `rst_pl1` |
| `pl2_ref_clk` | 300 MHz | `rst_pl2` |
| `pl3_ref_clk` | 333.33 MHz | `rst_pl3` |

All four are sourced from the PMC NoC PLL (NPLL), which is driven from the PMC
reference clock.

These frequencies cannot be changed from PYNQ at runtime. On Zynq and Zynq
UltraScale+, the `Overlay` class reprograms the PL clocks when a bitstream is
downloaded. On Versal the dividers belong to the PMC and are set by the boot
image. Changing a frequency means editing the CIPS configuration here and
rebuilding both golden and the image.

## Interrupts

Golden exposes a single PL-to-PS interrupt, `pl_ps_irq0`. An overlay with more
than one interrupt source multiplexes them through an AXI interrupt controller
onto that line.

## Base overlay example

`../base` is the worked example. It keeps the processor half untouched and
replaces golden's tie-offs with real logic:

| Golden provides, tied off by | Base connects |
|---|---|
| `M_AXI_FPD`, `pl_tieoff_fpd` | a SmartConnect fanning out to its nine slaves |
| `axi_noc_pl/S00_AXI` and `S01_AXI`, `pl_tieoff_dma0` and `dma1` | the two master ports of `axi_dma_0`, which reach DDR through `axi_noc_pl/M00_INI` |
| `pl_ps_irq0`, `pl_tieoff_irq` | `axi_intc_0`, fed by an `xlconcat` carrying seven interrupt sources |
| `pl0_ref_clk`, `rst_pl0` | every IP in the design, at 100 MHz |

It leaves `M_AXI_LPD` tied off and `pl1` to `pl3` unused.

## Rebuilding golden

Requires Vivado 2025.2. PL reload compatibility does not
span Vivado releases, so an overlay must be built with the same version as the
boot image.

Source the AMD-Xilinx tools, then:

```bash
cd <PYNQ repository>/boards/VCK190/golden
make
```

`make block_design` creates the project and block design from `golden.tcl`.
`make build` runs synthesis, implementation and `write_device_image`.



Rebuilding golden produces a new `BOOT.BIN`. Overlays built against the previous
golden will be rejected by the PLM. Golden and the image are rebuilt together.

## Verifying an overlay

Overlays check themselves against golden with two Make targets. `../base` runs
both as part of its build.

- `make check_timing` fails the build if the implemented design misses timing.
- `make check_compatibility` runs `pr_verify` against `golden_routed.dcp` and
  compares `golden_boot.pdi`'s `unique_id` against the overlay PDI's
  `parent_unique_id`, which is the comparison the PLM makes at load time.
