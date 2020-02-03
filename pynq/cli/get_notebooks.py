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

import os
import argparse
import pkg_resources
from shutil import move
from pynq.utils import deliver_notebooks, _detect_devices, get_logger


__author__ = "Giuseppe Natale"
__copyright__ = "Copyright 2020, Xilinx"
__email__ = "pynq_support@xilinx.com"


NOTEBOOKS_GROUP = "pynq.notebooks"
TARGET_NB_DIR = "pynq-notebooks"


class _GetNotebooksParser(argparse.ArgumentParser):
    @property
    def epilog(self):
        """Add list of entry points to epilog when help output is requested."""
        return "Available notebooks packages: {}".format(
            ", ".join(_list_entry_points(True)))

    @epilog.setter
    def epilog(self, x):
        """Dont set epilog in Parser.__init__."""
        pass


def _get_notebooks_parser():
    """Initialize and return the argument parser."""
    parser = _GetNotebooksParser(description="Deliver available PYNQ "
                                             "notebooks")
    group = parser.add_mutually_exclusive_group()
    parser.add_argument("notebooks", type=str, nargs="*",
                        help="Provide one or more target notebooks packages "
                             "to deliver. Use the 'list' command to get "
                             "available notebooks. The special keyword 'all' "
                             "will deliver all notebooks without prompt")
    parser.add_argument("-l", "--list", action="store_true",
                        help="List available notebooks packages and exit")
    group.add_argument("-d", "--device", type=str,
                       help="Provide a specific device name (XRT shell)")
    group.add_argument("-i", "--interactive", action="store_true",
                       help="Detect available shells and ask which one to use."
                            "Ignored if 'device' is provided or XILINX_XRT "
                            "env is not set")
    group.add_argument("-o", "--ignore-overlays", action="store_true",
                       help="Ignore automatic overlays lookup. Notebooks will "
                            "be forcibly delivered even if lookup might fail")
    parser.add_argument("-f", "--force", action="store_true",
                        help="Force delivery even if target notebooks "
                             "directory already exists. The existing "
                             "directory will be renamed adding a timestamp")
    parser.add_argument("-p", "--path", type=str,
                        help="Specify a custom path to deliver notebooks to. "
                             "Default is the current working directory. A "
                             "'{}' directory will be created in the specified "
                             "path with all the notebooks.".format(
                                 TARGET_NB_DIR))
    parser.add_argument("-n", "--no-root", action="store_true",
                        help="Do not create '{}' directory, copy "
                             "directly to the delivery path".format(
                                 TARGET_NB_DIR))
    parser.add_argument("-q", "--quiet", action="store_true",
                        help="Do not produce logging output")
    return parser


def _list_entry_points(print_format=False):
    """Returns a list of available entry points registered for discovery.

    Parameters
    ----------
        print_format: bool
            If `True`, return a list of just entry points names and related
            parent packages for printing, instead of a list of `EntryPoint`
            objects
    """
    discovered = [entry_point for entry_point in
                  pkg_resources.iter_entry_points(NOTEBOOKS_GROUP)]
    if print_format:
        return ["{} (source: {})".format(e.name, e.module_name.split(".")[0])
                for e in discovered]
    return discovered


# Define monkey patch for `pkg_resources.NullProvider.__init__` to use
# `module.__path__` instead of `module.__file__`, as the latter does not exist
# for namespace packages. It is a little bit hacky, but for the context of
# notebooks discovery and delivery should work just fine
# This is a workaround to: https://github.com/pypa/setuptools/issues/1407
def _NullProvider_init(self, module):
    self.loader = getattr(module, "__loader__", None)
    module_path = [p for p in getattr(module, "__path__", "")][0]
    self.module_path = module_path


def main():
    parser = _get_notebooks_parser()
    args = parser.parse_args()
    if args.list:
        notebooks_list = _list_entry_points(True)
        if notebooks_list:
            print("Available notebooks packages:\n- {}".format(
                  "\n- ".join(notebooks_list)))
        else:
            print("No notebooks package available")
        return
    logger = get_logger()
    if args.quiet:
        logger.setLevel("WARNING")
    else:
        logger.setLevel("INFO")
    if args.device:
        device = args.device
    elif args.interactive and "XILINX_XRT" in os.environ:
        shells = list(dict.fromkeys(_detect_devices()))
        shells_num = len(shells)
        print("Detected shells:")
        for i in range(shells_num):
            print("{}) - {}\n".format(i, shells[i]))
        idx = -1
        while idx < 0 or idx >= shells_num:
            idx = input("Select for which shell you want to deliver the "
                        "notebooks [0-{}]: ".format(shells_num-1))
            try:
                idx = int(idx)
                if idx < 0 or idx >= shells_num:
                    raise ValueError
            except ValueError:
                print("Invalid choice.")
                idx = -1
        device = shells[idx]
    else:  # default case, detect devices and use default device
        device = _detect_devices(active_only=True)
    discovered_notebooks = _list_entry_points()
    if not discovered_notebooks:
        logger.warn("No notebooks package available, nothing can be "
                    "delivered")
        return
    if args.notebooks:
        if "all" in args.notebooks:
            if len(args.notebooks) > 1:
                raise ValueError("The special keyword 'all' cannot be used "
                                 "with other notebooks packages")
        else:
            names = [ext.name for ext in discovered_notebooks]
            not_found = []
            for p in args.notebooks:
                if p not in names:
                    not_found.append(p)
            if not_found:
                raise ValueError("Notebooks packages '{}' not found. Make "
                                 "sure they exist and the source packages are "
                                 "installed".format(", ".join(not_found)))
    # Temporarily apply monkey patch to
    # `pkg_resources.NullProvider.__init__`
    _NullProvider_init_backup = pkg_resources.NullProvider.__init__
    pkg_resources.NullProvider.__init__ = _NullProvider_init
    if not args.notebooks:
        yes = ["yes", "ye", "y"]
        no = ["no", "n"]
        print("The following notebooks packages will be delivered:\n- "
              "{}".format("\n- ".join(_list_entry_points(True))))
        coiche = input("Do you want to proceed? [Y/n] ").lower()
        while True:
            if coiche == "" or coiche in yes:
                break
            if coiche in no:
                return
            coiche = input("Please respond with 'yes' or 'no' (or 'y' or "
                           "'n') ")
    if args.path:
        delivery_path = args.path
    else:
        delivery_path = os.getcwd()
    if args.no_root:
        delivery_fullpath = delivery_path
    else:
        delivery_fullpath = os.path.join(delivery_path, TARGET_NB_DIR)
    if os.path.exists(delivery_fullpath) and \
            (not args.notebooks or "all" in args.notebooks):
        if args.force:
            import datetime
            timestamp = datetime.datetime.now().strftime("%Y_%m_%d_%H%M%S")
            backup_dir = os.path.split(delivery_fullpath)[1] + "_" + \
                timestamp
            backup_fullpath = os.path.join(os.path.dirname(delivery_fullpath),
                                           backup_dir)
            move(delivery_fullpath, backup_fullpath)
        else:
            raise FileExistsError("Target notebooks directory already "
                                  "exists. Specify another path or use "
                                  "the 'force' option to proceed")
    overlays_lookup = not args.ignore_overlays
    try:
        ## Ignoring notebooks from main `pynq.notebooks` namespace as of now
        # src_path = pkg_resources.resource_filename(NOTEBOOKS_GROUP, "")
        # logger.info("Delivering notebooks from main '{}'...".format(
        #     NOTEBOOKS_GROUP))
        # deliver_notebooks(device, src_path, delivery_fullpath,
        #                   NOTEBOOKS_GROUP, overlays_lookup=overlays_lookup)
        # pkg_resources.cleanup_resources(force=True)
        ##
        for ext in discovered_notebooks:
            if args.notebooks and "all" not in args.notebooks and \
                    ext.name not in args.notebooks:
                continue
            logger.info("Delivering '{}' notebooks package...".format(
                ext.name))
            ext_mod = ext.load()
            if hasattr(ext_mod, "__no_root__") and \
                    type(ext_mod.__no_root__) is bool \
                    and ext_mod.__no_root__:
                # A `__no_root__` bool property can be set to `True` in the
                # plugin module to force `folder` to be equal to `False`
                # when calling `deliver_notebooks`
                folder = False
                logger.info("Folder '{}' will not be created. Notebooks will "
                            "be delivered directly in parent "
                            "directory.".format(ext.name))
            else:
                folder = True
            src_path = pkg_resources.resource_filename(ext.module_name, "")
            if hasattr(ext_mod, "deliver_notebooks"):
                # If it exists, call overloaded 'deliver_notebooks' method
                # from plugin module.
                # The overloaded method will need to respect the same
                # interface of `pynq.utils:deliver_notebooks`, and must
                # implement the same behavior. It can be used to implement some
                # pre- or post-processing calling
                # `pynq.utils:deliver_notebooks` inside, or an entirely custom
                # delivery procedure
                ext_mod.deliver_notebooks(device, src_path, delivery_fullpath,
                                          ext.name, folder=folder,
                                          overlays_lookup=overlays_lookup)
            else:
                deliver_notebooks(device, src_path, delivery_fullpath,
                                  ext.name, folder=folder,
                                  overlays_lookup=overlays_lookup)
            pkg_resources.cleanup_resources(force=True)
    except (Exception, KeyboardInterrupt) as e:
        raise e
    finally:
        if os.path.isdir(delivery_fullpath) and \
                len(os.listdir(delivery_fullpath)) == 0:
            os.rmdir(delivery_fullpath)
        if not os.path.isdir(delivery_fullpath):
            logger.warn("No notebooks available for target device, nothing "
                        "will be delivered")
        # Restore original `pkg_resources.NullProvider.__init__`
        pkg_resources.NullProvider.__init__ = _NullProvider_init_backup
