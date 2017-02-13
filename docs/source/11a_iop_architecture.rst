*******************************
IO Processor Architecture
*******************************

.. contents:: Table of Contents
   :depth: 2
   
Introduction
==================
   
For overlays to be useful, they must provide sufficient functionality, while also providing flexibility to suit a wide range of applications. Flexibility in the base overlay is demonstrated through the use of IO Processors (IOPs). 

An IO Processor is implemented in the programmable logic and connects to and controls an external port on the board. There are two types of IOP: Pmod IOP and Arduino IOP. 

Each IOP contains a MicroBlaze processor, a configurable switch, peripherals, and local memory for the MicroBlaze instruction and data memory. The local memory is dual-ported (implemented in Xilinx BRAMs), with one port connected to the MicroBlaze, and the other connected to the ARM® Cortex®-A9 processor. This allows the ARM processor to access the MicroBlaze memory and dynamically write a new program to the MicroBlaze instruction area. 

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


* `AXI Timer <http://www.xilinx.com/support/documentation/ip_documentation/axi_timer/v2_0/pg079-axi-timer.pdf>`_
* `AXI IIC <http://www.xilinx.com/support/documentation/ip_documentation/axi_iic/v2_0/pg090-axi-iic.pdf>`_
* `AXI SPI <http://www.xilinx.com/support/documentation/ip_documentation/axi_quad_spi/v3_2/pg153-axi-quad-spi.pdf>`_
* `AXI GPIO <http://www.xilinx.com/support/documentation/ip_documentation/axi_gpio/v2_0/pg144-axi-gpio.pdf>`_ 



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

The timer is 32 bits width, and has a *Generate* output, and a PWM output. The *Generate* signal can output one-time or periodic signal based on a loaded value. For example, on loading a value, the timer can count up or down. Once the counter expires (on a carry) a signal can be generated. The timer can stop, or automatically reload. 

Interrupt controller
^^^^^^^^^^^^^^^^^^^^^^^^^^

The I2c, SPI, GPIO and Timer are connected to the interrupt controller. This is the standard MicroBlaze interrupt controller, and interrupts can be managed by the IOP in a similar way to any other MicroBlaze application. 

Pmod IOP configurable switch
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

The configurable switch can route signals from the internal IP to the external FPGA pins. The switch is controlled by the MicroBlaze, and can be configured from an IOP application.  

For details on using the switch, see the next sections on *IO Processors: Writing your own software* and *IO Processors: Using peripherals in your applications*.



Arduino IOP
===========================

Similar to the Pmod IOP, an Arduino IOP is available to control the Arduino interface. The Arduino IOP is similar to the PMOD IOP, but has some additional internal peripherals (extra timers, an extra I2c, and SPI, a UART, and an XADC). The configurable switch is also different to the Pmod switch. 

.. image:: ./images/arduino_iop.jpg
   :align: center
   
As indicated in the diagram, the Arduino IOP has a MicroBlaze, a configurable switch, and the following peripherals: 



* 6x `AXI Timer <http://www.xilinx.com/support/documentation/ip_documentation/axi_timer/v2_0/pg079-axi-timer.pdf>`_
* 2x `AXI IIC <http://www.xilinx.com/support/documentation/ip_documentation/axi_iic/v2_0/pg090-axi-iic.pdf>`_
* 2x `AXI SPI <http://www.xilinx.com/support/documentation/ip_documentation/axi_quad_spi/v3_2/pg153-axi-quad-spi.pdf>`_
* 3x `AXI GPIO <http://www.xilinx.com/support/documentation/ip_documentation/axi_gpio/v2_0/pg144-axi-gpio.pdf>`_ 
* 1x `AXI UART <https://www.xilinx.com/support/documentation/ip_documentation/axi_uartlite/v2_0/pg142-axi-uartlite.pdf>`_ 
* 1x `AXI Interrupt controller <https://www.xilinx.com/support/documentation/ip_documentation/axi_intc/v4_1/pg099-axi-intc.pdf>`_ 
* 1x `AXI XADC <https://www.xilinx.com/support/documentation/ip_documentation/axi_xadc/v1_00_a/pg019_axi_xadc.pdf>`_ 


Arduino IOP peripherals 
------------------------

The I2C, SPI, GPIO and Timer blocks are the same as the Pmod IOP blocks. The only difference in the Arduino IOP with these blocks is that for the IIC and SPI, 2 interfaces are enabled, for the GPIO 3 blocks are include, and 6 timers. 

I2C
^^^^^^^^^^^^^^^^^^^
Two I2C available. 
   
SPI
^^^^^^^^^^^^^^^^^^^

Two SPI available. One is always connected to the Arduino interface dedicated SPI pins. 
   
GPIO blocks
^^^^^^^^^^^^^^^^^^^

There are three GPIO block available. They support 16 input or output pins on the Arduino interface (D0 - D15).

Timers
^^^^^^^^^^^^^^^^^^^

There are six timers available.

UART
^^^^^^^^^^^^^^^^^^^^^^^

There is a UART controller, with a fixed configuration of 9600 baud. The UART can be connected to the Arduino UART pins. The UART configuration is hard coded, and is part of the overlay. It is not possible to modify the UART configuration in software. 

Interrupt controller
^^^^^^^^^^^^^^^^^^^^^^^
   
The interrupt controller can be connected to all the analog and digital pins, and each of the 6 timers, the I2Cs, the SPIs, the XADC, and UART. This means an external pin on the shield interface can trigger an interrupt. An internal peripheral can also trigger an interrupt.  

Arduino shields have fixed possible configurations.  According to the Arduino specification, the analog pins can be used as analog, or digital I/O. 

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

While there is support for analog inputs via the internal XADC, this only allows inputs of 0-1V. The Arduino interface supports 0-5V analog inputs which is not supported on the PYNQ-Z1.


Arduino IOP configurable Switch
---------------------------------

The switch is controlled by the MicroBlaze, and can be configured by writing to its configuration registers from an IOP application. 

The dedicated SPI pins that are part of the Arduino interface are always connected to one of the SPI controllers. 

The analog and digital pins can be configured by writing a 4-bit value to the corresponding place in the IO switch configuration registers, similar to the Pmod switch.  

For details on using the switch, see the next sections on *IO Processors: Writing your own software* and *IO Processors: Using peripherals in your applications*.