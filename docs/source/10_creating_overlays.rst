Working with Overlays
==============================================

Creating overlays involves using traditional hardware design methods. This document will describe how overlays can be integrated into Pynq by FPGA/Zynq designers, but will not cover the hardware design process. 

While FPGA fabric can be customized to very specific and optimized implementations, a high level of expertise is required to do this, and is much more time consuming than creating software. 

One of the key concepts of Pynq Overlays, is that the Overlay should be designed to be flexible rather than highly customized. Flexibility allows an overlay to be used for many different applications, even if this results in a less optimal hardware implementation.

For example, it is recommended that IOPs are used for Pmod interfaces to make the overlay as widely applicable as possible, even where the designer intends to use a specific peripheral for a particular application. This may result in a design that uses more FPGA resources than is necessary, but the flexibility of the overlay is of higher value than the overhead of the additional resources used. 


Existing Overlays
-----------------

One overlay is currently included in the Pynq repository; *base*:

   * ``<GitHub repository>/Pynq-Z1/vivado/base``
  
A makefile exists in each folder that can be used to rebuild the Vivado project and generate the bitstream for the overlay. However, the overlay has been precompiled, and is available in ``<GitHub Repository>/Pynq-Z1/bitstream/``.

A full Vivado installation is required to design and build overlays. Building an existing overlay design allows the project to be opened in Vivado and examined, or modified to create a new overlay. 

.. image:: ./images/vivado_base_overlay.JPG
   :scale: 50%
   :align: center
   
Loading Overlays
----------------

The FPGA fabric can be dynamically reconfigured with new overlays as the system is running. This allows Pynq to swap in and out different overlays to support different functionality required by software (Python) applications. 

Loading overlays can be done in Python using the Overlay class, which is part of the Pynq package:

   ``<GitHub Repository>/python/pynq/pl.py``
   
The Bitstream can then be downloaded from Python:


.. code-block:: python

   from pynq import Overlay
   Overlay("base.bit").download()





Using new overlays with MMIO
-----------------------------------
Once a new overlay has been created, the overlay needs to be integrated into the Pynq environment.  It is recommended to use an existing Vivado *Overlay project* as a starting point for a new overlay. This will ensure the settings for the Zynq PS, and the existing PS/PL interfaces are used in the new project. 

As with any application running on Zynq, the interface between the software and hardware is via the Zynq memory map. 

To find the addressable IPs of a specific overlay (e.g. `base.bit`), users can do:

.. code-block:: python

   from pynq import Overlay
   Overlay("base.bit").ip_dict


This will show the IP dictionary of the overlay. Each entry in this IP dictionary is a key-value pair. For example, an entry can be: 

    ``'SEG_mb_bram_ctrl_1_Mem0': ['0x40000000', '0x10000', None]``

The key of the entry is the IP instance name; all the IP instance names are parsed from the `*.tcl` file (e.g. `base.tcl`) in the address segment section. The value of the entry is a list of 3 items:

   - The first item shows the base address of the addressable IP (hex).
   - The second item shows the address range in bytes (hex).
   - The third item records the state associated with the IP. It is `None` by default, but can be used flexibly by the users.

Similarly, to find the addressable IPs currently on the programmable logic, users can do:

.. code-block:: python

   from pynq import PL
   PL.ip_dict

To help ease the effort to communicate between the ARM processor and programmable logic, Pynq includes the *MMIO* Python class. Once the overlay has been created, and the memory map is known, the *MMIO* can be used to read/write from/to memory mapped locations in the FPGA fabric. 

The Python code for the MMIO can be viewed here:

    ``<GitHub Repository>/python/pynq/mmio.py``

Continuing the example shown above, we show a use case where the MMIO class can access an area of 0x10000 bytes in the FPFA fabric, starting at address 0x40000000 (`SEG_mb_bram_ctrl_1_Mem0`): 

.. code-block:: python

   from pynq import MMIO

   # an IP is located at 0x40000000
   myip = MMIO(0x40000000,0x10000)

   # Read from the IP at offset 0
   myip.read(0)


In the example above, any accesses outside the address range 0x10000 (65535 bytes) will cause an error. When creating the python driver for a new hardware function, the MMIO can be wrapped inside a Python module. 


New overlay example
-------------------------------------
An example notebook ``overlay_integration.ipynb`` is available in the *Examples* folder, showing how to write Python to interface to an overlay. 


Using new overlays with GPIO
-----------------------------------
GPIO between the Zynq PS and PL can be used by Python code as a control interface to overlays.  The information about a GPIO is kept in the GPIO dictionary of an overlay. 

The following code can be used to get the dictionary for a bitstream:

.. code-block:: python

   from pynq import Overlay
   ol = Overlay("base.bit")
   ol.gpio_dict


A GPIO dictionary entry is a key, value pair, where *value* is a list of two items. An example of the entry in a GPIO dictionary:

    ``'mb_1_reset/Din': [0, None]``

The key is the GPIO instance name (*mb_1_reset/Din*). GPIO instance names are read and parsed from the Vivado `*.tcl` file (e.g. `base.tcl`). 

The *value* is a list of 2 items:

  - The first item shows the index of the GPIO (0).
  - The second item (*None*) shows the state of the GPIO. It is `None` by default, but can be user defined.

The following code can be used to get the dictionary for GPIO currently in the FPGA fabric:

.. code-block:: python

   from pynq import PL
   pl = PL
   pl.gpio_dict



