# Building a PYNQ image

PYNQ images are built inside the `sdbuild` Docker container, which contains all
build dependencies. AMD tools should not be installed in the container. They stay
on the host and are mounted into it.

## Prerequisites

* Docker
* Vivado and Vitis 2025.2 installed on the host, with appropriate licences
* At least 100 GB of free disk space. A build from scratch takes several hours.

## 1. Build the container image

```sh
cd sdbuild
docker build \
  --build-arg USERNAME=$(whoami) \
  --build-arg USER_UID=$(id -u) \
  --build-arg USER_GID=$(id -g) \
  -t pynqdock:latest .
```

The build arguments make files that the build creates owned by your host user.

## 2. Build an image

Point `XILINX_TOOLS` at the directory holding your `Vivado` and `Vitis` installs,
and `XILINXD_LICENSE_FILE` at your licence. Run from the top of the repo:

```sh
export XILINX_TOOLS=/tools/Xilinx/2025.2
export XILINXD_LICENSE_FILE="$HOME/.Xilinx"

docker run --init --rm \
  --network host \
  -e XILINX_TOOLS -e XILINXD_LICENSE_FILE \
  -v "$XILINX_TOOLS:$XILINX_TOOLS:ro" \
  -v "$XILINXD_LICENSE_FILE:$XILINXD_LICENSE_FILE" \
  -v "$PWD:/workspace" \
  --privileged \
  pynqdock:latest \
  bash -lc 'cd /workspace/sdbuild && make BOARDS=ZCU104 REBUILD_PYNQ_SDIST=1 REBUILD_PYNQ_ROOTFS=1'
```

* `BOARDS` names the board to build. Any directory under `boards/` that contains
  a `.spec` file can be used, and several can be given at once.
* `XILINX_TOOLS` must be mounted at the same path it has on the host, because the
  `settings64.sh` scripts source their companion files by absolute path. The
  container entrypoint sources them.
* `XILINXD_LICENSE_FILE` names the licence: a `.lic` file, a directory holding
  them such as `~/.Xilinx`, or `port@host` for a licence server. A path is
  mounted at the path it has on the host, so the value means the same thing
  inside the container.
* A node-locked licence is tied to the machine's MAC address and hostname, which
  the container takes from the host through `--network host`. Without it the
  container has an identity of its own and the licence will not match. A licence
  server needs neither the mount nor `--network host`.
* `--privileged` is required: the root filesystem stages mount filesystems and
  run a QEMU chroot.
* `REBUILD_PYNQ_SDIST` and `REBUILD_PYNQ_ROOTFS` build the PYNQ package and the
  Ubuntu root filesystem from source. Leave them out to use prebuilt tarballs
  instead, placed in `sdbuild/prebuilt/` as `pynq_sdist.tar.gz` and
  `pynq_rootfs.<arch>.tar.gz`.

To work inside the container instead of running one command, add `-it` and replace
the `bash -lc ...` argument with `/bin/bash`.

## Build outputs

Once built, all output files will be located in `sdbuild/output/`:

| Path | Contents |
| --- | --- |
| `<BOARD>-<version>.img` | The SD card image |
| `boot/<BOARD>/` | `BOOT.BIN`, `Image`, `system.dtb`, `modules.tgz`, `zocl.ko` |
| `noble.<arch>.<version>.tar.gz` | The root filesystem, with `REBUILD_PYNQ_ROOTFS` |
| `dist/` | The PYNQ source distribution, with `REBUILD_PYNQ_SDIST` |

## The EDF cache

Boot artefacts are built with AMD's EDF (Yocto/bitbake) flow. The first build creates 
`sdbuild/edf-cache/` and syncs the EDF layers into it. The cache holds the layer 
workspace, the shared-state cache and the downloads, and runs to about 30 GB.

The cache is located outside the container, so it persists across container runs and 
`make clean` does not remove it. To share one cache between checkouts, or to keep it 
on another filesystem, set `EDF_CACHE`, or override `EDF_DIR`, `SSTATE_DIR` and `DL_DIR`
individually:

```sh
make BOARDS=ZCU104 EDF_CACHE=/path/to/edf-cache
```

## Rebuilding

A board's overlay is built from its own sources when the bitstream or PDI named
by `BITSTREAM_<BOARD>` in the board's `.spec` file is missing. Delete that file
to force a rebuild. For Versal boards, the golden reference design it depends on is
rebuilt first.

`make clean` removes `build/` and `output/`, leaving `edf-cache/` in place.

To add a board, see [BUILD_SYSTEM.md](BUILD_SYSTEM.md).
