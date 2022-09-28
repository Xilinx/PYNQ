# Copyright (C) 2022 Xilinx, Inc
# SPDX-License-Identifier: BSD-3-Clause

import json
from typing import Dict

from pynqmetadata import Module, ProcSysCore, SubordinatePort
from pynqmetadata.errors import FeatureNotYetImplemented

from .append_drivers_pass import DriverExtension

from .metadata_view import MetadataView


class GpioDictView(MetadataView):
    """
    Provides a view onto the Metadata object that displays all
    GPIO pins controlled by the PS. Models a dictionary where
    the keys are the names of the pin and each entry contains:
        * the index of the pin :int
        * the current state of the pin : str
    """

    def __init__(self, module: Module) -> None:
        super().__init__(module=module)
        self._state = {}

    @property
    def view(self) -> Dict:
        repr_dict = {}

        for core in self._md.blocks.values():
            if isinstance(core, ProcSysCore):
                gpio = core.gpio
                for n, i in gpio.items():
                    repr_dict[n] = {}
                    if n in self._state:
                        repr_dict[n]["state"] = self._state[n]
                    else:
                        repr_dict[n]["state"] = None
                    pins = set()
                    for p in i["pins"]:
                        ref: str = f"{p.parent().parent().hierarchy_name}/{p.name}"
                        pins.add(ref)
                    repr_dict[n]["pins"] = pins
                    repr_dict[n]["index"] = int(i["index"])

        return repr_dict

    def __setitem__(self, key: str, value: object) -> None:
        """Set the state of an item in the gpio_dict"""
        self._state[key] = value
