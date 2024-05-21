#   Copyright (c) 2016, Xilinx, Inc.
#   SPDX-License-Identifier: BSD-3-Clause



class LED(object):
    """This class controls the onboard leds.

    Attributes
    ----------
    _impl : object
        An object with appropriate LED methods

    """

    def __init__(self, device):
        """Create a new LED object.
        
        Parameters
        ----------
        device : object
            An object with appropriate LED methods:
            on, off, toggle and len

        """
        methods = ['on', 'off', 'toggle']
        if all(m in dir(device) for m in methods):
            self._impl = device
        else:
            raise TypeError("'device' must contain LED methods: " +
                            str(methods))

    def toggle(self):
        """Toggle led on/off."""
        self._impl.toggle()

    def on(self):
        """Turn on led."""
        self._impl.on()

    def off(self):
        """Turn off led."""
        self._impl.off()




