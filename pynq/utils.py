#   Copyright (c) 2020, Xilinx, Inc.
#   All rights reserved.
#
#   Redistribution and use in source and binary forms, with or without
#   modification, are permitted provided that the following conditions are met:
#
#   1.  Redistributions of source code must retain the above copyright notice,
#       this list of conditions and the following disclaimer.
#
#   2.  Redistributions in binary form must reproduce the above copyright
#       notice, this list of conditions and the following disclaimer in the
#       documentation and/or other materials provided with the distribution.
#
#   3.  Neither the name of the copyright holder nor the names of its
#       contributors may be used to endorse or promote products derived from
#       this software without specific prior written permission.
#
#   THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
#   AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
#   THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
#   PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR
#   CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
#   EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
#   PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS;
#   OR BUSINESS INTERRUPTION). HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
#   WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR
#   OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
#   ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

import json
import os
import shutil
import tempfile
import logging
from distutils.dir_util import copy_tree, remove_tree, mkpath
from distutils.file_util import copy_file
from distutils.command.build import build as dist_build
from setuptools.command.build_py import build_py as _build_py


__author__ = "Giuseppe Natale"
__copyright__ = "Copyright 2020, Xilinx"
__email__ = "pynq_support@xilinx.com"


_function_text = """
import json

def _default_repr(obj):
    return repr(obj)

def _resolve_global(name):
    g = globals()
    return g[name] if name in g else None

"""


class _PynqLoggingFormatter(logging.Formatter):
    FORMATS = {
        logging.ERROR: "ERROR: %(msg)s",
        logging.WARNING: "WARNING: %(msg)s",
        logging.DEBUG: "DEBUG: %(module)s: %(lineno)d: %(msg)s",
        "DEFAULT": "%(msg)s",
    }

    def format(self, record):
        log_fmt = self.FORMATS.get(record.levelno, self.FORMATS["DEFAULT"])
        formatter = logging.Formatter(log_fmt)
        return formatter.format(record)


def get_logger(level=logging.INFO, force_lvl=False):
    """Returns an instance of the pynq.utils logger.

    Parameters
    ----------
        level: str or int
            String or integer constant representing the logging level following
            Python's logging standard levels. By default, the level is not
            updated if the current level is higher, unless `force_lvl` is set
            to `True`.
        force_lvl: bool
            If `True`, sets the logging level to `level` in any case.
    """
    levels = {
        "critical": logging.CRITICAL,
        "error": logging.ERROR,
        "warning": logging.WARNING,
        "info": logging.INFO,
        "debug": logging.DEBUG
    }

    logger = logging.getLogger(__name__)
    if not logger.handlers:
        ch = logging.StreamHandler()
        ch.setFormatter(_PynqLoggingFormatter())
        logger.addHandler(ch)
    logger_lvl = logger.getEffectiveLevel()
    if type(level) is str:
        level = levels[level.lower()]
    if level > logger_lvl or force_lvl:
        logger.setLevel(level)
    return logger


def _detect_devices(active_only=False):
    """Return a list containing all the detected devices names."""
    from pynq.pl_server import Device
    devices = Device.devices
    if not devices:
        raise RuntimeError("No device found in the system")
    if active_only:
        return Device.active_device.name
    return [d.name for d in devices]


def _download_file(download_link, path):
    """Download a file from the web.

    Parameters
    ----------
        download_link: str
            The download link to use
        path: str
            The path where to save the file.
    """
    import urllib.request
    logger = get_logger()
    name = os.path.split(path)[1]
    logger.info("Downloading file '{}'. This may take a while...".format(name))
    with urllib.request.urlopen(download_link) as response, \
            open(path, "wb") as out_file:
        data = response.read()
        out_file.write(data)


def _find_local_overlay(device_name, overlay_filename, src_path):
    """Get overlay path to overlay to use.

    Inspects `overlay_name.d` directory for an available overlay for
    `device_name`. If a `overlay_name` file is also found, always return
    that one.
    Returns `None` if device_name is not found.

    Parameters
    ----------
        device_name: str
            The target device name (XRT shell)
        overlay_name: str
            the overlay filename
        src_path: str
            the path where to perform this search
    """
    overlay_path = os.path.join(src_path, overlay_filename)
    if os.path.isfile(overlay_path):
        return overlay_path
    overlay_filename_split = os.path.splitext(overlay_filename)
    overlay_filename_ext = "{}.{}{}".format(overlay_filename_split[0],
                                            device_name,
                                            overlay_filename_split[1])
    overlay_path = os.path.join(src_path, overlay_filename + ".d",
                                overlay_filename_ext)
    if os.path.isfile(overlay_path):
        return overlay_path
    return None


def _find_remote_overlay(device_name, links_json_path):
    """Get overlay download link from links json file.

    Returns `None` if device_name is not found

    Parameters
    ----------
        device_name: str
            The target device name (XRT shell)
        links_json_path: str
            The full path to the links json file
    """
    import json
    with open(links_json_path) as f:
        links = json.load(f)
        if device_name in links:
            return links[device_name]
        return None


class OverlayNotFoundError(Exception):
    pass


def deliver_notebooks(device_name, src_path, dst_path, name, folder=None,
                      overlays_lookup=True):
    """Deliver notebooks (and possibly overlays) to target destination path.

    If overlays are delivered alongside notebooks, the following resolution
    strategy is applied when inspecting the `src_path`:
        1. If an overlay file is found, prioritize that file and do not perform
           any overlay resolution
        2. In case step 1 fails, if a overlay_name.d folder is found, try to
           retrieve the overlay from there. The overlays in this folder are
           expected to contain the device name as a string, before the file
           extension
        3. In case step 2 fails, if there is an overlay_name.link file, attempt
           to download the correct overlay from the provided link, assumed that
           a valid entry is available in the links json
        4. If all steps fail, remove the associated notebooks if the overlay
           could not be found or downloaded, and warns the user.

    In the other case, notebooks are simply copied as is without any checks.
    It is assumed that for this scenario, overlays are delivered somewhere
    else.

    Parameters
    ----------
        device_name: str
            The target device name for the notebooks. If an overlay is already
            found, no overlay resolution will be done and `device_name` will be
            ignored for that overlay, as it is assumed that the overlay file is
            prioritized and no automatic resolution is expected
        src_path: str
            The source path to copy from
        dst_path: str
            The destination path to copy to
        name: str
            The name of the notebooks package
        folder: bool
            Indicates whether to use `name` as target folder to copy notebooks,
            inside `dst_path`. Notebooks will be copied directly in `dst_path`
            if `None`.
        overlays_lookup: bool
            Dictates whether automatic overlays lookup must be performed.
    """
    logger = get_logger()
    dst_fullpath = os.path.join(dst_path, name) if folder else dst_path
    files_to_copy = {}
    files_to_download = {}
    for root, dirs, files in os.walk(src_path):
        # If there is at least one notebook, inspect the folder
        if [f for f in files if f.endswith(".ipynb")]:
            if root in files_to_copy:
                files_to_copy.pop(root)
            relpath = os.path.relpath(root, src_path)
            relpath = "" if relpath == "." else relpath
            try:
                files_to_copy_tmp = {}
                files_to_download_tmp = {}
                for d in dirs:
                    if d.endswith(".d"):
                        if overlays_lookup:
                            overlay_name = os.path.splitext(d)[0]
                            if not os.path.isfile(os.path.join(
                                    root, overlay_name + ".link")):
                                overlay_src_path = _find_local_overlay(
                                    device_name, overlay_name, root)
                                if overlay_src_path:
                                    overlay_dst_path = os.path.join(
                                        dst_fullpath, relpath, overlay_name)
                                    files_to_copy_tmp[overlay_src_path] = \
                                        overlay_dst_path
                                else:
                                    raise OverlayNotFoundError
                    elif d != "__pycache__":  # exclude __pycache__ folder
                        dir_dst_path = os.path.join(dst_fullpath, relpath, d)
                        files_to_copy_tmp[os.path.join(root, d)] = \
                            dir_dst_path
                for f in files:
                    if f.endswith(".link"):
                        if overlays_lookup:
                            overlay_name = os.path.splitext(f)[0]
                            overlay_dst_path = os.path.join(dst_fullpath,
                                                            relpath,
                                                            overlay_name)
                            overlay_src_path = _find_local_overlay(
                                device_name, overlay_name, root)
                            if overlay_src_path:
                                files_to_copy_tmp[overlay_src_path] = \
                                    overlay_dst_path
                            else:
                                overlay_download_link = _find_remote_overlay(
                                    device_name, os.path.join(root, f))
                                if overlay_download_link:
                                    files_to_download_tmp[
                                        overlay_download_link] = \
                                        overlay_dst_path
                                else:
                                    raise OverlayNotFoundError
                    else:
                        file_dst_path = os.path.join(dst_fullpath, relpath, f)
                        files_to_copy_tmp[os.path.join(root, f)] = \
                            file_dst_path
                # No OverlayNotFoundError exception raised, can add
                # files_to_copy_tmp to files_to_copy
                files_to_copy.update(files_to_copy_tmp)
                # and files_to_download_tmp to files_to_download
                files_to_download.update(files_to_download_tmp)
            except OverlayNotFoundError:
                # files_to_copy not updated, notebooks here skipped
                nb_str = "{}/{}".format(name, relpath)
                logger.info("Could not find valid overlay for notebooks '{}', "
                            "these notebooks will not be delivered".format(
                                nb_str))
    try:
        # exclude root __init__.py from copy, if it exists
        files_to_copy.pop(os.path.join(src_path, "__init__.py"))
    except KeyError:
        pass
    try:
        if not files_to_copy:
            logger.info("The notebooks package '{}' could not be delivered. "
                        "No valid overlays were found".format(name))
        else:
            # now copy files and folders
            for src, dst in files_to_copy.items():
                if os.path.isfile(src):
                    mkpath(os.path.dirname(dst))
                    copy_file(src, dst)
                else:
                    copy_tree(src, dst)
            # download files from web
            for link, dst in files_to_download.items():
                _download_file(link, dst)
    except (Exception, KeyboardInterrupt) as e:
        # roll-back copy
        logger.info("Exception detected. Cleaning up as the delivery process "
                    "did not complete...")
        for _, dst in files_to_copy.items():
            if os.path.isfile(dst):
                os.remove(dst)
                while(len(os.listdir(os.path.dirname(dst))) == 0):
                    os.rmdir(os.path.dirname(dst))
                    dst = os.path.dirname(dst)
            elif os.path.isdir(dst):
                remove_tree(dst)
        for _, dst in files_to_download.items():
            if os.path.isfile(dst):
                os.remove(dst)
                while(len(os.listdir(os.path.dirname(dst))) == 0):
                    os.rmdir(os.path.dirname(dst))
                    dst = os.path.dirname(dst)
        raise e


def download_overlays(path, download_all=False, fail=False):
    """Download overlays for detected devices in destination path.

    Downloads overlays for all detected devices using 'overlay_filename.link'
    json files. Downloaded overlays are put in a 'overlay_filename.d'
    directory, with the device name added to their filename.
    If target overlay already exists, automatic resolution is skipped.

    Parameters
    ----------
        path: str
            The path to inspect for overlays installation
        download_all: bool
            Causes all overlays to be downloaded from .link files, regardless
            of the detected devices.
        fail: bool
            Determines whether the function should raise an exception in case
            no device is detected or overlay lookup fails. When `False`, the
            function will complete without raising any exception.
    """
    logger = get_logger()
    try:
        devices = _detect_devices()
    except RuntimeError as e:
        if fail:
            raise e
        devices = []
    for root, dirs, files in os.walk(path):
        if not download_all:
            for d in dirs:
                if d.endswith(".d"):
                    overlay_name = os.path.splitext(d)[0]
                    if not os.path.isfile(os.path.join(
                            root, overlay_name + ".link")):
                        for device in devices:
                            overlay_src_path = _find_local_overlay(
                                device, overlay_name, root)
                            if not overlay_src_path:
                                msg = "Could not find overlay '{}' for " \
                                      "device '{}'".format(overlay_name,
                                                           device)
                                if fail:
                                    raise FileNotFoundError(msg)
                                logger.info(msg)
        for f in files:
            if f.endswith(".link"):
                overlay_name = os.path.splitext(f)[0]
                if not download_all:
                    for device in devices:
                        overlay_src_path = _find_local_overlay(device,
                                                               overlay_name,
                                                               root)
                        if not overlay_src_path:
                            overlay_download_link = _find_remote_overlay(
                                device, os.path.join(root, f))
                            if overlay_download_link:
                                overlay_download_path = os.path.join(
                                    root, overlay_name + ".d")
                                overlay_filename_split = \
                                    os.path.splitext(overlay_name)
                                overlay_filename_ext = "{}.{}{}".format(
                                    overlay_filename_split[0], device,
                                    overlay_filename_split[1])
                                mkpath(overlay_download_path)
                                try:
                                    _download_file(overlay_download_link,
                                                   os.path.join(
                                                       overlay_download_path,
                                                       overlay_filename_ext))
                                except Exception as e:
                                    if fail:
                                        raise e
                                    if len(os.listdir(
                                            overlay_download_path)) == 0:
                                        os.rmdir(overlay_download_path)
                            else:
                                msg = "Could not find overlay '{}' for " \
                                      "device '{}'".format(overlay_name,
                                                           device)
                                if fail:
                                    raise FileNotFoundError(msg)
                                logger.log(msg)
                else:  # download all overlays regardless of detected devices
                    import json
                    with open(os.path.join(root, f)) as f:
                        links = json.load(f)
                        for device, download_link in links.items():
                            if not _find_local_overlay(device, overlay_name,
                                                       root):
                                overlay_download_path = os.path.join(
                                    root, overlay_name + ".d")
                                overlay_filename_split = \
                                    os.path.splitext(overlay_name)
                                overlay_filename_ext = "{}.{}{}".format(
                                    overlay_filename_split[0], device,
                                    overlay_filename_split[1])
                                mkpath(overlay_download_path)
                                try:
                                    _download_file(download_link,
                                                   os.path.join(
                                                       overlay_download_path,
                                                       overlay_filename_ext))
                                except Exception as e:
                                    if fail:
                                        raise e
                                    if len(os.listdir(
                                            overlay_download_path)) == 0:
                                        os.rmdir(overlay_download_path)


class _download_overlays(dist_build):
    """Custom distutils command to download overlays using .link files."""
    description = "Download overlays using .link files"
    user_options = [("download-all", "a",
                     "forcibly download every overlay from .link files, "
                     "overriding download based on detected devices"),
                    ("force-fail", "f",
                     "Do not complete setup if overlays lookup fails.")]
    boolean_options = ["download-all", "force-fail"]

    def initialize_options(self):
        self.download_all = False
        self.force_fail = False

    def finalize_options(self):
        pass

    def run(self):
        cmd = self.get_finalized_command("build_py")
        for package, _, build_dir, _ in cmd.data_files:
            if "." not in package:  # sub-packages are skipped
                download_overlays(build_dir,
                                  download_all=self.download_all,
                                  fail=self.force_fail)


class build_py(_build_py):
    """Overload the standard setuptools 'build_py' command to also call the
    command 'download_overlays'.
    """
    def run(self):
        super().run()
        self.run_command("download_overlays")


class NotebookResult:
    """Class representing the result of executing a notebook

    Contains members with the form ``_[0-9]*`` with the output object for
    each cell or ``None`` if the cell did not return an object.

    The raw outputs are available in the ``outputs`` attribute. See the
    Jupyter documentation for details on the format of the dictionary

    """
    def __init__(self, nb):
        self.outputs = [
            c['outputs'] for c in nb['cells'] if c['cell_type'] == 'code'
        ]
        objects = json.loads(self.outputs[-1][0]['text'])
        for i, o in enumerate(objects):
            setattr(self, "_" + str(i+1), o)


def _create_code(num):
    call_line = "print(json.dumps([{}], default=_default_repr))".format(
        ", ".join(("_resolve_global('_{}')".format(i+1) for i in range(num))))
    return _function_text + call_line


def run_notebook(notebook, root_path=".", timeout=30):
    """Run a notebook in Jupyter

    This function will copy all of the files in ``root_path`` to a
    temporary directory, run the notebook and then return a
    ``NotebookResult`` object containing the outputs for each cell.

    The notebook is run in a separate process and only objects that
    are serializable will be returned in their entirety, otherwise
    the string representation will be returned instead.

    Parameters
    ----------
    notebook : str
        The notebook to run relative to ``root_path``
    root_path : str
        The root notebook folder (default ".")
    timeout : int
        Length of time to run the notebook in seconds (default 30)

    """
    import nbformat
    from nbconvert.preprocessors import ExecutePreprocessor
    with tempfile.TemporaryDirectory() as td:
        workdir = os.path.join(td, 'work')
        notebook_dir = os.path.join(workdir, os.path.dirname(notebook))
        shutil.copytree(root_path, workdir)
        fullpath = os.path.join(workdir, notebook)
        with open(fullpath, "r") as f:
            nb = nbformat.read(f, as_version=4)
        ep = ExecutePreprocessor(kernel_name='python3', timeout=timeout)
        code_cells = [c for c in nb['cells'] if c['cell_type'] == 'code']
        nb['cells'].append(
            nbformat.from_dict({'cell_type': 'code',
                                'metadata': {},
                                'source': _create_code(len(code_cells))}
        ))
        ep.preprocess(nb, {'metadata': {'path': notebook_dir}})
        return NotebookResult(nb)


