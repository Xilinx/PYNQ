import os
import glob
import re
from collections import defaultdict
from pynq.pl_server import Device
from pynq.pl_server.remote_device import RemoteDevice
from pynq.remote import xrfclk_pb2, xrfclk_pb2_grpc

_Config = defaultdict(dict)
_Devices = defaultdict(dict)
_Config_loaded_from = None

lmk_devices = []
lmx_devices = []


def _write_LMK_regs(reg_vals, device):
    request = xrfclk_pb2.WriteLmkRegsRequest(reg_vals=reg_vals)
    try:
        device._stub['xrfclk'].write_lmk_regs(request)
    except Exception as e:
        raise RuntimeError(f"Failed to write LMK registers: {e}")


def _write_LMX_regs(reg_vals, device):
    request = xrfclk_pb2.WriteLmxRegsRequest(reg_vals=reg_vals)
    try:
        device._stub['xrfclk'].write_lmx_regs(request)
    except Exception as e:
        raise RuntimeError(f"Failed to write LMX registers: {e}")


def _set_LMK_regs(lmk_freq, device):
    if lmk_freq not in _Config[_Devices[device]['lmk']]:
        raise RuntimeError(f"LMK frequency {lmk_freq} MHz not supported for this device.")
    reg_vals = _Config[_Devices[device]['lmk']][lmk_freq]
    _write_LMK_regs(reg_vals, device)


def _set_LMX_regs(lmx_freq, device):
    if lmx_freq not in _Config[_Devices[device]['lmx']]:
        raise RuntimeError(f"LMX frequency {lmx_freq} MHz not supported for this device.")
    reg_vals = _Config[_Devices[device]['lmx']][lmx_freq]
    _write_LMX_regs(reg_vals, device)


def set_ref_clks(lmk_freq=122.88, lmx_freq=409.6, device=None):
    try:
        if not device:
            device = Device.active_device
    except Exception:
        raise RuntimeError("No remote device found. Either use the PYNQ_REMOTE_DEVICES "
                           "environment variable or pass device explicitly.")
    if not isinstance(device, RemoteDevice):
        raise RuntimeError("This function is only supported on remote devices.")

    if device not in _Devices or 'lmk' not in _Devices[device]:
        _find_devices(device)
    cwd = os.getcwd()
    if not _Config or _Config_loaded_from != cwd:
        _Config.clear()
        _read_tics_output()

    _set_LMK_regs(lmk_freq, device)
    _set_LMX_regs(lmx_freq, device)


def _find_devices(device):
    if not hasattr(device, '_stub'):
        device._stub = {}
    device._stub['xrfclk'] = xrfclk_pb2_grpc.XrfclkStub(device.client.channel)
    response = device._stub['xrfclk'].find_devices(xrfclk_pb2.FindDevicesRequest())
    _Devices[device]['lmk'] = response.lmk_device
    _Devices[device]['lmx'] = response.lmx_device


def _read_tics_output(config_dir=None):
    """Read all the TICS register values from all the txt files.

    Fill a single dictionary with dictionaries for each chip.
    Can store multiple frequencies per chip.

    Reading all the configurations from the specified directory, current
    working directory, or module directory (in that priority order).
    File format: `CHIPNAME_frequency.txt`.

    Parameters
    ----------
    config_dir : str, optional
        Path to directory containing TICS configuration files.
        If None, searches current working directory first, then module directory.

    """
    if config_dir is not None:
        if not os.path.exists(config_dir):
            raise RuntimeError(f"Specified config directory does not exist: {config_dir}")
        search_paths = [config_dir]
    else:
        cwd = os.getcwd()
        module_dir = os.path.dirname(os.path.realpath(__file__))
        bundled_tics_dir = os.path.join(module_dir, 'tics')
        search_paths = [cwd, bundled_tics_dir]

    _TICS_NAME = re.compile(r'^([a-z0-9]+)_([\d.]+)$')

    tics_files = []
    used_path = None
    for dir_path in search_paths:
        for s in glob.glob(os.path.join(dir_path, '*.txt')):
            basename = os.path.splitext(os.path.basename(s.lower()))[0]
            match = _TICS_NAME.match(basename)
            if match:
                tics_files.append((s, match.group(1), match.group(2)))
        if tics_files:
            used_path = dir_path
            break

    if not tics_files:
        search_str = f"'{config_dir}'" if config_dir else "current directory or module directory"
        raise RuntimeError(f"No TICS configuration files found in {search_str}. "
                           f"Expected files named CHIPNAME_FREQUENCY.txt "
                           f"(e.g. LMK04828_245.76.txt)")

    _Config.clear()
    for s, chip, freq_str in tics_files:
        with open(s, 'r') as f:
            lines = [l.rstrip("\n") for l in f]

        registers = []
        for line in lines:
            m = re.search(r'[\t]*(0x[0-9A-F]+)', line, re.IGNORECASE)
            if m:
                registers.append(int(m.group(1), 16))
        if not registers:
            raise RuntimeError(f"No register values found in TICS file: {s}")

        _Config[chip][float(freq_str)] = registers

    global _Config_loaded_from
    _Config_loaded_from = used_path if used_path else (config_dir or os.getcwd())
