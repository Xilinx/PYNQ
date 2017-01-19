**************************
Peripherals and Interfaces
**************************

.. contents:: Table of Contents
   :depth: 2
   
Pmod Interface
===================

A Pmod port is an open 12-pin interface that is supported by a range of Pmod peripherals from Digilent and third party manufacturers. 
Typical Pmod peripherals include sensors (voltage, light, temperature), communication interfaces (Ethernet, serial, wifi, bluetooth), and input and output interfaces (buttons, switches, LEDs).

There are two Pmod connectors on PYNQ-Z1.

.. image:: ./images/pynqz1_pmod_interface.jpg
   :align: center


Pmod Port
-----------------------

Each Pmod connector has 12 pins arranged in 2 rows of 6 pins. Each row has 3.3V (VCC), ground (GND) and 4 data pins. Using both rows gives 8 data pins in total. 

Pmods come in different configurations depending on the number of data pins required. e.g. Full single row: 1x6 pins; full double row: 2x6 pins; and partially populated: 2x4 pins. 

.. image:: images/pmod_pins.png
   :align: center

Pmods that use both rows (e.g. 2x4 pins, 2x6 pins), should usually be aligned to the left of the connector (to align with VCC and GND). VCC and GND are labelled on the PYNQ-Z1 board. 

.. image:: images/pmod_tmp2_8pin.JPG

Pmod peripherals with only a single row of pins can be connected to either the top row or the bottom row of a Pmod port (again, aligned to VCC/GND). If you are using an existing driver/overlay, you will need to check which pins/rows are supported for a given overlay, as not all options may be implemented. e.g. the Pmod ALS is currently only supported on the top row of a Pmod port, not the bottom row.  

Other Peripherals
-----------------------------

Pmod ports are design for use with Pmods. The 8 data pins of a Pmod port can be used to connect to a breadboard, or directly to other peripherals. 

Grove peripherals which use a four wire interface can also be connected to the Pmod port through a *PYNQ Grove Adapter*.


PYNQ Grove Adapter
^^^^^^^^^^^^^^^^^^^

A Grove connector has four pins, VCC and GND, and two data pins.

The PYNQ Grove Adapter has four connectors (G1 - G4), allowing up to four Grove devices to be connected to one Pmod port. Remember that an IOP application will be required to support the configuration of connected peripherals.

.. image:: ./images/pmod_grove_adapter.jpg
   :align: center

All pins operate at 3.3V. Due to different pull-up/pull-down I/O requirements for different peripherals (e.g. IIC requires pull-up, and SPI requires pull-down) the Pmod data pins have different IO standards. 

G1 and G2 ([0,4] and [1,5]) are connected to pins with pull-down resistors (supports SPI interfacae, and most peripherals), and G3 and G4 ([2,6], [3,7]) are connected to pins with pull-up resistors (IIC), as indicated in the image. 

.. image:: ./images/adapter_mapping.JPG
   :align: center

Pmods already take this pull up/down convention into account in their pin layout, so no special attention is required to connect Pmods. 
   

Arduino Peripherals
============================

There is one Arduino connector on the board and can be used to connect to arduino compatible shields. 

.. image:: ./images/pynqz1_arduino_interface.jpg
   :align: center

Arduino Connector
-----------------------

Each Arduino connector has 6 analog pins (A0 - A5), 14 multi-purpose Digital pins (D0 - D13), 2 dedicated I2C pins (SCL, SDA), and 4 dedicated SPI pins. 


Supported Peripherals
-----------------------------

Most Arduino compatible shields can be used with the PYNQ-Z1 board. However, the PYNQ-Z1 board has a limited analog range, so not all Arduino analog shields are supported. 


PYNQ Shield
--------------------

As mentioned previously, each Grove connector has 4 pins. The PYNQ Shield has 12 Grove connectors for digital IO (I2C, UART, G1 - G7) and 4 Grove connectors for analog IO (A1 - A4).

.. image:: ./images/arduino_shield.jpg
   :align: center

With the PYNQ shield jumper (JP1) set to 3.3V (as in the figure), all the pins operate at 3.3V. 

xxx pin numbers, and connfigurations


==========   =========================
Peripheral   Pins
==========   =========================
UART         D0, D1
I2C          A4, A5
SPI*         D10 - D13
PWM          D3, D5, D6, D9, D10, D11
Timer        D3 - D6 and D8 - D11
==========   =========================
