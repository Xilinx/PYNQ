************************
Change Log
************************

Version 2.6.0 
============================

Updates to PYNQ since the last release include:

* Image releases:
   * pynq_z1_v2.6.0
   * pynq_z2_v2.6.0
   * zcu104_v2.6.0
   * zcu111_v2.6.0
   
* Upgraded Software
   * All overlays built with Vivado 2020.1
   * Linux kernel and build updated to Petalinux 2020.1

* Productivity Additions
   * Docker support enabled in the kernel config
   * Pybind11 support and notebook added for C++ integration
   * Support for BOOT.BIN bitstream inclusion for custom sdcard builds
   * Boot.py added to boot partition to enable modifications to the PYNQ boot flow.

* Deprecations
   * Removed Xlnk allocator from all notebooks - please now use pynq.allocate
   * Tcl parsing removed - please generate and use an HWH file for Overlays


Version 2.5.1 
============================

Updates to PYNQ since the last release include:

* Alveo and AWS F1 Support
   * Alveo platforms and AWS F1 instances are now supported
   * IP dictionary and Overlay classes support xclbin metadata parsing
   * Live Alveo power monitoring added
   * Vitis kernel signatures delivered with loaded xlcbin files
   * AWS F1 awsxclbin files are supported

* Productivity Additions
   * PYNQ is now on PYPI and can be installed using ``pip install pynq``
   * PYNQ can be installed on x86 machines to support attached Alveo platforms or AWS F1 instances
   * pynq.utils added for dependent packages to install notebooks and bitstreams
   * pynq._cli added for new commandline calls to collect and deliver notebooks
   * JupyterLab views of bitstream metadata dictionaries added

* SD Build Updates
   * Support added for building sdcard images from Ubuntu 18.04 host machines

* No new SD Card images were created for this release


Version 2.5 
============================

* Image releases:
   * pynq_z1_v2.5
   * pynq_z2_v2.5
   * zcu104_v2.5
   * zcu111_v2.5

Within those image files, PYNQ v2.5 is already installed. Updates to PYNQ since the last release include:

* Productivity Additions
   * Updated to JupyterLab 1.1.3
   * JupyterLab extensions support added
   * Support for multiple memories using mem_dict entries
   * Support for Device Tree Overlays delivered with PL overlays
   * Support for custom PL device communication using the Device metaclass 
* Programmable Logic Updates
   * All bitstreams built using Vivado 2019.1
   * XRT Support added (beta)
* Repository Updates
   * Jenkins CI added
   * Sdist support added (removing all binaries from the repository)
* SDBuild Updates
   * Boot partition built on Petalinux 2019.1


Version 2.4 
============================

* Image releases:
   * pynq_z1_v2.4
   * pynq_z2_v2.4
   * zcu104_v2.4
   * zcu111_v2.4 

Documentation updated 22 Feb 2019

* Board Additions
   * RFSoC support added in the new ZCU111-PYNQ repository
* Programmable Logic Updates
   * All bitstreams built using Vivado 2018.3
   * Partial reconfiguration support added (beta)
   * Expanded metadata parsing using the Vivado hwh files
* SDBuild Updates
   * Boot partition built on Petalinux 2018.3
   * SDSoC 2018.3 support added
   * Vagrant configuration file for users building their own SDCard images
   * Yocto recipes added for including PYNQ in Petalinux root filesystems


Version 2.3 
============================

* Image releases:
   * pynq_z1_v2.3
   * pynq_z2_v2.3
   * zcu104_v2.3  

Documentation updated 7 Sep 2018

* Architecture Additions
   * Zynq UltraScale+ (ZU+) support added
* Board Additions
   * ZCU104 support added
* Programmable Logic Updates
   * All bitstreams built using Vivado 2018.2
   * Initial support for DSA generation and PL parsing added
   * Removed custom toplevel wrapper file requirement
* SDBuild Updates
   * Root filesystem based on Ubuntu 18.04
   * Boot partition built on Petalinux 2018.2
   * SDSoC 2018.2 support added
   * Added fpga_manager support for Zynq and ZU+
   * AWS Greengrass kernel configuration options added
   * Custom board support updated
* New PYNQ Python Modules
   * Added ZU+ DisplayPort
   * Added PMBus power monitoring
   * Added uio support
   * Added AXI IIC support
* New Microblaze Programming Notebooks
   * Added arduino ardumoto, arduino joystick, grove usranger notebooks

   
Version 2.2 
============================

Image release: pynq_z2_v2.2

Documentation updated 10 May 2018

* Board Additions
   * PYNQ-Z2 support added
* New Microblaze Subsystems
   * Added RPi Microblaze subsystem, bsp and notebooks
* New IP
   * Added audio with codec support


Version 2.1 
============================

Image release: pynq_z1_v2.1

Documentation updated 21 Feb 2018

* Overlay Changes
   * All overlays updated to build with Vivado 2017.4
   * Hierarchical IPs' port names refactored for readability and portability
   * The IOP hierarchical blocks are renamed from iop_1, 2, 3 to iop_pmoda, iop_pmodb, and iop_arduino
   * The Microblaze subsystem I/O controllers were renamed to be iop agnostic
* Base Overlay Changes
   * The onboard switches and LEDs controlled are now controlled by two AXI_GPIO IPs.
   * The 2nd I2C (shared) from the Arduino IOP was removed
* IP Changes
   * IP refactored for better portability to new boards and interfaces
   * IO Switch now with configuration options for pmod, arduino, dual pmod,
     and custom I/O connectivity
   * IO Switch now with standard I/O controller interfaces for IIC and SPI
* Linux changes   
   * Updated to Ubuntu 16.04 LTS (Xenial)
   * Updated kernel to tagged 2017.4 Xilinx release.
   * Jupyter now listens on both :80 and :9090 ports
   * opencv2.4.9 removed
* Microblaze Programming
   * IPython magics added for Jupyter programming of Microblazes
   * Microblaze pyprintf, RPC, and Python-callable function generation added.
   * New notebooks added to demonstrate the programming APIs
* Repository Changes
   * Repository pynqmicroblaze now a package to support Microblaze programming
* Pynq API Changes
   * Audio class renamed to AudioDirect to allow for future audio codec classes
* New Python Packages 
   * netifaces, imutils, scikit-image
* Device Updates
   * Removed version-deprecated Grove-I2C Color Sensor


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
   
