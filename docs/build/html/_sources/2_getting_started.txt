
This guide will show you how to setup your compter and PYNQ-Z1 board to get started using PYNQ. 
Any issues can be posted to `the PYNQ support forum <https://groups.google.com/forum/#!forum/pynq_project>`_. 

***************
Getting Started
***************

.. contents:: Table of Contents
   :depth: 2

Setup
================

Prerequisites
-------------

* PYNQ-Z1 board
* Computer with compatible browser (`Supported Browsers <http://jupyter-notebook.readthedocs.org/en/latest/notebook.html#browser-compatibility>`_)
* Micro-SD card (Minimum 8GB recommended)
* Ethernet cable
* Micro USB cable 
* USB port

Get the image and prepare the micro-SD Card
----------------------------------------------------

* `Download the PYNQ-Z1 image <https://files.digilent.com/Products/PYNQ/pynq_z1_image_2016_09_14.zip>`_, unzip, and write the image to an SD card. Windows: `win32DiskImager <https://sourceforge.net/projects/win32diskimager/>`_, Linux/MacOS: *dd*.
   
For detailed instructions for different operating systems, see the `Appendix: Writing the SD card image <17_appendix.rst#writing-the-sd-card-image.html>`_. 
   
PYNQ-Z1 setup
---------------


   .. image:: ./images/pynqz1_setup.jpg
      :align: center

To set up the board:

   1. Change the *boot* jumper to **SD** (Set the board to boot from the Micro-SD card)  
   
   2. Insert the **Micro SD** card loaded with the PYNQ-Z1 image into the board. (The Micro SD slot is underneath the board)
   
   3. Connect the USB cable to your PC/Laptop, and to the **PROG/UART** (J14) on the board
   
   4. Connect the Ethernet cable into your board, and directly to your computer or to a router/network switch that your computer is connected to.    
   
   5. **Turn on** the power switch on the board

   When you power on the board, you should see a *Red LED* indicating that the board is powered. After a few seconds, you should see a *Green LED* (LD12/DONE), indicating a bitstream has been downloaded to the programmable logic. This is also a good indication that the boot process has started correctly. After about 30 seconds the board should finish booting. You should see all the LEDs flash, and the yellow LEDs will remain on. You can then connect to the board from your browser. 
   
   
Connect to the board
==================================   

You need to make sure your board can connect to your computer or network correctly. You will need to know the hostname or the IP address of the board. By default, if the board is connected to a router or network with a DHCP server, it will get an IP address automatically. You can then use the board hostname to connect to it. The default hostname is ``pynq``.

If you connect your board directly to the Ethernet port of your PC, the board will automatically assign itself a static IP address (``192.168.2.99`` by default). To allow the board and computer to communicate, you can  manually configure your computer to have an IP address in the same range (e.g. 192.168.2.1). See the  `Appendix: Assign your PC/Laptop a static ip address <17_appendix.html#assign-your-laptop-pc-a-static-ip-address>`_
   
You can also connect to the board using a USB cable, and terminal, to manually configure the Ethernet/IP and any other operating system settings. See the `Frequently asked questions <14_faqs.html>`_  for more details on connecting to the board, and changing the IP address and other settings of the board. 
   
Two scripts are available if you need help configuring the Ethernet on a Windows computer, ``pynq_enable_static_IP_windows.bat`` and ``pynq_disable_static_IP_windows.bat`` available in the ``<GitHub repository>\scripts\host`` folder to allow you to enable/disable a static IP address on your host Windows machine. This Batch File scripts can be run from a Windows command prompt. You can also check the internet for instructions on how to configure the Ethernet settings for your computer. 
   
Open a web browser and connect to Pynq Jupyter Notebooks web portal
---------------------------------------------------------------------------

If the board is connected to your network, the board should get a DHCP (dynamic) IP address.

   * Open a web browser and go to `http://pynq:9090 <http://pynq:9090>`_ 

If the board is connected directly to your laptop/PC Ethernet port, the board will have a static IP (192.168.2.99) by default. 

   * Configure your Ethernet adapter IP address to be in the same range as the board (e.g.  192.168.2.1), open a web browser and  go to `http://192.168.2.99:9090 <http://192.168.2.99:9090>`_ 

The default hostname of the board is **pynq** and the default static IP address is ``192.168.2.99``. If you changed the hostname or static IP, you will need to change the address above to match your hostname. 
   
It may take a few seconds to resolve the hostname/IP address. If you have problems connecting to the board, first try to ping it from your laptop/PC. If you can't ping it, then try to connect a terminal to the board to check it has booted, and that the Ethernet settings for the board are correct. 
   
You will need to change the hostname if multiple boards are connected to the same network. E.g. classroom teaching. See the `Frequently asked questions <14_faqs.html>`_ for instructions to change the hostname, or if you are having problems connecting to the board. 
   

   * The Jupyter username/password is xilinx/xilinx
   
   .. image:: ./images/portal_homepage.jpg
      :height: 600px
      :scale: 75%
      :align: center

You should now be ready to start using Pynq. You can continue reading this documentation, or try using Pynq on the board. A number of *Getting Started* Notebooks, and *Examples* are available in the corresponding directories in the Pynq home area. 


Using Pynq
==========================

   
Getting started notebooks
----------------------------

Jupyter notebooks can be saved as html webpages. Some of this Pynq documentation has been generated directly from Jupyter notebooks. 

You can view the documentation as a webpage, or if you have a board running Pynq, you can view and run the notebook documentation interactively. The documentation available as notebooks can be found in the *Getting_Started* folder in the Jupyter home area. 
 
.. image:: ./images/getting_started_notebooks.jpg
   :height: 600px
   :scale: 75%
   :align: center
   

There are also a number of example notebooks available showing how to use various peripherals with the board. 

.. image:: ./images/example_notebooks.jpg
   :height: 600px
   :scale: 75%
   :align: center
   
   
Accessing files on the board
----------------------------
`Samba <https://www.samba.org/>`_, a file sharing service, is running on the board. The home area on the board can be accessed as a network drive, and you can transfer files to and from the board. 

In Windows, to access the pynq home area you can go to:

``\\pynq\xilinx`` 

or 

``\\192.168.2.99\xilinx``  

Or in Linux: 

``smb://pynq/xilinx`` 

or 

``smb://192.168.2.99/xilinx``

Remember to change the hostname/IP address if necessary.

The Samba username:password is ``xilinx:xilinx``

.. image:: ./images/samba_share.JPG
   :height: 600px
   :scale: 75%
   :align: center


Troubleshooting
--------------------
If you are having problems getting the board set up, please see the `Frequently asked questions <14_faqs.html>`_ or go the `PYNQ support forum <http://www.pynq.io>`_
