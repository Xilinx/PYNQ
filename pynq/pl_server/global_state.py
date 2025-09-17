# Copyright (C) 2022 Xilinx, Inc
# SPDX-License-Identifier: BSD-3-Clause

import json
import os
from pathlib import Path
from typing import Dict, Optional

from pydantic import BaseModel

STATE_DIR = os.path.dirname(__file__)


class ShutdownIP(BaseModel):
    name: str
    base_addr: int

import hashlib
def bitstream_hash(filename:str)->int:
    """ Returns a hash of the bitstream """
    h = hashlib.sha1()
    with open(filename, 'rb') as file:
        chunk=0
        while chunk != b'':
            chunk = file.read(1024)
            h.update(chunk)
    return h.hexdigest()

class GlobalState(BaseModel):
    """A class that is used to globally keep track on some details of the currently
    configured bitstream"""

    bitfile_name: str
    active_name: str
    timestamp : str
    bitfile_hash : str = ""
    shutdown_ips: Dict[str, ShutdownIP] = {}
    psddr: Dict = {}

    def add(self, name: str, addr: int) -> None:
        """
        Adds a shutdown_ip to the global state
        """
        if name not in self.shutdown_ips:
            self.shutdown_ips[name] = ShutdownIP(name=name, base_addr=addr)

    def __init__(self, **kwargs):
        super().__init__(**kwargs)

def initial_global_state_file_boot_check(device_tag="")->None:
    """ Performs a check to see if this is a coldstart, if it is then clear the
    config file. """
    pl_state_file:str = "/sys/class/fpga_manager/fpga0/state"
    pl_flags_file:str = "/sys/class/fpga_manager/fpga0/flags"
    with open(pl_state_file, "r") as state_fd:
        state = state_fd.read()
        with open(pl_flags_file, "r") as flags_fd:
            flags = flags_fd.read()
            if (state[0:7] == "unknown") or flags[0:3] == "100":
                clear_global_state(device_tag)

def _get_state_path(device_tag=""):
    """Get the path to the state file for a specific device"""
    return Path(f"{STATE_DIR}/global_pl_state_{device_tag}.json") 

def global_state_file_exists(device_tag="") -> bool:
    """Returns true if the global_pl_state file is present in the system
    False otherwise"""
    return os.path.isfile(_get_state_path(device_tag))


def clear_global_state(device_tag="") -> None:
    """Clears the global state file, used on boot"""
    if global_state_file_exists(device_tag):
        os.remove(_get_state_path(device_tag))


def save_global_state(state: GlobalState, device_tag="") -> None:
    """Saves the global state of the PL in a known location.

    This includes details on whether the current configured IP
    needs a shutdown before a reconfiguration can happen, along
    with where the shutdown logic lives.
    """
    with open(_get_state_path(device_tag), "w") as state_file:
        state_file.write(state.json())


def load_global_state(device_tag="") -> Optional[GlobalState]:
    """Reads the global state of the PL from a known location, returns None if it cannot be found"""
    with open(_get_state_path(device_tag), "r") as state_file:
        jdict = json.load(state_file)
        return GlobalState.parse_obj(jdict)
    return None
