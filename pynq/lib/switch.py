#   Copyright (c) 2016, Xilinx, Inc.
#   SPDX-License-Identifier: BSD-3-Clause



class Switch(object):
    """This class controls the onboard switches.

    Attributes
    ----------
    _impl : object
        An object with appropriate Switch methods

    """

    def __init__(self, device):
        """Create a new Switch object.

        Parameters
        ----------
        device : object
            An object with appropriate Switch methods:
            read, wait_for_value

        """
        methods = ['read', 'wait_for_value']
        if all(m in dir(device) for m in methods):
            self._impl = device
        else:
            raise TypeError("'device' must contain Switch methods: " +
                            str(methods))

    def read(self):
        """Read the current value of the switch."""
        return self._impl.read()

    def wait_for_value(self, value):
        """Wait for the switch to be closed or opened.

        Parameters
        ----------
        value: int
            1 for the switch up and 0 for the switch down

        """
        if (value != 1) or (value != 0):
            raise ValueError("'value' must be 0 or 1.")
        self._impl.wait_for_value(value)


