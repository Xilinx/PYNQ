*******************************
IO Processor Architecture
*******************************

.. contents:: Table of Contents
   :depth: 2
   
Introduction
==================
   
For overlays to be useful, they must provide sufficient functionality, while also providing flexibility to suit a wide range of applications. Flexibility in the base overlay is demonstrated through the use of IO Processors (IOPs). 

An IO Processor is implemented in the programmable logic and connects to and controls an external port on the board. There are two types of IOP: Pmod IOP and Arduino IOP. 

Each IOP contains a MicroBlaze processor, a configurable switch, peripherals, and local memory for the MicroBlaze instruction and data memory. The local memory is dual-ported (implemented in Xilin BRAMs), with one port connected to the MicroBlaze, and the other connected to the ARM® Cortex®-A9 processor. This allows the ARM processor to access the MicroBlaze memory and dynamically write a new program to the MicroBlaze instruction area. 

The data area of the memory can be used for communication and data exchanges between the ARM processor and the IOP(s). E.g. a simple mailbox. 

The IOP also has an interface to DDR memory. This allows the DDR to be used as data memory in addition to the local memory. This allows larger applications to be written (where data memory is the limitation) and allows a larger mailbox size for data transfer between the PS (Python) and the IOP. The DDR interface also allows different IOPs to communicate with each other directly without intervention from the PS (Python). 

In the base overlay, two IOPs control each of the two Pmod interfaces, and another IOP controls the Arduino interface. Inside the IOP are dedicated peripherals; timers, UART, IIC, SPI, GPIO, and a configurable switch. (Not all peripherals are available in the Pmod IOP.) 

IIC and SPI are standard interfaces used by many of the available Pmod, Grove and other peripherals. GPIO can be used to connect to custom interfaces or used as simple inputs and outputs. 

When a Pmod, Arduino shield, or other peripheral is plugged in to a port, the configurable switch allows the signals to be routed dynamically to the required dedicated interface. This is how the IOP provides flexibility and allows peripherals with different pin connections and protocols to be used on the same port. 


Pmod IOP
==================

Two Pmod IOPs are included in the base overlay to control each of the two Pmod interfaces on the board. 

.. image:: ./images/pmod_iop.jpg
   :align: center
   
As indicated in the diagram, the Pmod IOP has a MicroBlaze, a configurable switch, and the following peripherals: 

* I2C
* SPI
* GPIO blocks
* Timer
* Interrupt controller


Pmod IOP peripherals 
------------------------

I2C
^^^^^^^^^^^^^^^^^^^

The I2C configuration is:
   * Frequency: 100KHz
   * Address mode: 7 bit
   
SPI
^^^^^^^^^^^^^^^^^^^

The SPI configuration is:
   * Standard mode
   * Transaction width: 8
   * Frequency: 6.25 MHz (100MHz/16)
   * Master mode
   * Fifo depth: 16
   
GPIO blocks
^^^^^^^^^^^^^^^^^^^

The GPIO block supports 8 input or output pins

Timer
^^^^^^^^^^^^^^^^^^^

The timer is 32 bits width, and has a *Generate* output, and a PWM output. The *Generate* output can ouput one-time or periodic signal based on a loaded value. For example, on loading a value, the timer can count up or down. Once the counter expires (on a carry) a signal can be generated. The timer can stop, or automatically reload. 

Interrupt controller
^^^^^^^^^^^^^^^^^^^^^^^^^^

The I2c, SPI, GPIO and Timer are connected to the interrupt controller. This is the standard MicroBlaze interrupt controller, and interrupts can be managed by the IOP in a similar way to any other MicroBlaze application. 

Pmod IOP configurable switch
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

The MicroBlaze, inside the IOP, can configure the switch by writing to the configuration registers of the switch. This would be done by the MicroBlaze application.

For the Pmod IOP switch, each individual pin can be configured by writing a 4-bit value to the corresponding place in the IO switch configuration registers. This configuration is done from the IOP (C/C++) application. An IOP application can either set the switch to a fixed configuration, or allow a configuration to be sent from Python which it will then use to configure the switch. 

The following function, part of the Pmod IO switch driver, can be used to configure the switch in an IOP application. 

.. code-block:: c

   void config_pmod_switch();


You can check the IOP constants and addresses in the Python code here: 

:: 
   
   <GitHub Repository>/python/pynq/iop/iop_const.py


Arduino IOP
===========================

Similar to the Pmod IOP, an Arduino IOP is available to control the Arduino interface. The Arduino IOP is similar to the PMOD IOP, but has some additional internal peripherals (extra timers, an extra I2c, and SPI, a UART, and an XADC). The configurable switch is also different to the Pmod switch. 

.. image:: ./images/arduino_iop.jpg
   :align: center
   
As indicated in the diagram, the Arduino IOP has a MicroBlaze, a configurable switch, and the following peripherals: 

* 2x I2C
* 2x SPI
* 1x UART
* 3x GPIO blocks
* 1x XADC
* 1x UART
* 1x Interrupt controller (32 channels)

Arduino IOP peripherals 
------------------------

I2C
^^^^^^^^^^^^^^^^^^^

There are two I2C controllers available. They both have the same settings:
   * Frequency: 100KHz
   * Address mode: 7 bit
   
SPI
^^^^^^^^^^^^^^^^^^^

There are two SPI controllers available. They both have the same settings:
   * Standard mode
   * Transaction width: 8
   * Frequency: 6.25 MHz (100MHz/16)
   * Master mode
   * Fifo depth: 16
   
GPIO blocks
^^^^^^^^^^^^^^^^^^^

There are three GPIO block available. They support xxx input or output pins

Timers
^^^^^^^^^^^^^^^^^^^

There are six timers available. All are 32 bits wide, with a *Generate* output, and a PWM output. The *Generate* output can ouput one-time or periodic signal based on a loaded value. For example, on loading a value, the timer can count up or down. Once the counter expires (on a carry) a signal can be generated. The timer can stop, or automatically reload. 

UART
^^^^^^^^^^^^^^^^^^^^^^^

There is a UART controller, with a fixed configuration of 9600 baud. The UART can be connected to the Arduino UART pins. The UART configuration is hard coded, and is part of the overlay. It is not possible to modify the UART configuration in software. 

Interrupt controller
^^^^^^^^^^^^^^^^^^^^^^^
   
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
---------------------------------

The switch can be configured by writing to its configuration registers. 

The dedicated SPI pins are always connected to one of the SPI controllers. 

The analog and digital pins can be configured by writing a 4-bit value to the corresponding place in the IO switch configuration registers, similar to the Pmod switch.  

The following function, part of the Arduino IO switch driver, can be used to configure the switch. 

.. code-block:: c

   void config_arduino_switch();



Switch mappings used for IO switch configuration:

===  ======  =====   =========  ======  ======  ================  ========  ====  =============
                                                                                               
Pin  A/D IO  A_INT   Interrupt  UART    PWM     Timer             SPI       IIC   Input-Capture  
                                                                                         
===  ======  =====   =========  ======  ======  ================  ========  ====  =============
A0   A_GPIO  A_INT                                                                             
A1   A_GPIO  A_INT                                                                             
A2   A_GPIO  A_INT                                                                             
A3   A_GPIO  A_INT                                                                             
A4   A_GPIO  A_INT                                                          IIC                
A5   A_GPIO  A_INT                                                          IIC                
D0   D_GPIO          D_INT      D_UART                                                         
D1   D_GPIO          D_INT      D_UART                                                         
D2   D_GPIO          D_INT                                                                     
D3   D_GPIO          D_INT              D_PWM0  D_TIMER Timer0                    IC Timer0  
D4   D_GPIO          D_INT                      D_TIMER Timer0_6                             
D5   D_GPIO          D_INT              D_PWM1  D_TIMER Timer1                    IC Timer1  
D6   D_GPIO          D_INT              D_PWM2  D_TIMER Timer2                    IC Timer2  
D7   D_GPIO          D_INT                                                                     
D8   D_GPIO          D_INT                      D_TIMER Timer1_7                  Input Capture
D9   D_GPIO          D_INT              D_PWM3  D_TIMER Timer3                    IC Timer3  
D10  D_GPIO          D_INT              D_PWM4  D_TIMER Timer4    D_SS            IC Timer4  
D11  D_GPIO          D_INT              D_PWM5  D_TIMER Timer5    D_MOSI          IC Timer5  
D12  D_GPIO          D_INT                                        D_MISO                       
D13  D_GPIO          D_INT                                        D_SPICLK                     
                                                                                               
===  ======  =====   =========  ======  ======  ================  ========  ====  =============

For example, to connect the UART to D0 and D1, write D_UART to the configuration register for D0 and D1. 

.. code-block:: c

	config_arduino_switch(A_GPIO, A_GPIO, A_GPIO, A_GPIO, A_GPIO, A_GPIO,
			      D_UART, D_UART, D_GPIO, D_GPIO, D_GPIO,
			      D_GPIO, D_GPIO, D_GPIO, D_GPIO,
			      D_GPIO, D_GPIO, D_GPIO, D_GPIO);

From Python all the constants and addresses for the IOP can be found in:

:: 
	   
   <Pynq GitHub Repository>/python/pynq/iop/iop_const.py

``arduino.h`` and ``arduino.c`` are part of the Arduino IO switch driver, and contain an API, addresses, and constant definitions that can be used to write code for an IOP.

:: 
   
   <GitHub Repository>/Pynq-Z1/vivado/ip/arduino_io_switch_1.0/  \
   drivers/arduino_io_switch_v1_0/src/

This code this automatically compiled into the Board Support Package (BSP). Any application linking to the BSP can use this library by including the header file:

.. code-block:: c

   #include "arduino_io_switch.h"


   
