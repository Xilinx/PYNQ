# Porting a board

A board is a directory containing a `.spec` file and an `edf.env` file. Those two
are the only required files; everything else is added as the board needs it.
Boards in `boards/` are built by name; a board directory located elsewhere is built
by passing `BOARDDIR`:

```sh
make BOARDS=Myboard BOARDDIR=/path/to/myboards
```

## Board directory layout

```
Myboard/
├── Myboard.spec          # required: make variables for the board
├── edf.env               # required: boot artefact configuration
├── edf_bsp/              # optional
│   ├── board.dtsi        # optional: device tree nodes for the board
│   ├── kernel.cfg        # optional: kernel config fragment
│   └── u-boot/           # optional: u-boot patches and config fragments
├── base/                 # required if BITSTREAM_<BOARD> is set: overlay
│                         # sources and a Makefile that builds them
├── notebooks/            # optional: notebooks, delivered to the image
└── packages/             # optional: extra packages for the root filesystem
```

The directory name is the board name. It must match the `.spec` file name and
the `<BOARD>` suffix of the variables inside it, and it becomes the `BOARD`
environment variable in the image.

## The .spec file

Paths are relative to the board directory.

| Variable | | Meaning |
| --- | --- | --- |
| `ARCH_<BOARD>` | required | `aarch64` |
| `BITSTREAM_<BOARD>` | optional | Overlay loaded at boot, e.g. `base/base.bit` or `base/base.pdi`. Leave unset for a board with no boot overlay |
| `FPGA_MANAGER_<BOARD>` | optional | `1` to program the PL through the FPGA manager. Defaults to `1`, and selects which zocl device tree nodes are used |
| `STAGE4_PACKAGES_<BOARD>` | optional | Packages installed into the board's root filesystem. Without `pynq` here the image has no PYNQ in it |
| `REMOTE_PACKAGES_<BOARD>` | optional | Extra packages for a PYNQ.remote rootfs |

```Makefile
ARCH_Myboard := aarch64
BITSTREAM_Myboard := base/base.bit
FPGA_MANAGER_Myboard := 1
STAGE4_PACKAGES_Myboard := xrt pynq ethernet selftest
```

## Boot artefacts: edf.env

`BOOT.BIN`, the kernel `Image`, `system.dtb`, the kernel modules and `zocl.ko`
are built with AMD's EDF (Yocto/bitbake) flow. `edf.env` selects the Yocto
machine to build them for.

| Key | | Meaning |
| --- | --- | --- |
| `EDF_BOOT_MACHINE` | required | Machine used for `BOOT.BIN` and the device tree |
| `EDF_MODE` | optional | `prebuilt` to use a machine from AMD's layers, `custom` to generate one from an XSA. Defaults to `prebuilt` |
| `EDF_LINUX_MACHINE` | optional | Machine used for the kernel. Defaults to `EDF_BOOT_MACHINE` |
| `EDF_MANIFEST_TAG` | optional | EDF manifest tag to sync. Defaults to the tag in `scripts/build_edf_boot.sh` |
| `BSP_XSA_PATH` | custom mode | The XSA to generate the machine from. Without it, `base/base.xsa` is used if present |
| `EDF_BOARD_DTS` | optional | Custom mode only: board DTS to pass to `sdtgen`. Omit to use the generic SoC device tree and put everything board-specific in `board.dtsi` |
| `EDF_DDR_HIGH_BANK_REG` | optional | `reg` value trimming the high DDR bank to the board's real size |

### Prebuilt mode

Use this when AMD's layers already contain a machine for the board. ZCU104:

```sh
EDF_MANIFEST_TAG=amd-edf-rel-v25.11.1
EDF_MODE=prebuilt
EDF_BOOT_MACHINE=zynqmp-zcu104-sdt-full
EDF_LINUX_MACHINE=zynqmp-zcu104-sdt-full
```

### Custom mode

Use this when the boot image has to match a design built here, as on Versal,
where `BOOT.BIN` carries the golden reference design that runtime overlays are
segmented children of. The build runs `sdtgen` on `BSP_XSA_PATH` to produce a
system device tree, then `gen-machine-conf` to turn that into a machine layer,
so Vivado must be available. VCK190:

```sh
EDF_MANIFEST_TAG=amd-edf-rel-v25.11.1
EDF_MODE=custom
EDF_BOOT_MACHINE=versal-vck190-pynq-seg
EDF_LINUX_MACHINE=amd-cortexa72-common
EDF_BOARD_DTS=versal-vck190-reva
BSP_XSA_PATH=golden/golden.xsa
```

`EDF_BOOT_MACHINE` must not match a machine name in AMD's layers, or bitbake
resolves theirs and ignores the generated one.

## Kernel, device tree and u-boot: edf_bsp/

All three are optional, and a board that needs none of them can omit `edf_bsp/`
entirely.

* `board.dtsi` is appended to the machine's device tree. Board-specific nodes
  belong here: memory, PHYs, I2C devices, pin settings.
* `kernel.cfg` is added to the kernel's sources as a config fragment when
  present, and merged into its `.config`.
* `u-boot/` is added to u-boot's sources when present. `.patch` and `.diff`
  files are applied, and `.cfg` fragments are merged into u-boot's `.config`.

Editing `board.dtsi` invalidates the device tree's shared state, so the change
is picked up on the next build.

## Overlays and notebooks

The overlay named by `BITSTREAM_<BOARD>` is built by running `make` in its
directory, so that directory needs a `Makefile` that produces the bitstream or
PDI. The build only does this when the artefact is missing; delete it to force a
rebuild. A board with no `BITSTREAM_<BOARD>` needs no overlay directory, and
builds an image with no boot overlay.

Every directory within two levels of the board directory that holds a `.bit` or
`.pdi` becomes an overlay in the image. Its `.bit`, `.pdi`, `.hwh`, `.py` and
`.dtbo` files are installed into the `pynq.overlays` package, under the
directory's name. A `*_boot.pdi` is skipped, being loaded by the platform rather
than as an overlay.

Notebooks are optional. They are copied from `notebooks/` in the board
directory, and from `notebooks/` inside an overlay directory.

## Extra packages

`packages/` is optional. A directory under it becomes installable by naming it in
`STAGE4_PACKAGES_<BOARD>`. A package consists of up to four optional files: a
`Makefile` for work done on the host, `pre.sh` and `post.sh` which run outside
the target root filesystem and are passed its path, and `qemu.sh` which runs
inside it under QEMU. Scripts should write temporary files to `$BUILD_ROOT`.
