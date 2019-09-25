#   Copyright (c) 2016, Xilinx, Inc.
#   All rights reserved.
# 
#   Redistribution and use in source and binary forms, with or without 
#   modification, are permitted provided that the following conditions are met:
#
#   1.  Redistributions of source code must retain the above copyright notice, 
#       this list of conditions and the following disclaimer.
#
#   2.  Redistributions in binary form must reproduce the above copyright 
#       notice, this list of conditions and the following disclaimer in the 
#       documentation and/or other materials provided with the distribution.
#
#   3.  Neither the name of the copyright holder nor the names of its 
#       contributors may be used to endorse or promote products derived from 
#       this software without specific prior written permission.
#
#   THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
#   AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, 
#   THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR 
#   PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR 
#   CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, 
#   EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, 
#   PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS;
#   OR BUSINESS INTERRUPTION). HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, 
#   WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR 
#   OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF 
#   ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


import os
import struct
import math
import numpy
import cffi
import wave
import time
from pynq import PL
from pynq import GPIO
from pynq.uio import get_uio_index
from pynq import DefaultIP


__author__ = "Benedikt Janssen, Yun Rock Qu"
__copyright__ = "Copyright 2016, Xilinx"
__email__ = "pynq_support@xilinx.com"
LIB_SEARCH_PATH = os.path.dirname(os.path.realpath(__file__))


class AudioDirect(DefaultIP):
    """Class to interact with audio controller.
    
    Each audio sample is a 32-bit integer. The audio controller supports only 
    mono mode, and uses pulse density modulation (PDM).
    
    Attributes
    ----------
    mmio : MMIO
        The MMIO object associated with the audio controller.
    gpio : GPIO
        The GPIO object associated with the audio controller.
    buffer : numpy.ndarray
        The numpy array to store the audio.
    sample_rate: int
        Sample rate of the current buffer content.
    sample_len: int
        Sample length of the current buffer content.
        
    """
    def __init__(self, description, gpio_name=None):
        """Return a new Audio object based on the hierarchy description.
        
        Parameters
        ----------
        description : dict
            The hierarchical description of the hierarchy
        gpio_name : str
            The name of the audio path selection GPIO. If None then the GPIO
            pin in the hierarchy is used, otherwise the gpio_name is searched
            in the list of pins on the hierarchy and the PL.gpio_dict.

        """
        super().__init__(description)

        if gpio_name is None:
            if len(self._gpio) == 0:
                raise RuntimeError('Could not find audio path select GPIO.')
            elif len(self._gpio) > 1:
                raise RuntimeError('Multiple possible audio path select GPIO.')
            pin_name = next(iter(self._gpio.keys()))
            self.gpio = getattr(self, pin_name)
        else:
            if gpio_name in self._gpio:
                self.gpio = getattr(self, gpio_name)
            elif gpio_name in PL.gpio_dict:
                pin = GPIO.get_gpio_pin(PL.gpio_dict[gpio_name]['index'])
                self.gpio = GPIO(pin, 'out')
            else:
                raise RuntimeError('Provided gpio_name not found.')

        self._ffi = cffi.FFI()
        self._libaudio = self._ffi.dlopen(LIB_SEARCH_PATH + "/libaudio.so")
        self._ffi.cdef("""unsigned int Xil_Out32(unsigned int Addr, 
                                                 unsigned int Value);""")
        self._ffi.cdef("""unsigned int Xil_In32(unsigned int Addr);""")
        self._ffi.cdef("""void record(unsigned int BaseAddr, 
                                      unsigned int * BufAddr, 
                                      unsigned int Num_Samles_32Bit);""")
        self._ffi.cdef("""void play(unsigned int BaseAddr, 
                                    unsigned int * BufAddr, 
                                    unsigned int Num_Samles_32Bit);""")
        
        char_adrp = self._ffi.from_buffer(self.mmio.array)
        self._uint_adrpv = self._ffi.cast('unsigned int', char_adrp)
        
        self.buffer = numpy.zeros(0).astype(numpy.int)
        self.sample_rate = 0
        self.sample_len = 0

    bindto = ['xilinx.com:user:audio_direct:1.1']

    def record(self, seconds):
        """Record data from audio controller to audio buffer.
        
        The sample rate per word is 192000Hz.
        
        Parameters
        ----------
        seconds : float
            The number of seconds to be recorded.
            
        Returns
        -------
        None
        
        """
        if not 0 < seconds <= 60:
            raise ValueError("Recording time has to be in (0,60].")
            
        num_samples_32b = math.ceil(seconds * 192000)
        
        # Create data buffer
        self.buffer = numpy.zeros(num_samples_32b, dtype=numpy.int)
        char_datp = self._ffi.from_buffer(self.buffer)
        uint_datp = self._ffi.cast('unsigned int*', char_datp)
        
        # Record
        start = time.time()
        self._libaudio.record(self._uint_adrpv, uint_datp, num_samples_32b)
        end = time.time()
        self.sample_rate = num_samples_32b / (end - start)
        self.sample_len = num_samples_32b
        
    def play(self):
        """Play audio buffer via audio jack.
        
        Returns
        -------
        None
        
        """
        char_datp = self._ffi.from_buffer(self.buffer)
        uint_datp = self._ffi.cast('unsigned int*', char_datp)
        
        self._libaudio.play(self._uint_adrpv, uint_datp, len(self.buffer))
        
    def bypass_start(self):
        """Stream audio controller input directly to output.
        
        Returns
        -------
        None
        
        """
        self.gpio.write(1)

    def bypass_stop(self):
        """Stop streaming input to output directly.
        
        Returns
        -------
        None
        
        """
        self.gpio.write(0)

    def save(self, file):
        """Save audio buffer content to a file.
        
        The recorded file is of format `*.pdm`.
        
        Note
        ----
        The saved file will be put into the specified path, or in the 
        working directory in case the path does not exist.
        
        Parameters
        ----------
        file : string
            File name, with a default extension of `pdm`.
            
        Returns
        -------
        None
        
        """
        if self.buffer.dtype.type != numpy.int32:
            raise ValueError("Internal audio buffer should be of type int32.")
        if not isinstance(file, str):
            raise ValueError("File name has to be a string.")
        
        if os.path.isdir(os.path.dirname(file)):
            file_abs = file
        else:
            file_abs = os.getcwd() + '/' + file
            
        with wave.open(file_abs, 'wb') as pdm_file:
            # Set the number of channels
            pdm_file.setnchannels(1)
            # Set the sample width to 2 bytes (16 bit)
            pdm_file.setsampwidth(2)
            # Set the frame rate to sample_rate
            pdm_file.setframerate(self.sample_rate)
            # Set the number of frames to sample_len
            pdm_file.setnframes(self.sample_len)
            # Set the compression type and description
            pdm_file.setcomptype('NONE', "not compressed")
            # Write data
            pdm_file.writeframes(self.buffer.astype(numpy.int16))
            
    def load(self, file):
        """Loads file into internal audio buffer.
        
        The recorded file is of format `*.pdm`.
        
        Note
        ----
        The file will be searched in the specified path, or in the 
        working directory in case the path does not exist.
        
        Parameters
        ----------
        file : string
            File name, with a default extension of `pdm`.
            
        Returns
        -------
        None
        
        """
        if not isinstance(file, str):
            raise ValueError("File name has to be a string.")
            
        if os.path.isdir(os.path.dirname(file)):
            file_abs = file
        else:
            file_abs = os.getcwd() + '/' + file
            
        with wave.open(file_abs, 'rb') as pdm_file:
            temp_buffer = numpy.fromstring(pdm_file.readframes(
                                        pdm_file.getnframes()), dtype='<u2')
            self.sample_rate = pdm_file.getframerate()
            self.sample_len = pdm_file.getnframes()
            self.buffer = temp_buffer.astype(numpy.int32)

    @staticmethod
    def info(file):
        """Prints information about the sound files.

        The information includes name, channels, samples, frames, etc.

        Note
        ----
        The file will be searched in the specified path, or in the
        working directory in case the path does not exist.

        Parameters
        ----------
        file : string
            File name, with a default extension of `pdm`.

        Returns
        -------
        None

        """
        if not isinstance(file, str):
            raise ValueError("File name has to be a string.")

        if os.path.isdir(os.path.dirname(file)):
            file_abs = file
        else:
            file_abs = os.getcwd() + '/' + file

        with wave.open(file_abs, 'rb') as sound_file:
            print("File name:          " + file)
            print("Number of channels: " + str(sound_file.getnchannels()))
            print("Sample width:       " + str(sound_file.getsampwidth()))
            print("Sample rate:        " + str(sound_file.getframerate()))
            print("Number of frames:   " + str(sound_file.getnframes()))
            print("Compression type:   " + str(sound_file.getcomptype()))
            print("Compression name:   " + str(sound_file.getcompname()))


class AudioADAU1761(DefaultIP):
    """Class to interact with audio codec controller.

    Each raw audio sample is a 24 bits, padded to 32 bits.
    The audio controller supports both mono and stereo modes, and I2S format
    of data.

    Attributes
    ----------
    buffer : numpy.ndarray
        The numpy array to store the audio.
    sample_rate: int
        Sample rate of the codec.
    sample_len: int
        Sample length of the current buffer content.
    iic_index : int
        The index of the IIC instance in /dev.
    uio_index : int
        The index of the UIO instance in /dev.

    """
    def __init__(self, description):
        """Return a new Audio object based on the hierarchy description.

        Parameters
        ----------
        description : dict
            The hierarchical description of the hierarchy

        """
        super().__init__(description)

        self._ffi = cffi.FFI()
        self._libaudio = self._ffi.dlopen(LIB_SEARCH_PATH + "/libaudio.so")
        self._ffi.cdef("""void config_audio_pll(int iic_index);""")
        self._ffi.cdef("""void config_audio_codec(int iic_index);""")
        self._ffi.cdef("""void select_line_in(int iic_index);""")
        self._ffi.cdef("""void select_mic(int iic_index);""")
        self._ffi.cdef("""void deselect(int iic_index);""")
        self._ffi.cdef("""void bypass(unsigned int audio_mmap_size,
                          unsigned int nsamples, 
                          int uio_index, int iic_index) ;""")
        self._ffi.cdef("""void record(unsigned int audio_mmap_size,
                          unsigned int * BufAddr, unsigned int nsamples,
                          int uio_index, int iic_index);""")
        self._ffi.cdef("""void play(unsigned int audio_mmap_size,
                          unsigned int * BufAddr, unsigned int nsamples,
                          int uio_index, int iic_index);""")

        self.buffer = numpy.zeros(0).astype(numpy.int32)
        self.sample_rate = None
        self.sample_len = len(self.buffer)
        self.iic_index = None
        self.uio_index = None
        self.configure()

    bindto = ['xilinx.com:user:audio_codec_ctrl:1.0']

    def configure(self, sample_rate=48000,
                  iic_index=1, uio_name="audio-codec-ctrl"):
        """Configure the audio codec.

        The sample rate of the codec is 48KHz, by default.
        This method will configure the PLL and codec registers.

        The parameter `iic_index` is required as input; `uio_index` is
        calculated automatically from `uio_name`.

        Users can also explicitly call this function to reconfigure the driver.

        Parameters
        ----------
        sample_rate: int
            Sample rate of the codec.
        iic_index : int
            The index of the IIC instance in /dev.
        uio_name : int
            The name of the UIO configured in the device tree.

        """
        self.sample_rate = sample_rate
        self.iic_index = iic_index
        self.uio_index = get_uio_index(uio_name)
        if self.uio_index is None:
            raise ValueError("Cannot find UIO device {}".format(uio_name))

        self._libaudio.config_audio_pll(self.iic_index)
        self._libaudio.config_audio_codec(self.iic_index)

    def select_line_in(self):
        """Select LINE_IN on the board.

        This method will select the LINE_IN as the input.

        """
        self._libaudio.select_line_in(self.iic_index)

    def select_microphone(self):
        """Select MIC on the board.

        This method will select the MIC as the input.

        """
        self._libaudio.select_mic(self.iic_index)

    def deselect_inputs(self):
        """Deselect the inputs.

        This method will disable both LINE_IN and MIC inputs.

        """
        self._libaudio.deselect(self.iic_index)

    def record(self, seconds):
        """Record data from audio controller to audio buffer.

        The sample rate for both channels is 48000Hz. Note that the
        `sample_len` will only be changed when the buffer is modified.
        Since both channels are sampled, the buffer size has to be twice
        the sample length.

        Parameters
        ----------
        seconds : float
            The number of seconds to be recorded.

        Returns
        -------
        None

        """
        if not 0 < seconds <= 60:
            raise ValueError("Recording time has to be in (0,60].")

        self.sample_len = math.ceil(seconds * self.sample_rate)
        num_samples_32b = self.sample_len * 2

        # Create data buffer
        self.buffer = numpy.zeros(num_samples_32b, dtype=numpy.int32)
        char_buffer = self._ffi.from_buffer(self.buffer)
        uint_buffer = self._ffi.cast('unsigned int*', char_buffer)

        # Record
        self._libaudio.record(self.mmio.length, uint_buffer,
                              self.sample_len, self.uio_index, self.iic_index)

    def play(self):
        """Play audio buffer via audio jack.

        Since both channels are sampled, the buffer size has to be twice
        the sample length.

        Returns
        -------
        None

        """
        char_buffer = self._ffi.from_buffer(self.buffer)
        uint_buffer = self._ffi.cast('unsigned int*', char_buffer)

        self._libaudio.play(self.mmio.length, uint_buffer,
                            self.sample_len, self.uio_index, self.iic_index)

    def bypass(self, seconds):
        """Stream audio controller input directly to output.

        It will run for a certain number of seconds, then stop automatically.

        Parameters
        ----------
        seconds : float
            The number of seconds to be recorded.

        Returns
        -------
        None

        """
        if not 0 < seconds <= 60:
            raise ValueError("Bypassing time has to be in (0,60].")

        self.sample_len = math.ceil(seconds * self.sample_rate)
        self._libaudio.bypass(self.mmio.length,
                              self.sample_len, self.uio_index, self.iic_index)

    def save(self, file):
        """Save audio buffer content to a file.

        The recorded file is of format `*.wav`. Note that only 24 bits out
        of each 32-bit sample are the real samples; the highest 8 bits are
        padding, which should be removed when writing the wave file.

        Note
        ----
        The saved file will be put into the specified path, or in the
        working directory in case the path does not exist.

        Parameters
        ----------
        file : string
            File name, with a default extension of `wav`.

        Returns
        -------
        None

        """
        if self.buffer.dtype.type != numpy.int32:
            raise ValueError("Internal audio buffer should be of type int32.")
        if not isinstance(file, str):
            raise ValueError("File name has to be a string.")

        if os.path.isdir(os.path.dirname(file)):
            file_abs = file
        else:
            file_abs = os.getcwd() + '/' + file

        samples_4byte = self.buffer.tobytes()
        byte_format = ('%ds %dx ' % (3, 1)) * self.sample_len * 2
        samples_3byte = b''.join(struct.unpack(byte_format, samples_4byte))
        with wave.open(file_abs, 'wb') as wav_file:
            # Set the number of channels
            wav_file.setnchannels(2)
            # Set the sample width to 3 bytes
            wav_file.setsampwidth(3)
            # Set the frame rate to sample_rate
            wav_file.setframerate(self.sample_rate)
            # Set the number of frames to sample_len
            wav_file.setnframes(self.sample_len)
            # Set the compression type and description
            wav_file.setcomptype('NONE', "not compressed")
            # Write data
            wav_file.writeframes(samples_3byte)

    def load(self, file):
        """Loads file into internal audio buffer.

        The recorded file is of format `*.wav`. Note that we expect 32-bit
        samples in the buffer while the each saved sample is only 24 bits.
        Hence we need to pad the highest 8 bits when reading the wave file.

        Note
        ----
        The file will be searched in the specified path, or in the
        working directory in case the path does not exist.

        Parameters
        ----------
        file : string
            File name, with a default extension of `wav`.

        Returns
        -------
        None

        """
        if not isinstance(file, str):
            raise ValueError("File name has to be a string.")

        if os.path.isdir(os.path.dirname(file)):
            file_abs = file
        else:
            file_abs = os.getcwd() + '/' + file

        with wave.open(file_abs, 'rb') as wav_file:
            samples_3byte = wav_file.readframes(wav_file.getnframes())
            self.sample_rate = wav_file.getframerate()
            self.sample_len = wav_file.getnframes()
        byte_format = ('%ds' % 3) * self.sample_len * 2
        samples_4byte = b'\x00'.join(struct.unpack(byte_format, samples_3byte))
        samples_4byte += b'\x00'
        self.buffer = numpy.fromstring(samples_4byte, dtype='<u4')

    @staticmethod
    def info(file):
        """Prints information about the sound files.

        The information includes name, channels, samples, frames, etc.

        Note
        ----
        The file will be searched in the specified path, or in the
        working directory in case the path does not exist.

        Parameters
        ----------
        file : string
            File name, with a default extension of `wav`.

        Returns
        -------
        None

        """
        if not isinstance(file, str):
            raise ValueError("File name has to be a string.")

        if os.path.isdir(os.path.dirname(file)):
            file_abs = file
        else:
            file_abs = os.getcwd() + '/' + file

        with wave.open(file_abs, 'rb') as sound_file:
            print("File name:          " + file)
            print("Number of channels: " + str(sound_file.getnchannels()))
            print("Sample width:       " + str(sound_file.getsampwidth()))
            print("Sample rate:        " + str(sound_file.getframerate()))
            print("Number of frames:   " + str(sound_file.getnframes()))
            print("Compression type:   " + str(sound_file.getcomptype()))
            print("Compression name:   " + str(sound_file.getcompname()))
