Python Overlay API
==================

The Python API is the user interface for the overlay, exposing the programmable
functionality in the design.

An API for a PYNQ overlay can consist of

* a simple Python wrapper that interfaces directly with the hardware IP blocks
  in the overlay
* a more substantial Python layer utilising other Python packages
* a Python library that interfaces to a lower level higher performance library
  (written in C/C++ for example) to control the overlay

The API for an overlay will manage the transfer of data between the Python
environment in the PS, and the overlay in the PL. This may be the transfer of
data directly from the PS to a peripheral or managing system memory to allow a
peripheral in the PL to read or write data from DRAM that can also be access by
from the Python environment.

The Default API
---------------

When and Overlay is loaded using the ``pynq.Overlay`` function all of the IP and
hierarchies in the overlay will have drivers assigned to them and used to
construct an object hierarchy. The IP can then be accessed via attributes on the
returned overlay class using the names of the IP and hierarchies in the block
diagram.

If no driver has been specified for a type of IP then a ``DefaultIP`` will be
instantiated offering ``read`` and ``write`` functions to access the IP's
address space and named accessors to any interrupts or GPIO pins connected to
the IP. Hierarchies likewise will be instances of ``DefaultHierarchy`` offering
access to any sub hierarchies or contained IP. The top-level ``DefaultOverlay``
also acts just like any other IP.

Customising Drivers
-------------------

While the default drivers are useful for getting started with new hardware in a
design it is preferable to have a higher level driver for end users to interact
with. Each of ``DefaultIP``, ``DefaultHierarchy`` and ``DefaultOverlay`` can be
subclassed and automatically bound to elements of the block diagram. New drivers
will only be bound when the overlay is reloaded.

Creating IP Drivers
^^^^^^^^^^^^^^^^^^^

All IP drivers should inherit from ``DefaultIP`` and include a ``bindto`` class
attribute consisting of an array of strings. Each string should be a type of IP
that the driver should bind to. It is also strongly recommend to call
``super().__init__`` in the class's constructor. The type of an IP can be found
as the VLNV parameter in Vivado or from the ``ip_dict`` of the overlay.

A template for an IP driver is as follows:

.. code-block:: Python

    from pynq import DefaultIP

    class MyIP(DefaultIP):
        bindto = ['My IP Type']
        def __init__(self, description):
            super().__init__(description)

Creating Hierarchy Drivers
^^^^^^^^^^^^^^^^^^^^^^^^^^

Hierarchy drivers should inherit from ``DefaultHierarchy`` and provide a static
method ``checkhierarchy`` that takes a description and returns ``True`` if the
driver can bind to it. Any class that meets these two requirements will be
automatically added to a list of drivers tested against each hierarchy in a
newly loaded overlay.

A template for a hierarchy driver is as follows:

.. code-block:: Python

    from pynq import DefaultHierarchy

    class MyHierarchy(DefaultHierarchy)
        def __init__(self, description):
            super().__init__(description)

        @staticmethod
        def checkhierarchy(description):
            return False

Creating Custom Overlay Classes
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

Finally the class changed from the ``DefaultOverlay`` to provide a more suitable
high-level API or provide overlay-specific initialisation. The overlay loader
will look for a python file located alongside the bitstream and TCL files,
import it and then call the ``Overlay`` function.

A template for a custom overlay class is as follows:

.. code-block:: Python

    from pynq import DefaultOverlay

    class MyOverlay(DefaultOverlay):
        def __init__(self, bitfile_name, download):
            super().__init__(bitfile_name, download)

            # Other initialisation

    Overlay = MyOverlay

Working with Physically Contiguous Memory
-----------------------------------------

In many applications there is a need for large buffers to be transferred between
the PS and PL either using DMA engines or HLS IP with AXI master interfaces. In
PYNQ the ``Xlnk`` class provides a mechanism to acquire numpy arrays allocated
as to be physically contiguous. First an instance of the xlnk class must be
instantiated:

.. code-block:: Python

    from pynq import Xlnk

    xlnk = Xlnk()

Then the ``cma_array`` function can be used to allocate a physically contiguous
numpy array. The function takes a ``shape`` parameter and a ``dtype`` parameter
in a similar way to other numpy construction functions.

.. code-block:: Python

    import numpy as np

    matrix1 = xlnk.cma_array(shape=(32,32), dtype=np.float32)

These arrays can either be passed directly to the DMA driver's ``transfer``
function or they contain a ``physical_address`` attribute which can be used by
custom driver code.

When the array is no longer needed the underlying resources should be freed
using the ``freebuffer`` function. Alternatively a context manager can be used
to ensure that the buffer is freed at the end of a scope.

.. code-block:: Python

    with xlnk.cma_array(shape=(32,32), dtype=np.float32) as matrix2:
        dma.sendchannel.transfer(matrix2)
        dma.recvchannel.transfer(matrix1)
        dma.sendchannel.wait()
        dma.recvchannel.wait()
        matrix1.freebuffer()

