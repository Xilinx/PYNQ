.. _grove:

Grove
=====

The Grove peripherals can be accessed on Pmod pins using
the *PYNQ Grove Adapter* and on Arduino pins using the *PYNQ Shield*.

Block Diagram
-------------

There are two connectors available to connect Grove peripherals to the PYNQ-Z1
Board.

Pmod
^^^^

The first option for connecting Grove peripherals uses the Pmod PYNQ 
MicroBlaze.

.. image:: ../images/pmod.png
   :align: center
	
Grove devices can be connected to PYNQ-Z1 through the Pmod ports using the 
*PYNQ Grove Adapter*.

.. image:: ../images/pmod_grove_adapter.jpg
   :align: center

On the *PYNQ Grove Adapter* G1 and G2 map to Pmod pins [0,4] and [1,5], which
are connected to pins with pull-down resistors. Ports G1 and G2 support the SPI
protocol, GPIO, and timer Grove peripherals, but not IIC peripherals. Ports G3
and G4 map to pins [2,6], [3,7], which are connected to pins with pull-up
resistors and support the IIC protocol and GPIO peripherals.

.. image:: ../images/adapter_mapping.JPG
   :align: center

==========   =========================
Peripheral   Grove Port
==========   =========================
I2C          G3, G4
SPI          G1, G2
==========   =========================

Arduino
^^^^^^^

The second option for connecting Grove peripherals uses the Arduino PYNQ 
MicroBlaze.

.. image:: ../images/arduino_iop.jpg
   :align: center
	
Grove devices can be connected to PYNQ-Z1 through the Arduino ports using the 
*PYNQ Shield*.

.. image:: ../images/arduino_shield.jpg
   :align: center

On the *PYNQ Shield* there are 4 IIC Grove connectors (labeled I2C), 8
vertical Grove Connectors (labeled G1-G7 and UART), and four horizontal Grove
Connectors (labeled A1-A4). The SCL and SDA pins are connected to the SCL and
SDA pins on the Arduino header.

The following table maps Grove Ports to communcation protocols.

==========   =========================
Peripheral   Grove Port
==========   =========================
UART         UART
I2C          A4, I2C (x4)
SPI          G7, G6
GPIO         UART, G1 - G7
==========   =========================

A list of drivers provided for Grove peripherals can be found in 
:ref:`pynq-lib-pmod` for the *PYNQ Grove Adapter* and in 
:ref:`pynq-lib-arduino` for the *PYNQ Shield*.

Examples
--------

In :ref:`base-overlay`, two Pmod instances are available: PMODA and
PMODB. After the overlay is loaded, the Grove peripherals can be accessed 
as follows:

.. code-block:: Python

   from pynq.overlays.base import BaseOverlay
   from pynq.lib.pmod import Grove_Buzzer
   from pynq.lib.pmod import PMOD_GROVE_G1

   base = BaseOverlay("base.bit")

   grove_buzzer = Grove_Buzzer(base.PMODB,PMOD_GROVE_G1)
   grove_buzzer.play_melody()

More information about the Grove drivers in the Pmod subpackage, the supported
peripherals, and APIs can be found in :ref:`pynq-lib-pmod`.

For more examples using the *PYNQ Grove Adapter*, see the notebooks in the 
following directory on the PYNQ-Z1 board:

.. code-block:: console

   <Jupyter Dashboard>/base/pmod/

In :ref:`base-overlay`, one Arduino PYNQ MicroBlaze instance is available. 
After the overlay is loaded, the Grove peripherals can be accessed as follows:

.. code-block:: Python

   from pynq.overlays.base import BaseOverlay
   from pynq.lib.arduino import Grove_LEDbar
   from pynq.lib.arduino import ARDUINO_GROVE_G4

   base = BaseOverlay("base.bit")
		
   ledbar = Grove_LEDbar(base.ARDUINO,ARDUINO_GROVE_G4)
   ledbar.reset()

More information about the Grove drivers in the Arduino subpackage, the 
supported peripherals, and APIs can be found in :ref:`pynq-lib-arduino`.

For more examples using the *PYNQ Shield*, see the notebooks in the following 
directory on the PYNQ-Z1 board:

.. code-block:: console

   <Jupyter Dashboard>/base/arduino/
   
