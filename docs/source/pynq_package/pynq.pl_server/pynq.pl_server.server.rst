.. _pynq-pl_server-server:

pynq.pl_server.server Module
============================

The pynq.pl_server.server module manages all the device servers. The top-level
PL server class manages multiple device servers, while each device server
serves a unique communication socket for a programmable device. On embedded 
system, usually there is only one device per board; hence only one device
server is managed by the PL server. The device client class eases the access
to the device servers for users.

.. automodule:: pynq.pl_server.server
    :members:
    :undoc-members:
    :show-inheritance:
