pynq.lib Package
================

pynq.lib contains the pmod subpackage and additional
modules for communicating with other controllers in an overlay.

Modules:
  * :mod:`pynq.lib.audio` - Implements mono-mode audio driver using pulse density modulation (PDM)
  * :mod:`pynq.lib.axigpio` - Implements driver for AXI GPIO IP
  * :mod:`pynq.lib.axiswitch` - Implements driver for AXI Stream switch IP
  * :mod:`pynq.lib.button` - Implements driver for AXI GPIO push button IP
  * :mod:`pynq.lib.cmac` - Implements driver for UltraScale+ Integrated 100G Ethernet Subsystem
  * :mod:`pynq.lib.dma` - Implements driver for the AXI Direct Memory Access (DMA) IP
  * :mod:`pynq.lib.iic` - Implements driver for AXI IIC IP
  * :mod:`pynq.lib.led` - Implements driver for AXI GPIO LED IP
  * :mod:`pynq.lib.pynqmicroblaze.pynqmicroblaze` - Implements communcation and control for a PYNQ MicroBlaze subsystem
  * :mod:`pynq.lib.rgbled` - Implements driver for AXI GPIO multi color LEDs
  * :mod:`pynq.lib.switch` - Implements driver for AXI GPIO Dual In-Line (DIP) switches
  * :mod:`pynq.lib.video` - Implements driver for HDMI video input/output
  * :mod:`pynq.lib.wifi` - Implements driver for WiFi
  
Subpackages:
  * :ref:`pynq-lib-pmod` - Implements driver for PMOD IO Processor Subsystem

.. toctree::
    :hidden:

    pynq.lib/pynq.lib.audio
    pynq.lib/pynq.lib.axigpio
    pynq.lib/pynq.lib.button
    pynq.lib/pynq.lib.cmac
    pynq.lib/pynq.lib.dma
    pynq.lib/pynq.lib.iic
    pynq.lib/pynq.lib.led
    pynq.lib/pynq.lib.pmod
    pynq.lib/pynq.lib.pynqmicroblaze
    pynq.lib/pynq.lib.rgbled
    pynq.lib/pynq.lib.switch
    pynq.lib/pynq.lib.video
    pynq.lib/pynq.lib.wifi
