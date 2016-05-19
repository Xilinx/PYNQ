Working with Overlays
==============================================

Creating overlays is done using traditional hardware design methods. This document will describe how overlays can be integrated into Pynq by FPGA/Zynq designers, but will not cover the hardware design process. 

While FPGA fabric can be customized to very specific and optimized implementations, a high level of expertise is required to do this, and is much more time consuming than creating software. 

One of the key concepts of Pynq Overlays, is that the Overlay should be designed to be flexible rather than highly customized. Flexibility allows an overlay to be used for many different applications, even if this results in a less optimal hardware implementation.

For example, it is recommended that IOPs are used for PMOD interfaces to make the overlay as widely applicable as possible, even where the designer intends to use a specific peripheral for a particular application. This may result in a design that uses more FPGA resources than is necessary, but the flexibility of the overlay is of higher value than the overhead of the additional resources used. 


Existing Overlays
-----------------

Two overlays are currently included in the Pynq repository; *pmod*, and *audiovideo*:

   * ``<Pynq GitHub Repository>Pynq/zybo/vivado/pmod``
   * ``<Pynq GitHub Repository>Pynq/zybo/vivado/audiovideo``

A makefile exists in each folder that can be used to rebuild the Vivado projects and generate the bitstreams for the overlays. However, the overlays have been precompiled, and are available in ``<Pynq GitHub Repository>/Pynq/python/pynq/bitstream/`` so it is not necessary to rebuild the overlays, which requires a full Vivado installation.

Building overlays is only required to build a new overlay. Building an existing overlay allows the project to be opened in Vivado and examined, or modified to create a new overlay. 

.. image:: ./images/pmodio_overlay.jpg
   :scale: 50%
   :align: center
   
Loading Overlays
----------------

The PL can be dynamically reconfigured with new overlays as the system is running. This allows Pynq to swap in and out different overlays to support different functionality required by software (Python) applications. 

Loading Overlays can be done in Python using the Overlay class, which is part of the Pynq PL package:

   ``<Pynq GitHub Repository>/Pynq/python/pynq/pl.py``
   
The Bitstream can then be downloaded from Python:


.. code-block:: python

   from pynq import Overlay
   Overlay("audiovideo.bit").download()





Using new overlays with MMIO
-----------------------------------
Once a new overlay has been created, the overlay needs to be integrated into the Pynq environment.  It is recommended to use an existing Vivado *Overlay project* as a starting point for a new overlay. This will ensure the settings for the Zynq PS, and the existing PS/PL interfaces are used in the new project. 

As with any application running on Zynq, the interface between the software and hardware is via the Zynq memory map. 

An overlay can have many addressable IPs. These addressable IPs can be accessed by the ARM processor using the memory map. To find the addressable IPs of a specific overlay (e.g. `audiovideo.bit`), users can do:

.. code-block:: python

   from pynq import Overlay
   Overlay("audiovideo.bit").ip_dict


This will show the IP dictionary of the overlay. Each entry in this IP dictionary is a key-value pair. For example, an entry can be: 

    ``'SEG_mb_bram_ctrl_1_Mem0': ['0x40000000', '0x8000', None]``

The key of the entry is the IP instance name; all the IP instance names are parsed from the `*.tcl` file (e.g. `audiovideo.tcl`) in the address segment section. The value of the entry is a list of 3 items:
   - The first item shows the base address of the addressable IP (hex).
   - The second item shows the address range in bytes (hex).
   - The third item records the state associated with the IP. It is `None` by default, but can be used flexibly by the users.

Similarly, to find the addressable IPs currently on the programmable logic, users can do:

.. code-block:: python

   from pynq import PL
   PL.ip_dict

To help ease the effort to communicate between the ARM processor and programmable logic, Pynq includes the *MMIO* Python class. Once the Overlay has been created, and the memory map is known, the *MMIO* can be used to read/write to/from memory mapped locations in the PL. 

The Python code for the MMIO can be viewed here:

    ``<Pynq GitHub Repository>/Pynq/python/pynq/mmio.py``

Continuing the example shown above, we show a use case where the MMIO class can access an area of 0x8000 bytes in the PL, starting at address 0x40000000 (`SEG_mb_bram_ctrl_1_Mem0`): 

.. code-block:: python

   from pynq import MMIO

   # an IP is located at 0x40000000
   myip = MMIO(0x40000000,0x8000)

   # Read from the IP at offset 0
   myip.read(0)


In the example above, any accesses outside the address range 0x8000 (32768 bytes) will cause an error. When creating the python driver for a new hardware function, the MMIO can be wrapped inside a Python module. 



Using new overlays with GPIO
-----------------------------------
The control interface between the ARM processor and programmable logic is via the Zynq GPIO. The information about a GPIO is kept in the GPIO dictionary of an overlay. 

.. code-block:: python

   from pynq import Overlay
   Overlay("audiovideo.bit").gpio_dict


An example of the entry in a GPIO dictionary can be:

    ``'mb_1_reset/Din': [0, None]``

The key of the entry is the GPIO instance name; all the GPIO instance names are parsed from the `*.tcl` file (e.g. `audiovideo.tcl`) in the GPIO connection section. The value of the entry is a list of 2 items:
- The first item shows the user index of the GPIO.
- The second item records the state associated with the GPIO. It is `None` by default, but can be used flexibly by the users.

Similarly, to check the GPIO currently on the programmable logic:

.. code-block:: python

   from pynq import PL
   PL.gpio_dict



New overlay example
-------------------------------------
An example notebook ``overlay_mmio_gpio.ipynb`` is available in the *examples* folder, showing how to write Python to interface to an overlay. 