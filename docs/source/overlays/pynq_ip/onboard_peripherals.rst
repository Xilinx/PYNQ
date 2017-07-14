Onboard GPIO Peripherals
=========================

Zynq boards usually include basic onboard peripherals including buttons, switches, and LEDs. These peripherals are usually connected to the Zynq PL and controlled using an AXI GPIO controller in an overlay. It is also possible to build an overlay which connects these peripherals to the Zynq PS GPIO controller. 

PYNQ provides an ``AxiGPIO`` class to control GPIO. It provides ``read()`` and ``write()`` methods. 

``read()`` returns the current value from the GPIO

``write(val, mask)`` writes a *value*. *mask* can be used to mask of bits of the channel. 
 
For example:

.. code-block:: console

   AxiGPIO.write(0x3, 0xf)  # Set the two lower bits to ones and the upper bits to zeros. 
   AxiGPIO.write(0x3, 0x3)  # Set the two lower bits to ones and leaves remaining bits unchanged

   
The GPIO IO are initially configured as *inout* pins, with a default width of the GPIO is 32 bits. Reading or writing the GPIO will automatically set a direction. 

There are also methods to explicitly ``setdirection()``, to set the direction of the channel (input/output), setlength()`` set the number of wires connected to the channel, and a ``wait_for_interrupt_async()``. See the Asyncio section for details on the *_async()* method. 

All GPIO can be accessed using this class, or this class can be extended to write a custom class for a GPIO device. 

For example the PYNQ-Z1 base overlay has AXI GPIO connected to the LEDs, push buttons, dip switches and multi-color LEDs. These peripherals extend the 





