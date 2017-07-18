Arduino
=======

An Arduino IOP is available to control the Arduino interface. The Arduino IOP is
similar to the PMOD IOP, but has some additional internal peripherals (extra
timers, an extra I2c, and SPI, a UART, and an XADC). 

An Arduino connector can be used to connect to Arduino compatible shields to
FPGA pins. Remember that appropriate controllers must be implemented in an
overlay and connected to the corresponding pins before a shield can be
used. Arduino pins can also be used as general purpose pins to connect to custom
hardware using wires.

.. image:: ../images/pynqz1_arduino_interface.jpg
   :align: center


As indicated in the diagram, the Arduino IOP has a MicroBlaze, a configurable
switch, and the following peripherals:

============================= ==========================================
2x AXI I2C                     `AXI I2C Data sheet <http://www.xilinx.com/support/documentation/ip_documentation/axi_iic/v2_0/pg090-axi-iic.pdf>`_
2x AXI SPI                     `AXI SPI Data sheet <http://www.xilinx.com/support/documentation/ip_documentation/axi_quad_spi/v3_2/pg153-axi-quad-spi.pdf>`_
3x AXI GPIO                    `AXI GPIO Data sheet <http://www.xilinx.com/support/documentation/ip_documentation/axi_gpio/v2_0/pg144-axi-gpio.pdf>`_ 
6x AXI Timer                   `AXI Timer Data sheet <http://www.xilinx.com/support/documentation/ip_documentation/axi_timer/v2_0/pg079-axi-timer.pdf>`_
1x AXI UART                    `AXI UART Data sheet <https://www.xilinx.com/support/documentation/ip_documentation/axi_uartlite/v2_0/pg142-axi-uartlite.pdf>`_ 
1x AXI Interrupt controller    `AXI Interrupt controller Data sheet <https://www.xilinx.com/support/documentation/ip_documentation/axi_intc/v4_1/pg099-axi-intc.pdf>`_ 
1x AXI XADC                    `AXI XADC Data sheet <https://www.xilinx.com/support/documentation/ip_documentation/axi_xadc/v1_00_a/pg019_axi_xadc.pdf>`_ 
============================= ==========================================

The I2C, SPI, GPIO and Timer blocks are the same as the Pmod IOP blocks. The
only difference in the Arduino IOP with these blocks is that for the IIC and
SPI, 2 interfaces are enabled, for the GPIO 3 blocks are include, and 6 timers.

The I2C configuration is:
   * Frequency: 100KHz
   * Address mode: 7 bit
   
The SPI configuration is:
   * Standard mode
   * Transaction width: 8
   * Frequency: 6.25 MHz (100MHz/16)
   * Master mode
   * Fifo depth: 16

One SPI controller always connected to the Arduino interface dedicated SPI pins.
   
There are three GPIO block available. They support 16 input or output pins on
the Arduino interface (D0 - D15).

There are six timers available.  There is a UART controller, with a fixed
configuration of 9600 baud. The UART can be connected to the Arduino UART
pins. The UART configuration is hard coded, and is part of the overlay. It is
not possible to modify the UART configuration in software.


==========   =========================
Peripheral   Pins
==========   =========================
UART         D0, D1
I2C          A4, A5
SPI*         D10 - D13
PWM          D3, D5, D6, D9, D10, D11
Timer        D3 - D6 and D8 - D11
==========   =========================

Analog inputs are supported via the internal Xilinx XADC. This supports inputs
of 1V peak-to-peak. Note that the Arduino interface supports 0-5V analog inputs
which is not supported by Zynq without external circuitry.

Block Diagram
-------------

.. image:: ../images/arduino_iop.jpg
   :align: center
   

Examples
--------
