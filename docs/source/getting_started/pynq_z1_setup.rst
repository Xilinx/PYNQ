.. _pynq-z1-setup:

*******************
PYNQ-Z1 Setup Guide
*******************
     
Prerequisites for the Pynq-Z1
=============================

  * PYNQ-Z1 board
  * Computer with compatible browser (`Supported Browsers
    <http://jupyter-notebook.readthedocs.org/en/latest/notebook.html#browser-compatibility>`_)
  * Ethernet cable
  * Micro USB cable 
  * Micro-SD card with preloaded image, or blank card (Minimum 8GB recommended)
  
Getting Started Video
=====================

You can watch the getting started video guide, or follow the instructions in
:ref:`pynqz1-board-setup`.

.. raw:: html

    <embed>
         <iframe width="560" height="315" src="https://www.youtube.com/embed/SuXkbcK3w9E" frameborder="0" allowfullscreen></iframe>
         </br>
         </br>
    </embed>
   
.. _pynqz1-board-setup:

Board Setup
===========

   .. image:: ../images/pynqz1_setup.jpg
      :align: center

  1. Set the **JP4 / Boot** jumper to the *SD* position by
     placing the jumper over the top two pins of JP4 as shown in the image.
     (This sets the board to boot from the Micro-SD card)
   
  2. To power the PYNQ-Z1 from the micro USB cable, set the **JP5 / Power**
     jumper to the *USB* position. (You can also power the board from an external 12V
     power regulator by setting the jumper to *REG*.)

  3. Insert the Micro SD card loaded with the PYNQ-Z1 image into the **Micro
     SD** card slot underneath the board.

  4. Connect the USB cable to your PC/Laptop, and to the **PROG - UART / J14**
     MicroUSB port on the board

  5. Connect the board to Ethernet by following the instructions below

  6. Turn on the PYNQ-Z1 and check the boot sequence by following the instructions below

  .. _turning-on-the-PYNQ-Z1:

Turning On the PYNQ-Z1
----------------------

As indicated in step 6 of :ref:`pynqz1-board-setup`, slide the power switch to the *ON*
position to turn on the board. The **Red LD13** LED will come on immediately to
confirm that the board has power.  After a few seconds, the **Yellow/Green LD12
/ Done** LED will light up to show that the Zynq® device is operational.

After a minute you should see two **Blue LD4 & LD5** LEDs and four
**Yellow/Green LD0-LD3** LEDs flash simultaneously. The **Blue LD4-LD5** LEDs
will then turn on and off while the **Yellow/Green LD0-LD3** LEDs remain on. The
system is now booted and ready for use.

.. include:: network_connection.rst

.. include:: pynq_sdcard_getting_started.rst
