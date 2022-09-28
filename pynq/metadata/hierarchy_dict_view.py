# Copyright (C) 2022 Xilinx, Inc
# SPDX-License-Identifier: BSD-3-Clause

from typing import Dict, List
from pydantic import Field

import json
from pynqmetadata import Module, ProcSysCore, SubordinatePort, Hierarchy

from .ip_dict_view import IpDictView
from .mem_dict_view import MemDictView
from pynqmetadata import MetadataExtension

from .metadata_view import MetadataView

def _default_repr(obj):
    return repr(obj)

class HierarchyDriverExetension(MetadataExtension):
    """Extends the metadata for hierarchies with PYNQ runtime driver information"""
    driver:object = Field(..., exclude=True, description="the runtime driver for this hierarchy")
    device:object = Field(..., exclude=True, description="the device this core has been loaded onto")
    overlay:object = Field(..., exclude=True, description="the overlay that this driver is associated with")

class HierarchyDictView(MetadataView):
    """
    Provides a hierarchy view onto the Metadata object that will display
    all hierarchies of addressable IP from the Processing System.

    All IP when parsed into the HWH file is flat with no hierarchies. 
    However, there is an additional, full_name field that can be used to reconstruct
    these hierarchies, which is what this view uses. 

    This view models a dictionary where each key is the name of the hierarchy, and each
    entry contains:
        * a dictionary of all the IP contained within that level of the hierarchy.
        * a dictionare of all the memory objects within that level of the hierarchy.
        * a dictionary of sub-hierarchies contained within this level of the hierarchy.
        * any drivers that have been assigned to this level of the hierarchy.
    """

    def __init__(self, 
                module: Module, 
                ip_view:IpDictView, 
                mem_view:MemDictView, 
                overlay: object,
                hierarchy_drivers:object,
                default_hierarchy:object,
                device:object) -> None:
        super().__init__(module=module)
        self._ip_dict = ip_view
        self._mem_dict = mem_view
        self._hierarchy_drivers = hierarchy_drivers
        self._default_hierarchy = default_hierarchy
        self._device = device
        self._overlay = overlay

    def _hierarchy_walker(self, r:Dict, h:Hierarchy)->None:
        """ recursive walk down the hierarchy h, adding IP
        that is a match in ip_dict or mem_dict to the hierarchies
        """
        if h.name not in r:
            r[h.name] = {}
            r[h.name]["ip"] = {}
            r[h.name]["memories"] = {}
            r[h.name]["hierarchies"] = {}
            r[h.name]["interrupts"] = {}
            r[h.name]["gpio"] = {}
            r[h.name]["fullpath"] = h.path
            r[h.name]["md_ref"] = h

        for ip in h._core_obj.values():
            if ip.hierarchy_name in self._mem_dict:
                name = ip.hierarchy_name.split("/")[-1]
                r[h.name]["memories"][name] = self._mem_dict[ip.hierarchy_name]
            else:
                if ip.hierarchy_name in self._ip_dict: 
                    name = ip.hierarchy_name.split("/")[-1]
                    r[h.name]["ip"][name] = self._ip_dict[ip.hierarchy_name] 

        for hier in h._hierarchies_obj.values():
            self._hierarchy_walker(r[h.name]["hierarchies"], hier)

    def _prune_unused_walker(self, r:Dict)->bool:
        """ Walks down through the hierarchy dict, removing anything
        that is empty """
        del_list = []
        for i,h in r["hierarchies"].items():
            if self._prune_unused_walker(h):
                del_list.append(i)

        for i in del_list:
            del r["hierarchies"][i]

        if r["md_ref"].pr_region: # Do not prune empty PR regions
            return False
        else:
            return len(r["ip"])==0 and len(r["memories"])==0 and len(r["hierarchies"])==0

    def _replicate_subhierarchies(self, add_to_root:Dict, l:Dict)->None:
        """ The original hierarchy dict includes the sub-hierarchies
        of other hierarchies at the root of the hierarchy_dict.
        This walks through and appends the sub-hierarchies to the root. 
        """
        for hname,h in l["hierarchies"].items():
            add_to_root[h["fullpath"]] = h
            self._replicate_subhierarchies(add_to_root=add_to_root, l=h)

    def _assign_drivers(self, hier_dict:Dict)->None:
        """Assigns drivers to the hierarchy if the pattern matches
        in the driver class.
        
        Uses metadata extensions to append the driver information. First
        checks to see that there is not already a driver assigned."""
        for hier in hier_dict["hierarchies"].values():
            self._assign_drivers(hier_dict=hier)

        if "driver" not in hier_dict["md_ref"].ext:
            driver = self._default_hierarchy
            for hip in self._hierarchy_drivers:
                if hip.checkhierarchy(hier_dict):
                    driver = hip
                    break #taken 
            hier_dict["md_ref"].ext["driver"] = HierarchyDriverExetension(device=self._device, driver=driver, overlay=self._overlay)
            hier_dict["device"] = self._device
            hier_dict["driver"] = driver 
            hier_dict["overlay"] = self._overlay 
        else:
            hier_dict["device"] = hier_dict["md_ref"].ext["driver"].device 
            hier_dict["driver"] = hier_dict["md_ref"].ext["driver"].driver 
            hier_dict["overlay"] = hier_dict["md_ref"].ext["driver"].overlay 

    def _cleanup_metadata_hierarchy_references(self, hier_dict:Dict)->None:
        """"Removes any reference to the metadata hierarchy objects from
        the dictionary"""
        if "md_ref" in hier_dict:
            del hier_dict["md_ref"]
        for hier in hier_dict["hierarchies"].values():
            self._cleanup_metadata_hierarchy_references(hier)

    @property
    def view(self) -> Dict:
        """
        Walks down the hierarchy dict and whenever it encounters an IP
        that is in the ip_dict or mem_dict keep it.
        """
        repr_dict = {}
        top_level = self._md._hierarchies

        # Build up the hierarchies
        for hierarchy in top_level._hierarchies_obj.values():
            self._hierarchy_walker(repr_dict, hierarchy)      

        # Prune hierarchies that are not used
        for item in repr_dict.values():
            self._prune_unused_walker(item)

        # Remove anything at the root that has nothing beneath it
        del_list = []
        for i_name, i in repr_dict.items():
            if len(i["ip"])==0 and len(i["memories"])==0 and len(i["hierarchies"])==0:
                if not i["md_ref"].pr_region:
                    del_list.append(i_name)

        # Remove everything flagged for removal
        for d in del_list:
            del repr_dict[d]

        # the extra sub-hierarchies add them to the root
        add_to_root = {}
        for item in repr_dict.values():
            self._replicate_subhierarchies(add_to_root, item)

        for iname, i in add_to_root.items():
            repr_dict[iname] = i

        # Assign drivers to all the hierarchies (Writes into the central metadata with a metadata extension)
        # If a driver is already associated with the hierarchy then grab that
        for item in repr_dict.values(): 
            self._assign_drivers(item)

        # remove any references to the metadata hierarchies in the dict
        for item in repr_dict.values():
            self._cleanup_metadata_hierarchy_references(item)

        return repr_dict
