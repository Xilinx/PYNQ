**************************
What's New
**************************

.. contents:: Table of Contents
   :depth: 2
   
v1.4 PYNQ image
===============================

The latest PYNQ image for the Pynq-Z1 is available here: 

* `Download the v1.4 PYNQ-Z1 2016_02_10 image <https://files.digilent.com/Products/PYNQ/pynq_z1_image_2016_02_10.zip>`_

This image corresponds to the `v1.4 tag branch on the Pynq GitHub repository <https://github.com/Xilinx/PYNQ/tree/v1.4>`_.

This version of the documentation refers to the new image. The previous version of the documentation, corresponding to the previous image release, can be accessed from the ReadTheDocs version menu. 

In almost all cases, Python and IOP code developed for previous Pynq versions should be forwards compatible with the current image. 

Summary of updates
-----------------------

* The Xilinx Linux kernel has been upgraded to 4.6.0.
* Python has been updated to 3.6.
* The Jupyter Notebook Extension has been added.
* The base overlay has been updated to include an interrupt controller from the IOPs to the Zynq PS.
* The IOPs have a direct interface to DRAM. 
* The IOPs in the base overlay have an interrupt controller connected to the local peripherals in the IOP. 
* The ``asyncio`` python package has been added and can be used to manage interrupts from an overlay
* The GPIO of the Arduino IOP has been modified 
* The tracebuffer, video and PL APIs have been improved. 
* Additional Pmod drivers added
* Additional Linux drivers added
* Linux library updates, and other bug fixes.

For a more complete list of changes, see the `Pynq changelog <changelog.html>`_

