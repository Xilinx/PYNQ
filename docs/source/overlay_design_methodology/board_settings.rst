Board Settings
==============

For information on the board, see the `Digilent PYNQ-Z1 webpage
<https://reference.digilentinc.com/reference/programmable-logic/pynq-z1/start>`_

Base overlay project
--------------------

The source files for the *base* overlay can be found in the PYNQ GitHub. The
project can be rebuilt using the makefile/TCL available here:

   .. code-block:: console

      <GitHub repository>/boards/Pynq-Z1/base
      
The base design can be used as a starting point to create a new design.


Vivado board files
------------------

Vivado board files contain the configuration for a board that is required when
creating a new project in Vivado.

* `Download the PYNQ-Z1 board files
  <https://github.com/cathalmccabe/pynq-z1_board_files/raw/master/pynq-z1.zip>`_

Installing these files in Vivado, allows the board to be selected when creating
a new project. This will configure the Zynq PS settings for the PYNQ-Z1.

To install the board files, extract, and copy the board files folder to:

   .. code-block:: console

      <Xilinx installation directory>\Vivado\<version>\data\boards

If Vivado is open, it must be restart to load in the new project files before a
new project can be created.


Pynq-Z1 XDC constraints file
----------------------------

* `Download the PYNQ-Z1 Master XDC constraints
  <https://reference.digilentinc.com/_media/reference/programmable-logic/pynq-z1/pynq-z1_c.zip>`_



