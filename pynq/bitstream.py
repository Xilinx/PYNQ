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

__author__ = "Yun Rock Qu, Peter Ogden"
__copyright__ = "Copyright 2019, Xilinx"
__email__ = "pynq_support@xilinx.com"

import os
from datetime import datetime
import struct
import numpy as np
from .devicetree import get_dtbo_path

PYNQ_PATH = os.path.dirname(os.path.realpath(__file__))

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

    def __init__(self, bitfile_name, dtbo=None, partial=False, device=None):
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
        if device is None:
            from .pl_server.device import Device
            device = Device.active_device
        self.device = device

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

    def download(self, parser=None):
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
            self.device.shutdown()
            flag = '0'
        else:
            flag = '1'
        with open(self.BS_FPGA_MAN_FLAGS, "w") as fd:
            fd.write(flag)
        with open(self.BS_FPGA_MAN, 'w') as fd:
            fd.write(self.binfile_name)

        # update the entire PL information
        if not self.partial:
            self.update_pl(parser)

    def remove_dtbo(self):
        """Remove dtbo file from the system.

        A simple wrapper of the corresponding method in the PL class. This is
        very useful for partial bitstream downloading, where loading the
        new device tree blob will overwrites the existing device tree blob
        in the same partial region.

        """
        self.device.remove_device_tree(self.dtbo)

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
        self.device.insert_device_tree(self.dtbo)

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

    def update_pl(self, parser=None):
        """Update the PL information.

        This method will update all the PL dictionaries, including the device
        tree dictionaries.

        """
        t = datetime.now()
        self.timestamp = "{}/{}/{} {}:{}:{} +{}".format(
                t.year, t.month, t.day,
                t.hour, t.minute, t.second, t.microsecond)
        self.device.reset(parser, self.timestamp, self.bitfile_name)
