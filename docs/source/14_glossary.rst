********
Glossary
********

.. contents:: Table of Contents
   :depth: 2


.. glossary::


A-G
===

  APSOC
   All Programmable System on Chip

  ADC
   Analog to Digital Converter

  BSP 
   SDK Board Support Package - This is an SDK project that contains a collection of software libraries that can be used by an Application project
   
  DAC
   Digital to Analog Converter

  DPOT
   Digital Potentiometer

  FPGA
   Field Programmable Gate Array `https://en.wikipedia.org/wiki/Field-programmable_gate_array <https://en.wikipedia.org/wiki/Field-programmable_gate_array>`_

  FTDI
   Future Technology Devices International Ltd, supplier of the FT2232HQ USB-UART bridge chip used on Zybo.  Free USB-COM port
   drivers, available from www.ftdichip.com under the "Virtual Com Port" or VCP heading, convert USB packets to
   UART/serial port data. Serial port data is exchanged with the Zynq using a two-wire serial port (TXD/RXD). After the
   drivers are installed, I/O commands can be used from the PC directed to the COM port to produce serial data
   traffic on the Zynq pins.

H-R
===

  Hardware Platform
   An SDK project
   
  HDF
   Hardware Definition File (.hdf). This file is created by Vivado and contains information about a processor system in an FPGA overlay. The HDF specifies the peripherals that exist in the system, and the memory map. This is used by the BSP to build software librariesto support the availabel peripherals.

  I2C
    See IIC

  IIC
   Inter-Integrated Circuit; multi-master, multi-slave, single-ended, serial computer bus protocol

  IOPs
   Input/Output Processors

  Jupyter (Jupyter Notebooks) (www.jupyter.org)
   Jupyter is an open source, interactive, web application that allows the user to create and share notebook documents that contain live code and the full range of rich media supported by modern browser. These include include text, images, videos, LaTeX, and interactive widgets. It is used as a front-end to over 40 different programming languages.  It originated from the interactive data science and scientific computing communities.

  MicroBlaze
   The MicroBlaze is a soft microprocessor core designed for Xilinx FPGAs from Xilinx. As a soft-core processor, MicroBlaze is implemented entirely in the general-purpose memory and logic fabric of an FPGA.
   `https://en.wikipedia.org/wiki/MicroBlaze <https://en.wikipedia.org/wiki/MicroBlaze>`
   
  Pmod
   Peripheral Module - accessory boards to add functionality to the platform. e.g. ADC, DAC, I/O interfaces, sensors etc.

  Pmod I/O
   Pmod I/O overlay

  (Micro) SD
   Secure Digital (Memory Card standard)

  readthedocs.org
   A popular website which hosts the documentation for open source projects at no cost.  It can automatically generate both the website and PDF versions of project documentation from a GitHub repository when new updates are pushed to that site. 

  REPL
   A read–eval–print loop (REPL), also known as an interactive toplevel or language shell, is a simple, interactive computer     programming environment that takes single user inputs (i.e. single expressions), evaluates them, and returns the result to the user; a program written in a REPL environment is executed piecewise. The term is most usually used to refer to programming interfaces similar to the classic Lisp machine interactive environment. Common examples include command line shells and similar environments for programming languages, and is particularly characteristic of scripting languages `wikipedia <https://en.wikipedia.org/wiki/Read%E2%80%93eval%E2%80%93print_loop>`_

   reST
    Restructured text is a markup language used extensively with the Sphinx document generator

S-Z
===
  SDK
   Xilinx SDK - Software Development Kit. Software development environment including cross-compiles for ARM, and MicroBlaze processors. Also includes debug, and profiling tools. 
   Required to build software for a MicroBlaze processor inside an IOP. 
   
  SOC
   System On Chip

  Sphinx
   A document generator written in Python and used extensively to documemt Python and other coding projects

  SPI
   Serial Peripheral Interface; synchronous serial communication interface specification 

  UART
   Universal asynchronous receiver/transmitter; Serial communication protocol

  Vivado
   Xilinx software for creating FPGA overlays. 
   
  XADC
   Xilinx ADC - Analog to Digital Converter found on all Xilinx 7 series devices

  Zybo
   ZYnq BOard

  Zynq
   Xilinx device with ARM processor and FPGA fabric on the same chip

  Zynq PL
   Programmable Logic - FPGA fabric

  Zynq PS
   Processing System - SOC processing subsystem built around dual-core, ARM Cortex-A9 processor
