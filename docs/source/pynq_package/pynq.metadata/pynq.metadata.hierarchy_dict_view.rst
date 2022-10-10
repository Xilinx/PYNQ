.. _pynq-metadata-hierarchy_dict_view:

pynq.metadata-hierarchy_dict_view Module
========================================

Provides a hierarchy view onto the Metadata object that will display
all hierarchies of addressable IP from the Processing System.

All IP when parsed into the HWH file is flat with no hierarchies. 
However, there is an additional, full_name field that can be used to reconstruct
these hierarchies, which is what this view uses. 

This view models a dictionary where each key is the name of the hierarchy, and each
entry contains:

* a dictionary of all the IP contained within that level of the hierarchy.
* a dictionare of all the memory objects within that level of the hierarchy.
* a dictionary of sub-hierarchies contained within this level of the hierarchy.
* any drivers that have been assigned to this level of the hierarchy.Provides a hierarchy view onto the Metadata object that will display all hierarchies of addressable IP from the Processing System.

All IP when parsed into the HWH file is flat with no hierarchies. 
However, there is an additional, full_name field that can be used to reconstruct
these hierarchies, which is what this view uses. 

This view models a dictionary where each key is the name of the hierarchy, and each
entry contains:

* a dictionary of all the IP contained within that level of the hierarchy.
* a dictionare of all the memory objects within that level of the hierarchy.
* a dictionary of sub-hierarchies contained within this level of the hierarchy.
* any drivers that have been assigned to this level of the hierarchy.


.. automodule:: pynq.metadata.hierarchy_dict_view
    :members:
    :undoc-members:
    :show-inheritance: