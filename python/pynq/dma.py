from dma_const import *

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
