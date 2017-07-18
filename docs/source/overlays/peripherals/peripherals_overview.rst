Peripherals & Interfaces
===========================

Peripherals
-----------

Typical embedded systems support a fixed combination of peripherals (e.g. SPI, IIC, UART, Video, USB ). There may also be some GPIO (General Purpose Input/Output pins) available. The number of GPIO available in a CPU based embedded system is typically limited, and the GPIO are also controlled by the main CPU. As the main CPU which is managing the rest of the system, GPIO performance is usually limited.  

Zynq platforms usually have many more IO pins available than a typical embedded system. Dedicated hardware controllers and additional soft processors can be implemented in the PL and connected to external interfaces. This means performance on these interfaces can be much higher than other embedded system. 

PYNQ runs on Linux which uses the following Zynq PS peripherals by default: SD Card to boot the system and host the Linux file system, Ethernet to connect to Jupyter notebook, UART for Linux terminal access, and USB. 

The USB port and other standard interfaces can be used to connect off-the-shelf USB and other peripherals to the Zynq PS where they can be controlled from Python/Linux. The PYNQ image currently includes drivers for the most commonly used USB webcams, WiFi peripherals, and other standard USB devices.

Other peripherals can be connected to and accessed from the Zynq PL. E.g. HDMI, Audio, Buttons, Switches, LEDs, and general purpose interfaces including Pmods, and Arduino. As the PL is programmable, an overlay which provides controllers for these peripherals or interfaces must be loaded before they can be used. 

A library of hardware IP is included in Vivado which can be used to connect to a wide range of interface standards and protocols. PYNQ provides a Python API for a number of common peripherals including Video (HDMI in and Out), GPIO devices (Buttons, Switches, LEDs), and sensors and actuators. The PYNQ API can also be extended to support additional IP. 


Interfaces
---------------

Zynq platforms usually have one or more *headers* or *interfaces* that allow connection of external peripherals, or to connect directly to the Zynq PL pins. A range of off-the-shelf peripherals can be connected to Pmod and Arduino interfaces. Other peripherals can be connected to these ports via adapters, or with a breadboard. Note that while a peripheral can be physically connected to the Zynq PL pins, a controller must be built into the overlay, and a software driver provided, before the peripheral can be used. 


Pmod port
^^^^^^^^^^^^^^^^^^

A Pmod port is an open 12-pin interface that is supported by a range of Pmod peripherals from Digilent and third party manufacturers. 
Typical Pmod peripherals include sensors (voltage, light, temperature), communication interfaces (Ethernet, serial, WiFi, bluetooth), and input and output interfaces (buttons, switches, LEDs).


.. image:: ../../images/pmod.png
   :align: center


Pmod pins
^^^^^^^^^^^^^^^^

Each Pmod connector has 12 pins arranged in 2 rows of 6 pins. Each row has 3.3V (VCC), ground (GND) and 4 data pins. Using both rows gives 8 data pins in total. 

Pmods come in different configurations depending on the number of data pins required. E.g. Full single row: 1x6 pins; full double row: 2x6 pins; and partially populated: 2x4 pins. 

.. image:: ../../images/pmod_pins.png
   :align: center

Pmods that use both rows (e.g. 2x4 pins, 2x6 pins), should usually be aligned to the left of the connector (to align with VCC and GND). 

.. image:: ../../images/pmod_tmp2_8pin.JPG

Pmod peripherals with only a single row of pins can be connected to either the top row or the bottom row of a Pmod port (again, aligned to VCC/GND). If you are using an existing driver/overlay, you will need to check which pins/rows are supported for a given overlay, as not all options may be implemented. e.g. the Pmod ALS is currently only supported on the top row of a Pmod port, not the bottom row.  

Pmod IO standard
^^^^^^^^^^^^^^^^^^^^^^^^^^

All pins operate at 3.3V. Due to different pull-up/pull-down I/O requirements for different peripherals (e.g. IIC requires pull-up, and SPI requires pull-down) the Pmod data pins have different IO standards. 

Pins 0,1 and 4,5 are connected to pins with pull-down resistors. This can support the SPI interface, and most peripherals. Pins 2,3 and 6,7 are connected to pins with pull-up resistors. This can support the IIC interface. 

Pmods already take this pull up/down convention into account in their pin layout, so no special attention is required when using Pmods. 
   

Other Peripherals
-----------------------------

Pmod ports are design for use with Pmods. The 8 data pins of a Pmod port can be used to connect to a breadboard, or directly to other peripherals. 

Grove peripherals which use a four wire interface can also be connected to the Pmod port through a *PYNQ Grove Adapter*.


PYNQ Grove Adapter
^^^^^^^^^^^^^^^^^^^

A Grove connector has four pins, VCC and GND, and two data pins.

The PYNQ Grove Adapter has four connectors (G1 - G4), allowing up to four Grove devices to be connected to one Pmod port. Remember that an IOP application will be required to support the configuration of connected peripherals.

.. image:: ../../images/pmod_grove_adapter.jpg
   :align: center

Pmod IO standard for Grove
^^^^^^^^^^^^^^^^^^^^^^^^^^^

On the grove adapter G1 and G2 map to Pmod pins [0,4] and [1,5], which are connected to pins with pull-down resistors (supports SPI interface, and most peripherals). G3 and G4 map to pins [2,6], [3,7], which are connected to pins with pull-up resistors (IIC), as indicated in the image. 

.. image:: ../../images/adapter_mapping.JPG
   :align: center
   

Arduino connector
-----------------------

An Arduino connector can be used to connect to Arduino compatible shields to FPGA pins. Remember that appropriate controllers must be implemented in an overlay and connected to the corresponding pins before a shield can be used. Arduino pins can also be used as general purpose pins to connect to custom hardware using wires. 

.. image:: ../../images/pynqz1_arduino_interface.jpg
   :align: center

Arduino pins
^^^^^^^^^^^^^^^^^^^^^^^^^

The Arduino standard specifies 6 analog pins (A0 - A5), 14 multi-purpose Digital pins (D0 - D13), 2 dedicated I2C pins (SCL, SDA), and 4 dedicated SPI pins on the interface.   

Supported Arduino shields
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

Arduino standard supports 5V on all pins, including analog pins. Most Arduino compatible shields can be used with a PYNQ, but as the Zynq XADC (Analog to Digital Converter) only support 1V peak-to-peak, some analog shields may not work without additional interfacing circuitry. 


Using Pmod and Arduino Peripherals
-----------------------------------------

PYNQ introduces IOPs (Input/Output Processors) which are covered in a later section. An IOP consists of a MicroBlaze processor subsystem with dedicated hardware controllers. The appropriate hardware controller can be selected and routed to the physical interface at runtime, depending on the peripheral that is connected. An IOP provides flexibility allowing peripherals with different protocols and interfaces to be used with the same overlay. 
 
A peripheral will have an IOP software application (C/C++), and a Python wrapper. The next sections will cover the IOP architecture, and how to write software applications and the corresponding Python wrapper for a peripheral. 


