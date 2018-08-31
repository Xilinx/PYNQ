.. _pynq-libraries:

**************
PYNQ Libraries
**************

Typical embedded systems support a fixed combination of peripherals (e.g. SPI,
IIC, UART, Video, USB ). There may also be some GPIO (General Purpose
Input/Output pins) available. The number of GPIO available in a CPU based
embedded system is typically limited, and the GPIO are also controlled by the
main CPU. As the main CPU which is managing the rest of the system, GPIO
performance is usually limited.

Zynq platforms usually have many more IO pins available than a typical embedded
system. Dedicated hardware controllers and additional soft processors can be
implemented in the PL and connected to external interfaces. This means
performance on these interfaces can be much higher than other embedded system.

PYNQ runs on Linux which uses the following Zynq PS peripherals by default: SD
Card to boot the system and host the Linux file system, Ethernet to connect to
Jupyter notebook, UART for Linux terminal access, and USB.

The USB port and other standard interfaces can be used to connect off-the-shelf
USB and other peripherals to the Zynq PS where they can be controlled from
Python/Linux. The PYNQ image currently includes drivers for the most commonly
used USB webcams, WiFi peripherals, and other standard USB devices.

Other peripherals can be connected to and accessed from the Zynq PL. E.g. HDMI,
Audio, Buttons, Switches, LEDs, and general purpose interfaces including Pmods,
and Arduino. As the PL is programmable, an overlay which provides controllers
for these peripherals or interfaces must be loaded before they can be used.

A library of hardware IP is included in Vivado which can be used to connect to a
wide range of interface standards and protocols. PYNQ provides a Python API for
a number of common peripherals including Video (HDMI in and Out), GPIO devices
(Buttons, Switches, LEDs), and sensors and actuators. The PYNQ API can also be
extended to support additional IP.

Zynq platforms usually have one or more *headers* or *interfaces* that allow
connection of external peripherals, or to connect directly to the Zynq PL
pins. A range of off-the-shelf peripherals can be connected to Pmod and Arduino
interfaces. Other peripherals can be connected to these ports via adapters, or
with a breadboard. Note that while a peripheral can be physically connected to
the Zynq PL pins, a controller must be built into the overlay, and a software
driver provided, before the peripheral can be used.

.. toctree::
    :maxdepth: 1
    :hidden:
       
    pynq_libraries/psgpio.rst
    pynq_libraries/axigpio.rst
    pynq_libraries/mmio.rst
    pynq_libraries/xlnk.rst
    pynq_libraries/dma.rst
    pynq_libraries/pl.rst
    pynq_libraries/overlay.rst
    pynq_libraries/audio.rst
    pynq_libraries/video.rst
    pynq_libraries/pmod.rst
    pynq_libraries/arduino.rst
    pynq_libraries/grove.rst
    pynq_libraries/logictools.rst
    pynq_libraries/pynq_microblaze_subsystem.rst
    pynq_libraries/pynqmb_python.rst
    pynq_libraries/pynqmb_reference.rst       
    pynq_libraries/pmbus.rst
