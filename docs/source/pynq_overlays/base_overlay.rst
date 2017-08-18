.. _base-overlay:

Base Overlay
============

The purpose of the base overlay design is to allow PYNQ to use peripherals on a
board out-of-the-box. The design includes hardware IP to control peripherals on
the target board, and connects these IP blocks to the Zynq PS. If a base
overlay is available for a board, peripherals can be used from the Python
environment immediately after the system boots.

Board peripherals typically include GPIO devices (LEDs, Switches, Buttons),
Video, Audio, and other custom interfaces. 

As the base overlay includes IP for the peripherals on a board, it can also be
used as a reference design for creating new customized overlays.

In the case of general purpose interfaces, for example Pmod or Arduino headers,
the base overlay may include a PYNQ MicroBlaze. A PYNQ MicroBlaze allows
control of devices with different interfaces and protocols on the same port
without requiring a change to the programmable logic design. 

See :ref:`pynq-libraries` for more information on PYNQ MicroBlazes.

PYNQ-Z1 Block Diagram
---------------------

.. image:: ../images/pynqz1_base_overlay.png
   :align: center


The base overlay on PYNQ-Z1 includes the following hardware:

    * HDMI (Input and Output)
    * Microphone in 
    * Audio out
    * User LEDs, Switches, Pushbuttons
    * 2x Pmod PYNQ MicroBlaze
    * Arduino PYNQ MicroBlaze
    * 3x Trace Analyzer (PMODA, PMODB, ARDUINO)

HDMI 
----

The PYNQ-Z1 has HDMI in and HDMI out ports. The HDMI interfaces are connected
directly to PL pins. i.e. There is no external HDMI circuitry on the board. The
HDMI interfaces are controlled by HDMI IP in the programmable logic.

The HDMI IP is connected to PS DRAM. Video can be streamed from the
HDMI *in* to memory, and from memory to HDMI *out*. This allows processing of
video data from python, or writing an image or Video stream from Python to the
HDMI out.

Note that while Jupyter notebook supports embedded video, video captured from
the HDMI will be in raw format and would not be suitable for playback in a
notebook without appropriate encoding.

For information on the physical HDMI interface ports, see the
`Digilent HDMI reference for the PYNQ-Z1 board
<https://reference.digilentinc.com/reference/programmable-logic/pynq-z1/reference-manual#hdmi>`_

HDMI In
^^^^^^^

The HDMI in IP can capture standard HDMI resolutions. After a HDMI source has
been connected, and the HDMI controller for the IP is started, it will
automatically detect the incoming data. The resolution can be read from the HDMI
Python class, and the image data can be streamed to the PS DRAM.

HDMI Out
^^^^^^^^

The HDMI out IP supports the following resolutions:

    * 640x480  
    * 800x600 
    * 1280x720 (720p)
    * 1280x1024
    * 1920x1080 (1080p)\*

\*While the Pynq-Z1 cannot meet the official HDMI specification for 1080p, some
HDMI devices at this resolution may work.

Data can be streamed from the PS DRAM to the HDMI output. The HDMI Out
controller contains framebuffers to allow for smooth display of video data.

See example video notebooks in the ``<Jupyter Dashboard>/base/video`` directory 
on the board.

Microphone In 
-------------

The PYNQ-Z1 board has an integrated microphone on the board and is connected 
directly to the Zynq PL pins, and does not have an external audio codec. The 
microphone generates audio data in PDM format.

For more information on the audio hardware, see the `Digilent MIC in reference 
for the PYNQ-Z1 board
<https://reference.digilentinc.com/reference/programmable-logic/pynq-z1/reference-manual#microphone>`_

See example audio notebooks in the ``<Jupyter Dashboard>/base/audio`` directory 
on the board.

Audio Out
---------

The audio out IP is connected to a standard 3.5mm audio jack on the board. The
audio output is PWM driven mono.

For more information on the audio hardware, see the `Digilent Audio Out 
reference for the PYNQ-Z1 board <https://reference.digilentinc.com/reference/programmable-logic/pynq-z1/reference-manual#mono_audio_output>`_

See example audio notebooks in the ``<Jupyter Dashboard>/base/audio`` directory 
on the board.

User IO
-------

The PYNQ-Z1 board includes two tri-color LEDs, 2 switches, 4 push buttons, and 4
individual LEDs. These IO are connected directly to Zynq PL pins. In the PYNQ-Z1
base overlay, these IO are routed to the PS GPIO, and can be controlled directly
from Python.

PYNQ MicroBlaze
---------------

PYNQ MicroBlazes are dedicated MicroBlaze soft-processor
subsystems that allow peripherals with different IO standards to be connected to
the system on demand. This allows a software programmer to use a wide range of
peripherals with different interfaces and protocols. By using a PYNQ MicroBlaze, 
the same overlay can be used to support different peripheral without requiring a
different overlay for each peripheral.

There are two types of PYNQ MicroBlazes: Pmod, and Arduino.  The Pmod and 
Arduino ports, which the PYNQ MicroBlazes connect to, have a different number 
of pins and can support different sets of peripherals. Both types of PYNQ 
MicroBlaze have a similar architecture, but have different IP configurations 
to support the different sets of peripheral and interface pins.

PYNQ MicroBlaze block diagram and examples can be found in 
:ref:`pynq-microblaze-subsystem`. 

Trace Analyzer
----------------

Trace analyzer blocks are connected to the interface pins for the two Pmod 
PYNQ MicroBlazes, and the Arduino PYNQ MicroBlaze. The trace analyzer can 
capture IO signals and stream the data to the PS DRAM for analysis in the 
Python environment.

Using the Python Wavedrom package, the signals from the trace analyzer can be 
displayed as waveforms in a Jupyter notebook. 

On the base overlay, the trace analyzers are controlled by PS directly. In 
fact, on other overlays, the trace analyzers can also be controlled by PYNQ 
MicroBlaze.

See the example notebook in the ``<Jupyter Dashboard>/base/trace`` 
directory on the board.

Python API
----------

The Python API for the peripherals in the base overlay is covered in 
:ref:`pynq-libraries`. Example notebooks are also provided on the board to 
show how to use the base overlay.

Rebuilding the Overlay
----------------------

The project files for the overlays can be found here:

.. code-block:: console

   <PYNQ repository>/boards/<board>/base

Linux
^^^^^
A Makefile is provided to rebuild the base overlay in Linux. The Makefile calls 
two tcl files. The first Tcl files compiles any HLS IP used in the design. The 
second Tcl builds the overlay. 

To rebuild the overlay, source the Xilinx tools first. Then assuming PYNQ has 
been cloned: 

.. code-block:: console

   cd <PYNQ repository>/boards/Pynq-Z1/base
   make 

Windows
^^^^^^^
In Windows, the two Tcl files can be sourced in Vivado to rebuild the overlay. 
The Tcl files to rebuild the overlay can be sourced from the Vivado GUI, or 
from the Vivado Tcl Shell (command line). 

To rebuild from the Vivado GUI, open Vivado. In the Vivado Tcl command line 
window change to the correct directory, and source the Tcl files as indicated 
below. 

Assuming PYNQ has been cloned:
 
.. code-block:: console

   cd <PYNQ repository>/boards/Pynq-Z1/base
   source ./build_base_ip.tcl
   source ./base.tcl

To build from the command line, open the Vivado 2016.1 Tcl Shell, and run the 
following:

.. code-block:: console

   cd <PYNQ repository>/boards/Pynq-Z1/base
   vivado -mode batch -source build_base_ip.tcl
   vivado -mode batch -source base.tcl
   
Note that you must change to the overlay directory, as the tcl files has 
relative paths that will break if sourced from a different location.
