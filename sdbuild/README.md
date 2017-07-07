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
   are forward correctly. For EC2 images this is already done for you.
 * Run `scripts/setup_host.sh`
 * Install Vivado and SDK 2016.1
 * Source the Vivado and SDK settings files
 * Run `make`
 * Wait for a few hours

## Detailed host setup

The `setup_host.sh` script install a set of packages required either for Vivado
or the other build tools. It installs crosstool-ng which is not included in the
ubuntu repository and an up-to-date version of QEMU which fixes some race
conditions in the ubuntu-shipped version. See the source of the script for more
details in what exactly needs to be done to configure your own environment if
the script proves insufficient.

## Parts of an image build

### Releases

The complete configuration for an image is termed a *release* and generally
consists of a boot configuration and a root filesystem configuration. All
releases exist in the `releases` folder and have the extension `.config`. By
default an image for the Pynq-Z1 board will be created as it is the primary
platform for the project. The main aim of the release is to set the
`BOOT_CONFIG` and `ROOTFS_CONFIG` variables and overload any defaults if
desired.

### Boot configurations

The files for generating the boot files live inside of `boot_configs` with each
config being a separate directory containing a `config` file. The config file
is responsible for creating a set of `${BOOT_FILES}` which will later be copied
on to the boot partition. It can also create a `${KERNEL_DEB}` variable which
will be installed as part of the root filesystem. The code generic to all
Zynq-7000 designed is separated out into a separate makefile for re-use between
multiple boards.

### Root filesystem configurations

A root filesystem configuration consists of a directory containing a `config`
file  living the `rootfs_configs` directory. The config file is responsible for
setting the multistrap configuration to be used to generate the initial
filesystem, a set of *patch sets* to apply to configure the image and a series
of *packages* to install. Packages are split into two stages - stage one
packages are expected to static during a development cycle whereas stage two
packages are more fluid. For example the `pynq` package is almost always a
stage two package. This allows for fast iterations of new image releases while
testing. All packages are installed in the order listed, beginning with stage
one packages.

### Patch sets

Patch sets live in the `patchsets` directory and consist of a hierarchy of
directories that correspond to the root filesystem. A patch should be in a diff
format and named as per the file to patched but with a .diff extension.
Multiple patch sets can be applied when building an image.

### Packages

Packages form the core of the image flow and each consists of up to four files,
all of which are optional:

1. A `Makefile` which adds to the `PACKAGE_BUILD` variable any targets that are
   required. This should be used for downloading or compiling files that can be
   done on the host
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
location specified by `$WORKDIR` for all temporary files. This is also the
recommend place for the makefile to deposit files for the bash scripts to
subsequently use.

## Flow optimisation

To try and make the process slightly less laborious a few optimisation speed up
the time to create the image. First is relying on make to avoid regenerating
files unnecessarily. Secondly the root filesystem creation processing is split
into three stages. The first stage uses multistrap to build the initial system
and applies the patch sets. The second and third stage then install packages.
The image is checkpointed after each stage so that only a subset needs to be
rerun in most cases. Finally `ccache` is used to cache the results of
compilation in the image when the image is re-built in the same source folder.

## Porting to a new board

The main thing required when porting to a new Zynq-7000 board is to provide an
updated set of boot files and ensuring that the version of the pynq repository
builds with that board. Zynq Ultrascale Plus support is currently being
considered.
