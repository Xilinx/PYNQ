The ``Pynq`` (Python on Zynq) Platform
==============================================

The section describes the ``pynq`` (**Py**\thon on **Zy**\nq) Platform - specifically the preloaded SDCard contents and how the SDCard is tied to the PYNQ-Z1 platform. 

After powering the board with the Pynq image on the SDCard in place, the board will boot into Linux.  Python3 is installed with Jupyter notebook support and the Pynq Python Package. With the pynq package, users can access programmable logic overlays from Python.   

Some preinstalled features of this Linux image include:

* Networking is enabled and Ethernet port will attempt to use DHCP on boot.  If DHCP fails, the board will fallback to a static IP of 192.168.2.99.
* Samba is enabled and can be accessed from a Windows machine by navigating or mapping to ``\\pynq\xilinx``.  The ``username:password`` is ``xilinx:xilinx``.  You can browse to the directory in a similar way using other operating systems. The Pynq source code, and notebooks can be accessed and modified using your preferred editors on your host PC. 
* A Jupyter notebook server is initialized on port 9090 and automatically starts after boot.
* The PMOD IO overlay is preloaded onto the programmable logic. 






Python ``pynq`` Package Structure
---------------------------------
All Pynq supplied python code is preloaded in the pynq Python package and is accessible at /home/xilinx/pynq.  This package is derived from the Github repository and the latest version can always be installed from ``<GitHub repository>/Pynq/python/pynq``.

Pynq contains four main subpackages: ``board``, ``pmods``, ``audio``, and ``video``; a ``tests`` subpackage is for testing the user subpackages.  Each of the five subpackages are described below.

To learn more about Python package structure, please refer to the `official python documentation <https://docs.python.org/3.5/tutorial/modules.html#packages>`_.



board
-----
This folder contains libraries or python packages for peripherals available on the PYNQ-Z1 board: Buttons, Switches, and LEDs.  For example the following code will turn on one of PYNQ-Z1's LEDs:

.. code-block:: python

   from pynq.board import LED
   LED(0).on()


pmods
-----
This folder contains libraries for the following Pmod devices ``OLED``, ``TMP2``, ``ALS`` ``LED8``, ``ADC``, and ``DAC``.  

The following Grove peripherals are also supported: ``Grove ADC``, ``Grove PIR``, ``Grove OLED``, ``Grove Buzzer``, ``Grove Light Sensor``, ``Grove LED BAR``, ``Grove Temperature Sensor``. In addition, ``Pmodio``, ``PmodIic`` and ``DevMode`` are developer classes allowing direct low level access to I/O controllers.

There is also an additional module named ``_iop.py``; this module acts like a wrapper to allow all the PMOD classes to interface with the MicroBlaze inside an IOP.  The ``_IOP`` class prevents multiple device instantiations on the same PMOD at the same time. (i.e. This prevents the user assigning more devices to a port than can be physically connected.)  ``_IOP`` uses the Overlay class to track each IOP's status. 

.. note:: ``_iop.py`` is an internal module, not intended for the end user. In Python, there is no concept of _public_ and _private_; we use ``_`` as a prefix to indicate internal definitions, variables, functions, and packages.


For example, the following code will instantiate and write to the PMOD_OLED attached on PMOD 4.

.. code-block:: python

   from pynq.iop import PMOD_OLED 
   PMOD_OLED(4).write("hello world")

audio
-----

This folder contains the single audio class to use Line in and Headphone out.  Please see `The Audio Video Overlay Section <7_audio_video_overlay.html>`_ to learn more about using audio.


video
-----

This folder contains the HDMI class.  Please see the `Base Overlay Video Section <7_base_overlay_video.html>`_ to learn more about using video.


tests
-----

This folder includes a tests package for use with all other pynq subpackages.  All testing is done using `pytest <http://pytest.org/latest/>`_.  Please see `The Verification Section <11_verification.html>`_ to learn more about Pynq's use of pytest to do automated testing.

NOTE: The ``tests` folders in ``board``, ``pmods``, and others rely on the functions implemented in the ``test`` folders of the pynq package. This common practice in Python where each subpackage has its own ``tests``.  This practice can keep the source code modular and *self-contained*.

documentation
-----------------------------
To find documentation for each module, see the `Pynq Package <12_modules.html>`_ for documentation built from the actual Python source code.

