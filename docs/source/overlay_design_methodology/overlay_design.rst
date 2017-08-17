Overlay Design
==============

An overlay consists of two main parts; the PL design (bitstream) and the project
block diagram Tcl file. Overlay design is a specialized task for hardware
engineers. This section assumes the reader has some experience with digital
design, building Zynq systems, and with the Vivado design tools.

PL Design
---------

The Xilinx® Vivado software is used to create a Zynq design. A *bitstream* or
*binary* file (.bit file) will be generated that can be used to program the Zynq
PL.

A free WebPack version of Vivado is available to build overlays.
https://www.xilinx.com/products/design-tools/vivado/vivado-webpack.html

The hardware designer is encouraged to support programmability in the IP used in
a PYNQ overlays. Once the IP has been created, the PL design is carried out in
the same way as any other Zynq design. IP in an overlay that can be controlled
by PYNQ will be memory mapped, connected to GPIO. IP may also have a master
connection to the PL. PYNQ provides Python libraries to interface to the PL
design and which can be used to create their own drivers. The Python API for an
overlay will be and will be covered in the next sections.

Overlay Tcl file
----------------

The Tcl from the Vivado IP Integrator block design for the PL design is used by
PYNQ to automatically identify the Zynq system configuration, IP including
versions, interrupts, resets, and other control signals. Based on this
information, some parts of the system configuration can be automatically
modified from PYNQ, drivers can be automatically assigned, features can be
enabled or disabled, and signals can be connected to corresponding Python
methods.

The Tcl file must be generated and provided with the bitstream file as part of
an overlay. The Tcl file can be generated in Vivado by *exporting* the IP
Integrator block diagram at the end of the overlay design process. The Tcl file
should be provided with a bitstream when downloading an overlay. The PYNQ PL
class will automatically parse the Tcl.

A custom, or manually created Tcl file can be used to build a Vivado project,
but Vivado should be used to generate and export the Tcl file for the block
diagram. This automatically generated Tcl should ensure that it can be parsed
correctly by the PYNQ.

To generate the Tcl for the Block Diagram from the Vivado GUI:

   * Click **File > Export > Block Design**  

Or, run the following in the Tcl console:

.. code-block:: console

   write_bd_tcl
      
The Tcl filename should match the .bit filename. For example, `my_overlay.bit` 
and `my_overlay.tcl`.

The Tcl is parsed when the overlay is instantiated and downloaded. 

.. code-block:: python

   from pynq import Overlay
   ol = Overlay("base.bit") # Tcl is parsed here

   
An error will be displayed if a Tcl is not available when attempting to download
an overlay, or if the Tcl filename does not match the .bit file name.


Programmability
---------------

An overlay should have post-bitstream programmability to allow customization of
the system. A number of reusable PYNQ IP blocks are available to support
programmability. For example, a PYNQ MicroBlaze can be used on Pmod, and Arduino
interfaces. IP from the various overlays can be reused to provide run-time
configurability.


Zynq PS Settings
----------------

A Vivado project for a Zynq design consists of two parts; the PL design, and the
PS configuration settings.

The PYNQ image which is used to boot the board configures the Zynq PS at boot
time. This will fix most of the PS configuration, including setup of DRAM, and
enabling of the Zynq PS peripherals, including SD card, Ethernet, USB and UART
which are used by PYNQ.

The PS configuration also includes settings for system clocks, including the
clocks used in the PL. The PL clocks can be programmed at runtime to match the
requirements of the overlay. This is managed automatically by the PYNQ Overlay
class.

During the process of downloading a new overlay, the clock configuration will be
parsed from the overlay's Tcl file. The new clock settings for the overlay will
be applied automatically before the overlay is downloaded.


Existing Overlays
-----------------

Existing overlays can be used as a starting point to create a new overlay. The
*base* overlay can be found in the *boards* directory in the PYNQ repository,
and includes reference IP for peripherals on the board:

   ``<PYNQ repository>/boards/Pynq-Z1/base``
  
A makefile exists in each folder that can be used to rebuild the Vivado project
and generate the bitstream and Tcl for the overlay. (On windows, instead of
using *make*, the Tcl file can be sourced from Vivado.)

The bitstream and Tcl for the overlay are available on the board, and also in
the GitHub project repository:

   ``<PYNQ repository>/boards/Pynq-Z1/base``

