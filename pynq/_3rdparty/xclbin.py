"""
 Copyright (C) 2018 Xilinx, Inc
 Author(s): Ryan Radjabi
            Shivangi Agarwal
            Sonal Santan
 ctypes based Python binding for xclbin.h data structures

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

"""
    AXLF LAYOUT
    -----------

    -----------------------------------------
    | Magic                                 |
    -----------------------------------------
    | Header                                |
    -----------------------------------------
    | One or more section headers           |
    -----------------------------------------
    | Matching number of sections with data |
    -----------------------------------------
"""


class AXLF_SECTION_KIND:
    BITSTREAM            = 0
    CLEARING_BITSTREAM   = 1
    EMBEDDED_METADATA    = 2
    FIRMWARE             = 3
    DEBUG_DATA           = 4
    SCHED_FIRMWARE       = 5
    MEM_TOPOLOGY         = 6
    CONNECTIVITY         = 7
    IP_LAYOUT            = 8
    DEBUG_IP_LAYOUT      = 9
    DESIGN_CHECK_POINT  = 10
    CLOCK_FREQ_TOPOLOGY = 11
    MCS                 = 12
    BMC                 = 13
    BUILD_METADATA      = 14
    KEYVALUE_METADATA   = 15
    USER_METADATA       = 16
    DNA_CERTIFICATE     = 17

class MEM_TYPE:
    MEM_DDR3              = 0
    MEM_DDR4              = 1
    MEM_DRAM              = 2
    MEM_STREAMING         = 3
    MEM_PREALLOCATED_GLOB = 4
    MEM_ARE               = 5
    MEM_HBM               = 6
    MEM_BRAM              = 7
    MEM_URAM              = 8

class IP_TYPE:
    IP_MB              = 0
    IP_KERNEL          = 1
    instance           = 2
    IP_DNASC           = 3
    IP_DDR4_CONTROLLER = 4

class XCLBIN_MODE:
    XCLBIN_FLAT                  = 1
    XCLBIN_PR                    = 2
    XCLBIN_TANDEM_STAGE2         = 3
    XCLBIN_TANDEM_STAGE2_WITH_PR = 4
    XCLBIN_HW_EMU                = 5
    XCLBIN_SW_EMU                = 6
    XCLBIN_MODE_MAX              = 7

class axlf_section_header (ctypes.Structure):
    _fields_ = [
        ("m_sectionKind", ctypes.c_uint32),
        ("m_sectionName", ctypes.c_char*16),
        ("m_sectionOffset", ctypes.c_uint64),
        ("m_sectionSize", ctypes.c_uint64)
    ]

class s1 (ctypes.Structure):
    _fields_ = [
        ("m_platformId", ctypes.c_uint64),
        ("m_featureId", ctypes.c_uint64)
    ]

class u1 (ctypes.Union):
    _fields_ = [
        ("rom", s1),
        ("rom_uuid", ctypes.c_ubyte*16)
    ]

class u2 (ctypes.Union):
    _fields_ = [
        ("m_next_axlf", ctypes.c_char*16),
        ("uuid", ctypes.c_ubyte*16)  # uuid_t/xuid_t
    ]

class axlf_header (ctypes.Structure):
    _anonymous_ = ("u1","u2")
    _fields_ = [
        ("m_length", ctypes.c_uint64),
        ("m_timeStamp", ctypes.c_uint64),
        ("m_featureRomTimeStamp", ctypes.c_uint64),
        ("m_versionPatch", ctypes.c_uint16),
        ("m_versionMajor", ctypes.c_uint8),
        ("m_versionMinor", ctypes.c_uint8),
        ("m_mode", ctypes.c_uint32),
        ("u1", u1),
        ("m_platformVBNV", ctypes.c_ubyte*64),
        ("u2", u2),
        ("m_debug_bin", ctypes.c_char*16),
        ("m_numSections", ctypes.c_uint32)
    ]

class axlf (ctypes.Structure):
    _fields_ = [
        ("m_magic", ctypes.c_char*8),
        ("m_cipher", ctypes.c_ubyte*32),
        ("m_keyBlock", ctypes.c_ubyte*256),
        ("m_uniqueId", ctypes.c_uint64),
        ("m_header", axlf_header),
        ("m_sections", axlf_section_header)
    ]

class xlnx_bitstream(ctypes.Structure):
    _fields_ = [
        ("m_freq", ctypes.c_uint8*8),
        ("bits", ctypes.c_char*1)
    ]


"""   MEMORY TOPOLOGY SECTION   """

class mem_u1 (ctypes.Union):
    _fields_ = [
        ("m_size", ctypes.c_int64),
        ("route_id", ctypes.c_int64)
    ]

class mem_u2 (ctypes.Union):
    _fields_ = [
        ("m_base_address", ctypes.c_int64),
        ("flow_id", ctypes.c_int64)
    ]

class mem_data (ctypes.Structure):
    _anonymous_ = ("mem_u1", "mem_u2")
    _fields_ = [
        ("m_type", ctypes.c_uint8),
        ("m_used", ctypes.c_uint8),
        ("mem_u1", mem_u1),
        ("mem_u2", mem_u2),
        ("m_tag", ctypes.c_char * 16)
    ]

class mem_topology (ctypes.Structure):
    _fields_ = [
        ("m_count", ctypes.c_int32),
        ("m_mem_data", mem_data*1)
    ]


"""   CONNECTIVITY SECTION   """

class connection(ctypes.Structure):
    _fields_ = [
        ("arg_index", ctypes.c_int32),
        ("m_ip_layout_index", ctypes.c_int32),
        ("mem_data_index", ctypes.c_int32)
    ]

class connectivity(ctypes.Structure):
    _fields_ = [
        ("m_count", ctypes.c_int32),
        ("m_connection", connection*1)
    ]


"""   IP_LAYOUT SECTION   """

class ip_data (ctypes.Structure):
    _fields_ = [
        ("m_type", ctypes.c_uint32),
        ("properties", ctypes.c_uint32),
        ("m_base_address", ctypes.c_uint64),
        ("m_name", ctypes.c_uint8 * 64)
    ]

class ip_layout (ctypes.Structure):
    _fields_ = [
        ("m_count", ctypes.c_int32),
        ("m_ip_data", ip_data*1)
    ]


""" Debug IP section layout """

class DEBUG_IP_TYPE:
    UNDEFINED = 0
    LAPC = 1
    ILA = 2
    AXI_MM_MONITOR = 3
    AXI_TRACE_FUNNEL = 4
    AXI_MONITOR_FIFO_LITE = 5
    AXI_MONITOR_FIFO_FULL = 6
    ACCEL_MONITOR = 7
    AXI_STREAM_MONITOR = 8

class debug_ip_data(ctypes.Structure):
    _fields_ = [
        ("m_type", ctypes.c_uint8),
        ("m_index", ctypes.c_uint8),
        ("m_properties", ctypes.c_uint8),
        ("m_major", ctypes.c_uint8),
        ("m_minor", ctypes.c_uint8),
        ("m_reserved", ctypes.c_uint8*3),
        ("m_base_address", ctypes.c_uint64),
        ("m_name", ctypes.c_uint8*128)
    ]

class debug_ip_layout(ctypes.Structure):
    _fields_ = [
        ("m_count", ctypes.c_uint16),
        ("m_debug_ip_data", debug_ip_data*1)
    ]

class CLOCK_TYPE:
    CT_UNUSED = 0
    CT_DATA   = 1
    CT_KERNEL = 2
    CT_SYSTEM = 3

class clock_freq(ctypes.Structure):
    _fields_ = [
        ("m_freq_Mhz", ctypes.c_int16),
        ("m_type", ctypes.c_int8),
        ("m_unused", ctypes.c_uint8*5),
        ("m_name", ctypes.c_char*128)
    ]

class clock_freq_topology(ctypes.Structure):
    _fields_ = [
        ("m_count", ctypes.c_uint16),
        ("m_clock_freq", clock_freq*1)
    ]

class MCS_TYPE:
    MCS_UNKNOWN = 0
    MCS_PRIMARY = 1
    MCS_SECONDARY = 2

class mcs_chunk(ctypes.Structure):
    _fields_ = [
        ("m_type", ctypes.c_uint8),
        ("m_unused", ctypes.c_uint8*7),
        ("m_offset", ctypes.c_uint64),
        ("m_size", ctypes.c_uint64)
    ]

class mcs(ctypes.Structure):
    _fields_ = [
        ("m_count", ctypes.c_int8),
        ("m_unused", ctypes.c_int8),
        ("m_chunk", mcs_chunk*1)
    ]

class bmc(ctypes.Structure):
    _fields_ = [
        ("m_offset", ctypes.c_uint64),
        ("m_size", ctypes.c_uint64),
        ("m_image_name", ctypes.c_char*64),
        ("m_device_name", ctypes.c_char*64),
        ("m_version", ctypes.c_char*64),
        ("m_md5value", ctypes.c_char*33),
        ("m_padding", ctypes.c_char*7)
    ]

class CHECKSUM_TYPE:
    CST_UNKNOWN = 0
    CST_SDBM    = 1
    CST_LAST    = 2
