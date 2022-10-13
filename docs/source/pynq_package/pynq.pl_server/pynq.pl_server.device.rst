.. _pynq-pl_server-device:

pynq.pl_server.device Module
============================

The pynq.pl_server.device module exposes the user frontend for a device on 
a Linux system. This class, as a singleton for each device, manages
the device status by communicating either with the device class directly, 
or via the global state file that contains the metadata for the loaded device.
As a special case, the **Device** extends the device class and implements  
its own way of memory management.

.. automodule:: pynq.pl_server.device
    :members:
    :undoc-members:
    :show-inheritance:
