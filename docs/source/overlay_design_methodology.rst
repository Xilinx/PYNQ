.. _overlay-design-methodology:

**************************
Overlay Design Methodology
**************************

As described in the PYNQ introduction, overlays are analogous to software
libraries. A programmer can download overlays into the Zynq® PL at runtime to
provide functionality required by the software application.

An *overlay* is a class of Programmable Logic design. Programmable Logic designs
are usually highly optimized for a specific task. Overlays however, are designed
to be configurable, and reusable for broad set of applications. A PYNQ overlay
will have a Python interface, allowing a software programmer to use it like any
other Python package.

A software programmer can use an overlay, but will not usually create overlay,
as this usually requires a high degree of hardware design expertise.

There are a number of components required in the process of creating an overlay:

  * Board Settings
  * PS-PL Interface
  * MicroBlaze Soft Processors
  * Python/C Integration
  * Python AsyncIO
  * Python Overlay API
  * Python Packaging

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
   overlay_design_methodology/python_packaging
   overlay_design_methodology/overlay_tutorial.ipynb

   
