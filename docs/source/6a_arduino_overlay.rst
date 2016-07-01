Arduino IO Processor
========================================

Arduino Interface
-------------------

The Pynq-z1 board has an Arduino interface. 

.. image:: ./images/arduino_interface.jpg
   :align: center
   
An Arduino IOP is available to control this interface.

The Arduino interface has 6 analog pins (A0-A5), and 14 Digital pins and (D0-D13), and 4 dedicated SPI pins.

Arduino shields have fixed possible configurations.  According to the Arduino specification, the analog pins can also be used as digital I/O. 

==========   =========================
Peripheral   Pins
==========   =========================
UART         D0, D1
I2C          A4, A5
SPI*          D10-D13.
PWM          D3, D5, D6, D9, D10, D11
Timer        D3-D6 and D8-D11
==========   =========================

\* There are also dedicated pins for a seprate SPI. 

For example, a shield with a UART and 5 Digital IO can connect the UART to pins D0, D1, and the Digital IO can be connected to pins D2 - D6.

Limitations:
The analog compare feature of the Arduino is not supported on the Pynq-z1 board.

Arduino IOP 
--------------

The Arduino IOP is similar to the PMOD IOP. 


.. image:: ./images/arduino_iop.jpg
   :align: center
   
As indicated in the diagram, the Arduino IOP ha a MicroBlaze, a configurable switch, and the following peripherals: 

* 2x I2x
* 2x SPI
* 1x UART
* 3x GPIO blocks
* 1x XADC
* 1 Interrupt Controller (32 channels)
   
The interrupt controller can be connected to all the Analog and Digital pins, and each of the 6 Timers, the I2Cs, the SPIs, the XADC, and UART. 

This means an external pin on the shield interface can trigger the interrupt controller, and the internal peripherals can also trigger an interrupt.  


Arduino IO Switch
^^^^^^^^^^^^^^^^^^^^^^^^^^^

The switch can be configured by writing to its configuration registers. 

The dedicated SPI pins are always connected to one of the SPI controllers. 

The analog and digital pins can be configured by writing a 4-bit value to the corresponding place in the IOP Switch configuration registers. This can be done from the MicroBlaze code. 

The following function, part of the provided arduino_io_switch_v1_0 driver ``arduino.h`` can be used to configure the switch. 

.. code-block:: c

   void configureArduinoSwitch();



Switch mappings used for IOP Switch configuration:

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

   configureSwitch(D_UART, D_UART);

From Python all the constants and addresses for the IOP can be found in:

    ``<Pynq GitHub Repository>/python/pynq/iop/pmod_const.py``

    
arduino_io_switch driver
--------------------------
``arduino_io_switch.h`` and ``arduino_io_switch.c`` are part of the *arduino_io_switch* driver, and contain an API, addresses, and constant definitions that can be used to write code for an IOP.

   ``<Pynq GitHub Repository>/Pynq/zybo/vivado/ip/arduino_io_switch_1.0/drivers/arduino_io_switch_1.0/src/``

This code this automatically compiled into the Board Support Package. Any application linking to the BSP can use the Pmod library by including the header file:

.. code-block:: c

   #include "arduino_io_switch.h"

