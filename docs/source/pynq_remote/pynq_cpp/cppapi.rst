PYNQ.cpp C++ API
================

This section documents the `PYNQ.cpp C++ API`, which is used in `PYNQ.remote` to provide a Python interface from a networked host machine to the PYNQ platform. 

This C++ code handles low-level operations such as device management, memory-mapped I/O, and buffer management. 
The following classes provide device abstraction, MMIO, and remote buffer management for supported AMD PYNQ-enabled platforms, and can be used in independent C++ applications on PYNQ devices.

Device Class
------------

.. doxygenclass:: Device
   :project: Device
   :members:
   :undoc-members:
   :protected-members:
   :private-members:

MMIO Class
----------

.. doxygenclass:: MMIO
   :project: Device
   :members:
   :undoc-members:
   :protected-members:
   :private-members:

BufferRemote Class
------------------

.. doxygenclass:: BufferRemote
   :project: Device
   :members:
   :undoc-members:
   :protected-members:
   :private-members:

XrtBufferManager Class
----------------------

.. doxygenclass:: XrtBufferManager
   :project: Device
   :members:
   :undoc-members:
   :protected-members:
   :private-members:
