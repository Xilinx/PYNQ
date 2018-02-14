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

from setuptools import setup, Extension, find_packages
import shutil
import subprocess
import sys
import os
import site
import warnings
from datetime import datetime


# Board specific package delivery setup
def exclude_from_files(exclude, path):
    return [file for file in os.listdir(path)
            if os.path.isfile(os.path.join(path, file))
            and file != exclude]


def exclude_from_dirs(exclude, path):
    return [folder for folder in os.listdir(path)
            if os.path.isdir(os.path.join(path, folder))
            and folder != exclude]


def collect_pynq_data_files():
    return [(os.path.join(
        '{}/pynq/overlays'.format(os.path.dirname(site.__file__) \
             + "/site-packages"), ol),
             [os.path.join(board_folder, ol, f)
              for f in exclude_from_files(
                 'makefile', os.path.join(board_folder, ol))])
        for ol in exclude_from_dirs('notebooks', board_folder)]


if 'BOARD' not in os.environ:
    print("Please set the BOARD environment variable "
          "to get any BOARD specific overlays (e.g. Pynq-Z1).")
    board = None
    board_folder = None
    pynq_data_files = []
else:
    board = os.environ['BOARD']
    board_folder = 'boards/{}/'.format(board)
    pynq_data_files = collect_pynq_data_files()


# Extend data_files with Microblaze C BSPs and libraries
microblaze_data_dirs = ['pynq/lib/pynqmicroblaze/modules',
                        'pynq/lib/arduino/bsp_iop_arduino',
                        'pynq/lib/pmod/bsp_iop_pmod']

for mbdir in microblaze_data_dirs:
    pynq_data_files.extend(
        [(os.path.join(os.path.dirname(site.__file__) + "/site-packages", root),
         [os.path.join(root, f) for f in files])
        for root, _, files in os.walk(mbdir)]
    )

# Device family constants
ZYNQ_ARCH = "armv7l"
CPU_ARCH = os.uname().machine
CPU_ARCH_IS_SUPPORTED = CPU_ARCH in [ZYNQ_ARCH]

# Notebook delivery
default_nb_dir = '/home/xilinx/jupyter_notebooks'
if 'PYNQ_JUPYTER_NOTEBOOKS' in os.environ:
    notebooks_dir = os.environ['PYNQ_JUPYTER_NOTEBOOKS']
elif os.path.exists(default_nb_dir):
    notebooks_dir = default_nb_dir
else:
    notebooks_dir = None

if notebooks_dir is not None:
    notebooks_getting_started_dst_dir = os.path.join(notebooks_dir, 'getting_started')
    notebooks_getting_started_dst_img_dir = os.path.join(notebooks_getting_started_dst_dir, 'images')
    notebooks_getting_started_src_dir = os.path.join('docs', 'source')
    notebooks_getting_started_src_img_dir = os.path.join(notebooks_getting_started_src_dir, 'images')
else:
    notebooks_getting_started_dst_dir = None
    notebooks_getting_started_dst_img_dir = None
    notebooks_getting_started_src_dir = None
    notebooks_getting_started_src_img_dir = None

# Video source files
_video_src = ['pynq/lib/_pynq/_video/_video.c',
              'pynq/lib/_pynq/_video/_capture.c',
              'pynq/lib/_pynq/_video/_display.c',
              'pynq/lib/_pynq/_video/_frame.c',
              'pynq/lib/_pynq/_video/_legacy_display.c',
              'pynq/lib/_pynq/_video/_legacy_capture.c',
              'pynq/lib/_pynq/_video/axivdma_channel.c',
              'pynq/lib/_pynq/src/gpio.c',
              'pynq/lib/_pynq/src/py_xaxivdma.c',
              'pynq/lib/_pynq/src/py_xvtc.c',
              'pynq/lib/_pynq/src/utils.c',
              'pynq/lib/_pynq/src/py_xgpio.c',
              'pynq/lib/_pynq/src/video_capture.c',
              'pynq/lib/_pynq/src/video_display.c']

# BSP source files
bsp_axivdma = \
    ['pynq/lib/_pynq/bsp/ps7_cortexa9_0/libsrc/axivdma_v6_4/src/xaxivdma.c',
     'pynq/lib/_pynq/bsp/ps7_cortexa9_0/libsrc/axivdma_v6_4/src/xaxivdma_intr.c',
     'pynq/lib/_pynq/bsp/ps7_cortexa9_0/libsrc/axivdma_v6_4/src/xaxivdma_selftest.c']

bsp_gpio = \
    ['pynq/lib/_pynq/bsp/ps7_cortexa9_0/libsrc/gpio_v4_3/src/xgpio.c',
     'pynq/lib/_pynq/bsp/ps7_cortexa9_0/libsrc/gpio_v4_3/src/xgpio_extra.c',
     'pynq/lib/_pynq/bsp/ps7_cortexa9_0/libsrc/gpio_v4_3/src/xgpio_intr.c',
     'pynq/lib/_pynq/bsp/ps7_cortexa9_0/libsrc/gpio_v4_3/src/xgpio_selftest.c']

bsp_vtc = \
    ['pynq/lib/_pynq/bsp/ps7_cortexa9_0/libsrc/vtc_v7_2/src/xvtc.c',
     'pynq/lib/_pynq/bsp/ps7_cortexa9_0/libsrc/vtc_v7_2/src/xvtc_intr.c',
     'pynq/lib/_pynq/bsp/ps7_cortexa9_0/libsrc/vtc_v7_2/src/xvtc_selftest.c']

bsp_standalone = \
    ['pynq/lib/_pynq/bsp/ps7_cortexa9_0/libsrc/standalone_v6_5/src/xplatform_info.c',
     'pynq/lib/_pynq/bsp/ps7_cortexa9_0/libsrc/standalone_v6_5/src/xil_assert.c',
     'pynq/lib/_pynq/bsp/ps7_cortexa9_0/libsrc/standalone_v6_5/src/xil_io.c',
     'pynq/lib/_pynq/bsp/ps7_cortexa9_0/libsrc/standalone_v6_5/src/xil_exception.c']

getting_started_notebooks = \
    ['jupyter_notebooks.ipynb',
     'python_environment.ipynb',
     'jupyter_notebooks_advanced_features.ipynb']

# Merge BSP src to _video src
video = []
video.extend(bsp_standalone)
video.extend(bsp_axivdma)
video.extend(bsp_gpio)
video.extend(bsp_vtc)
video.extend(_video_src)


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
            shutil.copytree(src_folder_file, dst_folder_file)
        elif os.path.isfile(src_folder_file):
            shutil.copy(src_folder_file, dst_folder_file)


# Copy notebooks in boards/BOARD/notebooks/getting_started
def copy_getting_started_notebooks():
    if notebooks_dir is None:
        return None

    src_folder = os.path.join(board_folder, 'notebooks/getting_started')
    dst_folder = notebooks_getting_started_dst_dir
    if os.path.isdir(dst_folder):
        shutil.rmtree(dst_folder)
    if os.path.isdir(src_folder):
        shutil.copytree(src_folder, dst_folder)


# Copy notebooks in boards/BOARD/OVERLAY/notebooks
def copy_overlay_notebooks():
    if notebooks_dir is None:
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
            shutil.copytree(src_folder, dst_folder)


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
    try:
        shutil.copytree(notebooks_dir, notebooks_dir_backup)
    except Exception as e:
        print('Unable to backup notebooks.')
        raise e
    return notebooks_dir_backup


# Run Makefiles here
def run_make(src_path, dst_path, output_lib):
    status = subprocess.check_call(["make", "-C", src_path])
    if status != 0:
        print("Error while running make for ", output_lib)
        sys.exit(1)
    shutil.copyfile(src_path + output_lib, dst_path + output_lib)


if len(sys.argv) > 1 and sys.argv[1] == 'install' and CPU_ARCH_IS_SUPPORTED:
    run_make("pynq/lib/_pynq/_apf/", "pynq/lib/", "libdma.so")
    run_make("pynq/lib/_pynq/_audio/", "pynq/lib/", "libaudio.so")
    backup_notebooks()
    copy_common_notebooks()
    copy_getting_started_notebooks()
    copy_overlay_notebooks()
    copy_documentation_files()
    rename_notebooks()
    change_ownership()


if CPU_ARCH_IS_SUPPORTED:
    ext_modules = [
        Extension('pynq.lib._video', video,
                  include_dirs=['pynq/lib/_pynq/inc',
                                'pynq/lib/_pynq/bsp/ps7_cortexa9_0/include'],
                  libraries=['sds_lib'],
                  library_dirs=['/usr/lib'],
                  ),
    ]
else:
    warnings.warn("PYNQ does not support the CPU Architecture: {}"
                  .format(CPU_ARCH), ResourceWarning)
    ext_modules = []


setup(name='pynq',
      version='2.1',
      description='(PY)thon productivity for zy(NQ)',
      author='Xilinx PYNQ Development Team',
      author_email='pynq_support@xilinx.com',
      url='https://github.com/Xilinx/PYNQ',
      packages=find_packages(),
      download_url='https://github.com/Xilinx/PYNQ',
      package_data={
          '': ['tests/*', 'js/*', '*.bin', '*.so', '*.pdm'],
      },
      entry_points={
          'console_scripts': [
              'start_pl_server.py = pynq.pl:_start_server',
              'stop_pl_server.py = pynq.pl:_stop_server'
          ]
      },
      ext_modules=ext_modules,
      data_files=pynq_data_files
      )

if board:
    print('Restarting PL server')
    subprocess.run(['systemctl', 'restart', 'pl_server'])
