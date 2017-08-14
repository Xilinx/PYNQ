PMOD
====

A Pmod port is an open 12-pin interface that is supported by a range of Pmod
peripherals from Digilent and third party manufacturers.  Typical Pmod
peripherals include sensors (voltage, light, temperature), communication
interfaces (Ethernet, serial, WiFi, Bluetooth), and input and output interfaces
(buttons, switches, LEDs).

.. image:: ../images/pmod.png
   :align: center

Pmod IOPs are included in the to control each of the Pmod interfaces on the
board, if provided. As indicated in the diagram, the Pmod IOP has a MicroBlaze,
a configurable switch, and the following peripherals:

Should be a list:

========================== ============================================
AXI I2C                     `AXI I2C Data sheet <http://www.xilinx.com/support/documentation/ip_documentation/axi_iic/v2_0/pg090-axi-iic.pdf>`_           
AXI SPI                     `AXI SPIData sheet <http://www.xilinx.com/support/documentation/ip_documentation/axi_quad_spi/v3_2/pg153-axi-quad-spi.pdf>`_  
AXI Timer                   `AXI Timer Data sheet <http://www.xilinx.com/support/documentation/ip_documentation/axi_timer/v2_0/pg079-axi-timer.pdf>`_     
AXI GPIO                    `AXI GPIO Data sheet <http://www.xilinx.com/support/documentation/ip_documentation/axi_gpio/v2_0/pg144-axi-gpio.pdf>`_
AXI Interrupt controller    `AXI Interrupt controller Data sheet <https://www.xilinx.com/support/documentation/ip_documentation/axi_intc/v4_1/pg099-axi-intc.pdf>`_ 
========================== ============================================

The I2C configuration is:
   * Frequency: 100KHz
   * Address mode: 7 bit
   
The SPI configuration is:
   * Standard mode
   * Transaction width: 8
   * Frequency: 6.25 MHz (100MHz/16)
   * Master mode
   * Fifo depth: 16
   
The GPIO block supports 8 input or output pins

The timer is 32 bits wide, and has a *Generate* output, and a PWM output. The
*Generate* signal can output one-time or periodic signal based on a loaded
value. For example, on loading a value, the timer can count up or down. Once the
counter expires (on a carry) a signal can be generated. The timer can stop, or
automatically reload.

Each Pmod connector has 12 pins arranged in 2 rows of 6 pins. Each row has 3.3V
(VCC), ground (GND) and 4 data pins. Using both rows gives 8 data pins in total.

Pmods come in different configurations depending on the number of data pins
required. E.g. Full single row: 1x6 pins; full double row: 2x6 pins; and
partially populated: 2x4 pins.

.. image:: ../images/pmod_pins.png
   :align: center

Pmods that use both rows (e.g. 2x4 pins, 2x6 pins), should usually be aligned to
the left of the connector (to align with VCC and GND).

.. image:: ../images/pmod_tmp2_8pin.JPG

Pmod peripherals with only a single row of pins can be connected to either the
top row or the bottom row of a Pmod port (again, aligned to VCC/GND). If you are
using an existing driver/overlay, you will need to check which pins/rows are
supported for a given overlay, as not all options may be implemented. e.g. the
Pmod ALS is currently only supported on the top row of a Pmod port, not the
bottom row.

All pins operate at 3.3V. Due to different pull-up/pull-down I/O requirements
for different peripherals (e.g. IIC requires pull-up, and SPI requires
pull-down) the Pmod data pins have different IO standards.

Pins 0,1 and 4,5 are connected to pins with pull-down resistors. This can
support the SPI interface, and most peripherals. Pins 2,3 and 6,7 are connected
to pins with pull-up resistors. This can support the IIC interface.

Pmods already take this pull up/down convention into account in their pin
layout, so no special attention is required when using Pmods.


Block Diagram
-------------
.. image:: ../images/pmod_iop.jpg
   :align: center

IOP drivers are provided for the following Pmods:

* Pmod ADC (AD2)
* Pmod Ambient Light Sensor
* Pmod DAC (DA4)
* Pmod Digital Potentiometer
* Pmod OLED
* Pmod PWM
* Pmod Temperature sensor
* Pmod TC1 Thermocouple

Examples
--------

For Pmod examples, see the base/Pmod directory in the Jupyter home area on the 
board.