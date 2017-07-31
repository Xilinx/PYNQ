#   Copyright (c) 2017, Xilinx, Inc.
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

from pynq import DefaultIP
import os
import sys
import cffi
import functools
import signal
import numpy as np
import warnings
from pynq.ps import CPU_ARCH_IS_SUPPORTED, CPU_ARCH


__author__ = 'Peter Ogden, Anurag Dubey'
__copyright__ = 'Copyright 2017, Xilinx'
__email__ = 'pynq_support@xilinx.com'

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

class LegacyDMA:
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

    Note
    ----
    If this class is parsed on an unsupported architecture it will issue
    a warning and leave the class variables libxlnk and libdma undefined

    """

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
    LIB_SEARCH_PATH = os.path.dirname(os.path.realpath(__file__))
    if CPU_ARCH_IS_SUPPORTED:
        libdma = ffi.dlopen(LIB_SEARCH_PATH + "/libdma.so")
    else:
        warnings.warn("Pynq does not support the CPU Architecture: {}"
                      .format(CPU_ARCH), ResourceWarning)
        
    DMA_TO_DEV = 0
    DMA_FROM_DEV = 1
    DMA_BIDIRECTIONAL = 3
    DMA_TRANSFER_LIMIT_BYTES = 8388607

    DeviceId = 0
    DefaultConfig = {
        'DeviceId': 0,
        'BaseAddr': ffi.cast("uint32_t *", 0x00000000),
        'HasStsCntrlStrm': 0,
        'HasMm2S': 0,
        'HasMm2SDRE': 0,
        'Mm2SDataWidth': 32,
        'HasS2Mm': 1,
        'HasS2MmDRE': 0,
        'S2MmDataWidth': 64,
        'HasSg': 0,
        'Mm2sNumChannels': 1,
        'S2MmNumChannels': 1,
        'Mm2SBurstSize': 16,
        'S2MmBurstSize': 64,
        'MicroDmaMode': 0,
        'AddrWidth': 32
    }

    memapi = cffi.FFI()

    memapi.cdef("""
    static uint32_t xlnkBufCnt = 0;
    uint32_t cma_mmap(uint32_t phyAddr, uint32_t len);
    uint32_t cma_munmap(void *buf, uint32_t len);
    void *cma_alloc(uint32_t len, uint32_t cacheable);
    uint32_t cma_get_phy_addr(void *buf);
    void cma_free(void *buf);
    uint32_t cma_pages_available();
    """)

    if CPU_ARCH_IS_SUPPORTED:
        libxlnk = memapi.dlopen("/usr/lib/libsds_lib.so")
    else:
        warnings.warn("Pynq does not support the CPU Architecture: {}"
                      .format(CPU_ARCH), ResourceWarning)

    def __init__(self, address, direction=DMA_FROM_DEV, attr_dict=None):
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
        defined in self.DefaultConfig dict. Users can reinitialize the DMA
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
        self.DMAengine = self.ffi.new("XAxiDma *")
        self.DMAinstance = self.ffi.new("XAxiDma_Config *")
        self.Configuration = {}
        self._gen_config(address, direction, attr_dict)

        status = self.libdma.XAxiDma_CfgInitialize(self.DMAengine, self.DMAinstance)
        if status != 0:
            raise RuntimeError("Failed to initialize DMA!")
        self.libdma.XAxiDma_Reset(self.DMAengine)
        self.libdma.DisableInterruptsAll(self.DMAengine)

    def _gen_config(self, address, direction, attr_dict):
        """Build configuration and map memory.

        This is an internal method used for initialization and
        should not be called by user.

        """
        for key in self.DefaultConfig.keys():
            self.DMAinstance.__setattr__(key, self.DefaultConfig[key])
        if direction == self.DMA_TO_DEV:
            self.DMAinstance.HasS2Mm = 0
            self.DMAinstance.HasMm2S = 1
        elif direction == self.DMA_BIDIRECTIONAL:
            self.DMAinstance.HasS2Mm = 1
            self.DMAinstance.HasMm2S = 1
        self._bufPtr = None
        self._TransferInitiated = 0
        if attr_dict is not None:
            if type(attr_dict) == dict:
                for key in attr_dict.keys():
                    self.DMAinstance.__setattr__(key, attr_dict[key])
            else:
                print("Warning: Expecting 3rd Arg to be a dict.")

        virt = self.libxlnk.cma_mmap(address, 0x10000)
        if virt == -1:
            raise RuntimeError("Memory map of driver failed.")
        self.DMAinstance.BaseAddr = self.ffi.cast("uint32_t *", virt)
        self.DMAinstance.DeviceId = self.DeviceId
        self.DeviceId += 1

        for key in self.DefaultConfig.keys():
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
        if self.buf is not None and self.buf is not self.ffi.NULL:
            self.free_buf()
        self.libdma.XAxiDma_Reset(self.DMAengine)

    def transfer(self, num_bytes=-1, direction=-1):
        """Transfer data using DMA (Non-blocking).

        Used to initiate transfer of data between a physically contiguous
        buffer and PL. The buffer should be allocated using `create_buf`
        or get_ndarray before this call.

        The `num_bytes` defaults to the buffer size and be both
        less than or equal to the buffer size and `DMA_TRANSFER_LIMIT_BYTES`.

        Possible values for `direction` are:

        (0)`DMA_TO_DEV` : DMA sends data to PL.

        (1)`DMA_FROM_DEV` : DMA receives data from PL.

        If the direction is not specified it uses the direction passed at
        initialisation. This is not valid for bidirectional DMA.

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
        if num_bytes == -1:
            num_bytes = self.bufLength
        if direction == -1:
            direction = self.direction
        if num_bytes > self.bufLength:
            raise RuntimeError("Buffer size smaller than the transfer size")
        if num_bytes > self.DMA_TRANSFER_LIMIT_BYTES:
            raise RuntimeError("DMA transfer size > {}".format(
                self.DMA_TRANSFER_LIMIT_BYTES))
        if direction not in [self.DMA_FROM_DEV, self.DMA_TO_DEV]:
            raise RuntimeError("Invalid direction for transfer.")
        self.direction = direction
        if self.buf is not None:
            self.libdma.XAxiDma_SimpleTransfer(
                self.DMAengine,
                self._bufPtr,
                num_bytes,
                self.direction
            )
            self._TransferInitiated = 1
        else:
            raise RuntimeError("Buffer not allocated.")

    def create_buf(self, num_bytes, cacheable=0):
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
            self.buf = self.libxlnk.cma_alloc(num_bytes, cacheable)
            if self.buf == self.ffi.NULL:
                raise RuntimeError("Memory allocation failed.")
        else:
            self.libxlnk.cma_free(self.buf)
            self.buf = self.libxlnk.cma_alloc(num_bytes, cacheable)
        bufPhyAddr = self.libxlnk.cma_get_phy_addr(self.buf)
        self._bufPtr = self.ffi.cast("uint32_t *", bufPhyAddr)
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
        if self.buf is None or self.buf == self.ffi.NULL:
            return
        self.libxlnk.cma_free(self.buf)

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
        with timeout(seconds=wait_timeout, error_message=Error):
            while True:
                if self.libdma.XAxiDma_Busy(self.DMAengine,
                                            self.direction) == 0:
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
                return self.ffi.cast("unsigned int *", self.buf)
            elif width == 64:
                return self.ffi.cast("long long *", self.buf)
        else:
            raise RuntimeError("Buffer not created.")

    def get_ndarray(self, shape=None, dtype=np.float32, cacheable=0):
        """Get a numpy ndarray of the DMA buffer, if shape is provided the
        buffer is resized to fit the specified shape.

        Parameters
        ----------
        shape : int array
            Shape of the numpy array to return
        dtype : numpy.dtype
            Type of the numpy array to return
        cacheable : int
            Passed to create_buf if a shape is provided

        Returns
        -------
        numpy.ndarray
            Numpy view of the DMA buffer

        """
        if shape:
            totalsize = (functools.reduce(lambda x, y: x * y, shape) *
                         dtype().itemsize)
            self.create_buf(totalsize, cacheable)
        if not self.buf:
            raise RuntimeError("Buffer not created or shape not specified")
        buffer = self.ffi.buffer(self.buf, self.bufLength)
        ret = np.frombuffer(buffer, dtype=dtype)
        ret.shape = shape
        return ret

    def configure(self, attr_dict=None):
        """Reconfigure and Reinitialize the DMA IP.

        Uses a user provided dict to reinitialize the DMA.
        This method also frees the internal buffer
        associated with current object.

        The keys in `attr_dict` should exactly match the ones used in default
        config. All the keys are not required. The default configuration is
        defined in self.DefaultConfig dict. Users can reinitialize the DMA
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
        self.__init__(self.phyAddress, self.direction, attr_dict)


class _DMAChannel:
    """Drives a single channel of the Xilinx AXI DMA

    This driver is designed to be used in conjunction with the
    `Xlnk.cma_array` method of memory allocation. The channel has
    main functions `transfer` and `wait` which start and wait for
    the transfer to finish respectively. If interrupts are enabled
    there is also a `wait_async` coroutine.

    This class should not be constructed directly, instead used
    through the AxiDMA class.

    """
    def __init__(self, mmio, offset, interrupt=None):
        self._mmio = mmio
        self._offset = offset
        self._interrupt = interrupt
        self.start()

    @property
    def running(self):
        """True if the DMA engine is currently running

        """
        return self._mmio.read(self._offset + 4) & 0x01 == 0x00

    @property
    def idle(self):
        """True if the DMA engine is idle

        `transfer` can only be called when the DMA is idle

        """
        return self._mmio.read(self._offset + 4) & 0x02 == 0x02

    def start(self):
        """Start the DMA engine if stopped

        """
        if self._interrupt:
            self._mmio.write(self._offset, 0x1001)
        else:
            self._mmio.write(self._offset, 0x0001)
        while not self.running:
            pass
        self._first_transfer = True

    def stop(self):
        """Stops the DMA channel and aborts the current transfer

        """
        self._mmio.write(self._offset, 0x0000)
        while self.running:
            pass

    def _clear_interrupt(self):
        self._mmio.write(self._offset + 4, 0x1000)

    def transfer(self, array):
        """Transfer memory with the DMA

        Transfer must only be called when the channel is idle.

        Parameters
        ----------
        array : ContiguousArray
            An xlnk allocated array to be transferred

        """
        if not self.running:
            raise RuntimeError('DMA channel not started')
        if not self.idle and not self._first_transfer:
            raise RuntimeError('DMA channel not idle')
        self._mmio.write(self._offset + 0x18, array.physical_address)
        self._mmio.write(self._offset + 0x28, array.nbytes)
        self._first_transfer = False

    def wait(self):
        """Wait for the transfer to complete

        """
        if not self.running:
            raise RuntimeError('DMA channel not started')
        while not self.idle:
            pass

    async def wait_async(self):
        """Wait for the transfer to complete

        """
        if not self.running:
            raise RuntimeError('DMA channel not started')
        while not self.idle:
            await self._interrupt.wait()
        self._clear_interrupt()


class DMA(DefaultIP):
    """Class for Interacting with the AXI Simple DMA Engine

    This class provides two attributes for the read and write channels.
    The read channel copies data from the stream into memory and
    the write channel copies data from memory to the output stream.
    Both channels have an identical API consisting of `transfer` and
    `wait` functions. If interrupts have been enabled and connected
    for the DMA engine then `wait_async` is also present.

    Buffers to be transferred must be allocated through the Xlnk driver
    using the cma_array function either directly or indirectly. This
    means that Frames from the video subsystem can be transferred using
    this class.

    Attributes
    ----------
    recvchannel : _DMAChannel
        The stream to memory channel
    sendchannel : _DMAChannel
        The memory to stream channel

    """
    def __init__(self, description, *args, **kwargs):
        """Create an instance of the DMA Driver

        Parameters
        ----------
        description : dict
            The entry in the IP dict describing the DMA engine

        """
        if type(description) is not dict or args or kwargs:
            raise RuntimeError('You appear to want the old DMA driver which '
                               'has been deprecated and moved to '
                               'pynq.lib.deprecated')
        super().__init__(description=description)
        if 'mm2s_introut' in description['interrupts']:
            self.sendchannel = _DMAChannel(self.mmio, 0x0, self.mm2s_introut)
        else:
            self.sendchannel = _DMAChannel(self.mmio, 0x0)

        if 's2mm_introut' in description['interrupts']:
            self.recvchannel = _DMAChannel(self.mmio, 0x30, self.s2mm_introut)
        else:
            self.recvchannel = _DMAChannel(self.mmio, 0x30)

    bindto = ['xilinx.com:ip:axi_dma:7.1']
