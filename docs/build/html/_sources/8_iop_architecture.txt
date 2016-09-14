IO Processor Architecture
============================
For overlays to be useful, they must provide sufficient functionality, while also providing flexibility to suit a wide range of applications. Flexibility in the base overlay is demonstrated through the use of IO Processors (IOPs). 

An IO Processor is implemented in the programmable logic and connects to and controls an external port on the board. There are two types of IOP: Pmod IOP and Arduino IOP. 

Each IOP contains a MicroBlaze processor, a configurable switch, peripherals, and memory for the MicroBlaze instruction and data memory. The memory is dual-ported, with one port connected to the MicroBlaze, and the other connected to the ARM Cortex-A9 processor. This allows the ARM processor to access the MicroBlaze memory and dynamically write a new program to the MicroBlaze instruction area. The data area of the memory can be used for communication and data exchanges between the ARM processor and the IOP(s). e.g. a simple mailbox. 

In the base overlay, two IOPs control each of the two Pmod interfaces, and another IOP controls the Arduino interface. Inside the IOP are dedicated peripherals; timers, UART, IIC, SPI, GPIO, and a configurable switch. (Not all peripherals are available in the Pmod IOP.) IIC and SPI are standard interfaces used by many of the available Pmod, Grove and other peripherals. GPIO can be used to connect to custom interfaces or used as simple inputs and outputs. When a Pmod, Arduino shield, or other peripheral is plugged in to a port, the configurable switch allows the signals to be routed dynamically to the required dedicated interface. This is how the IOP provides flexibility and allows peripherals with different pin connections and protocols to be used on the same port. 


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


Pmod IOP configurable switch
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

The MicroBlaze, inside the IOP, can configure the switch by writing to the configuration registers of the switch. This would be done by the MicroBlaze application.

For the Pmod IOP switch, each individual pin can be configured by writing a 4-bit value to the corresponding place in the IO switch configuration registers. 

The following function, part of the Pmod IO switch driver, can be used to configure the switch. 

.. code-block:: c

   void config_pmod_switch();



Switch mappings used for IO switch configuration:


For example: 

.. code-block:: c

   config_pmod_switch(SS,MOSI,GPIO_2,SPICLK,GPIO_4,GPIO_5,GPIO_6,GPIO_7);
   
This would connect a SPI interface:
* Pin 1: SS
* Pin 2: MOSI
* Pin 4: SPICLK

and the remaining pins to their corresponding GPIO (which could be left unused in the MicroBlaze application). 

From Python all the constants and addresses for the IOP can be found in:

    ``<GitHub Repository>/python/pynq/iop/iop_const.py``

``pmod.h`` and ``pmod.c`` are part of the Pmod IO switch driver, and contain an API, addresses, and constant definitions that can be used to write code for an IOP.

   ``<GitHub Repository>/Pynq-Z1/vivado/ip/pmod_io_switch_1.0/drivers/pmod_io_switch_v1_0/src/``

This code is automatically compiled into the Board Support Package (BSP). Any application linking to the BSP can use this library by including the header file:

.. code-block:: c

   #include "pmod_io_switch.h"



Arduino IOP
---------------------------

Similar to the Pmod IOP, an Arduino IOP is available to control the Arduino interface. The Arduino IOP is similar to the PMOD IOP, but has some additional internal peripherals (extra timers, an extra I2c, and SPI, a UART, and an XADC). The configurable switch is also different to the Pmod switch. 

.. image:: ./images/arduino_iop.jpg
   :align: center
   
As indicated in the diagram, the Arduino IOP has a MicroBlaze, a configurable switch, and the following peripherals: 

* 2x I2C
* 2x SPI
* 1x UART
* 3x GPIO blocks
* 1x XADC
* 1 Interrupt controller (32 channels)
   
The interrupt controller can be connected to all the analog and digital pins, and each of the 6 timers, the I2Cs, the SPIs, the XADC, and UART. This means an external pin on the shield interface can trigger an interrupt. An internal peripheral can also trigger an interrupt.  

Arduino shields have fixed possible configurations.  According to the Arduino specification, the analog pins can be used as analgo, or digital I/O. 

Other peripherals can be connected as indicated in the table. 

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

While there is support for analog inputs via the internal XADC, this only allows inputs of 0-1V. The Arduino supports 0-5V analog inputs which are not supported on the PYNQ-Z1.


Arduino IOP configurable Switch
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

The switch can be configured by writing to its configuration registers. 

The dedicated SPI pins are always connected to one of the SPI controllers. 

The analog and digital pins can be configured by writing a 4-bit value to the corresponding place in the IO switch configuration registers, similar to the Pmod switch.  

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
			      D_UART, D_UART, D_GPIO, D_GPIO, D_GPIO,
			      D_GPIO, D_GPIO, D_GPIO, D_GPIO,
			      D_GPIO, D_GPIO, D_GPIO, D_GPIO);

From Python all the constants and addresses for the IOP can be found in:

    ``<Pynq GitHub Repository>/python/pynq/iop/iop_const.py``

``arduino.h`` and ``arduino.c`` are part of the Arduino IO switch driver, and contain an API, addresses, and constant definitions that can be used to write code for an IOP.

   ``<GitHub Repository>/Pynq-Z1/vivado/ip/arduino_io_switch_1.0/drivers/arduino_io_switch_v1_0/src/``

This code this automatically compiled into the Board Support Package (BSP). Any application linking to the BSP can use this library by including the header file:

.. code-block:: c

   #include "arduino_io_switch.h"


   
