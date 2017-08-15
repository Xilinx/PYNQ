.. _pynq-package:

****************
``pynq`` Package
****************

All PYNQ code is contained in the *pynq* Python package and can be found on the
on the `Github repository <https://github.com/xilinx/PYNQ/>`_.

To learn more about Python package structures, please refer to the `official
python documentation
<https://docs.python.org/3.5/tutorial/modules.html#packages>`_.

Foundational modules:

  * pynq.ps - Facilitates management of the Processing System (PS) and PS/PL
    interface.
  * pynq.pl - Facilitates management of the Programmable Logic (PL).
  * pynq.overlay - Manages the state, drivers, and and contents of overlays.

Data Movement modules:

  * pynq.mmio - Implements PYNQ Memory Mapped IO (MMIO) API
  * pynq.gpio - Implements PYNQ General-Purpose IO (GPIO) by wrapping the Linux
    Sysfs API
  * pynq.xlnk - Implements Contiguous Memory Allocation for PYNQ DMA

Interrupt/AsyncIO Module:

  * pynq.interrupt - Implements PYNQ asyncio

Sub-packages:

  * pynq.lib - Contains sub-packages with drivers for for PMOD, Arduino and
    Logictools PYNQ Libraries, and drivers for various communication controllers
    (GPIO, DMA, Video, Audio)
    
.. toctree::
    :hidden:
       
    pynq_package/pynq.interrupt
    pynq_package/pynq.gpio
    pynq_package/pynq.lib
    pynq_package/pynq.mmio
    pynq_package/pynq.overlay
    pynq_package/pynq.ps
    pynq_package/pynq.pl
    pynq_package/pynq.xlnk


    
