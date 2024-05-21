# Copyright (C) 2022 Xilinx, Inc
# SPDX-License-Identifier: BSD-3-Clause

import copy
from typing import Dict

import pynqutils
from pynqmetadata import Module

from .clock_dict_view import ClockDictView
from .gpio_dict_view import GpioDictView
from .hierarchy_dict_view import HierarchyDictView
from .interrupt_controllers_view import InterruptControllersView
from .interrupt_pins_view import InterruptPinsView
from .ip_dict_view import IpDictView
from .mem_dict_view import MemDictView


class RuntimeMetadataParser:
    """
    A class that produces a runtime metadata object.
    This is a collections of different views onto the metadata object.
    Each view presents a different interpretation of the underlying metadata.
    Views:
        * ip_dict: a dictionary of all IP that is addressable from the processing system.
        * hierarchy_dict : a dictionary containing the hierarchies of IP in the design.
        * gpio_dict: all the GPIO pins controlled by the PS.
        * interrupt_controllers : a dictionary of al AXI interrupt controllers in the system that are attached to the PS.
        * interrupt_pins : all pins attached to an interrupt controller in the interrupt_controllers view
        * mem_dict: a dictionary of all the memory regions in the design.
        * clock_dict : a dictionary of all the configurable clocks in the design.
    
    Views are dynamically updated as the underlying metadata is changed.
    However, this is not currently fully supported in the latest release of PYNQ, so one time
    deep copies of these dictionaries are made. 
    """

    def __init__(self, md: Module) -> None:
        self.md = md

        # Check to see if there is an XSA parser associated with the metadata
        if "xsa" in self.md.ext:
            self.xsa = self.md.ext["xsa"].xsa
        else:
            self.xsa = None

        self.partial = True
        self.bin_data = None
        self.xclbin_data = None
        self.dtbo_data = None
        self.systemgraph = self.md
        self.ps_name = list(md.get_processing_systems().keys())[0]
        self.ps = md.get_processing_systems()[self.ps_name]
        self.family_ps = self.ps.ps_name

        self.interrupt_controllers_view = InterruptControllersView(self.md)
        self.interrupt_controllers = copy.deepcopy(self.interrupt_controllers_view.view)

        self.interrupt_pins_view = InterruptPinsView(self.md, self.interrupt_controllers)
        self.interrupt_pins = copy.deepcopy(self.interrupt_pins_view.view)

        self.ip_dict_view = IpDictView(self.md)
        self.ip_dict = copy.deepcopy(self.ip_dict_view.view)

        self.gpio_dict_view = GpioDictView(self.md)
        self.gpio_dict = copy.deepcopy(self.gpio_dict_view.view)

        self.clock_dict_view = ClockDictView(self.md)
        self.clock_dict = copy.deepcopy(self.clock_dict_view.clock_dict)

        self.mem_dict_view = MemDictView(self.md)
        self.mem_dict = copy.deepcopy(self.mem_dict_view.view)

        self.hierarchy_dict_view = HierarchyDictView(
            module=self.md,
            ip_view=self.ip_dict,
            mem_view=self.mem_dict,
            overlay=None,
            hierarchy_drivers={},
            default_hierarchy=None,
            device=None,
        )
        self.refresh_hierarchy_dict()

        # Remove any duplicates in ip_dict and mem_dict
        for item in self.mem_dict:
            if item in self.ip_dict:
                del self.ip_dict[item]

    def refresh_hierarchy_dict(self) -> None:
        self.hierarchy_dict = copy.deepcopy(self.hierarchy_dict_view.view)
        self.assign_gpio_to_ip()
        self.assign_interrupts_to_ip()

    def assign_gpio_to_ip(self)->None:
        """
        Assigns the GPIO and Interrupts to the IP Dict
        """
        for gpio in self.gpio_dict.values():
            for connection in gpio["pins"]:
                ip, _, pin = connection.rpartition("/")
                if ip in self.ip_dict:
                    self.ip_dict[ip]["gpio"][pin] = gpio
                elif ip in self.hierarchy_dict:
                    self.hierarchy_dict[ip]["gpio"][pin] = gpio
                    
    def assign_interrupts_to_ip(self)->None:
        """
        Assigns interrupts to the dictionaries
        """
        for interrupt, val in self.interrupt_pins.items():
            block, _, pin = interrupt.rpartition("/")
            if block in self.ip_dict:
                self.ip_dict[block]["interrupts"][pin] = val
            elif block in self.hierarchy_dict:
                self.hierarchy_dict[block]["interrupts"][pin]= val   