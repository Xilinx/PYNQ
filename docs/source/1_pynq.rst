**************
PYNQ Overview
**************

.. contents:: Table of Contents
   :depth: 2


Project Goals
=============

Xilinx makes Zynq devices, a class of all programmable Systems on Chip (APSoCs) which integrates multiple processors and Field Programmable Gate Arrays (FPGAs) into single integrated circuits.  Programmable logic and microprocessors are complementary technologies for embedded systems.  Each serves distinct requirements of embedded systems that the other cannot perform as well. 

The main goal of **PYNQ**, the **Py**\ thon on Zy\ **nq** project, is to make it easier for designers of embedded  systems to exploit the unique benefits of APSoCs in their applications. Specifically, PYNQ enables the architects, engineers and programmers who design embedded systems to use Zynq APSoCs without having to use ASIC-style, design tools to design programmable logic circuits. 


PYNQ achieves this goal in three main ways:

* Programmable logic circuits are presented as hardware libraries called *overlays*.  These overlays are analogous to software libraries.  A software engineer can select the overlay that best matches his application.  He then proceeds to customize the overlay by programming its application programming interface (API) to perform the functions he requires. To create a new overlay still requires engineers with expertise in designing programmable logic circuits.  The key difference however, is the *build once, re-use many times* paradigm.  Overlays, like software libraries, are designed to be re-used as often as possible.


.. NOTE::
    This is a familiar approach that borrows from best-practice in the software community.  Every day, the Linux kernel is used by   hundreds of thousands of embedded designers.  The kernel, itself however, is developed and maintained by fewer than one thousand, high-skilled, software architects and engineers.  The extensive re-use of the work of a relatively small number of very talented engineers enables many thousands of their colleagues to be more productive and to work at higher levels of abstraction.  Hardware libraries or *overlays* are inspired by the success of the Linux kernel model in abstracting so many of the details of low-level, hardware-dependent software.


* PYNQ uses Python for programming both the embedded processors and the overlays.  Python is a "productivity-level" language.  To date, C or C++ are the most common, embedded, programming languages.  In contrast, Python raises the level of programming abstraction and programmer productivity. These are not mutually-exclusive choices, however.  PYNQ uses CPython which is written in C, integrates thousands of C libraries, and can be extended with code written in C.  So wherever practical, we use the more productive Python environment and, whenever efficiency dictates, we fall back on lower-level C code.

  
* PYNQ is an open-source project that aims to work on any computing platform and operating system.  This goal is achieved by adopting a web-based architecture, which is also browser agnostic.  We incorporate the open-source Jupyter notebook infrastructure to run an Interactive Python (IPython) kernel and a web server directly on the ARM CPUs.  The web server brokers access to the kernel via a suite of browser-based tools that provide a dashboard, bash terminal, code editors and Jupyter notebooks.  The browser tools are implemented with a combination of JavaScript, HTML and CSS and run on any modern browser.

Summary
=======

PYNQ is the first project to combine the following elements to simplify and improve APSoC design:

#. a high-level productivity language (Python in this case)
#. FPGA overlays with extensive APIs exposed as Python libraries 
#. a web-based architecture served from the embedded processors
#. and the Jupyter Notebook framework deployed in an embedded context 
