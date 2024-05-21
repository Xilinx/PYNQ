#   Copyright (c) 2016, Xilinx, Inc.
#   SPDX-License-Identifier: BSD-3-Clause



class Button(object):
    """This class controls the onboard push-buttons.

    Attributes
    ----------
    _impl : object
        An object with appropriate Button methods

    """

    def __init__(self, device):
        """Create a new Button object.

        Parameters
        ----------
        device : object
            An object with appropriate Button methods:
            read, wait_for_value

        """
        methods = ['read', 'wait_for_value']
        if all(m in dir(device) for m in methods):
            self._impl = device
        else:
            raise TypeError("'device' must contain Button methods: " +
                            str(methods))

    def read(self):
        """Read the current value of the button."""
        return self._impl.read()

    def wait_for_value(self, value):
        """Wait for the button to be pressed or released.

        Parameters
        ----------
        value: int
            1 to wait for press or 0 to wait for release

        """
        if (value != 1) or (value != 0):
            raise ValueError("'value' must be 0 or 1.")
        self._impl.wait_for_value(value)


