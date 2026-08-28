"""Remote xrfclk: set RFSoC reference clocks over gRPC.

Used exactly like classic PYNQ:

    import xrfclk
    xrfclk.set_ref_clks(lmk_freq=245.76, lmx_freq=491.52)

The only difference from classic is where the clock (TICS) files come from.

Normally you don't need additional clock files. Each board's remote image 
already ships its own, so set_ref_clks works for the frequencies the board 
supports. Any unsupported frequency raises "Frequency <f> MHz is not valid".

To override or add a frequency, put a clock file named CHIPNAME_FREQUENCY.txt
in the directory you run from. A local file takes precedence over the board's.

When driving multiple boards from the same host, place board-specific files
in a subdirectory so they do not clash. The most specific match wins:

    <site-packages>/**   applies to every board, every working directory
    ./                   applies to every board
    ./<device.name>/     one board model, e.g. ./RFSoC4x2/ or ./ZCU208/
    ./<device.ip_addr>/  one specific board

Two boards of the same model can only be told apart by ./<device.ip_addr>/.
"""

import os
import sys
import glob
import re
import sysconfig
import grpc
from collections import defaultdict
from pynq.pl_server import Device
from pynq.pl_server.remote_device import RemoteDevice
from pynq.remote import xrfclk_pb2, xrfclk_pb2_grpc

# Per-device TICS register cache: _Config[device][chip][freq] = [reg, ...].
# Keyed by device so multiple boards (even sharing a chip + frequency) do not collide.
_Config = defaultdict(lambda: defaultdict(dict))
_Devices = defaultdict(dict)

# Classic (single-board) compatibility surface, read as xrfclk.lmk_devices /
# xrfclk.lmx_devices. With multiple boards these reflect only the most recently
# resolved device; per-device chip identities live in _Devices[device].
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


def _program_LMK(lmk_freq, device=None):
    """Ask the target to program the LMK from its own on-target TICS file."""
    device = _get_device(device)
    request = xrfclk_pb2.ProgramLmkRequest(freq=lmk_freq)
    try:
        device._stub['xrfclk'].program_lmk(request)
    except grpc.RpcError as e:
        if e.code() == grpc.StatusCode.NOT_FOUND:
            raise RuntimeError(f"Frequency {lmk_freq} MHz is not valid.")
        raise RuntimeError(f"Failed to program LMK: {e}")


def _program_LMX(lmx_freq, device=None):
    """Ask the target to program the LMX from its own on-target TICS file."""
    device = _get_device(device)
    request = xrfclk_pb2.ProgramLmxRequest(freq=lmx_freq)
    try:
        device._stub['xrfclk'].program_lmx(request)
    except grpc.RpcError as e:
        if e.code() == grpc.StatusCode.NOT_FOUND:
            raise RuntimeError(f"Frequency {lmx_freq} MHz is not valid.")
        raise RuntimeError(f"Failed to program LMX: {e}")


def _set_LMK_regs(lmk_freq, device):
    """Set the LMK: use a matching local TICS file if present, else the target's own file."""
    lmk = _Devices[device]['lmk']
    config = _Config[device]
    if lmk_freq in config.get(lmk, {}):
        _write_LMK_regs(config[lmk][lmk_freq], device)
    else:
        _program_LMK(lmk_freq, device)


def _set_LMX_regs(lmx_freq, device):
    """Set the LMX: use a matching local TICS file if present, else the target's own file."""
    lmx = _Devices[device]['lmx']
    config = _Config[device]
    if lmx_freq in config.get(lmx, {}):
        _write_LMX_regs(config[lmx][lmx_freq], device)
    else:
        _program_LMX(lmx_freq, device)


def set_ref_clks(lmk_freq=122.88, lmx_freq=409.6, device=None):
    device = _get_device(device)

    if device not in _Devices or 'lmk' not in _Devices[device]:
        _find_devices(device)

    # Load this device's local TICS overrides; per chip, a local match wins,
    # otherwise the target programs from its own on-target files. LMK before LMX.
    _read_tics_output(device)
    _set_LMK_regs(lmk_freq, device)
    _set_LMX_regs(lmx_freq, device)


def set_all_ref_clks(lmx_freq=409.6, device=None):
    """Deprecated; retained for classic compatibility. Calls set_ref_clks."""
    return set_ref_clks(122.88, lmx_freq, device)

# find clock devices
def _find_devices(device=None):
    device = _get_device(device)
    if not hasattr(device, '_stub'):
        device._stub = {}
    device._stub['xrfclk'] = xrfclk_pb2_grpc.XrfclkStub(device.client.channel)
    response = device._stub['xrfclk'].find_devices(xrfclk_pb2.FindDevicesRequest())

    # Per-device chip identities, used by the dispatch (safe with multiple boards).
    _Devices[device]['lmk'] = response.lmk_device
    _Devices[device]['lmx'] = response.lmx_device

    # Classic-compatible flat globals: reflect the device just resolved.
    global lmk_devices, lmx_devices
    lmk_devices = [{'compatible': response.lmk_device}]
    lmx_devices = [{'compatible': response.lmx_device}]


def _load_tics_file(path, config):
    """Parse one CHIPNAME_FREQUENCY.txt TICS file into config[chip][freq].

    The file (e.g. LMK04828_245.76.txt) holds the register values for that chip at
    that frequency, stored as config[chip][freq] = [reg, ...]. Files whose name does
    not match the CHIPNAME_FREQUENCY pattern are skipped. Entries are overwritten, so
    a file loaded later overrides one loaded earlier for the same chip+freq.
    """
    name = os.path.splitext(os.path.basename(path).lower())[0]
    match = re.match(r'^([a-z0-9]+)_([\d.]+)$', name)
    if not match:
        return
    chip, freq = match.group(1), float(match.group(2))
    regs = []
    with open(path) as f:
        for line in f:
            m = re.search(r'0x[0-9A-Fa-f]+', line)
            if m:
                regs.append(int(m.group(0), 16))
    if not regs:
        raise RuntimeError(f"No register values found in TICS file: {path}")
    config[chip][freq] = regs


def _load_tics_dir(dir_path, config):
    """Load the TICS files directly in dir_path (non-recursive) into config.

    A missing directory yields no files (skipped).
    """
    for path in sorted(glob.glob(os.path.join(dir_path, '*.txt'))):
        _load_tics_file(path, config)


def _load_venv_tics(config):
    """Load TICS files from anywhere under the active environment's site-packages.

    Resolved from the running interpreter (honours an active virtualenv), so it
    tracks whichever environment PYNQ is executing in, and searched recursively so
    TICS files bundled inside any installed package are found.
    """
    site_packages = sysconfig.get_paths()['purelib']
    for path in sorted(glob.glob(os.path.join(site_packages, '**', '*.txt'),
                                 recursive=True)):
        _load_tics_file(path, config)


def _read_tics_output(device):
    """Load this device's local TICS overrides, most-specific directory winning.

    Search order (a later directory overrides an earlier one for the same file):
      <site-packages>/**   environment-wide default (searched recursively)
      ./                   shared / single-board (classic layout)
      ./<device.name>/     per board model, e.g. RFSoC4x2, ZCU208
      ./<device.ip_addr>/  per board instance (distinguishes identical boards)

    Frequencies found here are programmed by sending their register values to the
    target (host file wins). Frequencies with no local file fall back to the board's
    on-target files via set_ref_clks. An empty result is valid: it just means every
    frequency comes from the target.
    """
    config = _Config[device]
    config.clear()
    _load_venv_tics(config)
    cwd = os.getcwd()
    _load_tics_dir(cwd, config)
    if device.name:
        _load_tics_dir(os.path.join(cwd, device.name), config)
    _load_tics_dir(os.path.join(cwd, str(device.ip_addr)), config)
