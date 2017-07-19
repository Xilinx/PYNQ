Grove
=====

Pmod ports are design for use with Pmods. The 8 data pins of a Pmod port can be
used to connect to a breadboard, or directly to other peripherals.

Grove peripherals which use a four wire interface can also be connected to the
Pmod port through a *PYNQ Grove Adapter*.

.. image:: ../images/pmod_grove_adapter.jpg
   :align: center

On the grove adapter G1 and G2 map to Pmod pins [0,4] and [1,5], which are
connected to pins with pull-down resistors (supports SPI interface, and most
peripherals). G3 and G4 map to pins [2,6], [3,7], which are connected to pins
with pull-up resistors (IIC), as indicated in the image.

.. image:: ../images/adapter_mapping.JPG
   :align: center
	   
Block Diagram
-------------


Examples
--------
