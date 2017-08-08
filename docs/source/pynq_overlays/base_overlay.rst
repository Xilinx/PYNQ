Base Overlay
============

The purpose of the base overlay design is to allow PYNQ to use peripherals on a board out-of-the-box. The design includes hardware IP to control peripherals on the target board, and connects these IP blocks to the Zynq PS. 
If a base overlay is available for a board, peripherals can be used from the Python
environment immediately after the system boots.

Board peripherals typically include GPIO devices (LEDs, Switches, Buttons),
Video, Audio, and other custom interfaces. 

As the base overlay includes IP for the peripehrals on a board, it can also be used as a reference design for creating new customized overlays. 

In the case of general purpose interfaces, for example Pmod or Arduino headers, the base overlay may include a PYNQ IOP (Input/Output Porcessor). An IOP allows control of devices with different interfaces and protocols on the same port without requiring a change to the programmable logic design. See the PYNQ Libraries section for more information on IOPs. 

PYNQ-Z1 Base Overlay Block Diagram
------------------------------------

.. image:: ../images/pynqz1_base_overlay.png
   :align: center


This PYNQ-Z1 overlay includes the following hardware:

    * HDMI (Input and Output)
    * Mic in 
    * Audio out
    * User LEDs, Switches, Pushbuttons
    * 2x PMOD IOP
    * Arduino IOP

HDMI 
-----

The PYNQ-Z1 has HDMI in and HDMI out ports. The HDMI interfaces are connected directly to PL pins. i.e. There is no external HDMI circuitry on the board. The HDMI interfaces are controlled by HDMI IP in the programmable logic. 

The HDMI IP is connected to PS DRAM. Video can be streamed from the
HDMI *in* to memory, and from memory to HDMI *out*. This allows processing of
video data from python, or writing an image or Video stream from Python to the
HDMI out.

Note that while Jupyter notebook supports embedded video, video captured
from the HDMI will be in raw format and would not be suitable for playback in a
notebook without appropriate encoding.

For information on the physical HDMI interface ports, see th e`Digilent HDMI reference for the PYNQ-Z1 board
<https://reference.digilentinc.com/reference/programmable-logic/pynq-z1/reference-manual#hdmi>`_

HDMI In
^^^^^^^

The HDMI in IP can capture standard HDMI resolutions. After a HDMI source
has been connected, and the HDMI controller for the IP is started, it will automatically
detect the incoming data. The resolution can be read from the HDMI Python class,
and the image data can be streamed to the PS DRAM.

HDMI Out
^^^^^^^^

The HDMI out IP supports the following resolutions:

    * 640x480  
    * 800x600 
    * 1280x720 (720p)
    * 1280x1024
    * 1920x1080 (1080p)\*

\*While the Pynq-Z1 cannot meet the offical HDMI specification for 1080p, some HDMI devices at this resolution may work.

Data can be streamed from the PS DRAM to the HDMI output. The HDMI Out
controller contains framebuffers to allow for smooth display of video data.

See the *PYNQ Z1 base overlay video notebook* which can be found in the getting started
directory on the board.


Mic in 
-------

The PYNQ-Z1 board has an integrated mic on the board and is connected directly
to the Zynq PL pins, and does not have an external audio codec. The Mic
generates audio data in PDM format.

For more information see the `Digilent MIC in reference for the PYNQ-Z1 board
<https://reference.digilentinc.com/reference/programmable-logic/pynq-z1/reference-manual#microphone>`_

Audio out
---------

The audio out IP is connected to a standard 3.5mm audio jack on the board. The
audio output is PWM driven mono.


See the *pynq-z1_base_overlay_audio.ipynb* notebook in the *getting started* directory for examples of using the audio.

For more information see the `Digilent Audio Out reference for the PYNQ-Z1 board <https://reference.digilentinc.com/reference/programmable-logic/pynq-z1/reference-manual#mono_audio_output>`_

User IO
-------

The PYNQ-Z1 board includes two tri-color LEDs, 2 switches, 4 push buttons, and 4
individual LEDs. These IO are connected directly to Zynq PL pins. In the PYNQ-Z1 base overlay, these IO are routed to the
PS GPIO, and can be controlled directly from Python.


IOPs
----

IOPs (Input/Output Processors) are dedicated MicroBlaze soft-processor subsystems that allow peripherals with different
IO standards to be connected to the system on demand. This allows a software
programmer to use a wide range of peripherals with different interfaces and
protocols. By using an IOP, the same overlay can be used to support different peripheral without requiring a different overlay for each peripheral. 

There are two types of IOPs: Pmod, and Arduino.  The Pmod and Arduino ports, which the IOPs connect to, have a different number of pins and can support different sets of peripherals. Both types of IOP have a similar architecture, but have different IP configurations to support the different sets of peripehral and interface pins. 

IOPs are covered in more detail in the next section. 

Python API
----------

The Python API for the peripherals in the base overlay is covered in the next section on PYNQ Libraries. Example notebooks are also provided on the board which show how to use the base overlay. 


Rebuilding the Overlay
----------------------

The project files for the overlays can be found here:

.. code-block:: console

   <GitHub Repository>/boards/<board>/base

Linux
^^^^^^^^

To rebuild an overlay source the Xilixn tools and run *make* in the overlay directory. 

Windows
^^^^^^^^^

Open Vivado, change to the overlay directory, and source the .tcl file. The .tcl can also be sourced from the Vivado Tcl shell. Note that you must change to the overlay directory, as the .tcl file has relative paths that will break if it is sourced from a different location.  
