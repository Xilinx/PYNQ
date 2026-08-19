# VCK190 golden reference design

The golden reference is the processor half of every VCK190 PYNQ design: CIPS,
the two NoC instances, the DDR memory controller, the PL clocks and resets. It
contains no user logic — every PL-facing port is tied off — so it builds and
passes DRC on its own.

Its purpose is to define a fixed boundary. A PYNQ VCK190 image boots from this
design, and every overlay loaded on that image has to plug into it exactly.

## Why the boundary is fixed

The VCK190 image uses **Segmented Configuration**. The device is configured in
two stages:

- `boot.pdi` brings up the processors, the NoC and DDR. Linux boots from it
  before the programmable logic exists. It is written to the SD card as part of
  `BOOT.BIN` and does not change unless the image is rebuilt.
- `pld.pdi` configures the fabric afterwards and can be reloaded at runtime.
  This is what PYNQ writes every time you construct an `Overlay`.

Because the processor half is already running from `boot.pdi`, an overlay cannot
redefine it. The firmware enforces this: the PLM compares an identifier in the
PL image against the running boot image and refuses a mismatch with

```
Image is not compatible with Parent Image
PLM Error Status: 0x03530000
```

## What golden publishes

| Artifact | Purpose |
|---|---|
| `golden.xsa` | Input to sdbuild's EDF flow, which generates `BOOT.BIN`. |
| `golden_boot.pdi` | The boot image itself (PS, NoC, DDR). |
| `golden_noc.ncr` | The solved NoC routing. Overlays lock their implementation run to it so the boot-image NoC paths come out identical. |
| `golden_routed.dcp` | Reference for `pr_verify`, which compares an overlay's implemented boundary against golden's. |

These are build outputs and are not committed. Build them with `make`.

## The boundary

Fixed — an overlay must reproduce all of it unchanged:

- The block design name, `vck190_pynq`. The NoC solution records instance paths
  that include it, so a renamed design cannot lock to `golden_noc.ncr`.
- The `versal_cips_0` configuration.
- `axi_noc_ps` and its DDR paths.
- The number and type of `axi_noc_pl` slave ports.
- The four PL reference clocks and their frequencies.
- The four fabric resets, `rst_pl0` to `rst_pl3`.
- One PL-to-PS interrupt, `pl_ps_irq0`.
- The PS-PL address apertures.

Yours to change: everything in the PL.

**Use a subset of the boundary, never a superset.** Leaving a clock, reset or NoC
port unused is fine. Adding a PS-PL connection that golden does not have is not —
there is nothing in the boot image for it to connect to.

## PL clocks

Four clocks are brought out so a design has options for meeting timing. All four
are driven by the boot image, so they are available to an overlay whether or not
golden itself uses them.

| Clock | Frequency | Reset |
|---|---|---|
| `pl0_ref_clk` | 100 MHz | `rst_pl0` |
| `pl1_ref_clk` | 200 MHz | `rst_pl1` |
| `pl2_ref_clk` | 300 MHz | `rst_pl2` |
| `pl3_ref_clk` | 333.33 MHz | `rst_pl3` |

333.33 MHz is the highest this configuration supports; Vivado rejects requests of
400 MHz and above.

These frequencies cannot be changed from PYNQ at runtime, unlike Zynq and Zynq
UltraScale+ where the `Overlay` class reprograms the PL clocks on download. On
Versal the dividers belong to the PMC and are set by the boot image. Changing a
frequency therefore means editing the CIPS configuration here and rebuilding both
golden and the image.

## Interrupts

Golden exposes a single PL-to-PS interrupt, `pl_ps_irq0`, because that is the one
line PYNQ services. An overlay with more than one interrupt source multiplexes
them through an AXI interrupt controller onto that line; see
[`../base`](../base/README.md) for a worked example.

`pl_ps_irq0` is hwirq 116, which is GIC SPI 84 in the device tree.

## Build

```bash
make
```

Requires Vivado 2025.2, which ships the VCK190 board files this design uses
(board part `xilinx.com:vck190:part0:3.4`). Set `BOARD_STORE_PATH` to a
[XilinxBoardStore](https://github.com/Xilinx/XilinxBoardStore) checkout only if
you need to override them. PL Reload compatibility does not span Vivado releases,
so an overlay must be built with the same version as the boot image.

`make block_design` creates the project and block design from `golden.tcl`;
`make build` runs synthesis, implementation and `write_device_image`. `golden.tcl`
is a Vivado `write_bd_tcl` export and is not hand-edited — change the design in
the GUI and re-export.

**Rebuilding golden invalidates existing images.** It produces a new `BOOT.BIN`,
so overlays built against the previous golden will be rejected by the PLM. Golden
and the image are rebuilt together.

## Verifying an overlay

Overlays check themselves against golden with two Make targets; `../base` runs
both as part of its build.

- `make check_timing` fails the build if the implemented design misses timing.
- `make check_compatibility` runs `pr_verify` against `golden_routed.dcp` and
  compares `golden_boot.pdi`'s `unique_id` against the overlay PDI's
  `parent_unique_id`, which is the comparison the PLM makes at load time.

The UID comparison catches an overlay built against a different golden lineage.
It is not a content hash: it was measured not to change when only the CIPS
configuration changed, so `pr_verify` is what actually checks the boundary.
