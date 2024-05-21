.. _overlay-design-methodology:

**************************
Overlay Design Methodology
**************************

PYNQ *Overlays* are analogous to software
libraries. A programmer can download overlays into the AMD-Xilinx Programmable 
Logic at runtime to
provide functionality required by the software application.

An *overlay* is a class of Programmable Logic design. Programmable Logic designs
are usually highly optimized for a specific task. Overlays however, are designed
to be configurable, and reusable for broad set of applications. A PYNQ overlay
will have a Python interface, allowing a software programmer to use it like any
other Python package.

There are a number of components required in the process of creating an overlay:

  * Board or platform settings
  * Interfaces between host processor and programmable logic
  * MicroBlaze Soft Processors
  * Python/C Integration
  * Python AsyncIO
  * Python Overlay API
  * Python Packaging
  
While they are conceptually similar, there are differences in the process for 
building Overlays for different platforms. i.e. Zynq vs. Zynq Ultrascale+ vs. 
Kria SoM vs. Alveo platforms. Most of the differences relate to the configuration of the 
Zynq/Zynq Ultrascale+ PS, and the interfaces between the host processor and the
programmable logic. E.g. AXI interfaces for ARM & Zynq/Zynq Ultrascale+/Kria SoM, and 
PCIe for x86|IBM|ARM|etc. for Alveo. Most of the differences will be related to
the hardware (Programmable logic) design.

This section will give an overview of the process of creating an overlay and
integrating it into PYNQ, but will not cover the hardware design process in
detail. Hardware design will be familiar to Zynq, and FPGA hardware developers.

.. toctree::
   :maxdepth: 2
   :hidden:

   overlay_design_methodology/overlay_design 
   overlay_design_methodology/board_settings
   overlay_design_methodology/pspl_interface
   overlay_design_methodology/pynq_microblaze_subsystem
   overlay_design_methodology/python-c_integration
   overlay_design_methodology/pynq_and_asyncio
   overlay_design_methodology/python_overlay_api
   overlay_design_methodology/pynq_utils
   overlay_design_methodology/python_packaging
   overlay_design_methodology/partial_reconfiguration.rst
   overlay_design_methodology/overlay_tutorial.ipynb

   
