.. _remote_interrupts:

Remote Interrupts
=================

PYNQ.remote supports hardware interrupts over the network, so interrupt-driven code such as DMA transfer completion and GPIO edge detection works remotely using the same API as a local board.

Usage
-----

Interrupts use the same ``Interrupt`` class as classic PYNQ. Set the ``PYNQ_REMOTE_DEVICES`` environment variable before importing ``pynq`` (see :doc:`env_variables`), then create an ``Interrupt`` for a pin and await it:

.. code-block:: python

   import os
   os.environ["PYNQ_REMOTE_DEVICES"] = "192.168.2.99"  # before importing pynq
   from pynq import Overlay, Interrupt

   ol = Overlay("my_design.bit")
   irq = Interrupt("axi_dma_0/mm2s_introut")
   await irq.wait()

No source changes are required to move interrupt-driven code or notebooks between a local board and a remote board.

Overlay reload
--------------

As in classic PYNQ, downloading a new overlay invalidates existing interrupt objects. A subsequent ``wait()`` raises ``RuntimeError("Interrupt invalidated by Overlay change")``. Create a new ``Interrupt`` after loading a new overlay.

.. note::

    The ``UioController`` class is not used in remote mode; the target device handles the underlying UIO access. Use ``Interrupt`` for interrupt handling.
