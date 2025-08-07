# PYNQ Image Building

This repository builds a PYNQ image from Ubuntu and the sources of its constituent
components. Starting with the PYNQ v3.1 release, Docker is the recommended way to 
build PYNQ images. Docker simplifies setup by managing dependencies and environment 
configuration within an isolated container.

## Quick Start: Building with Docker

### 1. Prerequisites

To use the Docker-based flow, ensure the following tools are installed **on your host machine**:

* **Vivado**, **Vitis**, and **Petalinux**, version 2024.1
* A supported Linux distribution (see [UG973](https://docs.amd.com/r/2024.1-English/ug973-vivado-release-notes-install-license/Supported-Operating-Systems))
* **Docker** (Install via the [official instructions](https://docs.docker.com/engine/install/))

> ⚠️ AMD tools must be installed on the host system, not inside the Docker container.

### 2. Clone the Repository and Build the Docker Image

```sh
git clone --recursive https://github.com/Xilinx/PYNQ.git PYNQ
cd PYNQ/sdbuild
docker build \
  --build-arg USERNAME=$(whoami) \
  --build-arg USER_UID=$(id -u) \
  --build-arg USER_GID=$(id -g) \
  -t pynqdock:latest .
```

These `--build-arg` values ensure that any files created inside the container will
be owned by your user on the host system, helping to avoid permission issues.

### 3. Run the Docker Container

Before running the container, make sure you know where Vivado and Petalinux are 
installed on your host. For example:

* Vivado: `/tools/Xilinx`
* Petalinux: `/home/user/petalinux`

Then, from within the PYNQ repo top-level directory, you can start the container as follows:

```sh
docker run \
  --init \
  --rm \
  -it \
  -v /tools/Xilinx:/tools/Xilinx:ro \
  -v /home/user/petalinux:/home/user/petalinux:ro \
  -v $(pwd):/workspace \
  --name pynq-sdbuild-env \
  --privileged \
  pynqdock:latest \
  /bin/bash
```

Notes:

* `-v $(pwd):/workspace` mounts your local PYNQ repo inside the container.
* The `:ro` option mounts tool directories as read-only.
* `--privileged` is required for parts of the build process.

### 4. Build the PYNQ Image

Inside the container, first set up the tool environment:

```sh
source /tools/Xilinx/Vivado/2024.1/settings64.sh
source /home/user/petalinux/settings.sh
```

Ensure that the prebuilt pynq sdist and rootfs tarballs are in the `sdbuild/prebuilt` 
folder, then build your image:

```
cd sdbuild
make BOARDS=ZCU104 # Replace ZCU104 with the board you'd like to target.
```

## VM-Based Setup (Alternative)

If Docker is unavailable or you need to rebuild the SDIST, you can run the build process
inside a supported Ubuntu-based VM (e.g. Ubuntu 22.04). The image building requires doing
a lot of things as root and while every effort has been made to ensure it doesn't break
the world this is far from guaranteed. This flow must be run in a Ubuntu based Linux 
distribution and has been tested on Ubuntu 22.04. Other Linux versions might work but may 
require different or additional packages. The build process is optimised for 4-cores and 
can take up to 100 GB of space.

### Quick Steps

1. Ensure that sudo is configured for passwordless use and that proxy settings and other environment variables are forwarded correctly.
2. Run the setup script:

   ```sh
   scripts/setup_host.sh
   ```

3. Install Petalinux (2024.1) and ensure it is on your `PATH`
4. Download the prebuilt `pynq_sdist.tar.gz` and `pynq_rootfs.<arch>.tar.gz` and place them in `sdbuild/prebuilt/`
5. Build your image:

   ```sh
   make BOARDDIR=<boards_dir>
   ```

> The full build may require up to **50 GB** of disk space and a 4-core machine is recommended.

## Detailed host setup

The `setup_host.sh` script installs a set of packages required either for Vivado
or the other build tools. It installs crosstool-ng which is not included in the
Ubuntu repository and an up-to-date and slightly patched version of QEMU which
fixes some race conditions in the Ubuntu-shipped version. See the source of the
script for more details in what exactly needs to be done to configure your own
environment if the script proves insufficient. Also, make sure you have the 
appropriate Vivado licenses to build for your target board, in particular 
[HDMI IP](https://www.xilinx.com/products/intellectual-property/hdmi.html).

## Stages of an image build

The image process is designed for the quick building of multiple board images
across both ZYNQ and ZYNQ Ultrascale+ architectures. The build is split into
_board agnostic_ and _board specific_ sections. First a generic image is created
for each device family consisting of the base Ubuntu root filesystem and the
PYNQ packages such as Jupyter and the Microblaze compiler.

## Initial bootstrap

The `ubuntu` folder contains all of the files for the initial bootstrap of the
Ubuntu root filesystem. For this release we are targeting the 22.04 _Jammy Jellyfish_ 
release but other versions can be added here if desired. The `jammy`
folder contains subfolders for the `arm` and `aarch64` architectures each
containing a `multistrap` config file, a set of patches to apply to the
filesystem and a `config` file listing the packages to be installed.

## Packages

Packages form the core of the image flow and each consists of up to four files,
all of which are optional:

1. A `Makefile` which adds to the `PACKAGE_BUILD_${PACKGE_NAME}` variable any 
   targets that are required. This should be used for downloading or compiling
   files that can be done on the host. If the package needs to run architecture-
   specific rules this can be added to `PACKAGE_BUILD_${PACKAGE_NAME}_${ARCH}`.
2. A `pre.sh` bash script called before running the chroot which ordinarily
   copies files into the chroot. The chroot location is passed as the first
   argument.
3. A `qemu.sh` bash script called from within the context of the chroot. As the
   chroot is run with QEMU the minimum possible amount of work should be done
   here.
4. A `post.sh` bash script called after running the chroot which ordinarily
   cleans up any temporary files. The chroot location is passed as the first
   argument.

Scripts should not pollute their current working directory instead using the
location specified by `$BUILD_ROOT` for all temporary files. This is also the
recommend place for the makefile to deposit files for the bash scripts to
subsequently use. Each package script is passed `ARCH` and `PYNQ_BOARDNAME`
as environment variables.

## Board-specific files

Each board in the `boards` subdirectory of the PYNQ repo contains a `*.spec`
file, (optional) some packages, and (optional) Petalinux BSP related files. 

The `*.spec` file details the BSP file to use, 
the bitstream to load on boot and any additional packages that 
should be installed in the root filesystem.
The `*.spec` file should be placed in the root folder for the board and 
all paths within it should be given relative to it.

There are three main variables the spec file is responsible for setting:
 1. `BSP_${BOARD}`
 2. `BITSTREAM_${BOARD}`
 3. `STAGE4_PACKAGES_${BOARD}`

`${BOARD}` must be the same as the name of the folder containing the spec file.
This will also ultimately be the value of the $BOARD environment variable in
the final image.


## Porting to a new board

There are two flows for porting to a new board. The simplest approach is to
take a pre-existing PetaLinux BSP and our pre-built board-agnostic image
appropriate to the architecture - arm for Zynq-7000 and aarch64 for Zynq
UltraScale+. The `scripts/image_from_prebuilt.sh` script will take these two
components and create an image without needing to run the whole image creation
flow. See that script for the details of the arguments that are needed.

For more substantial board support you will need to create a board repository
based on either a PetaLinux BSP or an HDF file from Vivado. The steps to create
a board repository are detailed below.

### Step 1: Prepare the folder
First you need to create folder to act as a board repository - 
`myboards` in this example - and create a subfolder to hold the spec for 
the board you are porting to - `myboards/Myboard`. 
You also need to create a spec file - by convention
`Myboard.spec`. This will set make variables for the board as follow:

```Makefile
BSP_Myboard := Myboard.bsp
BITSTREAM_Myboard := Myboard.bit
# Optionally install some additional packages
STAGE4_PACKAGES_Myboard := my_package
```

### Step 2: Prepare the BSP
The main prerequisite for porting to a new board is the existence of a valid
Petalinux BSP (`Myboard.bsp`) for the board targeting the correct 
version of the Xilinx tools. This can be done in multiple ways shown below.

#### (1) Starting from a hardware project
You may already have a Vivado project to start with. In that case, either
(1) the make flow to build your hardware project
(all the way to the `*.hdf` file), or (2) the pre-built `*.hdf` file has to
be provided. The SD build flow will take that `*.hdf` file in and generate
the BSP. `BSP_Myboard` in the `*.spec` file can be left empty.

Meta-user configurations can be added to the `myboards/Myboard/petalinux_bsp` 
folder so the patches will be applied to the new BSP.


#### (2) Starting from a BSP

You may already have a BSP downloaded somewhere, or constructed
previously. In that case, you can just specify `BSP_Myboard` in
the `*.spec` file, and the SD build flow will take that BSP file in and build
the boot files.

Again, meta-user configurations can be added to the
`myboards/Myboard/petalinux_bsp` folder so the patches will be applied to the 
new BSP. For more details about customising the
boot files please refer to the Petalinux documentation.

### Step 2: Add extra packages 
Custom packages can be placed in a `packages` subfolder of the and will be
picked up automatically if referenced. This is a convenient way of installing
custom notebooks or Python packages if desired for your board.

### Step 3: Build the image

#### (1) Collect a prebuilt board-agnostic root filesystem tarball and a prebuilt PYNQ source distribution.

Starting in PYNQ v3.0, by default the SD card build flow expects a prebuilt root filesystem 
and a PYNQ source distribution to speedup and simplify user rebuilds of SD card images. 
These binaries can be found at [the PYNQ boards page](https://www.pynq.io/boards.html)
and copied into the sdbuild prebuilt folder

```bash
# For rebuilding all SD cards, both arm and aarch64 root filesystems
# may be required depending on boards being targetted.
cp pynq_rootfs.<arm|aarch64>.tar.gz <PYNQ repository>/sdbuild/prebuilt/pynq_rootfs.<arm|aarch64>.tar.gz
cp pynq-<version>.tar.gz            <PYNQ repository>/sdbuild/prebuilt/pynq_sdist.tar.gz
```

#### (2) Run `make`

With all the files prepared, the SD card image can be built by navigating to the following directory and running make:

```bash
cd <PYNQ repository>/sdbuild/
make
```

### Step 4 (Optional): Useful byproducts

You can force a PYNQ source distribution rebuild by setting the REBUILD_PYNQ_SDIST variable when invoking make

```bash
make REBUILD_PYNQ_SDIST=True
```

You can force a root filesystem build by setting the REBUILD_PYNQ_ROOTFS variable when invoking make:

```bash
make REBUILD_PYNQ_ROOTFS=True
```

All boot files are created using Petalinux based on a provided BSP. To generate
the boot files only:

```Makefile
make boot_files BOARDDIR=<absolute_path>/myboards
```

To generate sysroot:

```Makefile
make sysroot BOARDDIR=<absolute_path>/myboards
```

To generate the Petalinux BSP for future use:

```Makefile
make bsp BOARDDIR=<absolute_path>/myboards
```

To use a previously built PYNQ source distribution tarball and/or rootfs, instead of 
moving the files into the prebuilt folder, you can specify the `PYNQ_SDIST` and 
`PYNQ_ROOTFS` environment variables

```Makefile
make PYNQ_SDIST=<sdist tarball path> PYNQ_ROOTFS=<rootfs tarball path>
```

## Custom Ubuntu Repository

By default the SD build flow will pull from https://ports.ubuntu.com. This can
be changed by setting the `PYNQ_UBUNTU_REPO` environment variable. The
repository link in the final image will remain unchanged.
