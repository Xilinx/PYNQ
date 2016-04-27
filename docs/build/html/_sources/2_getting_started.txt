***************
Getting Started
***************

.. contents:: Table of Contents
   :depth: 2


Zybo is currently the supported Pynq platform. The full build steps and Python packages will be available on the  `Pynq project GitHub <https://github.com/Xilinx/Pynq>`_ after the official beta release. 

Any issues can be submitted via the github site's `issue tracker <https://github.com/Xilinx/Pynq/issues>`_ once the site is live.

.. NOTE::
  1. This beta deliverable of Pynq on Zybo runs natively on the Zynq ARM CPUs.  The CPUs run a web server which host the main Pynq portal.  Any computing platform that is connected to the Internet and supports a mainstream web browser, (Chrome, Firefox, Safari etc. - Internet Explorer not currently supported), can connect to the Pynq portal.  This should work all types of laptops, desktops and even phones and tablets, independent of whether they run Windows, OSX or Linux. 

  2. Pynq on Zybo does not try to teach Python programming to first-time users. Programmers who are familiar with other languages, will pick up much of the fundamentals of Python quickly from the examples in these notes. Nonetheless, Python is a very comprehensive language with many advanced features that may require additional study.  For these reasons we have provided links to excellent `Python training material <15_references.html#python-training>`_

Setup
================

Prerequisites
-------------

* Laptop or desktop with compatible browser (`Supported Browsers <http://jupyter-notebook.readthedocs.org/en/latest/notebook.html#browser-compatibility>`_)
* Ethernet port
* Zybo
* USB port 


There are three main steps to getting started with Pynq and the Zybo.  These are:

1. **Get the image and prepare the micro-SD Card**

   * For now you will need to obtain the image, or a micro-SD card preloaded with the image directly from the Pynq team.
   * The image can be copied to a Micro-SD card using `Win32DiskImager <https://sourceforge.net/projects/win32diskimager/>`_. The Micro-SD card must be at least 16GB.  

2. **Configure Zybo and connect it to your host machine and network**

   * See further detailed `Hardware Setup instructions <2_getting_started.html#hardware-setup>`_ below if necessary

3. **Open a web browser and connect to Pynq Jupyter Notebooks web portal**

   * Using a web browser, open the address  `http://pynq:9090 <http://pynq:9090>`_.  **pynq** is the default Ubuntu hostname of the board. If you have changed the hostname, you will need to change the address to match your hostname. It is recommended to change Zybo hostnames if multiple boards are on the same network. e.g. classroom teaching. See the `Frequently asked questions <13_faqs.html>`_ for how to change the hostname.
   
   .. image:: ./images/portal_login.jpg
      :height: 600px
      :scale: 75%
      :align: center
   
   
   * Log in with the username/password xpp/xpp
   
   
   .. image:: ./images/portal_homepage.jpg
      :height: 600px
      :scale: 75%
      :align: center
   
You should now be ready to start using Pynq. You can continue reading this documentation, or try using Pynq on the board by going to the *Getting Started* and *Example* Notebooks in the Pynq home area. 

If you can't connect to the board, see the `Frequently asked questions <13_faqs.html>`_


Interacting with the Pynq 
==========================

You can click on a notebook (.ipynb) to open it. 

   
Getting started notebooks
----------------------------

A powerful feature of Jupyter notebooks is the ability to render html webpages from the source documents. Some of this documentation has been generated directly from notebooks. 

You can view the webpage for documentation, or if you have a board running pynq, you can view the documentation interactively and try out some example code, by opening the corresponding notebook in the getting started folder. 
 
.. image:: ./images/pynq_getting_started.jpg
   :height: 600px
   :scale: 75%
   :align: center
   

There are also a number of example notebooks available showing examples of how to use different peripherals with the board. 

.. image:: ./images/pynq_examples.jpg
   :height: 600px
   :scale: 75%
   :align: center
   
   
Accessing files on the board
----------------------------
Samba is running on the board, and the home area is shared and can be accessed like a networked drive. 

Users should go to *\\\\pynq\\xpp* to access the pynq home area.

Login and password is xpp \ xpp

.. image:: ./images/samba_share.jpg
   :height: 600px
   :scale: 75%
   :align: center

Hardware setup
=====================

   .. image:: ./images/zybo_setup_config_600.jpeg
      :height: 600px
      :scale: 75%
      :align: center

   *If you received a Zybo kit from the Pynq team, all jumpers will be set correctly.*

   * Insert the *Micro SD* card into the Zybo. (The Micro-SD slot is underneath the board)

   * Change the *JP5* jumper to **SD** (Set the board to boot from the Micro SD card)  

   * Set the *JP7* jumper to **USB** (Power the board from the USB cable)
   
   * Plug the USB cable to your PC/Laptop, and connect to **PROG UART** (J11) on the board
   
   * Connect the board via an Ethernet cable to the same network that your host is connected to

   * **Turn on** the power switch on the board

   When you power on the board, you should see a *RED LED* (PGOOD) and a *GREEN LED* (DONE) indicating the system has booted successfully.

   * Switch on Zybo and verify that the status LEDs indicate successful boot-up

Additional external peripherals (Pmods and Grove Peripherals) are optional and will be discussed later.

Troubleshooting
--------------------
If you are having problems getting the board set up, please see the `Frequently asked questions <13_faqs.html>`_
