#   Copyright (c) 2018, Xilinx, Inc.
#   SPDX-License-Identifier: BSD-3-Clause


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

    bindto = ['xilinx.com:ip:axi_iic:2.1']


