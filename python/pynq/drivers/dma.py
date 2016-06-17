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


import cffi


LIB_SEARCH_PATH = os.path.dirname(os.path.realpath(__file__))
dmalib = ffi.dlopen(LIB_SEARCH_PATH + "/libdma.so")

DMA_TO_DEV = 0
DMA_FROM_DEV = 1
device_id = 0

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

class DMA():

    def __init__(self,address,direction = DMA_TO_DEV):
        self._get_channel(address,direction)
        self._register()
        self.readbuf = ffi.new_handle("void")
        self._readalloc = False
        self.writebuf = ffi.new_handle("void")
        self._writealloc = False

    def __del__(self):
        self._unregister()

    def _get_channel(self,address,direction):
        self.info = ffi.new("axi_dma_simple_info_t *")
        global device_id
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
        dmalib.reg_and_open(self.channel)

    def _unregister(self):
        dmalib.unreg_and_close(self.channel)

    def _send(self,buf,length):
        dmalib._dma_send(self.channel,buf,length,self.info.device_id)

    def _recv(self,buf,length):
        self.info.dir = DMA_FROM_DEV
        dmalib._dma_recv(self.channel,buf,length,self.info.device_id)

    def wait(self):
        dmalib._dma_wait(self.info.device_id)

    def _alloc(self,length):
        return dmalib.sds_alloc(length)

    def _free(self,pointer):
        dmalib.sds_free(pointer)

    def get_read_buf(self):
        return ffi.cast("int *",self.readbuf)

    def read(self,length,wait = True):
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
        if self._writealloc is True:
            self._free(self.writebuf)
        length = len(buf) * 4
        self.writebuf = self._alloc(length)
        self._writealloc = True
        self._send(self.writebuf,length)
        if wait is False:
            return
        self.wait()
