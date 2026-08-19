# VCK190

PYNQ support for the Versal AI Core Series VCK190 evaluation board.

## Layout

| Directory | Contents |
|---|---|
| `golden/` | The golden reference design: the processor half that the image boots from, and the fixed boundary every overlay must match. |
| `base/` | The base overlay, and a worked example of a conforming design. |
| `edf_bsp/` | Board-specific device tree additions used by the Yocto (EDF) build. |
| `notebooks/` | Getting-started notebook shipped on the image. |
| `packages/` | Board packages installed into the image, including the self-test. |

## How VCK190 differs from other PYNQ boards

The device is configured in two stages, which AMD calls Segmented Configuration.
The boot image brings up the processors, the NoC and DDR so that Linux can boot
before the programmable logic exists; a separate PL image configures the fabric
and is what PYNQ reloads when you construct an `Overlay`.

This means the processor half of the design is fixed when the image is built, and
overlays have to plug into it exactly. The firmware checks this and refuses to
load a mismatched PL image. `golden/README.md` describes the boundary and the
rules that follow from it.

Two further consequences worth knowing:

- PL clock frequencies are set by the boot image and cannot be reprogrammed at
  runtime, unlike Zynq and Zynq UltraScale+. Golden brings out four fixed clocks
  (100, 200, 300 and 333.33 MHz) so designs have a choice.
- PYNQ services one PL-to-PS interrupt line, so a design with several interrupt
  sources routes them through an AXI interrupt controller. `base/` shows this.

## Building

Each design is built with `make` from its own directory and needs Vivado 2025.2,
which ships the VCK190 board files.

To build your own overlay, start from `base/` and follow the rules in
[`golden/README.md`](golden/README.md).
