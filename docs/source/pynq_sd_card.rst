.. _pynq-sd-card:

******************
PYNQ SD Card image
******************

This page will explain how SD card images can be built for PYNQ
embedded platforms (Zynq, Zynq Ultrascale+, Zynq RFSoC). 

Note: the PYNQ images for supported boards are provided as precompiled 
`downloadable SD card images <https://www.pynq.io/boards.html>`_ and do 
not need rebuilt.  The SD card build flow is
only required to modify SD cards' contents or target a new board.

Specifically, The SD card build flow will create the BOOT.bin, the u-boot
bootloader, the Linux Device tree blob, the Linux kernel and the
PYNQ-Linux root filesystem.

The source files for the PYNQ image flow build can be found here:

.. code-block:: console
    
   <PYNQ repository>/sdbuild

More details on configuring the root filesystem can be found in the README file
in the folder above.

Prepare the Building Environment
================================

It is recommended to use a Ubuntu OS to build the image. The currently supported
Ubuntu OS are listed below:

================  ==================
Supported OS      Code name
================  ==================   
Ubuntu 22.04       Jammy
================  ==================

Use Docker to prepare the build environment
-------------------------------------------
Starting with the PYNQ v3.1 release, Docker is the recommended way to build PYNQ images. 
Docker simplifies setup by managing dependencies and environment configuration within an 
isolated container.

If you do not have a supported Ubuntu machine, you can use Docker to create an isolated 
build environment on your host OS using the following steps:

  1. Install Docker on your host OS by following the 
     `official Docker installation instructions <https://docs.docker.com/engine/install/>`_.

  2. Install the required AMD tools on your host OS (not inside Docker):
     
     * **Vivado**, **Vitis**, and **PetaLinux**, version 2024.1
     * Ensure your host OS is supported by the AMD tools (see 
       `UG973 <https://docs.amd.com/r/2024.1-English/ug973-vivado-release-notes-install-license/Supported-Operating-Systems>`_)

     .. note::
        AMD tools must be installed on the host system, not inside the Docker container.

  3. Clone the PYNQ repository and in a bash shell, build the Docker image:

     .. code-block:: console
    
        git clone --recursive https://github.com/Xilinx/PYNQ.git PYNQ
        cd PYNQ/sdbuild
        docker build \
          --build-arg USERNAME=$(whoami) \
          --build-arg USER_UID=$(id -u) \
          --build-arg USER_GID=$(id -g) \
          -t pynqdock:latest .

     If you are in a csh-like shell, switch to Bash by typing: ``bash``.

     The ``--build-arg`` values ensure that files created inside the container 
     will be owned by your user on the host system, avoiding permission issues.

  4. Run the Docker container, mounting your AMD tools and PYNQ repository:

     .. code-block:: console
    
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

     Replace ``/tools/Xilinx`` and ``/home/user/petalinux`` with the actual paths 
     to your Xilinx installations on the host system. The ``:ro`` option mounts 
     tool directories as read-only, and ``--privileged`` is required for parts of 
     the build process.

  5. Inside the container, set up the tool environment:

     .. code-block:: console
    
        source /tools/Xilinx/Vivado/2024.1/settings64.sh
        source /home/user/petalinux/settings.sh

     Adjust the paths to match your actual Xilinx tool installation paths.

  6. You are now ready to build PYNQ images inside the Docker container. 
     Navigate to the sdbuild directory and follow the building instructions 
     in the next section.


Use an existing Ubuntu OS
-------------------------
If you're not able to use Docker, you can still build PYNQ images on a supported Ubuntu OS.

If you already have a Ubuntu OS, and it is listed in the beginning of
this section, you can simply do the following:

  1. Install dependencies using the following script. This is necessary 
     if you are not using our vagrant file to prepare the environment.

     .. code-block:: console
    
        <PYNQ repository>/sdbuild/scripts/setup_host.sh

  2. Install correct version of the Xilinx tools, including 
     PetaLinux, Vivado, and Vitis. See the table below for the correct version 
     of each release.

     Starting from image v2.5, SDx is no longer needed.

     ================  ================
     Release version    Xilinx Tool Version
     ================  ================
     v1.4               2015.4
     v2.0               2016.1
     v2.1               2017.4
     v2.2               2017.4
     v2.3               2018.2
     v2.4               2018.3
     v2.5               2019.1
     v2.6               2020.1
     v2.7               2020.2
     v3.0               2022.1
     v3.1               2024.1
     ================  ================

Building the Image From Source
==============================

Once you have the build environment ready, you can build an SD card image 
following the steps below. You don't have to rerun the `setup_host.sh`.

  1. Source the appropriate settings for PetaLinux and Vitis. 
     Suppose you are using Xilinx 2024.1 tools:

     .. code-block:: console

        source <path-to-vitis>/Vitis/2024.1/settings64.sh
        source <path-to-petalinux>/petalinux-2024.1-final/settings.sh

  2. Depending on the overlays being rebuilt, make sure you have the appropriate
     Vivado licenses to build for your target board, especially the
     `HDMI IP <https://www.amd.com/en/products/adaptive-socs-and-fpgas/intellectual-property/hdmi.html>`_
     for the ZCU104 or the `CMAC IP <https://www.amd.com/en/products/adaptive-socs-and-fpgas/intellectual-property/cmac.html>`_
     for the RFSoC4x2.   

  3. Collect a prebuilt board-agnostic root filesystem tarball and a prebuilt PYNQ
     source distribution.  Starting in PYNQ v3.0, by default the SD card build
     flow expects a prebuilt root filesystem and a PYNQ source distribution to
     speedup and simplify user rebuilds of SD card images.  These binaries can be
     found at `the PYNQ boards page <https://www.pynq.io/boards.html>`_ and
     copied into the sdbuild prebuilt folder

     .. code-block:: console

	# For rebuilding all SD cards, both arm and aarch64 root filesystems
	# may be required depending on boards being targetted.
        cp pynq_rootfs.<arm|aarch64>.tar.gz <PYNQ repository>/sdbuild/prebuilt/pynq_rootfs.<arm|aarch64>.tar.gz
	cp pynq-<version>.tar.gz            <PYNQ repository>/sdbuild/prebuilt/pynq_sdist.tar.gz
        

     
  4. Navigate to the following directory and run make

     .. code-block:: console
    
        cd <PYNQ repository>/sdbuild/
        make

The build flow can take several hours and will rebuild SD cards for the Pynq-Z1, Pynq-Z2
and ZCU104 platforms. 

Rebuilding the prebuilt board-agnostic image
--------------------------------------------
In order to simplify and speed-up the image building process, users should re-use the 
prebuilt board-agnostic image appropriate to the architecture - arm for Zynq-7000 
and aarch64 for Zynq UltraScale+, downloadable at the 
`boards page <https://www.pynq.io/boards.html>`_ of our website. This will allow 
you to completely skip the board-agnostic stage.

You can force a root filesystem build by setting the ``REBUILD_PYNQ_ROOTFS`` variable
when invoking make:

.. code-block:: console
    
   cd <PYNQ repository>/sdbuild/
   make REBUILD_PYNQ_ROOTFS=True BOARDS=<board>

Rebuilding the PYNQ source distribution tarball
-----------------------------------------------
To avoid rebuilding the PYNQ source distribution package, and consequently bypass
the need to build bitstreams for the PYNQ-Z1, PYNQ-Z2 and the
ZCU104, a prebuilt PYNQ sdist tarball should be reused as described in steps listed above.

You can force a PYNQ source distribution rebuild by setting the ``REBUILD_PYNQ_SDIST`` variable
when invoking make

.. code-block:: console
    
   cd <PYNQ repository>/sdbuild/
   make REBUILD_PYNQ_SDIST=True


Please also refer to the 
`sdbuild readme <https://github.com/Xilinx/PYNQ/blob/master/sdbuild/README.md>`_
on our GitHub repository for more info regarding the image-build flow.

Unmount images before building again
------------------------------------
Sometimes the SD image building process can error out, leaving mounted images
in your host OS. You need to unmount these images before trying the make
process again. Starting from image v2.6, users can do the following to
unmount the images.

.. code-block:: console
    
   cd <PYNQ repository>/sdbuild/
   make delete

The above command not only unmounts all the images, but also deletes the
failed images. This makes sure the users do not use the failed images when
continuing the SD build process.

To unmount images but not delete them, use the following command instead.

.. code-block:: console
    
   cd <PYNQ repository>/sdbuild/
   make unmount

If you want to ignore all the previous staged or cached SD build
artifacts and start from scratch again, you can use the following command.
This will unmount and delete the failed images, and remove all the previously
built images at different stages.

.. code-block:: console
    
   cd <PYNQ repository>/sdbuild/
   make clean


Retargeting to a Different Board
================================

Additional boards are supported through external *board repositories*. A board
repository consists of a directory for each board consisting of a spec file and
any other files. The board repository is treated the same way as the ``<PYNQ
repository>/boards`` directory.

Elements of the specification file
----------------------------------

The specification file should be name ``<BOARD>.spec`` where BOARD is the name
of the board directory. A minimal spec file contains the following information

.. code-block:: makefile

   ARCH_${BOARD} := arm
   BSP_${BOARD} := mybsp.bsp
   BITSTREAM_${BOARD} := mybitstream.bsp
   FPGA_MANAGER_${BOARD} := 1

where ``${BOARD}`` is also the name of the board. The ARCH should be *arm* for
Zynq-7000 or *aarch64* for Zynq UltraScale+. If no bitstream is provided then the
one included in the BSP will be used by default. All paths in this file
should be relative to the board directory.

To customise the BSP a ``petalinux_bsp`` folder can be included in the board
directory the contents of which will be added to the provided BSP before the
project is created. See the ZCU104 for an example of this in action. This is
designed to allow for additional drivers, kernel or boot-file patches and
device tree configuration that are helpful to support elements of PYNQ to be
added to a pre-existing BSP.

If a suitable PetaLinux BSP is unavailable for the board then ``BSP_${BOARD}``
can be left blank; in this case, users have two options:

 1. Place a *<design_name>.xsa* file in the ``petalinux_bsp/hardware_project``
    folder. As part of the build flow, a new BSP will be created from
    this XSA file.
 2. Place a makefile along with tcl files which can generate the hardware
    design in the ``petalinux_bsp/hardware_project`` folder.
    As part of the build flow, the hardware design along with the XSA file
    will be generated, then a new BSP will be created from this XSA file.

Starting from image v2.6, we allow users to disable FPGA manager by setting
``FPGA_MANAGER_${BOARD}`` to 0. This may have many use cases. For example,
users may want the bitstream to be downloaded at boot to enable some
board components as early as possible. Another use case is that users want
to enable interrupt for XRT. The side effect of this, is that users
may not be able to reload a bitstream after boot.

If ``FPGA_MANAGER_${BOARD}`` is set to 1 or ``FPGA_MANAGER_${BOARD}`` is
not defined at all, FPGA manager will be enabled. In this case, the bitstream
will be downloaded later in user applications; and users can only use XRT
in polling mode. This is the default behavior of PYNQ since we want users
to be able to download any bitstream after boot.

Board-specific packages
-----------------------

A ``packages`` directory can be included in board directory with the same
layout as the ``<PYNQ repository>/sdbuild/packages`` directory. Each
subdirectory is a package that can optionally be installed as part of image
creation. See ``<PYNQ repository>/sdbuild/packages/README.md`` for a
description of the format of a PYNQ sdbuild package.

To add a package to the image you must also define a
``STAGE4_PACKAGE_${BOARD}`` variable in your spec file. These can either
packages in the standard sdbuild library or ones contained within the board
package. It is often useful to add the ``pynq`` package to this list which will
ensure that a customised PYNQ installation is included in your final image.

Leveraging ``boot.py`` to modify SD card boot behavior
------------------------------------------------------

Starting from the v2.6.0 release, PYNQ SD card images include a ``boot.py`` 
file in the boot partition that runs automatically after the board has been 
booted.  Whatever is inside this file runs during boot and can be modified 
any time for a custom next-boot behavior (e.g. changing the host name, 
connecting the board to WiFi, etc.). 

This file can be accessed using a SD Card reader on your host machine or 
from a running PYNQ board - if you are live on the board inside Linux, the 
file is located in the ``/boot`` folder.  Note that  ``/boot`` is the 
boot partition of the board and no other files should be modified.

If you see some existing code running inside the boot.py file, it probably came
from a PYNQ sdbuild package that modified that file.  To see an example of an
sdbuild package writing the boot.py file see the ZCU104's `boot_leds package 
<https://github.com/Xilinx/PYNQ/tree/image_v2.6.0/boards/ZCU104/packages/boot_leds>`_
which simply flashes the boards LEDs to signify Linux has booted on the board.

Using the PYNQ package
----------------------

The ``pynq`` package will treat your board directory the same as any of the
officially supported boards. This means, in particular, that:

 1. A ``notebooks`` folder, if it exists, will be copied into the
    ``jupyter_notebooks`` folder in the image. Notebooks here will overwrite any of
    the default ones.
 2. Any directory containing a bitstream will be treated as an overlay and
    copied into the overlays folder of the PYNQ installation. Any notebooks will
    likewise by installed in an overlay-specific subdirectory.


Building from a board repository
================================

To build from a third-party board repository, pass the ``BOARDDIR`` variable to the
sdbuild makefile.

.. code-block:: console
    
   cd <PYNQ repository>/sdbuild/
   make BOARDDIR=${BOARD_REPO}

The board repo should be provided as an absolute path. The ``BOARDDIR`` variable
can be combined with the ``BOARDS`` variable if the repository contains multiple
boards and only a subset should be built.
