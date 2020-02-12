.. _pynq-package:

****************
``pynq`` Package
****************

All PYNQ code is contained in the *pynq* Python package and can be found on the
on the `Github repository <https://github.com/xilinx/PYNQ/>`_.

To learn more about Python package structures, please refer to the `official
python documentation
<https://docs.python.org/3.6/tutorial/modules.html#packages>`_.

Foundational modules:

  * pynq.ps - Facilitates management of the Processing System (PS) and PS/PL
    interface.
  * pynq.pl - Facilitates management of the Programmable Logic (PL).
  * pynq.overlay - Manages the state, drivers, and and contents of overlays.
  * pynq.bitstream - Instantiates class for PL bitstream (full/partial).
  * pynq.devicetree - Instantiates the device tree segment class.

Data Movement modules:

  * pynq.mmio - Implements PYNQ Memory Mapped IO (MMIO) API
  * pynq.gpio - Implements PYNQ General-Purpose IO (GPIO) by wrapping the Linux
    Sysfs API
  * pynq.xlnk - Implements Contiguous Memory Allocation for PYNQ DMA
  * pynq.buffer - Implements a buffer class for DMA engines and accelerators

Additional modules:

  * pynq.interrupt - Implements PYNQ asyncio
  * pynq.pmbus - PYNQ class for reading power measurements from PMBus 
  * pynq.uio - Interacts directly with a UIO device
  * pynq.registers - Allows users to access registers easily
  * pynq.utils - Functions for assisting with installation and testing

Sub-packages:

  * pynq.lib - Contains sub-packages with drivers for for PMOD, Arduino and
    Logictools PYNQ Libraries, and drivers for various communication controllers
    (GPIO, DMA, Video, Audio, etc.)
  * pynq.pl_server - Contains sub-packages for PL server to work across
    multiple devices. It also includes the overlay metadata parsers 
    (e.g., tcl, hwh)

.. toctree::
    :hidden:

    pynq_package/pynq.lib
    pynq_package/pynq.pl_server
    pynq_package/pynq.bitstream
    pynq_package/pynq.buffer
    pynq_package/pynq.devicetree
    pynq_package/pynq.gpio
    pynq_package/pynq.interrupt
    pynq_package/pynq.mmio
    pynq_package/pynq.overlay
    pynq_package/pynq.pmbus
    pynq_package/pynq.ps
    pynq_package/pynq.registers
    pynq_package/pynq.uio
    pynq_package/pynq.utils
    pynq_package/pynq.xlnk

