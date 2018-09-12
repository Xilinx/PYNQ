.. _pynq-libraries-axigpio:

AxiGPIO
=======

The AxiGPIO class provides methods to read, write, and receive 
interrupts from external general purpose peripherals such as LEDs, 
buttons, switches connected to the PL using AXI GPIO controller IP.


Block Diagram
-------------

The AxiGPIO module controls instances of the AXI GPIO controller in
the PL. Each AXI GPIO can have up to two channels each with up to 32 pins. 

.. image:: ../images/gpio.png
   :align: center  

The ``read()`` and ``write()`` methods are used to read and write data
on a channel (all of the GPIO).

``setdirection()`` and ``setlength()`` can be used to configure the IP.
The direction can be 'in', 'out', and 'inout'. 

By default the direction
is 'inout'. Specifying 'in' or 'out' will only allow read and writes to
the IP respectively, and trying to *read* an 'out' or *write* an 'in'
will cause an error. 

The length can be set to only write a smaller range of the GPIO.

The GPIO can also be treated like an array. This allows specific bits to
be set, and avoids the need to use a bit mask. 

The interrupt signal, *ip2intc_irpt* from the AXI GPIO can be connected 
directly
to an AXI interrupt controller to cause interrupts in the PS. More 
information
about AsyncIO and Interrupts can be found in the :ref:`pynq-and-asyncio`
section.

.. image:: ../images/gpio_interrupt.png
   :align: center

The LED, Switch, Button and RGBLED classes extend the AxiGPIO controller 
and are customized for the corresponding peripherals. These classes 
expect an AXI GPIO instance called ``[led|switch|button|rgbleds]_gpio`` 
to exist in the overlay used with this class. 

Examples
--------

This example is for illustration, to show how to use the AxiGPIO class.
In practice, the LED, Button, Switches, and RGBLED classes may be available 
to extend the AxiGPIO class should be used for these peripherals in an overlay. 

After an overlay has been loaded, an AxiGPIO instance can be instantiated 
by passing the name of the AXI GPIO controller to the class. 

.. code-block:: Python

   from pynq import Overlay
   from pynq.lib import AxiGPIO
   ol = Overlay("base.bit")

   led_ip = ol.ip_dict['gpio_leds']
   switches_ip = ol.ip_dict['gpio_switches']
   leds = AxiGPIO(led_ip).channel1
   switches = AxiGPIO(switches_ip).channel1

Simple read and writes:
   
.. code-block:: Python

   mask = 0xffffffff
   leds.write(0xf, mask)
   switches.read()

Using AXI GPIO as an array:

.. code-block:: Python

   switches.setdirection("in")
   switches.setlength(3)
   switches.read() 

More information about the AxiGPIO module and the API for reading, writing
and waiting for interrupts can be found in the :ref:`pynq-lib-axigpio` 
sections.

For more examples see the "Buttons and LEDs demonstration" notebook for the
PYNQ-Z1/PYNQ-Z2 board at:

.. code-block:: console

   <Jupyter Home>/base/board/board_btns_leds.ipynb
   
The same notebook may be found in the corresponding folder in the GitHub repository. 
