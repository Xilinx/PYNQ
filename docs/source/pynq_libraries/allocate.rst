.. _pynq-libraries-allocate:

Allocate
========

The ``pynq.allocate`` function is used to allocate memory that will be used by IP
in the programmable logic.

IP connected to the AXI Master (HP or ACP ports) has access to PS DRAM. Before 
IP in the PL accesses DRAM, some memory must first be allocated (reserved) for 
the IP to use and the size, and address of the memory passed to the IP. An 
array in Python, or Numpy, will be allocated somewhere in virtual memory. The 
physical memory address of the allocated memory must be provided to IP in the PL.

``pynq.allocate`` allocates memory which is physically contiguous and returns a
``pynq.Buffer`` object representing the allocated buffer. The buffer is a numpy
array for use with other Python libraries and also provides a
``.device_address`` property which contains the physical address for use with
IP. For backwards compatibility a ``.physical_address`` property is also
provided

The allocate function uses the same signature as ``numpy.ndarray`` allowing for
any shape and data-type supported by numpy to be used with PYNQ.

Buffer
------

The ``Buffer`` object returned is a sub-class of ``numpy.ndarray`` with
additional properties and methods suited for use with the programmable logic.

 * ``device_address`` is the address that should be passed to the programmable
   logic to access the buffer
 * ``coherent`` is True if the buffer is cache-coherent between the PS and PL
 * ``flush`` flushes a non-coherent or mirrored buffer ensuring that any
   changes by the PS are visible to the PL
 * ``invalidate`` invalidates a non-coherent or mirrored buffer ensuring any
   changes by the PL are visible to the PS
 * ``sync_to_device`` is an alias to ``flush``
 * ``sync_from_device`` is an alias to ``invalidate``

Example
-------

Create a contiguous array of 5 32-bit unsigned integers

   .. code-block:: Python

      from pynq import allocate
      input_buffer = allocate(shape=(5,), dtype='u4')

``device_address`` property of the buffer

   .. code-block:: Python

      input_buffer.device_address


Writing data to the buffer:

   .. code-block:: Python

      input_buffer[:] = range(5)

Flushing the buffer to ensure the updated data is visible to the programmable
logic:

   .. code-block:: Python

      input_buffer.flush()

More information about memory allocation can be found in the :ref:`pynq-buffer`
section in the library reference.
