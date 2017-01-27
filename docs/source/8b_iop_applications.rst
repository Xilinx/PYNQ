********************************************
IO Processors: Writing Your Own Software
********************************************

.. contents:: Table of Contents
   :depth: 2
   
There are a number of steps required before you can start writing your own software for an IOP (IO Processor). This document will describe the IOP architecture, and how to set up and build the required software projects to allow you to write your own application for the MicroBlaze inside an IOP. Xilinx® SDK projects can be created manually using the SDK GUI, or software can be built using a Makefile flow. 

IO Processors
==============

As described in the previous section, an IOP can be used as a flexible controller for different types of external peripherals. The ARM® Cortex®-A9 is an application processor, which runs Pynq and Jupyter notebook on a Linux OS. This scenario is not well suited to real-time applications, which is a common requirement for an embedded systems.  In the base overlay there are three IOPs. As well as acting as a flexible controller, an IOP can be used as dedicated real-time controller.

IOPs can also be used standalone to offload some processing from the main processor. However, note that the MicroBlaze processor inside an IOP in the base overlay is running at 100 MHz, compared to the Dual-Core ARM Cortex-A9 running at 650 MHz. The clock speed, and different processor architectures and features should be taken into account when offloading pure application code. e.g. Vector processing on the ARM Cortex-A9 Neon processing unit will be much more efficient than running on the MicroBlaze. The MicroBlaze is most appropriate for low-level, background, or real-time applications.

Previous sections showed the similarities between the Pmod IOP and Arduino IOP. Each IOP contains a `Xilinx MicroBlaze processor <https://en.wikipedia.org/wiki/MicroBlaze>`_, a Debug module, and one or more of the following functional units and interface peripherals:

   * `AXI Timer <http://www.xilinx.com/support/documentation/ip_documentation/axi_timer/v2_0/pg079-axi-timer.pdf>`_
   * `AXI IIC <http://www.xilinx.com/support/documentation/ip_documentation/axi_iic/v2_0/pg090-axi-iic.pdf>`_
   * `AXI SPI <http://www.xilinx.com/support/documentation/ip_documentation/axi_quad_spi/v3_2/pg153-axi-quad-spi.pdf>`_
   * `AXI GPIO <http://www.xilinx.com/support/documentation/ip_documentation/axi_gpio/v2_0/pg144-axi-gpio.pdf>`_ 

The Arduino also includes a UART, and XADC. 

The interface peripherals are connected to a Configurable Switch. The switch is different for the Pmod and the Arduino IOPs. The Pmod configurable switch connects to a Pmod port, and the Arduino configurable switch connects to an Arduino interface connector.

Pmod IOP:


.. image:: ./images/pmod_iop.jpg
   :align: center

   
The IOP's configurable switch can be used to route signals between the physical interface, and the available internal peripherals in the IOP sub-system. 
     
Software requirements
==========================

A MicroBlaze cross-compiler is required to build software for the MicroBlaze inside an IOP.  Xilinx SDK contains the MicroBlaze cross-compiler and was used to build all Pmod device drivers released with Pynq and is available for free.  It should be noted that Pynq ships with precompiled IOP executables to support various peripherals (see `Pynq Modules <modules.html>`_), but that full source code is available from the project GitHub. Xilinx software is only needed if you intend to build your own IOP applications/peripheral drivers. A free, fully functional, version of the Xilinx tools is available for Pynq if required (see the free `Xilinx Vivado WebPack <https://www.xilinx.com/products/design-tools/vivado/vivado-webpack.html>`_ for more details).  

The current Pynq release is built using Vivado and SDK 2016.1. it is recommended to use the same version to rebuild existing Vivado and SDK projects. If you only intend to build software, you will only need to install SDK. The full Vivado and SDK installation is only required to design new overlays. 

`Download Xilinx Vivado and SDK 2016.1 <http://www.xilinx.com/support/download/index.html/content/xilinx/en/downloadNav/vivado-design-tools/2016-1.html>`_

You can use the Vivado HLx Web Install Client and select SDK and/or Vivado during the installation.

Pynq also support building of bitstreams from SDSoC. SDSoC is currently a separate download and installation from the main Vivado/SDK software. 

Compiling projects
==========================

Software executables run on the MicroBlaze inside the IOP. Code for the MicroBlaze can be written in C or C++ and compiled using the `Xilinx SDK (Software Development Kit) <http://www.xilinx.com/products/design-tools/embedded-software/sdk.html>`_. 

You can pull or clone the Pynq GitHub repository, and all the driver source and project files can be found in ``<GitHub Repository>\Pynq-Z1\sdk``,  (Where ``<GitHub Repository>`` is the location of the PYNQ repository).  

These projects are considered SDK *Application* projects and contain the top level application. Each SDK project requires a BSP project (Board Support Package), and a hardware platform project. See below for more details. Software libraries are included in a Board Support Package (BSP) project, and the BSP is linked to from the application project. 

All *Application* projects can be compiled from the command line using Makefiles, or imported into the SDK GUI. 

You can also use existing projects as a starting point to create your own project. 

HDF file
------------

Before an Application project and BSP can be created or compiled in SDK, a *Hardware Platform*  project is required. A Hardware Platform defines the peripherals in the IOP subsystem, and the memory map of the system, and is used by the BSP to build software libraries to support the underlying hardware. 

A Hardware Description File (.hdf), created by Vivado, is used to create the *Hardware Platfrom*  project in SDK.

A precompiled .hdf file is provided, so it is not necessary to run Vivado to generate a .hdf file:

   ``<GitHub Repository>/Pynq-Z1/sdk/``

Board Support Package
--------------------------

The BSP (Board Support Package) contains software libraries and drivers to support the underlying peripherals in the system.

A BSP must be linked to a Hardware Platform, as this is where the peripherals in the system are defined. An Application Project is then linked to a BSP, and can use the libraries available in the BSP.

Building the projects
--------------------------

A Makefile to automatically create and build the Hardware Platform and the BSP can be found in the same location as the .hdf file. 

    ``<GitHub Repository>/Pynq-Z1/sdk/makefile``

Application projects for peripherals that ship with Pynq (e.g. Pmods and Grove peripherals) can also be found in the same location. Each project is contained in a separate folder. 
   
The Makefile uses the .hdf file to create the Hardware Platform. The BSP can then be created. The application projects will also be compiled automatically as part of this process.

The Makefile requires SDK to be installed, and can be run from Windows, or Linux.

To run ``make`` from Windows, open SDK, and choose a temporary workspace (make sure this path is external to the downloaded GitHub repository). From the *Xilinx Tools* menu, select *Launch Shell*

.. image:: ./images/sdk_launch_shell.jpg
   :scale: 75%
   :align: center

In Linux, open a terminal, and source the SDK tools.

From either the Windows Shell, or the Linux terminal, navigate to the sdk folder in your local copy of the GitHub repository: 

   cd to ``<GitHub Repository>/Pynq-Z1/sdk`` and run ``make``

.. image:: ./images/sdk_make.JPG
   :scale: 75%
   :align: center

.. image:: ./images/sdk_make_result.JPG
   :scale: 75%
   :align: center
   
This will create the Hardware Platform Project (*hw_def*), and the Board Support Package (*bsp*), and then link and build all the application projects. 

If you examine the Makefile, you can see how the *MBBINS* variable at the top of the makefile is used to compile the application projects. If you want to add your own custom project to the build process, you need to add the project name to the *MBBINS* variable, and save the project in the same location as the other application projects.

Individual projects can be built by navigating to the ``<project directory>/Debug`` and running ``make``.

Binary files
-----------------

Compiling code produces an executable file (.elf) which needs to be converted to binary format (.bin) to be downloaded to, and run on, an IOP. 

A .bin file can be generated from a .elf by running the following command from the SDK shell:

    ``mb-objcopy -O binary <inputfile>.elf <outputfile>.bin``

This is done automatically by the makefile for the existing application projects. The makefile will also copy all .bin files into the ``<GitHub Repository>/Pynq-Z1/sdk/bin`` folder.

Creating your own Application project
--------------------------------------

Using the Makefile flow, you can use an existing project as a starting point for your own project. 

Copy and rename the project, and modify or replace the .c file in the src/ with your C code. The generated .bin file will have the same base name as your C file. 

e.g. if your C code is my_peripheral.c, the generated .elf and .bin will be my_peripheral.elf and my_peripheral.bin.

We encourage the following naming convention for applications <pmod|grove|arduino>_<peripheral>

You will need to update references from the old project name to your new project name in ``<project directory>/Debug/makefile`` and ``<project directory>/Debug/src/subdir.mk``

If you want your project to build in the main Makefile, you should also append the .bin name of your project to the *MBBINS* variable at the top of the makefile.

If you are using the SDK GUI, you can import the Hardware Platform, BSP, and any application projects into your SDK workspace.

.. image:: ./images/sdk_import_bsp.JPG
   :scale: 75%
   :align: center


The SDK GUI can be used to build and debug your code.  
    
IOP Memory
==========================


Each IOP has local memory (immplemented in Xilinx BRAMs) and a donnection to DDR memory. 

The IOP instruction and data memory is implemented in a dual port Block RAM, with one port connected to the IOP, and the other to the ARM processor. This allows an executable binary file to be written from the ARM (i.e. the Pynq environment) to the IOP instruction memory. The IOP can also be reset from Pynq, allowing the IOP to start executing the new program. 

The DDR can be used as extra data memory. You need to be careful when using DDR memory, as this is shared with the rest of the system, including other IOPs. 

xxx : How should DR be used?

The IOP data memory, either in local memory, or in DDR memory, can be used as a mailbox for communication and data exchanges between the Pynq environment and the IOP.


Memory map
----------

The local IOP memory is 64KB of shared data and instruction memory. Instruction memory for the IOP starts at address 0x0.

Pynq and the application running on the IOP can write to anywhere in the shared memory space. You should be careful not to write to the instruction memory unintentionally as this will corrupt the running application.  

When building the MicroBlaze project, the compiler will only ensure that the application and *allocated* stack and heap fit into the BRAM and DDR if used. For communication between the ARM and the MicroBlaze, a part of the shared memory space must also be reserved within the MicroBlaze address space. 

There is no memory management in the IOP. You must ensure the application, including stack and heap, do not overflow into the defined data area. Remember that declaring a stack and heap size only allocates space to the stack and heap. No boundary is created, so if sufficient space was not allocated, the stack and heap may overflow and corrupt your application.

If you need to modify the stack and heap for an application, the linker script can be found in the ``<project>/src/`` directory.

It is recommended to follow the convention for data communication between the two processors via MAILBOX. These MAILBOX values are defined in the header file.  


   ================================= ========
   Instruction and data memory start 0x0
   Instruction and data memory size  0xf000
   Shared mailbox memory start       0xf000
   Shared mailbox memory size        0x1000
   Shared mailbox Command Address    0xfffc
   ================================= ========


The following example explains how Python could initiate a read from a peripheral connected to an IOP. 

1. Python writes a read command (e.g. 0x3) to the mailbox command address (0xfffc).
2. MicroBlaze application checks the command address, and reads and decodes the command.
3. MicroBlaze performs a read from the peripheral and places the data at the mailbox base address (0xf000).
4. MicroBlaze writes 0x0 to the mailbox command address (0xfffc) to confirm transaction is complete.
5. Python checks the command address (0xfffc), and sees that the MicroBlaze has written 0x0, indicating the read is complete, and data is available.
6. Python reads the data in the mailbox base address (0xf000), completing the read.

Running code on different IOPs
=================================


The MicroBlaze local BRAM memory is mapped into the MircoBlaze address space, and also to the ARM address space.  These address spaces are independant, so the local memory will be located at different addresses in each memory space. Some example mappings are shown below to highlight the address translation between MicroBlaze and ARM's memory spaces.  

=================   =========================   ============================
IOP Base Address    MicroBlaze Address Space    ARM Equivalent Address Space
=================   =========================   ============================
0x4000_0000         0x0000_0000 - 0x0000_ffff   0x4000_0000 - 0x4000_ffff
0x4200_0000         0x0000_0000 - 0x0000_ffff   0x4200_0000 - 0x4200_ffff
0x4400_0000         0x0000_0000 - 0x0000_ffff   0x4400_0000 - 0x4400_ffff
=================   =========================   ============================

Note that each MicroBlaze has the same range for its address space. However, the location of each IOPs address space in the ARM memory map is different for each IOP. As the address space is the same for each IOP, any binary compiled for one Pmod IOP will work on another Pmod IOP. 

e.g. if IOP1 exists at 0x4000_0000, and IOP2 (a second instance of an IOP) exists at 0x4200_0000, the same binary can run on IOP1 by writing the binary from python to the 0x4000_0000 address space, and on IOP2 by writing to the 0x4200_0000. 

