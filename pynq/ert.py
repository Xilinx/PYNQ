"""
 Copyright (C) 2018 Xilinx, Inc
 Author(s): Ryan Radjabi
            Shivangi Agarwal
            Sonal Santan
 ctypes based Python binding for ert.h data structures

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

import ctypes
import os

if 'XILINX_XRT' in os.environ:
    libc = ctypes.CDLL(os.environ['XILINX_XRT'] + "/lib/libxrt_core.so")
else:
    libc = None

##  START OF ENUMS  ##

class ert_cmd_state:
    ERT_CMD_STATE_NEW        = 1
    ERT_CMD_STATE_QUEUED     = 2
    ERT_CMD_STATE_RUNNING    = 3
    ERT_CMD_STATE_COMPLETED  = 4
    ERT_CMD_STATE_ERROR      = 5
    ERT_CMD_STATE_ABORT      = 6
    ERT_CMD_STATE_SUBMITTED  = 7
    ERT_CMD_STATEIMEOUT      = 8
    ERT_CMD_STATE_NORESPONSE = 9

class ert_cmd_opcode:
    ERT_START_CU      = 0
    ERT_START_KERNEL  = 0
    ERT_CONFIGURE     = 2
    ERT_STOP          = 3
    ERT_ABORT         = 4
    ERT_WRITE         = 5
    ERT_CU_STAT       = 6
    ERT_START_COPYBO  = 7
    ERT_SK_CONFIG     = 8
    ERT_SK_START      = 9
    ERT_SK_UNCONFIG   = 10
    ERT_INIT_CU       = 11

class ert_cmd_type:
    ERT_DEFAULT   = 0
    ERT_KDS_LOCAL = 1
    ERT_CTRL      = 2
    ERT_CU        = 3

##  END OF ENUMS  ##

# struct ert_configure_cmd: ERT configure command format
#
# @state:           [3-0] current state of a command
# @count:           [22-12] number of words in payload (5 + num_cus)
# @opcode:          [27-23] 1, opcode for configure
# @type:            [31-27] 0, type of configure
#  *
# @slot_size:       command queue slot size
# @num_cus:         number of compute units in program
# @cu_shift:        shift value to convert CU idx to CU addr
# @cu_base_addr:    base address to add to CU addr for actual physical address
#
# @ert:1            enable embedded HW scheduler
# @polling:1        poll for command completion
# @cu_dma:1         enable CUDMA custom module for HW scheduler
# @cu_isr:1         enable CUISR custom module for HW scheduler
# @cq_int:1         enable interrupt from host to HW scheduler
# @cdma:1           enable CDMA kernel
# @unused:25
# @dsa52:1          reserved for internal use
#
# @data:            addresses of @num_cus CUs
class ert_cmd_struct(ctypes.Structure):
    _fields_ = [
        ("state", ctypes.c_uint32, 4),
        ("unused", ctypes.c_uint32, 8),
        ("count", ctypes.c_uint32, 11),
        ("opcode", ctypes.c_uint32, 5),
        ("type", ctypes.c_uint32, 4)
    ]

class uert(ctypes.Union):
    _fields_ = [
        ("m_cmd_struct", ert_cmd_struct),
        ("header", ctypes.c_uint32)
    ]

class ert_configure_features(ctypes.Structure):
    # features
    _fields_ = [
        ("ert", ctypes.c_uint32, 1),
        ("polling", ctypes.c_uint32, 1),
        ("cu_dma", ctypes.c_uint32, 1),
        ("cu_isr", ctypes.c_uint32, 1),
        ("cq_int", ctypes.c_uint32, 1),
        ("cdma", ctypes.c_uint32, 1),
        ("unusedf", ctypes.c_uint32, 25),
        ("dsa52", ctypes.c_uint32, 1),
    ]

class ert_configure_cmd(ctypes.Structure):
    _fields_ = [
        ("m_uert", uert),
        # payload
        ("slot_size", ctypes.c_uint32),
        ("num_cus", ctypes.c_uint32),
        ("cu_shift", ctypes.c_uint32),
        ("cu_base_addr", ctypes.c_uint32),
        ("m_features", ert_configure_features),
        ("data", ctypes.c_uint32*1)
    ]

# struct ert_start_kernel_cmd: ERT start kernel command format
#
# @state:           [3-0] current state of a command
# @extra_cu_masks:  [11-10] extra CU masks in addition to mandatory mask
# @count:           [22-12] number of words in payload (data)
# @opcode:          [27-23] 0, opcode for start_kernel
# @type:            [31-27] 0, type of start_kernel
#
# @cu_mask:         first mandatory CU mask
# @data:            count number of words representing command payload
#
# The packet payload is comprised of 1 mandatory CU mask plus
# extra_cu_masks per header field, followed a CU register map of size
# (count - (1 + extra_cu_masks)) uint32_t words.
class ert_start_cmd_struct(ctypes.Structure):
    _fields_ = [
        ("state", ctypes.c_uint32, 4),
        ("unused", ctypes.c_uint32, 6),
        ("extra_cu_masks", ctypes.c_uint32, 2),
        ("count", ctypes.c_uint32, 11),
        ("opcode", ctypes.c_uint32, 5),
        ("type", ctypes.c_uint32, 4)
    ]

class u_start_ert(ctypes.Union):
    _fields_ = [
        ("m_start_cmd_struct", ert_start_cmd_struct),
        ("header", ctypes.c_uint32)
    ]

class ert_start_kernel_cmd(ctypes.Structure):
    _fields_ = [
        ("m_uert", u_start_ert),

        # payload
        ("cu_mask", ctypes.c_uint32),
        ("data", ctypes.c_uint32*1)
    ]

# struct ert_packet: ERT generic packet format
#
# @state:   [3-0] current state of a command
# @custom:  [11-4] custom per specific commands
# @count:   [22-12] number of words in payload (data)
# @opcode:  [27-23] opcode identifying specific command
# @type:    [31-28] type of command (currently 0)
# @data:    count number of words representing packet payload
class ert_cmd(ctypes.Structure):
    _fields_ = [
        ("state", ctypes.c_uint32, 4),
        ("custom", ctypes.c_uint32, 8),
        ("count", ctypes.c_uint32, 11),
        ("opcode", ctypes.c_uint32, 5),
        ("type", ctypes.c_uint32, 4)
    ]

class u_ert(ctypes.Union):
    _fields_ = [
        ("m_cmd", ert_cmd),
        ("header", ctypes.c_uint32)
    ]

class ert_packet(ctypes.Structure):
    _fields_ = [
        ("u_ert", u_ert),
        ("data", ctypes.c_uint32*1)
    ]

# struct ert_abort_cmd: ERT abort command format.
# @idx: The slot index of command to abort
class ert_cmd_2(ctypes.Structure):
    _fields_ = [
        ("state", ctypes.c_uint32, 4),
        ("unused", ctypes.c_uint32, 8),
        ("idx", ctypes.c_uint32, 11),
        ("opcode", ctypes.c_uint32, 5),
        ("type", ctypes.c_uint32, 4)
    ]

class u_ert_2(ctypes.Union):
    _fields_ = [
        ("m_cmd", ert_cmd_2),
        ("header", ctypes.c_uint32)
    ]

class ert_abort_cmd(ctypes.Structure):
    _fields_ = [
        ("u_ert_2", u_ert_2)
    ]

# struct ert_init_kernel_cmd: ERT initialize kernel command format
# this command initializes CUs by writing CU registers. CUs are
# represented by cu_mask and extra_cu_masks.
#
# @state:           [3-0] current state of a command
# @extra_cu_masks:  [11-10] extra CU masks in addition to mandatory mask
# @count:           [22-12] number of words following header
# @opcode:          [27-23] 0, opcode for init_kernel
# @type:            [31-27] 0, type of init_kernel
#
# @cu_runimeout   the configured CU timeout value in Microseconds
#                   setting to 0 means CU should not timeout
# @cu_resetimeout the configured CU reset timeout value in Microseconds
#                   when CU timeout, CU will be reset. this indicates
#                   CU reset should be completed within the timeout value.
#                   if cu_runimeout is set to 0, this field is undefined.
#
# @cu_mask:         first mandatory CU mask
# @data:            count-9 number of words representing interpreted payload
class ert_init_kernel_cmd (ctypes.Structure):
     _fields_ = [
        ("u_ert", u_ert),
        ("cu_runimeout", ctypes.c_uint32),
        ("cu_resetimeout", ctypes.c_uint32),
        ("reserved", ctypes.c_uint32*6),
        #payload
        ("cu_mask", ctypes.c_uint32),
        ("data", ctypes.c_uint32*1),
    ]

class ert_start_copybo_cmd (ctypes.Structure):
    _fields_ = [
        ("state", ctypes.c_uint32, 4),
        ("unused", ctypes.c_uint32, 6),
        ("extra_cu_masks", ctypes.c_uint32, 2),
        ("count", ctypes.c_uint32, 11),
        ("opcode", ctypes.c_uint32, 5),
        ("type", ctypes.c_uint32, 4),
        ("cu_mask", ctypes.c_uint32*4),
        ("reserved", ctypes.c_uint32*4),
        ("src_addr_lo", ctypes.c_uint32),
        ("src_addr_hi", ctypes.c_uint32),
        ("src_bo_hdl", ctypes.c_uint32),
        ("dst_addr_lo", ctypes.c_uint32),
        ("dst_addr_hi", ctypes.c_uint32),
        ("dst_bo_hdl", ctypes.c_uint32),
        ("size", ctypes.c_uint32),
        ("arg", ctypes.c_void_p)
    ]

# struct ert_configure_sk_cmd: ERT configure soft kernel command format
# @state:           [3-0] current state of a command
# @count:           [22-12] number of words in payload (13 DWords)
# @opcode:          [27-23] 1, opcode for configure
# @type:            [31-27] 0, type of configure
# @start_cuidx:     start index of compute units
# @num_cus:         number of compute units in program
# @sk_size:         size in bytes of soft kernel image
# @sk_name:         symbol name of soft kernel
# @sk_addr:         soft kernel image's physical address (little endian)
class ert_configure_sk_cmd (ctypes.Structure):
     _fields_ = [
        ("u_ert", u_ert),
        #payload
        ("start_cuidx", ctypes.c_uint32),
        ("num_cus", ctypes.c_uint32),
        ("sk_size", ctypes.c_uint32),
        ("sk_name", ctypes.c_uint32*8),
        ("sk_addr", ctypes.c_uint32*1),
    ]

# struct ert_unconfigure_sk_cmd: ERT unconfigure soft kernel command format
#
# @state:           [3-0] current state of a command
# @count:           [22-12] number of words in payload
# @opcode:          [27-23] 1, opcode for configure
# @type:            [31-27] 0, type of configure
#
# @start_cuidx:     start index of compute units
# @num_cus:         number of compute units in program
class ert_unconfigure_sk_cmd (ctypes.Structure):
     _fields_ = [
        ("u_ert", u_ert),
        #payload
        ("start_cuidx", ctypes.c_uint32),
        ("num_cus", ctypes.c_uint32)
    ]

# Helper functions to hide details of ert_start_copybo_cmd
def ert_fill_copybo_cmd(pkt, src_bo, dst_bo, src_offset, dst_offset, size):
    libc.ert_fill_copybo_cmd.restype = None
    libc.ert_fill_copybo_cmd.argtypes = [ctypes.POINTER(ert_start_copybo_cmd), ctypes.c_uint32, ctypes.c_uint32, 
                                            ctypes.c_uint64, ctypes.c_uint64, ctypes.c_uint64]
    return libc.ert_fill_copybo_cmd(pkt, src_bo, dst_bo, src_offset, dst_offset, size)

def ert_copybo_src_offset(pkt):
    libc.ert_copybo_src_offset.restype = ctypes.c_uint64
    libc.ert_copybo_src_offset.argtype = ctypes.POINTER(ert_start_copybo_cmd)
    return libc.ert_copybo_src_offset(pkt)    

def ert_copybo_dst_offset(pkt):
    libc.ert_copybo_dst_offset.restype = ctypes.c_uint64
    libc.ert_copybo_dst_offset.argtype = ctypes.POINTER(ert_start_copybo_cmd)
    return libc.ert_copybo_dst_offset(pkt) 

def ert_copybo_size(pkt):
    libc.ert_copybo_size.restype = ctypes.c_uint64
    libc.ert_copybo_size.argtype = ctypes.POINTER(ert_start_copybo_cmd)
    return libc.ert_copybo_size(pkt) 
