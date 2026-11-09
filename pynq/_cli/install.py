#   Copyright (C) 2026 Advanced Micro Devices, Inc.
#   SPDX-License-Identifier: BSD-3-Clause

import argparse
import importlib.metadata
import importlib.util
import json
import os
import shutil
import subprocess
import sys
import sysconfig
import tempfile
from pathlib import Path

from pynqutils.runtime import get_logger
from pynq.ps import ON_TARGET

from .cmd import _get_subcommand_abspath
from .get_notebooks import NOTEBOOKS_GROUP, TARGET_NB_DIR


PRIMARY_EXTS = (".bit", ".xsa", ".pdi")
COMPANION_EXTS = (".hwh", ".dtbo", ".xclbin")
VERSIONS_FILE = ".versions.json"
NOTEBOOKS_ENV = "PYNQ_JUPYTER_NOTEBOOKS"


def _stash_board_files(root, files, board, version):
    """Move the bitstreams in `files` into per-board `<file>.d` folders.

    Returns the created files and the other boards recorded with a version
    different from `version`.
    """
    created = []
    originals = set()
    stale = set()
    for primary in files:
        if primary.suffix not in PRIMARY_EXTS or any(
            part.endswith(".d") for part in primary.parent.parts
        ):
            continue
        base = primary.with_suffix("")
        group = [primary] + [
            f for f in files if f.suffix in COMPANION_EXTS and f.with_suffix("") == base
        ]
        folder = (root / primary).with_name(primary.name + ".d")
        folder.mkdir(exist_ok=True)
        for ext in COMPANION_EXTS:
            (folder / f"{base.name}.{board}{ext}").unlink(missing_ok=True)
        for f in group:
            target = folder / f"{base.name}.{board}{f.suffix}"
            shutil.copyfile(root / f, target)
            created.append(target)
            originals.add(root / f)
        versions_file = folder / VERSIONS_FILE
        versions = {}
        if versions_file.is_file():
            versions = json.loads(versions_file.read_text())
        stale.update(b for b, v in versions.items() if b != board and v != version)
        versions[board] = version
        versions_file.write_text(json.dumps(versions))
    for original in originals:
        original.unlink()
    return created, stale


def _snapshot_dist_infos(purelib):
    """Map each `.dist-info` directory to its inode and mtime.

    uv reuses the inode of a reinstalled `.dist-info`, so the mtime is needed too.
    """
    snapshot = {}
    for p in Path(purelib).glob("*.dist-info"):
        if p.is_dir():
            stat = p.stat()
            snapshot[p.name] = (stat.st_ino, stat.st_mtime_ns)
    return snapshot


def _find_installed_dist(before, purelib):
    """Return the distribution whose `.dist-info` is new or was recreated."""
    after = _snapshot_dist_infos(purelib)
    changed = sorted(n for n, stamp in after.items() if before.get(n) != stamp)
    if not changed:
        raise RuntimeError(f"no distribution was installed in {purelib}")
    if len(changed) > 1:
        raise RuntimeError(
            "several distributions were installed: " + ", ".join(changed)
        )
    return importlib.metadata.PathDistribution(Path(purelib) / changed[0])


def _installer():
    if importlib.util.find_spec("pip"):
        return "pip"
    if shutil.which("uv"):
        return "uv"
    raise RuntimeError("pynq install needs pip or uv in this Python environment")


def _install_command(installer, requirement, forced, constraints=None):
    if installer == "pip":
        command = [sys.executable, "-m", "pip", "install"]
        forced_flags = [
            "--no-cache-dir",
            "--force-reinstall",
            "--no-deps",
            "--no-build-isolation",
        ]
    else:
        command = ["uv", "pip", "install", "--python", sys.executable]
        forced_flags = [
            "--no-cache",
            "--reinstall",
            "--no-deps",
            "--no-build-isolation",
        ]
    if forced:
        command += forced_flags
    if constraints:
        command += ["-c", constraints]
    return command + [requirement]


def _write_constraints(path):
    lines = []
    for name in ("pynq", "pynqutils", "pynqmetadata"):
        try:
            lines.append(f"{name}=={importlib.metadata.version(name)}\n")
        except importlib.metadata.PackageNotFoundError:
            pass
    Path(path).write_text("".join(lines))


def _prepare_source(requirement, workdir):
    if not os.path.isdir(requirement):
        return requirement
    src = os.path.join(workdir, "src")
    stale = shutil.ignore_patterns("build", "*.egg-info")
    shutil.copytree(
        requirement,
        src,
        ignore=lambda d, names: stale(d, names) if d == requirement else set(),
    )
    return src


def _legacy_installer(dist):
    """Return the package whose `__main__.py` is a notebook installer (StrathSDR)."""
    for f in dist.files or []:
        if f.parts[1:] == ("__main__.py",):
            if NOTEBOOKS_ENV in dist.locate_file(f).read_text(errors="ignore"):
                return f.parts[0]
    return None


def _deliver_notebooks(dist, board, nb_dir, force, env):
    names = [ep.name for ep in dist.entry_points if ep.group == NOTEBOOKS_GROUP]
    if names:
        get_nb = _get_subcommand_abspath("get-notebooks")
        command = [get_nb, *names, "-d", board, "-p", nb_dir] + ["-f"] * force
    else:
        pkg = _legacy_installer(dist)
        if pkg is None:
            return
        if force:
            shutil.rmtree(os.path.join(nb_dir, pkg), ignore_errors=True)
        command = [sys.executable, "-m", pkg, "install"]
    subprocess.run(command, env=env, check=True)


def _parser():
    parser = argparse.ArgumentParser(
        description="Install an overlay package for one board"
    )
    parser.add_argument(
        "requirement",
        help="what pip accepts: a PyPI name, a URL, a git URL or a local path",
    )
    parser.add_argument(
        "-b",
        "--board",
        help="remote board to install for; omit to install on the local PYNQ board",
    )
    parser.add_argument(
        "-p",
        "--path",
        help="notebooks folder; remote installs append the board name",
    )
    parser.add_argument(
        "-f",
        "--force",
        action="store_true",
        help="deliver the notebooks again if they are already delivered",
    )
    return parser


def main(argv=None):
    parser = _parser()
    args = parser.parse_args(argv)
    local = ON_TARGET and args.board is None
    board = args.board
    if local:
        board = Path('/proc/device-tree/chosen/pynq_board').read_text().rstrip('\x00\n')
    elif board is None:
        parser.error("--board is required when installing from a host")
    if board in ("", ".", "..") or os.path.basename(board) != board:
        parser.error(f"invalid board name: {board!r}")
    logger = get_logger(force_lvl=True)
    if ON_TARGET and args.board is not None:
        logger.warning(
            "Installing in remote mode because --board was specified. "
            "Omit --board to install for this board locally."
        )
    try:
        installer = _installer()
    except RuntimeError as e:
        logger.error(e)
        return 1
    nb_dir = os.path.abspath(args.path or (
        os.environ.get(NOTEBOOKS_ENV, TARGET_NB_DIR) if local else TARGET_NB_DIR
    ))
    if not local:
        nb_dir = os.path.join(nb_dir, board)
    os.makedirs(nb_dir, exist_ok=True)
    env = {**os.environ, "BOARD": board, NOTEBOOKS_ENV: nb_dir}
    purelib = sysconfig.get_path("purelib")
    status = 0
    created, stale = [], set()
    with tempfile.TemporaryDirectory() as workdir:
        source = _prepare_source(args.requirement, workdir)
        before = _snapshot_dist_infos(purelib)
        command = _install_command(installer, source, forced=True)
        code = subprocess.run(command, env=env).returncode
        if code:
            logger.error(
                f"{installer} failed to install {args.requirement} (exit code {code})"
            )
            return code
        try:
            dist = _find_installed_dist(before, purelib)
        except RuntimeError as e:
            logger.error(
                f"{args.requirement} was installed but could not be located in this "
                f"environment's site-packages ({e}), so no per-board files were created"
            )
            return 1
        name = dist.metadata["Name"]
        try:
            constraints = os.path.join(workdir, "constraints.txt")
            _write_constraints(constraints)
            command = _install_command(
                installer,
                f"{name}=={dist.version}",
                forced=False,
                constraints=constraints,
            )
            if subprocess.run(command, env=env).returncode:
                logger.error(
                    f"{installer} failed to install the dependencies of {name}"
                )
                status = 1
            # Delivery reads the bitstreams before the move below.
            _deliver_notebooks(dist, board, nb_dir, args.force, env)
        except Exception as e:
            logger.error(f"{name} was installed, but a later step failed: {e}")
            status = 1
        finally:
            if not local:
                # Unmoved bitstreams would serve every board.
                created, stale = _stash_board_files(
                    Path(dist.locate_file("")), list(dist.files or []), board, dist.version
                )
    for f in created:
        logger.info(f"Moved to {f}")
    logger.info(f"Notebooks folder: {nb_dir}")
    for b in sorted(stale):
        logger.warning(
            f"{b} has files from another version of {name}; "
            f"re-run: pynq install {args.requirement} --board {b}"
        )
    return status
