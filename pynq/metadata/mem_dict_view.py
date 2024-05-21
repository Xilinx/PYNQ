# Copyright (C) 2022 Xilinx, Inc
# SPDX-License-Identifier: BSD-3-Clause

import json
from typing import Dict

from pynqmetadata import Core, ManagerPort, Module, ProcSysCore
from pynqmetadata.errors import MetadataObjectNotFound

from .metadata_view import MetadataView


class DummyHwhParser:
    def __init__(self, mem_dict):
        self.mem_dict = mem_dict


class MemDictView(MetadataView):
    """
    Provides a view onto the Metadata object that displays all 
    memory accessible from the Processing System. Models a dictionary,
    where the key is the memory name, and each entry contains, details
    such as the XRT allocation information for each memory.
    """

    def __init__(self, module: Module) -> None:
        super().__init__(module=module)
        self._first_run = True
        self._created_xclbin = {}
        self._psddr_cache = {}

    @property
    def view(self) -> Dict:
        repr_dict = {}

        ps_core = None
        for core in self._md.blocks.values():
            if isinstance(core, ProcSysCore):
                ps_core = core

        if ps_core is None:
            raise MetadataObjectNotFound(f"Unable to find a PS in {self._md.ref}")

        for port in ps_core.ports.values():
            if isinstance(port, ManagerPort):
                for addr in port.addrmap.values():
                    if addr["memtype"] == "memory":
                        subord_port = port._addrmap_obj[addr["subord_port"]]
                        dst_core = subord_port.parent()
                        if isinstance(dst_core, Core):
                            repr_dict[dst_core.hierarchy_name] = {}
                            repr_dict[dst_core.hierarchy_name][
                                "fullpath"
                            ] = dst_core.hierarchy_name
                            repr_dict[dst_core.hierarchy_name]["type"] = "DDR4"
                            repr_dict[dst_core.hierarchy_name]["bdtype"] = None
                            repr_dict[dst_core.hierarchy_name]["state"] = None
                            repr_dict[dst_core.hierarchy_name][
                                "addr_range"
                            ] = subord_port.range
                            repr_dict[dst_core.hierarchy_name][
                                "phys_addr"
                            ] = subord_port.baseaddr
                            repr_dict[dst_core.hierarchy_name][
                                "mem_id"
                            ] = subord_port.name
                            repr_dict[dst_core.hierarchy_name]["memtype"] = "MEMORY"
                            repr_dict[dst_core.hierarchy_name]["gpio"] = {}
                            repr_dict[dst_core.hierarchy_name]["interrupts"] = {}
                            repr_dict[dst_core.hierarchy_name]["parameters"] = {}
                            for param in dst_core.parameters.values():
                                repr_dict[dst_core.hierarchy_name]["parameters"][
                                    param.name
                                ] = param.value
                            repr_dict[dst_core.hierarchy_name]["registers"] = {}
                            for reg in subord_port.registers.values():
                                repr_dict[dst_core.hierarchy_name]["registers"][
                                    reg.name
                                ] = {}
                                repr_dict[dst_core.hierarchy_name]["registers"][
                                    reg.name
                                ]["address_offset"] = reg.offset
                                repr_dict[dst_core.hierarchy_name]["registers"][
                                    reg.name
                                ]["size"] = reg.width
                                repr_dict[dst_core.hierarchy_name]["registers"][
                                    reg.name
                                ]["access"] = reg.access
                                repr_dict[dst_core.hierarchy_name]["registers"][
                                    reg.name
                                ]["description"] = reg.description
                                repr_dict[dst_core.hierarchy_name]["registers"][
                                    reg.name
                                ]["fields"] = {}
                                for field in reg.bitfields.values():
                                    repr_dict[dst_core.hierarchy_name]["registers"][
                                        reg.name
                                    ]["fields"][field.name] = {}
                                    repr_dict[dst_core.hierarchy_name]["registers"][
                                        reg.name
                                    ]["fields"][field.name]["bit_offset"] = field.LSB
                                    repr_dict[dst_core.hierarchy_name]["registers"][
                                        reg.name
                                    ]["fields"][field.name]["bit_width"] = (
                                        field.MSB - field.LSB
                                    ) + 1
                                    repr_dict[dst_core.hierarchy_name]["registers"][
                                        reg.name
                                    ]["fields"][field.name][
                                        "description"
                                    ] = field.description
                                    repr_dict[dst_core.hierarchy_name]["registers"][
                                        reg.name
                                    ]["fields"][field.name]["access"] = field.access

                            repr_dict[dst_core.hierarchy_name]["used"] = 1

        if self._first_run:
            self._first_run = False
        else:
            for ( name, mem ) in repr_dict.items():  
                if name != "PSDDR":
                    mem["xrt_mem_idx"] = self._created_xclbin[name]["xrt_mem_idx"]
                    mem["raw_type"] = self._created_xclbin[name]["raw_type"]
                    mem["base_address"] = self._created_xclbin[name]["base_address"]
                    mem["size"] = self._created_xclbin[name]["size"]
                    mem["streaming"] = self._created_xclbin[name]["streaming"]
                    mem["idx"] = self._created_xclbin[name]["idx"]
                    mem["tag"] = self._created_xclbin[name]["tag"]
            repr_dict["PSDDR"] = self._psddr_cache
        return repr_dict
