***************
Getting Started
***************

.. contents:: Table of Contents
   :depth: 2


There are two platforms supported by Pynq; the Pynq-z1 board, and Zybo. A Pynq boot image that can be loaded onto a Micro-SD card is needed.
The full build steps and Python packages will be available on the  `Pynq project GitHub <https://github.com/Xilinx/Pynq>`_ after the official beta release. 

Any Pynq related issues can be submitted via the github site's `issue tracker <https://github.com/Xilinx/Pynq/issues>`_ once the site is live.

.. NOTE::
  1. Pynq runs natively on the Zynq ARM CPUs.  The CPUs run a web server which host the main Pynq portal.  Any computing platform that is connected to the Internet and supports a mainstream web browser, (Chrome, Firefox, Safari etc. - Internet Explorer not currently supported), can connect to the Pynq portal.  This should work with all types of laptops, desktops and even phones and tablets, independent of whether they run Windows, OSX or Linux. 

  2. Pynq does not try to teach Python programming to first-time users. Programmers who are familiar with other languages, will pick up much of the fundamentals of Python quickly from the examples in these notes. Nonetheless, Python is a very comprehensive language with many advanced features that may require additional study.  For these reasons we have provided links to excellent `Python training material <15_references.html#python-training>`_

Setup
================

Prerequisites
-------------

* Laptop or desktop PC with compatible browser (`Supported Browsers <http://jupyter-notebook.readthedocs.org/en/latest/notebook.html#browser-compatibility>`_)
* Available USB port
* Pynq or Zybo board
* Micro-SD card (Minimum 4GB)
* Micro USB cable 
* Ethernet cable


Get the image and prepare the micro-SD Card
----------------------------------------------------

   * For now you will need to obtain the image, or a micro-SD card preloaded with the image, directly from the Pynq team.
   * The image can be copied to a Micro-SD card using `Win32DiskImager <https://sourceforge.net/projects/win32diskimager/>`_. The Micro-SD card should be at least 4GB.  
   
Pynq-z1 setup
---------------


   .. image:: ./images/pynqz1_setup_config_600.jpeg
      :align: center


   * Change the *boot* jumper to **SD** (Set the board to boot from the Micro SD card)  
   
   * Insert the *Micro SD* card into the board. (The Micro-SD slot is underneath the board)

   
   * Plug the USB cable to your PC/Laptop, and connect to **UART** (J14) on the board
   
   
   * **Turn on** the power switch on the board

   When you power on the board, you should see a *LED* (PGOOD) after a few seconds, indicating the boot process has started correctly.
   
   
Zybo setup
---------------


   .. image:: ./images/zybo_setup_config_600.jpeg
      :height: 600px
      :scale: 75%
      :align: center

   * If you received a Zybo kit from the Pynq team, all jumpers will be set correctly.*

   * Change the *JP5* jumper to **SD** (Set the board to boot from the Micro SD card)  
   
   * Insert the *Micro SD* card into the Zybo. (The Micro-SD slot is underneath the board)

   * Set the *JP7* jumper to **USB** (Power the board from the USB cable)
   
   * Plug the USB cable to your PC/Laptop, and connect to **PROG UART** (J11) on the board
     
   
   * **Turn on** the power switch on the board

   When you power on the board, you should see a *RED LED* (PGOOD) and a *GREEN LED* (DONE) indicating the boot process has started correctly.

Connect to the board
==================================   
Connect an ethernet cable directly from your laptop/PC to the board, or connect the board to the same network that your laptop/PC is connected to. i.e. The board can also be plugged into a home router, or network switch. 

To connect to your board, you need to make sure that it can connect to your computer or network correctly, and you will need to know the hostname or the IP address of the board. By default, if the board is connected to a router or network with a DHCP server, it will get an IP address automaticlly. You can then connect to it using the hostname. (``pynq`` by default).

If you connect your board directly to the Ethernet port of your PC, it will automatically assign itself a static IP address (``192.168.2.99`` by default). You can then connect to it using the IP address. 
   
   
You can also connect to the board using a USB cable, and terminal, to manually configure the Ethernet and any other settings. See the FAQ for more details on connecting to the board, and changing the IP settings. 
   
If you are using a static IP address, you will need to configure the Ethernet settings on your laptop/PC and make sure your computer has an IP address that is in the same range as the board's IP. e.g. You could assign you PC the IP address (``192.168.2.98``) is the board's address is (``192.168.2.99``)
   
Two scripts are available if you need help configuring the ethernet on a Windows computer, ``pynq_enable_static_IP_windows.bat`` and ``pynq_disable_static_IP_windows.bat`` available in the ``<GitHub respository>\Pynq\Ubuntu`` folder to allow you to enable/disable a static IP address on your host Windows machine. This Batch File scripts can be run from a command prompt. You can also check the internet for innstructions on how to configure your computer. 
   
Open a web browser and connect to Pynq Jupyter Notebooks web portal
---------------------------------------------------------------------------

   * Using a web browser, open the address  `http://pynq:9090 <http://pynq:9090>`_ or `http://192.168.2.99:9090 <http://192.168.2.99:9090>`_ if using a static IP.  **pynq** is the default hostname of the board. If you changed the hostname, you will need to change the address to match your hostname. 
   
It is recommended to change the hostname if multiple boards will be used on the same network. e.g. classroom teaching. See the `Frequently asked questions <13_faqs.html>`_ to change the hostname. 
   


   * The Jupyter username/password is xpp/xpp
   
   .. image:: ./images/portal_homepage.jpg
      :height: 600px
      :scale: 75%
      :align: center

   * You can also browse to the board using the IP address. e.g.: http://192.168.2.99:9090

You should now be ready to start using Pynq. You can continue reading this documentation, or try using Pynq on the board by going to the *Getting Started* and *Example* Notebooks in the Pynq home area. 

If you can't connect to the board, see the `Frequently asked questions <13_faqs.html>`_

Interacting with the Pynq 
==========================

   
Getting started notebooks
----------------------------

Jupyter notebooks can save notebooks as html webpages. Some of the Pynq getting started documentation has been generated directly from Jupyter notebooks. 

You can view the documentation as a webpage, or if you have a board running Pynq, you can view the notebook documentation interactively and try out some example code by opening the corresponding notebook in the getting started folder. 
 
.. image:: ./images/getting_started_notebooks.jpg
   :height: 600px
   :scale: 75%
   :align: center
   

There are also a number of example notebooks available showing examples of how to use different peripherals with the board. 

.. image:: ./images/example_notebooks.jpg
   :height: 600px
   :scale: 75%
   :align: center
   
   
Accessing files on the board
----------------------------
`Samba <https://www.samba.org/>`_, a file sharing service, is running on the board. The home area on the board can be accessed as a network drive, and you can transfer files to and from the board. 

You can go to ``\\pynq\xpp`` (DHCP) or ``\\192.168.2.99\xpp`` (static IP) to access the pynq home area. Remember to change the hostname if necessary.

The Samba username:password is ``xpp:xpp``

.. image:: ./images/samba_share.jpg
   :height: 600px
   :scale: 75%
   :align: center


Troubleshooting
--------------------
If you are having problems getting the board set up, please see the `Frequently asked questions <13_faqs.html>`_
