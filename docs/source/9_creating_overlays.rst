Creating Overlays
==============================================

Creating overlays is done using traditional hardware design methods. This document will describe how overlays can be integrated into Pynq by FPGA/Zynq designers, but will not cover the hardware design process. 

While FPGA fabric can be customized to very specific and optimized implementations, a high level of expertise is required to do this, and compared to creating software, is much more time consuming. 

In Pynq, the key concept when designing hardware overlays is that there should be few overlays used for many different applications.

An overlay should be flexible rather than highly customized, even if this results in a less optimal hardware implementation. This is so that each overlay can be reused by many different applications. 

For example, it is recommended that IOPs are used for PMOD interfaces to make the overlay as widely applicable as possible, even where the designer intends to use a specific peripheral for a particular application. 


Existing Overlays
-----------------

Two overlays are currently included in the Pynq repository; pmod, and audiovideo. Both can be found here:

   Pynq/zybo/vivado

A makefile exists in the same location that can be used to build the Vivado projects, and generate the bitstreams for the overlays. 

Once the projects have been built, they can be opened in Vivado and examined, or modified to create a new overlay. 

.. image:: ./images/pmodio_overlay.jpg
   :scale: 50%
   :align: center
   
Integrating new overlays into Pynq
-------------------------------------
Once a new overlay has been created by an experienced FPGA/Zynq designer, the overlay needs to be integrated into the Pynq environment. 

It is recommended to use an existing overlay Vivado project as a starting point for a new peripheral. This will ensure the settings for the Zynq PS, and the existing PS/PL interfaces are used in the new project. 

As with any application running on Zynq, the interface between the software and hardware is via the memory map for the PS and PL. 

Pynq includes the MMIO Python class, which can be used to read and write from the PL memory system. Once the Overlay has been designed, the MMIO can be used to read and write data to the PL. 

The same design principles for Zynq designs apply to creating overlays when choosing PS/PL interfaces and transferring data. The MMIO does not currently use a DMA, and there will be an overhead using the MMIO to read and write data, so it is recommended that this is used for control signals.  

The Python code for the MMIO can be viewed here:

    Pynq/python/pynq/mmio.py 

Loading Overlays
----------------

The PL can be dynamically reconfigured with new overlays as the system is running. This allows Pynq to swap in and out different overlays to support different functionality in the PL. 

This can be in Python done using the Overlay class, part of the Pynq PL package here:

   Pynq/python/pynq/pl.py
   
To use this class, the Overlay class must first be imported:
   
   from pynq import Overlay

The Overlay bitstream can be specified:

ol = Overlay("audiovideo.bit")

Finally, the overlay can be downloaded and used to configure the Zynq PL:

   ol.download()
   



