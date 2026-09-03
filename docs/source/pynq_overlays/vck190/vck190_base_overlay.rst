.. _vck190-base-overlay:

Base Overlay
============

The purpose of the *base* overlay design for any PYNQ supported board is to
allow peripherals on a board to be used out-of-the-box.

The VCK190 uses Versal segmented configuration. The golden reference design
configures the processors, NoC and DDR during boot. The ``base.pdi`` overlay
configures the programmable logic at runtime without re-initializing the
processor.

The base overlay can also be used as a reference design for creating new
customized overlays.

VCK190 Base Design
------------------

The base overlay on VCK190 includes the following hardware:

    * Four user LEDs, four DIP switches and four push buttons
    * AXI DMA loopback through an AXI Stream FIFO
    * 8 KB block RAM
    * Two AXI timers and an interrupt controller

User IO
-------

The four user LEDs, four DIP switches and four push buttons are each controlled
by an AXI GPIO controller, and are available as the ``leds``, ``switches`` and
``buttons`` attributes of the overlay.

DMA
---

The AXI DMA memory-to-stream and stream-to-memory channels are connected in
loopback through an AXI Stream FIFO. The DMA reaches DDR through the Versal
NoC.

Python API
----------

The VCK190 base overlay is loaded from its PDI:

.. code-block:: Python

   from pynq.overlays.base import BaseOverlay

   base = BaseOverlay("base.pdi")

Examples for LEDs, buttons, DIP switches, DMA, block RAM and interrupts are
provided in ``/home/xilinx/jupyter_notebooks/getting_started.ipynb``.

Rebuilding the Overlay
----------------------

The project files for the overlay can be found here:

.. code-block:: console

   <PYNQ repository>/boards/VCK190/base

The VCK190 image and overlays share a golden reference design. Build the golden
design before rebuilding the base overlay:

.. code-block:: console

   cd <PYNQ repository>/boards/VCK190/golden
   make
   cd ../base
   make

Both designs must be built with Vivado 2025.2. The base overlay checks that its
segmented PDI is compatible with the golden boot image.
