********************
PYNQ-Z1 Setup guide
********************

This guide will show you how to setup your computer and PYNQ-Z1 board to get started using PYNQ. 
Any issues can be posted to `the PYNQ support forum <https://groups.google.com/forum/#!forum/pynq_project>`_. 

     
PYNQ-Z1 Getting Started video 
=================================

You can watch the getting started video guide, or follow the instructions below.


.. raw:: html

    <embed>
        <iframe width="560" height="315" src="https://www.youtube.com/embed/K5okTyjKr5U" frameborder="0" allowfullscreen></iframe>
        </br>
        </br>
    </embed>


PYNQ-Z1 Prerequisites
===========================

* PYNQ-Z1 board
* Computer with compatible browser (`Supported Browsers <http://jupyter-notebook.readthedocs.org/en/latest/notebook.html#browser-compatibility>`_)
* Ethernet cable
* Micro USB cable 
* Micro-SD card with preloaded image, or blank card (Minimum 8GB recommended)


Get the image and prepare the Micro-SD Card
----------------------------------------------------

Preloaded Micro SD cards are available from Digilent. If you already have a Micro SD card preloaded with the PYNQ-Z1 image, you can skip this step. 

To make your own PYNQ Micro-SD card:

   * `Download and the PYNQ-Z1 image <https://files.digilent.com/Products/PYNQ/pynq_z1_image_2017_02_10.zip>`_ and unzip
   * Write the image to a blank Micro SD card (minimum 8GB recommended)
      * Windows: Use `win32DiskImager <https://sourceforge.net/projects/win32diskimager/>`_
      * Linux/MacOS: Use the built in *dd* command\*
   
\* For detailed instructions for writing the SD card using different operating systems, see the `Appendix: Writing the SD card image <appendix.rst#writing-the-sd-card-image>`_. 
   
Setup the PYNQ-Z1 
===================


   .. image:: ../../images/pynqz1_setup.jpg
      :align: center


1. Set the *boot* jumper (labelled JP4 on the board) to the **SD** position by placing the jumper over the top two pins of JP4 as shown in the image.  (This sets the board to boot from the Micro-SD card)  
   
2. To power the PYNQ-Z1 from the micro USB cable, set the *power* jumper (JP5) to the **USB** position by placing the jumper over the top two pins of JP5 as shown in the image. (You can also power the board from an external 12V power regulator by setting the jumper to **REG**.)
   
3. Insert the **Micro SD** card loaded with the PYNQ-Z1 image into the board. (The Micro SD slot is underneath the board)
  
4. Connect the USB cable to your PC/Laptop, and to the **PROG/UART** (J14) on the board
   
5. Connect the Ethernet cable into your board and see the step below for connecting to a computer or network

6. The last step is to power on the board. You should follow the steps below to connect to the board before powering on. 

Ethernet connection to the board
----------------------------------

You can connect the Ethernet port of the PYNQ-Z1 Ethernet in the following ways:

* To a router or switch on the same network as your computer

* Directly to an Ethernet port on your computer

If available, you should connect your board to a network with Ethernet access. This will allow you to update your board and install new packages. 

Connect to a network
--------------------------

If you connect to a network with a DHCP server, your board will automatically get an IP address. You must make sure you have permission to connect a device to your network, otherwise the board may not connect properly. 

+---------------------------------------------------------------------+
| Router/Network switch (DHCP)                                        |
+=====================================================================+
| 1. Connect to Ethernet port on router/switch                        |
+---------------------------------------------------------------------+
| 2. Browse to http://pynq:9090                                       |
+---------------------------------------------------------------------+
| 3. Optional: Change hostname                                        |
+---------------------------------------------------------------------+
| 4. Optional: Configure proxy                                        |
+---------------------------------------------------------------------+

Connect directly to your computer
---------------------------------------

You will need to have an Ethernet port available on your computer, and you will need to have permissions to configure your network interface. With a direct connection, you will be able to use PYNQ, but unless you can bridge the Ethernet connection to the board to an Internet connection on your computer, your board will not have Internet access. You will be unable to update or load new packages without Internet access.

+--------------------------------------------------------+
| Direct Connection to your computer (Static IP)         |
+========================================================+
| 1. Configure your computer with a Static IP\*          |
+--------------------------------------------------------+
| 2. Connect directly to your computer's Ethernet port   |
+--------------------------------------------------------+
| 3. Browse to  http://192.168.2.99:9090                 |
+--------------------------------------------------------+

\* See `Appendix: Assign your PC/Laptop a static IP address <appendix.html#assign-your-laptop-pc-a-static-ip-address>`_


Powering on
--------------

As indicated in step 6 in the diagram above, slide the power switch to the *ON* position to *Turn On* the board. A *Red LED* will come on immediately to confirm that the board is powered on.  After a few seconds, a *Yellow/Green LED* (LD12/DONE) will light up to show that the Zynq® device is operational.

After about 30 seconds you should see two blue LEDs and four yellow/green flash simultaneously.  The blue LEDS will then go off while the yellow/green LEDS remain on.  At this point the system is now booted and ready for use. 
  

