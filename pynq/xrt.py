"""
 Copyright (C) 2018 Xilinx, Inc
 Author(s): Ryan Radjabi
            Shivangi Agarwal
            Sonal Santan
 ctypes based Python binding for XRT

 Licensed under the Apache License, Version 2.0 (the "License"). You may
 not use this file except in compliance with the License. A copy of the
 License is located at

     http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
 WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
 License for the specific language governing permissions and limitations
 under the License.
"""

import os
import ctypes
from .xclbin import *

if 'XILINX_XRT' in os.environ:
    if "XCL_EMULATION_MODE" in os.environ:
        emu_mode = os.environ['XCL_EMULATION_MODE']
        if emu_mode == "hw_emu":
            libc = ctypes.CDLL(os.environ['XILINX_XRT'] + "/lib/libxrt_hwemu.so")
            XRT_EMULATION = True
        else:
            raise RuntimeError("Unknown Emulation Mode: " + emu_mode)
    else:
        libc = ctypes.CDLL(os.environ['XILINX_XRT'] + "/lib/libxrt_core.so")
        XRT_EMULATION = False
else:
    libc = None

xclDeviceHandle = ctypes.c_void_p

class xclDeviceInfo2(ctypes.Structure):
    # "_fields_" is a required keyword
    _fields_ = [
     ("mMagic", ctypes.c_uint),
     ("mName", ctypes.c_char*256),
     ("mHALMajorVersion", ctypes.c_ushort),
     ("mHALMinorVersion", ctypes.c_ushort),
     ("mVendorId", ctypes.c_ushort),
     ("mDeviceId", ctypes.c_ushort),
     ("mSubsystemId", ctypes.c_ushort),
     ("mSubsystemVendorId", ctypes.c_ushort),
     ("mDeviceVersion", ctypes.c_ushort),
     ("mDDRSize", ctypes.c_size_t),
     ("mDataAlignment", ctypes.c_size_t),
     ("mDDRFreeSize", ctypes.c_size_t),
     ("mMinTransferSize", ctypes.c_size_t),
     ("mDDRBankCount", ctypes.c_ushort),
     ("mOCLFrequency", ctypes.c_ushort*4),
     ("mPCIeLinkWidth", ctypes.c_ushort),
     ("mPCIeLinkSpeed", ctypes.c_ushort),
     ("mDMAThreads", ctypes.c_ushort),
     ("mOnChipTemp", ctypes.c_short),
     ("mFanTemp", ctypes.c_short),
     ("mVInt", ctypes.c_ushort),
     ("mVAux", ctypes.c_ushort),
     ("mVBram", ctypes.c_ushort),
     ("mCurrent", ctypes.c_float),
     ("mNumClocks", ctypes.c_ushort),
     ("mFanSpeed", ctypes.c_ushort),
     ("mMigCalib", ctypes.c_bool),
     ("mXMCVersion", ctypes.c_ulonglong),
     ("mMBVersion", ctypes.c_ulonglong),
     ("m12VPex", ctypes.c_short),
     ("m12VAux", ctypes.c_short),
     ("mPexCurr", ctypes.c_ulonglong),
     ("mAuxCurr", ctypes.c_ulonglong),
     ("mFanRpm", ctypes.c_ushort),
     ("mDimmTemp", ctypes.c_ushort*4),
     ("mSE98Temp", ctypes.c_ushort*4),
     ("m3v3Pex", ctypes.c_ushort),
     ("m3v3Aux", ctypes.c_ushort),
     ("mDDRVppBottom",ctypes.c_ushort),
     ("mDDRVppTop", ctypes.c_ushort),
     ("mSys5v5", ctypes.c_ushort),
     ("m1v2Top", ctypes.c_ushort),
     ("m1v8Top", ctypes.c_ushort),
     ("m0v85", ctypes.c_ushort),
     ("mMgt0v9", ctypes.c_ushort),
     ("m12vSW", ctypes.c_ushort),
     ("mMgtVtt", ctypes.c_ushort),
     ("m1v2Bottom", ctypes.c_ushort),
     ("mDriverVersion, ", ctypes.c_ulonglong),
     ("mPciSlot", ctypes.c_uint),
     ("mIsXPR", ctypes.c_bool),
     ("mTimeStamp", ctypes.c_ulonglong),
     ("mFpga", ctypes.c_char*256),
     ("mPCIeLinkWidthMax", ctypes.c_ushort),
     ("mPCIeLinkSpeedMax", ctypes.c_ushort),
     ("mVccIntVol", ctypes.c_ushort),
     ("mVccIntCurr", ctypes.c_ushort),
     ("mNumCDMA", ctypes.c_ushort)
    ]

class xclMemoryDomains:
    XCL_MEM_HOST_RAM    = 0
    XCL_MEM_DEVICE_RAM  = 1
    XCL_MEM_DEVICE_BRAM = 2
    XCL_MEM_SVM         = 3
    XCL_MEM_CMA         = 4
    XCL_MEM_DEVICE_REG  = 5

class xclDDRFlags:
    XCL_DEVICE_RAM_BANK0 = 0
    XCL_DEVICE_RAM_BANK1 = 2
    XCL_DEVICE_RAM_BANK2 = 4
    XCL_DEVICE_RAM_BANK3 = 8

class xclBOKind:
    XCL_BO_SHARED_VIRTUAL           = 0
    XCL_BO_SHARED_PHYSICAL          = 1
    XCL_BO_MIRRORED_VIRTUAL         = 2
    XCL_BO_DEVICE_RAM               = 3
    XCL_BO_DEVICE_BRAM              = 4
    XCL_BO_DEVICE_PREALLOCATED_BRAM = 5

class xclBOSyncDirection:
    XCL_BO_SYNC_BO_TO_DEVICE   = 0
    XCL_BO_SYNC_BO_FROM_DEVICE = 1

class xclAddressSpace:
    XCL_ADDR_SPACE_DEVICE_FLAT    = 0  # Absolute address space
    XCL_ADDR_SPACE_DEVICE_RAM     = 1  # Address space for the DDR memory
    XCL_ADDR_KERNEL_CTRL          = 2  # Address space for the OCL Region control port
    XCL_ADDR_SPACE_DEVICE_PERFMON = 3  # Address space for the Performance monitors
    XCL_ADDR_SPACE_DEVICE_CHECKER = 5  # Address space for protocol checker
    XCL_ADDR_SPACE_MAX = 8

class xclVerbosityLevel:
    XCL_QUIET = 0
    XCL_INFO  = 1
    XCL_WARN  = 2
    XCL_ERROR = 3

class xclResetKind:
    XCL_RESET_KERNEL = 0
    XCL_RESET_FULL   = 1
    XCL_USER_RESET   = 2

class xclDeviceUsage (ctypes.Structure):
    _fields_ = [
     ("h2c", ctypes.c_size_t*8),
     ("c2h", ctypes.c_size_t*8),
     ("ddeMemUsed", ctypes.c_size_t*8),
     ("ddrBOAllocated", ctypes.c_uint *8),
     ("totalContents", ctypes.c_uint),
     ("xclbinId", ctypes.c_ulonglong),
     ("dma_channel_cnt", ctypes.c_uint),
     ("mm_channel_cnt", ctypes.c_uint),
     ("memSize", ctypes.c_ulonglong*8)
    ]

class xclBOProperties (ctypes.Structure):
    _fields_ = [
     ("handle", ctypes.c_uint),
     ("flags" , ctypes.c_uint),
     ("size", ctypes.c_ulonglong),
     ("paddr", ctypes.c_ulonglong),
     ("domain", ctypes.c_uint),
    ]

def xclProbe():
    """
    xclProbe() - Enumerate devices found in the system
    :return: count of devices found
    """
    return libc.xclProbe()

def xclVersion():
    """
    :return: the version number. 1 => Hal1 ; 2 => Hal2
    """
    return libc.xclVersion()

def xclOpen(deviceIndex, logFileName, level):
    """
    xclOpen(): Open a device and obtain its handle

    :param deviceIndex: (unsigned int) Slot number of device 0 for first device, 1 for the second device...
    :param logFileName: (const char pointer) Log file to use for optional logging
    :param level: (int) Severity level of messages to log
    :return: device handle
    """
    libc.xclOpen.restype = ctypes.POINTER(xclDeviceHandle)
    libc.xclOpen.argtypes = [ctypes.c_uint, ctypes.c_char_p, ctypes.c_int]
    return libc.xclOpen(deviceIndex, logFileName, level)

def xclClose(handle):
    """
    xclClose(): Close an opened device

    :param handle: (xclDeviceHandle) device handle
    :return: None
    """
    libc.xclClose.restype = None
    libc.xclClose.argtype = xclDeviceHandle
    libc.xclClose(handle)

def xclResetDevice(handle, kind):
    """
    xclResetDevice() - Reset a device or its CL
    :param handle: Device handle
    :param kind: Reset kind
    :return: 0 on success or appropriate error number
    """
    libc.xclResetDevice.restype = ctypes.c_int
    libc.xclResetDevice.argtypes = [xclDeviceHandle, ctypes.c_int]
    libc.xclResetDevice(handle, kind)

def xclGetDeviceInfo2 (handle, info):
    """
    xclGetDeviceInfo2() - Obtain various bits of information from the device

    :param handle: (xclDeviceHandle) device handle
    :param info: (xclDeviceInfo pointer) Information record
    :return: 0 on success or appropriate error number
    """

    libc.xclGetDeviceInfo2.restype = ctypes.c_int
    libc.xclGetDeviceInfo2.argtypes = [xclDeviceHandle, ctypes.POINTER(xclDeviceInfo2)]
    return libc.xclGetDeviceInfo2(handle, info)

def xclGetUsageInfo (handle, info):
    """
    xclGetUsageInfo() - Obtain usage information from the device
    :param handle: Device handle
    :param info: Information record
    :return: 0 on success or appropriate error number
    """
    libc.xclGetUsageInfo.restype = ctypes.c_int
    libc.xclGetUsageInfo.argtypes = [xclDeviceHandle, ctypes.POINTER(xclDeviceInfo2)]
    return libc.xclGetUsageInfo(handle, info)

def xclGetErrorStatus(handle, info):
    """
    xclGetErrorStatus() - Obtain error information from the device
    :param handle: Device handle
    :param info: Information record
    :return: 0 on success or appropriate error number
    """
    libc.xclGetErrorStatus.restype = ctypes.c_int
    libc.xclGetErrorStatus.argtypes = [xclDeviceHandle, ctypes.POINTER(xclDeviceInfo2)]
    return libc.xclGetErrorStatus(handle, info)

def xclLoadXclBin(handle, buf):
    """
    Download FPGA image (xclbin) to the device

    :param handle: (xclDeviceHandle) device handle
    :param buf: (void pointer) Pointer to device image (xclbin) in memory
    :return: 0 on success or appropriate error number

    Download FPGA image (AXLF) to the device. The PR bitstream is encapsulated inside
    xclbin as a section. xclbin may also contains other sections which are suitably
    handled by the driver
    """
    libc.xclLoadXclBin.restype = ctypes.c_int
    libc.xclLoadXclBin.argtypes = [xclDeviceHandle, ctypes.c_void_p]
    return libc.xclLoadXclBin(handle, buf)

def xclGetSectionInfo(handle, info, size, kind, index):
    """
    xclGetSectionInfo() - Get Information from sysfs about the downloaded xclbin sections
    :param handle: Device handle
    :param info: Pointer to preallocated memory which will store the return value.
    :param size: Pointer to preallocated memory which will store the return size.
    :param kind: axlf_section_kind for which info is being queried
    :param index: The (sub)section index for the "kind" type.
    :return: 0 on success or appropriate error number
    """
    libc.xclGetSectionInfo.restype = ctypes.c_int
    libc.xclGetSectionInfo.argtypes = [xclDeviceHandle, ctypes.POINTER(xclDeviceInfo2),
                                       ctypes.POINTER(ctypes.sizeof(xclDeviceInfo2)),
                                       ctypes.c_int, ctypes.c_int]
    return libc.xclGetSectionInfo(handle, info, size, kind, index)

def xclReClock2(handle, region, targetFreqMHz):
    """
    xclReClock2() - Configure PR region frequencies
    :param handle: Device handle
    :param region: PR region (always 0)
    :param targetFreqMHz: Array of target frequencies in order for the Clock Wizards driving the PR region
    :return: 0 on success or appropriate error number
    """
    libc.xclReClock2.restype = ctypes.c_int
    libc.xclReClock2.argtypes = [xclDeviceHandle, ctypes.c_uint, ctypes.c_uint]
    return libc.xclReClock2(handle, region, targetFreqMHz)

def xclLockDevice(handle):
    """
    Get exclusive ownership of the device

    :param handle: (xclDeviceHandle) device handle
    :return: 0 on success or appropriate error number

    The lock is necessary before performing buffer migration, register access or bitstream downloads
    """
    libc.xclLockDevice.restype = ctypes.c_int
    libc.xclLockDevice.argtype = xclDeviceHandle
    return libc.xclLockDevice(handle)

def xclUnlockDevice(handle):
    """
    xclUnlockDevice() - Release exclusive ownership of the device

    :param handle: (xclDeviceHandle) device handle
    :return: 0 on success or appropriate error number
    """
    libc.xclUnlockDevice.restype = ctypes.c_int
    libc.xclUnlockDevice.argtype = xclDeviceHandle
    return libc.xclUnlockDevice(handle)

def xclOpenContext(handle, xclbinId, ipIndex, shared):
    """
    xclOpenContext() - Create shared/exclusive context on compute units
    :param handle: Device handle
    :param xclbinId: UUID of the xclbin image running on the device
    :param ipIndex: IP/CU index in the IP LAYOUT array
    :param shared: Shared access or exclusive access
    :return: 0 on success or appropriate error number

    The context is necessary before submitting execution jobs using xclExecBuf(). Contexts may be
    exclusive or shared. Allocation of exclusive contexts on a compute unit would succeed
    only if another client has not already setup up a context on that compute unit. Shared
    contexts can be concurrently allocated by many processes on the same compute units.
    """
    libc.xclOpenContext.restype = ctypes.c_int
    libc.xclOpenContext.argtypes = [xclDeviceHandle, ctypes.c_char_p, ctypes.c_uint, ctypes.c_bool]
    return libc.xclOpenContext(handle, xclbinId.bytes, ipIndex, shared)

def xclCloseContext(handle, xclbinId, ipIndex):
    """
    xclCloseContext() - Close previously opened context
    :param handle: Device handle
    :param xclbinId: UUID of the xclbin image running on the device
    :param ipIndex: IP/CU index in the IP LAYOUT array
    :return: 0 on success or appropriate error number

    Close a previously allocated shared/exclusive context for a compute unit.
    """
    libc.xclCloseContext.restype = ctypes.c_int
    libc.xclCloseContext.argtypes = [xclDeviceHandle, ctypes.c_char_p, ctypes.c_uint]
    return libc.xclCloseContext(handle, xclbinId.bytes, ipIndex)

def xclUpgradeFirmware(handle, fileName):
    """
    Update the device BPI PROM with new image
    :param handle: Device handle
    :param fileName:
    :return: 0 on success or appropriate error number
    """
    libc.xclUpgradeFirmware.restype = ctypes.c_int
    libc.xclUpgradeFirmware.argtypes = [xclDeviceHandle, ctypes.c_void_p]
    return libc.xclUpgradeFirmware(handle, fileName)

def xclUpgradeFirmware2(handle, file1, file2):
    """
    Update the device BPI PROM with new image with clearing bitstream
    :param handle: Device handle
    :param fileName:
    :return: 0 on success or appropriate error number
    """
    libc.xclUpgradeFirmware2.restype = ctypes.c_int
    libc.xclUpgradeFirmware2.argtypes = [xclDeviceHandle, ctypes.c_void_p, ctypes.c_void_p]
    return libc.xclUpgradeFirmware2(handle, file1, file2)

def xclUpgradeFirmwareXSpi (handle, fileName, index):
    """
    Update the device SPI PROM with new image
    :param handle:
    :param fileName:
    :param index:
    :return:
    """
    libc.xclUpgradeFirmwareXSpi.restype = ctypes.c_int
    libc.xclUpgradeFirmwareXSpi.argtypes = [xclDeviceHandle, ctypes.c_void_p, ctypes.c_int]
    return libc.xclUpgradeFirmwareXSpi(handle, fileName, index)

def xclBootFPGA(handle):
    """
    Boot the FPGA from PROM
    :param handle: Device handle
    :return: 0 on success or appropriate error number
    """
    libc.xclBootFPGA.restype = ctypes.c_int
    libc.xclBootFPGA.argtype = xclDeviceHandle
    return libc.xclBootFPGA(handle)

def xclRemoveAndScanFPGA():
    """
    Write to /sys/bus/pci/devices/<deviceHandle>/remove and initiate a pci rescan by
    writing to /sys/bus/pci/rescan.
    :return:
    """
    libc.xclRemoveAndScanFPGA.restype = ctypes.c_int
    return libc.xclRemoveAndScanFPGA()

def xclAllocBO(handle, size, domain, flags):
    """
    Allocate a BO of requested size with appropriate flags

    :param handle: (xclDeviceHandle) device handle
    :param size: (size_t) Size of buffer
    :param domain: (xclBOKind) Memory domain
    :param flags: (unsigned int) Specify bank information, etc
    :return: BO handle
    """
    libc.xclAllocBO.restype = ctypes.c_uint
    libc.xclAllocBO.argtypes = [xclDeviceHandle, ctypes.c_size_t, ctypes.c_int, ctypes.c_uint]
    return libc.xclAllocBO(handle, size, domain, flags)

def xclAllocUserPtrBO(handle, userptr, size, flags):
    """
    Allocate a BO using userptr provided by the user
    :param handle: Device handle
    :param userptr: Pointer to 4K aligned user memory
    :param size: Size of buffer
    :param flags: Specify bank information, etc
    :return: BO handle
    """
    libc.xclAllocUserPtrBO.restype = ctypes.c_uint
    libc.xclAllocUserPtrBO.argtypes = [xclDeviceHandle, ctypes.c_void_p, ctypes.c_size_t, ctypes.c_uint]
    return libc.xclAllocUserPtrBO(handle, userptr, size, flags)

def xclFreeBO(handle, boHandle):
    """
    Free a previously allocated BO

    :param handle: device handle
    :param boHandle: BO handle
    """
    libc.xclFreeBO.restype = None
    libc.xclFreeBO.argtypes = [xclDeviceHandle, ctypes.c_uint]
    libc.xclFreeBO(handle, boHandle)

def xclWriteBO(handle, boHandle, src, size, seek):
    """
    Copy-in user data to host backing storage of BO
    :param handle: Device handle
    :param boHandle: BO handle
    :param src: Source data pointer
    :param size: Size of data to copy
    :param seek: Offset within the BO
    :return: 0 on success or appropriate error number
    """
    libc.xclWriteBO.restype = ctypes.c_int
    libc.xclWriteBO.argtypes = [xclDeviceHandle, ctypes.c_uint, ctypes.c_void_p, ctypes.c_size_t, ctypes.c_size_t]
    return libc.xclWriteBO(handle, boHandle, src, size, seek)

def xclReadBO(handle, boHandle, dst, size, skip):
    """
    Copy-out user data from host backing storage of BO
    :param handle: Device handle
    :param boHandle: BO handle
    :param dst: Destination data pointer
    :param size: Size of data to copy
    :param skip: Offset within the BO
    :return: 0 on success or appropriate error number
    """
    libc.xclReadBO.restype = ctypes.c_int
    libc.xclReadBO.argtypes = [xclDeviceHandle, ctypes.c_uint, ctypes.c_void_p, ctypes.c_size_t, ctypes.c_size_t]
    return libc.xclReadBO(handle, boHandle, dst, size, skip)

def xclMapBO(handle, boHandle, write, buf_type='char', buf_size=1):
    """
    Memory map BO into user's address space

    :param handle: (xclDeviceHandle) device handle
    :param boHandle: (unsigned int) BO handle
    :param write: (boolean) READ only or READ/WRITE mapping
    :param buf_type: type of memory mapped buffer
    :param buf_size: size of buffer
    :return: (pointer) Memory mapped buffer

    Map the contents of the buffer object into host memory
    To unmap the buffer call POSIX unmap() on mapped void pointer returned from xclMapBO

    Return type void pointer doesn't get correctly binded in ctypes
    To map the buffer, explicitly specify the type and size of data
    """
    if buf_type == 'char':
        prop = xclBOProperties()
        xclGetBOProperties(handle, boHandle, prop)
        libc.xclMapBO.restype = ctypes.POINTER(ctypes.c_char * prop.size)

    elif buf_size == 1 and buf_type == 'int':
        libc.xclMapBO.restype = ctypes.POINTER(ctypes.c_int)

    elif buf_type == 'int':
        libc.xclMapBO.restype = ctypes.POINTER(ctypes.c_int * buf_size)
    else:
        print("ERROR: This data type is not supported ")

    libc.xclMapBO.argtypes = [xclDeviceHandle, ctypes.c_uint, ctypes.c_bool]
    ptr = libc.xclMapBO(handle, boHandle, write)
    return ptr

def xclSyncBO(handle, boHandle, direction, size, offset):
    """
    Synchronize buffer contents in requested direction

    :param handle: (xclDeviceHandle) device handle
    :param boHandle: (unsigned int) BO handle
    :param direction: (xclBOSyncDirection) To device or from device
    :param size: (size_t) Size of data to synchronize
    :param offset: (size_t) Offset within the BO
    :return: 0 on success or standard errno
    """
    libc.xclSyncBO.restype = ctypes.c_uint
    libc.xclSyncBO.argtypes = [xclDeviceHandle, ctypes.c_uint, ctypes.c_int, ctypes.c_size_t, ctypes.c_size_t]
    return libc.xclSyncBO(handle, boHandle, direction, size, offset)

def xclCopyBO(handle, dstBoHandle, srcBoHandle, size, dst_offset, src_offset):
    """
    Copy device buffer contents to another buffer
    :param handle: Device handle
    :param dstBoHandle: Destination BO handle
    :param srcBoHandle: Source BO handle
    :param size: Size of data to synchronize
    :param dst_offset: dst  Offset within the BO
    :param src_offset: src  Offset within the BO
    :return: 0 on success or standard errno
    """
    libc.xclCopyBO.restype = ctypes.c_int
    libc.xclCopyBO.argtypes = [xclDeviceHandle, ctypes.c_uint, ctypes.c_uint, ctypes.c_size_t, ctypes.c_size_t,
                               ctypes.c_uint]
    libc.xclCopyBO(handle, dstBoHandle, srcBoHandle, size, dst_offset, src_offset)

def xclExportBO(handle, boHandle):
    """
    Obtain DMA-BUF file descriptor for a BO
    :param handle: Device handle
    :param boHandle: BO handle which needs to be exported
    :return: File handle to the BO or standard errno
    """
    libc.xclExportBO.restype = ctypes.c_int
    libc.xclExportBO.argtypes = [xclDeviceHandle, ctypes.c_uint]
    return libc.xclExportBO(handle, boHandle)

def xclImportBO(handle, fd, flags):
    """
    Obtain BO handle for a BO represented by DMA-BUF file descriptor
    :param handle: Device handle
    :param fd: File handle to foreign BO owned by another device which needs to be imported
    :param flags: Unused
    :return: BO handle of the imported BO

    Import a BO exported by another device.
    This operation is backed by Linux DMA-BUF framework
    """
    libc.xclImportBO.restype = ctypes.c_int
    libc.xclImportBO.argtypes = [xclDeviceHandle, ctypes.c_int, ctypes.c_uint]
    libc.xclImportBO(handle, fd, flags)

def xclGetBOProperties(handle, boHandle, properties):
    """
    Obtain xclBOProperties struct for a BO

    :param handle: (xclDeviceHandle) device handle
    :param boHandle: (unsigned int) BO handle
    :param properties: BO properties struct pointer
    :return: 0 on success
    """
    libc.xclGetBOProperties.restype = ctypes.c_int
    libc.xclGetBOProperties.argtypes = [xclDeviceHandle, ctypes.c_uint, ctypes.POINTER(xclBOProperties)]
    return libc.xclGetBOProperties(handle, boHandle, properties)

def xclAllocDeviceBuffer(handle, size):
    """
    Allocate a buffer on the device
    :param handle: Device handle
    :param size: Size of buffer
    :return: Physical address of buffer on device or 0xFFFFFFFFFFFFFFFF in case of failure
    """
    libc.xclAllocDeviceBuffer.restype = ctypes.c_uint64
    libc.xclAllocDeviceBuffer.argtypes = [xclDeviceHandle, ctypes.c_size_t]
    return libc.xclAllocDeviceBuffer(handle, size)

def xclAllocDeviceBuffer2(handle, size, domain, flags):
    """
    Allocate a buffer on the device on a specific DDR
    :param handle: Device handle
    :param size: Size of buffer
    :param domain: Memory domain
    :param flags: Desired DDR bank as a bitmap.
    :return: Physical address of buffer on device or 0xFFFFFFFFFFFFFFFF in case of failure
    """
    libc.xclAllocDeviceBuffer2.restype = ctypes.c_uint64
    libc.xclAllocDeviceBuffer2.argtypes = [xclDeviceHandle, ctypes.c_size_t, ctypes.c_int, ctypes.c_uint]
    return libc.xclAllocDeviceBuffer2(handle, size, domain, flags)

def xclFreeDeviceBuffer(handle, buf):
    """
    Free a previously buffer on the device
    :param handle: Device handle
    :param buf: Physical address of buffer
    :return:
    """
    libc.xclFreeDeviceBuffer.restype = None
    libc.xclFreeDeviceBuffer.argtypes = [xclDeviceHandle, ctypes.c_uint64]
    return libc.xclFreeDeviceBuffer(handle, buf)

def xclCopyBufferHost2Device(handle, dest, src, size, seek):
    """
    Write to device memory
    :param handle: Device handle
    :param dest: Physical address in the device
    :param src: Source buffer pointer
    :param size: Size of data to synchronize
    :param seek: Seek within the segment pointed to physical address
    :return: Size of data moved or standard error number
    """
    libc.xclCopyBufferHost2Device.restype = ctypes.c_size_t
    libc.xclCopyBufferHost2Device.argtypes = [xclDeviceHandle, ctypes.c_uint64, ctypes.c_void_p, ctypes.c_size_t]
    return libc.xclCopyBufferHost2Device(handle, dest, src, size, seek)

def xclCopyBufferDevice2Host(handle, dest, src, size, skip):
    """
    Read from device memory
    :param handle: Device handle
    :param dest: Destination buffer pointer
    :param src: Physical address in the device
    :param size: Size of data to synchronize
    :param skip: Skip within the segment pointed to physical address
    :return: Size of data moved or standard error number
    """
    libc.xclCopyBufferDevice2Host.restype = ctypes.c_size_t
    libc.xclCopyBufferDevice2Host.argtypes = [xclDeviceHandle, ctypes.c_void_p, ctypes.c_uint64, ctypes.c_size_t]
    return libc.xclCopyBufferDevice2Host(handle, dest, src, size, skip)

def xclUnmgdPread(handle, flags, buf, size, offeset):
    """
    Perform unmanaged device memory read operation
    :param handle: Device handle
    :param flags: Unused
    :param buf: Destination data pointer
    :param size: Size of data to copy
    :param offeset: Absolute offset inside device
    :return: size of bytes read or appropriate error number

    This API may be used to perform DMA operation from absolute location specified. Users
    may use this if they want to perform their own device memory management -- not using the buffer
    object (BO) framework defined before.
    """
    libc.xclUnmgdPread.restype = ctypes.c_size_t
    libc.xclUnmgdPread.argtypes = [xclDeviceHandle, ctypes.c_uint, ctypes.c_void_p, ctypes.c_size_t, ctypes.c_uint64]
    return libc.xclUnmgdPread(handle, flags, buf, size, offeset)

def xclUnmgdPwrite(handle, flags, buf, size, offset):
    """
    Perform unmanaged device memory write operation
    :param handle: Device handle
    :param flags: Unused
    :param buf: Destination data pointer
    :param size: Size of data to copy
    :param offeset: Absolute offset inside device
    :return: size of bytes read or appropriate error number

    This API may be used to perform DMA operation from absolute location specified. Users
    may use this if they want to perform their own device memory management -- not using the buffer
    object (BO) framework defined before.
    """
    libc.xclUnmgdPwrite.restype = ctypes.c_size_t
    libc.xclUnmgdPwrite.argtypes = [xclDeviceHandle, ctypes.c_uint, ctypes.c_void_p, ctypes.c_size_t, ctypes.c_uint64]
    return libc.xclUnmgdPwrite(handle, flags, buf, size, offset)

def xclWrite(handle, space, offset, hostBuf, size):
    """
    Perform register write operation
    :param handle:  Device handle
    :param space: Address space
    :param offset: Offset in the address space
    :param hostBuf: Source data pointer
    :param size: Size of data to copy
    :return: size of bytes written or appropriate error number

    This API may be used to write to device registers exposed on PCIe BAR. Offset is relative to the
    the address space. A device may have many address spaces.
    This API will be deprecated in future. Please use this API only for IP bringup/debugging. For
    execution management please use XRT Compute Unit Execution Management APIs defined below
    """
    libc.xclWrite.restype = ctypes.c_size_t
    libc.xclWrite.argtypes = [xclDeviceHandle, ctypes.c_int, ctypes.c_uint64, ctypes.c_void_p, ctypes.c_size_t]
    return libc.xclWrite(handle, space, offset, hostBuf, size)

def xclRead(handle, space, offset, hostBuf, size):
    """
    Perform register write operation
    :param handle:  Device handle
    :param space: Address space
    :param offset: Offset in the address space
    :param hostBuf: Destination data pointer
    :param size: Size of data to copy
    :return: size of bytes written or appropriate error number

    This API may be used to write to device registers exposed on PCIe BAR. Offset is relative to the
    the address space. A device may have many address spaces.
    This API will be deprecated in future. Please use this API only for IP bringup/debugging. For
    execution management please use XRT Compute Unit Execution Management APIs defined below
    """
    libc.xclRead.restype = ctypes.c_size_t
    libc.xclRead.argtypes = [xclDeviceHandle, ctypes.c_int, ctypes.c_uint64, ctypes.c_void_p, ctypes.c_size_t]
    return libc.xclRead(handle, space, offset, hostBuf, size)

def xclExecBuf(handle, cmdBO):
    """
    xclExecBuf() - Submit an execution request to the embedded (or software) scheduler
    :param handle: Device handle
    :param cmdBO: BO handle containing command packet
    :return: 0 or standard error number

    Submit an exec buffer for execution. The exec buffer layout is defined by struct ert_packet
    which is defined in file *ert.h*. The BO should been allocated with DRM_XOCL_BO_EXECBUF flag.
    """
    libc.xclExecBuf.restype = ctypes.c_int
    libc.xclExecBuf.argtypes = [xclDeviceHandle, ctypes.c_uint]
    return libc.xclExecBuf(handle, cmdBO)

def xclExecBufWithWaitList(handle, cmdBO, num_bo_in_wait_list, bo_wait_list):
    """
    Submit an execution request to the embedded (or software) scheduler
    :param handle: Device handle
    :param cmdBO:BO handle containing command packet
    :param num_bo_in_wait_list: Number of BO handles in wait list
    :param bo_wait_list: BO handles that must complete execution before cmdBO is started
    :return:0 or standard error number

    Submit an exec buffer for execution. The BO handles in the wait
    list must complete execution before cmdBO is started.  The BO
    handles in the wait list must have beeen submitted prior to this
    call to xclExecBufWithWaitList.
    """
    libc.xclExecBufWithWaitList.restype = ctypes.c_int
    libc.xclExecBufWithWaitList.argtypes = [xclDeviceHandle, ctypes.c_uint, ctypes.c_size_t, ctypes.POINTER(ctypes.c_uint)]
    return libc.xclExecBufWithWaitList(handle, cmdBO, num_bo_in_wait_list, bo_wait_list)

def xclExecWait(handle, timeoutMilliSec):
    """
    xclExecWait() - Wait for one or more execution events on the device
    :param handle: Device handle
    :param timeoutMilliSec: How long to wait for
    :return:  Same code as poll system call

    Wait for notification from the hardware. The function essentially calls "poll" system
    call on the driver file handle. The return value has same semantics as poll system call.
    If return value is > 0 caller should check the status of submitted exec buffers
    """
    libc.xclExecWait.restype = ctypes.c_int
    libc.xclExecWait.argtypes = [xclDeviceHandle, ctypes.c_int]
    return libc.xclExecWait(handle, timeoutMilliSec)

def xclRegisterInterruptNotify(handle, userInterrupt, fd):
    """
    register *eventfdfile handle for a MSIX interrupt
    :param handle: Device handle
    :param userInterrupt: MSIX interrupt number
    :param fd: Eventfd handle
    :return: 0 on success or standard errno

    Support for non managed interrupts (interrupts from custom IPs). fd should be obtained from
    eventfd system call. Caller should use standard poll/read eventfd framework in order to wait for
    interrupts. The handles are automatically unregistered on process exit.
    """
    libc.xclRegisterInterruptNotify.restype = ctypes.c_int
    libc.xclRegisterInterruptNotify.argtypes = [xclDeviceHandle, ctypes.c_uint, ctypes.c_int]
    return libc.xclRegisterInterruptNotify(handle, userInterrupt, fd)

class xclStreamContextFlags:
    XRT_QUEUE_FLAG_POLLING = (1 << 2)

class xclQueueContext(ctypes.Structure):
    # structure to describe a Queue
    _fields_ = [
     ("type", ctypes.c_uint32),
     ("state", ctypes.c_uint32),
     ("route", ctypes.c_uint64),
     ("flow", ctypes.c_uint64),
     ("qsize", ctypes.c_uint32),
     ("desc_size", ctypes.c_uint32),
     ("flags", ctypes.c_uint64)
    ]

def xclCreateWriteQueue(handle, q_ctx, q_hdl):
    """
    Create Write Queue
    :param handle:Device handle
    :param q_ctx:Queue Context
    :param q_hdl:Queue handle
    :return:

    This is used to create queue based on information provided in Queue context. Queue handle is generated if creation
    successes.
    This feature will be enabled in a future release.
    """
    libc.xclCreateWriteQueue.restype = ctypes.c_int
    libc.xclCreateWriteQueue.argtypes = [xclDeviceHandle, ctypes.POINTER(xclQueueContext), ctypes.c_uint64]
    return libc.xclCreateWriteQueue(handle, q_ctx, q_hdl)

def xclCreateReadQueue(handle, q_ctx, q_hdl):
    """
    Create Read Queue
    :param handle:Device handle
    :param q_ctx:Queue Context
    :param q_hdl:Queue handle
    :return:

    This is used to create queue based on information provided in Queue context. Queue handle is generated if creation
    successes.
    This feature will be enabled in a future release.
    """
    libc.xclCreateReadQueue.restype = ctypes.c_int
    libc.xclCreateReadQueue.argtypes = [xclDeviceHandle, ctypes.POINTER(xclQueueContext), ctypes.c_uint64]
    return libc.xclCreateReadQueue(handle, q_ctx, q_hdl)


def xclAllocQDMABuf(handle, size, buf_hdl):
    """
    Allocate DMA buffer
    :param handle: Device handle
    :param size: Buffer handle
    :param buf_hdl: Buffer size
    :return: buffer pointer

    These functions allocate and free DMA buffers which is used for queue read and write.
    This feature will be enabled in a future release.
    """
    libc.xclAllocQDMABuf.restypes = ctypes.c_void_p
    libc.xclAllocQDMABuf.argtypes = [xclDeviceHandle, ctypes.c_size_t, ctypes.c_uint64]
    return libc.xclAllocQDMABuf(handle, size, buf_hdl)

def xclFreeQDMABuf(handle, buf_hdl):
    """
    Allocate DMA buffer
    :param handle: Device handle
    :param size: Buffer handle
    :param buf_hdl: Buffer size
    :return: buffer pointer

    These functions allocate and free DMA buffers which is used for queue read and write.
    This feature will be enabled in a future release.
    """
    libc.xclFreeQDMABuf.restypes = ctypes.c_int
    libc.xclFreeQDMABuf.argtypes = [xclDeviceHandle, ctypes.c_uint64]
    return libc.xclFreeQDMABuf(handle, buf_hdl)

def xclDestroyQueue(handle, q_hdl):
    """
    Destroy Queue
    :param handle: Device handle
    :param q_hdl: Queue handle

    This function destroy Queue and release all resources. It returns -EBUSY if Queue is in running state.
    This feature will be enabled in a future release.
    """
    libc.xclDestroyQueue.restypes = ctypes.c_int
    libc.xclDestroyQueue.argtypes = [xclDeviceHandle, ctypes.c_uint64]
    return libc.xclDestroyQueue(handle, q_hdl)

def xclModifyQueue(handle, q_hdl):
    """
    Modify Queue
    :param handle: Device handle
    :param q_hdl: Queue handle

    This function modifies Queue context on the fly. Modifying rid implies
    to program hardware traffic manager to connect Queue to the kernel pipe.
    """
    libc.xclModifyQueue.restypes = ctypes.c_int
    libc.xclModifyQueue.argtypes = [xclDeviceHandle, ctypes.c_uint64]
    return libc.xclModifyQueue(handle, q_hdl)

def xclStartQueue(handle, q_hdl):
    """
    set Queue to running state
    :param handle: Device handle
    :param q_hdl: Queue handle

    This function set xclStartQueue to running state. xclStartQueue starts to process Read and Write requests.
    """
    libc.xclStartQueue.restypes = ctypes.c_int
    libc.xclStartQueue.argtypes = [xclDeviceHandle, ctypes.c_uint64]
    return libc.xclStartQueue(handle, q_hdl)

def xclStopQueue(handle, q_hdl):
    """
    set Queue to init state
    :param handle: Device handle
    :param q_hdl: Queue handle

    This function set Queue to init state. all pending read and write requests will be flushed.
    wr_complete and rd_complete will be called with error wbe for flushed requests.
    """
    libc.xclStopQueue.restypes = ctypes.c_int
    libc.xclStopQueue.argtypes = [xclDeviceHandle, ctypes.c_uint64]
    return libc.xclStopQueue(handle, q_hdl)

class anonymous_union(ctypes.Union):
    _fields_ = [
        ("buf", ctypes.POINTER(ctypes.c_char)),
        ("va", ctypes.c_uint64)
    ]

class xclReqBuffer(ctypes.Structure):
    _fields_ = [
        ("anonymous_union", anonymous_union),
        ("len", ctypes.c_uint64),
        ("buf_hdl", ctypes.c_uint64),
    ]

class xclQueueRequestKind:
    XCL_QUEUE_WRITE = 0
    XCL_QUEUE_READ  = 1

class xclQueueRequestFlag:
    XCL_QUEUE_REQ_EOT         = 1 << 0
    XCL_QUEUE_REQ_CDH         = 1 << 1
    XCL_QUEUE_REQ_NONBLOCKING = 1 << 2
    XCL_QUEUE_REQ_SILENT      = 1 << 3

class xclQueueRequest(ctypes.Structure):
    _fields_ = [
        ("op_code", ctypes.c_int),
        ("bufs", ctypes.POINTER(xclReqBuffer)),
        ("buf_num", ctypes.c_uint32),
        ("cdh", ctypes.POINTER(ctypes.c_char)),
        ("cdh_len", ctypes.c_uint32),
        ("flag", ctypes.c_uint32),
        ("priv_data", ctypes.c_void_p),
        ("timeout", ctypes.c_uint32)
    ]

class xclReqCompletion(ctypes.Structure):
    _fields_ = [
        ("resv", ctypes.c_char*64),
        ("priv_data", ctypes.c_void_p),
        ("nbytes", ctypes.c_size_t),
        ("err_code", ctypes.c_int)
    ]

def xclWriteQueue(handle, q_hdl, wr_req):
    """
    write data to queue
    :param handle: Device handle
    :param q_hdl: Queue handle
    :param wr_req: write request
    :return:

     This function moves data from host memory. Based on the Queue type, data is written as stream or packet.
     Return: number of bytes been written or error code.
         stream Queue:
             There is not any Flag been added to mark the end of buffer.
             The bytes been written should equal to bytes been requested unless error happens.
         Packet Queue:
             There is Flag been added for end of buffer. Thus kernel may recognize that a packet is receviced.
     This function supports blocking and non-blocking write
         blocking:
             return only when the entire buf has been written, or error.
         non-blocking:
             return 0 immediatly.
         EOT:
             end of transmit signal will be added at last
         silent: (only used with non-blocking);
             No event generated after write completes
    """
    libc.xclWriteQueue.restype = ctypes.c_ssize_t
    libc.xclWriteQueue.argtypes = [xclDeviceHandle, ctypes.POINTER(xclQueueRequest)]
    return libc.xclWriteQueue(handle, q_hdl, wr_req)

def xclReadQueue(handle, q_hdl, wr_req):
    """
    write data to queue
    :param handle: Device handle
    :param q_hdl: Queue handle
    :param wr_req: write request
    :return:

     This function moves data to host memory. Based on the Queue type, data is read as stream or packet.
     Return: number of bytes been read or error code.
         stream Queue:
             read until all the requested bytes is read or error happens.
         blocking:
             return only when the requested bytes are read (stream) or the entire packet is read (packet)
         non-blocking:
             return 0 immidiately.
    """
    libc.xclReadQueue.restype = ctypes.c_ssize_t
    libc.xclReadQueue.argtypes = [xclDeviceHandle, ctypes.POINTER(xclQueueRequest)]
    return libc.xclReadQueue(handle, q_hdl, wr_req)

def xclPollCompletion(handle, min_compl, max_compl, comps, actual_compl, timeout):
    """
    for non-blocking read/write, check if there is any request been completed
    :param handle: device handle
    :param min_compl: unblock only when receiving min_compl completions
    :param max_compl: Max number of completion with one poll
    :param comps:
    :param actual_compl:
    :param timeout: timeout
    :return:
    """
    libc.xclPollCompletion.restype = ctypes.c_int
    libc.xclPollCompletion.argtypes = [xclDeviceHandle, ctypes.c_int, ctypes.c_int, ctypes.POINTER(xclReqCompletion),
                                       ctypes.POINTER(ctypes.c_int), ctypes.c_int]
    return libc.xclPollCompletion(handle, min_compl, max_compl, comps, actual_compl, timeout)

def xclWriteHostEvent(handle, type,id):
    """

    :param handle:
    :param type:
    :param id:
    :return:
    """
    libc.xclWriteHostEvent.restype = None
    libc.xclWriteHostEvent.argtypes = [xclDeviceHandle, ctypes.c_int, ctypes.c_int]
    return libc.xclWriteHostEvent(handle, type, id)

def xclGetDeviceTimestamp(handle):
    """

    :param handle:
    :return:
    """
    libc.xclGetDeviceTimestamp.restype = ctypes.c_size_t
    libc.xclGetDeviceTimestamp.argtype = xclDeviceHandle
    return libc.xclGetDeviceTimestamp(handle)

def xclGetDeviceClockFreqMHz(handle):
    """

    :param handle:
    :return:
    """
    libc.xclGetDeviceClockFreqMHz.restype = ctypes.c_double
    libc.xclGetDeviceClockFreqMHz.argtype = xclDeviceHandle
    return libc.xclGetDeviceClockFreqMHz(handle)

def xclGetReadMaxBandwidthMBps(handle):
    """

    :param handle:
    :return:
    """
    libc.xclGetReadMaxBandwidthMBps.restype = ctypes.c_double
    libc.xclGetReadMaxBandwidthMBps.argtype = xclDeviceHandle
    return libc.xclGetReadMaxBandwidthMBps(handle)

def xclGetWriteMaxBandwidthMBps(handle):
    """

    :param handle:
    :return:
    """
    libc.xclGetWriteMaxBandwidthMBps.restype = ctypes.c_double
    libc.xclGetWriteMaxBandwidthMBps.argtype = xclDeviceHandle
    return libc.xclGetWriteMaxBandwidthMBps(handle)

def xclSetProfilingNumberSlots(handle, type, numSlots):
    """

    :param handle:
    :param type:
    :param numSlots:
    :return:
    """
    libc.xclSetProfilingNumberSlots.restype = None
    libc.xclSetProfilingNumberSlots.argtypes = [xclDeviceHandle, ctypes.c_int, ctypes.c_uint32]
    libc.xclSetProfilingNumberSlots(handle, type, numSlots)

def xclGetProfilingNumberSlots(handle, type):
    """

    :param handle:
    :param type:
    :return:
    """
    libc.xclGetProfilingNumberSlots.restype = ctypes.c_uint32
    libc.xclGetProfilingNumberSlots.argtypes = [xclDeviceHandle, ctypes.c_int]
    return libc.xclGetProfilingNumberSlots(handle, type)

def xclGetProfilingSlotName(handle, type, slotnum, slotName, length):
    """

    :param handle:
    :param type:
    :param slotnum:
    :param slotName:
    :param length:
    :return:
    """
    libc.xclGetProfilingSlotName.restype = None
    libc.xclGetProfilingSlotName.argtypes = [xclDeviceHandle, ctypes.c_int, ctypes.c_uint32,
                                             ctypes.POINTER(ctypes.c_char), ctypes.c_uint32]
    return libc.xclGetProfilingSlotName(handle, type, slotnum, slotName, length)

def xclGetProfilingSlotProperties(handle, type, slotnum):
    """

    :param handle:
    :param type:
    :param slotnum:
    :return:
    """
    libc.xclGetProfilingSlotProperties.restype = ctypes.c_uint32
    libc.xclGetProfilingSlotProperties.argtypes = [xclDeviceHandle, ctypes.c_int, ctypes.c_uint32]
    return libc.xclGetProfilingSlotProperties(handle, type, slotnum)

def xclPerfMonClockTraining(handle, type):
    """

    :param handle:
    :param type:
    :return:
    """
    libc.xclPerfMonClockTraining.restype = ctypes.c_size_t
    libc.xclPerfMonClockTraining.argtypes = [xclDeviceHandle, ctypes.c_int]
    return libc.xclPerfMonClockTraining(handle, type)

def xclPerfMonStartCounters(handle, type):
    """

    :param handle:
    :param type:
    :return:
    """
    libc.xclPerfMonStartCounters.restype = ctypes.c_size_t
    libc.xclPerfMonStartCounters.argtypes = [xclDeviceHandle, ctypes.c_int]
    return libc.xclPerfMonStartCounters(handle, type)

def xclPerfMonStopCounters(handle, type):
    """

    :param handle:
    :param type:
    :return:
    """
    libc.xclPerfMonStopCounters.restype = ctypes.c_size_t
    libc.xclPerfMonStopCounters.argtypes = [xclDeviceHandle, ctypes.c_int]
    return libc.xclPerfMonStopCounters(handle, type)

def xclPerfMonReadCounters(handle, type, counterResults):
    """

    :param handle:
    :param type:
    :param counterResults:
    :return:
    """
    libc.xclPerfMonReadCounters.restype = ctypes.c_size_t
    libc.xclPerfMonReadCounters.argtypes = [xclDeviceHandle, ctypes.c_int, ctypes.POINTER(xclcounterResults)]  # defined in xclperf.h not implemented in python yet
    return libc.xclPerfMonReadCounters(handle, type, counterResults)

def xclDebugReadIPStatus(handle, type, debugResults):
    """

    :param handle:
    :param type:
    :param debugResults:
    :return:
    """
    libc.xclDebugReadIPStatusrestype = ctypes.c_size_t
    libc.xclDebugReadIPStatus.argtypes = [xclDeviceHandle, ctypes.c_int, ctypes.c_void_p]
    return libc.xclDebugReadIPStatus(handle, type, debugResults)

def xclPerfMonStartTrace(handle, type, startTrigger):
    """

    :param handle:
    :param type:
    :param startTrigger:
    :return:
    """
    libc.xclPerfMonStartTrace.restype = ctypes.c_size_t
    libc.xclPerfMonStartTrace.argtypes = [xclDeviceHandle, ctypes.c_int, ctypes.c_uint32]
    return libc.xclPerfMonStartTrace(handle, type, startTrigger)

def xclPerfMonStopTrace(handle, type):
    """

    :param handle:
    :param type:
    :return:
    """
    libc.xclPerfMonStopTrace.restype = ctypes.c_size_t
    libc.xclPerfMonStopTrace.argtypes = [xclDeviceHandle, ctypes.c_int]
    return libc.xclPerfMonStopTrace(handle, type)

def xclPerfMonGetTraceCount(handle, type):
    """

    :param handle:
    :param type:
    :return:
    """
    libc.xclPerfMonGetTraceCount.restype = ctypes.c_size_t
    libc.xclPerfMonGetTraceCount.argtypes = [xclDeviceHandle, ctypes.c_int]
    return libc.xclPerfMonGetTraceCount(handle, type)

def xclPerfMonReadTrace(handle, type, traceVector):
    """

    :param handle:
    :param type:
    :param traceVector:
    :return:
    """
    libc.xclPerfMonReadTrace.restype = ctypes.c_size_t
    libc.xclPerfMonReadTrace.argtypes = [xclDeviceHandle, ctypes.c_int, ctypes.POINTER(xclTraceResultsVector)]  # defined in xclperf.h not implemented in python yet
    return libc.xclPerfMonReadTrace(handle, type, traceVector)

def xclMapMgmt(handle):
    """

    :param handle:
    :return:
    """
    libc.xclMapMgmt.restype = ctypes.POINTER(ctypes.c_char)
    libc.xclMapMgmt.argtype = xclDeviceHandle
    return libc.xclMapMgmt(handle)

def xclOpenMgmt(deviceIndex):
    """

    :param deviceIndex:
    :return:
    """
    libc.xclOpenMgmt.restype = xclDeviceHandle
    libc.xclOpenMgmt.argtype = ctypes.c_uint
    return libc.xclOpenMgmt(deviceIndex)
