.. _pynq-metadata-clock_dict_view:

pynq.metadata-clock_dict_view Module
====================================

Provides a view onto the Metadata object that displays all
configurable clocks in the system. Models a dictionary, where
the key is the index for the clock and the values contain:

* ``enable`` : ``int`` whether the clock is enabled, ``1`` when enabled, ``0`` when disabled.
* ``divisor0`` : ``int`` divisor value for the clock
* ``divisor1`` : ``int`` divisor value for the clock

.. automodule:: pynq.metadata.clock_dict_view
    :members:
    :undoc-members:
    :show-inheritance: