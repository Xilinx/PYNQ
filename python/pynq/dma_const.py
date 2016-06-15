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
ffi = cffi.FFI()
#wa = ffi.new_handle("struct test")

DMA_TO_DEV = 0
DMA_FROM_DEV = 1
device_id = 0

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
