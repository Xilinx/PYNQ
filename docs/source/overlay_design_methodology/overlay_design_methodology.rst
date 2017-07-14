*****************************
Overlay design methodology
*****************************

.. contents:: Table of Contents
   :depth: 2
   
Introduction 
=============

As described in the PYNQ introduction, overlays are analogous to software libraries. A programmer can download overlays into the Zynq® PL at runtime to provide functionality required by the software application. 

An *overlay* is a class of Programmable Logic design. Programmable Logic designs are usually highly optimized for a specific task. Overlays however, are designed to be configurable, and reusable for broad set of applications. A PYNQ overlay will have a Python interface, allowing a software programmer to use it like any other Python package. 

A software programmer can use an overlay, but will not usually create overlay, as this usually requires a high degree of hardware design expertise. 

There are a number of components required in the process of creating an overlay:

* Overlay design (Programmable Logic) 
* Movement of data between PS/PL
* C library/driver
* IOP application
* Python API
* Packaging the overlay

This section will give an overview of the process of creating an overlay and integrating it into PYNQ, but will not cover the hardware design process in detail. Hardware design will be familiar to Zynq, and FPGA hardware developers. 
