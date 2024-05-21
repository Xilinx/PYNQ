#   Copyright (c) 2016, Xilinx, Inc.
#   SPDX-License-Identifier: BSD-3-Clause


import glob
import os
import re
import shutil
import subprocess
import warnings
from datetime import datetime
from distutils.dir_util import copy_tree
from distutils.file_util import copy_file, move_file
from shutil import rmtree

from setuptools import Distribution, Extension, find_packages, setup
from setuptools.command.build_ext import build_ext

# Requirement
required = [
    "pynqutils>=0.0.1",
    "pynqmetadata>=0.0.1",
    "setuptools>=24.2.0",
    "cffi",
    "numpy",
    "nest_asyncio",
]

# Device family constants
ZYNQ_ARCH = "armv7l"
ZU_ARCH = "aarch64"
if "PYNQ_BUILD_ARCH" in os.environ:
    CPU_ARCH = os.environ["PYNQ_BUILD_ARCH"]
else:
    CPU_ARCH = os.uname()[-1]
CPU_ARCH_IS_SUPPORTED = CPU_ARCH in [ZYNQ_ARCH, ZU_ARCH]


# Parse version number
def find_version(file_path):
    with open(file_path, "r") as fp:
        version_file = fp.read()
        version_match = re.search(
            r"^__version__ = ['\"]([^'\"]*)['\"]", version_file, re.M
        )
    if version_match:
        return version_match.group(1)
    raise NameError("Version string must be defined in {}.".format(file_path))


# Exclude specified file or folder when installing overlay
def exclude_file_or_folder(exclude, path):
    for f in os.listdir(path):
        if f == exclude:
            if os.path.isdir(os.path.join(path, f)):
                rmtree(os.path.join(path, f))
            else:
                os.remove(os.path.join(path, f))


# Locate overlays in the BOARD folder
def find_overlays(path):
    if os.path.isdir(path):
        return [
            f
            for f in os.listdir(path)
            if os.path.isdir(os.path.join(path, f))
            and len(glob.glob(os.path.join(path, f, "*.bit"))) > 0
        ]
    else:
        return []


# Extend pynq package files by directory or by file
def extend_pynq_package(data_list):
    for data in data_list:
        if os.path.isdir(data):
            pynq_package_files.extend(
                [
                    os.path.join("..", root, f)
                    for root, _, files in os.walk(data)
                    for f in files
                ]
            )
        elif os.path.isfile(data):
            pynq_package_files.append(os.path.join("..", data))


# Enforce platform-dependent distribution
class BinaryDistribution(Distribution):
    def has_ext_modules(self):
        return True


# Extend pynq package files with Microblaze C BSPs and libraries
pynq_package_files = []
extend_pynq_package(
    [
        "pynq/lib/pynqmicroblaze",
        "pynq/lib/arduino",
        "pynq/lib/pmod",
        "pynq/lib/rpi",
        "pynq/lib/logictools",
        "pynq/pl_server/default.xclbin",
    ]
)


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

getting_started_notebooks = [
    "jupyter_notebooks.ipynb",
    "python_environment.ipynb",
    "jupyter_notebooks_advanced_features.ipynb",
]

# Merge BSP src to _video src
video = []
video.extend(_video_gpio)
video.extend(_video_vtc)
video.extend(_video_src)
video.extend(_common_src)


# Copy notebooks in pynq/notebooks
def copy_common_notebooks(staging_notebooks_dir):
    common_folders_files = [f for f in os.listdir("pynq/notebooks/")]
    for basename in common_folders_files:
        if basename != "arch":
            dst_folder_file = os.path.join(staging_notebooks_dir, basename)
            src_folder_file = os.path.join("pynq/notebooks/", basename)

            if os.path.isdir(src_folder_file):
                copy_tree(src_folder_file, dst_folder_file)
            elif os.path.isfile(src_folder_file):
                copy_file(src_folder_file, dst_folder_file)
    if os.path.exists(os.path.join("pynq/notebooks/arch", CPU_ARCH)):
        dir_fd = os.open(os.path.join("pynq/notebooks/arch", CPU_ARCH), os.O_RDONLY)
        dirs = os.fwalk(dir_fd=dir_fd)
        for dir, _, files, _ in dirs:
            if not os.path.exists(os.path.join(staging_notebooks_dir, dir)):
                os.mkdir(os.path.join(staging_notebooks_dir, dir))
            for f in files:
                copy_file(
                    os.path.join("pynq/notebooks/arch", CPU_ARCH, dir, f),
                    os.path.join(staging_notebooks_dir, dir, f),
                )
        os.close(dir_fd)


# Copy notebooks in boards/BOARD/notebooks
def copy_board_notebooks(staging_notebooks_dir, board):
    board_folder = "boards/{}".format(board)
    src_folder = os.path.join(board_folder, "notebooks")
    dst_folder = staging_notebooks_dir
    if os.path.isdir(src_folder):
        copy_tree(src_folder, dst_folder)


# Copy notebooks in boards/BOARD/OVERLAY/notebooks
def copy_overlay_notebooks(staging_notebooks_dir, board):
    from pynqutils.setup_utils import download_overlays

    board_folder = "boards/{}".format(board)
    download_overlays(board_folder, fail_at_lookup=True, cleanup=True)
    overlay_dirs = find_overlays(board_folder)
    for overlay in overlay_dirs:
        src_folder = os.path.join(board_folder, overlay, "notebooks")
        dst_folder = os.path.join(staging_notebooks_dir, overlay)
        if os.path.isdir(src_folder):
            copy_tree(src_folder, dst_folder)


# Copy documentation files in docs/source and docs/source/images
def copy_documentation_files(staging_notebooks_dir):
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
            copy_file(f, dst)
            if os.path.splitext(f)[1] == ".ipynb":
                dest_nb = os.path.join(dst, os.path.split(f)[1])
                # rewrite image paths in notebooks
                with open(dest_nb, "r+") as nb:
                    text = nb.read()
                    text = re.sub(r"\(../images", r"(images", text)
                    nb.seek(0)
                    nb.truncate(0)
                    nb.write(text)


# Rename and copy getting started notebooks
def rename_notebooks(staging_notebooks_dir):
    notebooks_getting_started_dst_dir = os.path.join(
        staging_notebooks_dir, "getting_started"
    )
    for ix, getting_started_nb in enumerate(getting_started_notebooks):
        new_nb_name = "{}_{}".format(ix + 1, getting_started_nb)
        src_file = os.path.join(notebooks_getting_started_dst_dir, getting_started_nb)
        dst_file = os.path.join(notebooks_getting_started_dst_dir, new_nb_name)
        if os.path.exists(dst_file):
            os.remove(dst_file)
        move_file(src_file, dst_file)


# Get environment variables
def check_env():
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


# Backup notebooks
def backup_notebooks(notebooks_dir):
    if os.path.isdir(notebooks_dir):
        notebooks_dir_backup = "{}_{}".format(
            notebooks_dir, datetime.now().strftime("%Y_%m_%d_%H_%M_%S")
        )
        copy_tree(notebooks_dir, notebooks_dir_backup)
    else:
        os.makedirs(notebooks_dir, exist_ok=True)


# Change ownership of the notebook folder
def change_ownership(notebooks_dir):
    subprocess.run(["chmod", "-R", "a+rwX", notebooks_dir])


# Copy all the notebooks
def copy_notebooks():
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


# Build extension includes Jupyter notebooks, in addition to C bindings
class BuildExtension(build_ext):
    def run_make(self, src_path, dst_path, output_lib):
        self.spawn(["make", "PYNQ_BUILD_ARCH={}".format(CPU_ARCH), "-C", src_path])
        os.makedirs(os.path.join(self.build_lib, dst_path), exist_ok=True)
        copy_file(
            src_path + output_lib, os.path.join(self.build_lib, dst_path, output_lib)
        )

    def install_overlays(self):
        board, _ = check_env()
        if board:
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
        build_ext.run(self)
        copy_notebooks()
        self.install_overlays()


pynq_version = find_version("pynq/__init__.py")
with open("README.md", encoding="utf-8") as fh:
    readme_lines = fh.readlines()[:]
long_description = "".join(readme_lines)
extend_pynq_package(
    [
        "pynq/lib/_pynq/embeddedsw/XilinxProcessorIPLib/drivers/v_hdmi_common/src",
        "pynq/lib/_pynq/embeddedsw/XilinxProcessorIPLib/drivers/v_hdmirxss/src",
        "pynq/lib/_pynq/embeddedsw/XilinxProcessorIPLib/drivers/v_hdmirx/src",
        "pynq/lib/_pynq/embeddedsw/XilinxProcessorIPLib/drivers/v_hdmitxss/src",
        "pynq/lib/_pynq/embeddedsw/XilinxProcessorIPLib/drivers/v_hdmitx/src",
        "pynq/lib/_pynq/embeddedsw/XilinxProcessorIPLib/drivers/video_common/src",
        "pynq/lib/_pynq/embeddedsw/XilinxProcessorIPLib/drivers/vphy/src",
        "pynq/lib/_pynq/embeddedsw/XilinxProcessorIPLib/drivers/vtc/src",
        "pynq/lib/_pynq/embeddedsw/XilinxProcessorIPLib/drivers/iic/src",
        "pynq/lib/_pynq/embeddedsw/XilinxProcessorIPLib/drivers/gpio/src",
        "pynq/lib/_pynq/embeddedsw/XilinxProcessorIPLib/drivers/iicps/src",
        "pynq/lib/_pynq/embeddedsw/XilinxProcessorIPLib/drivers/scugic/src",
        "pynq/lib/_pynq/embeddedsw/XilinxProcessorIPLib/drivers/axivdma/src",
        "pynq/lib/_pynq/embeddedsw/XilinxProcessorIPLib/drivers/mipicsiss/src",
        "pynq/lib/_pynq/embeddedsw/XilinxProcessorIPLib/drivers/csi/src",
        "pynq/lib/_pynq/embeddedsw/XilinxProcessorIPLib/drivers/dphy/src",
        "pynq/lib/_pynq/embeddedsw/lib/bsp/standalone/src",
        "pynq/lib/_pynq/embeddedsw_lib.mk",
        "pynq/lib/_pynq/common",
        "pynq/lib/_pynq/_audio",
        "pynq/lib/_pynq/_video",
        "pynq/lib/_pynq/_video/bsp/vtc",
        "pynq/lib/_pynq/_video/bsp/gpio",
        "pynq/lib/_pynq/_displayport",
        "pynq/lib/_pynq/_xhdmi",
        "pynq/lib/_pynq/_xiic",
        "pynq/lib/_pynq/_pcam5c",
        "pynq/notebooks",
        "pynq/tests",
        "pynq/metadata",
        "pynq/devices",
        "pynq/lib/tests",
    ]
)


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
    name="pynq",
    version=pynq_version,
    description="(PY)thon productivity for zy(NQ)",
    long_description=long_description,
    long_description_content_type="text/markdown",
    author="Xilinx PYNQ Development Team",
    author_email="pynq_support@xilinx.com",
    url="https://github.com/Xilinx/PYNQ",
    packages=find_packages(),
    cmdclass={
        "build_ext": BuildExtension,
    },
    distclass=BinaryDistribution,
    python_requires=">=3.5.2",
    install_requires=required,
    download_url="https://github.com/Xilinx/PYNQ",
    package_data={
        "pynq": pynq_package_files,
    },
    entry_points={
        "console_scripts": [
            "pynq = pynq._cli.cmd:main",
            "pynq-get-notebooks = pynq._cli.get_notebooks:main",
        ],
        "distutils.commands": [
            "download_overlays = pynqutils.setup_utils:du_download_overlays"
        ],
    },
    ext_modules=ext_modules,
    zip_safe=False,
    license="BSD 3-Clause",
)


