Creating Overlays
==============================================

Creating overlays is done using traditional hardware design methods, and the design process will not be covered in this document. 

How overlays can be created and integrated into Pynq by FPGA/Zynq designers will be explained. 

While FPGA fabric has the ability to be customized to very specific and optimized implementations, a high level of expertise is required to do this. Compared to building and compiling software, this is typically a time consuing process.

The key concept of overlays in Pynq is that an overlay should be as flexible and generic as possible so that it can be as applicable to as many differen applications as possible. 

For example, it is recommended that IOPs are used for PMOD interfaces to make the overlay as widely applicable as possible, even where the designer intends to use a specific peripheral. 

Rather than customizing any other hardware components in the design, it is recommended to make the hardware generic, and as flexible as possible. 

There should be few overlays used for many different applications.

Provided Overlays
-----------------

Two overlays are currently included in the Pynq repository; pmod, and audiovideo. Both can be found here:

   Pynq/zybo/vivado

A makefile exists in the same location that can be used to build the Vivado projects, and generate the bitstreams for the overlays. Once the projects have been built, they can be opened in Vivado and modified to create a new overlay, or a new overlay can be created. 

Integratig new overlays into Pynq
-------------------------------------
Creating overlays for experienced FPGA/Zynq designers using Vivado should be familiar. 

The important part of the process of creating a new overlay is the interface to the Pynq environment. 

The Zynq design should be created as normal. As with any application running on Zynq, the interface between the software and hardware is via the memory map for the PS and PL. 

Pynq includes the MMIO switch which can be used to read and write from the PL memory system. Once the Overlay has been designed, the MMIO can be used to read and write data to the PL. The same design principles for Zynq designs apply to creating overlays when choosing PS/PL interfaces and transferring data.
 
The MMIO does not currently use a DMA, and there will be an overhead using the MMIO to read and write data, so it is recommended that this is used for control signals.  

The Python code for the MMIO can be viewed here:

    Pynq\python\pynq\mmio.py 

Loading Overlays
----------------

The PL can be dynamically reconfigured with new overlays as the system is running. This allows Pynq to swap in and out different overlays to support different functionality in the PL. 

This can be done using the Overlay class, part of the PL package here:

   Pynq/python/pynq/pl.py
   



