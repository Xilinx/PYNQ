GPIO: LEDs, Buttons and Switches
================================

The AXI GPIO controller can be used in an overlay to connect to external LEDs, 
buttons, switches, or to connect directly to external IO. 

The AXI GPIO has two channels that can be connected to two sets of up to 32-bit 
pins. 

.. image:: ../images/gpio.png
   :align: center  
   
The interrupt signal, *ip2intc_irpt* from the AXI GPIO can be connected directly
to an AXI interrupt controller, or connected through a concatenation block to 
the controller if there is more than one interrupt in the system. 

.. image:: ../images/gpio_interrupt.png
   :align: center  

PYNQ provides an ``AxiGPIO`` class to control GPIO that includes ``read()`` and 
``write()`` methods. 

There are also methods to explicitly ``setdirection()``, to set the direction of
the channel (input/output), ``setlength()``, to set the number of wires 
connected to the channel, and a ``wait_for_interrupt_async()`` to support 
interrupts on GPIO using Asyncio. See the Asyncio section for details on the 
*_async()* method.

A Python file is provided with an Overlay which allows drivers, including the 
``AxiGPIO`` class, to be automatically assigned to AXI GPIO instances in the 
design. This allows an AXI GPIO object to be used immediately without 
needing to import the AxiGPIO class, or set up each object before it can be 
used.

The mappings for the base overlay can be found in the BaseOverlay Python file:

.. code-block:: console

   boards\Pynq-Z1\base\base.py

The ``AxiGPIO`` class should not be used direcly in Python, but can be used as a
ready made API when creating custom overlays with AXI GPIO controllers.

See the ``pynq.lib.axigpio`` module in the pynq Package section of this 
documentation or run help(AxiGPIO) on the board for more information. 

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
   
