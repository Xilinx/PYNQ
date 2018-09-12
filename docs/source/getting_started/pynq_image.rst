.. _pynq-image:

**********
PYNQ image
**********

Pre-compiled images
-------------------

Pre-compiled images for supported boards can be found via the 
`PYNQ boards <http://www.pynq.io/board.html>`_ page.

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

