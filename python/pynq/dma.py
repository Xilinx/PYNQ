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


from pynq import dma_const

class DMA():
    
    def __init__(self,address,direction = DMA_TO_DEV):
        # Pick a random direction
        self.info = ffi.new("axi_dma_simple_info_t *")
        global device_id
        global DMA_ADDR_RANGE
        self.info.device_id = device_id
        device_id = device_id + 1
        self.info.phys_base_addr = address
        self.info.addr_range = DMA_ADDR_RANGE
        self.info.dir = direction
        self.channel = ffi.new("axi_dma_simple_channel_info_t *")
        self.channel.dma_info = self.info
        self.channel. in_use = 0
        self.channel.needs_cache_flush_invalidate = 0
        self.num_recd = ffi.new("int *")
        self.sent_data = 0
        
    def register(self):
        dmalib.custom_dma_register(self.info.device_id)
        
    def unregister(self):
        dmalib.custom_dma_unregister(self.info.device_id)
    
    def open(self):
        dmalib.custom_dma_open(self.channel, self.info.device_id)

    def close(self):
        dmalib.custom_dma_close(self.channel, self.info.device_id)
        
    def send(self,buf,length):
        dmalib.custom_dma_send_i(self.channel,buf,length,self.info.device_id)
        
    def recv(self,buf,length):
        self.info.dir = DMA_FROM_DEV
        self.sent_data = length
        dmalib.custom_dma_recv_i(self.channel,buf,length,self.num_recd,self.info.device_id)

    def wait(self):
        dmalib.custom_dma_wait(self.info.device_id)