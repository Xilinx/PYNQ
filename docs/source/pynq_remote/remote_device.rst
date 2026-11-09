.. _remote_device:

The RemoteDevice Class
======================

The ``RemoteDevice`` class enables controlling PYNQ boards over network connections using gRPC. It provides a complete remote access solution including bitstream downloading, memory allocation, MMIO operations, and other PYNQ functionalities through remote procedure calls. 

This module includes classes for remote memory management (``RemoteBuffer``), memory-mapped I/O (``RemoteMMIO``), bitstream handling, and communication channel management. The implementation handles multiple bitstream formats (.bit, .bin, .xsa), metadata parsing, and caching while maintaining compatibility with the local PYNQ API. 

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
server; an older server reports that the remote image must be updated.

The ``RemoteDevice`` class is complemented by ``PYNQ.cpp`` which operates on the target device, providing a C++ implementation of the PYNQ API. For more details on the C++ implementation, see the :ref:`cppindex` module documentation.

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

``Device.devices`` follows the address order. Each overlay keeps using its
selected board even if ``Device.active_device`` changes.

Pass ``device`` to standalone ``MMIO``, ``Register`` and ``GPIO`` objects,
and ``target`` to ``allocate``. Without an explicit target, these use
``Device.active_device``. GPIO lookup also accepts ``device``:

.. code-block:: python

   pin = pynq.GPIO.get_gpio_pin(0, device=a)
   output = pynq.GPIO(pin, "out", device=a)

Releasing a GPIO also releases other handles sharing that pin on the same
device instance. Remote interrupt waiting is not supported.

Some class-level interfaces select a board differently:

* ``Clocks`` uses the board of the last overlay created or downloaded.
  Use ``Clocks.set_device(device)`` to select a board explicitly.
* Remote ``xrfclk`` calls accept ``device``. Without it, they use the most
  recently created overlay's board, or the active device before the first overlay.
* ``PL`` describes ``Device.active_device``. Use ``overlay.ip_dict`` to inspect
  a particular overlay.

API Reference
-------------

.. automodule:: pynq.pl_server.remote_device
    :members:
    :undoc-members:
    :show-inheritance:
