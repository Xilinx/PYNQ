#   Copyright (c) 2022, Xilinx, Inc.
#   SPDX-License-Identifier: BSD-3-Clause

"""The following implementation is based on how `jupyter_core` handles the
command `jupyter` and the related subcommands.
More info on the `jupyter_core` implementation can be found at:
https://github.com/jupyter/jupyter_core
"""

import argparse
import os
import shutil
import sys




class _PynqParser(argparse.ArgumentParser):
    @property
    def epilog(self):
        """Add list of subcommands to epilog when help output is requested."""
        return "Available subcommands: {}".format(
            " ".join(list_subcommmands()))

    @epilog.setter
    def epilog(self, x):
        """Dont set epilog in Parser.__init__."""
        pass


def _pynq_parser():
    """Initialize and return the argument parser."""
    parser = _PynqParser(description="PYNQ: (PY)thon productivity for zy(NQ)")
    group = parser.add_mutually_exclusive_group(required=True)
    group.add_argument("subcommand", type=str, nargs="?",
                       help="the subcommand to execute")
    group.add_argument("-v", "--version", action="store_true",
                       help="show the PYNQ version and exit")
    return parser


def _get_search_paths():
    """Create list of valid search paths for `pynq` subcommands.
    The list is created using the environment variable PATH.
    """
    path_list = (os.environ.get('PATH') or os.defpath).split(os.pathsep)
    root = [sys.argv[0]]
    if os.path.islink(root[0]):
        # `pynq` is a symlink, so include the actual path
        root.append(os.path.realpath(root[0]))
    for r in root:
        scripts_dir = os.path.dirname(r)
        if os.path.isdir(scripts_dir) and os.access(r, os.X_OK):
            # make sure the `pynq` dir is included
            path_list.insert(0, scripts_dir)
    return path_list


def _get_subcommand_abspath(subcommand):
    """Get the absolute path of the given PYNQ `subcommand`, if valid."""
    path = os.pathsep.join(_get_search_paths())
    pynq_subcommand = "pynq-{}".format(subcommand)
    abs_path = shutil.which(pynq_subcommand, path=path)
    if abs_path is None:
        raise FileNotFoundError("PYNQ command `{}` not found.".
                                format(pynq_subcommand))
    if not os.access(abs_path, os.X_OK):
        raise PermissionError("PYNQ command `{}` is not executable".
                              format(pynq_subcommand))
    return abs_path


def list_subcommmands():
    """List all `pynq` subcommands.
    Searches PATH for all direct subcommands, like `pynq-foo`, and returns the
    list removing the `pynq-` prefix.
    Nested subcommands, like `pynq-foo-bar` are ignored here.
    However, if `pynq-foo` does not exist, then `pynq-foo-bar` is included
    and treated as a direct subcommand.
    """
    subcommands_tmp = set()
    subcommands = set()
    for d in _get_search_paths():
        try:
            names = os.listdir(d)
        except OSError:
            continue
        for n in names:
            if n.startswith("pynq-"):
                subcommands_tmp.add(tuple(n.split("-")[1:]))
    for s in subcommands_tmp:
        if not any(s[:i] in subcommands_tmp for i in range(1, len(s))):
            subcommands.add("-".join(s))
    return sorted(subcommands)


def main():
    if len(sys.argv) > 1 and not sys.argv[1].startswith("-"):
        # Subcommand passed, no need for parsing here
        subcommand = sys.argv[1]
    else:
        parser = _pynq_parser()
        args, opts = parser.parse_known_args()
        subcommand = args.subcommand
        if args.version:
            mod = __import__("pynq")
            version = mod.__version__
            git_id = mod.__git_id__.replace("$", "")
            path = mod.__path__[0]
            print("PYNQ version: {}".format(version))
            print("Path: {}".format(path))
            print("Git {}".format(git_id))
            return
    if not subcommand:
        parser.print_usage(file=sys.stderr)
        sys.exit("subcommand is required")
    cmd = _get_subcommand_abspath(subcommand)
    try:
        os.execvp(cmd, sys.argv[1:])
    except OSError as e:
        sys.exit("Error executing PYNQ command {}: {}".format(subcommand, e))


