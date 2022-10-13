# Copyright (C) 2022 Xilinx, Inc
# SPDX-License-Identifier: BSD-3-Clause

import json
import re
from typing import Dict, List

from pydantic import Field
from pynqmetadata import Core, MetadataExtension, Module, Signal
from .metadata_view import MetadataView


class InterruptIndex(MetadataExtension):
    index: int = Field(
        ...,
        description="The interrupt index that this pin is associated with in the PYNQ runtime",
    )
    controller: str = Field(
        default="unknown",
        description="The name of the interrupt controller for this interrupt pin",
    )


def _default_repr(obj):
    return repr(obj)


class InterruptPinsView(MetadataView):
    """
    Provides a view onto the metadata object that displays all
    the AXI interrupt controllers in the system that are 
    attached to the Processing System interrupt line.

    Models a dictionary where the Key is the name of the
    interrupt pin and each entry contains:
        * a reference to the parent controller : str
        * an index : int
    """

    def __init__(self, module: Module, controllers) -> None:
        super().__init__(module=module)
        self._controllers = controllers
        self._base_idx: int = 0

        pins = []
        for ctrler_name in self._controllers:
            irq_controller = self._md.blocks[ctrler_name]
            if "intr" in irq_controller.ports:
                pins = pins + self._walk_for_irq_pins(
                    irq_controller.ports["intr"].sig()
                )

            for irq_pin in pins:
                irq_pin.ext[
                    "interrupt_index"
                ].controller = irq_controller.hierarchy_name

    def _walk_for_irq_pins(self, sig: Signal) -> List[Signal]:
        """From and interrupt controller walk over connected concat blocks to
        get all the pins that are connected"""
        ret: List[Signal] = []

        if sig.parent().parent().vlnv.name == "xlconcat":
            idx_re = re.search("In([0-9]+)", sig.name)
            if len(idx_re.groups()) == 1:
                # idx = int(idx_re.group(1)) + self._base_idx
                idx = self._base_idx
            else:
                raise ValueError(
                    f"Trying to infer an interrupt index from the port name for {sig.ref} but it does not match the expected format signame={sig.name} groups={idx_re.groups()}"
                )
        else:
            idx = self._base_idx

        for dst in sig._connections.values():
            if isinstance(dst.parent().parent(), Core):
                if dst.parent().parent().vlnv.name == "xlconcat":
                    concat = dst.parent().parent()
                    for port in concat.ports.values():
                        if port.name != "dout":
                            sig = port.sig()
                            ret = ret + self._walk_for_irq_pins(sig)
                else:
                    sig.ext["interrupt_index"] = InterruptIndex(index=idx)
                    dst.ext["interrupt_index"] = InterruptIndex(index=idx)
                    self._base_idx = self._base_idx + 1
                    ret.append(dst)
                    ret.append(sig)
        return ret

    @property
    def view(self) -> Dict:
        repr_dict = {}
        self._base_idx = 0

        for ctrler_name in self._controllers:
            pins = []
            irq_controller = self._md.blocks[ctrler_name]
            if "intr" in irq_controller.ports:
                pins = pins + self._walk_for_irq_pins(
                    irq_controller.ports["intr"].sig()
                )

            for irq_pin in pins:
                full_path = f"{irq_pin.parent().parent().hierarchy_name}/{irq_pin.name}"
                repr_dict[full_path] = {}
                repr_dict[full_path]["controller"] = irq_controller.hierarchy_name
                if "interrupt_index" in irq_pin.ext:
                    repr_dict[full_path]["index"] = irq_pin.ext["interrupt_index"].index
                    irq_pin.ext[
                        "interrupt_index"
                    ].controller = irq_controller.hierarchy_name
                else:
                    repr_dict[full_path]["index"] = 127
                repr_dict[full_path]["fullpath"] = full_path

        return repr_dict

    def __setitem__(self, key: str, value: object) -> None:
        """Set the state of an item in the interrupt_pins"""
        self._state[key] = value
