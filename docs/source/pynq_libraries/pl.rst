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

Device Server Types
-------------------

The *server* associated to a *Device* can be of two types:

1. *Global* server: this server is globally defined and shared across all 
   Python processes. 
2. *Local* server: in this case, the server is defined locally with respect to
   a specific Python process and exists only within that context.

There are benefits and downsides for both approaches, and based on the 
requirements, scenarios in which one or the other is more appropriate. A global
server will arbitrate the usage of a device across different processes, but its
life-cycle is required to be managed explicitly. Conversely, a local process 
does not prevent contention across Python processes, but will be automatically 
spawned when a device is initialized and destroyed when the associated Python
process exits.

When instantiating a *Device* object, three different strategies can be selected
by setting the ``server_type`` flag appropriately :

1. ``server_type="global"`` will tell the Device object to use a globally defined 
   server. This server need to be already started separately.
2. ``server_type="local"`` will instead spawn a local server, that will be 
   closed as soon as the Python process terminates.
3. ``server_type="fallback"`` will attempt to use a global server, and in case
   it fails, will fallback to a local server instance. This is the default
   behavior in case ``server_type`` is not defined.

For Zynq and ZynqUltrascale+ devices, the selected server type is *global*. In
fact, the device server is started as a system service at boot time on PYNQ SD 
card images.

For XRT devices, the server type strategy is *fallback*. In case required, a 
system administrator can still setup a global device server to arbitrate usage.
However, if a global server is not found, it will automatically default to using
a local server instead.

More information about devices and bitstreams can be found in the
:ref:`pynq-bitstream` and :ref:`pynq-pl_server` sections.
