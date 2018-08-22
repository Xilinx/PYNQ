# PYNQ Image Building

This repository constructs a PYNQ image from the Ubuntu repositories and the
sources of the other constituent parts.

## Choosing a VM environment

It's highly recommended to run these scripts inside of a virtual machine. The
image building requires doing a lot of things as root and while every effort
has been made to ensure it doesn't break the world this is far from guarenteed.
This flow must be run in a Debian or Ubuntu based Linux distribution and has
been tested on Ubuntu 16.04. Other versions should work but may required
different or additional packages. The build process is optimised for 4-cores
and will take up to 20 GB of space. A default Amazon EC2 instance is the main
development environment.

## Quick start
 * Ensure that sudo is configured for passwordless use and that proxy settings
   and other environment variables are forwarded correctly.
 * Run `scripts/setup_host.sh`
 * Install Petalinux 2017.4
 * Ensure that Petalinux is on the PATH
 * Run `make` to recreate all board images or `make BOARDS=Pynq-Z1` to recreate
   a specific board
 * Wait for a couple of hours

## Detailed host setup

The `setup_host.sh` script install a set of packages required either for Vivado
or the other build tools. It installs crosstool-ng which is not included in the
ubuntu repository and an up-to-date and slightly patched version of QEMU which
fixes some race conditions in the ubuntu-shipped version. See the source of the
script for more details in what exactly needs to be done to configure your own
environment if the script proves insufficient.

## Stages of an image build

The image process is designed for the quick building of multiple board images
across both ZYNQ and ZYNQ Ultrascale+ architectures. The build is split into
_board agnostic_ and _board specific_ sections. First a generic image is created
for each device family consisting of the base Ubuntu root filesystem and the
PYNQ packages such as Jupyter and the Microblaze compiler.

### Initial bootstrap

The `unbuntu` folder contains all of the files for the initial bootstrap of the
Ubuntu root filesystem. For this release we are targeting the 18.04 _Bionic
Beaver_ release but other versions can be added here if desired. The `bionic`
folder contains subfolders for the `arm` and `aarch64` architectures each
containing a `multistrap` config file, a set of patches to apply to the
filesystem and a `config` file listing the packages to be installed.

### Packages

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

## Board-specifc files

Each board in the `boards` subdirectory of the PYNQ repo contains a `*.spec`
file and a Petalinux BSP file. The spec files details the BSP file to use, the
bitstream to load on boot and any additional packages that should be installed
in the root filesystem.

### `spec` file

The spec file informs the build system which BSP and bitstream should be used
for a board. It should be placed in the root folder for the board and all paths
within it should be given relative to it.

There are three main variables the spec file is responsible for setting:
 1. `BSP_${BOARD}`
 2. `BITSTREAM_${BOARD}`
 3. `STAGE4_PACKAGES_${BOARD}`

`${BOARD}` must be the same as the name of the folder containing the spec file.
This will also ultimately be the value of the $BOARD environment variable in
the final image.

### Boot files

All boot files are created using Petalinux based on a provided BSP

## Porting to a new board

The main prerequisite for porting to a new board is the existance of a
Petalinux BSP for the board targeting version 2017.4. Other versions may work
but haven't been tested. Petalinux BSPs can be created from an HDF file using
the following commands:

 1. `petalinux-create -t project --template zynq|zynqmp --name <project name>`
 2. `cd <project name>`
 3. `petalinux-config --get-hw-description <HDF file>`
 4. `petalinux-package --bsp -o <BSP file>`

This will use the default options for all of the settings which should be
sufficient to get the board booted. For more details about customising the
boot files please refer to the Petalinux documentation.

Next create folder to act as a board repository - `my_boards` in this example -
and create a subfolder to hold the spec for the board you are porting to -
`my_boards/my_board`. Copy the BSP into the folder along with a boot bitstream
to use. The final stage is to create a spec file - by convention
`my_board.spec`. This will set make variables for the board as follow:

```Makefile
BSP_myboard := myboard.bsp
BITSTREAM_myboard := myboard.bit
# Optionally install some additional packages
STAGE4_PACKAGES_myboard := my_package
```

Custom packages can be placed in a `packages` subfolder of the and will be
picked up automatically if referenced. This is a convient way of installing
custom notebooks or Python packages if desired for your board.

# Custom Ubuntu Repository

By default the sdbuild flow will pull from https://ports.ubuntu.com. This can
be changed by setting the `PYNQ_UBUNTU_REPO` environment variable. The
repository link in the final image will remain unchanged.
