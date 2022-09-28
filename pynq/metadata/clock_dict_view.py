# Copyright (C) 2022 Xilinx, Inc
# SPDX-License-Identifier: BSD-3-Clause

import json
from typing import Dict

import pynqutils
from pynqmetadata import Module, ProcSysCore
from pynqmetadata.errors import FeatureNotYetImplemented


def _default_repr(obj):
    return repr(obj)


class ClockDictView:
    """
    Provides a view onto the Metadata object that displays all
    configurable clocks in the system. Models a dictionary, where
    the key is the index for the clock and the values contain:
        * 'enable' : int whether the clock is enabled
        * 'divisor0' : int divisor value for the clock
        * 'divisor1' : int divisor value for the clock
    """

    def __init__(self, module: Module) -> None:
        self._md = module

    @property
    def clock_dict(self) -> Dict:
        repr_dict = {}

        for core in self._md.blocks.values():
            if isinstance(core, ProcSysCore):
                for i in range(4):
                    repr_dict[i] = {}
                    repr_dict[i]["enable"] = int(core.find_clock_enable(i))
                    for j in range(2):
                        repr_dict[i][f"divisor{j}"] = core.find_clock_divisor(i, j)

        return repr_dict

    def items(self):
        return self.clock_dict.items()

    def __len__(self) -> int:
        return len(self.clock_dict)

    def __iter__(self):
        for clock in self.clock_dict:
            yield clock

    def _repr_json_(self) -> Dict:
        return json.loads(json.dumps(self.clock_dict, default=_default_repr))

    def __getitem__(self, key: str) -> None:
        return self.clock_dict[key]

    def keys(self):
        return self.clock_dict.keys()

    def __setitem__(self, key: str, value: object) -> None:
        """TODO: needs to send value into the model bypassing ip_dict
        this will require view tranlation in the other direction"""
        raise FeatureNotYetImplemented("IPDictView is currently only read only")
