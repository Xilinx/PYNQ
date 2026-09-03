Board Settings
==============

Base overlay project
--------------------

The source files for the *base* overlay for supported boards can be found in
the PYNQ GitHub. The project can be rebuilt using the makefile/TCL available
here:

   .. code-block:: console

      <GitHub repository>/boards/<board>/base
      
The base design can be used as a starting point to create a new design.

The VCK190 uses segmented configuration. Build
``boards/VCK190/golden`` before ``boards/VCK190/base`` so that the overlay is
compatible with the boot image.


Vivado board files
------------------

Vivado board files contain the configuration required when creating a project
for a board. The ZCU104 and VCK190 board files are included with Vivado and can
be selected when creating a project.

Boards that are not shipped with Vivado, for example the RFSoC 4x2 used by
RFSoC-PYNQ, supply their own board files. Extract them and copy the board files
folder to:

   .. code-block:: console

      <Xilinx installation directory>/Vivado/<version>/data/xhub/boards/XilinxBoardStore/boards/Xilinx/

Installing the files allows the board to be selected when creating a new
project, which applies the processing system settings for that board. If Vivado
is already open it must be restarted before the new board files can be used.


XDC constraints file
--------------------

Constraint files and board documentation are available from the
`ZCU104 <https://www.amd.com/en/products/adaptive-socs-and-fpgas/evaluation-boards/zcu104.html>`_
and
`VCK190 <https://www.amd.com/en/products/adaptive-socs-and-fpgas/evaluation-boards/vck190.html>`_
board pages.



