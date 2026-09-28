# VCK190 golden reference design

The golden design provides the processor and memory configuration shared by
VCK190 PYNQ images and overlays. It includes the Versal CIPS, the DDR4 and
LPDDR memory controllers, the NoC configuration, the PL interfaces, and the AXI
debug hub.

The PL-facing boundary provides:

- four memory interfaces, `noc_pl/S00_AXI` to `S03_AXI`;
- `M_AXI_FPD` and `M_AXI_LPD`;
- one PL clock and reset; and
- one PL-to-PS interrupt.

Interfaces that golden does not use are connected to tie-offs, ready to be
replaced by overlay logic.

## Segmented configuration

The VCK190 uses segmented configuration. `BOOT.BIN` loads the processor, NoC
and memory configuration before Linux starts. PYNQ can then load a PL overlay
without replacing that boot configuration.

Overlays should keep the same processor and NoC boundary as golden, but they
only need to use the interfaces their design requires.

## PL clock

Golden enables `pl0_ref_clk` with a single fabric reset through `rst_pl0`. The
initial clock frequency is 300 MHz.

An overlay can request a different frequency in its hardware metadata. PYNQ
programs `pl0_ref_clk` to that frequency when the overlay is downloaded. For
example, the base overlay requests 100 MHz.

## Building golden

Vivado 2025.2 is required. After sourcing the AMD tools, run:

```bash
cd <PYNQ repository>/boards/VCK190/golden
make
```

The build produces:

| File | Purpose |
|---|---|
| `golden.xsa` | Input to the VCK190 EDF image build |
| `golden_boot.pdi` | Boot configuration used for compatibility checks |
| `golden_noc.ncr` | NoC solution used when implementing overlays |
| `golden_routed.dcp` | Golden checkpoint used by `pr_verify` |

The EDF image build uses `golden.xsa` to generate `BOOT.BIN`.

## Building overlays

The base design in `../base` is a useful reference for building an overlay
against golden. Its build locks the implementation to `golden_noc.ncr` and
runs both timing and compatibility checks.

The same checks can be run separately with:

```bash
make check_timing
make check_compatibility
```

The compatibility check runs `pr_verify` and confirms that the overlay PDI
targets the current golden boot image.
