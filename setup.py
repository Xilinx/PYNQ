#   Copyright (c) 2016, Xilinx, Inc.
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

__author__ = "Giuseppe Natale, Yun Rock Qu"
__copyright__ = "Copyright 2016, Xilinx"
__email__ = "pynq_support@xilinx.com"

from setuptools import setup, Extension, find_packages, Distribution
from setuptools.command.build_ext import build_ext
from setuptools.command.install import install
from setuptools.command.develop import develop
from distutils.dir_util import copy_tree
import glob
import re
import shutil
import subprocess
import os
import warnings
from datetime import datetime


# Requirement
required = [
    'setuptools>=24.2.0',
    'cffi',
    'numpy',
    'pandas',
    'Pillow>=5.0.0',
    'pytest',
    'pyeda',
    'pygraphviz',
    'matplotlib'
]


# Parse version number
def find_version(file_path):
    with open(file_path, 'r') as fp:
        version_file = fp.read()
        version_match = re.search(r"^__version__ = ['\"]([^'\"]*)['\"]",
                                  version_file, re.M)
    if version_match:
        return version_match.group(1)
    raise NameError("Version string must be defined in {}.".format(file_path))


# Board specific package delivery setup
def exclude_from_files(exclude, path):
    return [file for file in os.listdir(path)
            if os.path.isfile(os.path.join(path, file))
            and file != exclude]


def find_overlays(path):
    return [f for f in os.listdir(path)
            if os.path.isdir(os.path.join(path, f))
            and len(glob.glob(os.path.join(path, f, "*.bit"))) > 0]


def collect_pynq_overlays():
    overlay_files = []
    overlay_dirs = find_overlays(board_folder)
    for ol in overlay_dirs:
        copy_tree(os.path.join(board_folder, ol),
                        os.path.join("pynq/overlays", ol))
        newdir = os.path.join("pynq/overlays", ol)
        files = exclude_from_files('makefile', newdir)
        overlay_files.extend(
                [os.path.join("..", newdir, f) for f in files])
    return overlay_files


# Enforce platform-dependent distribution
class BinaryDistribution(Distribution):
    def has_ext_modules(self):
        return True


pynq_package_files = []
if 'BOARD' not in os.environ:
    warnings.warn("Use `export BOARD=<board-name>` "
                  "to get board specific overlays (e.g. Pynq-Z1, ZCU104).",
                  UserWarning)
    board = None
    board_folder = None
else:
    board = os.environ['BOARD']
    board_folder = 'boards/{}/'.format(board)
    if not os.path.isdir(board_folder):
        warnings.warn("Could not find board folder {}".format(board),
                      UserWarning)
        board_folder = None
    else:
        pynq_package_files.extend(collect_pynq_overlays())


# Extend data_files with Microblaze C BSPs and libraries
microblaze_data_dirs = ['pynq/lib/pynqmicroblaze/modules',
                        'pynq/lib/arduino/bsp_iop_arduino',
                        'pynq/lib/pmod/bsp_iop_pmod',
                        'pynq/lib/rpi/bsp_iop_rpi']

for mbdir in microblaze_data_dirs:
    pynq_package_files.extend(
        [os.path.join("..", root, f)
         for root, _, files in os.walk(mbdir) for f in files]
    )


# Device family constants
ZYNQ_ARCH = "armv7l"
ZU_ARCH = "aarch64"
if 'PYNQ_BUILD_ARCH' in os.environ:
    CPU_ARCH = os.environ['PYNQ_BUILD_ARCH']
else:
    CPU_ARCH = os.uname().machine
CPU_ARCH_IS_SUPPORTED = CPU_ARCH in [ZYNQ_ARCH, ZU_ARCH]


# Notebook delivery
default_nb_dir = '/home/xilinx/jupyter_notebooks'
notebooks_dir = None
if 'PYNQ_JUPYTER_NOTEBOOKS' in os.environ:
    notebooks_dir = os.environ['PYNQ_JUPYTER_NOTEBOOKS']
elif os.path.exists(default_nb_dir):
    notebooks_dir = default_nb_dir

if notebooks_dir is None:
    notebooks_getting_started_dst_dir = None
    notebooks_getting_started_dst_img_dir = None
    notebooks_getting_started_src_dir = None
    notebooks_getting_started_src_img_dir = None
    warnings.warn("Use `export PYNQ_JUPYTER_NOTEBOOKS=<path-to-jupyter-home>` "
                  "to get the notebooks.", UserWarning)
else:
    notebooks_getting_started_dst_dir = os.path.join(
        notebooks_dir, 'getting_started')
    notebooks_getting_started_dst_img_dir = os.path.join(
        notebooks_getting_started_dst_dir, 'images')
    notebooks_getting_started_src_dir = os.path.join(
        'docs', 'source')
    notebooks_getting_started_src_img_dir = os.path.join(
        notebooks_getting_started_src_dir, 'images')


# Video source files
_video_src = ['pynq/lib/_pynq/_video/_video.c',
              'pynq/lib/_pynq/_video/_capture.c',
              'pynq/lib/_pynq/_video/_display.c',
              'pynq/lib/_pynq/_video/py_xvtc.c',
              'pynq/lib/_pynq/_video/utils.c',
              'pynq/lib/_pynq/_video/py_xgpio.c',
              'pynq/lib/_pynq/_video/video_capture.c',
              'pynq/lib/_pynq/_video/video_display.c']

_video_gpio = \
    ['pynq/lib/_pynq/_video/bsp/gpio/xgpio.c',
     'pynq/lib/_pynq/_video/bsp/gpio/xgpio_extra.c',
     'pynq/lib/_pynq/_video/bsp/gpio/xgpio_intr.c',
     'pynq/lib/_pynq/_video/bsp/gpio/xgpio_selftest.c']

_video_vtc = \
    ['pynq/lib/_pynq/_video/bsp/vtc/xvtc.c',
     'pynq/lib/_pynq/_video/bsp/vtc/xvtc_intr.c',
     'pynq/lib/_pynq/_video/bsp/vtc/xvtc_selftest.c']

_common_src = \
    ['pynq/lib/_pynq/common/xil_stubs.c']

_bsp_includes = \
    ['pynq/lib/_pynq/embeddedsw/lib/bsp/standalone/src/common',
     'pynq/lib/_pynq/embeddedsw/lib/bsp/standalone/src/arm/common',
     'pynq/lib/_pynq/embeddedsw/lib/bsp/standalone/src/arm/common/gcc']

if CPU_ARCH == ZYNQ_ARCH:
    _bsp_includes.append(
        'pynq/lib/_pynq/embeddedsw/lib/bsp/standalone/src/arm/cortexa9')
elif CPU_ARCH == ZU_ARCH:
    _bsp_includes.append(
        'pynq/lib/_pynq/embeddedsw/lib/bsp/standalone/src/arm/cortexa53/64bit')

getting_started_notebooks = \
    ['jupyter_notebooks.ipynb',
     'python_environment.ipynb',
     'jupyter_notebooks_advanced_features.ipynb']

# Merge BSP src to _video src
video = []
video.extend(_video_gpio)
video.extend(_video_vtc)
video.extend(_video_src)
video.extend(_common_src)


# Copy notebooks in pynq/notebooks
def copy_common_notebooks():
    if notebooks_dir is None:
        return None

    common_folders_files = [f for f in os.listdir('pynq/notebooks/')]
    for basename in common_folders_files:
        dst_folder_file = os.path.join(notebooks_dir, basename)
        src_folder_file = os.path.join('pynq/notebooks/', basename)

        if os.path.isdir(dst_folder_file):
            shutil.rmtree(dst_folder_file)
        elif os.path.isfile(dst_folder_file):
            os.remove(dst_folder_file)

        if os.path.isdir(src_folder_file):
            copy_tree(src_folder_file, dst_folder_file)
        elif os.path.isfile(src_folder_file):
            shutil.copy(src_folder_file, dst_folder_file)


# Copy notebooks in boards/BOARD/notebooks
def copy_board_notebooks():
    if notebooks_dir is None or board_folder is None:
        return None

    src_folder = os.path.join(board_folder, 'notebooks')
    dst_folder = notebooks_dir
    if os.path.isdir(src_folder):
        copy_tree(src_folder, dst_folder)


# Copy notebooks in boards/BOARD/OVERLAY/notebooks
def copy_overlay_notebooks():
    if notebooks_dir is None or board_folder is None:
        return None

    if os.path.isdir(board_folder):
        overlay_notebook_folders = [
            (os.path.join(notebooks_dir, overlay),
             os.path.join(board_folder, overlay, 'notebooks/'))
            for overlay in list(os.listdir(board_folder))
            if os.path.isdir(os.path.join(board_folder, overlay, 'notebooks'))]

        for dst_folder, src_folder in overlay_notebook_folders:
            if os.path.exists(dst_folder):
                shutil.rmtree(dst_folder)
            copy_tree(src_folder, dst_folder)


# Copy documentation files in docs/source and docs/source/images
def copy_documentation_files():
    if notebooks_dir is None:
        return None

    doc_files = list()
    doc_files.append((notebooks_getting_started_dst_dir,
                      [os.path.join(notebooks_getting_started_src_dir, nb)
                       for nb in getting_started_notebooks]))
    doc_files.extend([(notebooks_getting_started_dst_img_dir,
                       [os.path.join(root, f) for f in files])
                      for root, dirs, files in os.walk(
            notebooks_getting_started_src_img_dir)])

    if not os.path.exists(notebooks_getting_started_dst_img_dir):
        os.makedirs(notebooks_getting_started_dst_img_dir)
    for dst, files in doc_files:
        for f in files:
            shutil.copy(f, dst)


# Rename and copy getting started notebooks
def rename_notebooks():
    if notebooks_dir is None:
        return None

    for ix, getting_started_nb in enumerate(getting_started_notebooks):
        new_nb_name = '{}_{}'.format(ix + 1, getting_started_nb)
        src_file = os.path.join(notebooks_getting_started_dst_dir,
                                getting_started_nb)
        dst_file = os.path.join(notebooks_getting_started_dst_dir,
                                new_nb_name)
        shutil.move(src_file, dst_file)


# Change ownership of the notebook folder
def change_ownership():
    subprocess.run(['chown', '-R', 'xilinx:xilinx', notebooks_dir])


# Backup notebooks
def backup_notebooks():
    if notebooks_dir is None:
        return None

    notebooks_dir_backup = '{}_{}'.format(notebooks_dir,
                                          datetime.now().strftime(
                                              "%Y_%m_%d_%H_%M_%S"))
    copy_tree(notebooks_dir, notebooks_dir_backup)
    return notebooks_dir_backup


# Restart PL server if service available
def restart_pl_server():
    if board:
        subprocess.run(['systemctl', 'restart', 'pl_server'])


# Build extension includes Jupyter notebooks, in addition to C bindings
class BuildExtension(build_ext):
    def run_make(self, src_path, dst_path, output_lib):
        self.spawn(['make', 'PYNQ_BUILD_ARCH={}'.format(CPU_ARCH),
                    '-C', src_path])
        shutil.copyfile(src_path + output_lib, dst_path + output_lib)

    def run(self):
        if CPU_ARCH == ZYNQ_ARCH:
            self.run_make("pynq/lib/_pynq/_audio/", "pynq/lib/",
                          "libaudio.so")
            self.run_make("pynq/lib/_pynq/_xiic/", "pynq/lib/",
                          "libiic.so")
        elif CPU_ARCH == ZU_ARCH:
            self.run_make("pynq/lib/_pynq/_displayport/", "pynq/lib/video/",
                          "libdisplayport.so")
            self.run_make("pynq/lib/_pynq/_xhdmi/", "pynq/lib/video/",
                          "libxhdmi.so")
            self.run_make("pynq/lib/_pynq/_xiic/", "pynq/lib/",
                          "libiic.so")

        if notebooks_dir:
            backup_notebooks()
            copy_common_notebooks()
            copy_board_notebooks()
            copy_overlay_notebooks()
            copy_documentation_files()
            rename_notebooks()
            change_ownership()
        build_ext.run(self)


# Post development command
class PostDevelop(develop):
    def run(self):
        develop.run(self)
        restart_pl_server()


# Post installation command
class PostInstall(install):
    def run(self):
        install.run(self)
        restart_pl_server()


if CPU_ARCH == ZYNQ_ARCH:
    ext_modules = [
        Extension('pynq.lib._video', video,
                  include_dirs=['pynq/lib/_pynq/_video',
                                'pynq/lib/_pynq/_video/bsp/vtc',
                                'pynq/lib/_pynq/_video/bsp/gpio',
                                'pynq/lib/_pynq/common/armv7l'] + _bsp_includes
                  ),
    ]
else:
    ext_modules = []
pynq_version = find_version('pynq/__init__.py')
pynq_package_files.extend(['tests/*', 'js/*', '*.bin', '*.so', '*.pdm'])


setup(name='pynq',
      version=pynq_version,
      description='(PY)thon productivity for zy(NQ)',
      author='Xilinx PYNQ Development Team',
      author_email='pynq_support@xilinx.com',
      url='https://github.com/Xilinx/PYNQ',
      packages=find_packages(),
      cmdclass={
          "build_ext": BuildExtension,
          "develop": PostDevelop,
          "install": PostInstall
          },
      distclass=BinaryDistribution,
      python_requires='>3.5.0',
      install_requires=required,
      download_url='https://github.com/Xilinx/PYNQ',
      package_data={
          '': pynq_package_files,
      },
      entry_points={
          'console_scripts': [
              'start_pl_server.py = pynq.pl:_start_server',
              'stop_pl_server.py = pynq.pl:_stop_server'
          ]
      },
      ext_modules=ext_modules,
      zip_safe=False,
      license="BSD 3-Clause"
      )

