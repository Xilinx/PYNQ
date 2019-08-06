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

import os
import subprocess

__author__ = "Yun Rock Qu"
__copyright__ = "Copyright 2019, Xilinx"
__email__ = "pynq_support@xilinx.com"


SYSTEM_DEVICE_TREE_PATH = '/sys/kernel/config/device-tree/overlays'


def get_dtbo_path(bitfile_name):
    """This method returns the path of the dtbo file.

    For example, the input "/home/xilinx/pynq/overlays/base/base.bit" will
    lead to the result "/home/xilinx/pynq/overlays/base/base.dtbo".

    Parameters
    ----------
    bitfile_name : str
        The absolute path of the bit file.

    Returns
    -------
    str
        The absolute path of the dtbo file.

    """
    return ''.join(bitfile_name.split('.', -1)[:-1]) + '.dtbo'


def get_dtbo_base_name(dtbo_path):
    """This method returns the base name of the dtbo file.

    For example, the input "/home/xilinx/pynq/overlays/name1/name2.dtbo" will
    lead to the result "name2".

    Parameters
    ----------
    dtbo_path : str
        The absolute path of the dtbo file.

    Returns
    -------
    str
        The base name of the dtbo file.

    """
    return dtbo_path.split('/')[-1].split('.')[0]


class DeviceTreeSegment:
    """This class instantiates the device tree segment object.

    Attributes
    ----------
    dtbo_name : str
        The base name of the dtbo file as a string.
    dtbo_path : str
        The absolute path to the dtbo file as a string.

    """
    def __init__(self, dtbo_path):
        """Return a new DeviceTreeSegment object.

        Parameters
        ----------
        dtbo_path : str
            The absolute path to the dtbo file as a string.

        """
        if not os.path.isfile(dtbo_path):
            raise IOError('The dtbo file {} does not exist.'.format(dtbo_path))
        self.dtbo_path = dtbo_path
        self.dtbo_name = get_dtbo_base_name(dtbo_path)

    def is_dtbo_applied(self):
        """Show if the device tree segment has been applied.

        Returns
        -------
        bool
            True if the device tree status shows `applied`.

        """
        command = 'cat ' + os.path.join(
            SYSTEM_DEVICE_TREE_PATH, self.dtbo_name, 'status')
        status = subprocess.check_output(command.split())
        return status.decode('utf-8') == 'applied\n'

    def insert(self):
        """Insert the dtbo file into the device tree.

        The method will raise an exception if the insertion has failed.

        """
        command = 'mkdir -p ' + os.path.join(
            SYSTEM_DEVICE_TREE_PATH, self.dtbo_name)
        _ = subprocess.check_output(command.split())

        command = 'cat ' + self.dtbo_path + ' > ' + os.path.join(
            SYSTEM_DEVICE_TREE_PATH, self.dtbo_name, 'dtbo')
        _ = os.system(command)

        if not self.is_dtbo_applied():
            raise RuntimeError('Device tree {} cannot be applied.'.format(
                self.dtbo_name))

    def remove(self):
        """Remove the dtbo file from the device tree.

        """
        dtbo_folder = os.path.join(SYSTEM_DEVICE_TREE_PATH, self.dtbo_name)
        if os.path.exists(dtbo_folder):
            command = 'rmdir ' + dtbo_folder
            _ = subprocess.check_output(command.split())
