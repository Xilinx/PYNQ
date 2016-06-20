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

__author__      = "Anurag Dubey"
__copyright__   = "Copyright 2016, Xilinx"
__email__       = "xpp_support@xilinx.com"


import os
import cffi


ffi = cffi.FFI()

ffi.cdef("""
typedef struct axi_dma_simple_info_struct {
        int device_id;
        int phys_base_addr;
        int addr_range;
        int virt_base_addr;
        int dir; // either DMA_TO_DEV or DMA_FROM_DEV 
} axi_dma_simple_info_t;
""")

ffi.cdef("""
typedef struct axi_dma_simple_channel_info_struct {
                axi_dma_simple_info_t *dma_info;
                int in_use;
                int needs_cache_flush_invalidate;
} axi_dma_simple_channel_info_t;
""")

ffi.cdef("""
void reg_and_open(
        axi_dma_simple_channel_info_t * dmainfo
        );
""")

ffi.cdef("""
void unreg_and_close(
        axi_dma_simple_channel_info_t * dmainfo
        );
""")

ffi.cdef("""
void  _dma_send(
        axi_dma_simple_channel_info_t * dmainfo, 
        void * data,int len, int handle_id
        );
""")

ffi.cdef("""
void _dma_recv(
        axi_dma_simple_channel_info_t * dmainfo, 
        void * data,int len, int handle_id
        );
""")

ffi.cdef("""
void *sds_alloc( size_t size);
""")

ffi.cdef("""
void sds_free(void *memptr);
""")

ffi.cdef("""
void _dma_wait(int handle_id);
""")

LIB_SEARCH_PATH = os.path.dirname(os.path.realpath(__file__))
dmalib = ffi.dlopen(LIB_SEARCH_PATH + "/libdma.so")

DMA_TO_DEV = 0
DMA_FROM_DEV = 1
device_id = 0
_address_table = {}

class DMA():

    def __new__(cls,address,direction = DMA_TO_DEV):
        """ Return a DMA object.

        This function is called before __init__ and is responsible for
        actually creating the object. If the object is already present in
        the address table, a reference to the old object is returned.
        IMPORTANT: DO NOT TOUCH THIS FUNCTION

        """
        if address in _address_table.keys():
            return _address_table[address]
        new_obj =  super(DMA, cls).__new__(cls)
        return new_obj

    def __init__(self,address,direction = DMA_TO_DEV):
        """Returns a new DMA Object.

        Initialization process also checks for address conflics
        and registers and opens the DMA port.
        Only single instance of a particular DMA address should be present
        to avoid conflicts

        Parameters
        ----------
        address : integer
            Physical address of the DMA
        direction : integer
            DMA can either send or receive data based on direction.
            Possible values of direction are:
            0 : DMA sends data to PL
            1 : DMA receives data from PL

        """
        if address in _address_table.keys():
            return
        self._get_channel(address,direction)
        self._register()
        self.readbuf = ffi.new_handle("void")
        self._readalloc = False
        self.writebuf = ffi.new_handle("void")
        self._writealloc = False
        _address_table[address] = self

    def __del__(self):
        """Destructor for DMA Object.

        Unregisters and closes the DMA port

        Parameters
        ----------
        None

        """
        self._unregister()

    def _get_channel(self,address,direction):
        """Setups the DMA channel during initialization.

        Should not be called by user as the program might crash.
        This internal function returns dmalib compatible C structs
        which are passed to dmalib functions.

        """
        self.info = ffi.new("axi_dma_simple_info_t *")
        global device_id
        global _address_table
        self.info.device_id = device_id
        device_id = device_id + 1
        self.info.phys_base_addr = address
        self.info.addr_range = 0x10000
        self.info.dir = direction
        self.channel = ffi.new("axi_dma_simple_channel_info_t *")
        self.channel.dma_info = self.info
        self.channel.in_use = 0
        self.channel.needs_cache_flush_invalidate = 0

    def _register(self):
        """Registers the DMA channel during initialization.

        Should not be called by user as the program might crash.

        """
        dmalib.reg_and_open(self.channel)

    def _unregister(self):
        """Unregisters the DMA channel during destroy.

        Should not be called by user as the program might crash.

        """
        dmalib.unreg_and_close(self.channel)

    def _send(self,buf,length):
        """Basic DMA send method (Non- Blocking).

        This method takes a buffer in physically contiguous memory locations
        and sends it via DMA into the PL. The buffer can be allocated using
        "_alloc" method. If you don't want to do it manually, then use
        "write" method instead. This is a non blocking function as it.
        returns immediately.

        Parameters
        ----------
        buf : cffi.FFI.CData
            The buffer allocated using sds_alloc function.
        length : integer
            Length of the buffer.

        Returns
        -------
        None

        """
        dmalib._dma_send(self.channel,buf,length,self.info.device_id)

    def _recv(self,buf,length):
        """Basic DMA receive method (Non- Blocking).

        This method takes a buffer in physically contiguous memory locations
        and fills it with data received from PL. The buffer can be allocated using
        "_alloc" method. If you don't want to do it manually, then use
        "read" method instead. This is a non blocking function as it.
        returns immediately.

        Parameters
        ----------
        buf : cffi.FFI.CData
            The buffer allocated using sds_alloc function.
        length : integer
            Length of the buffer.

        Returns
        -------
        None

        """
        self.info.dir = DMA_FROM_DEV
        dmalib._dma_recv(self.channel,buf,length,self.info.device_id)

    def wait(self):
        """Wait on DMA transfer to complete.

        Call this function if you want to block till the DMA transfer
        is complete.

        Parameters
        ----------
        None

        Returns
        -------
        None

        """
        dmalib._dma_wait(self.info.device_id)

    def _alloc(self,length):
        """Allocate physically contiguous memory locations in memory.

        This method generates the buffers needed for DMA transfers.

        Parameters
        ----------
        length : integer
            length of the allocate array in bytes.

        Returns
        -------
        cffi.FFI.CData
            This contains a pointer to the buffer which can be accessed in python
            like a C array.

        """
        return dmalib.sds_alloc(length)

    def _free(self,pointer):
        """Free previously allocated buffer memory.

        Use this to free a previously allocated buffer memory. There is a 
        limit on size of physically contiguous memory which can be allocated 
        and thus, it is important to free up any unrequired memory.

        Parameters
        ----------
        pointer : cffi.FFI.CData
            The buffer which was allocated using _alloc.

        Returns
        -------
        None

        """
        dmalib.sds_free(pointer)

    def get_read_buf(self):
        """Return a previously read buffer

        Use this to get the read buffer if you called a non-blocking
        read and then later called a "wait".

        Parameters
        ----------
        None

        Returns
        -------
        cffi.FFI.CData
            An CFFI object which can be accessed similar to arrays in Python.
            The data is cast as integer and the raw hex/binary can be accessed
            like the following example:

            >> print(output[0] & 0xffffffff)
            3735928559

            >> print(hex(output[0] & 0xffffffff))
            0xdeadbeef

            >> print(bin(output[0] & 0xffffffff))
            0b11011110101011011011111011101111

        """
        return ffi.cast("int *",self.readbuf)

    def read(self,length,wait = True):
        """ Read 'length' 4 byte elements from the PL

        This method is intended for anyone who doesn't want to deal
        with memory allocations. They can simply pass length of an array
        that they want to receive from PL. Each array element is 4 bytes 
        in size.

        Parameters
        ----------
        length : integer
            length of the array to be read. Each element is 4 bytes in size.
        wait : bool (=True)
            if wait is True then the DMA call is blocking. It 
            can be made non-blocking by setting wait to False.

        Returns
        -------
        cffi.FFI.CData : if Blocking read else None

            An CFFI object which can be accessed similar to arrays in Python.
            The data is cast as integer and the raw hex/binary can be accessed
            like the following example:

            >> print(output[0] & 0xffffffff)
            3735928559

            >> print(hex(output[0] & 0xffffffff))
            0xdeadbeef

            >> print(bin(output[0] & 0xffffffff))
            0b11011110101011011011111011101111

        """
        if self._readalloc is True:
            self._free(self.readbuf)
        self.readbuf = self._alloc(length * 4)
        self._readalloc = True
        self._recv(self.readbuf,length)
        if wait is False:
            return
        self.wait()
        buf = ffi.cast("int *",self.readbuf)
        return buf

    def write(self,buf, wait = True):
        """Write a python integer list into PL using DMA.

        This method is intended for anyone who doesn't want to deal
        with memory allocations while writing data into PL.

        Parameters
        ----------
        buf : list
            list containing integers to be written into the PL
        wait : bool (=True)
            if wait is True then the DMA call is blocking. It 
            can be made non-blocking by setting wait to False.

        Returns
        -------
        None

        """
        if self._writealloc is True:
            self._free(self.writebuf)
        length = len(buf) * 4
        self.writebuf = self._alloc(length)
        ffi.cast("int *",self.writebuf)
        for i in range(0,len(buf)):
            self.writebuf[i] = buf[i]
        self._writealloc = True
        self._send(self.writebuf,length)
        if wait is False:
            return
        self.wait()