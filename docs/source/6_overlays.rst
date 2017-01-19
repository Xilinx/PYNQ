**************************
Introduction to Overlays
**************************

.. contents:: Table of Contents
   :depth: 2
   
Overlay Concept
===================

The Xilinx® Zynq® All Programmable device is an SOC based on a dual-core ARM® Cortex®-A9 processor (referred to as the  *Processing System* or **PS**). A Zynq chip also includes FPGA fabric (referred to as  *Programmable Logic* or **PL**). The ARM SoC subsystem also includes a number of dedicated peripherals (memory controllers, USB, Uart, IIC, SPI etc). 

.. image:: ./images/zynq_block_diagram.jpg
   :align: center

The FPGA fabric is reconfigurable, and can be used to implement high performance functions in hardware. However, FPGA design is a specialized task which requires deep hardware engineering knowledge and expertise. 
Overlays, or hardware libraries, are programmable/configurable FPGA designs that extend the user application from the Processing System of the Zynq into the Programmable Logic. Overlays can be used to accelerate a software application, or to customize the hardware platform for a particular application.

For example, image processing is a typical application where the FPGAs can provide acceleration. A software programmer can use a Overlay in a similar way to a software library to run some of the image processing functions (e.g. edge detect, thresholding etc.) on the FPGA fabric. 
Overlays can be loaded to the FPGA dynamically, as required, just like a software library. In this example, separate image processing functions could be implemented in different overlays and loaded from Python on demand.
 
Base Overlay
===================

The base overlay is the default overlay included with the PYNQ-Z1 image, and is automatically loaded when the system boots. 

This overlay includes the follwoing hardware:
* HDMI In
* HDMI Out
* Mic in 
* Audio out
* User LEDs, Switches, Pushbuttons
* 2x PMOD IOP
* Arduino IOP
* Tracebuffer
 

.. image:: ./images/pynqz1_base_overlay.png
   :align: center


HDMI 
----------- 

The PYNQ-Z1 does not contain external HDMI circutry. The Zynq pins are connected directly to the HDMI interfaces.
https://reference.digilentinc.com/reference/programmable-logic/pynq-z1/reference-manual#hdmi

Both HDMI interfaces are connected to DDR memory. Video can be streamed from the HDMI *in* to memory, and from memory to HDMI *out*. This allows processing of Video data from python, or writing an image or Video stream from Python to the HDMI out. 

Note that Jupyter notebooks supports embedded video. However, video captured from the HDMI will be in raw format and would not be suitable for playback in a notebook without appropriate encoding. 

HDMI In
^^^^^^^^^^^^

HDMI in interface needs to be started before it will capture video data. See the example notebooks for examples of using the HDMI. 

HDMI Out
^^^^^^^^^^^^

The HDMI out IP supports the following resolutions:

* 640x480  
* 800x600 
* 1024x768  
* 1280x1024
* 1920x1080


Mic in 
--------------
The mic on the board is connected directly to the Zynq PL pins. i.e. the board does not have an audio codec. The audio data is captured in PDM format.
https://reference.digilentinc.com/reference/programmable-logic/pynq-z1/reference-manual#microphone

Audio out
--------------
The audio out IP is PWM driven mono. 
https://reference.digilentinc.com/reference/programmable-logic/pynq-z1/reference-manual#mono_audio_output

User IO
--------------
The PYNQ-Z1 board includes two tri-color LEDs, 2 switches, 4 push buttons, and 4 individual LEDs. In the base overlay, the user IO is connected directly to the PS, and can be controlled directly from Python. 


IOPs
--------------
IOPs are dedicated IO processor subsystems that allow peripherals with different IO standards to be connected to the system on demand. This allows a software programmer to use a wide range of peripherals with different interfaces and protocols without needing to create a new FPGA design for each peripheral. There are two types of IOP, Pmod, and Arduino. Both IOPs are similar, but have different hardware configurations to support the interefaces they connect to. 

Pmods are covered in more detail in the next section. 

Tracebuffer
--------------

A tracebuffer is available and can be used to capture trace data on the Pmod, and Arduino interfaces for debug. The tracebuffer is connected directly to DDR. This allows trace data on the interfaces to be streamed back to DDR memory for analysis in Python. 



