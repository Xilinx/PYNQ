.. _pynq-pl_server-global_state:

pynq.pl_server.global_state Module
==================================

The pynq.pl_server.global_state module manages the global state file for the device. 
Using PYNQ-Metadata, it creates a JSON representation of the currently loaded Overlay
in the install location of the module. This global state file is checked on overlay
download to determine if any AXI shutdown IP Cores need to be triggered
before the bitstream is loaded onto the device. The global state file also provides
a way for processes outside the one that loaded the Overlay to inspect the state
of the PL and interact with IP. 

.. automodule:: pynq.pl_server.global_state
    :members:
    :undoc-members:
    :show-inheritance:
