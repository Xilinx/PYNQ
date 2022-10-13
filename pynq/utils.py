#   Copyright (c) 2020-2022, Xilinx, Inc.
#   SPDX-License-Identifier: BSD-3-Clause
import atexit
import json
import logging
import os
import shutil
import tempfile
from distutils.command.build import build as dist_build
from distutils.dir_util import copy_tree, mkpath, remove_tree
from distutils.file_util import copy_file
from warnings import warn

import pkg_resources
import pynq
import pynqutils
from setuptools.command.build_py import build_py as _build_py


class _ExtensionsManager(pynqutils.setup_utils.ExtensionsManager):
    def __init__(self, package_name: str) -> None:
        super().__init__(package_name)
        warn(
            "_ExtensionManager in utils.py is being deprecated, in future please use pynqutils.setup_utils.ExtensionsManager",
            DeprecationWarning,
        )

class build_py(_build_py):
    def run(self):
        print("Running build_py")
        warn(
            "build_py in utils.py is being deprecated, in future please use pynqutils.setup_utils.build_py",
            DeprecationWarning,
        )
        super().run()
        self.run_command("download_overlays")



def get_logger(level=logging.INFO, force_lvl=False):
    warn(
        "get_logger in utils.py is being deprecated, in future please use pynqutils.runtime.get_logger",
        DeprecationWarning,
    )
    return pynqutils.runtime.get_logger(level=level, force_lvl=force_lvl)


def _detect_devices(active_only=False):
    """Return a list containing all the detected devices names."""
    from pynq.pl_server import Device
    devices = Device.devices
    if not devices:
        raise RuntimeError("No device found in the system")
    if active_only:
        return Device.active_device.name
    return [d.name for d in devices]



def _find_local_overlay_res(device_name, overlay_res_filename, src_path):
    warn(
        "get_logger in utils.py is being deprecated, in future please use pynqutils.runtime.get_logger",
        DeprecationWarning,
    )
    return pynqutils.setup_utils._find_local_overlay_res(
        device_name=device_name,
        overlay_res_filename=overlay_res_filename,
        src_path=src_path,
    )


def deliver_notebooks(
    device_name, src_path, dst_path, name, folder=False, overlays_res_lookup=True
):
    warn(
        "deliver_notebooks in utils.py is being deprecated, in future please use pynqutils.setup_utils.deliver_notebooks",
        DeprecationWarning,
    )
    return pynqutils.setup_utils.deliver_notebooks(
        device_name=device_name,
        src_path=src_path,
        dst_path=dst_path,
        name=name,
        folder=folder,
        overlays_res_lookup=overlays_res_lookup,
    )


def download_overlays(
    path,
    download_all=False,
    fail_at_lookup=False,
    fail_at_device_detection=False,
    cleanup=False,
):
    warn(
        "download_overlays in utils.py is being deprecated, in future please use pynqutils.setup_utils.download_overlays",
        DeprecationWarning,
    )
    return pynqutils.setup_utils.download_overlays(
        path=path,
        download_all=download_all,
        fail_at_lookup=fail_at_lookup,
        fail_at_device_detection=fail_at_device_detection,
        cleanup=cleanup,
    )


def run_notebook(notebook, root_path=".", timeout=30, prerun=None):
    warn(
        "run_notebook in utils.py is being deprecated, in future please use pynqutils.runtime.run_notebook",
        DeprecationWarning,
    )
    return pynqutils.runtime.run_notebook(
        notebook=notebook, root_path=root_path, timeout=timeout, prerun=prerun
    )


class ReprDict(pynqutils.runtime.ReprDict):
    def __init__(self, *args, rootname="root", expanded=False, **kwargs):
        warn(
            "ReprDict in utils.py is being deprecated, in future please use pynqutils.runtime.ReprDict",
            DeprecationWarning,
        )
        super().__init__(*args, **kwargs, rootname=rootname, expanded=expanded)

