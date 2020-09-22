# PYNQ Image Building

This repository constructs a PYNQ image from the Ubuntu repositories and the
sources of the other constituent parts.

## Choosing a VM environment

It's highly recommended to run these scripts inside of a virtual machine. The
image building requires doing a lot of things as root and while every effort
has been made to ensure it doesn't break the world this is far from guaranteed.
This flow must be run in a Ubuntu based Linux distribution and has been tested
on Ubuntu 16.04 and Ubuntu 18.04. Other Linux versions might work but may
require different or additional packages. The build process is optimised for
4-cores and can take up to 50 GB of space.

## Quick start
 * Ensure that sudo is configured for passwordless use and that proxy settings
   and other environment variables are forwarded correctly.
 * Run `scripts/setup_host.sh`
 * Install Petalinux (e.g. 2017.4)
 * Ensure that Petalinux is on the PATH
 * Run `make BOARDDIR=<boards_directory>` to recreate all board images
 * Wait for a couple of hours

## Detailed host setup

The `setup_host.sh` script install a set of packages required either for Vivado
or the other build tools. It installs crosstool-ng which is not included in the
ubuntu repository and an up-to-date and slightly patched version of QEMU which
fixes some race conditions in the ubuntu-shipped version. See the source of the
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

The `unbuntu` folder contains all of the files for the initial bootstrap of the
Ubuntu root filesystem. For this release we are targeting the 18.04 _Bionic
Beaver_ release but other versions can be added here if desired. The `bionic`
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

Scripts should not polluted their current working directory instead using the
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

### Step 3: Run `make`

With all the files prepared, the SD card image can be built:

```Makefile
make BOARDDIR=<absolute_path>/myboards
```

### Step 4 (Optional): Useful byproducts

All boot files are created using Petalinux based on a provided BSP. To generate
the boot files only:

```Makefile
make boot_files BOARDDIR=<absolute_path>/myboards
```

To generate the software components for SDx platform:

```Makefile
make sdx_sw BOARDDIR=<absolute_path>/myboards
```

To generate sysroot:

```Makefile
make sysroot BOARDDIR=<absolute_path>/myboards
```

To generate the Petalinux BSP for future use:

```Makefile
make bsp BOARDDIR=<absolute_path>/myboards
```

To build the board-agnostic images and sysroot you can pass the `ARCH_ONLY`
variable to make. This will cause the `images` target to build the architecture
image.

```Makefile
make images ARCH_ONLY=arm
```

To use a board-agnostic image to build a board-specific image you can pass the
`PREBUILT` variable:

```Makefile
make PREBUILT=<image path> BOARDS=<board>
```

To use a previously built PYNQ source distribution tarball you can pass the 
`PYNQ_SDIST` variable. This will also avoid having to rebuild bitstreams 
(except for external boards) and MicroBlazes' bsps and binaries.

```Makefile
make PYNQ_SDIST=<sdist tarball path>
```

## Custom Ubuntu Repository

By default the SD build flow will pull from https://ports.ubuntu.com. This can
be changed by setting the `PYNQ_UBUNTU_REPO` environment variable. The
repository link in the final image will remain unchanged.
