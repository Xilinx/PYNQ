.. _pynq-z2-setup:

*******************
PYNQ-Z2 Setup Guide
*******************
     
Prerequisites
=============

  * PYNQ-Z2 board
  * Computer with compatible browser (`Supported Browsers
    <http://jupyter-notebook.readthedocs.org/en/latest/notebook.html#browser-compatibility>`_)
  * Ethernet cable
  * Micro USB cable 
  * Micro-SD card with preloaded image, or blank card (Minimum 8GB recommended)
  
Getting Started Video
=====================

You can watch the getting started video guide, or follow the instructions in
:ref:`pynqz2-board-setup`.

.. raw:: html

    <embed>
         <iframe width="560" height="315" src="https://www.youtube.com/embed/RiFbRf6gaK4" frameborder="0" allowfullscreen></iframe>
         </br>
         </br>
    </embed>

.. _pynqz2-board-setup:

Board Setup
===========

   .. image:: ../images/pynqz2_setup.png
      :align: center

  1. Set the ** Boot** jumper to the *SD* position.
     (This sets the board to boot from the Micro-SD card)
   
  2. To power the board from the micro USB cable, set the **Power**
     jumper to the *USB* position. (You can also power the board from an external 12V
     power regulator by setting the jumper to *REG*.)

  3. Insert the Micro SD card loaded with the PYNQ-Z2 image into the **Micro
     SD** card slot underneath the board

  4. Connect the USB cable to your PC/Laptop, and to the **PROG - UART**
     MicroUSB port on the board

  5. Connect the Ethernet port by following the instructions below

  6. Turn on the PYNQ-Z2 and check the boot sequence by following the instructions below

.. _turning-on-the-PYNQ-Z2:

Turning On the PYNQ-Z2
----------------------

As indicated in step 6 of :ref:`pynqz2-board-setup`, slide the power switch to the *ON*
position to turn on the board. The **Red** LED will come on immediately to
confirm that the board has power.  After a few seconds, the **Yellow/Green
/ Done** LED will light up to show that the Zynq® device is operational.

After a minute you should see two **Blue ** LEDs and four
**Yellow/Green** LEDs flash simultaneously. The **Blue** LEDs
will then turn on and off while the **Yellow/Green** LEDs remain on. The
system is now booted and ready for use.
  

.. include:: network_connection.rst

.. include:: pynq_sdcard_getting_started.rst
