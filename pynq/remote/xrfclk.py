import os
import sys
import glob
import re
from collections import defaultdict
from pynq.pl_server import Device
from pynq.pl_server.remote_device import RemoteDevice
from pynq.remote import xrfclk_pb2, xrfclk_pb2_grpc

_Config = defaultdict(dict)
_Devices = defaultdict(dict)

lmk_devices = []
lmx_devices = []

# Self-alias for classic compatibility: expose xrfclk.xrfclk as this module.
xrfclk = sys.modules[__name__]

# get target devices
def _get_device(device):
    """Return device if it is a RemoteDevice, else the active remote device."""
    if not isinstance(device, RemoteDevice):
        try:
            device = Device.active_device
        except Exception:
            raise RuntimeError("No remote device found. Either use the "
                               "PYNQ_REMOTE_DEVICES environment variable or pass "
                               "a device explicitly.")
    if not isinstance(device, RemoteDevice):
        raise RuntimeError("This function is only supported on remote devices.")
    return device


def _write_LMK_regs(reg_vals, device=None):
    device = _get_device(device)
    request = xrfclk_pb2.WriteLmkRegsRequest(reg_vals=reg_vals)
    try:
        device._stub['xrfclk'].write_lmk_regs(request)
    except Exception as e:
        raise RuntimeError(f"Failed to write LMK registers: {e}")


def _write_LMX_regs(reg_vals, device=None):
    device = _get_device(device)
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
    device = _get_device(device)

    if device not in _Devices or 'lmk' not in _Devices[device]:
        _find_devices(device)

    _read_tics_output(device.name)
    _set_LMK_regs(lmk_freq, device)
    _set_LMX_regs(lmx_freq, device)

# find clock devices
def _find_devices(device=None):
    device = _get_device(device)
    if not hasattr(device, '_stub'):
        device._stub = {}
    device._stub['xrfclk'] = xrfclk_pb2_grpc.XrfclkStub(device.client.channel)
    response = device._stub['xrfclk'].find_devices(xrfclk_pb2.FindDevicesRequest())
    _Devices[device]['lmk'] = response.lmk_device
    _Devices[device]['lmx'] = response.lmx_device

    # Classic-compatible globals for code that reads xrfclk.lmk_devices/lmx_devices.
    global lmk_devices, lmx_devices
    lmk_devices = [{'compatible': response.lmk_device}]
    lmx_devices = [{'compatible': response.lmx_device}]


def _load_tics_dir(dir_path):
    """Parse the CHIPNAME_FREQUENCY.txt TICS files in dir_path into _Config.

    Each file (e.g. LMK04828_245.76.txt) holds the register values for that chip
    at that frequency, stored as _Config[chip][freq] = [reg, ...]. Entries are
    overwritten, so a directory loaded later overrides one loaded earlier.
    """
    for path in sorted(glob.glob(os.path.join(dir_path, '*.txt'))):
        name = os.path.splitext(os.path.basename(path).lower())[0]
        match = re.match(r'^([a-z0-9]+)_([\d.]+)$', name)
        if not match:
            continue
        chip, freq = match.group(1), float(match.group(2))
        regs = []
        with open(path) as f:
            for line in f:
                m = re.search(r'0x[0-9A-Fa-f]+', line)
                if m:
                    regs.append(int(m.group(0), 16))
        if not regs:
            raise RuntimeError(f"No register values found in TICS file: {path}")
        _Config[chip][freq] = regs


def _read_tics_output(board=None):
    """Populate _Config with the board's TICS clock files plus local overrides.

    Loads the board's bundled files from pynq/remote/tics/<board>/ first, then any
    CHIPNAME_FREQUENCY.txt in the current working directory on top, so a local file
    overrides (or adds to) the bundled set. TICS register values are board-specific
    (boards sharing an LMK/LMX chip may ship different registers), hence the
    per-board bundled layout.
    """
    _Config.clear()
    module_dir = os.path.dirname(os.path.realpath(__file__))
    board_dir = os.path.join(module_dir, 'tics', board) if board else None
    if board_dir and os.path.isdir(board_dir):
        _load_tics_dir(board_dir)        # bundled base
    _load_tics_dir(os.getcwd())          # local overrides win

    if not _Config:
        raise RuntimeError(
            f"No TICS files found for board '{board}' or in the current directory. "
            f"Expected files named CHIPNAME_FREQUENCY.txt (e.g. LMK04828_245.76.txt).")
