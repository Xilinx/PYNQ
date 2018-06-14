#   Copyright (c) 2018, Xilinx, Inc.
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

__author__ = "Peter Ogden"
__copyright__ = "Copyright 2018, Xilinx"
__email__ = "pynq_support@xilinx.com"

import cffi
import os
from pynq import DefaultIP

LIB_SEARCH_PATH = os.path.dirname(os.path.realpath(__file__))

_lib_header = R"""
unsigned XIic_Recv(unsigned long BaseAddress, unsigned char Address,
                   unsigned char *BufferPtr, unsigned ByteCount, unsigned char Option);

unsigned XIic_Send(unsigned long BaseAddress, unsigned char Address,
                   unsigned char *BufferPtr, unsigned ByteCount, unsigned char Option);

unsigned int XIic_CheckIsBusBusy(unsigned long BaseAddress);

unsigned int XIic_WaitBusFree(unsigned long BaseAddress);
"""

_lib_location = os.path.join(LIB_SEARCH_PATH, 'libiic.so')


class AxiIIC(DefaultIP):
    """Driver for the AXI IIC controller

    """
    _lib = None
    _ffi = None

    REPEAT_START = 1

    @staticmethod
    def _initialise_lib():
        AxiIIC._ffi = cffi.FFI()
        AxiIIC._ffi.cdef(_lib_header)
        AxiIIC._lib = AxiIIC._ffi.dlopen(_lib_location)

    def __init__(self, description):
        """Create a new instance of the driver

        Parameters
        ----------
        description : dict
            Entry in the ip_dict for the IP

        """
        if AxiIIC._lib is None:
            AxiIIC._initialise_lib()

        super().__init__(description)
        self._virtaddr = self.mmio.array.ctypes.data

    def send(self, address, data, length, option=0):
        """Send data to an attached IIC slave

        Parameters
        ----------
        address : int
            Address of the slave device
        data : bytes-like
            Data to send
        length : int
            Length of data
        option : int
            Optionally `REPEAT_START` to keep hold of the bus
            between transactions

        """
        sent = AxiIIC._lib.XIic_Send(
            self._virtaddr, address, data, length, option)
        if sent == 0:
            raise RuntimeError("Could not send I2C data")
        return sent

    def receive(self, address, data, length, option=0):
        """Receive data from an attached IIC slave

        Parameters
        ----------
        address : int
            Address of the slave device
        data : bytes-like
            Data to receive
        length : int
            Number of bytes to receive
        option : int
            Optionally `REPEAT_START` to keep hold of the bus
            between transactions

        """
        received = AxiIIC._lib.XIic_Recv(
            self._virtaddr, address, data, length, option)
        if received == 0:
            raise RuntimeError("Could not receive I2C data")
        return received

    def wait(self):
        """Wait for the transaction to complete

        """
        timed_out = AxiIIC._lib.XIic_WaitBusFree(self._virtaddr)
        if timed_out:
            raise RuntimeError("Timed out waiting for free bus")

    bindto = ['xilinx.com:ip:axi_iic:2.0']
