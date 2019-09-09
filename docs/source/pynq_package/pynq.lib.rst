pynq.lib Package
================

pynq.lib contains the arduino, pmod, and logictools subpackages, and additional
modules for communicating with other controllers in an overlay.

Modules:
  * pynq.lib.audio - Implements mono-mode audio driver using pulse density modulation (PDM)
  * pynq.lib.axigpio - Implements driver for AXI GPIO IP
  * pynq.lib.iic - Implements driver for AXI IIC IP
  * pynq.lib.button - Implements driver for AXI GPIO push button IP
  * pynq.lib.dma - Implements driver for the AXI Direct Memory Access (DMA) IP
  * pynq.lib.led - Implements driver for AXI GPIO LED IP
  * pynq.lib.pynqmicroblaze - Implements communcation and control for a PYNQ MicroBlaze subsystem
  * pynq.lib.rgbled - Implements driver for AXI GPIO multi color LEDs
  * pynq.lib.switch - Implements driver for AXI GPIO Dual In-Line (DIP) switches
  * pynq.lib.wifi - Implements driver for WiFi
  * pynq.lib.video - Implements driver for HDMI video input/output
  
Subpackages:
  * pynq.lib.arduino - Implements driver for Arduino IO Processor Subsystem
  * pynq.lib.pmod - Implements driver for PMOD IO Processor Subsystem
  * pynq.lib.rpi - Implements driver for Raspberry Pi IO Processor Subsystem
  * pynq.lib.logictools - Implements driver for Logictools IP Processor Subsystem

.. toctree::
    :hidden:

    pynq.lib/pynq.lib.arduino
    pynq.lib/pynq.lib.audio
    pynq.lib/pynq.lib.axigpio
    pynq.lib/pynq.lib.iic
    pynq.lib/pynq.lib.button
    pynq.lib/pynq.lib.dma
    pynq.lib/pynq.lib.led
    pynq.lib/pynq.lib.logictools
    pynq.lib/pynq.lib.pmod
    pynq.lib/pynq.lib.pynqmicroblaze
    pynq.lib/pynq.lib.rgbled
    pynq.lib/pynq.lib.rpi
    pynq.lib/pynq.lib.switch
    pynq.lib/pynq.lib.video
    pynq.lib/pynq.lib.wifi
