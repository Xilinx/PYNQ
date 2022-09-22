# Copyright (C) 2022 Xilinx, Inc
#
# SPDX-License-Identifier: BSD-3-Clause

from pynq import DefaultIP
import numpy as np

__author__ = "Mario Ruiz"
__copyright__ = "Copyright 2022, Xilinx"
__email__ = "pynq_support@xilinx.com"


_mi_offset = 0x40
_mi_disable = np.uint64(0x80000000)


def _mux_mi_gen(ports: int) -> tuple:
    """Generates index and address for AXI4-Stream Switch MI Mux Registers"""

    for i in range(ports):
        yield i, _mi_offset + 4 * i


class StreamSwitch(DefaultIP):
    """AXI4-Stream Switch Python driver

    This class provides the driver to control an AXI4-Stream Switch
    which uses the AXI4-Lite interfaces to specify the routing table.
    This routing mode requires that there is precisely only one path between
    manager and subordinate. When attempting to map the same subordinate
    interface to multiple manager interfaces, only the lowest subordinate
    interface is able to access the subordinate interface.
    Unused manager interfaces are automatically disabled by the logic
    provided in this driver
    """

    bindto = ['xilinx.com:ip:axis_switch:1.1']

    _control_reg = 0x0
    _reg_update = 1 << 1

    def __init__(self, description: dict):
        super().__init__(description=description)
        self.max_slots = int(description['parameters']['NUM_MI'])
        self._mi = np.zeros(self.max_slots, dtype=np.int64)

    def default(self) -> None:
        """Generate default configuration

        Configures the AXI4-Stream Switch to connect
        manager[j] to subordinate[j] for j = 0 to j = (max_slots-1)
        """

        for i in range(len(self._mi)):
            self._mi[i] = i
        self._populate_routing()

    def disable(self) -> None:
        """Disable all connections in the AXI4-Stream Switch"""

        for i in range(len(self._mi)):
            self._mi[i] = _mi_disable
        self._populate_routing()

    @property
    def mi(self):
        """ AXI4-Stream Switch configuration

        Configure the AXI4-Stream Switch given a numpy array
        Each element in the array controls a subordinate interface selection.
        If more than one element in the array is set to the same subordinate
        interface, then the lower manager interface wins.

        Parameters
        ----------
        conf_array : numpy array (dtype=np.int64)
            An array with the mapping of subordinate to manager interfaces
            The index in the array is the manager interface and
            the value is the subordinate interface slot
            The length of the array can vary from 1 to max slots
            Use negative values to indicate that a manager is disabled

            For instance, given this input [-1, 2, 1, 0]\n
                Subordinate 2 will be routed to Manager 1\n
                Subordinate 1 will be routed to Manager 2\n
                Subordinate 0 will be routed to Manager 3\n
                Manager 0 is disabled
        """
        mi = np.zeros(self.max_slots, dtype=np.int64)
        for idx, offset in _mux_mi_gen(self.max_slots):
            mi[idx] = self.read(offset)
        return mi

    @mi.setter
    def mi(self, conf_array: np.dtype(np.int64)):
        if conf_array.dtype is not np.dtype(np.int64):
            raise TypeError("Numpy array must be np.int64 dtype")
        elif (length := len(conf_array)) > self.max_slots:
            raise ValueError("Provided numpy array is bigger than "
                             "number of slots {}".format(self.max_slots))
        elif length < 1:
            raise ValueError("Input numpy array must be at least "
                             "one element long")

        for slot in range(len(conf_array)):
            if conf_array[slot] < 0:
                conf_array[slot] = _mi_disable

        if length != self.max_slots:
            new_slots = self.max_slots - length
            conf_array = np.append(conf_array,
                                   np.ones(new_slots, dtype=np.int32) *
                                   _mi_disable)

        self._mi = conf_array
        self._populate_routing()

    def _populate_routing(self):
        """Writes the current configuration to the AXI4-Stream Switch

        First the Mi selector values are written to the corresponding
        register. Once the registers have been programmed, a commit
        register transfers the programmed values from the register interface
        into the switch, for a short period of time the AXI4-Stream Switch
        interfaces are held in reset.
        """

        for idx, offset in _mux_mi_gen(self.max_slots):
            self.write(offset, int(self._mi[idx]))
        self.write(self._control_reg, self._reg_update)
