PYNQ-Z1 Base Overlay
======================

This PYNQ-Z1 overlay includes the following hardware:

* HDMI In
* HDMI Out
* Mic in 
* Audio out
* User LEDs, Switches, Pushbuttons
* 2x PMOD IOP
* Arduino IOP
* Trace buffer
 

.. image:: ../../../images/pynqz1_base_overlay.png
   :align: center


HDMI 
----------- 

The HDMI controllers are connected directly to the HDMI interfaces. There is no external HDMI circuitry on the board. 

`Digilent HDMI reference for the PYNQ-Z1 board <https://reference.digilentinc.com/reference/programmable-logic/pynq-z1/reference-manual#hdmi>`_

Both HDMI interfaces are connected to PS DRAM. Video can be streamed from the HDMI *in* to memory, and from memory to HDMI *out*. This allows processing of video data from python, or writing an image or Video stream from Python to the HDMI out. 

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

While the Pynq-Z1 cannot meet the offical HDMI specification for 1920x1080 (1080p), some HDMI devices at this resolution may work. 

Data can be streamed from DDR memory to the HDMI output. The Pynq HDMI Out python instance contains framebuffers to allow for smooth display of video data. 

See the `PYNQ Z1 base overlay video notebook <./pynq-z1_base_overlay_video.html>`_ which shows examples of using the HDMI in and out. The notebook can also be found on the board in the getting started directory.  


Mic in 
--------------

The PYNQ-Z1 board has an integrated mic on the board and is connected directly to the Zynq PL pins. This means the board does not have an audio codec. The Mic generates audio data in PDM format.

`Digilent MIC in reference for the PYNQ-Z1 board <https://reference.digilentinc.com/reference/programmable-logic/pynq-z1/reference-manual#microphone>`_

Audio out
--------------

The audio out IP is connected to a standard 3.5mm audio jack on the board. The audio output is PWM driven mono. 

`Digilent Audio Out reference for the PYNQ-Z1 board <https://reference.digilentinc.com/reference/programmable-logic/pynq-z1/reference-manual#mono_audio_output>`_

See the `pynq-z1_base_overlay_audio.ipynb <https://github.com/xilinx/PYNQ/blob/master/boards/Pynq-Z1/base/notebooks/audio/pynq-z1_base_overlay_audio.ipynb>`_ notebook in the *getting started* directory for examples of using the audio. 


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

A trace buffer is available and can be used to capture trace data on the Pmod, and Arduino interfaces for debug. The trace buffer is connected to the PS DRAM. This allows trace data on the interfaces to be streamed back to DRAM for analysis in Python. 

Trace data can be displayed as decoded waveforms inside a Jupyter notebook. 

Examples
-------------

For examples on how to use the base overlay, see the `base notebooks <https://github.com/Xilinx/PYNQ/tree/v1.5/boards/Pynq-Z1/base/notebooks/board>`_ section on GitHub or in the corresponding folder in the Jupyter home area on the board. 

