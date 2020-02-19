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
import pkg_resources
import atexit
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


class _ExtensionsManager:
    """Utility class to manage a list of available extensions registered for
    discovery.

    Parameters
    ----------
        package_name: str
            Name of the package to inspect for extensions
    """
    def __init__(self, package_name):
        self.package_name = package_name
        self.list = [ext for ext in
                     pkg_resources.iter_entry_points(self.package_name)]
        atexit.register(pkg_resources.cleanup_resources, force=True)

    def extension_path(self, extension_name):
        """Return the source path of the given extension name."""
        # Define monkey patch for `pkg_resources.NullProvider.__init__` to use
        # `module.__path__` instead of `module.__file__`, as the latter does
        # not exist for namespace packages.
        # Workaround for https://github.com/pypa/setuptools/issues/1407
        def init(self, module):
            self.loader = getattr(module, "__loader__", None)
            module_path = [p for p in getattr(module, "__path__", "")][0]
            self.module_path = module_path
        # Temporarily apply monkey patch to
        # `pkg_resources.NullProvider.__init__`
        init_backup = pkg_resources.NullProvider.__init__
        pkg_resources.NullProvider.__init__ = init
        src_path = pkg_resources.resource_filename(extension_name, "")
        # Restore original `pkg_resources.NullProvider.__init__`
        pkg_resources.NullProvider.__init__ = init_backup
        return src_path

    @property
    def printable(self):
        """Return a list of extension names and related parent packages
        for printing.
        """
        return ["{} (source: {})".format(e.name, e.module_name.split(".")[0])
                for e in self.list]

    @property
    def paths(self):
        """Return a list of paths from the discovered extensions.
        """
        return [self.ext_src_path(e) for e in self.list]


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


class DownloadedFileChecksumError(Exception):
    """This exception is raised when a downloaded file has an incorrect
    checksum."""
    pass


def _download_file(download_link, path, md5sum=None):
    """Download a file from the web.

    Parameters
    ----------
        download_link: str
            The download link to use
        path: str
            The path where to save the file. The path must include the target
            file
        md5sum: str or None
            If specified, it is used after download to check for correctness.
            Raises a `DownloadedFileChecksumError` exception when the checksum
            is incorrect, and deletes the downloaded file.
    """
    import urllib.request
    import hashlib
    with urllib.request.urlopen(download_link) as response, \
            open(path, "wb") as out_file:
        data = response.read()
        out_file.write(data)
    if md5sum:
        file_md5sum = hashlib.md5()
        with open(path, "rb") as out_file:
            for chunk in iter(lambda: out_file.read(4096), b""):
                file_md5sum.update(chunk)
        if md5sum != file_md5sum.hexdigest():
            os.remove(path)
            raise DownloadedFileChecksumError("Incorrect checksum for file "
                                              "'{}'. The file has been "
                                              "deleted as a result".format(
                                                  path))


def _find_local_overlay_res(device_name, overlay_res_filename, src_path):
    """Inspects ``overlay_res.ext.d` directory for an available
    ``overlay_res.ext`` file for  ``device_name``.
    Returns ``None`` if ``device_name`` is not found.

    If a ``overlay_res.ext`` file is also found, always return that one
    without doing any resolution based on ``device_name``.

    Parameters
    ----------
        device_name: str
            The target device name
        overlay_res_filename: str
            The target filename to resolve
        src_path: str
            The path where to perform this search
    """
    overlay_res_path = os.path.join(src_path, overlay_res_filename)
    if os.path.isfile(overlay_res_path):
        return overlay_res_path
    overlay_res_filename_split = os.path.splitext(overlay_res_filename)
    overlay_res_filename_ext = "{}.{}{}".format(overlay_res_filename_split[0],
                                                device_name,
                                                overlay_res_filename_split[1])
    overlay_res_path = os.path.join(src_path, overlay_res_filename + ".d",
                                    overlay_res_filename_ext)
    if os.path.isfile(overlay_res_path):
        return overlay_res_path
    return None


def _find_remote_overlay_res(device_name, links_json_path):
    """Get download link for ``overlay_res.ext`` file and related checksum from
    ``overlay_res.ext.link`` json file, based on ``device_name``.

    The ``.link`` file is generally a dict of device names and associated url
    and md5sum.

    .. code-block:: python3
        {
            "device_1": {
                            "url": "https://link.to/overlay.xclbin",
                            "md5sum": "da1e100gh8e7becb810976e37875de38"
                        }.
            "device_2": {
                            "url": "https://link.to/overlay.xclbin",
                            "md5sum": "da1e100gh8e7becb810976e37875de38"
                        }
        }

    Expected return content from the ``.link`` json file is a dict with two
    entries:

    .. code-block:: python3

        {
            "url": "https://link.to/overlay.xclbin",
            "md5sum": "da1e100gh8e7becb810976e37875de38"
        }

    Returns `None` if ``device_name`` is not found.

    If the ``.link`` file contains a *url* and *md5sum* entries at the top
    level, these are returned and no device-based resolution is performed.

    Parameters
    ----------
        device_name: str
            The target device name
        links_json_path: str
            The full path to the ``.link`` json file
    """
    with open(links_json_path) as f:
        links = json.load(f)
    if "url" in links and "md5sum" in links:
        return {"url": links["url"], "md5sum": links["md5sum"]}
    if device_name in links:
        return links[device_name]
    return None


class OverlayNotFoundError(Exception):
    """This exception is raised when an overlay for the target device could not
    be located."""
    pass


def _resolve_overlay_res_from_folder(device_name, overlay_res_folder, src_path,
                                     dst_path, rel_path, files_to_copy):
    """Resolve ``overlay_res.ext`` file from ``overlay_res.ext.d`` folder,
    based on ``device_name``. Updates ``files_to_copy`` with the resolved file
    to use. If a ``overlay_res.ext.link`` file is found, resolution is skipped
    here. This is to avoid inspecting the ``overlay_res.ext.d`` folder twice.
    See ``_resolve_overlay_res_from_link()``.
    """
    overlay_res_filename = os.path.splitext(overlay_res_folder)[0]
    # Avoid checking a .d folder twice when also a
    # related .link file is found
    if not os.path.isfile(os.path.join(src_path,
                                       overlay_res_filename + ".link")):
        overlay_res_src_path = _find_local_overlay_res(device_name,
                                                       overlay_res_filename,
                                                       src_path)
        if overlay_res_src_path:
            overlay_res_dst_path = os.path.join(dst_path, rel_path,
                                                overlay_res_filename)
            files_to_copy[overlay_res_src_path] = overlay_res_dst_path
        else:
            raise OverlayNotFoundError(overlay_res_filename)


def _resolve_overlay_res_from_link(device_name, overlay_res_link, src_path,
                                   dst_path, rel_path, files_to_copy,
                                   files_to_move, logger):
    """Resolve ``overlay_res.ext`` file from ``overlay_res.ext.link`` file,
    based on ``device_name``. Updates ``files_to_copy`` with the resolved file
    to use if found locally (by inspecting ``overlay_res.ext.d`` folder), or
    updates ``files_to_move`` in case the file is downloaded.
    """
    overlay_res_filename = os.path.splitext(overlay_res_link)[0]
    overlay_res_dst_path = os.path.join(dst_path, rel_path,
                                        overlay_res_filename)
    overlay_res_src_path = _find_local_overlay_res(device_name,
                                                   overlay_res_filename,
                                                   src_path)
    if overlay_res_src_path:
        files_to_copy[overlay_res_src_path] = overlay_res_dst_path
    else:
        overlay_res_download_dict = _find_remote_overlay_res(
            device_name, os.path.join(src_path, overlay_res_link))
        if overlay_res_download_dict:
            # attempt overlay_res.ext file download
            try:
                tmp_file = tempfile.mkstemp()[1]
                logger.info("Downloading file '{}'. This may take a while"
                            "...".format(overlay_res_filename))
                _download_file(
                    overlay_res_download_dict["url"],
                    tmp_file,
                    overlay_res_download_dict["md5sum"]
                )
                files_to_move[tmp_file] = overlay_res_dst_path
            except DownloadedFileChecksumError:
                raise OverlayNotFoundError(overlay_res_filename)
        else:
            raise OverlayNotFoundError(overlay_res_filename)


def _copy_and_move_files(files_to_copy, files_to_move):
    """Copy and move files and folders. ``files_to_copy`` and ``files_to_move``
    are expected to be dict where the key is the source path, and the value is
    destination path.
    """
    # copy files and folders
    for src, dst in files_to_copy.items():
        if os.path.isfile(src):
            mkpath(os.path.dirname(dst))
            copy_file(src, dst)
        else:
            copy_tree(src, dst)
    # and move files previously downloaded
    for src, dst in files_to_move.items():
        shutil.move(src, dst)


def _roll_back_copy(files_to_copy, files_to_move):
    """Roll-back previously performed copy of files and folders.
    ``files_to_copy`` and ``files_to_move`` are expected to be dict where the
    key is the source path, and the value is destination path.
    """
    for _, dst in files_to_copy.items():
        if os.path.isfile(dst):
            os.remove(dst)
            while(len(os.listdir(os.path.dirname(dst))) == 0):
                os.rmdir(os.path.dirname(dst))
                dst = os.path.dirname(dst)
        elif os.path.isdir(dst):
            remove_tree(dst)
    for _, dst in files_to_move.items():
        if os.path.isfile(dst):
            os.remove(dst)
            while(len(os.listdir(os.path.dirname(dst))) == 0):
                os.rmdir(os.path.dirname(dst))
                dst = os.path.dirname(dst)


def deliver_notebooks(device_name, src_path, dst_path, name, folder=False,
                      overlays_res_lookup=True):
    """Deliver notebooks to target destination path.

    If a ``overlay_res.ext.link`` file or a ``overlay_res.ext.d`` folders is
    found, then ``overlay_res.ext`` (where ``.ext`` represents a generic file
    extension) is considered to be a file that need to be resolved dynamically,
    based on ``device_name``.
    The following resolution strategy is applied when inspecting ``src_path``:

        1. If an ``overlay_res.ext`` file is found, prioritize that file and do
           not perform any resolution.
        2. In case step 1 fails, if a ``overlay_res.ext.d`` folder is found,
           try to retrieve the right ``overlau_res.ext`` file from there. The
           files in this folder are expected to contain the device name as a
           string, before the file extension ``.ext``.
           Format should be ``overlay_res.device_name.ext``.
        3. In case step 2 fails, if there is an ``overlay_res.ext.link`` file,
           attempt to download the correct file from the provided url, assumed
           that a valid entry for ``device_name`` is available in the ``.link``
           json file.
        4. If all steps fail, notebooks that are in the same folder as
           ``overlay_res.ext`` are not delivered, and the user is warned.

    For simplicity, it is assumed that ``.link`` files and ``.d`` folders are
    located next to the notebooks that use the associated resource. Folders
    that does not contain notebooks will not be inspected.

    In case no ``.link`` or ``overlay_res.d`` files are found, notebooks are
    simply copied as is, no resolution is performed.
    It is assumed that for this scenario, overlays are delivered somewhere
    else.

    Parameters
    ----------
        device_name: str
            The target device name to use when doing resolution of ``.link``
            files and ``.d`` folders. If an ``overlay_res.ext`` file is also
            found, no resolution will be done and ``device_name`` will be
            ignored, as it is assumed that the ``overlay_res.ext`` file is
            prioritized and no automatic resolution is expected
        src_path: str
            The source path to copy from
        dst_path: str
            The destination path to copy to
        name: str
            The name of the notebooks module
        folder: bool
            Indicates whether to use ``name`` as target folder to copy
            notebooks, inside ``dst_path``. Notebooks will be copied directly
            in ``dst_path`` if ``False``.
        overlays_res_lookup: bool
            Dynamic resolution of ``.link`` files and ``.d`` folders is
            disabled if ```False``.
    """
    logger = get_logger()
    dst_fullpath = os.path.join(dst_path, name) if folder else dst_path
    files_to_copy = {}
    files_to_move = {}
    for root, dirs, files in os.walk(src_path):
        # If there is at least one notebook, inspect the folder
        if [f for f in files if f.endswith(".ipynb")]:
            # If folder is in the list of files to copy, remove it as it is
            # going to be inspected
            if root in files_to_copy:
                files_to_copy.pop(root)
            relpath = os.path.relpath(root, src_path)
            relpath = "" if relpath == "." else relpath
            try:
                files_to_copy_tmp = {}
                files_to_move_tmp = {}
                for d in dirs:
                    if d.endswith(".d"):
                        if overlays_res_lookup:
                            _resolve_overlay_res_from_folder(
                                device_name, d, root, dst_fullpath, relpath,
                                files_to_copy_tmp)
                    elif d != "__pycache__":  # exclude __pycache__ folder
                        dir_dst_path = os.path.join(dst_fullpath, relpath, d)
                        files_to_copy_tmp[os.path.join(root, d)] = \
                            dir_dst_path
                for f in files:
                    if f.endswith(".link"):
                        if overlays_res_lookup:
                            _resolve_overlay_res_from_link(
                                device_name, f, root, dst_fullpath, relpath,
                                files_to_copy_tmp, files_to_move_tmp, logger)
                    else:
                        file_dst_path = os.path.join(dst_fullpath, relpath, f)
                        files_to_copy_tmp[os.path.join(root, f)] = \
                            file_dst_path
                # No OverlayNotFoundError exception raised, can add
                # files_to_copy_tmp to files_to_copy
                files_to_copy.update(files_to_copy_tmp)
                # and files_to_move_tmp to files_to_move
                files_to_move.update(files_to_move_tmp)
            except OverlayNotFoundError as e:
                # files_to_copy not updated, folder skipped
                if relpath:
                    nb_str = os.path.join(name, relpath)
                    logger.info("Could not resolve file '{}' in folder "
                                "'{}', notebooks will not be "
                                "delivered".format(str(e), nb_str))
    try:
        # exclude root __init__.py from copy, if it exists
        files_to_copy.pop(os.path.join(src_path, "__init__.py"))
    except KeyError:
        pass
    try:
        if not files_to_copy:
            logger.info("The notebooks module '{}' could not be delivered. "
                        "The module has no notebooks, or no valid overlays "
                        "were found".format(name))
        else:
            _copy_and_move_files(files_to_copy, files_to_move)
    except (Exception, KeyboardInterrupt) as e:
        # roll-back copy
        logger.info("Exception detected. Cleaning up as the delivery process "
                    "did not complete...")
        _roll_back_copy(files_to_copy, files_to_move)
        raise e


def _resolve_global_overlay_res(overlay_res_link, src_path, logger,
                                fail=False):
    """Resolve resource that is global to every device (using a ``device=None``
    when calling ``_find_remote_overlay_res``). File is downloaded in
    ``src_path``.
    """
    overlay_res_filename = os.path.splitext(overlay_res_link)[0]
    overlay_res_download_dict = \
        _find_remote_overlay_res(None,
                                 os.path.join(src_path, overlay_res_link))
    if overlay_res_download_dict:
        overlay_res_fullpath = os.path.join(
            src_path, overlay_res_filename)
        try:
            logger.info("Downloading file '{}'. "
                        "This may take a while"
                        "...".format(
                            overlay_res_filename))
            _download_file(
                overlay_res_download_dict["url"],
                overlay_res_fullpath,
                overlay_res_download_dict["md5sum"])
        except Exception as e:
            if fail:
                raise e
        finally:
            if not os.path.isfile(
                    overlay_res_fullpath):
                err_msg = "Could not resolve file '{}'".format(
                    overlay_res_filename)
                logger.info(err_msg)
            return True  # overlay_res_download_dict was not empty
    return False


def _resolve_devices_overlay_res(overlay_res_link, src_path, devices, logger,
                                 fail=False):
    """Resolve ``overlay_res.ext`` file for every device in ``devices``.
    Files are downloaded in a ``overlay_res.ext.d`` folder in ``src_path``.
    """
    overlay_res_filename = os.path.splitext(overlay_res_link)[0]
    for device in devices:
        overlay_res_src_path = _find_local_overlay_res(device,
                                                       overlay_res_filename,
                                                       src_path)
        err_msg = "Could not resolve file '{}' for " \
                  "device '{}'".format(overlay_res_filename,
                                       device)
        if not overlay_res_src_path:
            overlay_res_download_dict = _find_remote_overlay_res(
                device, os.path.join(src_path, overlay_res_link))
            if overlay_res_download_dict:
                overlay_res_download_path = os.path.join(
                    src_path, overlay_res_filename + ".d")
                overlay_res_filename_split = \
                    os.path.splitext(overlay_res_filename)
                overlay_res_filename_ext = "{}.{}{}".format(
                    overlay_res_filename_split[0], device,
                    overlay_res_filename_split[1])
                mkpath(overlay_res_download_path)
                overlay_res_fullpath = os.path.join(overlay_res_download_path,
                                                    overlay_res_filename_ext)
                try:
                    logger.info("Downloading file '{}'. "
                                "This may take a while"
                                "...".format(
                                    overlay_res_filename))
                    _download_file(
                        overlay_res_download_dict["url"],
                        overlay_res_fullpath,
                        overlay_res_download_dict["md5sum"])
                except Exception as e:
                    if fail:
                        raise e
                finally:
                    if not os.path.isfile(
                            overlay_res_fullpath):
                        logger.info(err_msg)
                    if len(os.listdir(overlay_res_download_path)) == 0:
                        os.rmdir(overlay_res_download_path)
            else:
                if fail:
                    raise OverlayNotFoundError(err_msg)
                logger.info(err_msg)


def _resolve_all_overlay_res_from_link(overlay_res_link, src_path, logger,
                                       fail=False):
    """Resolve every entry of ``.link`` files regardless of detected devices.
    """
    overlay_res_filename = os.path.splitext(overlay_res_link)[0]
    with open(os.path.join(src_path, overlay_res_link)) as f:
        links = json.load(f)
    if not _resolve_global_overlay_res(overlay_res_link, src_path, logger,
                                       fail):
        for device, download_link_dict in links.items():
            if not _find_local_overlay_res(
                    device, overlay_res_filename, src_path):
                err_msg = "Could not resolve file '{}' for " \
                    "device '{}'".format(overlay_res_filename,
                                         device)
                overlay_res_download_path = os.path.join(
                    src_path, overlay_res_filename + ".d")
                overlay_res_filename_split = \
                    os.path.splitext(overlay_res_filename)
                overlay_res_filename_ext = "{}.{}{}".format(
                    overlay_res_filename_split[0], device,
                    overlay_res_filename_split[1])
                mkpath(overlay_res_download_path)
                overlay_res_fullpath = os.path.join(
                    overlay_res_download_path,
                    overlay_res_filename_ext)
                try:
                    logger.info("Downloading file '{}'. "
                                "This may take a while"
                                "...".format(
                                    overlay_res_filename))
                    _download_file(
                        download_link_dict["url"],
                        overlay_res_fullpath,
                        download_link_dict["md5sum"])
                except Exception as e:
                    if fail:
                        raise e
                finally:
                    if not os.path.isfile(
                            overlay_res_fullpath):
                        logger.info(err_msg)
                    if len(os.listdir(
                            overlay_res_download_path)) == 0:
                        os.rmdir(overlay_res_download_path)


def download_overlays(path, download_all=False, fail=False):
    """Download overlays for detected devices in destination path.

    Resolve ``overlay_res.ext`` files from  ``overlay_res.ext.link``
    json files. Downloaded ``overlay_res.ext`` files are put in a
    ``overlay_res.ext.d`` directory, with the device name added to their
    filename, as ``overlay_res.device_name.ext``.
    If target ``overlay_res.ext`` already exists, resolution is skipped.

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
        for f in files:
            if f.endswith(".link"):
                if not download_all:
                    if not _resolve_global_overlay_res(f, root, logger, fail):
                        _resolve_devices_overlay_res(f, root, devices, logger,
                                                     fail)
                else:  # download all overlays regardless of detected devices
                    _resolve_all_overlay_res_from_link(f, root, logger, fail)


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


def run_notebook(notebook, root_path=".", timeout=30, prerun=None):
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
    prerun : function
        Function to run prior to starting the notebook, takes the
        temporary copy of root_path as a parameter

    """
    import nbformat
    from nbconvert.preprocessors import ExecutePreprocessor
    with tempfile.TemporaryDirectory() as td:
        workdir = os.path.join(td, 'work')
        notebook_dir = os.path.join(workdir, os.path.dirname(notebook))
        shutil.copytree(root_path, workdir)
        if prerun is not None:
            prerun(workdir)
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


def _default_repr(obj):
    return repr(obj)


class ReprDict(dict):
    """Subclass of the built-in dict that will display using the Jupyterlab
    JSON repr.

    The class is recursive in that any entries that are also dictionaries
    will be converted to ReprDict objects when returned.

    """
    def __init__(self, *args, rootname="root", expanded=False, **kwargs):
        """Dictionary constructor

        Parameters
        ----------
        rootname : str
            The value to display at the root of the tree
        expanded : bool
            Whether the view of the tree should start expanded

        """
        self._rootname = rootname
        self._expanded = expanded

        super().__init__(*args, **kwargs)

    def _repr_json_(self):
        return json.loads(json.dumps(self, default=_default_repr)), \
            {'expanded': self._expanded, 'root': self._rootname}

    def __getitem__(self, key):
        obj = super().__getitem__(key)
        if type(obj) is dict:
            return ReprDict(obj, expanded=self._expanded, rootname=key)
        else:
            return obj
