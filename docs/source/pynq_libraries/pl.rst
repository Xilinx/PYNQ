.. _pynq-libraries-pl:

Device and Bitstream classes
============================

The *Device* is a class representing some programmable logic that is mainly
used by the Overlay class. Each instance of the Device class has a
corresponding *server* which manages the loaded overlay. The server can stop
multiple overlays from different applications from overwriting the currently
loaded overlay. 

The overlay Tcl file is parsed by the Device class to generate the IP, clock,
interrupts, and gpio dictionaries (lists of information about IP, clocks and
signals in the overlay).

The *Bitstream* class can be found in the bitstream.py source file, and can be used
instead of the overlay class to download a bitstream file to the PL without
requiring an overlay Tcl file. This can be used for testing, but these
attributes can also be accessed through the Overlay class (which inherits from
this class). Using the Overlay class is the recommended way to access these
attributes.

Examples
--------

Device
^^^^^^

.. code-block:: Python

   from pynq import Device

   dev = Device.active_device # Retrieve the currently used device

   dev.timestamp # Get the timestamp when the current overlay was loaded

   dev.ip_dict # List IP in the overlay

   dev.gpio_dict # List GPIO in the overlay

   dev.interrupt_controllers # List interrupt controllers in the overlay

   dev.interrupt_pins # List interrupt pins in the overlay

   dev.hierarchy_dict # List the hierarchies in the overlay


Bitstream
^^^^^^^^^

.. code-block:: Python

   from pynq import Bitstream

   bit = Bitstream("base.bit") # No overlay Tcl file required

   bit.download()

   bit.bitfile_name
   
'/opt/python3.6/lib/python3.6/site-packages/pynq/overlays/base/base.bit'


More information about devices and bitstreams can be found in the
:ref:`pynq-bitstream` and :ref:`pynq-pl_server` sections.
