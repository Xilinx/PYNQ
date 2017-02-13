*********************
``pynq`` Package
*********************

.. contents:: Table of Contents
   :depth: 2
   
This section describes the ``pynq`` package for the PYNQ-Z1 platform. 

After powering the board with the Micro SD card in place, the board will boot into Linux. Python3 is installed with Jupyter Notebook support. The Python package `pynq` allows users to access  overlays from Python.   

Some pre-installed features of this Linux image include:

* Networking is enabled, and the board will attempt to get an IP address from a DHCP server on the network.  If a DHCP server is not found, the board will fallback and assign itself a static IP of 192.168.2.99 by default. This default IP address can be changed. 
* Samba, a file sharing service, is enabled. This means that the Linux home area can be accessed from a Windows machine by navigating to or mapping ``\\pynq\xilinx`` (Windows) or ``smb:pynq/xilinx`` (Mac/Linux) .  The samba ``username:password`` is ``xilinx:xilinx``.  Files can be copied to and from the board, and the Pynq source code, and notebooks can be accessed and modified using your preferred editors on your host PC. 
* A Jupyter Notebook server is initialized on port 9090 and automatically starts after boot.
* The base overlay is preloaded in the FPGA fabric. 


Python ``pynq`` Package Structure
==================================
All Pynq code is contained in the *pynq* Python package and is can be found on the board at /home/xilinx/pynq.  This package is derived from the Github repository and the latest version can always be installed from ``<GitHub repository>/python/pynq``.

Pynq contains four main subpackages: ``board``, ``iop``, ``drivers``, and ``bitstream``; a ``tests`` subpackage is available for testing the user subpackages.  Each of the five subpackages are described below.

To learn more about Python package structures, please refer to the `official python documentation <https://docs.python.org/3.5/tutorial/modules.html#packages>`_.



board
=====
This folder contains libraries or python packages for peripherals available on the PYNQ-Z1 board: button, switch, rgbled and led.  For example the following code will turn on one of PYNQ-Z1's LEDs:

.. code-block:: python

   from pynq.board import LED
   led = LED(0)
   led.on()


iop
=====
This folder contains libraries for Pmod devices and Grove peripherals.

``Arduino_Analog``, and ``Arduino_IO`` are provided for interfacing to the arduino interface. 

In addition, ``Pmod_IO``, ``Pmod_IIC`` and ``DevMode`` are developer classes allowing direct low level access to I/O controllers.

There is also an additional module named ``_iop.py``; this module acts like a wrapper to allow all the Pmod classes to interface with the MicroBlaze inside an IOP.  The ``_IOP`` class prevents multiple device instantiations on the same Pmod at the same time. (i.e. This prevents the user assigning more devices to a port than can be physically connected.)  ``_IOP`` uses the overlay class to track each IOP's status. 

.. note:: ``_iop.py`` is an internal module, not intended to be instantiated directly use. In Python, there is no concept of _public_ and _private_; we use ``_`` as a prefix to indicate internal definitions, variables, functions, and packages.


For example, the following code will instantiate and write to the Pmod_OLED attached on PMODA.

.. code-block:: python

   from pynq import Overlay
   from pynq.iop import Pmod_OLED
   from pynq.iop.iop_const import PMODA

   ol = Overlay("base.bit")
   ol.download()

   pmod_oled = Pmod_OLED(PMODA)
   pmod_oled.clear()
   pmod_oled.write('Welcome to the\nPynq-Z1 board!')

bitstream
===========

This folder contains the base.bit and the base.tcl. The base.bit is the precompiled overlay and base.tcl provides information about the hardware it is built from. The tcl file can be parsed by Pynq packages to determine information about the hardware. ``PL.ip_dict`` will parse the tcl for an overlay and respond with the addresses of any peripherals in the overlay. 


drivers
=========

This folder contains various classes to support audio, video, DMA, and Trace_Buffer.


tests
======

This folder includes a tests package for use with all other pynq subpackages.  All testing is done using `pytest <http://pytest.org/latest/>`_.  Please see `The Verification Section <18_verification.html>`_ to learn more about Pynq's use of pytest to do automated testing.

.. note:: The ``tests`` folders in ``board``, ``iop``, ``drivers``, and others rely on the functions implemented in the ``test`` folders of the pynq package. This common practice in Python where each subpackage has its own ``tests``.  This practice can keep the source code modular and *self-contained*.

documentation
=============================
To find documentation for each module, see the `Pynq Package <modules.html>`_ for documentation built from the actual Python source code.

