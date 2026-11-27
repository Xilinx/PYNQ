.. _pynq-overlays:

*************
PYNQ Overlays
*************

AMD MPSoCs combine multiple processing units, such as application and real-time
processors, into what is referred to as the *Processing System* (**PS**) with
Programmable Logic (**PL**). The *PS* subsystem includes dedicated peripherals
and can be extended with additional hardware IP in a *PL* overlay. Versal devices
further this to include reprogrammable Adaptable Intelligent (**AI**) Engines.

.. image:: images/zynq_block_diagram.jpg
   :align: center

Overlays, or hardware libraries, are programmable/configurable FPGA designs that
extend the user application from the Processing System of the SoC into the
Programmable Logic. Overlays can be used to accelerate a software application,
or to customize the hardware platform for a particular application. Above, a diagram
of the (now deprecated) Zynq-7000 series is shown to demonstrate an Overlay with custom
accelerators.

For example, image processing is a typical application where the FPGAs can
provide acceleration. A software programmer can use an overlay in a similar way
to a software library to run some of the image processing functions (e.g. edge
detect, thresholding etc.) on the FPGA fabric. Overlays can be loaded to the
FPGA dynamically, as required, just like a software library. In this example,
separate image processing functions could be implemented in different overlays
and loaded from Python on demand.

PYNQ provides a Python interface to allow overlays in the *PL* to be controlled
from Python running in the *PS*. FPGA design is a specialized task which
requires hardware engineering knowledge and expertise. PYNQ overlays are created
by hardware designers, and wrapped with the PYNQ Python API. Software
developers can then use the Python interface to program and control specialized
hardware overlays without needing to design an overlay themselves. This is
analogous to software libraries created by expert developers which are then used
by many other software developers working at the application level.

.. warning::
    PYNQ cannot currenntly be used program Versal overlays with custom AI Engine designs.

.. toctree::
    :maxdepth: 1
    :hidden:
   
    pynq_overlays/zcu104
    pynq_overlays/vck190