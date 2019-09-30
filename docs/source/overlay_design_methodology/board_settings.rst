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
creating a new project in Vivado. For most of the Xilinx boards (for example,
ZCU104), the board files have already been included in Vivado; users can 
simply choose the corresponding board when they create a new project. 
For some other boards (for example, Pynq-Z1 and Pynq-Z2), 
the corresponding board files can be downloaded as shown below.

* `Download the Pynq-Z1 board files
  <https://github.com/cathalmccabe/pynq-z1_board_files/raw/master/pynq-z1.zip>`_
* `Download the Pynq-Z2 board files
  <https://d2m32eurp10079.cloudfront.net/Download/pynq-z2.zip>`_
  
Installing these files in Vivado allows the board to be selected when creating
a new project. This will configure the Zynq PS settings.

To install the board files, extract, and copy the board files folder to:

   .. code-block:: console

      <Xilinx installation directory>\Vivado\<version>\data\boards

If Vivado is open, it must be restart to load in the new project files before a
new project can be created.


XDC constraints file
--------------------

Please see below for a list of constraint files.

* `Download the Pynq-Z1 Master XDC constraints
  <https://reference.digilentinc.com/_media/reference/programmable-logic/pynq-z1/pynq-z1_c.zip>`_

* `Download the Pynq-Z2 Master XDC constraints
  <http://www.tul.com.tw/download/PYNQ-Z2_v1.0.xdc.zip>`_



