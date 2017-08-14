Building Applications
=====================

   
There are a number of steps required before you can start writing your own
software for an IOP (IO Processor). This document will describe the IOP
architecture, and how to set up and build the required software projects to
allow you to write your own application for the MicroBlaze inside an
IOP. Xilinx® SDK projects can be created manually using the SDK GUI, or software
can be built using a Makefile flow.

IO Processors
-------------

As described in the previous section, an IOP can be used as a flexible
controller for different types of external peripherals. The ARM® Cortex®-A9 is
an application processor, which runs Pynq and Jupyter notebook on a Linux
OS. This scenario is not well suited to real-time applications, which is a
common requirement for an embedded systems.  In the base overlay there are three
IOPs. As well as acting as a flexible controller, an IOP can be used as
dedicated real-time controller.

IOPs can also be used standalone to offload some processing from the main
processor. However, note that the MicroBlaze processor inside an IOP in the base
overlay is running at 100 MHz, compared to the Dual-Core ARM Cortex-A9 running
at 650 MHz. The clock speed, and different processor architectures and features
should be taken into account when offloading pure application code. e.g. Vector
processing on the ARM Cortex-A9 Neon processing unit will be much more efficient
than running on the MicroBlaze. The MicroBlaze is most appropriate for
low-level, background, or real-time applications.

     
Software Requirements
---------------------

`Xilinx SDK (Software Development Kit)
<http://www.xilinx.com/products/design-tools/embedded-software/sdk.html>`_
contains the MicroBlaze cross-compiler which can be used to build software for
the MicroBlaze inside an IOP. SDK is available for free as part of the `Xilinx
Vivado WebPack
<https://www.xilinx.com/products/design-tools/vivado/vivado-webpack.html>`_.

The full source code for all supported IOP peripherals is available from the
project GitHub. Pynq ships with precompiled IOP executables to support various
peripherals (see :ref:`pynq-libraries`), so Xilinx software is only
needed if you intend to modify existing code, or build your own IOP
applications/peripheral drivers.

The current Pynq release is built using Vivado and SDK 2016.1. it is recommended
to use the same version to rebuild existing Vivado and SDK projects. If you only
intend to build software, you will only need to install SDK. The full Vivado and
SDK installation is only required to modify or design new overlays. `Download
Xilinx Vivado and SDK 2016.1
<http://www.xilinx.com/support/download/index.html/content/xilinx/en/downloadNav/vivado-design-tools/2016-1.html>`_
You can use the Vivado HLx Web Install Client and select SDK and/or Vivado
during the installation.

Compiling Projects
------------------

Software executables run on the MicroBlaze inside an IOP. Code for the
MicroBlaze can be written in C or C++ and compiled using Xilinx SDK .

You can pull or clone the Pynq GitHub repository, and all the driver source and
project files can be found in ``<GitHub Repository>\boards\<board name>\sdk``,
(Where ``<GitHub Repository>`` is the location of the PYNQ repository).

SDK Application, Board Support Package, Hardware Platform
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

Each SDK application project requires a BSP project (Board Support Package), and
a hardware platform project. The application project will include the user code
(C/C++). The Application project is linked to a BSP. The BSP (Board Support
Package) contains software libraries and drivers to support the underlying
peripherals in the system and is automatically generated in SDK. The BSP is then
linked to a Hardware Platform. A Hardware Platform defines the peripherals in
the IOP subsystem, and the memory map of the system. It is used by the BSP to
build software libraries to support the underlying hardware. The hardware
platform is also automatically generated in SDK.

All *Application* projects and the underlying BSP and hardware platform can be
compiled from the command line using makefiles, or imported into the SDK GUI.

You can also use existing projects as a starting point to create your own
project.

Board Support Package
^^^^^^^^^^^^^^^^^^^^^

A Board Support Package (BSP) includes software libraries for peripherals in the
system. The BSPs for a PYNQ processor subsystem are provided in the directory
corresponding to the processor.

BSP for the Arduino IOP:

    ``<GitHub Repository>/pynq/lib/arduino/bsp_arduino/``
    
BSP for the Pmod IOP:

    ``<GitHub Repository>/pynq/lib/pmod/bsp_pmod``


A BSP is specific to a processor subsystem. There can be many BSPs associated
with an overlay, depending on the types of processors available in the
system. In the case of the base overlay, there are two types of processor
subsystems: Pmod IOP and Arduino IOP which both require a BSP.

An application for the Pmod IOP will be linked to the Pmod IOP BSP. As the two
Pmod IOPs are identical, an application written for one Pmod IOP can run on the
other Pmod IOP. An Arduino application will be linked to the Pmod IOP BSP.

Building the projects
^^^^^^^^^^^^^^^^^^^^^

To build all the software projects associated with a processor, run the
corresponding makefile:

    ``<GitHub Repository>/pynq/lib/arduino/makefile``
    
    ``<GitHub Repository>/pynq/lib/pmod/makefile``

Application projects for peripherals that ship with Pynq (e.g. Pmods and Grove
peripherals) can also be found in the same location. Each project is contained
in a separate folder.
   
The makefile compiles the BSP from its source files. These files have been
created from SDK. The application projects will also be compiled automatically
as part of this process.

The makefile requires SDK to be installed, and can be run from Windows, or
Linux.

To run ``make`` from Windows, open SDK, and choose a temporary workspace (make
sure this path is external to the downloaded GitHub repository). From the
*Xilinx Tools* menu, select *Launch Shell*

.. image:: ../../images/sdk_launch_shell.jpg
   :scale: 75%
   :align: center

In Linux, open a terminal, and source the SDK tools.

From either the Windows Shell, or the Linux terminal, navigate to the sdk folder
in your local copy of the GitHub repository:

   cd to ``<GitHub Repository>/pynq/lib/pmod/`` and run ``make``

.. image:: ../../images/sdk_make.JPG
   :scale: 75%
   :align: center

.. image:: ../../images/sdk_make_result.JPG
   :scale: 75%
   :align: center
   
This will create the Board Support Package (*bsp*), and then link and build all
the application projects.

If you examine the makefile, you can see how the *MBBINS* variable at the top of
the makefile is used to compile the application projects. If you want to add
your own custom project to the build process, you need to add the project name
to the *MBBINS* variable, and save the project in the same location as the other
application projects.

Individual projects can be built by navigating to the ``<project
directory>/Debug`` and running ``make``.

Binary files
^^^^^^^^^^^^

Compiling code produces an executable file (.elf) which needs to be converted to
binary format (.bin) to be downloaded to, and run on, an IOP.

A .bin file can be generated from a .elf by running the following command from
the SDK shell:

    ``mb-objcopy -O binary <inputfile>.elf <outputfile>.bin``

This is done automatically by the makefile for the existing application
projects. The makefile will also copy all .bin files into the ``<GitHub
Repository>/pynq/lib/<processor>/`` folder.

Creating your own Application project
-------------------------------------

Using the makefile flow, you can use an existing project as a starting point for
your own project.

Copy and rename the project, and modify or replace the .c file in the src/ with
your C code. The generated .bin file will have the same base name as your C
file.

e.g. if your C code is my_peripheral.c, the generated .elf and .bin will be
  my_peripheral.elf and my_peripheral.bin.

The following naming convention is recommended for peripheral applications
<pmod|grove|arduino>_<peripheral>

You will need to update references from the old project name to your new project
name in ``<project directory>/Debug/makefile`` and ``<project
directory>/Debug/src/subdir.mk``

If you want your project to build in the main makefile, you should also append
the .bin name of your project to the *MBBINS* variable at the top of the
makefile.

If you are using the SDK GUI, you can import the Hardware Platform, BSP, and any
application projects into your SDK workspace.

.. image:: ../../images/sdk_import_bsp.JPG
   :scale: 75%
   :align: center


The SDK GUI can be used to build and debug your code.  
   
