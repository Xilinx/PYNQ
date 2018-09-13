.. _pynqz2-overlays:

****************
PYNQ-Z2 Overlays
****************

The PYNQ-Z2  board has the following features:

  * Zynq XC7Z020-1CLG400C
  * 512MB DDR3
  * 1G Ethernet
  * USB 2.0
  * MicroSD
  * Uart
  * ADAU1761 Audio Codec with 3.5mm HP/Mic and line-in jacks
  * 2x HDMI (can be used as input or output) 
  * 4 push-buttons
  * 2 slide switches
  * 4 LEDs
  * 2 RGB LEDs
  * 2x Pmod ports
  * 1x Arduino header 
  * 1x RaspberryPi header
  
Note that 8 pins of the RaspberryPi header are shared with one of the Pmod ports.

For details on the PYNQ-Z2 board including reference manual, schematics, 
constraints file (xdc),
see the `PYNQ-Z2 webpage <http://www.tul.com.tw/ProductsPYNQ-z2.html>`_

The following overlays are include by default in the PYNQ image for the PYNQ-Z2 board:

.. toctree::
    :maxdepth: 1
   
    pynqz2/pynqz2_base_overlay
    pynqz2/pynqz2_logictools_overlay

Other third party overlays may also be available for this board. See the 
`PYNQ community webpage <http://www.pynq.io/community.html>`_ for details of 
third party overlays and other resources. 