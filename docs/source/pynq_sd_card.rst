************
PYNQ SD Card
************

The source files for the PYNQ image flow build can be found here:

   ``<GitHub repository>/sdbuild``

Check the readme in this directory for detailed instructions about the Image
flow build.

The PYNQ image for the PYNQ-Z1 is provided precompiled as a downloadable SD card
image, so you do not need to rerun this flow for the PYNQ-Z1 unless you want to
make changes to the image flow.

This flow can also be used as a starting point to build a PYNQ image for another
Zynq board.

The image flow will create the Zynq Boot.bin, the Linux Device tree blob, and
the Linux kernel.

Building the Image
==================

It is recommended to use a Virtual machine to run the image build flow. Root
permissions are required, and the flow has been tested on Ubuntu 16.04.  Vivado
and SDK 2016.1 must be installed.

Run the following script to install the required packages onto the host.

   ``<GitHub repository>/sdbuild/scripts/setup_host.sh``

Once the host has been set up, source the settings for Vivado and SDK, and run
make. The build flow can take several hours.


Retargeting to a different board
================================

To build the PYNQ image for another Zynq board the board configuration must be
modified. The configuration settings for the board are defined in the Zynq PS
settings. The settings for the memory device, and the Zynq PS peripherals must
be specified. The clock settings to the Zynq PL can also be modified.

Board specific files can be found here:

   ``<GitHub repository>/PYNQ/sdbuild/boot_configs``

In the PYNQ image flow, the script ``create_zynq_hdf.tcl`` is used to create a
Vivado project and generate the HDF file which includes the board specific
settings. The HDF is then used to create the Linux device tree.

The ``create_zynq_hdf.tcl`` script calls a board specific script
``boot_configs/`<board>-defconfig/ps7_config.tcl`` which contains the settings
for the Zynq PS.

To target a different board, an updated HDF file is required. The existing .tcl
files can be modified with updated settings for the Zynq PS, or a new project
can be created using the Vivado GUI, and used to export the HDF file.

PYNQ also expects a base.bit as the default overlay for a board, and it
downloads this bitstream to the Zynq PL at boot time.

The bitstream is specified here:

   ``<GitHub repository>/sdbuild/boot_configs/common/Zynq7000.makefile``

Any overlay can be used as the default for a new image, but the file must be
called ``base.bit``

This variable in the ``Zynq7000.makefile`` can be updated to point to the new
location of the bitstream

.. code-block:: console

   BOOT_BITSTREAM ?= ${WORKDIR}/PYNQ/boards/${BOARD}/base/base.bit
