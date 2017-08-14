Audio
=====
The audio subsystem in the PYNQ-Z1 base overlay consists of an IP block to drive
the PWM mono output, and another block to read the PDM input from the MIC.

Block Diagram
-------------

.. image:: ../images/audio_subsystem.png
   :align: center
   
Examples
--------
The PYNQ Audio module includes the following methods:

* ``bypass_start()`` - Stream audio controller input directly to output.
* ``bypass_stop()`` - Stop streaming input to output directly.
* ``load(file)`` - Loads file into internal audio buffer.
* ``play()`` - Play audio buffer via audio jack.
* ``record(seconds)`` - Record data from audio controller to audio buffer.
* ``save(file)`` - Save audio buffer content to a file.

See the `PYNQ audio notebook on GitHub <https://github.com/Xilinx/PYNQ/blob/v1.5/boards/Pynq-Z1/base/notebooks/audio/audio_playback.ipynb>`_ or in the following directory on the board:

   .. code-block:: console

      <Jupyter Home>\base\audio\audio_playback.ipynb

