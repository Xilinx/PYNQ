.. _pynq-sd-card:

************
PYNQ SD Card
************

The PYNQ image for supported boards are provided precompiled as 
downloadable SD card images, so you do not need to rerun this flow for these 
boards unless you want to make changes to the image flow.

This flow can also be used as a starting point to build a PYNQ image for another
Zynq / Zynq Ultrascale board.

The image flow will create the BOOT.bin, the u-boot bootloader, the Linux
Device tree blob, and the Linux kernel.

The source files for the PYNQ image flow build can be found here:

.. code-block:: console
    
   <PYNQ repository>/sdbuild

More details on configuring the root filesystem can be found in the README file
in the folder above.

Prepare the Building Environment
================================

It is recommended to use a Ubuntu OS to build the image. If you do not have a 
Ubuntu OS, you may need to prepare a Ubuntu virtual machine (VM) on your host OS.
We provide in our repository a *vagrant* file that can help you install the 
Ubuntu VM on your host OS.

If you do not have a Ubuntu OS, and you need a Ubuntu VM, do the following:

  1. Download the `vagrant software <https://www.vagrantup.com/>`_ and the 
     `Virtual Box <https://www.virtualbox.org/>`_. Install them on your host OS.
  2. In your host OS, open a terminal program. Locate your PYNQ repository, 
     where the vagrant file is stored.

     .. code-block:: console
    
        cd <PYNQ repository>

  3. (optional) Depending on your Virtual Box configurations, you may 
     need to run the following command first; it may help you get better 
     screen resolution for your Ubuntu VM.

     .. code-block:: console

	vagrant plugin install vagrant-vbguest

  4. You can then prepare the VM using the following command. This step will
     prepare a Ubuntu VM called *pynq_vm* on your Virtual Box. For this VM,
     username and password are both defaulted to *vagrant*. The Ubuntu 
     packages on the VM will be updated during this process; the Ubuntu desktop 
     will also be installed so you can install Xilinx software later.

     .. code-block:: console
    
        vagrant up

     After the VM has been successfully loaded, you will see a folder
     */pynq* on your VM; this folder is shared with your PYNQ repository on 
     your host OS.
  5. (optional) To restart the VM without losing the shared folder, in your 
     terminal, run:

     .. code-block:: console
    
        vagrant reload

  6. Now you are ready to install Xilinx tools. You will need 
     PetaLinux, Vivado, and SDK for building PYNQ image.
     Starting from image v2.5, SDx is no longer needed.
     The version of Xilinx tools for each PYNQ release is shown below:

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
     ================  ================

If you already have a Ubuntu OS, you can do the following:

  1. Install dependencies using the following script. This is necessary 
     if you are not using our vagrant file to prepare the environment.

     .. code-block:: console
    
        <PYNQ repository>/sdbuild/scripts/setup_host.sh

  2. Install correct version of the Xilinx tools, including 
     PetaLinux, Vivado, and SDK. See the above table for the correct version 
     of each release.

Building the Image
==================

Once you have the building environment ready, you can start to build the image 
following the steps below. You don't have to rerun the `setup_host.sh`.

  1. Export PATH and source the appropriate settings for PetaLinux, Vivado, 
     and SDK. Suppose you are using Xilinx 2018.3 tools:

     .. code-block:: console
         
	export PATH="/opt/crosstool-ng/bin:/opt/qemu/bin:$PATH"
	source <path-to-vivado>/Vivado/2018.3/settings64.sh
	source <path-to-sdk>/SDK/2018.3/settings64.sh
	source <path-to-petalinux>/petalinux-v2018.3-final/settings.sh
	petalinux-util --webtalk off

     Currently the SD build flow is checking the PetaLinux path for the 
     version number, so please make sure the version number appears 
     in your installation path of Petalinux.
     In the above commands, the SD build flow will recognize the Petalinux
     version number as 2018.3.

  2. Navigate to the following directory and run make

     .. code-block:: console
    
        cd <PYNQ repository>/sdbuild/
        make

The build flow can take several hours. By default images for all of the
supported boards will be built.

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

where ``${BOARD}`` is also the name of the board. The ARCH should be *arm* for
Zynq-7000 or *aarch64* for Zynq UltraScale+. If no bitstream is provided then the
one included in the BSP will be used by default.  All paths in this file
should be relative to the board directory.

To customise the BSP a ``petalinux_bsp`` folder can be included in the board
directory the contents of which will be added to the provided BSP before the
project is created. See the ZCU104 for an example of this in action. This is
designed to allow for additional drivers, kernel or boot-file patches and
device tree configuration that are helpful to support elements of PYNQ to be
added to a pre-existing BSP.

If a suitable PetaLinux BSP is unavailable for the board then this can be left
blank; in this case, an HDF file needs to be provided in the board directory. 
The *system.hdf* file should be placed in the ``petalinux_bsp/hardware_project`` 
folder and a new generic BSP will be created as part of the build flow.

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

To build from a third-party board repository pass the ``${BOARDDIR}`` variable to the
sdbuild makefile.

.. code-block:: console
    
   cd <PYNQ repository>/sdbuild/
   make BOARDDIR=${BOARD_REPO}

The board repo should be provided as an absolute path. The ``${BOARDDIR}`` variable
can be combined with the ``${BOARD}`` variable if the repository contains multiple
boards and only a subset should be built.
