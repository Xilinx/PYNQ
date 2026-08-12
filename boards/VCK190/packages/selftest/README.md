# VCK190 Self-test Package

This package installs `pynq-selftest`, a headless script that verifies a booted
VCK190 PYNQ (Versal) image. Run it on the board as root:

```bash
sudo pynq-selftest
```

Results are printed to the terminal and saved to
`/tmp/pynq-selftest.<timestamp>.log`. The script exits non-zero if any check
fails, so it can also be used in automated bring-up. Pass `--no-peripherals`
to skip the checks that program the PL.

The board-specific checks exercise the in-repo VCK190 base overlay
(`base.pdi`), which is the same overlay the `getting_started` and
`register_map_intro` notebooks use.

## What is tested

Image-level checks (no external hardware needed):

1. Root filesystem auto-resize ran.
2. Networking — a global IPv4 address is present.
3. CMA pool is at least ~512 MB.
4. Jupyter server is active and listening on `:9090`.
5. XRT runtime opens an FPGA device (`pyxrt.device(0)`).
6. PYNQ overlay load + DMA buffer allocation.
7. No unexpected failed systemd units.
8. Image identity (`PynqLinux 4.0.0`).
9. `xilinx` user exists and is in `sudo`/`adm`.
10. Notebook delivery.
11. Serial console autologin.
12. merged-/usr layout.
13. base-config patches.
14. sysfs GPIO interface.
15. pybind11 C++ compile + import.
16. Internet connectivity (needed to download overlays).
17. Dropped libs (arduino/rpi/logictools removed on the EDF port).

Board-specific checks (segmented-configuration base overlay):

* **Base overlay load** — `BaseOverlay("base.pdi")` programs the PL and
  populates `ip_dict`.
* **LEDs** — the 4 LED AXI GPIO channel is driven on/off/toggle.
* **Buttons + DIP switches** — the 4+4 input AXI GPIO channels read back
  binary values.
* **register_map** — read/write via the AXI GPIO `register_map` interface.
* **AXI DMA loopback** — a 1024×uint32 buffer is sent and received through the
  AXI Stream FIFO loopback, validating the PL↔DDR data path.
* **AXI BRAM** — read/write through the BRAM controller MMIO.
* **Static MAC** — the NIC MAC is globally-administered (a factory MAC read
  from the board EEPROM by u-boot), not a random/fallback MAC.

Checks whose hardware is absent are reported as `[SKIP]`, not `[FAIL]`.

## Hardware setup

For the fullest coverage, before running the self-test:

1. Insert the SD card with the image and set the boot mode switch to SD.
2. Connect the USB-UART to your PC for the serial console (optional).
3. Connect an Ethernet cable (needed for tests 2, 16).
4. Connect the power supply and power on.

## Adding the package to the SD build

The self-test is added automatically by the PYNQ SD build flow via the
`VCK190.spec` `STAGE4_PACKAGES` list (entry `selftest`). No manual step is
required for images produced by this repository.
