************************
Change log
************************

.. contents:: Table of Contents
   :depth: 2

Version 1.4 
============================

Image release: pynq_z1_image_2016_02_10

Documentation updated:  10 Feb 2017

* Xilinx Linux kernel upgraded to 4.6.0

* Added Linux Packages
   * Python3.6
   * iwconfig
   * iwlist
   * microblaze-gcc

* New Python Packages 
   * asyncio
   * uvloop
   * transitions
   * pygraphviz
   * pyeda
   
* Updated Python Pacakges 
   * pynq
   * Jupyter Notebook Extension added
   * IPython upgraded to support Python 3.6
   * pip
 
* Other changes
   * Jupyter extensions
   * reveal.js updated
   * update_pynq.sh
   * wavedrom.js

* Base overlay changes
   * IOP interface to DDR added (Pmod and Arduino IOP)
   * Interrupt controller from overlay to PS added. IOP GPIO connected to Interrupt controller. 
   * Arduino GPIO base address has changed due to merge of GPIO into a single block.  `arduino_grove_ledbar` and `arduino_grove_buzzer` compiled binaries are not backward compatible with previous Pynq overlay/image.

* Pynq API/driver changes
   * TraceBuffer: Bit masks are not required. Only pins should be specified. 
   * PL: ``pl_dict`` returns an integer type for any base addresshttp://pynq.readthedocs.io/en/latest/4_programming_python.html / address range.
   * Video: Video mode constants are exposed outside the class.
   * Microblaze binaries for IOP updated.    
   * Xlnk() driver updated, with better support for SDX 2016.3. Removed the customized Xlnk() drivers and use the libsds version.

* Added new iop modules  
   * arduino_lcd18
   
* Added Notebooks	
   * audio (updated)
   * arduino_lcd (new)
   * utilities (new)
   * asyncio (new)
   
* Documentation changes
   * New section on peripherals and interfaces
   * New section on using peripherals in your applications
   * New section on Asyncio/Interrupts
   * New section on trace buffer
   
Version 1.3
=================

Image release: pynq_z1_image_2016_09_14

Documentation updated: 16 Dec 2016

* Added new iop modules to docs
   * Arduino Grove Color
   * Arduino Grove DLight
   * Arduino Grove Ear HR
   * Arduino Grove Finger HR
   * Arduino Grove Haptic motor
   * Arduino Grove TH02
   * Pmod Color
   * Pmod DLight
   * Pmod Ear HR
   * Pmod Finger HR
   * Pmod Haptic motor
   * Pmod TH02
* Added USB WiFI driver
   