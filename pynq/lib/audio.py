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

__author__      = "Benedikt Janssen"
__copyright__   = "Copyright 2016, Xilinx"
__email__       = "pynq_support@xilinx.com"

import os
import math
import numpy
import cffi
import wave
import time
from pynq import PL
from pynq import GPIO
from pynq import MMIO

LIB_SEARCH_PATH = os.path.dirname(os.path.realpath(__file__))

class Audio:
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
    def __init__(self, ip='SEG_d_axi_pdm_1_S_AXI_reg',
                 rst="audio_path_sel"):
        """Return a new Audio object.
        
        The PL is queried to get the base address and length.
        
        Parameters
        ----------
        ip : str
            The name of the IP required for the audio driver.
        rst : str
            The name of the GPIO pins used as reset for the audio driver.
        
        """
        if ip not in PL.ip_dict:
            raise LookupError("No such audio IP in the overlay.")
        if rst not in PL.gpio_dict:
            raise LookupError("No such reset pin in the overlay.")

        self.mmio = MMIO(PL.ip_dict[ip][0], PL.ip_dict[ip][1])
        self.gpio = GPIO(GPIO.get_gpio_pin(PL.gpio_dict[rst][0]), 'out')
        
        self._ffi = cffi.FFI()
        self._libaudio = self._ffi.dlopen(LIB_SEARCH_PATH + "/libaudio.so")
        self._ffi.cdef("""unsigned int Xil_Out32(unsigned int Addr, 
                                                 unsigned int Value);""")
        self._ffi.cdef("""unsigned int Xil_In32(unsigned int Addr);""")
        self._ffi.cdef("""void _Pynq_record(unsigned int BaseAddr, 
                                            unsigned int * BufAddr, 
                                            unsigned int Num_Samles_32Bit);""")
        self._ffi.cdef("""void _Pynq_play(unsigned int BaseAddr, 
                                          unsigned int * BufAddr, 
                                          unsigned int Num_Samles_32Bit);""")
        
        char_adrp  = self._ffi.from_buffer(self.mmio.mem)
        self._uint_adrpv  = self._ffi.cast('unsigned int', char_adrp)
        
        self.buffer = numpy.zeros(0).astype(numpy.int)
        self.sample_rate = 0
        self.sample_len = 0
        
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
        char_datp  = self._ffi.from_buffer(self.buffer)
        uint_datp  = self._ffi.cast('unsigned int*', char_datp)
        
        # Record
        start = time.time()
        self._libaudio._Pynq_record(self._uint_adrpv, uint_datp,
                                    num_samples_32b)
        end = time.time()
        self.sample_rate = num_samples_32b / (end - start)
        self.sample_len = num_samples_32b
        
    def play(self):
        """Play audio buffer via audio jack.
        
        Returns
        -------
        None
        
        """
        char_datp  = self._ffi.from_buffer(self.buffer)
        uint_datp  = self._ffi.cast('unsigned int*', char_datp)
        
        char_adrp  = self._ffi.from_buffer(self.mmio.mem)
        uint_adrp  = self._ffi.cast('unsigned int', char_adrp)
        
        self._libaudio._Pynq_play(self._uint_adrpv, uint_datp, 
                                       len(self.buffer))
        
    def bypass_start(self):
        """Stream audio controller input directly to output.
        
        Returns
        -------
        None
        
        """
        self.gpio.write(1)
        del gpio_pin
        
    def bypass_stop(self):
        """Stop streaming input to output directly.
        
        Returns
        -------
        None
        
        """
        self.gpio.write(0)
        del gpio_pin
        
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
        if not isinstance(file, str) :
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
        if not isinstance(file, str) :
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
        """Prints information about pdm files.
        
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
        if not isinstance(file, str) :
            raise ValueError("File name has to be a string.")
            
        if os.path.isdir(os.path.dirname(file)):
            file_abs = file
        else:
            file_abs = os.getcwd() + '/' + file
            
        with wave.open(file_abs, 'rb') as pdm_file:
            print("File name:          " + file)
            print("Number of channels: " + str(pdm_file.getnchannels()))
            print("Sample width:       " + str(pdm_file.getsampwidth()))
            print("Sample rate:        " + str(pdm_file.getframerate()))
            print("Number of frames:   " + str(pdm_file.getnframes()))
            print("Compression type:   " + str(pdm_file.getcomptype()))
            print("Compression name:   " + str(pdm_file.getcompname()))
            