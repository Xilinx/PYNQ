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
import stat
from datetime import datetime

''' Board specific package delivery setup '''
if 'BOARD' not in os.environ:
    print("Please set the BOARD environment variable to get any BOARD specific overlays (e.g. Pynq-Z1).")
    board = None
    board_folder = None
    pynq_data_files = None
else:
    board = os.environ['BOARD']
    board_folder = 'boards/{}/'.format(board)
    pynq_data_files = [(os.path.join('{}/pynq'.format(site.getsitepackages()[0]), root.replace(board_folder, '')),
                        [os.path.join(root, f) for f in files]) for root, dirs, files in os.walk(board_folder)]

''' Notebook Delivery '''
default_nb_dir = '/home/xilinx/jupyter_notebooks'
if 'PYNQ_JUPYTER_NOTEBOOKS' in os.environ:
    notebooks_dir = os.environ['PYNQ_JUPYTER_NOTEBOOKS']
elif os.path.exists(default_nb_dir):
    notebooks_dir = default_nb_dir
else:
    notebooks_dir = None

if notebooks_dir is not None:
    notebooks_getting_started_dir = os.path.join(notebooks_dir, 'getting_started')
    notebooks_getting_started_dst_img_dir = os.path.join(notebooks_getting_started_dir, 'images')
    notebooks_getting_started_src_dir = os.path.join('docs', 'source')
    notebooks_getting_started_src_img_dir = os.path.join(notebooks_getting_started_src_dir, 'images')
else:
    notebooks_getting_started_dir = None
    notebooks_getting_started_dst_img_dir = None
    notebooks_getting_started_src_dir = None
    notebooks_getting_started_src_img_dir = None

# Video source files
_video_src = ['pynq/lib/_pynq/_video/_video.c', 'pynq/lib/_pynq/_video/_capture.c',
              'pynq/lib/_pynq/_video/_display.c',
              'pynq/lib/_pynq/src/gpio.c', 'pynq/lib/_pynq/src/py_xaxivdma.c',
              'pynq/lib/_pynq/src/py_xvtc.c', 'pynq/lib/_pynq/src/utils.c',
              'pynq/lib/_pynq/src/py_xgpio.c',
              'pynq/lib/_pynq/src/video_capture.c',
              'pynq/lib/_pynq/src/video_display.c']

# BSP source files
bsp_axivdma = \
    ['pynq/lib/_pynq/bsp/ps7_cortexa9_0/libsrc/axivdma_v6_0/src/xaxivdma.c',
     'pynq/lib/_pynq/bsp/ps7_cortexa9_0/libsrc/axivdma_v6_0/src/xaxivdma_channel.c',
     'pynq/lib/_pynq/bsp/ps7_cortexa9_0/libsrc/axivdma_v6_0/src/xaxivdma_intr.c',
     'pynq/lib/_pynq/bsp/ps7_cortexa9_0/libsrc/axivdma_v6_0/src/xaxivdma_selftest.c']

bsp_gpio = \
    ['pynq/lib/_pynq/bsp/ps7_cortexa9_0/libsrc/gpio_v4_0/src/xgpio.c',
     'pynq/lib/_pynq/bsp/ps7_cortexa9_0/libsrc/gpio_v4_0/src/xgpio_extra.c',
     'pynq/lib/_pynq/bsp/ps7_cortexa9_0/libsrc/gpio_v4_0/src/xgpio_intr.c',
     'pynq/lib/_pynq/bsp/ps7_cortexa9_0/libsrc/gpio_v4_0/src/xgpio_selftest.c']

bsp_vtc = \
    ['pynq/lib/_pynq/bsp/ps7_cortexa9_0/libsrc/vtc_v7_0/src/xvtc.c',
     'pynq/lib/_pynq/bsp/ps7_cortexa9_0/libsrc/vtc_v7_0/src/xvtc_intr.c',
     'pynq/lib/_pynq/bsp/ps7_cortexa9_0/libsrc/vtc_v7_0/src/xvtc_selftest.c']

bsp_standalone = \
    ['pynq/lib/_pynq/bsp/ps7_cortexa9_0/libsrc/standalone_v5_2/src/xplatform_info.c',
     'pynq/lib/_pynq/bsp/ps7_cortexa9_0/libsrc/standalone_v5_2/src/xil_assert.c',
     'pynq/lib/_pynq/bsp/ps7_cortexa9_0/libsrc/standalone_v5_2/src/xil_io.c',
     'pynq/lib/_pynq/bsp/ps7_cortexa9_0/libsrc/standalone_v5_2/src/xil_exception.c']

getting_started_notebooks = \
    ['3_jupyter_notebook.ipynb', '4_programming_python.ipynb', '5_programming_onboard.ipynb',
     '8_base_overlay_iop.ipynb', '9_base_overlay_video.ipynb', '10_base_overlay_audio.ipynb']

# Merge BSP src to _video src
video = []
video.extend(bsp_standalone)
video.extend(bsp_axivdma)
video.extend(bsp_gpio)
video.extend(bsp_vtc)
video.extend(_video_src)


# Build Package Data files - notebooks, overlays
def fill_notebooks_dir():
    if notebooks_dir is None:
        return None

    # boards/BOARD/OVERLAY/notebooks
    overlay_notebook_folders = [(ol, os.path.join(board_folder, ol, 'notebooks/')) for ol in os.listdir(board_folder)
                                if os.path.isdir(os.path.join(board_folder, ol, 'notebooks'))]

    # pynq/notebooks/*
    pynq_notebook_files = ([(os.path.join(notebooks_dir, root.replace('pynq/notebooks/', '')),
                             [os.path.join(root, f) for f in files]) for root, dirs, files in
                            os.walk('pynq/notebooks/')])

    # boards/BOARD/OVERLAY_NAME/notebooks/*
    for ol, nb_dir in overlay_notebook_folders:
        pynq_notebook_files.extend([(os.path.join(notebooks_dir, root.replace(nb_dir, f'{ol}/')),
                                     [os.path.join(root, f) for f in files]) for root, dirs, files in os.walk(nb_dir)])

    # docs/source/<subset of notebooks>
    pynq_notebook_files.append((notebooks_getting_started_dir,
                                [os.path.join('docs', 'source', nb) for nb in getting_started_notebooks]))

    # docs/source/images/*
    pynq_notebook_files.extend([(notebooks_getting_started_dst_img_dir,
                                 [os.path.join(root, f) for f in files])
                                for root, dirs, files in os.walk(notebooks_getting_started_src_img_dir)])

    # copy notebooks into final destination
    for dst, files in pynq_notebook_files:
        if not os.path.exists(dst):
            os.makedirs(dst)
        for file in files:
            shutil.copy(file, dst)
            dst_file = os.path.join(dst, os.path.basename(file))
            os.chmod(dst_file, os.stat(dst_file).st_mode | stat.S_IWOTH)

    # rename and copy getting started notebooks
    for ix, getting_started_nb in enumerate(getting_started_notebooks):
        new_nb_name = f'{ix+1}_{getting_started_nb.split("_",1)[1]}'
        src_file = os.path.join(notebooks_getting_started_dir, getting_started_nb)
        dst_file = os.path.join(notebooks_getting_started_dir, new_nb_name)
        shutil.move(src_file, dst_file)


# Backup Notebooks
def backup_notebooks():
    if notebooks_dir is None:
        return None

    notebooks_dir_backup = '{}_{}'.format(notebooks_dir, datetime.now().strftime("%Y_%m_%d_%H-%M-%S"))
    try:
        shutil.copytree(notebooks_dir, notebooks_dir_backup)
    except Exception as e:
        print('Unable to backup notebooks {}'.format(e))
        raise e
    return notebooks_dir_backup


# Run Makefiles here
def run_make(src_path, dst_path, output_lib):
    status = subprocess.check_call(["make", "-C", src_path])
    if status is not 0:
        print("Error while running make for", output_lib, "Exiting..")
        sys.exit(1)
    shutil.copyfile(src_path + output_lib, dst_path + output_lib)


if len(sys.argv) > 1 and sys.argv[1] == 'install':
    run_make("pynq/lib/_pynq/_apf/", "pynq/lib/", "libdma.so")
    run_make("pynq/lib/_pynq/_audio/", "pynq/lib/", "libaudio.so")

    backup_notebooks()
    fill_notebooks_dir()

setup(name='pynq',
      version='1.5',
      description='Python for Xilinx package',
      author='XilinxPythonProject',
      author_email='pynq_support@xilinx.com',
      url='https://github.com/Xilinx/PYNQ',
      packages=find_packages(),
      download_url='https://github.com/Xilinx/PYNQ',
      package_data={
          '': ['tests/*', 'js/*', '*.bin', '*.so', 'bitstream/*', '*.pdm'],
      },
      scripts=['bin/start_pl_server.py',
               'bin/stop_pl_server.py'],
      ext_modules=[
          Extension('pynq.lib._video', video,
                    include_dirs=['pynq/lib/_pynq/inc',
                                  'pynq/lib/_pynq/bsp/ps7_cortexa9_0/include'],
                    libraries=['sds_lib'],
                    library_dirs=['/usr/lib'],
                    ),
      ],
      data_files=pynq_data_files
      )
