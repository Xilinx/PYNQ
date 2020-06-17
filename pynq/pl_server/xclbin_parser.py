#   Copyright (c) 2019, Xilinx, Inc.
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


__author__ = "Peter Ogden"
__copyright__ = "Copyright 2019, Xilinx"
__email__ = "pynq_support@xilinx.com"

import ctypes
from copy import deepcopy
from xml.etree import ElementTree
try:
    import xclbin_binding as xclbin
except ImportError:
    from pynq import xclbin

_mem_types = [
    "DDR3",
    "DDR4",
    "DRAM",
    "Streaming",
    "Preallocated",
    "ARE",
    "HBM",
    "BRAM",
    "URAM",
    "AXI Stream"
]


def _xclxml_to_ip_dict(raw_xml, xclbin_uuid):
    xml = ElementTree.fromstring(raw_xml)
    ip_dict = {}
    for kernel in xml.findall('platform/device/core/kernel'):
        if 'hwControlProtocl' in kernel.attrib:
            control_protocol = kernel.attrib['hwControlProtocl']
        else:
            control_protocol = 's_axilite'
        slaves = {n.attrib['name']: n for n in kernel.findall('port[@mode="slave"]')}
        if not slaves:
            continue
        masters = {n.attrib['name']: n for n in kernel.findall('port[@mode="master"]')}
        readonly = {n.attrib['name']: n for n in kernel.findall('port[@mode="read_only"]')}
        writeonly = {n.attrib['name']: n for n in kernel.findall('port[@mode="write_only"]')}
        addr_size = max([int(n.attrib['range'], 0) for n in slaves.values()])
        registers = {
            'CTRL': {
                'address_offset': 0,
                'access': 'read-write',
                'size': 4,
                'description': 'OpenCL Control Register',
                'type': 'unsigned int',
                'id': None,
                'fields': {
                    'AP_START': {
                        'access': 'read-write',
                        'bit_offset': 0,
                        'bit_width': 1,
                        'description': 'Start the accelerator'
                    },
                    'AP_DONE': {
                        'access': 'read-only',
                        'bit_offset': 1,
                        'bit_width': 1,
                        'description': 'Accelerator has finished - cleared on read'
                    },
                    'AP_IDLE': {
                        'access': 'read-only',
                        'bit_offset': 2,
                        'bit_width': 1,
                        'description': 'Accelerator is idle'
                    },
                    'AP_READY': {
                        'access': 'read-only',
                        'bit_offset': 3,
                        'bit_width': 1,
                        'description': 'Accelerator is ready to start next computation'
                    },
                    'AUTO_RESTART': {
                        'access': 'read-write',
                        'bit_offset': 7,
                        'bit_width': 1,
                        'description': 'Restart the accelerator automatically when finished'
                    }
                }
            }
        }
        if control_protocol == 'ap_ctrl_chain':
            registers['fields']['AP_CONTINUE'] = {
                'access': 'read-write',
                'bit_offset': 4,
                'bit_width': 1,
                'description': 'Invoke next iteration of kernel'
            }
        streams = {}
        for arg in kernel.findall('arg'):
            attrib = arg.attrib
            if int(attrib['addressQualifier'], 0) & 0x4 == 0:
                registers[attrib['name']] = {
                    'address_offset': int(attrib['offset'], 0),
                    'access': 'read-write;',
                    'size': int(attrib['size'], 0) * 8,
                    'host_size': int(attrib['hostSize'], 0),
                    'description': 'OpenCL Argument Register',
                    'type': attrib['type'],
                    'id': int(attrib['id'])
                }
            else:
                portname = attrib['port']
                if portname in readonly:
                    direction = 'input'
                elif portname in writeonly:
                    direction = 'output'
                else:
                    raise RuntimeError('Could not determine port direction')
                streams[attrib['name']] = {
                    'id': int(attrib['id']),
                    'type': attrib['type'],
                    'direction': direction
                }
        for instance in kernel.findall('instance'):
            ip_dict[instance.attrib['name']] = {
                'phys_addr': int(instance.find('addrRemap').attrib['base'], 0),
                'addr_range': addr_size,
                'type': kernel.attrib['vlnv'],
                'fullpath': instance.attrib['name'],
                'registers': deepcopy(registers),
                'streams': deepcopy(streams),
                'mem_id': None,
                'state': None,
                'interrupts': {},
                'gpio': {},
                'xclbin_uuid': xclbin_uuid
            }
    for i, d in enumerate(sorted(ip_dict.values(), key=lambda x: x['phys_addr'])):
        d['adjusted_index'] = i
    return {k: v for k, v in sorted(ip_dict.items())}


def _add_argument_memory(ip_dict, ip_data, connections, memories):
    import ctypes
    connection_dict = {
        (c.m_ip_layout_index, c.arg_index): c.mem_data_index
        for c in connections
    }
    for ip_index, ip in enumerate(ip_data):
        if ip.m_type != 1:
            continue
        full_name = ctypes.string_at(ip.m_name).decode()
        ip_name = full_name.partition(':')[2]
        if ip_name not in ip_dict:
            continue
        dict_entry = ip_dict[ip_name]
        dict_entry['index'] = ip_index
        for r in dict_entry['registers'].values():
            # Subtract 1 from the register index to account for AP_CTRL
            if (ip_index, r['id']) in connection_dict:
                r['memory'] = \
                    memories[connection_dict[(ip_index, r['id'])]].decode()
        for r in dict_entry['streams'].values():
            if (ip_index, r['id']) in connection_dict:
                r['stream_id'] = connection_dict[(ip_index, r['id'])]


def _get_buffer_slice(b, offset, length):
    return b[offset:offset+length]


def _get_object_as_array(obj, number):
    ctype = type(obj) * number
    return ctype.from_address(ctypes.addressof(obj))


def _mem_data_to_dict(idx, mem):
    if mem.m_type == 9:
        # Streaming Endpoing
        return {
            "raw_type": mem.m_type,
            "used": mem.m_used,
            "flow_id": mem.mem_u2.flow_id,
            "route_id": mem.mem_u1.route_id,
            "type": _mem_types[mem.m_type],
            "streaming": True,
            "idx": idx
        }
    else:
        return {
            "raw_type": mem.m_type,
            "used": mem.m_used,
            "base_address": mem.mem_u2.m_base_address,
            "size": mem.mem_u1.m_size * 1024,
            "type": _mem_types[mem.m_type],
            "streaming": False,
            "idx": idx
        }


def _xclbin_to_dicts(filename):
    with open(filename, 'rb') as f:
        binfile = bytearray(f.read())
    header = xclbin.axlf.from_buffer(binfile)
    section_headers = _get_object_as_array(
        header.m_sections, header.m_header.m_numSections)
    sections = {
        s.m_sectionKind: _get_buffer_slice(
            binfile, s.m_sectionOffset, s.m_sectionSize)
        for s in section_headers}

    xclbin_uuid = bytes(header.m_header.u2.uuid).hex()

    ip_dict = _xclxml_to_ip_dict(
        sections[xclbin.AXLF_SECTION_KIND.EMBEDDED_METADATA].decode(),
        xclbin_uuid)
    ip_layout = xclbin.ip_layout.from_buffer(
        sections[xclbin.AXLF_SECTION_KIND.IP_LAYOUT])
    ip_data = _get_object_as_array(ip_layout.m_ip_data[0], ip_layout.m_count)
    connectivity = xclbin.connectivity.from_buffer(
        sections[xclbin.AXLF_SECTION_KIND.CONNECTIVITY])
    connections = _get_object_as_array(connectivity.m_connection[0],
                                       connectivity.m_count)

    mem_topology = xclbin.mem_topology.from_buffer(
        sections[xclbin.AXLF_SECTION_KIND.MEM_TOPOLOGY])
    mem_data = _get_object_as_array(mem_topology.m_mem_data[0],
                                    mem_topology.m_count)
    memories = {i: ctypes.string_at(m.m_tag) for i, m in enumerate(mem_data)}
    mem_dict = {memories[i].decode(): _mem_data_to_dict(i, mem)
                for i, mem in enumerate(mem_data)}
    _add_argument_memory(ip_dict, ip_data, connections, memories)

    return ip_dict, mem_dict


class XclBin:
    """Helper Class to extract information from an xclbin file

    Note
    ----
    This class requires the absolute path of the '.xclbin' file.
    Most of the dictionaries are empty to ensure compatibility
    with the HWH and TCL files.

    Attributes
    ----------
    ip_dict : dict
        All the addressable IPs from PS7. Key is the name of the IP; value is
        a dictionary mapping the physical address, address range, IP type,
        memory segment ID, the state associated with that IP, any
        interrupts and GPIO pins attached to the IP and the full path to the
        IP in the block design:
        {str: {'phys_addr' : int, 'addr_range' : int,\
               'type' : str, 'mem_id' : str, 'state' : str,\
               'interrupts' : dict, 'gpio' : dict, 'fullpath' : str}}.

    mem_dict : dict
        All of the memory regions and streaming connections in the design:
        {str: {'used' : bool, 'base_address' : int, 'size' : int, 'idx' : int,\
               'raw_type' : int, 'tyoe' : str, 'streaming' : bool}}.

    """
    def __init__(self, filename):
        self.ip_dict, self.mem_dict = _xclbin_to_dicts(filename)
        self.gpio_dict = {}
        self.interrupt_controllers = {}
        self.interrupt_pins = {}
        self.hierarchy_dict = {}
        self.clock_dict = {}
