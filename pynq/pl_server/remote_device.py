import os
import asyncio
from pathlib import Path
import pickle
import datetime
import warnings
import numpy as np

import pynq._3rdparty.tinynumpy as tnp
from pynqmetadata.views.runtime import RuntimeMetadataParser
from pynqmetadata.frontends import Metadata
from .device import Device
from .embedded_device import (
    _unify_dictionaries, DEFAULT_XCLBIN, CacheMetadataError,
    BitstreamHandler, bit2bin,
    ZU_FPD_SLCR_REG, ZU_FPD_SLCR_VALUE, ZU_AXIFM_REG, ZU_AXIFM_VALUE, 
)
from .global_state import (
    GlobalState,
    save_global_state, load_global_state,
    global_state_file_exists, clear_global_state,
    bitstream_hash
)
from pynq.remote import (
    remote_device_pb2_grpc, remote_device_pb2,
    mmio_pb2_grpc, mmio_pb2,
    buffer_pb2_grpc, buffer_pb2,
    gpio_pb2_grpc, gpio_pb2,
    interrupt_pb2_grpc, interrupt_pb2,
)

import grpc

PYNQ_PORT = 7967
BS_FPGA_MAN = "/sys/class/fpga_manager/fpga0/firmware"
BS_FPGA_MAN_FLAGS = "/sys/class/fpga_manager/fpga0/flags"
FIRMWARE = "/lib/firmware/"

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
    
    def __init__(self, filepath):
        super().__init__(filepath)

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
            self._xsa_bitstream_file = parser.xsa.bitstreamPaths[0]
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

class RemoteXsafileHandler(RemoteBitstreamHandler):
    def get_bin_data(self):
        if self._xsa_bitstream_file is None:
            raise RuntimeError("Could not find bitstream file in XSA")
        else:
            return bit2bin(Path(self._xsa_bitstream_file).read_bytes())

_bitstream_handlers = {
    ".bit": RemoteBitfileHandler,
    ".bin": RemoteBinfileHandler,
    ".xsa": RemoteXsafileHandler,
}


def _get_bitstream_handler(bitfile_name):
    filetype = Path(bitfile_name).suffix
    if filetype not in _bitstream_handlers:
        raise RuntimeError("Unknown file format")
    return _bitstream_handlers[filetype](bitfile_name)

class RemoteDevice(Device):
    """Device class for interacting with remote PYNQ devices via gRPC

    This device enables control of remote PYNQ boards over network connections.
    It provides bitstream downloading, memory allocation, MMIO operations,
    and other PYNQ functionality through gRPC remote procedure calls.

    The device supports multiple bitstream formats (.bit, .bin, .xsa) and
    handles metadata parsing, caching, and AXI port width configuration
    remotely.
    """

    _probe_priority_ = 100
    
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
        self.client = GrpcChannel(self.ip_addr, self.port)
        self._stub = {
            'device': remote_device_pb2_grpc.RemoteDeviceStub(self.client.channel),
            'mmio': mmio_pb2_grpc.MmioStub(self.client.channel),
            'buffer': buffer_pb2_grpc.RemoteBufferStub(self.client.channel),
            'gpio': gpio_pb2_grpc.GpioStub(self.client.channel),
            'interrupt': interrupt_pb2_grpc.RemoteInterruptStub(self.client.channel),
        }

        self.arch = self.get_arch()
        self.name = self.get_board_name()

        self.capabilities = {
            "REMOTE": True,
            "INTERRUPT": True,
        }

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
            raise RuntimeError(f"Unable to obtain architecture information for {self.addr}")  

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

    def get_bitfile_metadata(self, bitfile_name:str, partial:bool=False):
        parser = _get_bitstream_handler(bitfile_name).get_parser(partial=partial)
        if parser is None:
            raise RuntimeError("Unable to find metadata for bitstream")
        return parser

    def set_axi_port_width(self, parser):
        """Set the AXI port width on the remote device

        This method configures AXI port widths to resolve discrepancies between 
        PS configurations during boot and those required by the bitstream. 
        It is usually required for full bitstream reconfiguration.

        For remote execution, register operations are performed via gRPC calls.

        Check https://www.xilinx.com/support/answers/66295.html for more
        information on the meaning of register values.

        Currently only Zynq UltraScale+ devices support data width changes.
        """
        from pynq.registers import Register
        if not hasattr(parser, "ps_name"):
            # Setting port widths not supported for xclbin-only designs
            return
        parameter_dict = parser.ip_dict[parser.ps_name]["parameters"]
        if parser.family_ps == "zynq_ultra_ps_e":
            for para in ZU_FPD_SLCR_REG:
                if para in parameter_dict:
                    width = parameter_dict[para]
                    for reg_name in ZU_FPD_SLCR_REG[para]:
                        addr = ZU_FPD_SLCR_REG[para][reg_name]["addr"]
                        f = ZU_FPD_SLCR_REG[para][reg_name]["field"]
                        Register(addr)[f[0] : f[1]] = ZU_FPD_SLCR_VALUE[width]

            for para in ZU_AXIFM_REG:
                if para in parameter_dict:
                    width = parameter_dict[para]
                    for reg_name in ZU_AXIFM_REG[para]:
                        addr = ZU_AXIFM_REG[para][reg_name]["addr"]
                        f = ZU_AXIFM_REG[para][reg_name]["field"]
                        Register(addr)[f[0] : f[1]] = ZU_AXIFM_VALUE[width]

    def gen_cache(self, bitstream, parser=None):
        """ Generates the cache of the metadata even if no download occurred """
        if not hasattr(parser, "_from_cache"):
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

            if hasattr(parser, "systemgraph"):
                if not parser.systemgraph is None:
                    STATE_DIR = os.path.dirname(__file__)
                    pickle.dump(parser, open(f"{STATE_DIR}/_current_metadata.pkl", "wb"))

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

        response = self.exists_file(FIRMWARE + bitstream.binfile_name)
        if not response.exists:
            self.write_file(FIRMWARE + bitstream.binfile_name, parser.bin_data)
                
        self.write_file(BS_FPGA_MAN_FLAGS, flag.encode())
        self.write_file(BS_FPGA_MAN, bitstream.binfile_name.encode())

        self.set_axi_port_width(parser)
        super().post_download(bitstream, parser, self.name)
    
    def initial_global_state_file_boot_check(self):
        """Check and clear global state based on FPGA manager status
        
        Reads the FPGA manager state and flags from the remote device to
        determine if global state should be cleared. Currently clears
        global state by default for remote devices.
        """
        pl_state_file:str = "/sys/class/fpga_manager/fpga0/state"
        pl_flags_file:str = "/sys/class/fpga_manager/fpga0/flags"
        state = self.read_file(pl_state_file, output_as_string=True).decode('utf-8').strip()
        flags = self.read_file(pl_flags_file, output_as_string=True).decode('utf-8').strip()
        # if (state[0:7] == "unknown") or flags[0:3] == "100":
        #     clear_global_state()
        # seeing issue where pynq.remote image state is always "operating"
        # clearing global state by default for now
        clear_global_state()

    def shutdown(self):
        """Shutdown the AXI connections to the PL remotely
        
        Prepares the programmable logic for reconfiguration by shutting down
        AXI connections using shutdown manager IP cores. This prevents
        potential issues during bitstream loading.
        """
        self.initial_global_state_file_boot_check()

        if global_state_file_exists():
            gs = load_global_state()
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
            Device object for RemoteGPIO operations
        """
        if device is None:
            raise RuntimeError("RemoteGPIO requires a RemoteDevice instance")
        self.device = device
        self.gpio_index = gpio_index
        self._direction = direction
        self._stub = device._stub['gpio']
        
        response = self._stub.get_gpio(
            gpio_pb2.GetGpioRequest(index=gpio_index, direction=direction)
        )
        self._gpio_id = response.gpio_id
        
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
            Remote device object for RemoteGPIO operations

        Returns
        -------
        str
            The path to the Remote GPIO base.

        """
        if device is None:
            raise RuntimeError("get_gpio_base_path requires a RemoteDevice instance.")
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
            Remote device object for RemoteGPIO operations

        Returns
        -------
        int
            The GPIO index of the base.

        """
        if device is None:
            raise RuntimeError("get_gpio_base requires a RemoteDevice instance.")
        
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

        Returns
        -------
        int
            The Linux Sysfs GPIO pin number.

        """
        if device is None:
            raise RuntimeError("get_gpio_pin requires a RemoteDevice instance.")
        
        if target_label is not None:
            GPIO_OFFSET = 0
        else:
            if device.arch == "aarch64":
                GPIO_OFFSET = 78
            else:
                GPIO_OFFSET = 54
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
            Remote device object for RemoteGPIO operations

        Returns
        -------
        int
            The number of GPIO pins for the GPIO base.

        """
        if device is None:
            raise RuntimeError("get_gpio_npins requires a RemoteDevice instance.")
        
        stub = device._stub['gpio']
        response = stub.get_gpio_npins(
            gpio_pb2.GetGpioNPinsRequest(
                target_label=target_label)
        )
        return response.npins 
        

class RemoteInterrupt:
    """Remote interrupt support over gRPC.

    Registers an interrupt on the remote server and waits for hardware
    events via a unary gRPC call wrapped with asyncio.wrap_future().

    If the Overlay is changed or re-downloaded this object is invalidated
    and waiting raises a RuntimeError, mirroring the local Interrupt class.
    """

    def __init__(self, fullpath):
        """Initialise an Interrupt object attached to the specified pin

        Parameters
        ----------
        fullpath : str
            Fully qualified interrupt pin name in the block diagram of the
            form ${cell}/${pin} (e.g. "axi_dma_0/mm2s_introut"). Raises an
            exception if the pin cannot be found in the currently active
            Overlay.
        """
        self.fullpath = fullpath
        self._interrupt_id = None
        self._stub = None
        self._timestamp = None
        self._ensure_registered()

    def _ensure_registered(self):
        device = Device.active_device
        if not device.has_capability("REMOTE") or not device.has_capability("INTERRUPT"):
            raise RuntimeError("Active device does not support remote interrupts")
        self._stub = device._stub['interrupt']
        from ..pl import PL
        if self.fullpath not in PL.interrupt_pins:
            raise ValueError("No Pin of name {} found".format(self.fullpath))

        pin_info = PL.interrupt_pins[self.fullpath]
        controller_name = pin_info.get('controller', pin_info.get('parent', ''))
        pin_index = pin_info['index']

        raw_irq = 0
        controller_phys_addr = 0
        if controller_name:
            ctrl_info = PL.interrupt_controllers.get(controller_name, {})
            raw_irq = ctrl_info.get('raw_irq', 0)
            controller_phys_addr = PL.ip_dict.get(
                ctrl_info.get('name', controller_name), {}
            ).get('phys_addr', 0)

        try:
            resp = self._stub.register_interrupt(
                interrupt_pb2.RegisterRequest(
                    pin_name=self.fullpath,
                    pin_index=pin_index,
                    raw_irq=raw_irq,
                    controller_phys_addr=controller_phys_addr,
                ))
        except grpc.RpcError as e:
            raise RuntimeError("Interrupt registration RPC failed: {}".format(e))
        if not resp.interrupt_id:
            raise RuntimeError(
                "Interrupt registration failed: {}".format(resp.msg))
        self._interrupt_id = resp.interrupt_id
        self._timestamp = PL.timestamp
    
    async def wait(self):
        """Wait for the interrupt to fire on the remote board.
        
        Uses gRPC's .future() variant so that asyncio cancellation
        propagates to the server: cancelling the awaiting task calls
        call.cancel(), which signals the RPC to terminate and lets
        the server's IsCancelled() check release the waiter.
        """
        from ..pl import PL
        if PL.timestamp != self._timestamp:
            raise RuntimeError("Interrupt invalidated by Overlay change")
        call = self._stub.wait_for_interrupt.future(
            interrupt_pb2.WaitRequest(interrupt_id=self._interrupt_id))
        try:
            resp = await asyncio.wrap_future(call)
        except asyncio.CancelledError:
            call.cancel()
            raise
        except grpc.RpcError as e:
            if e.code() == grpc.StatusCode.CANCELLED:
                raise RuntimeError(e.details() or "Interrupt invalidated by Overlay change")
            raise
        if resp.status == interrupt_pb2.WaitResponse.FIRED:
            return
        elif resp.status == interrupt_pb2.WaitResponse.TIMEOUT:
            raise TimeoutError("Interrupt wait timed out")
        elif resp.status == interrupt_pb2.WaitResponse.ERROR:
            raise RuntimeError(f"Interrupt error: {resp.msg}")
    
    def __del__(self):
        if self._interrupt_id and self._stub:
            try:
                self._stub.release_interrupt(
                    interrupt_pb2.ReleaseRequest(
                        interrupt_id=self._interrupt_id))
            except Exception:
                pass


class RemoteUioController:
    """Stub for remote UIO controller.
    
    The server handles UIO internally, so this class is not used
    in remote mode. Kept for API compatibility.
    """
    
    def __init__(self, device=None):
        warnings.warn(
            "RemoteUioController is a no-op stub. Use pynq.Interrupt "
            "for interrupt handling on remote devices.",
            stacklevel=2,
        )
        self.device = device
    
    def add_event(self, event, number):
        pass
    
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