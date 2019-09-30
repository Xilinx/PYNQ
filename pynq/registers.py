#   Copyright (c) 2019, Xilinx, Inc.
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

import functools
import textwrap
import numpy as np
import re
import warnings

__author__ = "Peter Ogden, Yun Rock Qu"
__copyright__ = "Copyright 2019, Xilinx"
__email__ = "pynq_support@xilinx.com"


def _wrap_docstring(doc):
    """Helper function to wrap a docstring at 72 characters while
    maintaining line breaks.

    """
    return "\n".join(
        ["\n".join(textwrap.wrap(l, subsequent_indent="    "))
         for l in doc.split('\n') if l])


def _safe_attrname(name):
    if name[0].isdigit():
        name = "r" + name
    return re.sub(r'[^a-zA-Z0-9_]', '_', name)


class Register:
    """Register class that allows users to access registers easily.

    This class supports register slicing, which makes the access to register
    values much more easily. Users can either use +1 or -1 as the step when
    slicing the register. By default, the slice starts from MSB to LSB, which
    is consistent with the common hardware design practice.

    For example, the following slices are acceptable:
    reg[31:13] (commonly used), reg[:], reg[3::], reg[:20:], reg[1:3], etc.

    Note
    ----
    The slicing endpoints are closed, meaning both of the 2 endpoints will
    be included in the final returned value. For example, reg[31:0] will
    return a 32-bit value; this is consistent with most of the hardware
    definitions.

    Attributes
    ----------
    address : int
        The address of the register.
    width : int
        The width of the register, e.g., 32 (default) or 64.

    """

    def __init__(self, address, width=32, debug=False, buffer=None):
        """Instantiate a register object.

        Parameters
        ----------
        address : int
            The address of the register.
        width : int
            The width of the register, e.g., 32 (default) or 64.
        debug : bool
            Turn on debug mode if True; default is False.
        buffer : Buffer
            Buffer object to use for reading and writing the value
            of the register. If None the address is assumed to be
            an absolute physical address

        """

        self.address = address
        self.width = width
        self.debug = debug

        if width == 32:
            register_type = 'u4'
        elif width == 64:
            register_type = 'u8'
        else:
            raise ValueError("Supported register width is 32 or 64.")

        if buffer is None:
            from .mmio import MMIO
            array = MMIO(address, np.dtype(register_type).itemsize).array
        elif hasattr(buffer, 'view'):
            array = buffer
        else:
            array = np.frombuffer(buffer, register_type, count=1)

        self._buffer = array.view(dtype=register_type)

    def __getitem__(self, index):
        """Get the register value.

        This method accepts both integer index, or slice as input parameters.

        Parameters
        ----------
        index : int | slice
            The integer index, or slice to access the register value.

        """

        curr_val = self._buffer[0]
        if isinstance(index, int):
            self._debug("Reading index {} at address {}"
                        .format(index, hex(self.address)))
            mask = 1 << index
            return (curr_val & mask) >> index
        elif isinstance(index, slice):
            start, stop, step = index.start, index.stop, index.step
            self._debug("Reading bits {}:{} at address {}"
                        .format(start, stop, hex(self.address)))
            if step is None or step == -1:
                if start is None:
                    start = self.width - 1
                if stop is None:
                    stop = 0
            elif step == 1:
                if start is None:
                    start = 0
                if stop is None:
                    stop = self.width - 1
            else:
                raise ValueError("Slicing step is not valid.")
            if start not in range(self.width):
                raise ValueError("Slice endpoint {0} not in range "
                                 "0 - {1}".format(start, self.width))
            if stop not in range(self.width):
                raise ValueError("Slicing endpoint {0} not in range "
                                 "0 - {1}".format(stop, self.width))

            if start >= stop:
                mask = ((1 << (start - stop + 1)) - 1) << stop
                return int((curr_val & mask) >> stop)
            else:
                width = stop - start + 1
                mask = ((1 << width) - 1) << start
                reg_val = (curr_val & mask) >> start
                return int('{:0{width}b}'.format(reg_val,
                                                 width=width)[::-1], 2)
        else:
            raise ValueError("Index must be int or slice.")

    def __setitem__(self, index, value):
        """Set the register value.

        This method accepts both integer index, or slice as input parameters.

        Parameters
        ----------
        index : int | slice
            The integer index, or slice to access the register value.

        """

        curr_val = self._buffer[0]
        if isinstance(index, int):
            if value != 0 and value != 1:
                raise ValueError("Value to be set should be either 0 or 1.")
            self._debug("Setting bit {} at address {} to {}"
                        .format(index, hex(self.address), value))
            mask = 1 << index
            self._buffer[0] = (curr_val & ~mask) | (value << index)
        elif isinstance(index, slice):
            count = self.count(index, width=self.width)
            start, stop, step = index.start, index.stop, index.step
            if step is None or step == -1:
                if start is None:
                    start = self.width - 1
                if stop is None:
                    stop = 0
            elif step == 1:
                if start is None:
                    start = 0
                if stop is None:
                    stop = self.width - 1
            else:
                raise ValueError("Slicing step is not valid.")
            if start not in range(self.width):
                raise ValueError("Slicing endpoint {} is not in range 0 - {}."
                                 .format(start, self.width))
            if stop not in range(self.width):
                raise ValueError("Slicing endpoint {} is not in range 0 - {}."
                                 .format(stop, self.width))
            if value not in range(1 << count):
                raise ValueError("Slicing range cannot represent value {}"
                                 .format(value))

            shift = stop if start >= stop else start
            mask = ((1 << count) - 1) << shift
            self._debug("Setting bits {}:{} at address {} to {}".format(
                count + shift, shift, hex(self.address), value))
            self._buffer[0] = (curr_val & ~mask) | (value << shift)
        else:
            raise ValueError("Index must be int or slice.")

    def _reordered_setitem(self, value, index):
        """Wrapped version of __setitem__ for better use with
        functools.partial

        """
        return self.__setitem__(index, value)

    def __str__(self):
        """Print the register value.

        This method is overloaded to print the register value. The output
        is a string in hex format.

        """

        return hex(self[:])

    def _debug(self, s, *args):
        """The method provides debug capabilities for this class.

        Parameters
        ----------
        s : str
            The debug information format string
        *args : any
            The arguments to be formatted
        Returns
        -------
        None

        """
        if self.debug:
            print('Register Debug: {0}'.format(s.format(*args)))

    def __repr__(self):
        """Print a representation of the Register and all its fields

        If the Register has been subclassed with fields then these
        will be printed otherwise the return string will contain the
        value of the entire register

        """
        if hasattr(self, '_fields') and self._fields:
            field_desc = []
            for k in self._fields.keys():
                field_desc.append("{}={}".format(k, getattr(self, k)))
            return "Register({})".format(", ".join(field_desc))
        else:
            return "Register(value={})".format(self[:])

    def __int__(self):
        """Return an integer of the value of the register

        """
        return self[:]

    def __index__(self):
        """Return an index containing the value of the register

        """
        return self[:]

    @classmethod
    def create_subclass(cls, name, fields, doc=None):
        """Create a subclass of Register that has properties for the
        specified fields

        The fields should be in the form used by `ip_dict`, namely::

            {name: {'access': "read-only" | "read-write" | "write-only",
                    'bit_offset': int, 'bit_width': int, 'description': str}}

        Parameters
        ----------
        name : str
            A suffix for the name of the subclass
        fields : dict
            A Dictionary containing the fields to add to the subclass

        """
        attr_dict = {}
        safe_fields = {}
        attr_dict['_fields'] = safe_fields
        if doc:
            attr_dict['__doc__'] = doc
        name = _safe_attrname(name)
        for k, v in fields.items():
            attrname = _safe_attrname(k)
            safe_fields[attrname] = v
            doc = _wrap_docstring(v['description'])
            stop = v['bit_offset']
            start = stop + v['bit_width'] - 1
            index = slice(start, stop, -1)
            if v['access'] == 'read-only':
                attr_dict[attrname] = property(
                    functools.partial(Register.__getitem__, index=index),
                    doc=doc)
            else:
                attr_dict[attrname] = property(
                    functools.partial(Register.__getitem__, index=index),
                    functools.partial(Register._reordered_setitem, index=index),
                    doc=doc)
        return type("Register" + name, (Register,), attr_dict)

    @classmethod
    def count(cls, index, width=32):
        """Provide the number of bits accessed by an index or slice

        This method accepts both integer index, or slice as input parameters.

        Parameters
        ----------
        index : int | slice
            The integer index, or slice to access the register value.
        width : int
            The number of bits accessed.

        """

        if isinstance(index, int):
            return 1
        elif isinstance(index, slice):
            start, stop, step = index.start, index.stop, index.step
            if step is None or step == -1:
                if start is None:
                    start = width - 1
                if stop is None:
                    stop = 0
            elif step == 1:
                if start is None:
                    start = 0
                if stop is None:
                    stop = width - 1
            else:
                raise ValueError("Slicing step is not valid.")
            if start not in range(width):
                raise ValueError("Slicing endpoint {} is not in range(0,{})."
                                 .format(start, self.width))
            if stop not in range(width):
                raise ValueError("Slicing endpoint {} is not in range(, {})."
                                 .format(stop, self.width))

            if start >= stop:
                count = start - stop + 1
            else:
                count = stop - start + 1
            return count


class RegisterMap:
    """Provides access to a named register map.

    This class is designed to be subclassed using the
    `create_subclass` method which will create a class with
    properties for all of the registers in a specific map.

    See the `create_subclass` function for more details.

    """

    def __init__(self, buffer):
        """Create a new instance of the RegisterMap

        Parameters
        ----------
        buffer : buffer-like
            A Python buffer object to bind the register map to

        """
        if not hasattr(self, '_map_size'):
            raise RuntimeError("Only subclasses of RegisterMap from " +
                               "create_subclass can be instantiated")
        if hasattr(buffer, 'view'):
            array32 = buffer.view(dtype='u4')
            array64 = buffer.view(dtype='u8')
        else:
            array32 = np.frombuffer(buffer=buffer, dtype=np.uint32,
                                    count=self._map_size // 4)
            array64 = np.frombuffer(buffer=buffer, dtype=np.uint64,
                                    count=self._map_size // 8)
        self._instances = {}
        for k, v in self._register_classes.items():
            if v[2] <= 32:
                index = v[1] // 4
                array = array32[index:index+1]
                align_width = 32
            elif v[2] <= 64:
                index = v[1] // 4
                array = array32[index:index+2]
                align_width = 64
            else:
                warnings.warn(
                    "Unsupported register size {} for register {}".format(
                        v[2], k
                    ))
                continue
            self._instances[k] = v[0](
                address=v[1], width=align_width, buffer=array)

    def _set_value(self, value, name):
        self._instances[name][:] = value

    def _get_value(self, name):
        return self._instances[name]

    def __repr__(self):
        register_info = []
        for k, v in self._instances.items():
            register_info.append(
                "  {} = {}".format(k, repr(v)))
        return "RegisterMap {\n" + ",\n".join(register_info) + "\n}"

    @classmethod
    def create_subclass(cls, name, registers):
        """Create a new RegisterMap subclass with the specified registers

        The dictionary should have the same form as the "registers" entry in
        the ip_dict. For example::

             {name : {"address_offset" : int,
                      "access" : "read-only" | "write-only" | "read-write",
                      "size" : int,
                      "description" : str,
                      "fields" : dict}}

        For details on the contents of the "fields" entry see the `Register`
        class documentation.

        Parameters
        ----------
        name : str
            Suffix to append to "RegisterMap" to make the name of the new class
        registers : dict
            Dictionary of the registers to create in the subclass

        """
        attr_dict = {}
        register_classes = {}
        address_high = 0
        name = _safe_attrname(name)
        for k, v in registers.items():
            attrname = _safe_attrname(k)
            doc = _wrap_docstring(v['description'])
            if 'fields' in v:
                register_class = Register.create_subclass(
                        attrname, v['fields'], doc)
            else:
                register_class = Register
            register_classes[attrname] = (
                register_class, v['address_offset'], v['size'])
            upper_range = v['address_offset'] + v['size'] // 8
            if upper_range > address_high:
                address_high = upper_range
            if v['access'] == 'read-only':
                attr_dict[attrname] = property(
                    functools.partial(RegisterMap._get_value, name=attrname),
                    doc=doc
                )
            else:
                attr_dict[attrname] = property(
                    functools.partial(RegisterMap._get_value, name=attrname),
                    functools.partial(RegisterMap._set_value, name=attrname),
                    doc=doc
                )
        attr_dict['_register_classes'] = register_classes
        attr_dict['_map_size'] = address_high
        return type("RegisterMap" + name, (RegisterMap,), attr_dict)
