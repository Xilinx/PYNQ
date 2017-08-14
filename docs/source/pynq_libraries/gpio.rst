GPIO: LEDs, Buttons and Switches
================================

The AXI GPIO controller can be used in an overlay to connect to external LEDs, 
buttons, switches, or to connect directly to external IO. 

PYNQ provides an ``AxiGPIO`` class to control GPIO that includes ``read()`` and 
``write()`` methods. ``read()`` returns the current value from the GPIO, and 
``write(val)`` writes a *value*. 

There are also methods to explicitly ``setdirection()``, to set the direction of
the channel (input/output), ``setlength()``, to set the number of wires 
connected to the channel, and a ``wait_for_interrupt_async()`` to support 
interrupts on GPIO using Asyncio. See the Asyncio section for details on the 
*_async()* method.

The ``AxiGPIO`` class is automatically assigned to AXI GPIO instances discovered
in an overlay. This allows an AXI GPIO object to be used immediately without 
needing to import the AxiGPIO class, or set up each object before it can be 
used.

The ``AxiGPIO`` class should not be used direcly in Python, but can be used as a
ready made API when creating custom overlays with AXI GPIO controllers.

See help(AxiGPIO) for more information. 

Examples
--------

In the base overlay for the Pynq-Z1, three *AxiGPIO* instances are available:

.. code-block:: console

   btns_gpio            : pynq.lib.axigpio.AxiGPIO
   rgbleds_gpio         : pynq.lib.axigpio.AxiGPIO
   swsleds_gpio         : pynq.lib.axigpio.AxiGPIO

After the overlay is loaded, the ``AxiGPIO`` class is already available and can 
be used directly from each *AxiGPIO* object. 

.. code-block:: Python

   from pynq import Overlay
   base = Overlay("base.bit")
   
   base.btns_gpio.read()
   
   base.rgbleds_gpio.write(0x3)  
   
