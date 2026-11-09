# Copyright (C) 2022 Xilinx, Inc
# Copyright (C) 2022-2026 Advanced Micro Devices, Inc.
# SPDX-License-Identifier: BSD-3-Clause

import os
import pickle
import struct
from pathlib import Path
import datetime
import platform
import warnings

import numpy as np
from pynqmetadata.frontends import Metadata

from pynqmetadata.views.runtime import RuntimeMetadataParser
from .arch import VersalArch, ZynqArch, ZynqUltrascaleArch, _arch_class
from .xrt_device import XrtDevice, XrtMemory
from .global_state import GlobalState, save_global_state
from .global_state import initial_global_state_file_boot_check, load_global_state
from .global_state import bitstream_hash, global_state_file_exists, clear_global_state
from .global_state import _get_metadata_path

DEFAULT_XCLBIN = (Path(__file__).parent / "default.xclbin").read_bytes()

class CacheMetadataError(Exception):
    """ An exception that is raised when there is no cached metadata """
    pass

def _unify_dictionaries(hwh_parser, xclbin_parser):
    """Merges the XRT specific info from the xclbin file into
    the HWH parser

    """
    mem_by_address = {v["base_address"]: v for k, v in xclbin_parser.mem_dict.items()}
    for k, v in hwh_parser.mem_dict.items():
        if v.get("phys_addr", None) in mem_by_address:
            hwh_parser.mem_dict[k].update(mem_by_address[v["phys_addr"]])
            del mem_by_address[v["phys_addr"]]
    for v in mem_by_address.values():
        hwh_parser.mem_dict[v["tag"]] = v


def parse_bit_header(bit_data):
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
    finished = False
    offset = 0
    contents = bit_data
    bit_dict = {}

    # Strip the (2+n)-byte first field (2-bit length, n-bit data)
    length = struct.unpack(">h", contents[offset : offset + 2])[0]
    offset += 2 + length

    # Strip a two-byte unknown field (usually 1)
    offset += 2

    # Strip the remaining headers. 0x65 signals the bit data field
    while not finished:
        desc = contents[offset]
        offset += 1

        if desc != 0x65:
            length = struct.unpack(">h", contents[offset : offset + 2])[0]
            offset += 2
            fmt = ">{}s".format(length)
            data = struct.unpack(fmt, contents[offset : offset + length])[0]
            data = data.decode("ascii")[:-1]
            offset += length

        if desc == 0x61:
            s = data.split(";")
            bit_dict["design"] = s[0]
            bit_dict["version"] = s[-1]
        elif desc == 0x62:
            bit_dict["part"] = data
        elif desc == 0x63:
            bit_dict["date"] = data
        elif desc == 0x64:
            bit_dict["time"] = data
        elif desc == 0x65:
            finished = True
            length = struct.unpack(">i", contents[offset : offset + 4])[0]
            offset += 4
            # Expected length values can be verified in the chip TRM
            bit_dict["length"] = str(length)
            if length + offset != len(contents):
                raise RuntimeError("Invalid length found")
            bit_dict["data"] = contents[offset : offset + length]
        else:
            raise RuntimeError("Unknown field: {}".format(hex(desc)))
    return bit_dict


def bit2bin(bit_data):
    """Convert an in-memory .bit file to .bin data for fpga_manager"""
    bit_dict = parse_bit_header(bit_data)
    bit_buffer = np.frombuffer(bit_dict["data"], "i4")
    bin_buffer = bit_buffer.byteswap()
    return bytes(bin_buffer)


def _preload_binfile(bitstream, parser):
    """Dump the data from a parser into a binary file in firmware"""
    bin_data = getattr(parser, "bin_data", None)
    if bin_data is None:
        bin_data = _get_bitstream_handler(bitstream.bitfile_name).get_bin_data()
    bitstream.binfile_name = Path(bitstream.bitfile_name).stem + ".bin"
    bitstream.firmware_path = Path("/lib/firmware") / bitstream.binfile_name
    bitstream.firmware_path.write_bytes(bin_data)


class BitstreamHandler:
    """Base class for handling various formats of bitstreams

    For a bitstream at least one of get_xclbin_data and get_hwh_data
    should return valid data in order for the bitstream to be used
    the Overlay class. If the bitstream is going to be used with
    the Bitstream class then only get_bin_data is required.

    """

    def __init__(self, filepath, device_tag=""):
        self._filepath = Path(filepath)
        self._device_tag = device_tag

    def get_bin_data(self):
        """Get the binary data of the bitstream in a form suitable
        for passing to FPGA manager

        """
        return None

    def get_xclbin_data(self):
        """Return the xclbin data for the bitstream

        Should be None if no data exists

        """
        xclbin_file = self._filepath.with_suffix(".xclbin")
        if xclbin_file.exists():
            return xclbin_file.read_bytes()
        return None

    def get_dtbo_data(self):
        """Return the device tree overlay for the bitstream

        Should be None if no device tree overlay is present

        """
        dtbo_file = self._filepath.with_suffix(".dtbo")
        if dtbo_file.exists():
            return dtbo_file.read_bytes()
        return None

    def get_hwh_data(self):
        """Return the hardware handoff file for the bitstream

        Should be None if no HWH data is available

        """
        hwh_file = self._filepath.with_suffix(".hwh")
        if hwh_file.exists():
            return hwh_file.read_text(encoding='utf-8')
        return None

    def is_xsa(self):
        """Returns true if this is an XSA file, false otherwise"""
        xsa_file = self._filepath.with_suffix(".xsa")
        if xsa_file.exists():
            return True
        return False

    def _cache_exists(self)->bool:
        """ Checks to see if this bitstream is already on the system and
        use the cached metadata """
        if global_state_file_exists(self._device_tag):
            glob_state = load_global_state(self._device_tag)
            return glob_state.bitfile_hash == bitstream_hash(self._filepath)
        return False
             

    def _clear_cache(self):
        """ Clears the cache file """
        metadata_state_file = _get_metadata_path(self._device_tag)
        if os.path.isfile(metadata_state_file):
            os.remove(metadata_state_file)

    def _get_cache(self):
        """ Tries to return the Cached data """
        if self._cache_exists():
            metadata_state_file = _get_metadata_path(self._device_tag)
            if os.path.isfile(metadata_state_file):
                try:
                    parser = pickle.load(open(metadata_state_file, "rb"))
                    parser._from_cache = True

                    # Removing previous synthetic XRT mem_dict items
                    mem_dict_to_remove = []
                    for itemname, item in parser.mem_dict.items():
                        if not "fullpath" in item:
                            mem_dict_to_remove.append(itemname)
                    for i in mem_dict_to_remove:
                        del parser.mem_dict[i]

                    return parser
                except:
                    self._clear_cache()
                    raise CacheMetadataError(f"Global state file exists, but pickled metadata cannot be found")
            else:
                clear_global_state(self._device_tag)
                raise CacheMetadataError(f"Global state file exists, but pickled metadata cannot be found")
        else:
            raise CacheMetadataError(f"No cached metadata present")

    def get_parser(self, partial:bool=False):
        """Returns a parser object for the bitstream

        The returned object contains all of the data that
        was processed from both the HWH and Xclbin metadata
        attached to the object. Note that the parser may
        contain synthetic xclbin data where that is necessary

        """
        from .hwh_parser import HWH
        from .xclbin_parser import XclBin

        hwh_data = self.get_hwh_data()
        xclbin_data = self.get_xclbin_data()
        is_xsa = self.is_xsa()
        self._xsa_bitstream_file = None
        if hwh_data is not None and not is_xsa:

            if partial:
                parser = HWH(hwh_data=hwh_data)
            else:
                try:
                    parser = self._get_cache() 
                except CacheMetadataError:
                    parser = RuntimeMetadataParser(Metadata(input=self._filepath.with_suffix(".hwh")))
                except:
                    raise RuntimeError(f"Unable to parse metadata")

            if xclbin_data is None:
                xclbin_data = _create_xclbin(parser.mem_dict)
            xclbin_parser = XclBin(xclbin_data=xclbin_data)
            _unify_dictionaries(parser, xclbin_parser)

            if not partial:
                parser.refresh_hierarchy_dict()
        elif xclbin_data is not None:
            parser = XclBin(xclbin_data=xclbin_data)
        elif is_xsa:
            parser = RuntimeMetadataParser(Metadata(input=self._filepath))
            if xclbin_data is None:
                xclbin_data = _create_xclbin(parser.mem_dict)
            xclbin_parser = XclBin(xclbin_data=xclbin_data)
            _unify_dictionaries(parser, xclbin_parser)
            parser.refresh_hierarchy_dict()
            self._xsa_bitstream_file = parser.xsa._primaryProgrammableImagePath()
        else:
            return None
        parser.bin_data = self.get_bin_data()
        parser.xclbin_data = xclbin_data
        parser.dtbo_data = self.get_dtbo_data()
        return parser


class BitfileHandler(BitstreamHandler):
    def get_bin_data(self):
        bit_data = self._filepath.read_bytes()
        return bit2bin(bit_data)


class BinfileHandler(BitstreamHandler):
    def get_bin_data(self):
        return self._filepath.read_bytes()


class XclbinHandler(BitstreamHandler):
    def __init__(self, filepath):
        from .xclbin_parser import parse_xclbin_header

        super().__init__(filepath)
        self._data = self._filepath.read_bytes()
        self._sections, _ = parse_xclbin_header(self._data)

    def get_bin_data(self):
        from pynq._3rdparty.xclbin import AXLF_SECTION_KIND

        if AXLF_SECTION_KIND.BITSTREAM in self._sections:
            return bit2bin(self._sections[AXLF_SECTION_KIND.BITSTREAM])
        return None

    def get_xclbin_data(self):
        return self._data


class XsafileHandler(BitstreamHandler):
    def get_bin_data(self):
        if self._xsa_bitstream_file is None:
            raise RuntimeError("Could not find bitstream file in XSA")
        else:
            return _get_bitstream_handler(self._xsa_bitstream_file).get_bin_data()


class PdifileHandler(BitstreamHandler):
    """Handler for Versal Programmable Device Image (.pdi) files.

    A PDI is already in the layout the FPGA Manager expects, so unlike a
    .bit it needs no conversion. Metadata comes from the sibling .hwh and
    optional .dtbo through the base class.

    """

    def get_bin_data(self):
        return self._filepath.read_bytes()


_bitstream_handlers = {
    ".bit": BitfileHandler,
    ".bin": BinfileHandler,
    ".xsa": XsafileHandler,
    ".xclbin": XclbinHandler,
    ".pdi": PdifileHandler,
}


def _get_bitstream_handler(bitfile_name):
    filetype = Path(bitfile_name).suffix
    if filetype not in _bitstream_handlers:
        raise RuntimeError("Unknown file format")
    return _bitstream_handlers[filetype](bitfile_name)


BLANK_METADATA = r"""<?xml version="1.0" encoding="UTF-8"?>
<project name="binary_container_1">
  <platform vendor="xilinx" boardid="zcu111" name="name" featureRomTime="0">
    <version major="0" minor="1"/>
    <description/>
    <board name="xilinx.com:zcu111:1.4"
            vendor="xilinx.com" fpga="xczu28dr-ffvg1517-2-e">
      <interfaces/>
      <memories>
        <memory name="ddr4_0" type="ddr4" size="4GB"/>
        <memory name="ddr4_0" type="ddr4" size="4GB"/>
        <memory name="ddr4_0" type="ddr4" size="4GB"/>
        <memory name="ddr4_0" type="ddr4" size="4GB"/>
        <memory name="ddr4_0" type="ddr4" size="4GB"/>
        <memory name="ddr4_0" type="ddr4" size="4GB"/>
        <memory name="ddr4_0" type="ddr4" size="4GB"/>
        <memory name="ddr4_0" type="ddr4" size="4GB"/>
      </memories>
      <images>
        <image name="zcu111_board.jpeg" type="HDPI"/>
        <image name="" type="MDPI"/>
        <image name="" type="LDPI"/>
      </images>
      <id>
        <vendor/>
        <device/>
        <subsystem/>
      </id>
    </board>
    <build_flow/>
    <host architecture="unknown"/>
    <device name="fpga0" fpgaDevice="zynquplusRFSOC:xczu28dr:ffvg1517:-2:e"
            addrWidth="0">
      <core name="OCL_REGION_0" target="bitstream" type="clc_region"
            clockFreq="0MHz" numComputeUnits="60">
        <kernelClocks>
          <clock port="KERNEL_CLK" frequency="333.250000MHz"/>
          <clock port="DATA_CLK" frequency="99.999001MHz"/>
        </kernelClocks>
      </core>
    </device>
  </platform>
</project>
"""


def _ip_to_topology(mem_dict):
    topology = {
        "m_mem_data": [
            {
                "m_type": "MEM_DDR4",
                "m_used": 1,
                "m_sizeKB": 256 * 1024,
                "m_tag": "PSDDR",
                "m_base_address": 0,
            }
        ]
    }
    for k, v in mem_dict.items():
        v["xrt_mem_idx"] = len(topology["m_mem_data"])
        if not v.get("dfx"):
            topology["m_mem_data"].append(
                {
                    "m_type": "MEM_DDR4",
                    "m_used": 1,
                    "m_sizeKB": v["addr_range"] // 1024,
                    "m_tag": f'MIG{len(topology["m_mem_data"])}',
                    "m_base_address": v["phys_addr"],
                }
            )
    topology["m_count"] = len(topology["m_mem_data"])
    return {"mem_topology": topology}


def _as_str(obj):
    if type(obj) is bytes:
        return obj.decode()
    return obj


def _create_xclbin(mem_dict):
    """Create an XCLBIN file containing the specified memories"""
    import json
    import subprocess
    import tempfile

    with tempfile.TemporaryDirectory() as td:
        td = Path(td)
        (td / "metadata.xml").write_text(BLANK_METADATA)
        (td / "mem.json").write_text(json.dumps(_ip_to_topology(mem_dict)))
        completion = subprocess.run(
            [
                "xclbinutil",
                "--add-section=EMBEDDED_METADATA:RAW:metadata.xml",
                "--add-section=MEM_TOPOLOGY:JSON:mem.json",
                "--output",
                "t.xclbin",
                "--skip-bank-grouping",
            ],
            cwd=td,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
        )
        if completion.returncode != 0:
            raise RuntimeError("xclbinutil failed: " + _as_str(completion.stdout))
        return (td / "t.xclbin").read_bytes()


class EmbeddedXrtMemory(XrtMemory):
    def __init__(self, device, desc):
        super().__init__(device, desc)
        self._mmio = None

    def read(self, address):
        return self.mmio.read(address)

    def write(self, address, value):
        return self.mmio.write(address, value)

    @property
    def mmio(self):
        if self._mmio is None:
            import pynq

            self._mmio = pynq.MMIO(self.base_address, self.size, device=self.device)
        return self._mmio


class EmbeddedDevice(XrtDevice):
    """Device for interacting with Zynq-7000 and Zynq US+ logic

    For Zynq and Zynq US+ a hybrid approach is taken whereby FPGA
    manager is used to program the device, /dev/mem is used to
    interact with IP in the programmable logic and XRT is used to
    allocate memory.

    The device can take multiple forms of bitstream and metadata files:

     * .bit/.bin file with HWH metadata
     * .bit/.bin file with XclBin metadata
     * .bit/.bin file with both HWH and Xclbin metadata
     * Xclbin file containing a bitstream
     * XSA file containing a bitstream

    In situations where an xclbin file isn't provided a temporary one
    will be created so that all memories in the design can be allocated
    with XRT.

    Note that a bitstream will need to be loaded before any allocation
    can occur.

    Constructing `EmbeddedDevice` returns the subclass for the board's
    architecture. Subclasses should inherit the matching class from
    `pynq.pl_server.arch`.

    """

    BS_FPGA_MAN = "/sys/class/fpga_manager/fpga0/firmware"
    BS_FPGA_MAN_FLAGS = "/sys/class/fpga_manager/fpga0/flags"

    _probe_priority_ = 50

    @classmethod
    def _probe_(cls):
        if Path(EmbeddedDevice.BS_FPGA_MAN).exists():
            return [EmbeddedDevice()]
        else:
            return []

    def __new__(cls, *args, **kwargs):
        arch = _arch_class()
        if cls is EmbeddedDevice:
            from .versal_device import VersalDevice

            cls = {
                ZynqArch: ZynqDevice,
                ZynqUltrascaleArch: ZynqUltrascaleDevice,
                VersalArch: VersalDevice,
            }.get(arch, cls)
        elif arch is not None and not issubclass(cls, arch):
            warnings.warn(
                f"{cls.__name__} does not inherit {arch.__name__}, "
                f"the architecture of this board"
            )
        return super().__new__(cls)

    @property
    def default_memory(self):
        if not hasattr(self, "mem_dict"):
            initial_global_state_file_boot_check()
            if global_state_file_exists(): 
                gs = load_global_state()
                return self.get_memory(gs.psddr)
            else:
                raise RuntimeError("Overlay is not downloaded")
        else:
            mem_dict = self.mem_dict

        for k, v in mem_dict.items():
            if "base_address" in v:
                if v["base_address"] == 0:
                    return self.get_memory(v)
        raise RuntimeError("XRT design does not contain PS memory")

    def __init__(self, index=0, tag="embedded_xrt{}"):
        super().__init__(index, tag.format(index))
        self.capabilities["REGISTER_RW"] = False
        self.capabilities["MEMORY_MAPPED"] = True
        self.capabilities["CALLABLE"] = False
        self.arch = platform.machine()

    @property
    def _gpio_class(self):
        from pynq.gpio import GPIO

        return GPIO

    @property
    def _interrupt_class(self):
        from pynq.interrupt import Interrupt

        return Interrupt

    def get_memory(self, description):
        return EmbeddedXrtMemory(self, description)

    def mmap(self, base_addr, length):
        import mmap

        euid = os.geteuid()
        if euid != 0:
            raise EnvironmentError("Root permissions required.")

        # Align the base address with the pages
        virt_base = base_addr & ~(mmap.PAGESIZE - 1)

        # Calculate base address offset w.r.t the base address
        virt_offset = base_addr - virt_base

        # Open file and mmap
        mmap_file = os.open("/dev/mem", os.O_RDWR | os.O_SYNC)
        mem = mmap.mmap(
            mmap_file,
            length + virt_offset,
            mmap.MAP_SHARED,
            mmap.PROT_READ | mmap.PROT_WRITE,
            offset=virt_base,
        )
        os.close(mmap_file)
        array = np.frombuffer(mem, np.uint32, length >> 2, virt_offset)
        return array

    def gen_cache(self, bitstream, parser=None):
        """ Generates the cache of the metadata even if no download occurred """
        t = datetime.datetime.now()
        ts = "{}/{}/{} {}:{}:{} +{}".format(
            t.year, t.month, t.day, t.hour, t.minute, t.second, t.microsecond
        )
        if os.path.exists(bitstream.bitfile_name):
            gs=GlobalState(bitfile_name=str(bitstream.bitfile_name),
                             bitfile_hash=bitstream_hash(bitstream.bitfile_name),
                             timestamp=ts,
                             active_name=self.name,
                             psddr=parser.mem_dict.get("PSDDR", {}))
            ip=parser.ip_dict
            for sd_name, details in ip.items():
                if details["type"] in ["xilinx.com:ip:pr_axi_shutdown_manager:1.0",
                                       "xilinx.com:ip:dfx_axi_shutdown_manager:1.0",]:
                    gs.add(name=sd_name, addr=details["phys_addr"])
            save_global_state(gs)

        if not hasattr(parser, "_from_cache") and hasattr(parser, "systemgraph"):
            if not parser.systemgraph is None:
                pickle.dump(parser, open(_get_metadata_path(), "wb"))

    def write_fpga_manager(self, attribute, value):
        """Write a value to an FPGA Manager sysfs attribute.

        Parameters
        ----------
        attribute : str
            The path of the sysfs attribute to write.
        value : str
            The value to write.

        """
        with open(attribute, "w") as fd:
            fd.write(value)

    def download(self, bitstream, parser=None):

        if parser is None:
            from .xclbin_parser import XclBin

            parser = XclBin(xclbin_data=DEFAULT_XCLBIN)

        if not bitstream.binfile_name:
            _preload_binfile(bitstream, parser)

        if not bitstream.partial:
            self.shutdown()
            self.gen_cache(bitstream, parser)
            flag = 0
        else:
            flag = 1

        self.write_fpga_manager(self.BS_FPGA_MAN_FLAGS, str(flag))
        self.write_fpga_manager(self.BS_FPGA_MAN, bitstream.binfile_name)

        self.set_axi_port_width(parser)

        self._xrt_download(parser.xclbin_data)
        super().post_download(bitstream, parser, self.name)

    def get_bitfile_metadata(self, bitfile_name:str, partial:bool=False):
        parser = _get_bitstream_handler(bitfile_name).get_parser(partial=partial)
        if parser is None:
            raise RuntimeError("Unable to find metadata for bitstream")
        return parser


class ZynqDevice(ZynqArch, EmbeddedDevice):
    """Device for Zynq-7000 SoCs"""


class ZynqUltrascaleDevice(ZynqUltrascaleArch, EmbeddedDevice):
    """Device for Zynq UltraScale+ MPSoCs and RFSoCs"""
