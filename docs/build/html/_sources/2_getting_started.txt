***************
Getting Started
***************

.. contents:: Table of Contents
   :depth: 2


Pynq is currently supported on the PYNQ-Z1 board. To start using Pynq, you will need a Micro-SD card loaded with the Pynq image.
The Pynq image will be available to download from the Digilent website. 

Any Pynq related issues can be submitted via the GitHub site's `issue tracker <https://github.com/Xilinx/PYNQ/issues>`_.

.. NOTE::
  1. Pynq runs natively on the ARM Cortex A9 processor on Zynq.  A web server hosts the main Jupyter portal.  Any computing platform that supports a modern, mainstream web browser, (Chrome, Firefox, Safari etc. - Internet Explorer not currently supported), can access the Jupyter portal on the board.  

  2. Pynq does not try to teach Python programming to first-time users. Programmers who are familiar with other languages, will pick up much of the fundamentals of Python quickly from the examples in these notes. Nonetheless, Python is a very comprehensive language with many advanced features that may require additional study.  For these reasons we have provided links to `Python training material <16_references.html#python-training>`_

Simple Setup
================

Prerequisites
-------------

* Laptop/PC with compatible browser (`Supported Browsers <http://jupyter-notebook.readthedocs.org/en/latest/notebook.html#browser-compatibility>`_)
* Available USB port
* PYNQ-Z1 board
* Micro-SD card (Minimum 8GB recommended)
* Micro USB cable 
* Ethernet cable


Get the image and prepare the micro-SD Card
----------------------------------------------------

   * The Pynq image will be available to download from the Digilent website. 
   * The image can be written to a Micro-SD card using `Win32DiskImager <https://sourceforge.net/projects/win32diskimager/>`_. We recommend that the Micro-SD card should be at least 8GB.  
   
PYNQ-Z1 setup
---------------


   .. image:: ./images/pynqz1_setup.jpg
      :align: center

To set up the board:

   1. Change the *boot* jumper to **SD** (Set the board to boot from the Micro-SD card)  
   
   2. Insert the *Micro SD* card into the board. (The Micro-SD slot is underneath the board)
   
   3. Connect the USB cable to your PC/Laptop, and to the **PROG/UART** (J14) on the board
   
   4. Connect the Ethernet cable into your board, and directly to your laptop/PC or to a router/network switch your computer is connected to.    
   
   5. **Turn on** the power switch on the board

   When you power on the board, you should see a *Red LED* indicating that the board is powered. After a few seconds, you should see a *Green LED* (LD12/DONE), indicating a bitstream has been downloaded to the programmable logic. This is also a good indication that the boot process has started correctly. After about 30 seconds the board should finish booting and you can then connect to the board from your browser. 
   
   
Connect to the board
==================================   

You need to make sure your board can connect to your computer or network correctly. You will need to know the hostname or the IP address of the board. By default, if the board is connected to a router or network with a DHCP server, it will get an IP address automatically. You can then use the board hostname to connect to it. The default hostname is ``pynq``.

If you connect your board directly to the Ethernet port of your PC, the board will automatically assign itself a static IP address (``192.168.2.99`` by default). To allow the board and computer to communicate, you can  manually configure your computer to have an IP address in the same range (e.g. 192.168.2.1). 
   
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

You can go to ``\\pynq\xilinx`` or ``\\192.168.2.99\xilinx`` (windows) or ``smb://pynq/xilinx`` or ``smb://192.168.2.99/xilinx`` (linux) to access the pynq home area. Remember to change the hostname/IP address if necessary.

The Samba username:password is ``xilinx:xilinx``

.. image:: ./images/samba_share.JPG
   :height: 600px
   :scale: 75%
   :align: center


Troubleshooting
--------------------
If you are having problems getting the board set up, please see the `Frequently asked questions <14_faqs.html>`_
