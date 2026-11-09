import os
import posixpath
from pathlib import Path
import pickle
import re
import datetime
import warnings
import numpy as np

import pynq._3rdparty.tinynumpy as tnp
from pynq.devicetree import SYSTEM_DEVICE_TREE_PATH, DeviceTreeSegment
from pynqmetadata.views.runtime import RuntimeMetadataParser
from pynqmetadata.frontends import Metadata
from .arch import VersalArch, ZynqArch, ZynqUltrascaleArch, _arch_class
from .device import Device
from .embedded_device import (
    _unify_dictionaries, DEFAULT_XCLBIN, CacheMetadataError,
    BitstreamHandler, bit2bin,
)
from .global_state import (
    GlobalState,
    save_global_state, load_global_state,
    global_state_file_exists, clear_global_state,
    _get_metadata_path,
    bitstream_hash
)
from pynq.remote import (
    remote_device_pb2_grpc, remote_device_pb2,
    mmio_pb2_grpc, mmio_pb2,
    buffer_pb2_grpc, buffer_pb2,
    gpio_pb2_grpc, gpio_pb2,
)

import grpc

PYNQ_PORT = 7967
BS_FPGA_MAN = "/sys/class/fpga_manager/fpga0/firmware"
BS_FPGA_MAN_FLAGS = "/sys/class/fpga_manager/fpga0/flags"
FIRMWARE = "/lib/firmware/"
BOOT_ID = "/proc/sys/kernel/random/boot_id"
PL_MARKER = "/tmp/pynq_pl_state"

class GrpcChannel:
    """gRPC Channel wrapper for remote device communication
    
    Establishes and manages a gRPC channel connection to a remote PYNQ device.
    Includes connection timeout and error handling.
    """
    
    def __init__(self, ip_addr, port):
        """Initialize gRPC channel connection
        
        Parameters
        ----------
        ip_addr : str
            IP address of the remote PYNQ device
        port : int
            Port number for gRPC communication
        """
        try:
            self.channel = grpc.insecure_channel(f"{ip_addr}:{port}")
            grpc.channel_ready_future(self.channel).result(timeout=5)
        except grpc.FutureTimeoutError:
            raise RuntimeError("Failed to connect to remote device")

class RemoteBitstreamHandler(BitstreamHandler):
    """Remote bitstream handler for processing bitstreams on remote devices
    
    Extends BitstreamHandler to handle bitstream parsing and metadata extraction
    for remote PYNQ devices. Uses default XCLBIN data for remote operations.
    """
    
    def __init__(self, filepath, device_tag=""):
        super().__init__(filepath, device_tag)

    def get_parser(self, partial:bool=False):
        """Returns a parser object for the remote bitstream

        The returned object contains all of the data that
        was processed from both the HWH and Xclbin metadata
        attached to the object. For remote devices, uses
        default XCLBIN data instead of creating synthetic data.

        Parameters
        ----------
        partial : bool, optional
            Whether this is a partial reconfiguration bitstream.
            Default is False.

        Returns
        -------
        parser : object or None
            Parser object containing metadata, or None if parsing fails
        """
        from .hwh_parser import HWH
        from .xclbin_parser import XclBin

        hwh_data = self.get_hwh_data()
        xclbin_data = DEFAULT_XCLBIN
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

            xclbin_parser = XclBin(xclbin_data=xclbin_data)
            _unify_dictionaries(parser, xclbin_parser)

            if not partial:
                parser.refresh_hierarchy_dict()
        elif is_xsa:
            parser = RuntimeMetadataParser(Metadata(input=self._filepath))
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

class RemoteBitfileHandler(RemoteBitstreamHandler):
    def get_bin_data(self):
        bit_data = self._filepath.read_bytes()
        return bit2bin(bit_data)

class RemoteBinfileHandler(RemoteBitstreamHandler):
    def get_bin_data(self):
        return self._filepath.read_bytes()

class RemotePdifileHandler(RemoteBinfileHandler):
    pass

class RemoteXsafileHandler(RemoteBitstreamHandler):
    def get_bin_data(self):
        if self._xsa_bitstream_file is None:
            raise RuntimeError("Could not find bitstream file in XSA")
        else:
            return _get_bitstream_handler(self._xsa_bitstream_file).get_bin_data()

_bitstream_handlers = {
    ".bit": RemoteBitfileHandler,
    ".bin": RemoteBinfileHandler,
    ".xsa": RemoteXsafileHandler,
    ".pdi": RemotePdifileHandler,
}


def _get_bitstream_handler(bitfile_name, device_tag=""):
    filetype = Path(bitfile_name).suffix
    if filetype not in _bitstream_handlers:
        raise RuntimeError("Unknown file format")
    return _bitstream_handlers[filetype](bitfile_name, device_tag)

class RemoteDevice(Device):
    """Device class for interacting with remote PYNQ devices via gRPC

    This device enables control of remote PYNQ boards over network connections.
    It provides bitstream downloading, memory allocation, MMIO operations,
    and other PYNQ functionality through gRPC remote procedure calls.

    The device supports multiple bitstream formats (.bit, .bin, .xsa) and
    handles metadata parsing, caching, and AXI port width configuration
    remotely.

    Constructing `RemoteDevice` returns the subclass for the board's
    architecture. Subclasses should inherit the matching class from
    `pynq.pl_server.arch`.
    """

    _probe_priority_ = 100
    _last_overlay_device = None
    
    @classmethod
    def _probe_(cls):
        if not os.environ.get("PYNQ_REMOTE_DEVICES", False):
            return []
        else:
            ip_env = os.environ.get("PYNQ_REMOTE_DEVICES", "")
            ip_list = [ip.strip() for ip in ip_env.split(",") if ip.strip()]
            num = len(ip_list)
            devices = [RemoteDevice(i, ip_list[i]) for i in range(num)]
            return devices

    def __init__(self, index=0, ip_addr=None, port=PYNQ_PORT, tag="remote{}"):
        super().__init__(tag.format(index))
        self.ip_addr = ip_addr
        self.port = port
        self._state_tag = re.sub(r"[^\w.-]", "_", f"{ip_addr}_{port}")
        self.client = GrpcChannel(self.ip_addr, self.port)
        self._stub = {
            'device': remote_device_pb2_grpc.RemoteDeviceStub(self.client.channel),
            'mmio': mmio_pb2_grpc.MmioStub(self.client.channel),
            'buffer': buffer_pb2_grpc.RemoteBufferStub(self.client.channel),
            'gpio': gpio_pb2_grpc.GpioStub(self.client.channel),
        }

        self.arch = self.get_arch()
        self.name = self.get_board_name()

        self.capabilities = {
            "REMOTE": True,
        }
        arch = _arch_class(self)
        if type(self) is RemoteDevice:
            self.__class__ = {
                ZynqArch: RemoteZynqDevice,
                ZynqUltrascaleArch: RemoteZynqUltrascaleDevice,
                VersalArch: RemoteVersalDevice,
            }.get(arch, RemoteDevice)
        elif arch is not None and not isinstance(self, arch):
            warnings.warn(
                f"{type(self).__name__} does not inherit {arch.__name__}, "
                f"the architecture of {self.ip_addr}"
            )

    @property
    def _gpio_class(self):
        return RemoteGPIO

    @property
    def _interrupt_class(self):
        return RemoteInterrupt

    def get_board_name(self):
        board_name_path = "/proc/device-tree/chosen/pynq_board"
        response = self.exists_file(board_name_path)
        if response.exists:
            content = self.read_file(board_name_path)
            return content.decode('utf-8').strip('\x00')
        else:
            return "Unknown"
        

    def get_arch(self):
        """Determine the architecture of the remote device
        
        This method reads "/proc/version" on the target to determine its CPU architecture 
        It also is used on device object creation to verify the IP address and gRPC 
        connection to a PYNQ.remote device.

        Returns
        -------
        str
            The architecture of the remote device, either "aarch64" or "armv7l"
        """
        response = self.exists_file("/proc/version")
        if response.exists:
            content = self.read_file("/proc/version")
            version_info = content.decode('utf-8').strip()
            if "aarch64" in version_info:
                return "aarch64"
            return "armv7l"
        else:
            raise RuntimeError(f"Unable to obtain architecture information for {self.ip_addr}")

    def exists_file(self, file_path):
        """Check if a file/directory exists on the remote device
        
        Parameters
        ----------
        file_path : str
            The path to the file on the remote device
        """
        response = self._stub['device'].existsfile(
            remote_device_pb2.ExistsFileRequest(file_path=file_path)
        )
        return response 

    def read_file(self, file_path, output_as_string=True):
        """Read a file from the remote device
        
        Parameters
        ----------
        file_path : str
            The path to the file on the remote device
        output_as_string : bool, optional
            If True, return the file content as bytes. If False, save the file
            locally. Default is True.
            
        Returns
        -------
        bytes or str
            If output_as_string is True, returns the file content as bytes.
            If output_as_string is False, returns the local filename where the
            file content was saved.
        """
        response_stream = self._stub['device'].readfile(
            remote_device_pb2.ReadFileRequest(file_path=file_path)
        )
        
        if output_as_string:
            content = b""
            for response in response_stream:
                content += response.data
            return content
        else:
            filename = os.path.basename(file_path)
            with open(filename, "wb") as f:
                for response in response_stream:
                    f.write(response.data)
            return filename

    def write_file(self, file_path, content):
        """Write content to a file on the remote device in chunks
        
        Parameters
        ----------
        file_path : str
            The path to the file on the remote device
        content : bytes
            The content to be written to the file
        """
        CHUNK_SIZE = 2*1024*1024  # 2MB chunks
        requests = []
        for i in range(0, len(content), CHUNK_SIZE):
            chunk = content[i:i+CHUNK_SIZE]
            requests.append(
                remote_device_pb2.WriteFileRequest(
                    file_path=file_path,
                    data=chunk,
                )
            )
        response = self._stub['device'].writefile(iter(requests))
        return response 

    def make_dir(self, dir_path):
        """Create a directory, and any missing parents, on the remote device

        Parameters
        ----------
        dir_path : str
            The path to the directory on the remote device
        """
        try:
            self._stub['device'].makedir(
                remote_device_pb2.MakeDirRequest(dir_path=dir_path)
            )
        except grpc.RpcError as e:
            if e.code() == grpc.StatusCode.UNIMPLEMENTED:
                raise RuntimeError(
                    f"The PYNQ remote server on {self.ip_addr} cannot create "
                    "directories; update the remote image"
                ) from e
            raise

    def remove_dir(self, dir_path):
        """Remove a directory from the remote device

        Parameters
        ----------
        dir_path : str
            The path to the directory on the remote device
        """
        self._stub['device'].removedir(
            remote_device_pb2.RemoveDirRequest(dir_path=dir_path)
        )

    def _devicetree_segment(self, abs_dtbo):
        return RemoteDeviceTreeSegment(abs_dtbo, self)

    def set_bitfile_name(self, bitfile_name: str) -> None:
        super().set_bitfile_name(bitfile_name)
        RemoteDevice._last_overlay_device = self

    def get_bitfile_metadata(self, bitfile_name:str, partial:bool=False):
        if not partial:
            self.initial_global_state_file_boot_check()
        parser = _get_bitstream_handler(bitfile_name, self._state_tag).get_parser(partial=partial)
        if parser is None:
            raise RuntimeError("Unable to find metadata for bitstream")
        return parser

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
                             psddr=parser.mem_dict.get("PSDDR", {}),
                             boot_id=self._boot_id())
            ip=parser.ip_dict
            for sd_name, details in ip.items():
                if details["type"] in ["xilinx.com:ip:pr_axi_shutdown_manager:1.0",
                                       "xilinx.com:ip:dfx_axi_shutdown_manager:1.0",]:
                    gs.add(name=sd_name, addr=details["phys_addr"])
            save_global_state(gs, self._state_tag)

        if not hasattr(parser, "_from_cache") and hasattr(parser, "systemgraph"):
            if not parser.systemgraph is None:
                pickle.dump(parser, open(_get_metadata_path(self._state_tag), "wb"))

    def mmap(self, address, length):
        """Create memory mapped I/O object for remote device
        
        Parameters
        ----------
        address : int
            Base address for memory mapping
        length : int
            Length of memory region to map
            
        Returns
        -------
        RemoteMMIO
            Memory mapped I/O object for remote access
        """
        return RemoteMMIO(self._stub['mmio'], address, length)

    @property
    def default_memory(self):
        return self.get_memory(None)

    def get_memory(self, description):
        """Create a memory object for a memory in the overlay

        Parameters
        ----------
        description : dict
            The entry from the overlay mem_dict describing the memory

        Returns
        -------
        RemoteMemory
            Memory object for allocating buffers on the remote device
        """
        return RemoteMemory(self, description)

    def download(self, bitstream, parser=None):
        """Download bitstream to the remote FPGA device

        This method handles the complete bitstream download process including:
        - Transferring bitstream file to remote device  
        - Configuring FPGA manager flags
        - Setting AXI port widths
        - Generating metadata cache

        Parameters
        ----------
        bitstream : object
            Bitstream object containing file and configuration information
        parser : object, optional
            Metadata parser object. If None, uses default XCLBIN parser.
        """
        if parser is None:
            from .xclbin_parser import XclBin
            parser = XclBin(xclbin_data=DEFAULT_XCLBIN)
            
        if not bitstream.binfile_name:
            bitstream.binfile_name = Path(bitstream.bitfile_name).stem + ".bin"

        bin_data = getattr(parser, "bin_data", None)
        if bin_data is None:
            bin_data = _get_bitstream_handler(bitstream.bitfile_name).get_bin_data()
        self.write_file(FIRMWARE + bitstream.binfile_name, bin_data)

        if not bitstream.partial:
            self.shutdown()
            self.gen_cache(bitstream, parser)
            flag = "0"
        else:
            flag = "1"

        response = self._stub['device'].set_bitstream_attrs(
            remote_device_pb2.SetBitstreamAttrsRequest(
                binfile_name=bitstream.binfile_name,
                partial=bitstream.partial,
            )
        )
        if not response:
            warnings.warn("Remote device failed to set bitstream attributes")

        self.write_file(BS_FPGA_MAN_FLAGS, flag.encode())
        self.write_file(BS_FPGA_MAN, bitstream.binfile_name.encode())
        if not bitstream.partial:
            token = ""
            if global_state_file_exists(self._state_tag):
                token = load_global_state(self._state_tag).timestamp
            self.write_file(PL_MARKER, token.encode())

        self.set_axi_port_width(parser)
        super().post_download(bitstream, parser, self.name)
    
    def _boot_id(self):
        return self.read_file(BOOT_ID).decode("utf-8").strip()

    def _pl_marker(self):
        if self.exists_file(PL_MARKER).exists:
            return self.read_file(PL_MARKER).decode("utf-8")
        return None

    def initial_global_state_file_boot_check(self):
        """Clear the global state unless it still describes the remote PL

        The remote FPGA Manager always reports "operating", so the kernel
        boot ID identifies a reboot, and a marker written after each full
        download identifies a bitstream loaded by another client.
        """
        if global_state_file_exists(self._state_tag):
            gs = load_global_state(self._state_tag)
            rebooted = gs.boot_id != self._boot_id()
            if rebooted:
                from pynq.ps import Clocks
                if Clocks.device is self and hasattr(Clocks, '_real_instance'):
                    del Clocks._real_instance
            if rebooted or self._pl_marker() != gs.timestamp:
                clear_global_state(self._state_tag)

    def shutdown(self):
        """Shutdown the AXI connections to the PL remotely
        
        Prepares the programmable logic for reconfiguration by shutting down
        AXI connections using shutdown manager IP cores. This prevents
        potential issues during bitstream loading.
        """
        self.initial_global_state_file_boot_check()

        if global_state_file_exists(self._state_tag):
            gs = load_global_state(self._state_tag)
            for sd_ip in gs.shutdown_ips.values():
                mmio = self.mmap(sd_ip.base_addr, length=4)
                # Request shutdown
                mmio.write(0x0, 0x1)
                i = 0
                while mmio.read(0x0) != 0x0F and i < 16000:
                    i += 1
                if i >= 16000:
                    warnings.warn(
                        "Timeout for shutdown manager. It's likely "
                        "the configured bitstream and metadata "
                        "don't match."
                    )

    def allocate(self, shape, dtype, cacheable=1, **kwargs):
        """Allocate memory buffer on the remote device

        Parameters
        ----------
        shape : int or tuple of int
            Shape of the buffer to allocate
        dtype : dtype
            Data type of the buffer elements  
        cacheable : int, optional
            Whether buffer should be cacheable (0=non-cacheable, 1=cacheable).
            For remote buffers, this is always set to 1.
        **kwargs
            Additional keyword arguments (currently unused)
        """
        cacheable = 1  # always cacheable for remote buffers
        elements = 1
        try:
            for s in shape:
                elements *= s
        except TypeError:
            elements = shape
        dtype = np.dtype(dtype)
        size = elements * dtype.itemsize
        response = self._stub['buffer'].allocate(
            buffer_pb2.AllocateRequest(size=size,
                                       dtype=dtype.str,
                                       cacheable=bool(cacheable)
                                       )
        )
        if not response:
            raise RuntimeError(response.msg)
        buffer_id = response.buffer_id
        ar = RemoteBuffer(
            shape,
            dtype,
            stub=self._stub['buffer'],
            device=self,
            buffer_id=buffer_id,
        )
        return ar


class RemoteZynqDevice(ZynqArch, RemoteDevice):
    """Remote device for Zynq-7000 SoCs"""


class RemoteZynqUltrascaleDevice(ZynqUltrascaleArch, RemoteDevice):
    """Remote device for Zynq UltraScale+ MPSoCs and RFSoCs"""


class RemoteVersalDevice(VersalArch, RemoteDevice):
    """Remote device for Versal adaptive SoCs"""


class RemoteDeviceTreeSegment(DeviceTreeSegment):
    """Device tree segment applied to a remote device

    Parameters
    ----------
    dtbo_path : str
        The path to the dtbo file on this machine.
    device : RemoteDevice
        The remote device the segment is applied to.
    """

    def __init__(self, dtbo_path, device):
        super().__init__(dtbo_path)
        self.device = device
        self.sysfs_dir = posixpath.join(SYSTEM_DEVICE_TREE_PATH, self.dtbo_name)

    def is_dtbo_applied(self):
        status = posixpath.join(self.sysfs_dir, "status")
        if not self.device.exists_file(status).exists:
            return False
        return self.device.read_file(status) == b"applied\n"

    def insert(self):
        with open(self.dtbo_path, "rb") as f:
            dtbo_data = f.read()
        self.device.make_dir(self.sysfs_dir)
        try:
            path = posixpath.join(self.sysfs_dir, "dtbo")
            self.device.write_file(path, dtbo_data)
            if self.device.read_file(path) != dtbo_data or not self.is_dtbo_applied():
                raise RuntimeError(
                    "Failed to apply device-tree overlay {}.".format(self.dtbo_name)
                )
        except Exception:
            self.remove()
            getattr(self.device, "devicetree_dict", {}).pop(self.dtbo_name, None)
            raise

    def remove(self):
        if self.device.exists_file(self.sysfs_dir).exists:
            self.device.remove_dir(self.sysfs_dir)


class RemoteMemory:
    """Remote Memory placeholder class

    Placeholder implementation for the memories of an overlay on remote
    devices. Allocating into a specific memory is not yet implemented for
    remote PYNQ devices, so buffers are allocated in the default memory.

    Parameters
    ----------
    device : RemoteDevice
        Device object for memory operations
    desc : dict
        The entry from the overlay mem_dict describing the memory
    """

    def __init__(self, device, desc):
        self.device = device
        self.desc = desc or {}
        self.idx = self.desc.get("idx")
        self.size = self.desc.get("size", self.desc.get("addr_range"))
        self.base_address = self.desc.get("base_address", self.desc.get("phys_addr"))
        warnings.warn(
            "Allocating into a specific memory is not yet implemented for "
            "remote devices; using the default memory instead."
        )

    def allocate(self, shape, dtype, **kwargs):
        """Create a new buffer in the memory

        Parameters
        ----------
        shape : tuple(int)
            Shape of the array
        dtype : np.dtype
            Data type of the array

        """
        return self.device.allocate(shape, dtype, **kwargs)


class RemoteGPIO:
    """Internal Helper class to wrap Linux's GPIO Sysfs API.

    This GPIO class does not handle PL I/O without the use of
    device tree overlays.

    Attributes
    ----------
    index : int
        The index of the GPIO, starting from the GPIO base.
    direction : str
        Input/output direction of the GPIO.
    """

    def __init__(self, gpio_index, direction, device=None):
        """Return a new RemoteGPIO object.

        Parameters
        ----------
        gpio_index : int
            The index of the RemoteGPIO using Linux's GPIO Sysfs API.
        direction : 'str'
            Input/output direction of the GPIO.
        device : RemoteDevice
            Device object for RemoteGPIO operations. Defaults to
            `Device.active_device`.
        """
        if device is None:
            device = Device.active_device
        self.device = device
        self.gpio_index = gpio_index
        self._direction = direction
        self._stub = device._stub['gpio']
        
        response = self._stub.get_gpio(
            gpio_pb2.GetGpioRequest(index=gpio_index, direction=direction)
        )
        self._gpio_id = response.gpio_id
        self._exported = True
        
    def read(self):
        """The method to read a value from the GPIO.

        Returns
        -------
        int
            An integer read from the GPIO

        """
        if self.direction != 'in':
            raise AttributeError("Cannot read from GPIO output.")
        
        response = self._stub.read(
            gpio_pb2.GpioReadRequest(gpio_id=self._gpio_id)
        )
        return response.value
        
    def write(self, value):
        """The method to write a value into the GPIO.

        Parameters
        ----------
        value : int
            An integer value, either 0 or 1

        Returns
        -------
        None

        """
        if self.direction != 'out':
            raise AttributeError("Cannot write to GPIO input.")
        
        if value not in (0, 1):
            raise ValueError("Can only write integer 0 or 1.")
        
        response = self._stub.write(
            gpio_pb2.GpioWriteRequest(gpio_id=self._gpio_id, value=value)
        )
        return
        
    def unexport(self):
        """The method to unexport the GPIO using Linux's GPIO Sysfs API.

        Returns
        -------
        None

        """
        response = self._stub.unexport(
            gpio_pb2.GpioUnexportRequest(gpio_id=self._gpio_id)
        )
        self._exported = False
        
    def release(self):
        """The method to release the GPIO.

        Returns
        -------
        None

        """
        self.unexport()
        
    def is_exported(self):
        """The method to check if a GPIO is still exported using
        Linux's GPIO Sysfs API.

        Returns
        -------
        bool
            True if the GPIO is still loaded.

        """
        if not self._exported:
            return False
        response = self._stub.is_exported(
            gpio_pb2.GpioIsExportedRequest(gpio_id=self._gpio_id)
        )
        return bool(response.is_exported)
    
    @property
    def index(self):
        return self.gpio_index
    
    @property
    def direction(self):
        return self._direction
    
    @property
    def path(self):
        warnings.warn("This property is not implemented for remote devices.")
    
    @staticmethod
    def get_gpio_base_path(target_label=None, device=None):
        """This method returns the path to the Remote GPIO base using Linux's
        GPIO Sysfs API. This path relates to the target device, not the 
        host machine.

        This is a static method. To use:

        >>> from pynq import GPIO
        
        >>> from pynq.pl_server import RemoteDevice
        
        >>> device = RemoteDevice(ip_addr='192.168.2.99')

        >>> gpio = GPIO.get_gpio_base_path(device=device)

        Parameters
        ----------
        target_label : str
            The label of the GPIO driver to look for, as defined in a
            device tree entry.
        device : RemoteDevice
            Remote device object for RemoteGPIO operations. Defaults to
            `Device.active_device`.

        Returns
        -------
        str
            The path to the Remote GPIO base.

        """
        if device is None:
            device = Device.active_device
        if target_label is None and isinstance(device, VersalArch):
            raise ValueError(
                "target_label must be specified on Versal; use "
                "'versal_gpio' or 'pmc_gpio'."
            )
        stub = device._stub['gpio']

        response = stub.get_gpio_base_path(
            gpio_pb2.GetGpioBasePathRequest(target_label=target_label)
        )
        if response.base_path == "":
            return None
        return response.base_path
    
    @staticmethod
    def get_gpio_base(target_label=None, device=None):
        """This method returns the GPIO base using Linux's GPIO Sysfs API.

        This is a static method. To use:

        >>> from pynq import GPIO
        
        >>> from pynq.pl_server import RemoteDevice
        
        >>> device = RemoteDevice(ip_addr='192.168.2.99')
        
        >>> gpio = GPIO.get_gpio_base(device)

        Note
        ----
        For path '/sys/class/gpio/gpiochip138/', this method returns 138.

        Parameters
        ----------
        target_label : str
            The label of the GPIO driver to look for, as defined in a
            device tree entry.
        device : RemoteDevice
            Remote device object for RemoteGPIO operations. Defaults to
            `Device.active_device`.

        Returns
        -------
        int
            The GPIO index of the base.

        """
        base_path = RemoteGPIO.get_gpio_base_path(target_label=target_label, device=device)
        if base_path is not None:
            return int(''.join(x for x in base_path if x.isdigit()))
        
    @staticmethod
    def get_gpio_pin(gpio_user_index, target_label=None, device=None):
        """This method returns a GPIO instance for PS GPIO pins.

        Users only need to specify an index starting from 0; this static
        method will map this index to the correct Linux GPIO pin number.

        Note
        ----
        The GPIO pin number can be calculated using:
        GPIO pin number = GPIO base + GPIO offset + user index
        e.g. The GPIO base is 138, and pin 54 is the base GPIO offset.
        Then the Linux GPIO pin would be (138 + 54 + 0) = 192.

        Parameters
        ----------
        gpio_user_index : int
            The index specified by users, starting from 0.
        target_label : str
            The label of the GPIO driver to look for, as defined in a
            device tree entry.
        device : RemoteDevice
            Remote device object for RemoteGPIO operations. Defaults to
            `Device.active_device`.

        Returns
        -------
        int
            The Linux Sysfs GPIO pin number.

        """
        if device is None:
            device = Device.active_device
        
        if isinstance(device, VersalArch):
            if target_label not in device._GPIO_MIN_USER_PIN:
                raise ValueError(
                    "target_label must be specified on Versal; use "
                    "'versal_gpio' or 'pmc_gpio'."
                )
            GPIO_OFFSET = device._GPIO_MIN_USER_PIN[target_label]
        elif target_label is not None:
            GPIO_OFFSET = 0
        else:
            GPIO_OFFSET = device._GPIO_MIN_USER_PIN
        return (RemoteGPIO.get_gpio_base(target_label=target_label, device=device) +
                GPIO_OFFSET +
                gpio_user_index)
        
    @staticmethod
    def get_gpio_npins(target_label=None, device=None):
        """This method returns the number of GPIO pins for the GPIO base
        using Linux's GPIO Sysfs API.

        This is a static method. To use:

        >>> from pynq import GPIO
        
        >>> from pynq.pl_server import RemoteDevice
        
        >>> device = RemoteDevice(ip_addr='192.168.2.99')

        >>> gpio = GPIO.get_gpio_npins()

        Parameters
        ----------
        target_label : str
            The label of the GPIO driver to look for, as defined in a
            device tree entry.
        device : RemoteDevice
            Remote device object for RemoteGPIO operations. Defaults to
            `Device.active_device`.

        Returns
        -------
        int
            The number of GPIO pins for the GPIO base.

        """
        if device is None:
            device = Device.active_device
        
        stub = device._stub['gpio']
        response = stub.get_gpio_npins(
            gpio_pb2.GetGpioNPinsRequest(
                target_label=target_label)
        )
        return response.npins 
        

class RemoteInterrupt:
    """Remote Interrupt placeholder class
    
    Placeholder implementation for interrupt handling on remote devices.
    Interrupt functionality is not yet implemented for remote PYNQ devices.
    
    Parameters
    ----------
    fullpath : str, optional
        Full path to interrupt device
    """
    
    def __init__(self, fullpath=None, device=None):
        self.fullpath = fullpath
        self.device = device if device is not None else Device.active_device
        warnings.warn(f"Interrupts are not yet implemented for remote devices")
        
    def wait(self, timeout=None):
        raise RuntimeError("Interrupts are not yet implemented for remote devices")


class RemoteUioController:
    """Remote UIO Controller placeholder class
    
    Placeholder implementation for UIO (Userspace I/O) operations on remote devices.
    UIO functionality is not yet implemented for remote PYNQ devices.
    
    Parameters
    ----------
    device : Device, optional
        Device object for UIO operations
    """
    
    def __init__(self, device=None):
        self.device = device
        warnings.warn("UIO operations are not yet implemented for remote devices")
    
    def add_event(self, event, number):
        raise RuntimeError("UIO operations are not yet implemented for remote devices")
    
    def __del__(self):
        pass

class _AccessHook:
    """Internal access hook for remote MMIO operations
    
    Provides read/write interface between tinynumpy arrays and remote MMIO.
    """
    
    def __init__(self, baseaddress, mmio):
        """Initialize access hook
        
        Parameters
        ----------
        baseaddress : int
            Base address for MMIO region
        mmio : RemoteMMIO
            Remote MMIO object for actual operations
        """
        self.baseaddress = baseaddress
        self.mmio = mmio

    def read(self, offset, length):
        """Read data from remote MMIO
        
        Parameters
        ----------
        offset : int
            Offset from base address
        length : int
            Number of bytes to read
        """
        data = self.mmio.read(offset, length)
        if isinstance(data, int):
            data = data.to_bytes(length, byteorder='little')
        return data

    def write(self, offset, data):
        """Write data to remote MMIO
        
        Parameters
        ----------
        offset : int
            Offset from base address  
        data : bytes or int
            Data to write to remote device
        """
        self.mmio.write(offset, data)

class RemoteMMIO:
    """Memory-mapped I/O for remote devices via gRPC
    
    Provides memory-mapped I/O operations on remote PYNQ devices through
    gRPC remote procedure calls. 
    """
    
    def __init__(self, stub, address, length):
        """Initialize RemoteMMIO object
    
    Parameters
    ----------
    stub : grpc stub
        gRPC stub for MMIO operations
    address : int
        Base address for memory-mapped region
    length : int
        Length of memory-mapped region in bytes
    """
        self._stub = stub
        response = self._stub.get_mmio(
            mmio_pb2.GetMmioRequest(base_addr=address, length=length)
        )
        if response.msg:
            raise RuntimeError(response.msg)
        self.mmio_id = response.mmio_id

        self._hook = _AccessHook(address, self)
        stype = tnp._convert_dtype("u4", to="array")
        fake_buffer = tnp._FakeBuffer(length // 4, stype, hook=self._hook)
        self.array = tnp.ndarray(shape=(length // 4,), dtype="u4", buffer=fake_buffer)

    def read(self, offset=0, length=4, word_order="little"):
        if length not in [1, 2, 4, 8]:
            raise ValueError("MMIO currently only supports 1, 2, 4 and 8-byte reads.")
        if offset < 0:
            raise ValueError("Offset cannot be negative.")
        if length == 8 and word_order not in ["big", "little"]:
            raise ValueError("MMIO only supports big and little endian.")
        if offset % 4:
            raise MemoryError("Unaligned read: offset must be multiple of 4.")

        response = self._stub.read(
            mmio_pb2.ReadRequest(mmio_id=self.mmio_id, offset=offset,
                                          length=length, word_order=word_order)
        )
        if response.msg:
            raise RuntimeError(response.msg)
        return response.data

    def write(self, offset, data):
        if offset < 0:
            raise ValueError("Offset cannot be negative.")
        if offset % 4:
            raise MemoryError("Unaligned write: offset must be multiple of 4.")
        if type(data) in [int, np.int32, np.uint32]:
            if data < 0:
                # Convert data to equivalent unsigned using two's complement for 32 bit
                data = data + (1 << 32) 
            data_bytes = data.to_bytes(4, byteorder='little')
        elif type(data)in [np.int64, np.uint64]:
            if data < 0:
                # Convert data to equivalent unsigned using two's complement for 64 bit
                data = data + (1 << 64) 
            data_bytes = data.to_bytes(8, byteorder='little')
        elif isinstance(data, bytes):
            data_bytes = data
        else:
            raise ValueError("Data type must be int or bytes.")
        
        if len(data_bytes) % 4:
            raise MemoryError("Unaligned write: data length must be multiple of 4.")
        
        response = self._stub.write(
            mmio_pb2.WriteRequest(
                mmio_id=self.mmio_id,
                offset=offset,
                data=data_bytes
                )
        )

        if response.msg:
            raise RuntimeError(response.msg)


class RemoteBuffer(np.ndarray):
    """A subclass of numpy.ndarray which represents memory allocated
    on a remote device. The buffer operates on a local cache and
    requires explicit synchronization with the remote device using
    `sync_to_device` and `sync_from_device`. The DMA driver handles
    this automatically when using the `transfer` method 
    
    As physically contiguous memory is a limited resource on remote 
    devices, it is strongly recommended to free the underlying 
    buffer with `del` when the buffer is no longer needed. 
    Alternatively a `with` statement can be used to automatically 
    free the memory at the end of the scope.

    This class should not be constructed directly and instead
    created using `RemoteDevice.allocate()`.

    Attributes
    ----------
    device_address: int
        The physical address of the buffer on the remote device.
    coherent: bool
        Whether the buffer is cache coherent. Always set to False for RemoteBuffer.
    stub: grpc stub
        gRPC stub for buffer operations.
    buffer_id: int
        Unique identifier for the remote buffer.
    freed: bool
        Indicates whether the buffer has been freed.
    device: RemoteDevice
        The remote device associated with this buffer.

    """

    def __new__(cls, shape, dtype, stub, buffer_id, device=None, coherent=False):
        """
        Create a new RemoteBuffer instance.

        Parameters
        ----------
        shape : tuple
            Shape of the buffer.
        dtype : str or numpy.dtype
            Data type of the buffer.
        stub : grpc stub
            gRPC stub for buffer operations.
        buffer_id : int
            Unique identifier for the remote buffer.
        device : RemoteDevice, optional
            The remote device associated with this buffer. Default is None.
        coherent : bool, optional
            Whether the buffer is cache coherent. Default is False.

        Returns
        -------
        RemoteBuffer
            A new instance of the RemoteBuffer class.
        """
        self = super().__new__(cls, shape, dtype)
        self.stub = stub
        self.buffer_id = buffer_id
        self.coherent = False  # Always set to False for RemoteBuffer
        self.freed = False
        self.device = device
        return self

    def __array_finalize__(self, obj):
        if isinstance(obj, RemoteBuffer):
            self.coherent = obj.coherent
            self.stub = obj.stub
            self.buffer_id = obj.buffer_id
            self.device = obj.device
        else:
            self.stub = None
            self.buffer_id = None
            self.coherent = None

    def __del__(self):
        if hasattr(self, 'freed') and not self.freed:
            try:
                self.freebuffer()
            except Exception:
                pass
    

    def freebuffer(self):
        """Free the remote buffer memory
        
        Explicitly releases the buffer memory on the remote device.
        Called automatically by destructor.
        """
        if not self.freed:
            self.freed = True
            response = self.stub.freebuffer(
                buffer_pb2.FreeBufferRequest(buffer_id=self.buffer_id)
            )
            if response.msg:
                raise RuntimeError(response.msg)

    def flush(self):
        """Flush local changes to the remote buffer."""
        data_bytes = self.tobytes()
        total_size = len(data_bytes)

        def request_iterator():
            CHUNK_SIZE = 2 * 1024 * 1024  # 2MB chunks
            for i in range(0, total_size, CHUNK_SIZE):
                chunk = data_bytes[i:i + CHUNK_SIZE]
                yield buffer_pb2.BufferWriteRequest(
                    buffer_id=self.buffer_id,
                    data=chunk
                )

        response = self.stub.write(request_iterator())
        if response.msg:
            raise RuntimeError(response.msg)

        # Perform a FlushRequest to sync PS and PL
        response = self.stub.flush(
            buffer_pb2.FlushRequest(buffer_id=self.buffer_id)
        )
        if response.msg:
            raise RuntimeError(response.msg)

    def invalidate(self):
        """Invalidate the local cache and sync from the remote buffer."""
        # Perform an InvalidateRequest to sync PS and PL
        response = self.stub.invalidate(
            buffer_pb2.InvalidateRequest(buffer_id=self.buffer_id)
        )
        if response.msg:
            raise RuntimeError(response.msg)

        # Perform a BufferReadRequest to update the local cache
        request = buffer_pb2.BufferReadRequest(buffer_id=self.buffer_id)
        response_stream = self.stub.read(request)

        data_bytes = b""
        for response in response_stream:
            data_bytes += response.data

        flat_data = np.frombuffer(data_bytes, dtype=self.dtype)
        self[:] = flat_data.reshape(self.shape)

    def sync_to_device(self):
        """Copy the contents of the local buffer to the remote device."""
        self.flush()

    def sync_from_device(self):
        """Copy the contents of the remote buffer to the local buffer."""
        self.invalidate()

    @property
    def cacheable(self):
        return not self.coherent
        
    @property
    def physical_address(self):
        response = self.stub.physical_address(
            buffer_pb2.AddressRequest(buffer_id=self.buffer_id)
        )
        if response.msg:
            raise RuntimeError(response.msg)
        return response.address
    
    @property
    def device_address(self):
        return self.physical_address 

    @property
    def virtual_address(self):
        response = self.stub.virtual_address(
            buffer_pb2.AddressRequest(buffer_id=self.buffer_id)
        )
        if response.msg:
            raise RuntimeError(response.msg)
        return response.address
    
    def __enter__(self):
        """Enter the runtime context related to this object."""
        return self

    def __exit__(self, exc_type, exc_value, traceback):
        """Exit the runtime context and release the buffer."""
        self.freebuffer()
        return 0
