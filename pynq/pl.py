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

import os
import warnings
from copy import deepcopy
from datetime import datetime
import struct
import numpy as np
from multiprocessing.connection import Listener
from multiprocessing.connection import Client
from .mmio import MMIO
from .ps import CPU_ARCH_IS_SUPPORTED, CPU_ARCH, ZYNQ_ARCH, ZU_ARCH
from .devicetree import DeviceTreeSegment
from .devicetree import get_dtbo_path
from .devicetree import get_dtbo_base_name

from .pl_server import HWH, TCL
from .pl_server import get_hwh_name, get_tcl_name
from .pl_server import DeviceClient

__author__ = "Yun Rock Qu"
__copyright__ = "Copyright 2016, Xilinx"
__email__ = "pynq_support@xilinx.com"










class PLMeta(type):
    """This method is the meta class for the PL.

    This is not a class for users. Hence there is no attribute or method
    exposed to users.

    We make no assumption of the overlay during boot, so most of the
    dictionaries are empty. Those dictionaries will get populated when
    users download an overlay onto the PL.

    Note
    ----
    If this metaclass is parsed on an unsupported architecture it will issue
    a warning and leave class variables undefined

    """
    _client = DeviceClient()

    @property
    def bitfile_name(cls):
        """The getter for the attribute `bitfile_name`.

        Returns
        -------
        str
            The absolute path of the bitstream currently on PL.

        """
        return cls._client.bitfile_name 

    @property
    def timestamp(cls):
        """The getter for the attribute `timestamp`.

        Returns
        -------
        str
            Bitstream download timestamp.

        """
        return cls._client.timestamp

    @property
    def ip_dict(cls):
        """The getter for the attribute `ip_dict`.

        Returns
        -------
        dict
            The dictionary storing addressable IP instances; can be empty.

        """
        return cls._client.ip_dict

    @property
    def gpio_dict(cls):
        """The getter for the attribute `gpio_dict`.

        Returns
        -------
        dict
            The dictionary storing the PS GPIO pins.

        """
        return cls._client.gpio_dict

    @property
    def interrupt_controllers(cls):
        """The getter for the attribute `interrupt_controllers`.

        Returns
        -------
        dict
            The dictionary storing interrupt controller information.

        """
        return cls._client.interrupt_controllers

    @property
    def interrupt_pins(cls):
        """The getter for the attribute `interrupt_pins`.

        Returns
        -------
        dict
            The dictionary storing the interrupt endpoint information.

        """
        return cls._client.interrupt_pins

    @property
    def hierarchy_dict(cls):
        """The getter for the attribute `hierarchy_dict`

        Returns
        -------
        dict
            The dictionary containing the hierarchies in the design

        """
        return cls._client.hierarchy_dict

    @property
    def devicetree_dict(cls):
        """The getter for the attribute `devicetree_dict`

        Returns
        -------
        dict
            The dictionary containing the device tree blobs.

        """
        return cls._client.devicetree_dict

    def shutdown(cls):
        """Shutdown the AXI connections to the PL in preparation for
        reconfiguration

        """
        ip = cls.ip_dict
        for name, details in ip.items():
            if details['type'] == 'xilinx.com:ip:pr_axi_shutdown_manager:1.0':
                from pynq.mmio import MMIO
                mmio = MMIO(details['phys_addr'])
                # Request shutdown
                mmio.write(0x0, 0x1)
                i = 0
                while mmio.read(0x0) != 0x0F and i < 16000:
                    i += 1
                if i >= 16000:
                    warnings.warn("Timeout for shutdown manager. It's likely "
                                  "the configured bitstream and metadata "
                                  "don't match.")

    def reset(cls, parser=None):
        """Reset all the dictionaries.

        This method must be called after a bitstream download.
        1. In case there is a `hwh` or `tcl` file, this method will reset
        the states of the IP, GPIO, and interrupt dictionaries .
        2. In case there is no `hwh` or `tcl` file, this method will simply
        clear the state information stored for all dictionaries.

        An existing parser given as the input can significantly reduce
        the reset time, since the PL can reset based on the
        information provided by the parser.

        Parameters
        ----------
        parser : TCL/HWH
            A parser object to speed up the reset process.

        """
        cls._client.reset(parser)

    def clear_dict(cls):
        """Clear all the dictionaries stored in PL.

        This method will clear all the related dictionaries, including IP
        dictionary, GPIO dictionary, etc.

        """
        cls._client.clear_dict()

    def clear_devicetree(cls):
        """Clear the device tree dictionary.

        This should be used when downloading the full bitstream, where all the
        dtbo are cleared from the system.

        """
        cls._client.clear_devicetree()

    def insert_device_tree(cls, abs_dtbo):
        """Insert device tree segment.

        For device tree segments associated with full / partial bitstreams,
        users can provide the relative or absolute paths of the dtbo files.

        Parameters
        ----------
        abs_dtbo : str
            The absolute path to the device tree segment.

        """
        cls._client.insert_device_tree(abs_dtbo)

    def remove_device_tree(cls, abs_dtbo):
        """Remove device tree segment for the overlay.

        Parameters
        ----------
        abs_dtbo : str
            The absolute path to the device tree segment.

        """
        cls._client.remove_device_tree(abs_dtbo)

    def load_ip_data(cls, ip_name, data, zero=False):
        """This method writes data to the addressable IP.

        Note
        ----
        The data is assumed to be in binary format (.bin). The data
        name will be stored as a state information in the IP dictionary.

        Parameters
        ----------
        ip_name : str
            The name of the addressable IP.
        data : str
            The absolute path of the data to be loaded.
        zero : bool
            Zero out the address of the IP not covered by data

        Returns
        -------
        None

        """
        with open(data, 'rb') as bin_file:
            size = os.fstat(bin_file.fileno()).st_size
            target_size = cls._ip_dict[ip_name]['addr_range']
            if size > target_size:
                raise RuntimeError("Binary file too big for IP")
            mmio = MMIO(cls._ip_dict[ip_name]['phys_addr'], target_size)
            buf = bin_file.read(size)
            mmio.write(0, buf)
            if zero and size < target_size:
                mmio.write(size, b'\x00' * (target_size - size))

        cls._client.load_ip_data(ip_name, data)

    def update_partial_region(cls, hier, parser):
        """Merge the parser information from partial region.

        Combine the currently PL information and the partial HWH/TCL file
        parsing results.

        Parameters
        ----------
        hier : str
            The name of the hierarchical block as the partial region.
        parser : TCL/HWH
            A parser object for the partial region.

        """
        cls._client.update_partial_region(hier, parser)


class PL(metaclass=PLMeta):
    """Serves as a singleton for `Overlay` and `Bitstream` classes.

    This class stores multiple dictionaries: IP dictionary, GPIO dictionary,
    interrupt controller dictionary, and interrupt pins dictionary.

    Attributes
    ----------
    bitfile_name : str
        The absolute path of the bitstream currently on PL.
    timestamp : str
        Bitstream download timestamp, using the following format:
        year, month, day, hour, minute, second, microsecond.
    ip_dict : dict
        All the addressable IPs from PS7. Key is the name of the IP; value is
        a dictionary mapping the physical address, address range, IP type,
        configuration dictionary, the state associated with that IP, any
        interrupts and GPIO pins attached to the IP and the full path to the
        IP in the block design:
        {str: {'phys_addr' : int, 'addr_range' : int,\
               'type' : str, 'config' : dict, 'state' : str,\
               'interrupts' : dict, 'gpio' : dict, 'fullpath' : str}}.
    gpio_dict : dict
        All the GPIO pins controlled by PS7. Key is the name of the GPIO pin;
        value is a dictionary mapping user index (starting from 0),
        the state associated with that GPIO pin and the pins in block diagram
        attached to the GPIO:
        {str: {'index' : int, 'state' : str, 'pins' : [str]}}.
    interrupt_controllers : dict
        All AXI interrupt controllers in the system attached to
        a PS7 interrupt line. Key is the name of the controller;
        value is a dictionary mapping parent interrupt controller and the
        line index of this interrupt:
        {str: {'parent': str, 'index' : int}}.
        The PS7 is the root of the hierarchy and is unnamed.
    interrupt_pins : dict
        All pins in the design attached to an interrupt controller.
        Key is the name of the pin; value is a dictionary
        mapping the interrupt controller and the line index used:
        {str: {'controller' : str, 'index' : int}}.
    hierarchy_dict : dict
        All of the hierarchies in the block design containing addressable IP.
        The keys are the hiearachies and the values are dictionaries
        containing the IP and sub-hierarchies contained in the hierarchy and
        and GPIO and interrupts attached to the hierarchy. The keys in
        dictionaries are relative to the hierarchy and the ip dict only
        contains immediately contained IP - not those in sub-hierarchies.
        {str: {'ip': dict, 'hierarchies': dict, 'interrupts': dict,\
               'gpio': dict, 'fullpath': str}}

    """
    def __init__(self):
        """Return a new PL object.

        This class requires a root permission.

        """
        euid = os.geteuid()
        if euid != 0:
            raise EnvironmentError('Root permissions required.')


class Bitstream:
    """This class instantiates the meta class for PL bitstream (full/partial).

    Attributes
    ----------
    bitfile_name : str
        The absolute path or name of the bit file as a string.
    dtbo : str
        The absolute path of the dtbo file as a string.
    partial : bool
        Flag to indicate whether or not the bitstream is partial.
    bit_data : dict
        Dictionary storing information about the bitstream.
    binfile_name : str
        The absolute path or name of the bin file as a string.
    firmware_path : str
        The absolute path of the bin file in the firmware folder.
    timestamp : str
        Timestamp when loading the bitstream. Format:
        year, month, day, hour, minute, second, microsecond

    """
    BS_FPGA_MAN = "/sys/class/fpga_manager/fpga0/firmware"
    BS_FPGA_MAN_FLAGS = "/sys/class/fpga_manager/fpga0/flags"

    def __init__(self, bitfile_name, dtbo=None, partial=False):
        """Return a new Bitstream object.

        Users can either specify an absolute path to the bitstream file
        (e.g. '/home/xilinx/pynq/overlays/base/base.bit'),
        or a relative path within an overlay folder.
        (e.g. 'base.bit' for base/base.bit).

        Note
        ----
        `self.bitfile_name` always stores the absolute path of the bitstream.
        `self.dtbo` always stores the absolute path of the dtbo file.

        Parameters
        ----------
        bitfile_name : str
            The absolute path or name of the bit file as a string.
        dtbo : str
            The relative or absolute path to the device tree segment.
        partial : bool
            Flag to indicate whether or not the bitstream is partial.

        """
        if not isinstance(bitfile_name, str):
            raise TypeError("Bitstream name has to be a string.")

        bitfile_abs = os.path.abspath(bitfile_name)
        bitfile_overlay_abs = os.path.join(PYNQ_PATH,
                                           'overlays',
                                           bitfile_name.replace('.bit', ''),
                                           bitfile_name)

        if os.path.isfile(bitfile_name):
            self.bitfile_name = bitfile_abs
        elif os.path.isfile(bitfile_overlay_abs):
            self.bitfile_name = bitfile_overlay_abs
        else:
            raise IOError('Bitstream file {} does not exist.'.format(
                bitfile_name))

        self.dtbo = dtbo
        if dtbo:
            default_dtbo = get_dtbo_path(self.bitfile_name)
            if os.path.exists(dtbo):
                self.dtbo = dtbo
            elif os.path.exists(default_dtbo):
                self.dtbo = default_dtbo
            else:
                raise IOError("DTBO file {} does not exist.".format(
                    dtbo))

        self.bit_data = dict()
        self.binfile_name = ''
        self.firmware_path = ''
        self.timestamp = ''
        self.partial = partial

    def convert_bit_to_bin(self):
        """The method to convert a .bit file to .bin file.

        A .bit file is generated by Vivado, but .bin files are needed
        by the FPGA manager driver. Users must specify
        the absolute path to the source .bit file, and the destination
        .bin file and have read/write access to both paths.
        This function is only converting the bit file when the bit file is
        updated.

        Note
        ----
        Implemented based on: https://blog.aeste.my/?p=2892

        """
        if self.bit_data != self.parse_bit_header() or \
                not os.path.isfile(self.firmware_path):
            self.bit_data = self.parse_bit_header()
            bit_buffer = np.frombuffer(self.bit_data['data'],
                                       dtype=np.int32, offset=0)
            bin_buffer = bit_buffer.byteswap()
            bin_buffer.tofile(self.firmware_path, "")

    def parse_bit_header(self):
        """The method to parse the header of a bitstream.

        The returned dictionary has the following keys:
        "design": str, the Vivado project name that generated the bitstream;
        "version": str, the Vivado tool version that generated the bitstream;
        "part": str, the Xilinx part name that the bitstream targets;
        "date": str, the date the bitstream was compiled on;
        "time": str, the time the bitstream finished compilation;
        "length": int, total length of the bitstream (in bytes);
        "data": binary, binary data in .bit file format

        Returns
        -------
        Dict
            A dictionary containing the header information.

        Note
        ----
        Implemented based on: https://blog.aeste.my/?p=2892

        """
        with open(self.bitfile_name, 'rb') as bitf:
            finished = False
            offset = 0
            contents = bitf.read()
            bit_dict = {}

            # Strip the (2+n)-byte first field (2-bit length, n-bit data)
            length = struct.unpack('>h', contents[offset:offset + 2])[0]
            offset += 2 + length

            # Strip a two-byte unknown field (usually 1)
            offset += 2

            # Strip the remaining headers. 0x65 signals the bit data field
            while not finished:
                desc = contents[offset]
                offset += 1

                if desc != 0x65:
                    length = struct.unpack('>h',
                                           contents[offset:offset + 2])[0]
                    offset += 2
                    fmt = ">{}s".format(length)
                    data = struct.unpack(fmt,
                                         contents[offset:offset + length])[0]
                    data = data.decode('ascii')[:-1]
                    offset += length

                if desc == 0x61:
                    s = data.split(";")
                    bit_dict['design'] = s[0]
                    bit_dict['version'] = s[-1]
                elif desc == 0x62:
                    bit_dict['part'] = data
                elif desc == 0x63:
                    bit_dict['date'] = data
                elif desc == 0x64:
                    bit_dict['time'] = data
                elif desc == 0x65:
                    finished = True
                    length = struct.unpack('>i',
                                           contents[offset:offset + 4])[0]
                    offset += 4
                    # Expected length values can be verified in the chip TRM
                    bit_dict['length'] = str(length)
                    if length + offset != len(contents):
                        raise RuntimeError("Invalid length found")
                    bit_dict['data'] = contents[offset:offset + length]
                else:
                    raise RuntimeError("Unknown field: {}".format(hex(desc)))
            return bit_dict

    def download(self):
        """Download the bitstream onto PL and update PL information.

        If device tree blob has been specified during initialization, this
        method will also insert the corresponding device tree blob into the
        system. This is same for both full bitstream and partial bitstream.

        Note
        ----
        For partial bitstream, this method does not guarantee isolation between
        static and dynamic regions.

        Returns
        -------
        None

        """
        # preload bin into firmware
        if not self.binfile_name:
            self.preload()

        # use fpga manager to download bin
        if not self.partial:
            PL.shutdown()
            flag = '0'
        else:
            flag = '1'
        with open(self.BS_FPGA_MAN_FLAGS, "w") as fd:
            fd.write(flag)
        with open(self.BS_FPGA_MAN, 'w') as fd:
            fd.write(self.binfile_name)

        # update the entire PL information
        if not self.partial:
            self.update_pl()

    def remove_dtbo(self):
        """Remove dtbo file from the system.

        A simple wrapper of the corresponding method in the PL class. This is
        very useful for partial bitstream downloading, where loading the
        new device tree blob will overwrites the existing device tree blob
        in the same partial region.

        """
        PL.remove_device_tree(self.dtbo)

    def insert_dtbo(self, dtbo=None):
        """Insert dtbo file into the system.

        A simple wrapper of the corresponding method in the PL class. If
        `dtbo` is None, `self.dtbo` will be used to insert the dtbo
        file. In most cases, users should just ignore the parameter
        `dtbo`.

        Parameters
        ----------
        dtbo : str
            The relative or absolute path to the device tree segment.

        """
        if dtbo:
            default_dtbo = get_dtbo_path(self.bitfile_name)
            default_dtbo_folder = '/'.join(default_dtbo.split('/')[:-1])
            absolute_dtbo = os.path.join(default_dtbo_folder, dtbo)
            if os.path.exists(dtbo):
                self.dtbo = dtbo
            elif os.path.exists(absolute_dtbo):
                self.dtbo = absolute_dtbo
            else:
                raise IOError("DTBO file {} does not exist.".format(
                    dtbo))
        if not self.dtbo:
            raise ValueError("DTBO path has to be specified.")
        PL.insert_device_tree(self.dtbo)

    def preload(self):
        """Pre-processing of the bit file.

        This method will pre-process the bit file into a FPGA-manager friendly
        format.

        """
        if not os.path.exists(self.BS_FPGA_MAN):
            raise RuntimeError("Could not find programmable device")

        self.binfile_name = os.path.basename(
            self.bitfile_name).replace('.bit', '.bin')
        self.firmware_path = '/lib/firmware/' + self.binfile_name
        self.convert_bit_to_bin()

    def update_pl(self):
        """Update the PL information.

        This method will update all the PL dictionaries, including the device
        tree dictionaries.

        """
        t = datetime.now()
        self.timestamp = "{}/{}/{} {}:{}:{} +{}".format(
                t.year, t.month, t.day,
                t.hour, t.minute, t.second, t.microsecond)

        # Update PL information
        PL.client_request()
        PL._bitfile_name = self.bitfile_name
        PL._timestamp = self.timestamp
        PL.clear_dict()
        PL.clear_devicetree()
        PL.server_update()
