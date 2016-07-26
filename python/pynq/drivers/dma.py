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
__email__       = "pynq_support@xilinx.com"


import os
import cffi

ffi = cffi.FFI()

ffi.cdef("""
typedef struct axi_dma_simple_info_struct {
        int device_id;
        unsigned int phys_base_addr;
        unsigned int addr_range;
        unsigned int virt_base_addr;
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
int _dma_wait(int handle_id, int timeout_sec);
""")

LIB_SEARCH_PATH = os.path.dirname(os.path.realpath(__file__))
dmalib = ffi.dlopen(LIB_SEARCH_PATH + "/libdma.so")

DMA_TO_DEV = 0
DMA_FROM_DEV = 1
device_id = 0
_address_table = {}
DMA_TRANSFER_LIMIT_BYTES = 8388607

class DMA():
    """This class controls the DMA.
    
    Attributes
    ----------
    readbuf : CdataOwnGC
        Read buffer, read from DMA.
    writebuf : CdataOwnGC
        Write buffer, write into DMA.
    info : CDataOwn
        A collection of information about the DMA.
    channel : CDataOwn
        The channel information.
        
    """
    def __new__(cls, address, direction=DMA_TO_DEV):
        """Return a DMA object.
        
        NOTE
        ----
        Users should not touch this method directly.
        
        This method is called before __init__ and is responsible for
        actually creating the object. If the object is already present in
        the address table, a reference to the old object is returned.
        
        """
        if address in _address_table.keys():
            return _address_table[address]
        new_obj =  super(DMA, cls).__new__(cls)
        return new_obj
        
    def __init__(self, address, direction=DMA_TO_DEV):
        """Return a new DMA Object.
        
        Initialization process also checks for address conflics
        and registers and opens the DMA port.
        
        Only single instance of a particular DMA address should be present
        to avoid conflicts.
        
        Note
        ----
        Possible values of direction are: 
        0 : DMA sends data to PL.
        1 : DMA receives data from PL.
        
        Parameters
        ----------
        address : int
            Physical address of the DMA.
        direction : int
            Direction indicating whether the DMA sends or receives data.
            
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
        
        Unregisters and closes the DMA port.
        
        Parameters
        ----------
        None
        
        Returns
        -------
        None
        
        """
        self._unregister()
        
    def _get_channel(self, address, direction):
        """Setups the DMA channel during initialization.
        
        This method returns dmalib compatible C structs which are passed to 
        dmalib functions.
        
        Note
        ----
        This method should not be called by user as the program might crash.
        
        Parameters
        ----------
        address : int
            Physical address of the DMA.
        direction : int
            Direction indicating whether the DMA sends or receives data.
            
        Returns
        -------
        None
        
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
        
        Note
        ----
        This method should not be called by user as the program might crash.
        
        Parameters
        ----------
        None
        
        Returns
        -------
        None
        
        """
        dmalib.reg_and_open(self.channel)
        
    def _unregister(self):
        """Unregisters the DMA channel during destroy.
        
        Note
        ----
        This method should not be called by user as the program might crash.
        
        Parameters
        ----------
        None
        
        Returns
        -------
        None
        
        """
        dmalib.unreg_and_close(self.channel)
        
    def _send(self, buf, length):
        """Basic DMA send method (non-blocking).
        
        This method takes a buffer in physically contiguous memory locations
        and sends it via DMA into the PL. The buffer can be allocated using
        "_alloc" method. If users don't want to do it manually, they can use
        "write" method instead. This is a non blocking method as it
        returns immediately.
        
        Parameters
        ----------
        buf : cffi.FFI.CData
            The buffer allocated using sds_alloc method.
        length : int
            Length of the buffer.
            
        Returns
        -------
        None
        
        """
        dmalib._dma_send(self.channel,buf,length,self.info.device_id)
        
    def _recv(self, buf, length):
        """Basic DMA receive method (non-blocking).
        
        This method takes a buffer in physically contiguous memory locations
        and fills it with data received from PL. The buffer can be allocated
        using "_alloc" method. If users don't want to do it manually, they
        can use "read" method instead. This is a non blocking method as it
        returns immediately.
        
        Parameters
        ----------
        buf : cffi.FFI.CData
            The buffer allocated using sds_alloc method.
        length : integer
            Length of the buffer.
            
        Returns
        -------
        None
        
        """
        self.info.dir = DMA_FROM_DEV
        dmalib._dma_recv(self.channel,buf,length,self.info.device_id)
        
    def wait(self, timeout=0):
        """Wait on DMA transfer to complete.
        
        Call this method if users want to block till the DMA transfer
        is complete. Note that timing out a wait operation does not
        reset the underlying hardware.
        
        Note
        ----
        Set `timeout` to 0 for unlimited timeout.
        
        Parameters
        ----------
        timeout : int
            Time to wait in seconds before timeout.
            
        Returns
        -------
        None
        
        """
        if dmalib._dma_wait(self.info.device_id,timeout) == -1:
            raise RuntimeError("DMA wait timed out.")
            
    def _alloc(self, length):
        """Allocate physically contiguous memory locations in memory.
        
        This method generates the buffers needed for DMA transfers.
        
        Parameters
        ----------
        length : int
            length of the allocate array in bytes.
            
        Returns
        -------
        cffi.FFI.CData
            A pointer to the buffer which can be accessed like a C array.
            
        """
        allocated = dmalib.sds_alloc(length)
        if allocated != ffi.NULL:
            return allocated
        else:
            raise RuntimeError("Memory allocation failed.")
            return
            
    def _free(self, pointer):
        """Free previously allocated buffer memory.
        
        Use this to free a previously allocated buffer memory. There is a 
        limit on size of physically contiguous memory which can be allocated 
        and thus, it is important to free up any unneeded memory.
        
        Parameters
        ----------
        pointer : cffi.FFI.CData
            The buffer which was allocated using _alloc.
            
        Returns
        -------
        None
        
        """
        if pointer != ffi.NULL and pointer != None:
            dmalib.sds_free(pointer)
            
    def get_read_buf(self):
        """Return a previously read buffer
        
        Use this to get the read buffer when calling a non-blocking
        read and then later calling a "wait".
        
        The returned data is cast as integer and the raw hex/binary can be 
        accessed just like the following examples:
        
        >>> print(output[0] & 0xffffffff)
        3735928559
        
        >>> print(hex(output[0] & 0xffffffff))
        0xdeadbeef
        
        >>> print(bin(output[0] & 0xffffffff))
        0b11011110101011011011111011101111
        
        Parameters
        ----------
        None
        
        Returns
        -------
        cffi.FFI.CData
            An CFFI object which can be accessed similar to arrays in C.
            
        """
        return ffi.cast("int *",self.readbuf)
        
    def read(self, length, blocking=True, timeout=0):
        """ Read bytes from the PL
        
        This method is intended for those who don't want to deal
        with memory allocations. Users can simply pass length of an array
        that they want to receive from PL. Each array element is 4 bytes 
        in size.
        
        An CFFI object can be accessed similar to arrays in C. The data is 
        cast as integer and the raw hex/binary can be accessed just like the 
        following example:
        
        >>> print(output[0] & 0xffffffff)
        3735928559
        
        >>> print(hex(output[0] & 0xffffffff))
        0xdeadbeef
        
        >>> print(bin(output[0] & 0xffffffff))
        0b11011110101011011011111011101111
        
        Note
        ----
        Set `blocking` to False to make DMA non-blocking.
        
        Note
        ----
        Set `timeout` to 0 for unlimited timeout.
        
        Parameters
        ----------
        length : int
            Number of bytes to be read (prefer a multiple of 4)
        blocking : bool
            Indicate whether or not the DMA call is blocking.
        timeout : int
            Time to wait in seconds before timeout.
            
        Returns
        -------
        cffi.FFI.CData
            Only returns for blocking reads.
            
        """
        # Check if Size is Less than 8MB
        if length > DMA_TRANSFER_LIMIT_BYTES:
            raise ValueError("Read input length exceeds the DMA size.")
            
        if self._readalloc is True:
            self._free(self.readbuf)
        self.readbuf = self._alloc(length)
        self._readalloc = True
        self._recv(self.readbuf,length)
        if blocking == False:
            return
        else:
            self.wait(timeout)
            return ffi.cast("int *",self.readbuf)
            
    def write(self, buf, blocking=True, timeout=0):
        """Write a python integer list into PL using DMA.
        
        This method is intended for those who don't want to deal
        with memory allocations while writing data into PL.
        
        Note
        ----
        Set `blocking` to False to make DMA non-blocking.
        
        Note
        ----
        Set `timeout` to 0 for unlimited timeout.
        
        Parameters
        ----------
        buf : list
            list containing integers to be written into the PL
        blocking : bool
            Indicate whether or not the DMA call is blocking.
        timeout : int
            Time to wait in seconds before timeout.
            
        Returns
        -------
        None
        
        """
        length = len(buf) * 4
        
        # Check if Size is less than 8MB
        if length > DMA_TRANSFER_LIMIT_BYTES:
            raise ValueError("Write input length exceeds the DMA size.")
            
        if self._writealloc is True:
            self._free(self.writebuf)
        self.writebuf = self._alloc(length)
        self.writebuf = ffi.cast("int *",self.writebuf)
        for i in range(0,len(buf)):
            self.writebuf[i] = buf[i]
        self._writealloc = True
        self._send(self.writebuf,length)
        if blocking is True:
            self.wait(timeout)
            