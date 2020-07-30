Audio
=====

The Audio module provides methods to read audio from the input microphone, play
audio to the output speaker, or read and write audio files. The audio module
connects to the audio IP subsystem in in overlay to capture and playback data.
The audio module is intended to support different IP subsystems. It currently
supports the line-in, HP/Mic with the ADAU1761 codec on the PYNQ-Z2 and the 
Pulse Width Modulation (PWM) mono output and Pulse Density Modulated (PDM)
microphone input on the PYNQ-Z1 board. 


Examples
--------


Both the :ref:`pynqz1-base-overlay` and the :ref:`pynqz2-base-overlay` contain
a single Audio instance: *audio*.  After the overlay is loaded this instance
can be accessed as follows:

PYNQ-Z1 
^^^^^^^

.. code-block:: Python

   from pynq.overlays.base import BaseOverlay
   base = BaseOverlay("base.bit")
   pAudio = base.audio

   pAudio.load("/home/xilinx/pynq/lib/tests/pynq_welcome.pdm")
   pAudio.play()

PYNQ-Z2
^^^^^^^

.. code-block:: Python

   from pynq.overlays.base import BaseOverlay
   base = BaseOverlay("base.bit")
   pAudio = base.audio
   pAudio.set_volume(20)
   pAudio.load("/home/xilinx/jupyter_notebooks/base/audio/data/recording_0.wav")

   pAudio.play()

(Note the PYNQ-Z1 supports direct playback of PDM out, and the PYNQ-Z2 supports Wav.)

More information about the Audio module and the API for reading and writing
audio interfaces, or loading and saving audio files can be found in the
:ref:`pynq-lib-audio` section.

For more examples see the Audio notebook on your PYNQ-Z1 or PYNQ-Z2 board:
at:

.. code-block:: console

   <Jupyter Home>/base/audio/audio_playback.ipynb
