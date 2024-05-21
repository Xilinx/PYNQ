.. _pynq-metadata:

pynq.metadata Package
=====================

The pynq.metadata module contains the required modules for managing the Overlay metadata. 
The metadata can be extracted from a HWH file or an XSA and contains the complete hardware
design. This module also contains a collection of different views onto the metadata that
present the metadata as the traditional PYNQ dicts.

Modules:
  * :mod:`pynq.metadata.runtime_metadata_parser` - A wrapper class that provides a collection of different view onto the metadata. 
  * :mod:`pynq.metadata.metadata_view` - A base class for metadata views providing getters and iterators.
  * :mod:`pynq.metadata.ip_dict_view` - A view onto the metadata that displays the ip_dict.
  * :mod:`pynq.metadata.mem_dict_view` - A view onto the metadata that displays the mem_dict.
  * :mod:`pynq.metadata.interrupt_controllers_view` - A view onto the metadata that displays the interrupt_controllers dictionary.
  * :mod:`pynq.metadata.hierarchy_dict_view` - A view onto the metadata that displays the hierarchy_dict.
  * :mod:`pynq.metadata.gpio_dict_view` - A view onto the metadata that displays the gpio_dict.
  * :mod:`pynq.metadata.clock_dict_view` - A view onto the metadata that displays the clock_dict.

.. toctree::
    :hidden:

    pynq.metadata/pynq.metadata.runtime_metadata_parser
    pynq.metadata/pynq.metadata.metadata_view
    pynq.metadata/pynq.metadata.ip_dict_view
    pynq.metadata/pynq.metadata.mem_dict_view
    pynq.metadata/pynq.metadata.interrupt_controllers_view
    pynq.metadata/pynq.metadata.hierarchy_dict_view
    pynq.metadata/pynq.metadata.gpio_dict_view
    pynq.metadata/pynq.metadata.clock_dict_view