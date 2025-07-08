.. _remote_device:

The RemoteDevice Class
======================

The ``RemoteDevice`` class enables controlling PYNQ boards over network connections using gRPC. It provides a complete remote access solution including bitstream downloading, memory allocation, MMIO operations, and other PYNQ functionalities through remote procedure calls. 

This module includes classes for remote memory management (``RemoteBuffer``), memory-mapped I/O (``RemoteMMIO``), bitstream handling, and communication channel management. The implementation handles multiple bitstream formats (.bit, .bin, .xsa), metadata parsing, and caching while maintaining compatibility with the local PYNQ API. 

Remote devices can be configured through the ``PYNQ_REMOTE_DEVICES`` environment variable, which should contain a comma-separated list of IP addresses for target devices. Additionally, separate devices can be specified by directly passing the IP address to the ``RemoteDevice`` constructor.

The ``RemoteDevice`` class is complimented by ``PYNQ.cpp`` which operates on the target device, providing a C++ implementation of the PYNQ API. For more details on the C++ implementation, see the :ref:`cppindex` module documentation.

.. automodule:: pynq.pl_server.remote_device
    :members:
    :undoc-members:
    :show-inheritance: