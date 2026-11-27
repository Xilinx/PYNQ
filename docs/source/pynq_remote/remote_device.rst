.. _remote_device:

The RemoteDevice Class
======================

The ``RemoteDevice`` class enables controlling PYNQ boards over network connections using gRPC. It provides bitstream downloading, memory allocation and MMIO operations through remote procedure calls.

This module includes classes for remote memory management (``RemoteBuffer``), memory-mapped I/O (``RemoteMMIO``), bitstream handling, and communication channel management. It handles .bit, .bin, .xsa and .pdi files, with metadata parsing and caching on the host.

Remote devices can be configured through the ``PYNQ_REMOTE_DEVICES`` environment
variable, which should contain a comma-separated list of IP addresses for target
devices. Alternatively, construct a ``RemoteDevice`` directly and pass it to
``Overlay``:

.. code-block:: python

   from pynq import Overlay
   from pynq.pl_server.remote_device import RemoteDevice

   dev = RemoteDevice(0, "192.168.2.99")
   overlay = Overlay("design.bit", device=dev)

When ``PYNQ_REMOTE_DEVICES`` is set, ``Device.devices`` lists one
``RemoteDevice`` per address and ``Overlay`` uses the active device if no
``device`` argument is given.

``RemoteDevice`` returns a subclass that matches the board's SoC:
``RemoteZynqDevice``, ``RemoteZynqUltrascaleDevice`` or ``RemoteVersalDevice``.
Local and remote devices share the architecture classes in
:mod:`pynq.pl_server.arch`.

Device tree overlays (``.dtbo``) shipped with a bitstream are applied on the
board. This needs a remote image built with the matching ``pynq-remote``
server. Update older remote images before downloading a full bitstream or
applying device tree overlays.

Device tree files must be nonempty and no larger than 1 MiB. Before a full
bitstream download, PYNQ removes the board's PYNQ.remote device tree overlays,
including those installed by other clients.

The ``RemoteDevice`` class is complemented by ``PYNQ.cpp`` which operates on the target device, providing a C++ implementation of the PYNQ API. For more details on the C++ implementation, see the :ref:`cppindex` module documentation.

Interrupts
----------

PL interrupts use the same asynchronous interface as local PYNQ. Pass the
remote device when creating a standalone interrupt:

.. code-block:: python

   from pynq import Interrupt

   interrupt = Interrupt("my_ip/interrupt", device=dev)
   await interrupt.wait()

Overlay drivers create interrupts for their selected device. DMA transfers
can use ``await dma.recvchannel.wait_async()`` or
``await dma.sendchannel.wait_async()``. The peripheral's interrupt condition
must be cleared before waiting again; the DMA driver handles this when its
transfer completes. Several events before rearming may be combined, so use
the peripheral's status or counters when individual events must be counted.

Interrupts can connect directly to the PS or through AXI interrupt
controllers, including cascaded controllers. The PS interrupt must have a
UIO device on the board; the standard images provide the first PL-to-PS
interrupt line.

Independent clients can wait on different interrupt sources in the same
loaded overlay. Additional clients must attach without downloading it again:

.. code-block:: python

   overlay = Overlay("design.bit", device=dev, download=False)

Each source is owned by one client; another client waiting
on that source receives an error. Multiple waiters within the owning client
are notified together. Cancelling the last wait disables that source while
retaining ownership. Ownership is released when its interrupt objects are
discarded or the client disconnects.

Changing the overlay invalidates existing interrupt objects and fails pending
waits in every client. A lost connection also fails pending waits. Recreate
the interrupt objects before waiting again. Older remote images report an
unsupported-feature error when an interrupt wait is requested; update the
remote image to use interrupts. RF data converter-specific interrupt control
and callbacks remain unsupported.

Several Remote Boards in One Session
------------------------------------

On a PYNQ.remote host, list the board addresses before importing ``pynq``.
Create an overlay for each board using its ``device``:

.. code-block:: python

   import os
   os.environ["PYNQ_REMOTE_DEVICES"] = "192.168.2.99,192.168.2.100"

   import pynq

   a, b = pynq.Device.devices
   overlay_a = pynq.Overlay("design_a.bit", device=a)
   overlay_b = pynq.Overlay("design_b.bit", device=b)

   buffer = pynq.allocate(1024, target=b)

The remote entries in ``Device.devices`` follow the address order. Other
backends can also contribute devices; the example assumes only these two
remote devices are discovered.

Overlay programming and resources created by the default overlay drivers use
the selected board even if ``Device.active_device`` changes. Drivers that use
global ``PL`` metadata or create resources without passing ``device`` can still
use the active device; check such drivers before using them with several boards.

Pass ``device`` to standalone ``MMIO``, ``Register`` and ``GPIO`` objects,
and ``target`` to ``allocate``. Without an explicit target, these use
``Device.active_device``. GPIO lookup also accepts ``device``:

.. code-block:: python

   pin = pynq.GPIO.get_gpio_pin(0, device=a)
   output = pynq.GPIO(pin, "out", device=a)

Releasing a GPIO also releases other handles sharing that pin on the same
device instance.

Some class-level interfaces select a board differently:

* ``Clocks`` uses the board of the last overlay created or downloaded.
  Use ``Clocks.set_device(device)`` to select a board explicitly.
* Remote ``xrfclk`` calls accept ``device``. Without it, they use the most
  recently created remote overlay's board, or the active device before the first
  remote overlay.
* ``PL`` describes ``Device.active_device``. Use ``overlay.ip_dict`` to inspect
  a particular overlay.

API Reference
-------------

.. automodule:: pynq.pl_server.remote_device
    :members:
    :undoc-members:
    :show-inheritance:
