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
import sys
import cffi

ffi = cffi.FFI()

ffi.cdef("""
typedef unsigned int* XAxiDma_Bd[20];
typedef struct {
        uint32_t ChanBase;           /**< physical base address*/
        int IsRxChannel;        /**< Is this a receive channel */
        volatile int RunState;  /**< Whether channel is running */
        int HasStsCntrlStrm;    /**< Whether has stscntrl stream */
        int HasDRE;
        int DataWidth;
        int Addr_ext;
        uint32_t MaxTransferLen;

        uint32_t * FirstBdPhysAddr;        /**< Physical address of 1st BD in list */
        uint32_t * FirstBdAddr;    /**< Virtual address of 1st BD in list */
        uint32_t * LastBdAddr;             /**< Virtual address of last BD in the list */
        uint32_t Length;             /**< Total size of ring in bytes */
        uint32_t * Separation;             /**< Number of bytes between the starting
                                     address of adjacent BDs */
        XAxiDma_Bd *FreeHead;   /**< First BD in the free group */
        XAxiDma_Bd *PreHead;    /**< First BD in the pre-work group */
        XAxiDma_Bd *HwHead;     /**< First BD in the work group */
        XAxiDma_Bd *HwTail;     /**< Last BD in the work group */
        XAxiDma_Bd *PostHead;   /**< First BD in the post-work group */
        XAxiDma_Bd *BdaRestart; /**< BD to load when channel is started */
        int FreeCnt;            /**< Number of allocatable BDs in free group */
        int PreCnt;             /**< Number of BDs in pre-work group */
        int HwCnt;              /**< Number of BDs in work group */
        int PostCnt;            /**< Number of BDs in post-work group */
        int AllCnt;             /**< Total Number of BDs for channel */
        int RingIndex;          /**< Ring Index */
} XAxiDma_BdRing;
typedef struct {
        uint32_t DeviceId;
        uint32_t * BaseAddr;

        int HasStsCntrlStrm;
        int HasMm2S;
        int HasMm2SDRE;
        int Mm2SDataWidth;
        int HasS2Mm;
        int HasS2MmDRE;
        int S2MmDataWidth;
        int HasSg;
        int Mm2sNumChannels;
        int S2MmNumChannels;
        int Mm2SBurstSize;
        int S2MmBurstSize;
        int MicroDmaMode;
        int AddrWidth;            /**< Address Width */
} XAxiDma_Config;
typedef struct XAxiDma {
        uint32_t RegBase;            /* Virtual base address of DMA engine */
        int HasMm2S;            /* Has transmit channel */
        int HasS2Mm;            /* Has receive channel */
        int Initialized;        /* Driver has been initialized */
        int HasSg;
        XAxiDma_BdRing TxBdRing;     /* BD container management for TX channel */
        XAxiDma_BdRing RxBdRing[16]; /* BD container management for RX channel */
        int TxNumChannels;
        int RxNumChannels;
        int MicroDmaMode;
        int AddrWidth;            /**< Address Width */
} XAxiDma;
unsigned int getMemoryMap(unsigned int phyAddr, unsigned int len);
void *frame_alloc(unsigned int len);
unsigned int getPhyAddr(void *buf);
void frame_free(void *buf);
int XAxiDma_CfgInitialize(XAxiDma * InstancePtr, XAxiDma_Config *Config);
void XAxiDma_Reset(XAxiDma * InstancePtr);
int XAxiDma_ResetIsDone(XAxiDma * InstancePtr);
int XAxiDma_Pause(XAxiDma * InstancePtr);
int XAxiDma_Resume(XAxiDma * InstancePtr);
uint32_t XAxiDma_Busy(XAxiDma *InstancePtr,int Direction);
uint32_t XAxiDma_SimpleTransfer(XAxiDma *InstancePtr, uint32_t * BuffAddr, uint32_t Length,int Direction);
int XAxiDma_SelectKeyHole(XAxiDma *InstancePtr, int Direction, int Select);
int XAxiDma_SelectCyclicMode(XAxiDma *InstancePtr, int Direction, int Select);
int XAxiDma_Selftest(XAxiDma * InstancePtr);
void DisableInterruptsAll(XAxiDma * InstancePtr);
""")

LIB_SEARCH_PATH = os.path.dirname(os.path.realpath(__file__))
libdma = ffi.dlopen(LIB_SEARCH_PATH + "/libdma.so")

# This is a template
DMAinstance = ffi.new("XAxiDma_Config *")
DMAinstance.DeviceId = 0
DMAinstance.BaseAddr = ffi.cast("uint32_t *",0x00000000)
DMAinstance.HasStsCntrlStrm = 0
DMAinstance.HasMm2S = 0
DMAinstance.HasMm2SDRE = 0
DMAinstance.Mm2SDataWidth = 32
DMAinstance.HasS2Mm = 1
DMAinstance.HasS2MmDRE = 0
DMAinstance.S2MmDataWidth = 64
DMAinstance.HasSg = 0
DMAinstance.Mm2sNumChannels = 1
DMAinstance.S2MmNumChannels = 1
DMAinstance.Mm2SBurstSize = 16
DMAinstance.S2MmBurstSize = 64
DMAinstance.MicroDmaMode = 0
DMAinstance.AddrWidth = 32

DMA_TO_DEV = 0
DMA_FROM_DEV = 1
device_id = 0
DMA_TRANSFER_LIMIT_BYTES = 8388607

class DMA():

    def __init__(self, address, direction='r',AttrDict= None):
        global DMAinstance
        global device_id
        self.DMAengine = ffi.new("XAxiDma *")
        self.DMAinstance = DMAinstance
        if direction == 'w':
            DMAinstance.HasS2Mm = 0
            DMAinstance.HasMm2S = 1
        elif direction == 'rw':
            DMAinstance.HasS2Mm = 1
            DMAinstance.HasMm2S = 1 
        self._bufPtr = None
        self._TransferInitiated = 0
        if self.AttrDict is not None:
            if type(AttrDict) == dict:
                for key in AttrDict.keys():
                    self.DMAinstance.__setattr__(key,AttrDict[key])
            else:
                print("Warning: Expecting 3rd Arg to be a dict.")
        self.buf = None
        self.direction = None
        self.bufLength = None

        virt = libdma.getMemoryMap(address,0x10000)
        if virt == -1:
            raise RuntimeError("Memory map of driver failed!")
        print("virt : ",hex(virt))
        DMAinstance.BaseAddr = ffi.cast("uint32_t *",virt)
        if direction == DMA_TO_DEV:
            DMAinstance.HasS2Mm = 0
            DMAinstance.HasMm2S = 1
        self.DMAinstance.DeviceId = device_id
        device_id += 1

        status = libdma.XAxiDma_CfgInitialize(self.DMAengine,self.DMAinstance)
        if status != 0:
            raise RuntimeError("Failed to initialize DMA!")
        libdma.XAxiDma_Reset(self.DMAengine)
        libdma.DisableInterruptsAll(self.DMAengine)
        
    def __del__(self):
        self.FreeBuf()
        libdma.XAxiDma_Reset(self.DMAengine)

    def SimpleTransfer(self,numBytes,direction='r'):
        if numBytes > self.bufLength:
            raise RuntimeError("Buffer Size Smaller than the transfer size")
        if numBytes > DMA_TRANSFER_LIMIT_BYTES:
            raise RuntimeError("DMA Transfer Size Exceeds the max of",\
                DMA_TRANSFER_LIMIT_BYTES)
        if direction == 'r':
            self.direction = DMA_FROM_DEV
        elif direction == 'w':
            self.direction = DMA_TO_DEV 
        if self.buf is not None:
            libdma.XAxiDma_SimpleTransfer(\
                self.DMAengine,\
                self._bufPtr,\
                numBytes,\
                self.direction\
                )
            self._TransferInitiated = 1
        else:
            print("Transfer Error! Please allocate a buffer first.")

    def CreateBuf(self, numBytes):
        if self.buf is None:
            self.buf = libdma.frame_alloc(numBytes)
            if self.buf == ffi.NULL:
                raise RuntimeError("Memory allocation failed.")
        else:
            libdma.frame_free(self.buf)
            self.buf = libdma.frame_alloc(numBytes)
        bufPhyAddr = libdma.getPhyAddr(self.buf)
        self._bufPtr = ffi.cast("uint32_t *",bufPhyAddr)
        self.bufLength = numBytes

    def FreeBuf(self):
        libdma.frame_free(self.buf)

    def SimpleWait(self):
        if self._TransferInitiated == 0:
            return
        while True:
            if libdma.XAxiDma_Busy(self.DMAengine,self.direction) == 0:
                break

    def GetBuf(self):
        if self.buf is not None:
            return ffi.cast("unsigned int *",self.buf)
        print("Buffer not created!")

    def ReInitializeDMA(AttrDict=None):
        self.FreeBuf()
        self.__init__(AttrDict)