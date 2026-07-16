#   Copyright (c) 2016, Xilinx, Inc.
#   SPDX-License-Identifier: BSD-3-Clause

import glob
import os
import platform
import re
import shutil
import subprocess
import warnings
from datetime import datetime
from shutil import rmtree

from setuptools import Distribution, Extension, setup
from setuptools.command.build_ext import build_ext

# Get remote install flag from environment
REMOTE_INSTALL = os.environ.get("PYNQ_REMOTE", False)

# Device family constants
ZYNQ_ARCH = "armv7l"  # 32-bit Zynq-7000 devices
ZU_ARCH = "aarch64"   # 64-bit Zynq UltraScale+ / Versal devices

# Allow overriding the detected architecture
if "PYNQ_BUILD_ARCH" in os.environ:
    CPU_ARCH = os.environ["PYNQ_BUILD_ARCH"]
else:
    CPU_ARCH = platform.machine()

# True only when building directly on/for supported Zynq hardware, otherwise False (e.g. dev machines)
CPU_ARCH_IS_SUPPORTED = CPU_ARCH in [ZYNQ_ARCH, ZU_ARCH]


def exclude_file_or_folder(exclude, path):
    """
    Exclude specified file or folder from the target path when installing overlay.

    Args:
        exclude (str): name of the specific file or folder to delete
        path (str): directory path to search within
    """
    for f in os.listdir(path):
        if f == exclude:
            if os.path.isdir(os.path.join(path, f)):
                rmtree(os.path.join(path, f))
            else:
                os.remove(os.path.join(path, f))


def find_overlays(path):
    """
    Locate and return a list of overlay directories containing (.bit) bitstreams.

    Args:
        path (str): directory path to search for board overlays

    Returns:
        list[str]: list representing the names of valid overlay directories
    """
    if os.path.isdir(path):
        return [
            f
            for f in os.listdir(path)
            if os.path.isdir(os.path.join(path, f))
            and len(glob.glob(os.path.join(path, f, "*.bit"))) > 0
        ]
    else:
        return []


# Enforce platform-dependent distribution
class BinaryDistribution(Distribution):
    """
    Enforce a platform-dependent distribution for the compiled package.
    """
    def has_ext_modules(self):
        """
        return true to indicate the presence of c-extensions.
        """
        return True


# Native C extension source lists (video/HDMI capture + display pipeline)
# Video source files
_video_src = [
    "pynq/lib/_pynq/_video/_video.c",
    "pynq/lib/_pynq/_video/_capture.c",
    "pynq/lib/_pynq/_video/_display.c",
    "pynq/lib/_pynq/_video/py_xvtc.c",
    "pynq/lib/_pynq/_video/utils.c",
    "pynq/lib/_pynq/_video/py_xgpio.c",
    "pynq/lib/_pynq/_video/video_capture.c",
    "pynq/lib/_pynq/_video/video_display.c",
]

_video_gpio = [
    "pynq/lib/_pynq/_video/bsp/gpio/xgpio.c",
    "pynq/lib/_pynq/_video/bsp/gpio/xgpio_extra.c",
    "pynq/lib/_pynq/_video/bsp/gpio/xgpio_intr.c",
    "pynq/lib/_pynq/_video/bsp/gpio/xgpio_selftest.c",
]

_video_vtc = [
    "pynq/lib/_pynq/_video/bsp/vtc/xvtc.c",
    "pynq/lib/_pynq/_video/bsp/vtc/xvtc_intr.c",
    "pynq/lib/_pynq/_video/bsp/vtc/xvtc_selftest.c",
]

_common_src = ["pynq/lib/_pynq/common/xil_stubs.c"]

# Xilinx standalone BSP headers, plus the arch-specific processor headers
# (Cortex-A9 for Zynq-7000, Cortex-A53 64-bit for Zynq UltraScale+/Versal)
_bsp_includes = [
    "pynq/lib/_pynq/embeddedsw/lib/bsp/standalone/src/common",
    "pynq/lib/_pynq/embeddedsw/lib/bsp/standalone/src/arm/common",
    "pynq/lib/_pynq/embeddedsw/lib/bsp/standalone/src/arm/common/gcc",
]

if CPU_ARCH == ZYNQ_ARCH:
    _bsp_includes.append(
        "pynq/lib/_pynq/embeddedsw/lib/bsp/standalone/src/arm/cortexa9"
    )
elif CPU_ARCH == ZU_ARCH:
    _bsp_includes.append(
        "pynq/lib/_pynq/embeddedsw/lib/bsp/standalone/src/arm/cortexa53/64bit"
    )

# The three notebooks copied into every board's "getting_started" folder
getting_started_notebooks = [
    "jupyter_notebooks.ipynb",
    "python_environment.ipynb",
    "jupyter_notebooks_advanced_features.ipynb",
]

# Merge BSP src to _video src
# (Combine all video-related sources into a single Extension() source list)
video = []
video.extend(_video_gpio)
video.extend(_video_vtc)
video.extend(_video_src)
video.extend(_common_src)


def copy_common_notebooks(staging_notebooks_dir):
    """
    Copy the architecture-agnostic jupyter notebooks into the staging directory.

    Args:
        staging_notebooks_dir (str): path indicating where to copy the notebooks
    """
    common_folders_files = [f for f in os.listdir("pynq/notebooks/")]
    for basename in common_folders_files:
        if basename != "arch":
            dst_folder_file = os.path.join(staging_notebooks_dir, basename)
            src_folder_file = os.path.join("pynq/notebooks/", basename)

            if os.path.isdir(src_folder_file):
                shutil.copytree(src_folder_file, dst_folder_file, dirs_exist_ok=True)
            elif os.path.isfile(src_folder_file):
                shutil.copy(src_folder_file, dst_folder_file)
    
    # Layer in any architecture-specific notebook variants for this build
    if os.path.exists(os.path.join("pynq/notebooks/arch", CPU_ARCH)):
        dir_fd = os.open(os.path.join("pynq/notebooks/arch", CPU_ARCH), os.O_RDONLY)
        dirs = os.fwalk(dir_fd=dir_fd)
        for dir, _, files, _ in dirs:
            if not os.path.exists(os.path.join(staging_notebooks_dir, dir)):
                os.mkdir(os.path.join(staging_notebooks_dir, dir))
            for f in files:
                shutil.copy(
                    os.path.join("pynq/notebooks/arch", CPU_ARCH, dir, f),
                    os.path.join(staging_notebooks_dir, dir, f),
                )
        os.close(dir_fd)


def copy_board_notebooks(staging_notebooks_dir, board):
    """
    Copy notebooks specific to boards/<board>/notebooks, if present.

    Args:
        staging_notebooks_dir (str): path indicating where to copy the notebooks
        board (str): name of the target hardware board
    """
    board_folder = "boards/{}".format(board)
    src_folder = os.path.join(board_folder, "notebooks")
    dst_folder = staging_notebooks_dir
    if os.path.isdir(src_folder):
        shutil.copytree(src_folder, dst_folder, dirs_exist_ok=True)


def copy_overlay_notebooks(staging_notebooks_dir, board):
    """
    Download and copy the hardware overlay notebooks for the specified board.

    Args:
        staging_notebooks_dir (str): path indicating where to copy the notebooks
        board (str): name of the target hardware board
    """
    from pynqutils.setup_utils import download_overlays

    board_folder = "boards/{}".format(board)
    download_overlays(board_folder, fail_at_lookup=True, cleanup=True)
    overlay_dirs = find_overlays(board_folder)
    for overlay in overlay_dirs:
        src_folder = os.path.join(board_folder, overlay, "notebooks")
        dst_folder = os.path.join(staging_notebooks_dir, overlay)
        if os.path.isdir(src_folder):
            shutil.copytree(src_folder, dst_folder, dirs_exist_ok=True)


def copy_documentation_files(staging_notebooks_dir):
    """
    Copy the "Getting Started" notebooks + images out of docs/source.

    Args:
        staging_notebooks_dir (str): path indicating where to copy the files
    """
    doc_files = list()
    notebooks_getting_started_dst_dir = os.path.join(
        staging_notebooks_dir, "getting_started"
    )
    notebooks_getting_started_dst_img_dir = os.path.join(
        staging_notebooks_dir, "getting_started", "images"
    )
    notebooks_getting_started_src_dir = os.path.join(
        "docs", "source", "getting_started"
    )
    notebooks_getting_started_src_img_dir = os.path.join("docs", "source", "images")

    doc_files.append(
        (
            notebooks_getting_started_dst_dir,
            [
                os.path.join(notebooks_getting_started_src_dir, nb)
                for nb in getting_started_notebooks
            ],
        )
    )
    doc_files.extend(
        [
            (
                notebooks_getting_started_dst_img_dir,
                [os.path.join(root, f) for f in files],
            )
            for root, dirs, files in os.walk(notebooks_getting_started_src_img_dir)
        ]
    )

    if not os.path.exists(notebooks_getting_started_dst_img_dir):
        os.makedirs(notebooks_getting_started_dst_img_dir)
    for dst, files in doc_files:
        for f in files:
            shutil.copy(f, dst)
            if os.path.splitext(f)[1] == ".ipynb":
                dest_nb = os.path.join(dst, os.path.split(f)[1])
                # rewrite image paths in notebooks
                with open(dest_nb, "r+") as nb:
                    text = nb.read()
                    text = re.sub(r"\(../images", r"(images", text)
                    nb.seek(0)
                    nb.truncate(0)
                    nb.write(text)


def rename_notebooks(staging_notebooks_dir):
    """
    Prepend a numerical index to the getting started notebooks for ordered display.

    Args:
        staging_notebooks_dir (str): path containing the unindexed notebooks
    """
    notebooks_getting_started_dst_dir = os.path.join(
        staging_notebooks_dir, "getting_started"
    )
    for ix, getting_started_nb in enumerate(getting_started_notebooks):
        new_nb_name = "{}_{}".format(ix + 1, getting_started_nb)
        src_file = os.path.join(notebooks_getting_started_dst_dir, getting_started_nb)
        dst_file = os.path.join(notebooks_getting_started_dst_dir, new_nb_name)
        if os.path.exists(dst_file):
            os.remove(dst_file)
        shutil.move(src_file, dst_file)


def check_env():
    """
    Validate and return the board and jupyter notebook environment variables.

    Returns:
        tuple: contains the board name (str) and notebooks directory path (str)
    """
    board = None
    if "BOARD" not in os.environ:
        warnings.warn(
            "Use `export BOARD=<board-name>` "
            "to get board specific overlays (e.g. Pynq-Z1, ZCU104).",
            UserWarning,
        )
    else:
        board = os.environ["BOARD"]

    notebooks_dir = None
    if "PYNQ_JUPYTER_NOTEBOOKS" not in os.environ:
        warnings.warn(
            "Use `export PYNQ_JUPYTER_NOTEBOOKS=<path-to-jupyter-home>` "
            "to get the notebooks.",
            UserWarning,
        )
    else:
        notebooks_dir = os.environ["PYNQ_JUPYTER_NOTEBOOKS"]

    return board, notebooks_dir


def backup_notebooks(notebooks_dir):
    """
    Create a timestamped backup of the existing jupyter notebook directory
        
    Args:
        notebooks_dir (str): path of the notebook directory to backup
    """
    if os.path.isdir(notebooks_dir):
        notebooks_dir_backup = "{}_{}".format(
            notebooks_dir, datetime.now().strftime("%Y_%m_%d_%H_%M_%S")
        )
        shutil.copy(notebooks_dir, notebooks_dir_backup, dirs_exist_ok=True)
    else:
        os.makedirs(notebooks_dir, exist_ok=True)


def change_ownership(notebooks_dir):
    """
    Grant read, write, and execute permissions to the notebook folder on unix systems.

    Args:
        notebooks_dir (str): path of the notebook directory to modify
    """
    if os.name != 'nt':  # Skip on Windows
        subprocess.run(["chmod", "-R", "a+rwX", notebooks_dir])


def copy_notebooks():
    """
    Orchestrate the backup, copying, and renaming of all repository notebooks.
    """
    board, notebooks_dir = check_env()
    if notebooks_dir:
        backup_notebooks(notebooks_dir)
        copy_common_notebooks(notebooks_dir)
        if board:
            copy_board_notebooks(notebooks_dir, board)
            copy_overlay_notebooks(notebooks_dir, board)
        copy_documentation_files(notebooks_dir)
        rename_notebooks(notebooks_dir)
        change_ownership(notebooks_dir)


class BuildExtension(build_ext):
    """
    Custom build extension to compile c bindings and stage jupyter notebooks.
    """

    def run_make(self, src_path, dst_path, output_lib):
        """
        Invoke the hardware-specific makefile to compile a shared object library.

        Args:
            src_path (str): directory path containing the source files and makefile
            dst_path (str): destination directory path for the compiled library
            output_lib (str): name of the generated shared object file
        """
        self.spawn(["make", "PYNQ_BUILD_ARCH={}".format(CPU_ARCH), "-C", src_path])
        os.makedirs(os.path.join(self.build_lib, dst_path), exist_ok=True)
        shutil.copy(
            src_path + output_lib, os.path.join(self.build_lib, dst_path, output_lib)
        )

    def install_overlays(self):
        """
        Copy the compiled bitstreams and overlays into the final build library.
        """
        board, _ = check_env()
        if not REMOTE_INSTALL:
            board_folder = "boards/{}".format(board)
            overlay_dirs = find_overlays(board_folder)
            for ol in overlay_dirs:
                src = os.path.join(board_folder, ol)
                dst = os.path.join(self.build_lib, "pynq/overlays", ol)
                if not os.path.isdir(dst):
                    shutil.copytree(
                        src, dst, ignore=shutil.ignore_patterns("notebooks")
                    )

    def run(self):
        """
        Execute the custom compilation steps and stage the non-python assets.
        """
        if not REMOTE_INSTALL:
            if CPU_ARCH == ZYNQ_ARCH:
                self.run_make("pynq/lib/_pynq/_audio/", "pynq/lib/", "libaudio.so")
                self.run_make("pynq/lib/_pynq/_xiic/", "pynq/lib/", "libiic.so")
            elif CPU_ARCH == ZU_ARCH:
                self.run_make(
                    "pynq/lib/_pynq/_displayport/", "pynq/lib/video/", "libdisplayport.so"
                )
                self.run_make("pynq/lib/_pynq/_xhdmi/", "pynq/lib/video/", "libxhdmi.so")
                self.run_make("pynq/lib/_pynq/_audio/", "pynq/lib/", "libaudio.so")
                self.run_make("pynq/lib/_pynq/_xiic/", "pynq/lib/", "libiic.so")
                self.run_make("pynq/lib/_pynq/_pcam5c/", "pynq/lib/video/", "libpcam5c.so")
        else:
            self.announce("Remote install, skipping native C/C++ builds", level=2)

        build_ext.run(self)
        if not REMOTE_INSTALL:
            copy_notebooks()
            self.install_overlays()


if REMOTE_INSTALL:
    ext_modules = [] # no extension modules for remote install
else:
    if CPU_ARCH == ZYNQ_ARCH:
        ext_modules = [
            Extension(
                "pynq.lib._video",
                video,
                include_dirs=[
                    "pynq/lib/_pynq/_video",
                    "pynq/lib/_pynq/_video/bsp/vtc",
                    "pynq/lib/_pynq/_video/bsp/gpio",
                    "pynq/lib/_pynq/common/armv7l",
                ]
                + _bsp_includes,
            ),
        ]
    else:
        ext_modules = []

setup(
    cmdclass={
        "build_ext": BuildExtension,
    },
    distclass=BinaryDistribution,
    ext_modules=ext_modules,
)
