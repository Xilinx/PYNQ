PYNQ on XRT Platforms
=====================

PYNQ now supports XRT-based platforms including Amazon's AWS F1 and Alveo for
cloud and on-premise deployment. PYNQ Alveo Edition contains the updated
PYNQ libraries for PCIe support and new examples to help get started quickly.
If you are new to PYNQ we recommend browsing the rest of the documentation to
fully understand the core PYNQ concepts as these form the foundation of PYNQ
Alveo Edition. Here we will explore what's changed to bring PYNQ into the
world of PCIe based FPGA compute.

Programming the Device
----------------------

The ``Overlay`` class still forms the core of interacting with a design on the
FPGA fabric. When running on an XRT device the Overlay class will now accept
an xclbin file directly and will automatically download the bitstream.

.. code:: python

    ol = pynq.Overlay('my_design.xclbin')

The Overlay instance will contain properties for each IP and, new to Alveo,
memory that is accessible in the design. For a human-readable summary of an
overlay instance you can use the ``?`` operator in IPython or Jupyter or
print the ``__doc__`` attribute.

Allocating Memory
-----------------

One of the big changes with a PCIe FPGA is how memory is allocated. There are
potentially multiple banks of DDR and PLRAM available and buffers need to be
placed into the appropriate buffer. Fabric-accessible memory is still
allocated using ``pynq.allocate`` with the new ``target`` keyword parameter
used to select which bank the buffer should be allocated in.

.. code:: python

    buf = pynq.allocate((1024,1024), 'u4', target=ol.bank1)

Memory banks are named based on the Alveo shell that is in use and can be
found through the overlay class and in the shell's documentation.

Buffers also need to be explicitly synchronized between the host and
accelerator card memories. We have reloaded the terminology from our
embedded devices with memory being ``flush`` ed and ``invalidate`` d.

.. code:: python

    input_buf.flush()
    output_buffer.invalidate()

It is also possible to transfer only part of a buffer by slicing the array
prior to calling flush or invalidate.

.. code:: python

    input_buffer[0:64].flush()

Kernel Streams
--------------

Kernel-to-kernel (K2K) streams are supported by PYNQ and are exposed as part of
the memory infrastructure. In SDAccel or Vitis designs the K2K streams are
given names in the form of ``dc_#`` and will appear in the memory dictionary
with the entry ``streaming: True``. The docstring of the overlay will also
identify streams under the *Memories* section.

.. code::

    Memories
    ------------
    bank1                : Memory
    dc_0                 : Stream
    dc_1                 : Stream
    dc_2                 : Stream
    dc_3                 : Stream
    dc_4                 : Stream

Accessing a stream member of an overlay will give an ``XrtStream`` describing
the endpoints of the stream. Following from the above example:

.. code:: python

    > ol.dc_3
    XrtStream(source=vadd_1.out_c, sink=vmult_1.in_a)

The ``source`` and ``sink`` attributes are strings in the form ``{ip}.{port}``.
If the driver for an endpoint has been initialized then there will also be
``source_ip`` and ``sink_ip`` attributes pointing to the respective driver
interfaces.

Note that despite being described by the memory dictionary it is not possible
pass a stream object as a ``target`` to ``pynq.allocate``.

The other way of accessing stream objects is via the ``streams`` dictionary of
an IP driver. This will return the same object as derived from the overlay.

.. code:: python

    > ol.vadd_1.stream
    {'out_c': XrtStream(source=vadd_1.out_c, sink=vmult_1.in_a)}

Running Accelerators
--------------------

PYNQ Alveo Edition provides the same access to the registers of the kernels
on the card as IP in a ZYNQ design however one of the advantages of the XRT
environment is that we have more information on the types and argument names
for the kernels. For this reason we have added the ability to call kernels
directly without needing to explicitly read and write registers

.. code:: python

    ol.my_kernel.call(input_buf, output_buf)

For HLS C++ or OpenCL kernels the  signature of the ``call`` function will
mirror the function in the original source. You can see how that has been
interpreted in Python by looking at the ``.signature`` property of the kernel.
``.call`` will call the kernel synchronously, returning only when the
execution has finished. For more complex sequences of kernel calls it may
be desirable to start accelerators without waiting for them to complete
before continuing. To support this there is also a ``.start`` function
which takes the same arguments as ``.call`` but returns a handle that has a
``.wait()`` function that will block until the kernel has finished. Note that
it currently results in undefined behavior to call ``.start()`` before
calling ``.wait()`` on the previously returned handle.

Efficient Scheduling of Multiple Kernels
----------------------------------------

In addition to ``.start`` each IP also has a ``.start_ert`` method which uses
the low-level scheduler or *embedded runtime* (ERT). The ERT can handle a queue
of tasks with much lower latency than the user-space based PYNQ library.
``start_ert`` has the same function signature as ``start`` and can in most
cases be used as a drop-in replacement - except that multiple calls to
``start_ert`` can be made without waiting for the previous kernel execution to
finish.

``start_ert`` can also handle tasks with dependencies using the ``waitlist``
keyword parameter. The ``waitlist`` is a list of handles to tasks that must
complete before ``start`` should be resolved. As an example consider the
following snippet that chains two calls to a vector addition accelerator to
compute the sum of three arrays.

.. code:: python

    handle1 = ol.vadd_1.start_ert(input1, input2, output)
    handle2 = ol.vadd_1.start_ert(input3, output, output, waitlist=(handle1,))
    handle2.wait()

Note that calls to ``start`` and ``start_ert`` should not be mixed for the same
accelerator - even across multiple PYNQ processes.

Freeing Designs
---------------

XRT requires that device memory and accelerators be freed before the card can
be reprogrammed. Memory will be freed when the buffers are deleted however the
accelerators need to be explicitly freed by calling the ``Overlay.free()``
method. The overlay will be freed automatically when a new ``Overlay`` object
is created in the same process as the currently-loaded overlay.

Multiple Cards
--------------

In datacenter applications it is possible to have multiple accelerator cards
in one server. PYNQ provides a ``Device`` class to designate which card should
be used for given operations. The first operation is to query the cards in the
system:

.. code:: python

    print(pynq.Device.devices)

The first device in the list is chosen as the *active device* at start-up. To
change this the ``active_device`` property of the ``Device`` class can be
updated.

.. code:: python

    pynq.Device.active_device = python.Device.devices[2]

To use multiple devices in the same PYNQ instance the ``Overlay`` class has
a ``device`` keyword parameter that can be used to override the active device
for this overlay. Note that the PYNQ framework doesn't at present do any
error checking to ensure that buffers have been allocated on the same card
that a kernel is on. It is up to you to ensure that only the correct buffers
are used with the correct cards.

.. code:: python

    overlay_1 = pynq.Overlay('my_overlay1.xclbin', device=pynq.Device.devices[0])
    overlay_2 = pynq.Overlay('my_overlay2.xclbin', device=pynq.Device.devices[1])
