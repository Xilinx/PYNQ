# Copyright (C) 2022 Xilinx, Inc
# SPDX-License-Identifier: BSD-3-Clause

import json
from typing import Dict, List

from pynqmetadata import Core, ManagerPort, Module, ProcSysCore, Signal, SubordinatePort
from pynqmetadata.errors import CoreNotFound

from .metadata_view import MetadataView

from .append_drivers_pass import DriverExtension


class IpDictView(MetadataView):
    """
    Provides a view onto the Metadata object that displays all 
    addressable IP from the Processing System. Models a dictionary,
    where the key is the IP name, and each entry contains:
        * physical address
        * address range
        * type
        * parameters dictionary
        * register dictionary
        * any associated state

    The produced view dictionary has the type:  
    IP: {str: {‘phys_addr’ : int, ‘addr_range’ : int, ‘type’ : str, 
               ‘parameters’ : dict, ‘registers’: dict, ‘state’ : str}}
    """

    def __init__(self, module: Module, submodule: bool = False) -> None:
        super().__init__(module=module)
        self._is_submodule = submodule

    def get_ps(self) -> ProcSysCore:
        """Gets a reference to the PS core for this design"""
        for core in self._md.blocks.values():
            if isinstance(core, ProcSysCore):
                return core
        raise CoreNotFound(
            f"Could not find a processing system for the design when getting the ip_dict_view"
        )

    def _search_for_interrupts(self, core: Core) -> List[Signal]:
        """For a given core return all it's signals that are interrupt pins"""
        itr_pins = []
        for port in core.ports.values():
            for sig in port.signals.values():
                if "interrupt_index" in sig.ext:
                    itr_pins.append(sig)
        return itr_pins

    @property
    def view(self) -> Dict:
        repr_dict = {}

        ps = self.get_ps()
        for port in ps.ports.values():
            if isinstance(port, ManagerPort):
                for sp_ref in port.addrmap:
                    target_port = port._addrmap_obj[sp_ref]
                    dparent = target_port.parent()

                    # check if we are traversing across a BDC and jump in to grab the block if we are
                    dcore = None
                    dst_port = None

                    # This is an ordinary core
                    if isinstance(dparent, Core):
                        dcore = dparent
                        dst_port = target_port

                    # This is a module (BDC/Hierarchy)
                    elif isinstance(dparent, Module):
                        if len(dparent.blocks) == 0:
                            # We require a BDC stub interface (used in the composable)
                            dcore = dparent
                            dst_port = target_port
                        else:
                            # We flatten the hierarchy as there are blocks within this module
                            dcore = None
                            for b in dparent.blocks.values():
                                for p in b.ports.values():
                                    for d in p.destinations().values():
                                        if target_port.ref == d.ref:
                                            dcore = b
                                            dcore.hierarchy_name = (
                                                f"{dparent.hierarchy_name}/{b.name}"
                                            )
                                            dst_port = p

                    if dcore is not None:
                        repr_dict[dcore.hierarchy_name] = {}

                        # Special case the vlvn for empty BDC modules
                        if hasattr(dcore, "vlnv"):
                            repr_dict[dcore.hierarchy_name]["type"] = dcore.vlnv.str
                        else:
                            repr_dict[dcore.hierarchy_name][
                                "type"
                            ] = "xilinx.com:bdc:bdc:1.0"

                        repr_dict[dcore.hierarchy_name]["mem_id"] = dst_port.name
                        repr_dict[dcore.hierarchy_name]["memtype"] = "REGISTER"
                        repr_dict[dcore.hierarchy_name]["gpio"] = {}
                        repr_dict[dcore.hierarchy_name]["interrupts"] = {}

                        for itr_sig in self._search_for_interrupts(dcore):
                            repr_dict[dcore.hierarchy_name]["interrupts"][
                                itr_sig.name
                            ] = {}
                            repr_dict[dcore.hierarchy_name]["interrupts"][itr_sig.name][
                                "controller"
                            ] = itr_sig.ext["interrupt_index"].controller
                            repr_dict[dcore.hierarchy_name]["interrupts"][itr_sig.name][
                                "index"
                            ] = itr_sig.ext["interrupt_index"].index
                            repr_dict[dcore.hierarchy_name]["interrupts"][itr_sig.name][
                                "fullpath"
                            ] = f"{itr_sig.parent().parent().hierarchy_name}/{itr_sig.name}"

                        repr_dict[dcore.hierarchy_name]["parameters"] = {}
                        for param in dcore.parameters.values():
                            repr_dict[dcore.hierarchy_name]["parameters"][
                                param.name
                            ] = param.value
                        repr_dict[dcore.hierarchy_name]["registers"] = {}

                        repr_dict[dcore.hierarchy_name]["driver"] = None
                        repr_dict[dcore.hierarchy_name]["device"] = None
                        if "driver" in dst_port.ext and isinstance(
                            dst_port.ext["driver"], DriverExtension
                        ):
                            repr_dict[dcore.hierarchy_name]["driver"] = dst_port.ext[
                                "driver"
                            ].driver
                            repr_dict[dcore.hierarchy_name]["device"] = dst_port.ext[
                                "driver"
                            ].device

                        if not isinstance(dst_port.parent(), ProcSysCore):
                            for reg in dst_port.registers.values():
                                repr_dict[dcore.hierarchy_name]["registers"][
                                    reg.name
                                ] = {}
                                repr_dict[dcore.hierarchy_name]["registers"][reg.name][
                                    "address_offset"
                                ] = reg.offset
                                repr_dict[dcore.hierarchy_name]["registers"][reg.name][
                                    "size"
                                ] = reg.width
                                repr_dict[dcore.hierarchy_name]["registers"][reg.name][
                                    "access"
                                ] = reg.access
                                repr_dict[dcore.hierarchy_name]["registers"][reg.name][
                                    "description"
                                ] = reg.description
                                repr_dict[dcore.hierarchy_name]["registers"][reg.name][
                                    "fields"
                                ] = {}
                                for f in reg.bitfields.values():
                                    repr_dict[dcore.hierarchy_name]["registers"][
                                        reg.name
                                    ]["fields"][f.name] = {}
                                    repr_dict[dcore.hierarchy_name]["registers"][
                                        reg.name
                                    ]["fields"][f.name]["bit_offset"] = f.LSB
                                    repr_dict[dcore.hierarchy_name]["registers"][
                                        reg.name
                                    ]["fields"][f.name]["bit_width"] = (
                                        f.MSB - f.LSB
                                    ) + 1
                                    repr_dict[dcore.hierarchy_name]["registers"][
                                        reg.name
                                    ]["fields"][f.name]["access"] = f.access
                                    repr_dict[dcore.hierarchy_name]["registers"][
                                        reg.name
                                    ]["fields"][f.name]["description"] = f.description
                            repr_dict[dcore.hierarchy_name]["state"] = None
                            repr_dict[dcore.hierarchy_name]["bdtype"] = None
                            repr_dict[dcore.hierarchy_name][
                                "phys_addr"
                            ] = dst_port.baseaddr
                            repr_dict[dcore.hierarchy_name][
                                "addr_range"
                            ] = dst_port.range
                            repr_dict[dcore.hierarchy_name][
                                "fullpath"
                            ] = dcore.hierarchy_name

        repr_dict[ps.hierarchy_name] = {}
        repr_dict[ps.hierarchy_name]["type"] = ps.vlnv.str
        repr_dict[ps.hierarchy_name]["gpio"] = {}
        repr_dict[ps.hierarchy_name]["interrupts"] = {}
        repr_dict[ps.hierarchy_name]["parameters"] = {}
        repr_dict[ps.hierarchy_name]["driver"] = None
        repr_dict[ps.hierarchy_name]["device"] = None
        if "driver" in ps.ext and isinstance(ps.ext["driver"], DriverExtension):
            repr_dict[ps.hierarchy_name]["driver"] = ps.ext["driver"].driver
            repr_dict[ps.hierarchy_name]["device"] = ps.ext["driver"].device

        for param in ps.parameters.values():
            repr_dict[ps.hierarchy_name]["parameters"][param.name] = param.value

        return repr_dict
