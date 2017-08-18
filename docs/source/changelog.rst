************************
Change Log
************************

Version 2.0
============================

Image release: pynq_z1_v2.0

Documentation updated: 18 Aug 2017

* Overlay changes
   * New logictools overlay
   * Updated to new Trace Analyzer IP in the base overlay
* Repository Changes
   * Repository restructured to provide better support for multiple platforms
   * Repository now supports direct pip install
      * update_pynq.sh is now deprecated
* PYNQ Image build flow now available
* Pynq API Changes
   * pynq.lib combines previous packages: pynq.board, pynq.iop, pynq.drivers
   * The pynq.iop subpackage has been restructured into lib.arduino and lib.pmod

      For example:

      .. code-block:: Python
   
         from pynq.iop import Arduino_Analog 
   
      is replaced by:

      .. code-block:: Python
      
         from pynq.lib.arduino import Arduino_Analog

   * Overlay() automatically downloads an overlays on instantiation by default. 
     Explicit .download() is not required
   * DMA driver replaced with new version

     The buffer is no longer owned by the DMA driver and should instead be
     allocated using `Xlnk.cma_array`. Driver exposes both directions of the DMA
     engine. For example:

     .. code-block:: Python

        send_buffer = xlnk.cma_array(1024, np.float32)
        dma.sendchannel.transfer(send_buffer)
        dma.wait()
        # wait dma.wait_async() also available in coroutines


   * New Video subsystem with support for openCV style frame passing, color space
     transforms, and grayscale conversion
   * New PynqMicroblaze parent class to implement any PYNQ MicroBlaze subsystem
   * New DefaultIP driver to access MMIO, interrupts and GPIO for an IP and
     is used as the base class for all IP drivers
   * New DefaultHierarchy driver to access contained IP as attributes and is
     used as the base class for all hierarchy drivers
   * New AxiGPIO driver
* Linux changes   
   * Addition USB Ethernet drivers added
   * Start-up process added to systemd services 
* New Python Packages 
   * cython 
* IP changes
   * Updated Trace Analyzer, deprecated Trace Buffer
   * Updated Video subsytem with added HLS IP to do color space transforms, and
     grayscale conversion
   * Added new logictools overlay IP: Pattern Generator, Boolean Generator, FSM
     Generator
* Documentation changes
   * Restructured documentation
   * Added :ref:`pynq-overlays` section describing each overlay and its hardware
     components
   * Added :ref:`pynq-libraries` section descriping Python API for each hardware
     component
   * Added :ref:`pynq-package` section for Python Docstrings
   * Creating Overlays section renamed to :ref:`overlay-design-methodology`
   * Added :ref:`pynq-sd-card` section describing PYNQ image build process

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
   
* Updated Python Packages 
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
   * Interrupt controller from overlay to PS added. IOP GPIO connected to
     interrupt controller.
   * Arduino GPIO base address has changed due to merge of GPIO into a single
     block. `arduino_grove_ledbar` and `arduino_grove_buzzer` compiled binaries
     are not backward compatible with previous Pynq overlay/image.

* Pynq API/driver changes
   * TraceBuffer: Bit masks are not required. Only pins should be specified.
   * PL: ``pl_dict`` returns an integer type for any base
     addresshttp://pynq.readthedocs.io/en/latest/4_programming_python.html /
     address range.
   * Video: Video mode constants are exposed outside the class.
   * Microblaze binaries for IOP updated.    
   * Xlnk() driver updated, with better support for SDX 2016.3. Removed the
     customized Xlnk() drivers and use the libsds version.

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
   
