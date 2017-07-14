
Pynq-Z1 audio Subsystem
============================

The Pynq-Z1 has a 3.5mm mono audio jack for audio-out, and an omnidirectional MEMS microphone integrated on the board for audio-in. 

The audio out needs to be driven by a PWM signal, and the digitized audio from the mic is in the pulse density modulated (PDM) format.

For more information on the audio subsystem see the relevant sections in the `PYNQ-Z1 reference guide <https://reference.digilentinc.com/reference/programmable-logic/pynq-z1/reference-manual>`_ 

The audio subsystem in the PYNQ-Z1 base overlay consists of an IP block to drive the PWM mono output, and another block to read the PDM input from the MIC.  
   
.. image:: ../../images/audio_subsystem.png
   :align: center
   
The PYNQ Audio module includes the following methods:

* ``bypass_start()`` - Stream audio controller input directly to output.
* ``bypass_stop()`` - Stop streaming input to output directly.
* ``load(file)`` - Loads file into internal audio buffer.
* ``play()`` - Play audio buffer via audio jack.
* ``record(seconds)`` - Record data from audio controller to audio buffer.
* ``save(file)`` - Save audio buffer content to a file.

For more information on the PYNQ audio class, run ``help()`` on the audio instance in the overlay.

   .. code-block:: Python
      
      from pynq import Overlay
      base = Overlay("base.bit")
      audio = base.audio
      help(audio)
   
   .. code-block:: console
   
      Help on Audio in module pynq.lib.audio object:

      class Audio(pynq.overlay.DefaultHierarchy)
      |  Class to interact with audio controller.
      |  
      |  Each audio sample is a 32-bit integer. The audio controller supports only 
      |  mono mode, and uses pulse density modulation (PDM).
      |  
      |  Attributes
      |  ----------
      |  mmio : MMIO
      |      The MMIO object associated with the audio controller.
      |  gpio : GPIO
      |      The GPIO object associated with the audio controller.
      |  buffer : numpy.ndarray
      |      The numpy array to store the audio.
      |  sample_rate: int
      |      Sample rate of the current buffer content.
      |  sample_len: int
      |      Sample length of the current buffer content.
 

See the `PYNQ audio notebook on GitHub <https://github.com/Xilinx/PYNQ/blob/v1.5/boards/Pynq-Z1/base/notebooks/audio/audio_playback.ipynb>`_ or in the following directory on the board:

   .. code-block:: console

      base\audio\audio_playback.ipynb

