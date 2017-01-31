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
import signal

ffi = cffi.FFI()
memapi = cffi.FFI()

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

        uint32_t * FirstBdPhysAddr; /**< Physical address of 1st BD in list */
        uint32_t * FirstBdAddr;  /**< Virtual address of 1st BD in list */
        uint32_t * LastBdAddr;  /**< Virtual address of last BD in the list */
        uint32_t Length;         /**< Total size of ring in bytes */
        uint32_t * Separation;  /**< Number of bytes between the starting
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
        XAxiDma_BdRing TxBdRing;     /* BD container management */
        XAxiDma_BdRing RxBdRing[16]; /* BD container management */
        int TxNumChannels;
        int RxNumChannels;
        int MicroDmaMode;
        int AddrWidth;            /**< Address Width */
} XAxiDma;
unsigned int getMemoryMap(unsigned int phyAddr, unsigned int len);
unsigned int getPhyAddr(void *buf);
void frame_free(void *buf);
int XAxiDma_CfgInitialize(XAxiDma * InstancePtr, XAxiDma_Config *Config);
void XAxiDma_Reset(XAxiDma * InstancePtr);
int XAxiDma_ResetIsDone(XAxiDma * InstancePtr);
int XAxiDma_Pause(XAxiDma * InstancePtr);
int XAxiDma_Resume(XAxiDma * InstancePtr);
uint32_t XAxiDma_Busy(XAxiDma *InstancePtr,int Direction);
uint32_t XAxiDma_SimpleTransfer(XAxiDma *InstancePtr,\
uint32_t * BuffAddr, uint32_t Length,int Direction);
int XAxiDma_SelectKeyHole(XAxiDma *InstancePtr, int Direction, int Select);
int XAxiDma_SelectCyclicMode(XAxiDma *InstancePtr, int Direction, int Select);
int XAxiDma_Selftest(XAxiDma * InstancePtr);
void DisableInterruptsAll(XAxiDma * InstancePtr);
""")

memapi.cdef("""
static uint32_t xlnkBufCnt = 0;
uint32_t cma_mmap(uint32_t phyAddr, uint32_t len);
uint32_t cma_munmap(void *buf, uint32_t len);
void *cma_alloc(uint32_t len, uint32_t cacheable);
uint32_t cma_get_phy_addr(void *buf);
void cma_free(void *buf);
uint32_t cma_pages_available();
""")

LIB_SEARCH_PATH = os.path.dirname(os.path.realpath(__file__))
libdma = ffi.dlopen(LIB_SEARCH_PATH + "/libdma.so")
libxlnk = memapi.dlopen("/usr/lib/libsds_lib.so")

DefaultConfig = {
    'DeviceId' : 0,
    'BaseAddr' : ffi.cast("uint32_t *",0x00000000),
    'HasStsCntrlStrm' : 0,
    'HasMm2S' : 0,
    'HasMm2SDRE' : 0,
    'Mm2SDataWidth' : 32,
    'HasS2Mm' : 1,
    'HasS2MmDRE' : 0,
    'S2MmDataWidth' : 64,
    'HasSg' : 0,
    'Mm2sNumChannels' : 1,
    'S2MmNumChannels' : 1,
    'Mm2SBurstSize' : 16,
    'S2MmBurstSize' : 64,
    'MicroDmaMode' : 0,
    'AddrWidth' : 32
}

DMA_TO_DEV = 0
DMA_FROM_DEV = 1
DMA_BIDIRECTIONAL = 3

DeviceId = 0
DMA_TRANSFER_LIMIT_BYTES = 8388607


class timeout:
    """Internal timeout functions.
    
    This class is only used internally.
    
    """
    def __init__(self, seconds=1, error_message='Timeout'):
        self.seconds = seconds
        self.error_message = error_message

    def handle_timeout(self, signum, frame):
        raise TimeoutError(self.error_message)

    def __enter__(self):
        signal.signal(signal.SIGALRM, self.handle_timeout)
        signal.alarm(self.seconds)

    def __exit__(self, type, value, traceback):
        signal.alarm(0)

class DMA:
    """Python class which controls DMA.
    
    This is a generic DMA class that can be used to access main memory.
    
    The DMA direction can be:
    
    (0)`DMA_TO_DEV` : DMA sends data to PL.
    
    (1)`DMA_FROM_DEV` : DMA receives data from PL.
    
    (3)`DMA_BIDIRECTIONAL` : DMA can send/receive data from PL.
    
    Attributes
    ----------
    buf : cffi.FFI.CData
        A pointer to physically contiguous buffer.
    bufLength : int
        Length of internal buffer in bytes.
    phyAddress : int
        Physical address of the DMA device.
    DMAengine : cdata 'XAxiDma *'
        DMA engine instance defined in C. Not to be directly modified.
    DMAinstance : cdata 'XAxiDma_Config *'
        DMA configuration instance struct. Not to be directly modified.
    direction : int
        The direction indicating whether DMA sends/receives data from PL.
    Configuration : dict
        Current DMAinstance configuration values.
        
    """
    def __init__(self, address, direction=DMA_FROM_DEV,attr_dict= None):
        """Initializes a new DMA object.
        
        Uses the Default configuration parameters to initialize
        a DMA. After initialization, the DMA is reset and the
        interrupts are disabled for DMA.
        
        The DMA direction can be:
        
        (0)`DMA_TO_DEV` : DMA sends data to PL.
        
        (1)`DMA_FROM_DEV` : DMA receives data from PL.
        
        (3)`DMA_BIDIRECTIONAL` : DMA can send/receive data from PL.
        
        The keys in `attr_dict` should exactly match the ones used in default 
        config. All the keys are not required. The default configuration is 
        defined in dma.DefaultConfig dict. Users can reinitialize the DMA 
        with new configuratiuon after creating the object.
        
        Parameters
        ----------
        address: int
            Physical address of the DMA IP.
        direction : int
            The direction indicating whether DMA sends/receives data from PL.
        attr_dict : dict
            An optional dictionary specifying DMA configuration values.
            
        """
        self.buf = None
        self.direction = direction
        self.bufLength = None
        self.phyAddress = address
        self.DMAengine = ffi.new("XAxiDma *")
        self.DMAinstance = ffi.new("XAxiDma_Config *")
        self.Configuration = {}
        self._gen_config(address,direction,attr_dict)
        
        status = libdma.XAxiDma_CfgInitialize(self.DMAengine,self.DMAinstance)
        if status != 0:
            raise RuntimeError("Failed to initialize DMA!")
        libdma.XAxiDma_Reset(self.DMAengine)
        libdma.DisableInterruptsAll(self.DMAengine)

    def _gen_config(self, address, direction, attr_dict):
        """Build configuration and map memory.

        This is an internal method used for initialization and
        should not be called by user.

        """
        global DefaultConfig
        global DeviceId
        for key in DefaultConfig.keys():
            self.DMAinstance.__setattr__(key,DefaultConfig[key])
        if direction == DMA_TO_DEV:
            self.DMAinstance.HasS2Mm = 0
            self.DMAinstance.HasMm2S = 1
        elif direction == DMA_BIDIRECTIONAL:
            self.DMAinstance.HasS2Mm = 1
            self.DMAinstance.HasMm2S = 1 
        self._bufPtr = None
        self._TransferInitiated = 0
        if attr_dict is not None:
            if type(attr_dict) == dict:
                for key in attr_dict.keys():
                    self.DMAinstance.__setattr__(key,attr_dict[key])
            else:
                print("Warning: Expecting 3rd Arg to be a dict.")

        virt = libxlnk.cma_mmap(address,0x10000)
        if virt == -1:
            raise RuntimeError("Memory map of driver failed.")
        self.DMAinstance.BaseAddr = ffi.cast("uint32_t *",virt)
        self.DMAinstance.DeviceId = DeviceId
        DeviceId += 1
        
        for key in DefaultConfig.keys():
            self.Configuration[key] = self.DMAinstance.__getattribute__(key)
        
    def __del__(self):
        """Destructor for DMA object.

        Frees the internal buffer and Resets the DMA.

        Parameters
        ----------
        None

        Returns
        -------
        None

        """
        if self.buf != None and self.buf != ffi.NULL:
            self.free_buf()
        libdma.XAxiDma_Reset(self.DMAengine)

    def transfer(self,num_bytes,direction=DMA_FROM_DEV):
        """Transfer data using DMA (Non-blocking).

        Used to initiate transfer of data between a physically contiguous
        buffer and PL. The buffer should be allocated using `create_buf`
        before this call.
        
        The `num_bytes` should be less than buffer size and 
        `DMA_TRANSFER_LIMIT_BYTES`.
        
        Possible values for `direction` are:
        
        (0)`DMA_TO_DEV` : DMA sends data to PL.
        
        (1)`DMA_FROM_DEV` : DMA receives data from PL.
        
        Parameters
        ----------
        num_bytes : int
            Number of bytes to transfer.
        direction : int
            Direction in which DMA transfers data. 
            
        Returns
        -------
        None
        
        """
        if num_bytes > self.bufLength:
            raise RuntimeError("Buffer size smaller than the transfer size")
        if num_bytes > DMA_TRANSFER_LIMIT_BYTES:
            raise RuntimeError("DMA transfer size > {}".format(
                                    DMA_TRANSFER_LIMIT_BYTES))
        if not direction in [DMA_FROM_DEV, DMA_TO_DEV]:
            raise RuntimeError("Invalid direction for transfer.")
        self.direction = direction
        if self.buf is not None:
            libdma.XAxiDma_SimpleTransfer(\
                self.DMAengine,
                self._bufPtr,
                num_bytes,
                self.direction
                )
            self._TransferInitiated = 1
        else:
            raise RuntimeError("Buffer not allocated.")
            
    def create_buf(self, num_bytes, cacheable = 0):
        """Allocate physically contiguous memory buffer.
        
        Allocates/Reallocates buffer needed for DMA operations.
        
        Possible values for parameter `cacheable` are:
        
        `1`: the memory buffer is cacheable.
        
        `0`: the memory buffer is non-cacheable.
        
        Note
        ----
        This buffer is allocated inside the kernel space using
        xlnk driver. The maximum allocatable memory is defined
        at kernel build time using the CMA memory parameters.
        For Pynq-Z1 kernel, it is specified as 128MB.
        
        Parameters
        ----------
        num_bytes : int
            Length of the allocated array in bytes.
        cacheable : int
            Indicating whether or not the memory buffer is cacheable
            
        Returns
        -------
        None
        
        """
        if self.buf is None:
            self.buf = libxlnk.cma_alloc(num_bytes, cacheable)
            if self.buf == ffi.NULL:
                raise RuntimeError("Memory allocation failed.")
        else:
            libxlnk.cma_free(self.buf)
            self.buf = libxlnk.cma_alloc(num_bytes, cacheable)
        bufPhyAddr = libxlnk.cma_get_phy_addr(self.buf)
        self._bufPtr = ffi.cast("uint32_t *",bufPhyAddr)
        self.bufLength = num_bytes
        
    def free_buf(self):
        """Free the memory buffer associated with this object.

        Use this to free a previously allocated memory buffer.
        This is specially useful for reallocations.

        Parameters
        ----------
        None

        Returns
        -------
        None

        """
        if self.buf == None or self.buf == ffi.NULL:
            return
        libxlnk.cma_free(self.buf)
        
    def wait(self, wait_timeout=10):
        """Block till DMA is busy or a timeout occurs.
        
        Default value of timeout is 10 seconds.
        
        Parameters
        ----------
        wait_timeout : int
            Time to wait in seconds before timing out wait operation.
            
        Returns
        -------
        None
        
        """
        if self._TransferInitiated == 0:
            return
        Error = "DMA wait timed out."
        with timeout(seconds = wait_timeout, error_message = Error):
            while True:
                if libdma.XAxiDma_Busy(self.DMAengine,self.direction) == 0:
                    break
                    
    def get_buf(self, width=32):
        """Get a CFFI pointer to object's internal buffer.
        
        This can be accessed like a regular array in python. The width can be 
        either 32 or 64.
        
        Parameters
        ----------
        width : int
            The data width in the buffer.
            
        Returns
        -------
        cffi.FFI.CData
            An CFFI object which can be accessed similar to arrays in C.
            
        """
        if self.buf is not None:
            if width == 32:
                return ffi.cast("unsigned int *",self.buf)
            elif width == 64:
                return ffi.cast("long long *",self.buf)
        else:
            raise RuntimeError("Buffer not created.")
        
    def configure(self, attr_dict=None):
        """Reconfigure and Reinitialize the DMA IP.

        Uses a user provided dict to reinitialize the DMA.
        This method also frees the internal buffer
        associated with current object.
        
        The keys in `attr_dict` should exactly match the ones used in default 
        config. All the keys are not required. The default configuration is 
        defined in dma.DefaultConfig dict. Users can reinitialize the DMA 
        with new configuratiuon after creating the object.
        
        Parameters
        ----------
        attr_dict : dict
            A dictionary specifying DMA configuration values.
            
        Returns
        -------
        None
        
        """
        self.free_buf()
        self.__init__(self.phyAddress,self.direction,attr_dict)
        