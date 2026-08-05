# PYNQ EDF self-test

An on-board self test for the PYNQ image on the ZCU104. It checks the
root filesystem, networking, XRT/overlay, MicroBlaze firmware, kernel GPIO,
a live pybind11 C++ compile, and (optionally) the attached peripherals.

## Running

Log in as `xilinx` (default password `xilinx`) and run:

```bash
sudo pynq-selftest                  # full run -- requires the hardware below
sudo pynq-selftest --no-peripherals # software-only, no board setup needed
```

- **Full run** exercises everything, including the PMOD/Grove, HDMI, and USB
  webcam checks. Set the board up as described below first.
- **`--no-peripherals`** runs only the checks that need no extra hardware
  (checks 1-17). The peripheral checks are reported as `[SKIP]`.

A timestamped log is written to `/tmp/pynq-selftest.<date>.log`. The HDMI and
webcam checks also drop PNG captures (`pynq-hdmi-tx.png`, `pynq-hdmi-rx.png`,
`pynq-webcam.png`) in the current directory for manual inspection.

The script exits `0` only when every check passes (skipped checks do not fail
the run).

## Board setup (full run only)

Do this before running without `--no-peripherals`:

| Connector           | Attach                                                              |
|---------------------|---------------------------------------------------------------------|
| **PMODA**           | Pmod OLED                                                           |
| **PMODB**           | PYNQ Grove Adapter; Grove I2C ADC on port **G4**; Grove temp -> ADC |
| **HDMI**            | Cable looping **Tx (OUT)** back to **Rx (IN)**                      |
| **USB**             | A UVC USB webcam                                                    |
| **User DIP switches** | Pattern **0101**                                                 |
| **User push-buttons** | All released                                                     |

## What each check does

1. **Root filesystem auto-resize** -- confirms `RESIZED=1` in `/etc/environment`
   (the first-boot resizefs ran) and reports the root partition size.
2. **Networking** -- confirms `eth0` obtained an IPv4 address over DHCP.
3. **CMA pool** -- confirms the contiguous DMA pool (`CmaTotal` in
   `/proc/meminfo`) is ~512 MB, as needed for `allocate()` buffers.
4. **Jupyter server** -- confirms `jupyter.service` is active and something is
   listening on port 9090.
5. **XRT runtime** -- confirms `XILINX_XRT` is set and `pyxrt.device(0)` opens
   an XRT device (env + `zocl` driver working).
6. **PYNQ overlay + DMA buffer** -- loads `base.bit` with `Overlay`, allocates a
   DMA buffer, flushes it, and reads its physical address.
7. **systemd failed units** -- confirms no unexpected failed units (the benign
   `isc-dhcp-server*` and `pynq-x11` are allowed).
8. **Image identity** -- confirms `os-release` is `PynqLinux 4.0.0` / codename
   `Verona` and `/home/xilinx/REVISION` matches.
9. **xilinx user + groups** -- confirms the `xilinx` user exists and is in the
   `sudo` and `adm` groups.
10. **Notebook delivery** -- confirms `PYNQ_JUPYTER_NOTEBOOKS` is set and the
    directory exists and is populated.
11. **Serial console autologin** -- confirms `serial-getty@.service` autologins
    the `xilinx` user.
12. **merged-/usr layout** -- confirms `/bin`, `/sbin`, `/lib`, `/lib64` are all
    symlinks into `/usr`.
13. **base-config patches** -- confirms the image customisations: sudoers keeps
    the `BOARD` env, ssh `ForwardX11 yes`, `/etc/pip.conf` present, the
    MicroBlaze toolchain is on `PATH`, `PYNQ_PYTHON=python3`, and the samba
    `[xilinx]` share exists.
14. **Pmod/Grove MicroBlaze firmware** -- confirms `pynq.lib.pmod` imports and at
    least 20 `pmod_*.bin` are installed, including `pmod_oled.bin` and a
    `pmod_grove_*.bin`.
15. **Dropped libs** -- confirms the removed stacks (`arduino`, `rpi`,
    `logictools`) are absent and `pynq.lib.Arduino` is not importable.
16. **sysfs GPIO** -- confirms `/sys/class/gpio` exposes `gpiochip` entries with
    a `zynqmp_gpio` controller and `pynq.GPIO.get_gpio_base()` resolves a base
    (kernel `CONFIG_GPIO_SYSFS` enabled; prerequisite for MicroBlaze IOP reset).
17. **pybind11 C++ compile** -- compiles a small C++ module with `c++` +
    `python3-config` via PYNQ's pybind11 flow, imports it, and calls it.
18. **Pmod OLED + Grove temp + switches + buttons** (HARDWARE) -- loads the base
    overlay, writes `PYNQ 4.0.0 OK` to the OLED on PMODA (SPI is write-only, so
    verify the text on the display by eye), reads the Grove temperature via the
    I2C ADC on PMODB/G4 and checks it is 0-60 C, reads the DIP switches expecting
    `0101` (its reverse `1010` also passes, since bit order depends on how the
    block is read), and reads the buttons expecting all released (`0000`).
19. **HDMI Tx->Rx loopback** (HARDWARE) -- sends a colour-bar pattern out the Tx
    port and checks the Rx port recovers it over the loopback cable; saves
    `pynq-hdmi-tx.png` and `pynq-hdmi-rx.png` for manual comparison.
20. **USB webcam capture** (HARDWARE) -- captures frames and verifies the camera
    returns *real* image data via spatial texture and/or frame-to-frame change
    (it does not know what the camera sees); saves `pynq-webcam.png`. For an
    extra sanity check, cover the lens and confirm the saved frame is mostly
    black.
