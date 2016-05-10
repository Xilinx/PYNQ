Working with Overlays
==============================================

Creating overlays is done using traditional hardware design methods. This document will describe how overlays can be integrated into Pynq by FPGA/Zynq designers, but will not cover the hardware design process. 

While FPGA fabric can be customized to very specific and optimized implementations, a high level of expertise is required to do this, and compared to creating software, is much more time consuming. 

In Pynq, the key concept when designing hardware overlays is that there should be few overlays used for many different applications.

An overlay should be flexible rather than highly customized, even if this results in a less optimal hardware implementation. This is so that each overlay can be reused by many different applications. 

For example, it is recommended that IOPs are used for PMOD interfaces to make the overlay as widely applicable as possible, even where the designer intends to use a specific peripheral for a particular application. 


 


Existing Overlays
-----------------

Two overlays are currently included in the Pynq repository; pmod, and audiovideo. These overlays can be rebuilt in their respective repository folders:

   * Pynq/zybo/vivado/pmod
   * Pynq/zybo/vivado/audiovideo

A makefile exists in each folder that can be used to rebuild the Vivado projects and generate the bitstreams for the overlays. 

Once the projects have been built, they can be opened in Vivado and examined, or modified to create a new overlay. 

.. image:: ./images/pmodio_overlay.jpg
   :scale: 50%
   :align: center
   
Loading Overlays
----------------

The PL can be dynamically reconfigured with new overlays as the system is running. This allows Pynq to swap in and out different overlays to support different functionality required by software applications. 

This can be in Python done using the Overlay class, part of the Pynq PL package here:

   Pynq/python/pynq/pl.py
   
To download a new bitstream, only two lines of Python are required:


.. code-block:: python

   from pynq import Overlay
   Overlay("audiovideo.bit").download()





Integrating new overlays into Pynq
-------------------------------------
Once a new overlay has been created, the overlay needs to be integrated into the Pynq environment.  It is recommended to use an existing overlay Vivado project as a starting point for a new peripheral. This will ensure the settings for the Zynq PS, and the existing PS/PL interfaces are used in the new project. 

As with any application running on Zynq, the interface between the software and hardware is via the memory map for the PS and PL. 

To help ease the effort to communicate between the ARM A9s and programmable logic, Pynq includes the MMIO Python class, which can be used to read and write from the PL memory system. Once the Overlay has been designed, the MMIO can be used to read and write data to the PL.  The Python code for the MMIO can be viewed here:

    Pynq/python/pynq/mmio.py 

An example use of the mmio class to read a PL address of 0x4000_0000 is shown below:

.. code-block:: python

   from pynq import MMIO

   # an IP is located at 0x4000_0000
   myip = MMIO(0x40000000,4096)

   # Read from the IP at offset 0
   myip.read(0)



   



