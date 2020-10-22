.. _pynq-sd-card:

************
PYNQ SD Card
************

The PYNQ images for supported boards are provided precompiled as 
downloadable SD card images, so you do not need to rerun this flow for these 
boards unless you want to make changes to the image.

This flow can also be used as a starting point to build a PYNQ image for another
Zynq / Zynq Ultrascale+ board.

The image flow will create the BOOT.bin, the u-boot bootloader, the Linux
Device tree blob, and the Linux kernel.

The source files for the PYNQ image flow build can be found here:

.. code-block:: console
    
   <PYNQ repository>/sdbuild

More details on configuring the root filesystem can be found in the README file
in the folder above.

Prepare the Building Environment
================================

It is recommended to use a Ubuntu OS to build the image. The currently supported Ubuntu OS are listed below:

================  ==================
Supported OS      Code name
================  ==================   
Ubuntu 16.04       xenial
Ubuntu 18.04       bionic
================  ==================

Use Vagrant to prepare Ubuntu OS
--------------------------------
If you do not have a Ubuntu OS, you may need to prepare a Ubuntu virtual 
machine (VM) on your host OS. We provide in our repository a *vagrant* file 
that can help you install the Ubuntu VM on your host OS.

If you do not have a Ubuntu OS, and you need a Ubuntu VM, do the following:

  1. Download the `vagrant software <https://www.vagrantup.com/>`_ and 
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
     prepare a Ubuntu VM called *pynq_ubuntu_<version>* on your Virtual Box.
     The Ubuntu packages on the VM will be updated during this process; 
     the Ubuntu desktop will also be installed so you can install Xilinx 
     software later.

     .. code-block:: console
    
        vagrant up

     The above command will take about 20 minutes to finish.
     By default, our vagrant file will prepare a Ubuntu 16.04 OS. If you would
     like to use another OS, do:
     
     .. code-block:: console
    
        vagrant up <ubuntu_code_name>

     For example, you can do the following to prepare a Ubuntu 18.04 OS:
     
     .. code-block:: console
    
        vagrant up bionic

     The supported OS and their corresponding code names are listed in the 
     beginning of this section.

  5. In the end, you will see a Virtual Box window popped up with only shell 
     terminal, asking for your Ubuntu login information. 
     Ignore this window and close it. Run the following command on your host:
     
     .. code-block:: console
    
        vagrant reload <ubuntu_code_name>
     
     After running the above command, you will be asked to log onto your 
     Ubuntu desktop. The username and password are both defaulted to *vagrant*.
     The current working directory on your host machine will be shared with 
     */pynq* on your VM. Always use *vagrant reload* command to reboot the VM;
     otherwise vagrant has no clue whether the VM has been rebooted, and users
     will not be able to see shared folder.

  6. (optional) You can enable bidirectional clipboard between your host and 
     your VM in your Virtual Box settings:

     .. image:: ./images/bidirectional-clipboard.png
        :width: 400

  7. Now you are ready to install Xilinx tools. You will need 
     PetaLinux, Vivado, and Vitis for building PYNQ image.
     Do not install Xilinx tools into */pynq* since it is only a small shared
     folder. Instead, a 160GB disk space will be allocated at */workspace*
     folder in VM. Install Xilinx tools there.
     
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
     v2.6               2020.1
     ================  ================

Use existing Ubuntu OS
----------------------
If you already have a Ubuntu OS, and it is listed in the beginning of
this section, you can simply do the following:

  1. Install dependencies using the following script. This is necessary 
     if you are not using our vagrant file to prepare the environment.

     .. code-block:: console
    
        <PYNQ repository>/sdbuild/scripts/setup_host.sh

  2. Install correct version of the Xilinx tools, including 
     PetaLinux, Vivado, and Vitis. See the above table for the correct version 
     of each release.

Building the Image
==================

Once you have the building environment ready, you can start to build the image 
following the steps below. You don't have to rerun the `setup_host.sh`.

  1. Source the appropriate settings for PetaLinux and Vitis. 
     Suppose you are using Xilinx 2020.1 tools:

     .. code-block:: console

        source <path-to-vitis>/Vitis/2020.1/settings64.sh
        source <path-to-petalinux>/petalinux-2020.1-final/settings.sh
        petalinux-util --webtalk off

  2. Make sure you have the appropriate Vivado licenses to build for your
     target board, especially 
     `HDMI IP <https://www.xilinx.com/products/intellectual-property/hdmi.html>`_. 

  3. Navigate to the following directory and run make

     .. code-block:: console
    
        cd <PYNQ repository>/sdbuild/
        make

The build flow can take several hours. By default images for all of the
supported boards will be built.

Using the prebuilt board-agnostic image
---------------------------------------
In order to simplify and speed-up the image building process, you can re-use the 
prebuilt board-agnostic image appropriate to the architecture - arm for Zynq-7000 
and aarch64 for Zynq UltraScale+, downloadable at the 
`boards page <http://www.pynq.io/board.html/>`_ of our website. This will allow 
you to completely skip the board-agnostic stage. It is important to notice however
that this will restrict the build process to only boards that share the same
architecture. You can do so by passing the ``PREBUILT`` variable when invoking make:

.. code-block:: console
    
   cd <PYNQ repository>/sdbuild/
   make PREBUILT=<image path> BOARDS=<board>

Re-use the PYNQ source distribution tarball
-------------------------------------------
To avoid rebuilding the PYNQ source distribution package, and consequently bypass
the need to build bitstreams (except for external boards) and MicroBlazes' bsps 
and binaries, a prebuilt PYNQ sdist tarball can be reused by specifying the 
``PYNQ_SDIST`` variable when invoking make. The tarball specific to the target
PYNQ version will be distributed when a new version is released on 
`GitHub <https://github.com/Xilinx/PYNQ/releases>`_.

.. code-block:: console
    
   cd <PYNQ repository>/sdbuild/
   make PYNQ_SDIST=<sdist tarball path>


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

To build from a third-party board repository pass the ``${BOARDDIR}`` variable to the
sdbuild makefile.

.. code-block:: console
    
   cd <PYNQ repository>/sdbuild/
   make BOARDDIR=${BOARD_REPO}

The board repo should be provided as an absolute path. The ``${BOARDDIR}`` variable
can be combined with the ``${BOARD}`` variable if the repository contains multiple
boards and only a subset should be built.
