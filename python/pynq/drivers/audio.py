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
from pynq import PL
from pynq import GPIO
from pynq import MMIO
import numpy as np
import cffi
import wave
import time

class Audio:
    """Class to interact with audio controller.
    Each audio sample is a 32bit width integer.
    The audio controller supports only mono mode, 
    and uses pulse density modulation (PDM).
    
    Attributes
    ----------
    sample_rate: int
        Sample rate of the current buffer content.
    sample_len: int
        Sample length of the current buffer content.
    """

    def __init__(self, base_addr=None, length=None):
        """Return a new Audio object.

        Parameters
        ----------
        base_addr : int
            The base address of the audio controller
            (default: 0x43C0000).
        length : int
            Length of audio controller address space 
            (default: 0x10000).

        """
        # Create MMIO object
        if base_addr == None:
            base_addr = int(PL.ip_dict["SEG_d_axi_pdm_1_S_AXI_reg"][0],16)
        if length == None:
            length = int(PL.ip_dict["SEG_d_axi_pdm_1_S_AXI_reg"][1],16)
        
        # Create MMIO object
        self._AudioMMIO = MMIO(base_addr, length)

        # Import C functions
        self._ffi = cffi.FFI()
        #   Load lib
        LIB_SEARCH_PATH = os.path.dirname(os.path.realpath(__file__))
        self._libaudio = self._ffi.dlopen(LIB_SEARCH_PATH + "/libaudio.so")
        #   Define functions
        self._ffi.cdef("""unsigned int Xil_Out32(unsigned int Addr, 
                                                 unsigned int Value);""")
        self._ffi.cdef("""unsigned int Xil_In32(unsigned int Addr);""")
        self._ffi.cdef("""void _Pynq_record(unsigned int BaseAddr, 
                                            unsigned int * BufAddr, 
                                            unsigned int Num_Samles_32Bit);""")
        self._ffi.cdef("""void _Pynq_play(unsigned int BaseAddr, 
                                          unsigned int * BufAddr, 
                                          unsigned int Num_Samles_32Bit);""")
        
        # Create C reference to audio controller mem space
        char_adrp  = self._ffi.from_buffer(self._AudioMMIO.mem)
        self._uint_adrpv  = self._ffi.cast('unsigned int', char_adrp)

        # Create buffer and attributes
        self.buffer = np.zeros(0).astype(np.int)
        self.sample_rate = 0
        self.sample_len = 0
        self.MMIO_Base_Addr = self._AudioMMIO.base_addr
        self.MMIO_Length = self._AudioMMIO.length

    def record(self, seconds):
        """Record data from audio controller to audio buffer.

        Parameters
        ----------
        seconds : float
            The number of seconds to be recorded.

        Returns
        -------
        None.
        """
        # Check arguments
        if seconds <= 0:
            raise ValueError(""" Number of seconds to be recorded needs to be 
                                 greater than zero.""" )
        elif seconds > 60:
            raise ValueError(""" Maximum number of seconds to be recorded is 
                                 currently set to 60s.""" )
        # Get number of samples
        #   the sample rate per word is 192000 Hz
        Num_Samles_32Bit = math.ceil(seconds * 192000)

        # Create data buffer
        self.buffer = np.zeros(Num_Samles_32Bit, dtype=np.int)
        char_datp  = self._ffi.from_buffer(self.buffer)
        uint_datp  = self._ffi.cast('unsigned int*', char_datp)
        
        # Record
        start = time.time()
        self._libaudio._Pynq_record(self._uint_adrpv, uint_datp,
                                          Num_Samles_32Bit)
        end = time.time()
        self.sample_rate = Num_Samles_32Bit / (end - start)
        self.sample_len = Num_Samles_32Bit

    def play(self):
        """Play audio buffer via audio jack.

        Parameters
        ----------
        None.

        Returns
        -------
        None
        """
        # Get data buffer reference
        char_datp  = self._ffi.from_buffer(self.buffer)
        uint_datp  = self._ffi.cast('unsigned int*', char_datp)

        # Create C reference to audio controller mem space
        char_adrp  = self._ffi.from_buffer(self._AudioMMIO.mem)
        uint_adrp  = self._ffi.cast('unsigned int', char_adrp)

        # Play
        self._libaudio._Pynq_play(self._uint_adrpv, uint_datp, 
                                       len(self.buffer))

    def bypass_start(self):
        """Stream audio controller input directly to output.

        Parameters
        ----------
        None

        Returns
        -------
        None
        """
        # Select direct connection from input to output
        #   Pin for audio path selection: 57
        GpioIndex = GPIO.get_gpio_base() + 57
        GpioPin = GPIO(GpioIndex, 'out')
        GpioPin.write(1)
        del GpioPin

    def bypass_stop(self):
        """Stop streaming input to output directly.

        Parameters
        ----------
        None

        Returns
        -------
        None
        """
        # Deselect direct connection from input to output
        #   Pin for audio path selection: 57
        GpioIndex = GPIO.get_gpio_base() + 57
        GpioPin = GPIO(GpioIndex, 'out')
        GpioPin.write(0)
        del GpioPin

    def save_file(self, file):
        """Save audio buffer content to <file> in WAV fomat

        Parameters
        ----------
        file : string
            File name

        Returns
        -------
        None
        """
        # Check arguments
        if (self.buffer.dtype.type != np.int32) :
            raise ValueError("Internal audio buffer should be of type int32.")
        if not isinstance(file, str) :
            raise ValueError("Filename string is missing.")

        # Write .wav file
        wavfile=wave.open(file,'wb')
        #  Set the number of channels.
        wavfile.setnchannels(1)            
        #  Set the sample width to 2 bytes (16 bit).      
        wavfile.setsampwidth(2)                
        #  Set the frame rate to sample_rate.  
        wavfile.setframerate(self.sample_rate)   
        #  Set the number of frames to sample_len. 
        wavfile.setnframes(self.sample_len)
        #  Set the compression type and description.
        wavfile.setcomptype('NONE', "not compressed") 
        #  Write data.
        wavfile.writeframes(self.buffer.astype(np.int16))
        wavfile.close()

    def load_file(self, file):
        """Loads file into internal audio buffer.

        Parameters
        ----------
        file : string
            File name

        Returns
        -------
        None
        """
        # Check arguments
        if not isinstance(file, str) :
            raise ValueError("Filename string is missing.")

        # Read .wav file
        wavfile=wave.open(file,'rb')
        temp_buffer = np.fromstring(wavfile.readframes(
                                    wavfile.getnframes()), dtype='<u2')
        self.sample_rate = wavfile.getframerate()
        self.sample_len = wavfile.getnframes()
        self.buffer = temp_buffer.astype(np.int32)
        wavfile.close()

    def print_file_info(self, file):
        """Prints information about .wav files.

        Parameters
        ----------
        file : string
            File name

        Returns
        -------
        None
        """
        # Check arguments
        if not isinstance(file, str) :
            raise ValueError("Filename string is missing.")

        # Read .wav file
        wavfile=wave.open(file,'rb')
        print("File name:          " + file)
        print("Number of channels: " + str(wavfile.getnchannels()))
        print("Sample width:       " + str(wavfile.getsampwidth()))
        print("Sample rate:        " + str(wavfile.getframerate()))
        print("Number of frames:   " + str(wavfile.getnframes()))
        print("Compression type:   " + str(wavfile.getcomptype()))
        print("Compression name:   " + str(wavfile.getcompname()))
        wavfile.close()