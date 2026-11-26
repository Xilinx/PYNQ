JTAG devices
============

The ``JtagDevice`` class allows PYNQ to program an FPGA and access its registers
and memory over JTAG. An overlay loaded on a JTAG device exposes its IP through
the PYNQ overlay API, including drivers such as AXI GPIO. Drivers that require
PS GPIO or host interrupts cannot be used through this connection.

The host requires Vivado or Vivado Lab, with both the tools and ``hw_server`` on
``PATH``. Install PYNQ using the host installation option, ``PYNQ_REMOTE=1``.
The FPGA design must contain one JTAG-to-AXI master with a 32-bit data bus and
32-bit addresses. Supply a complete ``.bit`` file and a matching ``.hwh`` file
with the same name in the same directory.

Example
-------

Create a JTAG device and pass it to ``Overlay`` to program the FPGA. The following
example selects a memory described by the overlay's HWH metadata and allocates
a buffer in that memory. The selected memory must have space for 256 unsigned
32-bit integers. The context managers release the buffer and close the device
when the example finishes::

    from pynq import Overlay, allocate
    from pynq.pl_server import JtagDevice

    with JtagDevice() as device:
        overlay = Overlay("design.bit", device=device)
        # Select a memory exposed by this design's HWH metadata.
        memory = device.get_memory(next(iter(overlay.mem_dict.values())))
        with allocate((256,), dtype="u4", target=memory) as buffer:
            buffer[:] = range(256)
            buffer.sync_to_device()
            buffer.sync_from_device()

Working with memory
-------------------

A JTAG buffer is a host NumPy array backed by an allocation in FPGA memory.
``sync_to_device`` copies changes from the host array to the FPGA, while
``sync_from_device`` updates the host array with data from the FPGA. In the
example, these calls write the values to FPGA memory and read them back.

Buffers and slices must be contiguous to be synchronised. Synchronisation
handles partial words in contiguous byte-buffer slices; direct register and
byte-transfer addresses and lengths must be multiples of four.

Use buffers and their views within the lifetime of the allocation. After
loading another overlay, obtain new memory objects and buffers from that
overlay, since reprogramming invalidates the previous ones.

JTAG connections
----------------

The default connection requires one JTAG target. When several targets are
available, select one by passing its complete Hardware Manager target name as
``JtagDevice(target=...)``. The selected target must contain exactly one FPGA.

PYNQ connects to a local ``hw_server`` on port 3121, starting one if needed.
A server started by PYNQ is closed when the last JTAG device in that Python
process closes. If other clients need to keep using the server after that,
start it separately before creating the device; PYNQ leaves an existing
server running.

If Vivado exits, a request times out, or communication is interrupted, the
session closes. Create a new device and reload the overlay before continuing.

.. automodule:: pynq.pl_server.jtag_device
    :members: JtagDevice
