#   Copyright (c) 2016, Xilinx, Inc.
#   SPDX-License-Identifier: BSD-3-Clause

import os



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
    return os.path.splitext(bitfile_name)[0] + '.dtbo'


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
        self.sysfs_dir = os.path.join(SYSTEM_DEVICE_TREE_PATH, self.dtbo_name)

    def is_dtbo_applied(self):
        """Show if the device tree segment has been applied.

        Returns
        -------
        bool
            True if the device tree status shows `applied`.

        """
        if not os.path.exists(self.sysfs_dir):
            return False
        with open(os.path.join(self.sysfs_dir, 'status'), 'r') as f:
            return f.read() == 'applied\n'

    def insert(self):
        """Insert the dtbo file into the device tree.

        The method will raise an exception if the insertion has failed.

        """
        os.makedirs(self.sysfs_dir, exist_ok=True)
        with open(self.dtbo_path, 'rb') as f:
            dtbo_data = f.read()

        with open(os.path.join(self.sysfs_dir, 'dtbo'),
                  'wb', buffering=0) as f:
            f.write(dtbo_data)

        # The only way to detect a DTBO insert failure is to try and
        # read back the contents of the dtbo attribute and see if
        # it is non-empty

        with open(os.path.join(self.sysfs_dir, 'dtbo'),
                'rb', buffering=0) as f:
            # The entire DTBO file has to be read in a single syscall
            # otherwise and IO error will occur
            read_back = f.read(1024*1024)
            if read_back != dtbo_data:
                raise RuntimeError('Device tree {} cannot be applied'.format(
                    self.dtbo_name))

        if not self.is_dtbo_applied():
            raise RuntimeError('Device tree {} cannot be applied.'.format(
                self.dtbo_name))

    def remove(self):
        """Remove the dtbo file from the device tree.

        """
        if os.path.exists(self.sysfs_dir):
            os.rmdir(self.sysfs_dir)


