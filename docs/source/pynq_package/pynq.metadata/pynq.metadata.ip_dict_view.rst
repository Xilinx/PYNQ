.. _pynq-metadata-ip_dict_view:

pynq.metadata-ip_dict_view Module
=================================

Provides a view onto the Metadata object that displays all 
addressable IP from the Processing System. Models a dictionary,
where the key is the IP name, and each entry contains:

* physical address
* address range
* type
* parameters dictionary
* register dictionary
* any associated state

The produced view dictionary has the type:  

``IP: {str: {‘phys_addr’ : int, ‘addr_range’ : int, ‘type’ : str, ‘parameters’ : dict, ‘registers’: dict, ‘state’ : str}}``


.. automodule:: pynq.metadata.ip_dict_view
    :members:
    :undoc-members:
    :show-inheritance: