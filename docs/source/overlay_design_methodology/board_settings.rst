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


Vivado board files
------------------

Vivado board files contain the configuration for a board that is required when
creating a new project in Vivado.

* `Download the PYNQ-Z1 board files
  <https://github.com/cathalmccabe/pynq-z1_board_files/raw/master/pynq-z1.zip>`_
* `Download the PYNQ-Z2 board files
  <http://www.tul.com.tw/download/PYNQ-Z2_board_file_v1.0.zip>`_
  
Installing these files in Vivado, allows the board to be selected when creating
a new project. This will configure the Zynq PS settings.

To install the board files, extract, and copy the board files folder to:

   .. code-block:: console

      <Xilinx installation directory>\Vivado\<version>\data\boards

If Vivado is open, it must be restart to load in the new project files before a
new project can be created.


XDC constraints file
--------------------

* `Download the PYNQ-Z1 Master XDC constraints
  <https://reference.digilentinc.com/_media/reference/programmable-logic/pynq-z1/pynq-z1_c.zip>`_

* `Download the PYNQ-Z2 Master XDC constraints
  <http://www.tul.com.tw/download/PYNQ-Z2_v1.0.xdc.zip>`_



