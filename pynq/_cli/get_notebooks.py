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
import json
from shutil import move
from pynq.utils import (deliver_notebooks, _detect_devices, get_logger,
                        _ExtensionsManager)


__author__ = "Giuseppe Natale"
__copyright__ = "Copyright 2020, Xilinx"
__email__ = "pynq_support@xilinx.com"


NOTEBOOKS_GROUP = "pynq.notebooks"
TARGET_NB_DIR = os.path.join(".", "pynq-notebooks")
INSTALLED_LIST_FILENAME = ".pynq-notebooks"


class _GetNotebooksParser(argparse.ArgumentParser):
    @property
    def epilog(self):
        """Add list of entry points to epilog when help output is requested."""
        return "Available notebooks modules: {}".format(
            ", ".join(_ExtensionsManager(NOTEBOOKS_GROUP).printable))

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
                        help="Provide one or more target notebooks modules "
                             "to deliver. The special keyword 'all' "
                             "will deliver all notebooks without prompt")
    parser.add_argument("-l", "--list", action="store_true",
                        help="List available notebooks modules and exit")
    group.add_argument("-d", "--device", type=str,
                       help="Provide a specific device name (XRT shell)")
    group.add_argument("-i", "--interactive", action="store_true",
                       help="Detect available shells and ask which one to "
                            "use")
    group.add_argument("-o", "--ignore-overlays", action="store_true",
                       help="Ignore automatic overlays lookup. Notebooks will "
                            "be forcibly delivered")
    parser.add_argument("-f", "--force", action="store_true",
                        help="Force delivery even if target notebooks "
                             "are already delivered. Files will be "
                             "overwritten")
    parser.add_argument("-p", "--path", type=str,
                        help="Specify a custom path to deliver notebooks to. "
                             "Default is '{}'".format(TARGET_NB_DIR))
    parser.add_argument("--from-package", type=str,
                        help="Get notebooks only from target package name")
    parser.add_argument("-q", "--quiet", action="store_true",
                        help="Do not produce logging output")
    return parser


def _get_installed(path):
    """Get list of installed notebooks from json metafile."""
    if not os.path.isfile(os.path.join(path, INSTALLED_LIST_FILENAME)):
        return []
    with open(os.path.join(path, INSTALLED_LIST_FILENAME)) as f:
        installed = json.load(f)
    return installed


def _update_installed(path, ext):
    """Update list of installed notebooks adding ext to json metafile.

    If file already exist, it is overwritten."""
    nbs_installed = _get_installed(path)
    if ext.module_name not in nbs_installed:
        nbs_installed.append(ext.module_name)
    with open(os.path.join(path, INSTALLED_LIST_FILENAME), "w") as f:
        json.dump(nbs_installed, f)


def main():
    parser = _get_notebooks_parser()
    args = parser.parse_args()
    notebooks_ext_man = _ExtensionsManager(NOTEBOOKS_GROUP)
    if args.list:
        notebooks_list = notebooks_ext_man.printable
        if notebooks_list:
            print("Available notebooks modules:\n- {}".format(
                  "\n- ".join(notebooks_list)))
        else:
            print("No notebooks available")
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
    elif args.ignore_overlays:  # overlays are ignored, set device to `None`
        device = None
    else:  # default case, detect devices and use default device
        device = _detect_devices(active_only=True)
    if not notebooks_ext_man.list:
        logger.warn("No notebooks available, nothing can be "
                    "delivered")
        return
    if args.path:
        delivery_path = args.path
    else:
        delivery_path = TARGET_NB_DIR
    overlays_res_lookup = not args.ignore_overlays
    from_package = args.from_package
    if from_package:
        from_package = from_package.replace("-", "_").lower()
    if args.notebooks:
        if "all" in args.notebooks:
            if len(args.notebooks) > 1:
                raise ValueError("The special keyword 'all' cannot be used "
                                 "with other notebooks modules")
        else:
            names = [ext.name.lower() for ext in notebooks_ext_man.list]
            not_found = []
            for p in args.notebooks:
                if p.lower() not in names:
                    not_found.append(p)
            if not_found:
                raise ValueError("Notebooks modules '{}' not found. Make "
                                 "sure they exist and the source packages are "
                                 "installed".format(", ".join(not_found)))
    else:
        yes = ["yes", "ye", "y"]
        no = ["no", "n"]
        nbs_printable = notebooks_ext_man.printable
        if from_package:
            nbs_printable = [nb for nb in nbs_printable if from_package in nb]
            if not nbs_printable:
                logger.warn("No notebooks available for package '{}', nothing "
                            "can be delivered".format(args.from_package))
                return
        if not args.force:
            nbs_installed_all = \
                ["{} (source: {})".format(e.name, e.module_name.split(".")[0])
                    for e in notebooks_ext_man.list
                    if e.module_name in _get_installed(delivery_path)]
            nbs_installed_printable = [nb for nb in nbs_printable
                                       if nb in nbs_installed_all]
            nbs_printable = [nb for nb in nbs_printable
                             if nb not in nbs_installed_all]
            if nbs_installed_printable:
                print("Already delivered notebooks (use --force to force "
                      "delivery):\n- {}".format("\n- ".join(
                          nbs_installed_printable)))
        if not nbs_printable:
            logger.warn("No new notebooks to deliver.")
            return
        print("The following notebooks modules will be delivered:\n- "
              "{}".format("\n- ".join(nbs_printable)))
        coiche = input("Do you want to proceed? [Y/n] ").lower()
        while True:
            if coiche == "" or coiche in yes:
                break
            if coiche in no:
                return
            coiche = input("Please respond with 'yes' or 'no' (or 'y' or "
                           "'n') [you replied: '{}']\nDo you want to proceed? "
                           "[Y/n] ".format(coiche))
    try:
        ## Ignoring notebooks from main `pynq.notebooks` namespace as of now
        # src_path = notebooks_ext_man.extension_path(NOTEBOOKS_GROUP)
        # logger.info("Delivering notebooks from '{}'...".format(
        #     NOTEBOOKS_GROUP))
        # deliver_notebooks(device, src_path, delivery_path,
        #                   NOTEBOOKS_GROUP,
        #                   overlays_res_lookup=overlays_res_lookup)
        ##
        for ext in notebooks_ext_man.list:
            if args.notebooks and \
                    "all" not in [n.lower() for n in args.notebooks] and \
                    ext.name.lower() not in \
                    [n.lower() for n in args.notebooks]:
                continue
            if from_package and from_package != \
                    ext.module_name.split(".")[0].lower():
                continue
            if ext.module_name in _get_installed(delivery_path) and \
                    not args.force:
                if args.notebooks:
                    logger.info("Notebooks '{}' are already delivered and "
                                "will be ignored, use --force to "
                                "override.".format(ext.module_name))
                continue
            logger.info("Delivering notebooks '{}'...".format(
                os.path.join(delivery_path, ext.name)))
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
            src_path = notebooks_ext_man.extension_path(ext.module_name)
            if hasattr(ext_mod, "deliver_notebooks"):
                # If it exists, call overloaded 'deliver_notebooks' method
                # from plugin module.
                # The overloaded method will need to respect the same
                # interface of `pynq.utils:deliver_notebooks`, and must
                # implement the same behavior. It can be used to implement some
                # pre- or post-processing calling
                # `pynq.utils:deliver_notebooks` inside, or an entirely custom
                # delivery procedure
                ext_mod.deliver_notebooks(
                    device, src_path, delivery_path, ext.name, folder=folder,
                    overlays_res_lookup=overlays_res_lookup)
            else:
                deliver_notebooks(device, src_path, delivery_path,
                                  ext.name, folder=folder,
                                  overlays_res_lookup=overlays_res_lookup)
            _update_installed(delivery_path, ext)
    except (Exception, KeyboardInterrupt) as e:
        raise e
    finally:
        if os.path.isdir(delivery_path) and \
                len(os.listdir(delivery_path)) == 0:
            os.rmdir(delivery_path)
        if not os.path.isdir(delivery_path):
            logger.warn("No notebooks available for target device, nothing "
                        "will be delivered")
