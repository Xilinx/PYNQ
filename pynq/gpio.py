#   Copyright (c) 2016-2022, Xilinx, Inc.
#   Copyright (C) 2022-2026 Advanced Micro Devices, Inc.
#   SPDX-License-Identifier: BSD-3-Clause

import os
import warnings
import weakref
from .ps import CPU_ARCH, ZU_ARCH, ZYNQ_ARCH, _is_versal


class _GPIO:
    """Internal Helper class to wrap Linux's GPIO Sysfs API.

    This GPIO class does not handle PL I/O without the use of
    device tree overlays.

    Attributes
    ----------
    index : int
        The index of the GPIO, starting from the GPIO base.
    direction : str
        Input/output direction of the GPIO.
    path: str
        The path of the GPIO device in the linux system.

    """

    def __init__(self, gpio_index, direction):
        """Return a new GPIO object.

        Parameters
        ----------
        gpio_index : int
            The index of the GPIO using Linux's GPIO Sysfs API.
        direction : 'str'
            Input/output direction of the GPIO.

        """
        euid = os.geteuid()
        if euid != 0:
            raise EnvironmentError('Root permissions required.')

        if direction not in ('in', 'out'):
            raise ValueError("Direction should be in or out.")
        self.index = gpio_index
        self.direction = direction
        self.path = '/sys/class/gpio/gpio{}/'.format(gpio_index)

        if not os.path.exists(self.path):
            with open('/sys/class/gpio/export', 'w') as f:
                f.write(str(self.index))

        with open(self.path + 'direction', 'w') as f:
            f.write(self.direction)

    def read(self):
        """The method to read a value from the GPIO.

        Returns
        -------
        int
            An integer read from the GPIO

        """
        if self.direction != 'in':
            raise AttributeError("Cannot read GPIO output.")

        with open(self.path + 'value', 'r') as f:
            return int(f.read())

    def write(self, value):
        """The method to write a value into the GPIO.

        Parameters
        ----------
        value : int
            An integer value, either 0 or 1

        Returns
        -------
        None

        """
        if self.direction != 'out':
            raise AttributeError("Cannot write GPIO input.")

        if value not in (0, 1):
            raise ValueError("Can only write integer 0 or 1.")

        with open(self.path + 'value', 'w') as f:
            f.write(str(value))
        return

    def unexport(self):
        """The method to unexport the GPIO using Linux's GPIO Sysfs API.

        Returns
        -------
        None

        """
        if os.path.exists(self.path):
            with open('/sys/class/gpio/unexport', 'w') as f:
                f.write(str(self.index))

    def is_exported(self):
        """The method to check if a GPIO is still exported using
        Linux's GPIO Sysfs API.

        Returns
        -------
        bool
            True if the GPIO is still loaded.

        """
        return os.path.exists(self.path)

_gpio_map = weakref.WeakValueDictionary()

def _resolve_gpio_backend(device=None):
    """Select the GPIO implementation, allowing local access without a device."""
    if device is None:
        from .pl_server.device import Device
        if hasattr(Device, "_active_device") or Device.devices:
            device = Device.active_device
    return device, getattr(device, "_gpio_class", GPIO)


class GPIO:
    """Class to wrap Linux's GPIO Sysfs API.

    This GPIO class does not handle PL I/O without the use of device tree
    overlays.

    Attributes
    ----------
    index : int
        The index of the GPIO, starting from the GPIO base.
    direction : str
        Input/output direction of the GPIO.
    path: str
        The path of the GPIO device in the linux system.

    """

    if _is_versal():
        _GPIO_MIN_USER_PIN = {'versal_gpio': 26, 'pmc_gpio': 52}
    elif CPU_ARCH == ZYNQ_ARCH:
        _GPIO_MIN_USER_PIN = 54
    elif CPU_ARCH == ZU_ARCH:
        _GPIO_MIN_USER_PIN = 78
    else:
        warnings.warn("Pynq does not support the CPU Architecture: {}"
                      .format(CPU_ARCH), ResourceWarning)


    def __init__(self, gpio_index, direction, device=None):
        """Return a new GPIO object.

        Parameters
        ----------
        gpio_index : int
            The index of the GPIO using Linux's GPIO Sysfs API.
        direction : 'str'
            Input/output direction of the GPIO.
        device : Device
            Target device. Defaults to the active device.

        """
        self.device, backend = _resolve_gpio_backend(device)
        if backend is not GPIO:
            # The same GPIO number on different boards must use separate handles.
            if not hasattr(self.device, "_gpio_map"):
                self.device._gpio_map = weakref.WeakValueDictionary()
            cache = self.device._gpio_map
            impl = cache.get(gpio_index)
            if impl is not None and impl.is_exported():
                if impl.direction != direction:
                    raise AttributeError("GPIO already in use in other direction")
            else:
                impl = backend(gpio_index, direction, device=self.device)
                cache[gpio_index] = impl
            self._impl = impl
            return
        self._impl = None
        if gpio_index in _gpio_map:
            self._impl = _gpio_map[gpio_index]
            if self._impl and self._impl.is_exported() and \
               self._impl.direction != direction:
                raise AttributeError("GPIO already in use in other direction")

        if not self._impl or not self._impl.is_exported():
            self._impl = _GPIO(gpio_index, direction)
            _gpio_map[gpio_index] = self._impl

    @property
    def index(self):
        return self._impl.index

    @property
    def direction(self):
        return self._impl.direction

    @property
    def path(self):
        return self._impl.path

    def read(self):
        """The method to read a value from the GPIO.

        Returns
        -------
        int
            An integer read from the GPIO

        """
        return self._impl.read()

    def write(self, value):
        """The method to write a value into the GPIO.

        Parameters
        ----------
        value : int
            An integer value, either 0 or 1

        Returns
        -------
        None

        """
        self._impl.write(value)

    def release(self):
        """The method to release the GPIO.

        Returns
        -------
        None

        """
        self._impl.unexport()
        del self._impl


    @staticmethod
    def get_gpio_base_path(target_label=None, device=None):
        """This method returns the path to the GPIO base using Linux's
        GPIO Sysfs API.

        This is a static method. To use:

        >>> from pynq import GPIO

        >>> gpio = GPIO.get_gpio_base_path()

        Parameters
        ----------
        target_label : str
            The label of the GPIO driver to look for, as defined in a
            device tree entry.

        Returns
        -------
        str
            The path to the GPIO base.

        """
        device, backend = _resolve_gpio_backend(device)
        if backend is not GPIO:
            return backend.get_gpio_base_path(target_label=target_label, device=device)
        if target_label is None and _is_versal():
            raise ValueError(
                "target_label must be specified on Versal; use "
                "'versal_gpio' or 'pmc_gpio'."
            )

        valid_labels = []
        if target_label is not None:
            valid_labels.append(target_label)
        else:
            valid_labels.append('zynqmp_gpio')
            valid_labels.append('zynq_gpio')

        for root, dirs, files in os.walk('/sys/class/gpio'):
            for name in dirs:
                if 'gpiochip' in name:
                    with open(os.path.join(root, name, "label")) as fd:
                        label = fd.read().rstrip()
                    if label in valid_labels:
                        return os.path.join(root, name)

    @staticmethod
    def get_gpio_base(target_label=None, device=None):
        """This method returns the GPIO base using Linux's GPIO Sysfs API.

        This is a static method. To use:

        >>> from pynq import GPIO

        >>> gpio = GPIO.get_gpio_base()

        Note
        ----
        For path '/sys/class/gpio/gpiochip138/', this method returns 138.

        Parameters
        ----------
        target_label : str
            The label of the GPIO driver to look for, as defined in a
            device tree entry.

        Returns
        -------
        int
            The GPIO index of the base.

        """
        base_path = GPIO.get_gpio_base_path(target_label, device=device)
        if base_path is not None:
            return int(''.join(x for x in base_path if x.isdigit()))

    @staticmethod
    def get_gpio_pin(gpio_user_index, target_label=None, device=None):
        """This method returns a GPIO instance for PS GPIO pins.

        Users only need to specify an index starting from 0; this static
        method will map this index to the correct Linux GPIO pin number.

        Note
        ----
        The GPIO pin number can be calculated using:
        GPIO pin number = GPIO base + GPIO offset + user index
        e.g. The GPIO base is 138, and pin 54 is the base GPIO offset.
        Then the Linux GPIO pin would be (138 + 54 + 0) = 192.

        Parameters
        ----------
        gpio_user_index : int
            The index specified by users, starting from 0.
        target_label : str
            The label of the GPIO driver to look for, as defined in a
            device tree entry.
        device : Device
            Target device. Defaults to the active device.

        Returns
        -------
        int
            The Linux Sysfs GPIO pin number.

        """
        device, backend = _resolve_gpio_backend(device)
        if backend is not GPIO:
            return backend.get_gpio_pin(
                gpio_user_index, target_label=target_label, device=device
            )
        if _is_versal():
            if target_label not in GPIO._GPIO_MIN_USER_PIN:
                raise ValueError(
                    "target_label must be specified on Versal; use "
                    "'versal_gpio' or 'pmc_gpio'."
                )
            GPIO_OFFSET = GPIO._GPIO_MIN_USER_PIN[target_label]
        elif target_label is not None:
            GPIO_OFFSET = 0
        else:
            GPIO_OFFSET = GPIO._GPIO_MIN_USER_PIN

        return (GPIO.get_gpio_base(target_label, device=device) + GPIO_OFFSET +
                gpio_user_index)

    @staticmethod
    def get_gpio_npins(target_label=None, device=None):
        """This method returns the number of GPIO pins for the GPIO base
        using Linux's GPIO Sysfs API.

        This is a static method. To use:

        >>> from pynq import GPIO

        >>> gpio = GPIO.get_gpio_npins()

        Parameters
        ----------
        target_label : str
            The label of the GPIO driver to look for, as defined in a
            device tree entry.

        Returns
        -------
        int
            The number of GPIO pins for the GPIO base.

        """
        device, backend = _resolve_gpio_backend(device)
        if backend is not GPIO:
            return backend.get_gpio_npins(target_label=target_label, device=device)
        base_path = GPIO.get_gpio_base_path(target_label, device=device)
        if base_path is not None:
            with open(os.path.join(base_path, "ngpio")) as fd:
                ngpio = fd.read().rstrip()
            return int(''.join(x for x in ngpio if x.isdigit()))

