#   Copyright (c) 2019-2021, Xilinx, Inc.
#   SPDX-License-Identifier: BSD-3-Clause



import ctypes
import itertools
from copy import deepcopy
from xml.etree import ElementTree
from pynq._3rdparty import xclbin

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
        if 'hwControlProtocol' in kernel.attrib:
            control_protocol = kernel.attrib['hwControlProtocol']
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
            registers['CTRL']['fields']['AP_CONTINUE'] = {
                'access': 'read-write',
                'bit_offset': 4,
                'bit_width': 1,
                'description': 'Invoke next iteration of kernel'
            }
        elif control_protocol == 'ap_ctrl_none' or \
                control_protocol == 'user_managed':
            registers = {}
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
                sid = attrib.get('id')
                streams[attrib['name']] = {
                    'id': int(sid) if sid else None,
                    'type': attrib.get('type'),
                    'direction': direction
                }
        for instance in kernel.findall('instance'):
            try:
                phys_addr = int(instance.find('addrRemap').attrib['base'], 0)
            except ValueError:
                phys_addr = None

            if phys_addr is not None:
                ip_dict[instance.attrib['name']] = {
                    'phys_addr': phys_addr,
                    'addr_range': addr_size,
                    'type': kernel.attrib['vlnv'],
                    'hw_control_protocol': control_protocol,
                    'fullpath': instance.attrib['name'],
                    'registers': deepcopy(registers),
                    'streams': deepcopy(streams),
                    'mem_id': None,
                    'state': None,
                    'interrupts': {},
                    'gpio': {},
                    'xclbin_uuid': xclbin_uuid,
                    'cu_name': ":".join((kernel.attrib['name'],
                                         instance.attrib['name']))
                }
    for i, d in enumerate(sorted(ip_dict.values(),
                          key=lambda x: x['phys_addr'])): d['cu_index'] = i
    return {k: v for k, v in sorted(ip_dict.items())}


def _add_argument_memory(ip_dict, ip_data, connections, memories):
    import ctypes
    connection_dict = dict()
    for c in connections:
        key = c.m_ip_layout_index, c.arg_index
        if key not in connection_dict.keys():
            connection_dict[key] = list()
        connection_dict[key].append(memories[c.mem_data_index])

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
                memory = connection_dict[(ip_index, r['id'])]
                r['memory'] = memory[-1]
                if len(memory) > 1:
                    r['MBG'] = memory
        for r in dict_entry['streams'].values():
            if (ip_index, r['id']) in connection_dict:
                r['stream_id'] = connection_dict[(ip_index, r['id'])][-1]


def _get_buffer_slice(b, offset, length):
    return b[offset:offset+length]


def _get_object_as_array(obj, number):
    ctype = type(obj) * number
    return ctype.from_address(ctypes.addressof(obj))


def _mem_data_to_dict(idx, mem, tag):
    if mem.m_type == 9:
        # Streaming Endpoint
        return {
            "raw_type": mem.m_type,
            "used": mem.m_used,
            "flow_id": mem.mem_u2.flow_id,
            "route_id": mem.mem_u1.route_id,
            "type": _mem_types[mem.m_type],
            "streaming": True,
            "idx": idx,
            "tag": tag
        }
    else:
        return {
            "raw_type": mem.m_type,
            "used": mem.m_used,
            "base_address": mem.mem_u2.m_base_address,
            "size": mem.mem_u1.m_size * 1024,
            "type": _mem_types[mem.m_type],
            "streaming": False,
            "idx": idx,
            "tag": tag
        }


_clock_types = [
    "UNUSED",
    "DATA",
    "KERNEL",
    "SYSTEM"
]


def _clk_data_to_dict(clk_data):
    """Create a dictionary of dictionaries for the clock data.
    The clocks will be sorted depending on the clock type.
    """

    clk_dict = {}
    idx = 0
    for i in _clock_types:
        for j, clk in enumerate(clk_data):
            clk_i = {
                "name": clk.m_name.decode("utf-8"),
                "frequency": clk.m_freq_Mhz,
                "type": _clock_types[clk.m_type]}
            if _clock_types[clk.m_type] is i:
                clk_dict['clock'+str(idx)] = clk_i
                idx += 1

    return clk_dict

def parse_xclbin_header(xclbin_data):
    binfile = bytearray(xclbin_data)
    header = xclbin.axlf.from_buffer(binfile)
    section_headers = _get_object_as_array(
        header.m_sections, header.m_header.m_numSections)
    sections = {
        s.m_sectionKind: _get_buffer_slice(
            binfile, s.m_sectionOffset, s.m_sectionSize)
        for s in section_headers}
    return sections, bytes(header.m_header.u2.uuid).hex()


def _xclbin_to_dicts(filename, xclbin_data=None):
    if xclbin_data is None:
         with open(filename, 'rb') as f:
             xclbin_data = bytearray(f.read())
    sections, xclbin_uuid = parse_xclbin_header(xclbin_data)

    ip_dict = _xclxml_to_ip_dict(
        sections[xclbin.AXLF_SECTION_KIND.EMBEDDED_METADATA].decode(),
        xclbin_uuid)

    if xclbin.AXLF_SECTION_KIND.IP_LAYOUT in sections:
        ip_layout = xclbin.ip_layout.from_buffer(
            sections[xclbin.AXLF_SECTION_KIND.IP_LAYOUT])
        ip_data = _get_object_as_array(ip_layout.m_ip_data[0], ip_layout.m_count)
    else:
        ip_data = []

    if xclbin.AXLF_SECTION_KIND.CONNECTIVITY in sections:
        connectivity = xclbin.connectivity.from_buffer(
            sections[xclbin.AXLF_SECTION_KIND.CONNECTIVITY])
        connections = _get_object_as_array(connectivity.m_connection[0],
                                           connectivity.m_count)
    elif xclbin.AXLF_SECTION_KIND.GROUP_CONNECTIVITY in sections:
        connectivity = xclbin.connectivity.from_buffer(
            sections[xclbin.AXLF_SECTION_KIND.GROUP_CONNECTIVITY])
        connections = _get_object_as_array(connectivity.m_connection[0],
                                           connectivity.m_count)
    else:
        connections = []

    if xclbin.AXLF_SECTION_KIND.MEM_TOPOLOGY in sections:
        mem_topology = xclbin.mem_topology.from_buffer(
            sections[xclbin.AXLF_SECTION_KIND.MEM_TOPOLOGY])
        mem_data = _get_object_as_array(mem_topology.m_mem_data[0],
                                        mem_topology.m_count)
    elif xclbin.AXLF_SECTION_KIND.GROUP_TOPOLOGY in sections:
        mem_topology = xclbin.mem_topology.from_buffer(
            sections[xclbin.AXLF_SECTION_KIND.GROUP_TOPOLOGY])
        mem_data = _get_object_as_array(mem_topology.m_mem_data[0],
                                        mem_topology.m_count)
    else:
        mem_data = []

    memories = [ctypes.string_at(m.m_tag).decode() for m in mem_data]
    mem_dict = {tag: _mem_data_to_dict(i, mem, tag)
                for i, tag, mem in zip(itertools.count(), memories, mem_data)}
    _add_argument_memory(ip_dict, ip_data, connections, memories)
    
    if xclbin.AXLF_SECTION_KIND.CLOCK_FREQ_TOPOLOGY in sections:
        clock_topology = xclbin.clock_freq_topology.from_buffer(
              sections[xclbin.AXLF_SECTION_KIND.CLOCK_FREQ_TOPOLOGY])

        clk_data = _get_object_as_array(clock_topology.m_clock_freq[0],
                                        clock_topology.m_count)

        clock_dict = _clk_data_to_dict(clk_data)
    else:
        clock_dict = {}

    return ip_dict, mem_dict, clock_dict


class XclBin:
    """Helper Class to extract information from an xclbin file

    Note
    ----
    This class requires the absolute path of the '.xclbin' file.
    Most of the dictionaries are empty to ensure compatibility
    with the HWH files.

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
               'raw_type' : int, 'type' : str, 'streaming' : bool}}.

    clock_dict : dict
        All of the clocks in the design:
        {str: {'name' : str, 'frequency' : int, 'type' : str}}.

    """
    def __init__(self, filename="", xclbin_data=None):
        self.ip_dict, self.mem_dict, self.clock_dict = \
            _xclbin_to_dicts(filename, xclbin_data)
        self.gpio_dict = {}
        self.interrupt_controllers = {}
        self.interrupt_pins = {}
        self.hierarchy_dict = {}
        self.xclbin_data = xclbin_data
        self.systemgraph = None


