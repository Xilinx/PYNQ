Hardware Libraries and Overlays
========================================

Overlay Concept
-------------------
Zynq provides a processor and FPGA fabric on the same chip. 

Overlays, or hardware libraries extend the user application from the PS (processing system) of the Zynq into the FPGA. This allows software programmers to take advantage of the FPGA fabric to accelerate the application, or to use a customized platform optimized for a particular application.

For example, for an image processing, a typical application where the FPGA can provide acceleration, the software programmer can use a hardware library to run some of the image processing functions on the FPGA fabric. 

An Overlay could also be used to generate a custom hardware platform using the available pins on the Pmod and Arduino interfaces. 

Hardware libraries can be loaded to the FPGA dynamically, as required, just like a software library.

Base Overlay
---------------
The base overlay is the default overlay that ships with the PYNQ-Z1. 

This overlay customizes the platform to connect the HDMI In and Out, the Mic In and Audio Out, and the Pmod and Arduino interfaces through the IO Processors to the PS to allow them to be used from the Pynq environment. The user buttons, switches and LEDs are also connected in the base overlay. 

.. image:: ./images/pynqz1_base_overlay.png
   :align: center

The Pmod and Arduino interfaces have special custom IO Processors  that allow a range of peripherals with different IO standards to be connected to the system and used directly by a software programmer without needing to create a new FPGA design.



Pmod Peripherals
-----------------
A Pmod interface is a 12-pin connector that can be used to connect peripherals. 

A range of Pmod peripherals are available. Typical Pmod peripherals include sensors, communication interfaces (Ethernet, serial), and input and output interfaces (buttons, switches, LEDs).

There are two Pmod connectors on PYNQ-Z1.

.. image:: ./images/pynqz1_pmod_interface.jpg
   :align: center

Supported peripherals
^^^^^^^^^^^^^^^^^^^^^^^^^^^

A number of peripherals are supported: 

 * Pmods can be plugged directly into the Pmod port. 
 * Grove peripherals can be connected to the Pmod port through a *PYNQ Grove Adapter*.
 * Other peripherals can be wired to a Pmod port.

Pmod Connector
^^^^^^^^^^^^^^^^^^^^^^^^^^^
Each Pmod connector has 12 pins (2 rows of 6 pins, where each row has 3.3V (VCC), ground (GND) and 4 data pins giving 8 data pins in total). Pmod data pins are labelled 0-7. 

.. image:: images/pmod_closeup.JPG
   :align: center

Pmods come in different configurations depending on the number of data pins required (single row, double row, e.g. 1x6 pins, 2x4 pins, 2x6 pins). Pmod peripherals with only a single row of pins can be plugged into the top row or the bottom row of the connector.

.. image:: images/pmod_pins.png
   :align: center

Pmods that use both rows (e.g. 2x4 pins, 2x6 pins), should in general be aligned to the left of the connector (to align with VCC and GND).

.. image:: images/pmod_tmp2_8pin.JPG

PYNQ Grove Adapter
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

Each Grove connector has 4 pins, one each for VCC and GND leaving 2 pins on each connector for signal wires. The PYNQ Grove Adapter has 4 connectors (G1 - G4) for Grove devices.

.. image:: ./images/pmod_grove_adapter.jpg
   :align: center

All pins operate at 3.3V. Due to different pull-up/pull-down I/O requirements for different peripherals (e.g. IIC requires pull-up, and SPI requires pull-down), Grove peripherals must be plugged into the appropriate connector.

G1 and G2 pins are connected to pins with pull-down resistors, and G3 and G4 are connected to pins with pull-up resistors, as indicated in the image. This doesn't affect Pmods.

.. image:: ./images/adapter_mapping.JPG
   :align: center

Arduino Peripherals
--------------------
An Arduino interface is a 22-pin connector that can be used to connect peripherals. 

A range of Arduino peripherals are available. Typical Arduino peripherals include Grove peripherals, and communication interfaces (Ethernet, WiFi).

There is one Arduino connector on the board.

.. image:: ./images/pynqz1_arduino_interface.jpg
   :align: center

Supported peripherals
^^^^^^^^^^^^^^^^^^^^^^^^^^^

Currently the Arduino connectors can be connected to the *PYNQ Shield*, which serves as a bridge to Grove peripherals. 

Arduino Connector
^^^^^^^^^^^^^^^^^^^^^^^^^^^
Each Arduino connector has 6 analog pins (A0 - A5), 14 multi-purpose Digital pins (D0 - D13), 2 dedicated I2C pins (SCL, SDA), and 4 dedicated SPI pins. The assignment of other pins is marked on the board.

With so many pins on the connector, there is only one way for an Arduino shield to fit in. 

.. image:: images/arduino_closeup.JPG

PYNQ Shield
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
Each Grove connector has 4 pins, one each for VCC and GND leaving 2 pins on each connector for signal wires. The PYNQ Shield has 12 connectors for digital IO (I2C, UART, G1 - G7) and 4 connectors for analog IO (A1 - A4) for Grove devices.

.. image:: ./images/arduino_shield.jpg
   :align: center

With the jumper set as in the figure, all the pins operate at 3.3V. 

IOPs
==============
For overlays to be useful, they must provide sufficient functionality, while also providing flexibility to suit a wide range of applications. Flexibility in the overlay is provided through IO Processors (IOPs). 

An IO Processor is implemented in the FPGA fabric and connects to an external port on the board. There are two types of IOP: Pmod IOP and Arduino IOP. 

Each IOP contains a MicroBlaze processor and a dedicated memory block for the MicroBlaze instruction and data memory. This memory block is dual-ported, with one port connected to the MicroBlaze, and the other connected to the ARM Cortex-A9 processor. This allows the ARM processor to access the MicroBlaze memory and dynamically write a new program to the MicroBlaze instruction area. The data area can be used for communication and data exchanges between the ARM processor and the IOP(s).

In the base overlay on the board, two IOPs control each of the two Pmod interfaces, and another IOP controls the Arduino interface. Inside the IOP are interface and functional blocks; timer, UART, IIC, SPI, GPIO, and configurable switch. IIC and SPI are standard interfaces used by many of the available Pmod, Grove and other peripherals, and GPIO can be used to connect to custom interfaces or used as simple inputs and outputs. When a Pmod, Arduino shield, or other peripheral is plugged in to a port, the configurable switch allows the signals to be routed internally to the required interface.

Pmod IOP
------------------

Two Pmod IOPs are included in the base overlay to control each of the two Pmod interfaces on the board. 

.. image:: ./images/pmod_iop.jpg
   :align: center
   
As indicated in the diagram, the Pmod IOP has a MicroBlaze, a configurable switch, and the following peripherals: 

* I2C
* SPI
* GPIO blocks
* Timer


Pmod IO Switch
^^^^^^^^^^^^^^^^^^^^^^^^^^^

The switch can be configured by writing to its configuration registers. 

Each individual pins can be configured by writing a 4-bit value to the corresponding place in the IO switch configuration registers. This can be done from the MicroBlaze code. 

The following function, part of the Pmod IO switch driver, can be used to configure the switch. 

.. code-block:: c

   void config_pmod_switch();



Switch mappings used for IO switch configuration:


For example: 

.. code-block:: c

   config_pmod_switch(SS,MOSI,GPIO_2,SPICLK,GPIO_4,GPIO_5,GPIO_6,GPIO_7);

From Python all the constants and addresses for the IOP can be found in:

    ``<GitHub Repository>/python/pynq/iop/iop_const.py``

``pmod.h`` and ``pmod.c`` are part of the Pmod IO switch driver, and contain an API, addresses, and constant definitions that can be used to write code for an IOP.

   ``<GitHub Repository>/Pynq-Z1/vivado/ip/pmod_io_switch_1.0/drivers/pmod_io_switch_v1_0/src/``

This code is automatically compiled into the Board Support Package (BSP). Any application linking to the BSP can use this library by including the header file:

.. code-block:: c

   #include "pmod_io_switch.h"



Arduino IOP
---------------------------

The board has an Arduino interface. An Arduino IOP is available to control this interface. The Arduino IOP is similar to the PMOD IOP with multiple interface and functional units. 

.. image:: ./images/arduino_iop.jpg
   :align: center
   
As indicated in the diagram, the Arduino IOP has a MicroBlaze, a configurable switch, and the following peripherals: 

* 2x I2C
* 2x SPI
* 1x UART
* 3x GPIO blocks
* 1x XADC
* 1 Interrupt controller (32 channels)
   
The interrupt controller can be connected to all the analog and digital pins, and each of the 6 timers, the I2Cs, the SPIs, the XADC, and UART. This means an external pin on the shield interface can trigger the interrupt controller, and the internal peripherals can also trigger an interrupt.  

Arduino shields have fixed possible configurations.  According to the Arduino specification, the analog pins can also be used as digital I/O. 

==========   =========================
Peripheral   Pins
==========   =========================
UART         D0, D1
I2C          A4, A5
SPI*         D10 - D13
PWM          D3, D5, D6, D9, D10, D11
Timer        D3 - D6 and D8 - D11
==========   =========================

\* There are also dedicated pins for a separate SPI. 

For example, a shield with a UART and 5 Digital IO can connect the UART to pins D0, D1, and the Digital IO can be connected to pins D2 - D6.

There is one limitation: The analog feature of the Arduino is not supported on Pynq-Z1.


Arduino IO Switch
^^^^^^^^^^^^^^^^^^^^^^^^^^^

The switch can be configured by writing to its configuration registers. 

The dedicated SPI pins are always connected to one of the SPI controllers. 

The analog and digital pins can be configured by writing a 4-bit value to the corresponding place in the IO switch configuration registers. This can be done from the MicroBlaze code. 

The following function, part of the Arduino IO switch driver, can be used to configure the switch. 

.. code-block:: c

   void config_arduino_switch();



Switch mappings used for IO switch configuration:

========  =======  =======   =========  ======  =======  ==================  ========  =======  ==============

Pin Name  A/D IO   A_INT     Interrupt  UART    PWM      Timer               SPI       IIC      Input Capture

========  =======  =======   =========  ======  =======  ==================  ========  =======  ==============
A0        A_GPIO   A_INT                                   
A1        A_GPIO   A_INT                                   
A2        A_GPIO   A_INT                                   
A3        A_GPIO   A_INT                                   
A4        A_GPIO   A_INT                                                               IIC
A5        A_GPIO   A_INT                                                               IIC
D0        D_GPIO             D_INT      D_UART
D1        D_GPIO             D_INT      D_UART
D2        D_GPIO             D_INT                              
D3        D_GPIO             D_INT              D_PWM0   D_TIMER (Timer0)                       IC (Timer0)
D4        D_GPIO             D_INT                       D_TIMER (Timer0_6)               
D5        D_GPIO             D_INT              D_PWM1   D_TIMER (Timer1)                       IC (Timer1)
D6        D_GPIO             D_INT              D_PWM2   D_TIMER (Timer2)                       IC (Timer2)
D7        D_GPIO             D_INT                              
D8        D_GPIO             D_INT                       D_TIMER (Timer1_7)                     Input Capture
D9        D_GPIO             D_INT              D_PWM3   D_TIMER (Timer3)                       IC (Timer3)
D10       D_GPIO             D_INT              D_PWM4   D_TIMER (Timer4)    D_SS               IC (Timer4)
D11       D_GPIO             D_INT              D_PWM5   D_TIMER (Timer5)    D_MOSI             IC (Timer5)
D12       D_GPIO             D_INT                                           D_MISO          
D13       D_GPIO             D_INT                                           D_SPICLK          

========  =======  =======   =========  ======  =======  ==================  ========  =======  ==============

For example, to connect the UART to D0 and D1, write D_UART to the configuration register for D0 and D1. 

.. code-block:: c

	config_arduino_switch(A_GPIO, A_GPIO, A_GPIO, A_GPIO, A_GPIO, A_GPIO,
			      D_GPIO, D_GPIO, D_GPIO, D_GPIO, D_GPIO,
			      D_GPIO, D_GPIO, D_GPIO, D_GPIO,
			      D_GPIO, D_GPIO, D_GPIO, D_GPIO);

From Python all the constants and addresses for the IOP can be found in:

    ``<Pynq GitHub Repository>/python/pynq/iop/iop_const.py``

``arduino.h`` and ``arduino.c`` are part of the Arduino IO switch driver, and contain an API, addresses, and constant definitions that can be used to write code for an IOP.

   ``<GitHub Repository>/Pynq-Z1/vivado/ip/arduino_io_switch_1.0/drivers/arduino_io_switch_v1_0/src/``

This code this automatically compiled into the Board Support Package (BSP). Any application linking to the BSP can use this library by including the header file:

.. code-block:: c

   #include "arduino_io_switch.h"


   
   
