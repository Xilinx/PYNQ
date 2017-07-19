.. Python productivity for Zynq® (PYNQ) documentation master file, created by
   sphinx-quickstart on Mon Mar 28 22:10:04 2016.
   You can adapt this file completely to your liking, but it should at least
   contain the root `toctree` directive.

*****************
PYNQ Introduction
*****************

Xilinx® makes Zynq® devices, a class of All Programmable Systems on Chip (APSoC)
which integrates a multi-core processor (Dual-core ARM® Cortex®-A9) and a Field
Programmable Gate Array (FPGA) into a single integrated circuit.  FPGA, or
programmable logic, and microprocessors are complementary technologies for
embedded systems.  Each meets distinct requirements for embedded systems that
the other cannot perform as well.

Project Goals
=============

The main goal of **PYNQ**, **Py**\ thon Productivity for Zy\ **nq**, is to make
it easier for designers of embedded systems to exploit the unique benefits of
APSoCs in their applications. Specifically, PYNQ enables architects, engineers
and programmers who design embedded systems to use Zynq APSoCs, without having
to use ASIC-style design tools to design programmable logic circuits.

PYNQ achieves this goal in three ways:

* Programmable logic circuits are presented as hardware libraries called
  *overlays*.  These overlays are analogous to software libraries.  A software
  engineer can select the overlay that best matches their application.  The
  overlay can be accessed through an application programming interface
  (API). Creating a new overlay still requires engineers with expertise in
  designing programmable logic circuits.  The key difference however, is the
  *build once, re-use many times* paradigm.  Overlays, like software libraries,
  are designed to be configurable and re-used as often as possible in many
  different applications.


.. NOTE:: This is a familiar approach that borrows from best-practice in the
    software community.  Every day, the Linux kernel is used by hundreds of
    thousands of embedded designers.  The kernel is developed and maintained by
    fewer than one thousand, high-skilled, software architects and engineers.
    The extensive re-use of the work of a relatively small number of very
    talented engineers enables many more software engineers to work at higher
    levels of abstraction. Hardware libraries or *overlays* are inspired by the
    success of the Linux kernel model in abstracting so many of the details of
    low-level, hardware-dependent software.


* PYNQ uses Python for programming both the embedded processors and the
  overlays.  Python is a "productivity-level" language.  To date, C or C++ are
  the most common, embedded programming languages.  In contrast, Python raises
  the level of programming abstraction and programmer productivity. These are
  not mutually-exclusive choices, however.  PYNQ uses CPython which is written
  in C, and integrates thousands of C libraries and can be extended with
  optimized code written in C.  Wherever practical, the more productive Python
  environment should be used, and whenever efficiency dictates, lower-level C
  code can be used.

  
* PYNQ is an open-source project that aims to work on any computing platform and
  operating system.  This goal is achieved by adopting a web-based architecture,
  which is also browser agnostic.  We incorporate the open-source Jupyter
  notebook infrastructure to run an Interactive Python (IPython) kernel and a
  web server directly on the ARM Cortex A9 of the Zynq device.  The web server
  brokers access to the kernel via a suite of browser-based tools that provide a
  dashboard, bash terminal, code editors and Jupyter notebooks.  The browser
  tools are implemented with a combination of JavaScript, HTML and CSS and run
  on any modern browser.

Summary
=======

PYNQ is the first project to combine the following elements to simplify and
improve APSoC design:

#. A high-level productivity language (Python in this case)
#. FPGA overlays with extensive APIs exposed as Python libraries 
#. A web-based architecture served from the embedded processors, and
#. The Jupyter Notebook framework deployed in an embedded context 


.. toctree::
   :maxdepth: 2
   :hidden:
   
   getting_started
   jupyter_notebooks
   python_environment
   pynq_overlays
   pynq_libraries
   overlay_design_methodology
   pynq_sd_card
   pynq_package
   verification
   faqs
   glossary
   references
   appendix
   changelog

