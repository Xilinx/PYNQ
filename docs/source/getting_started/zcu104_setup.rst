.. _ZCU104-setup:

*******************
ZCU104 Setup Guide
*******************
     
Prerequisites
=============

  * `ZCU104 board <https://www.xilinx.com/products/boards-and-kits/zcu104.html>`_
  * Computer with compatible browser (`Supported Browsers
    <http://jupyter-notebook.readthedocs.org/en/latest/notebook.html#browser-compatibility>`_)
  * Ethernet cable
  * Micro USB cable (optional)
  * Micro-SD card with preloaded image, or blank card (Minimum 8GB recommended)
  
Getting Started Video
=====================

You can watch the getting started video guide, or follow the instructions in
:ref:`ZCU104-board-setup`.

.. raw:: html

    <embed>
         <iframe width="560" height="315" src="https://www.youtube.com/embed/emXEmVONk0Q" frameborder="0" allowfullscreen></iframe>
         </br>
         </br>
    </embed>

.. _ZCU104-board-setup:

Board Setup
===========

   .. image:: ../images/zcu104_setup.png
      :align: center

  1. Set the **Boot** Dip Switches (SW6) to the following positions:

     (This sets the board to boot from the Micro-SD card)

     * Dip switch 1 (Mode 0): On (down position in diagram)
     * Dip switch 2 (Mode 1): Off (up position in diagram)
     * Dip switch 3 (Mode 2): Off (up)
     * Dip switch 4 (Mode 3): Off (up)

  2. Connect the 12V power cable. Note that the connector is keyed and can only
     be connected in one way. 

  3. Insert the Micro SD card loaded with the appropriate PYNQ image into the 
     **MicroSD** card slot underneath the board

  4. (Optional) Connect the USB cable to your PC/Laptop, and to the 
     **USB JTAG UART** MicroUSB port on the board

  5. Connect the Ethernet port by following the instructions below

  6. Turn on the board and check the boot sequence by following the instructions
     below

.. _turning-on-the-ZCU104:

Turning On the ZCU104
----------------------

As indicated in step 6, slide the power switch to the *ON* position to turn on
the board. A **Red** LED and some additional yellow board LEDs will come on to
confirm that the board has power.  After a few seconds, the red LED will 
change to **Yellow**. This indicates that the bitstream has been downloaded
and the system is booting. 

.. include:: network_connection.rst

.. include:: pynq_sdcard_getting_started.rst
