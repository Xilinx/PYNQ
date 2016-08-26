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
import signal
import sys
import cffi
import resource

if os.getuid() != 0:
    raise RuntimeError("Root permission needed by the library")

# Cleanup on Segfaults
def sig_handler(signum, frame):
    print("Invalid Memory Access!")
    xlnk().xlnk_reset()
    sys.exit(127)
signal.signal(signal.SIGSEGV, sig_handler)

ffi = cffi.FFI()

ffi.cdef("""
static uint32_t xlnkBufCnt = 0;
uint32_t cma_mmap(uint32_t phyAddr, uint32_t len);
uint32_t cma_munmap(void *buf, uint32_t len);
void *cma_alloc(uint32_t len, uint32_t cacheable);
uint32_t cma_get_phy_addr(void *buf);
void cma_free(void *buf);
uint32_t cma_pages_available();
void _xlnk_reset();
""")

libxlnk = ffi.dlopen("/usr/lib/libxlnk_cma.so")

class xlnk:

    def __init__(self):
        self.bufmap = {}

    def __del__(self):
        for key in self.bufmap.keys():
            libxlnk.cma_free(key)
    
    def __check_buftype(self, buf):
        if "cdata" not in str(buf):
            raise RuntimeError("Unknown buffer type")
        
    def cma_alloc(self, length, cacheable = 0, data_type = "void"):
        if data_type != "void":
            length = ffi.sizeof(data_type) * length
        buf = libxlnk.cma_alloc(length, cacheable)
        if buf == ffi.NULL:
            raise RuntimeError("Failed to allocate Memory!")
        self.bufmap[buf] = length
        return ffi.cast(data_type+"*",buf)

    def cma_get_buffer(self, buf, length):
        self.__check_buftype(buf)
        return(memoryview(ffi.buffer(buf, length)))

    @staticmethod
    def cma_memcopy(dest, src, nbytes):
        ffi.memmove(dest, src, nbytes)
    
    @staticmethod
    def cma_cast(data, data_type = "void"):
        return ffi.cast(data_type+"*", data)
      
    def cma_free(self, buf):
        if buf in self.bufmap:
            self.bufmap.pop(buf, None)
        self.__check_buftype(buf)
        libxlnk.cma_free(buf)
    
    def cma_stats(self):
        stats = {}
        free_pages = libxlnk.cma_pages_available()
        stats['CMA Memory Available'] = resource.getpagesize() * free_pages
        memused = 0
        for key in self.bufmap:
            memused += self.bufmap[key]
        stats['CMA Memory Usage'] = memused
        stats['Buffer Count'] = len(self.bufmap)
        return stats

    def xlnk_reset(self):
        self.bufmap = {}
        libxlnk._xlnk_reset()