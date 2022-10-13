# Copyright (C) 2022 Xilinx, Inc
# SPDX-License-Identifier: BSD-3-Clause

import warnings
from typing import Dict

from pydantic import Field
from pynqmetadata import Core, MetadataExtension, Module, ProcSysCore, SubordinatePort
from pynqmetadata.errors import UnexpectedMetadataObjectType

DRIVERS_GROUP = "pynq.lib"


class DriverExtension(MetadataExtension):
    """Extends the metadata for an IP with driver
    information"""

    driver: object = Field(
        ..., exclude=True, description="The runtime driver for this core"
    )
    device: object = Field(
        ..., exclude=True, description="The device that this core has been loaded onto"
    )


def bind_driver(
    port: SubordinatePort,
    device: object,
    ip_drivers: Dict[str, object],
    default_ip: object,
    ignore_version: bool = False,
) -> None:
    """Assigns a driver to this port"""
    core = port.parent()
    if isinstance(core, Core):
        if core.vlnv.str in ip_drivers:
            port.ext["driver"] = DriverExtension(
                driver=ip_drivers[core.vlnv.str], device=device
            )
        else:
            no_version_ip = core.vlnv.str.rpartition(":")[0]
            if no_version_ip in ip_drivers:
                if ignore_version:
                    port.ext["driver"] = DriverExtension(
                        driver=ip_drivers[no_version_ip], device=device
                    )
                else:
                    other_versions = [
                        v
                        for v in ip_drivers.keys()
                        if v.startswith(f"{no_version_ip}:")
                    ]
                    message = f"IP {core.ref} is of type {core.vlnv.str} a driver has been found for {other_versions}. Use ignore_version=True to use this driver."
                    warnings.warn(message, UserWarning)
                    port.ext["driver"] = DriverExtension(
                        driver=default_ip, device=device
                    )
            else:
                port.ext["driver"] = DriverExtension(driver=default_ip, device=device)
    # else:
    #    raise UnexpectedMetadataObjectType(
    #        f"Trying to bind driver to {port.ref} but it has no parent. The parent is {core.ref} which has type {type(core)}"
    #    )


def bind_ps_driver(
    core: ProcSysCore,
    device: object,
    ip_drivers: Dict[str, object],
    default_ip: object,
    ignore_version: bool = False,
) -> None:
    """Assigns a driver to the PS"""
    if core.vlnv.str in ip_drivers:
        core.ext["driver"] = DriverExtension(
            driver=ip_drivers[core.vlnv.str], device=device
        )
    else:
        no_version_ip = core.vlnv.str.rpartition(":")[0]
        if no_version_ip in ip_drivers:
            if ignore_version:
                core.ext["driver"] = DriverExtension(
                    driver=ip_drivers[core.vlnv.str], device=device
                )
            else:
                other_versions = [
                    v for v in ip_drivers.keys() if v.startswith(f"{no_version_ip}:")
                ]
                message = f"IP {core.ref} is of type {core.vlnv.str} a driver has been found for {other_versions}. Use ignore_version=True to use this driver."
                warnings.warn(message, UserWarning)
                core.ext["driver"] = DriverExtension(driver=default_ip, device=device)
        else:
            core.ext["driver"] = DriverExtension(driver=default_ip, device=device)


def bind_drivers_to_metadata(
    md: Module, device: object, ip_drivers: Dict[str, object], default_ip: object
) -> Module:
    """Passes over the metadata and for each subordinate port
    extends the metadata to include drivers bound to it"""
    for core in md.blocks.values():

        if isinstance(core, Module):
            bind_drivers_to_metadata(
                md=core, device=device, ip_drivers=ip_drivers, default_ip=default_ip
            )
        for port in core.ports.values():
            if isinstance(port, SubordinatePort):
                bind_driver(
                    port=port,
                    device=device,
                    ip_drivers=ip_drivers,
                    default_ip=default_ip,
                )
        if isinstance(core, ProcSysCore):
            bind_ps_driver(
                core=core,
                device=device,
                ip_drivers=ip_drivers,
                default_ip=default_ip,
            )

    return md
