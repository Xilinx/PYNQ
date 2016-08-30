The ``Pynq`` (Python Productivity for Zynq) Platform
==============================================

This section describes the ``pynq`` (**Py**\thon Productivity for **Zy**\nq) Platform - specifically the preloaded SDCard contents and how the SDCard is tied to the PYNQ-Z1 platform. 

After powering the board with the Pynq image on the SDCard in place, the board will boot into Linux.  Python3 is installed with Jupyter Notebook support and the Pynq Python Package. With the pynq package, users can access FPGA fabric overlays from Python.   

Some preinstalled features of this Linux image include:

* Networking is enabled and Ethernet port will attempt to use DHCP on boot.  If DHCP fails, the board will fallback to a static IP of 192.168.2.99.
* Samba is enabled and can be accessed from a Windows machine by navigating or mapping to ``\\pynq\xilinx``.  The ``username:password`` is ``xilinx:xilinx``.  You can browse to the directory in a similar way using other operating systems. The Pynq source code, and notebooks can be accessed and modified using your preferred editors on your host PC. 
* A Jupyter Notebook server is initialized on port 9090 and automatically starts after boot.
* The base overlay is preloaded in the FPGA fabric. 






Python ``pynq`` Package Structure
---------------------------------
All Pynq supplied python code is preloaded in the pynq Python package and is accessible at /home/xilinx/pynq.  This package is derived from the Github repository and the latest version can always be installed from ``<GitHub repository>/Pynq/python/pynq``.

Pynq contains four main subpackages: ``board``, ``iop``, ``drivers``, and ``bitstream``; a ``tests`` subpackage is for testing the user subpackages.  Each of the five subpackages are described below.

To learn more about Python package structure, please refer to the `official python documentation <https://docs.python.org/3.5/tutorial/modules.html#packages>`_.



board
-----
This folder contains libraries or python packages for peripherals available on the PYNQ-Z1 board: button, switch, rgbled and led.  For example the following code will turn on one of PYNQ-Z1's LEDs:

.. code-block:: python

   from pynq.board import LED
   LED(0).on()


iop
-----
This folder contains libraries for the following Pmod devices ``OLED``, ``TMP2``, ``DPOT``, ``PWM``, ``TIMER``, ``ALS`` ``LED8``, ``ADC``, and ``DAC``.  

The following Grove peripherals are also supported: ``Grove ADC``, ``Grove PIR``, ``Grove OLED``, ``Grove Buzzer``, ``Grove Light Sensor``, ``Grove LED BAR``, ``Grove Temperature Sensor``. In addition, ``Pmodio``, ``PmodIic`` and ``DevMode`` are developer classes allowing direct low level access to I/O controllers.

There is also an additional module named ``_iop.py``; this module acts like a wrapper to allow all the Pmod classes to interface with the MicroBlaze inside an IOP.  The ``_IOP`` class prevents multiple device instantiations on the same Pmod at the same time. (i.e. This prevents the user assigning more devices to a port than can be physically connected.)  ``_IOP`` uses the Overlay class to track each IOP's status. 

.. note:: ``_iop.py`` is an internal module, not intended for the end user. In Python, there is no concept of _public_ and _private_; we use ``_`` as a prefix to indicate internal definitions, variables, functions, and packages.


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
-----

This folder contains the base.bit and the base.tcl. The abse.bit is the precompiled overlay and base.tcl provides the information of the hardware it is built from.


drivers
-----

This folder contains various classes to support audio, video, DMA, and Trace_Buffer.


tests
-----

This folder includes a tests package for use with all other pynq subpackages.  All testing is done using `pytest <http://pytest.org/latest/>`_.  Please see `The Verification Section <11_verification.html>`_ to learn more about Pynq's use of pytest to do automated testing.

NOTE: The ``tests`` folders in ``board``, ``iop``, ``drivers``, and others rely on the functions implemented in the ``test`` folders of the pynq package. This common practice in Python where each subpackage has its own ``tests``.  This practice can keep the source code modular and *self-contained*.

documentation
-----------------------------
To find documentation for each module, see the `Pynq Package <12_modules.html>`_ for documentation built from the actual Python source code.

