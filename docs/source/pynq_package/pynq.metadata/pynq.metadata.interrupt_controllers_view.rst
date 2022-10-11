.. _pynq-metadata-interrupt_controllers_view:

pynq.metadata-interrupt_controllers_view Module
===============================================

Provides a view onto the Metadata object that displays all the AXI interrupt
controllers that are accessible from the processing system. Models a dictionary
where the key is the name of the interrupt controller and each entry contains:

* ``parent``: either another controller or the PS
* ``index``: the index of this interrupt.

The PS is the root of this hierarchy and is unnamed.


.. automodule:: pynq.metadata.interrupt_controllers_view
    :members:
    :undoc-members:
    :show-inheritance: