.. _pynq-image:

**********
PYNQ image
**********

PYNQ is delivered as a bootable image that can be written to an SD card or
other media and used to boot the board.

Supported boards
----------------

Pre-compiled images are available for the following boards and can be used
to make a bootable MicroSD card:

=========================== =========================================================================================
 Board                       Download PYNQ image                                                                   
=========================== =========================================================================================
 Pynq-Z1 board (Digilent)    `Pynq-Z1 v2.1 image <http://files.digilent.com/Products/PYNQ/pynq_z1_v2.1.img.zip>`_  
 Pynq-Z2 board (TUL)         `Pynq-Z2 v2.2 image <http://www.tul.com.tw/download/pynq_z2_image_2018_04_24.img.zip>`_ 
=========================== =========================================================================================

If you already have a MicroSD card preloaded with a PYNQ image for your
board, you don't need to rewrite it unless you want to restore or update your
image 
to a new version of PYNQ.

To write a PYNQ image, see the instructions below for :ref:`write-sd-card`.

Other boards
------------

To use PYNQ with other Zynq boards, a PYNQ image is required. 

If a PYNQ image is not already available for your board, you will need to build
it yourself. You can do this by following the :ref:`pynq-sd-card` guide. 

You will need to setup and boot your board yourself, and setup a network 
connection to your computer to start using Jupyter. Once you do this, you can 
return to the :ref:`connecting-to-jupyter-notebook` instructions.

.. _write-sd-card:

MicroSD Card Setup
------------------

To make your own PYNQ Micro-SD card:

  1. Download the appropriate PYNQ image for your board
  2. Unzip the image 
  3. Write the image to a blank Micro SD card (minimum 8GB recommended)
   
For detailed instructions on writing the SD card using different operating
systems, see :ref:`writing-the-sd-card`.

