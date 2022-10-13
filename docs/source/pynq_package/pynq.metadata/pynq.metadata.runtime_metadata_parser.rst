.. _pynq-metadata-runtime_metadata_parser:

pynq.metadata-runtime_metadata_parser Module
============================================

A class that provides a runtime metadata object. The RuntimeMetadataParser class 
contains a collection  of different views onto the metadata object.
Each view presents a different interpretation of the underlying metadata.

Views:

* ``ip_dict``: a dictionary of all IP that is addressable from the processing system.
* ``hierarchy_dict`` : a dictionary containing the hierarchies of IP in the design.
* ``gpio_dict``: all the GPIO pins controlled by the PS.
* ``interrupt_controllers`` : a dictionary of al AXI interrupt controllers in the system that are attached to the PS.
* ``interrupt_pins`` : all pins attached to an interrupt controller in the interrupt_controllers view
* ``mem_dict``: a dictionary of all the memory regions in the design.
* ``clock_dict``: a dictionary of all the configurable clocks in the design.
 
Views are dynamically updated as the underlying metadata is changed.
However, this is not currently fully supported in the latest release of PYNQ, so one time
deep copies of these dictionaries are made. 

.. automodule:: pynq.metadata.runtime_metadata_parser
    :members:
    :undoc-members:
    :show-inheritance:
