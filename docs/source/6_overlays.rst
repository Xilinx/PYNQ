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

On the Pynq-Z1 board, the DDR memory controller, Ethernet, USB, SD, UART are connected on the board. 
   
The FPGA fabric is reconfigurable, and can be used to implement high performance functions in hardware. However, FPGA design is a specialized task which requires deep hardware engineering knowledge and expertise. 
Overlays, or hardware libraries, are programmable/configurable FPGA designs that extend the user application from the Processing System of the Zynq into the Programmable Logic. Overlays can be used to accelerate a software application, or to customize the hardware platform for a particular application.

For example, image processing is a typical application where the FPGAs can provide acceleration. A software programmer can use an overlay in a similar way to a software library to run some of the image processing functions (e.g. edge detect, thresholding etc.) on the FPGA fabric. 
Overlays can be loaded to the FPGA dynamically, as required, just like a software library. In this example, separate image processing functions could be implemented in different overlays and loaded from Python on demand.
 
Base Overlay
===================

The base overlay is the default overlay included with the PYNQ-Z1 image, and is automatically loaded into the Programmable Logic when the system boots. 

This overlay includes the following hardware:

* HDMI In
* HDMI Out
* Mic in 
* Audio out
* User LEDs, Switches, Pushbuttons
* 2x PMOD IOP
* Arduino IOP
* Trace buffer
 

.. image:: ./images/pynqz1_base_overlay.png
   :align: center


HDMI 
----------- 

The HDMI controllers are connected directly to the HDMI interfaces. There is no external HDMI circuitry. 

`Digilent HDMI reference for the PYNQ-Z1 board <https://reference.digilentinc.com/reference/programmable-logic/pynq-z1/reference-manual#hdmi>`_

Both HDMI interfaces are connected to DDR memory. Video can be streamed from the HDMI *in* to memory, and from memory to HDMI *out*. This allows processing of video data from python, or writing an image or Video stream from Python to the HDMI out. 

Note that Jupyter notebooks supports embedded video. However, video captured from the HDMI will be in raw format and would not be suitable for playback in a notebook without appropriate encoding. 

HDMI In
^^^^^^^^^^^^

The HDMI in interface can capture standard HDMI resolutions. After a HDMI source has been connected, and the HDMI controller started, it will automatically detect the incoming data. The resolution can be read from the HDMI Python class, and the image data can be streamed to DDR memory. 

HDMI Out
^^^^^^^^^^^^

The HDMI out IP supports the following resolutions:

* 640x480  
* 800x600 
* 1024x768  
* 1280x1024
* 1920x1080

Data can be stream from DDR memory to the HDMI output. The Pynq HDMI Out python instance contains framebuffers to allow for smooth display of video data. 

See the `5_base_overlay_video.ipynb <https://github.com/cathalmccabe/PYNQ/blob/master/docs/source/9b_base_overlay_video.ipynb>`_ notebook in the getting started directory for examples of using the HDMI In and Out. 


Mic in 
--------------

The PYNQ-Z1 board has an integrated mic on the board and is connected directly to the Zynq PL pins. This means the board does not have an audio codec. The Mic generates audio data in PDM format.

`Digilent MIC in reference for the PYNQ-Z1 board <https://reference.digilentinc.com/reference/programmable-logic/pynq-z1/reference-manual#microphone>`_

Audio out
--------------

The audio out IP is connected to a standard 3.5mm audio jack on the board. The audio output is PWM driven mono. 

`Digilent Audio Out reference for the PYNQ-Z1 board <https://reference.digilentinc.com/reference/programmable-logic/pynq-z1/reference-manual#mono_audio_output>`_

User IO
--------------
The PYNQ-Z1 board includes two tri-color LEDs, 2 switches, 4 push buttons, and 4 individual LEDs. In the base overlay, the user IO is connected directly to the PS, and can be controlled directly from Python. 


IOPs
--------------
IOPs are dedicated IO processor subsystems that allow peripherals with different IO standards to be connected to the system on demand. This allows a software programmer to use a wide range of peripherals with different interfaces and protocols. The same overlay can be used to support different peripheral. 

There are two types of IOPs: Pmod, and Arduino. Both types of IOPs have a similar architecture, but have different configurations of IP to connect to supported peripherals. 

Pmods are covered in more detail in the next section. 

Trace buffer
--------------

A trace buffer is available and can be used to capture trace data on the Pmod, and Arduino interfaces for debug. The trace buffer is connected directly to DDR. This allows trace data on the interfaces to be streamed back to DDR memory for analysis in Python. 

Trace data can be displayed as decoded waveforms inside a Jupyter notebook. 

Examples
^^^^^^^^^^^^

See the `trace buffer_i2c.ipynb <https://github.com/Xilinx/PYNQ/blob/master/Pynq-Z1/notebooks/examples>`_ and the `trace buffer_spi.ipynb <https://github.com/Xilinx/PYNQ/blob/master/Pynq-Z1/notebooks/examples>`_ in the examples directory for examples on how to use the trace buffer. 

