#   Copyright (c) 2019, Xilinx, Inc.
#   SPDX-License-Identifier: BSD-3-Clause


import cffi
import os
from enum import Enum
import warnings
import weakref
import parsec as ps
from wurlitzer import sys_pipes
import pynq




_whitespace = ps.regex(r'\s*')
_lexeme = lambda p: p << _whitespace
_lbrace = _lexeme(ps.string('{'))
_rbrace = _lexeme(ps.string('}'))
_separator = _lexeme(ps.regex(r'[ ,]'))
_name = _lexeme(ps.regex(r'[\w]+'))
_num_hex = _lexeme(
    ps.regex(r'0x[0-9a-fA-F]+')).parsecmap(lambda h: int(h, base=16))
_num_int = _lexeme(
    ps.regex(r'-?(0|[1-9][0-9]*)([.][0-9]+)?([eE][+-]?[0-9]+)?')).\
    parsecmap(int)
_num_float = _lexeme(
    ps.regex(r'-?(0|[1-9][0-9]*)([.][0-9]+)?([eE][+-]?[0-9]+)?')).\
    parsecmap(float)
_list_of = lambda elems: _lbrace >> ps.many(elems) << _rbrace
_sep_list_of = lambda elems: _lbrace >> ps.sepBy(elems, _separator) << _rbrace
_param_value = _num_int | _list_of(_num_int)


@ps.generate
def _ldpc_key_value():
    key = yield _name
    val = yield _param_value
    return key, val


@ps.generate
def _ldpc_param():
    param_name = yield _name
    elems = yield _list_of(_ldpc_key_value)
    return param_name, dict(elems)


@ps.generate
def _ldpc_param_table():
    params = yield ps.many(_ldpc_param)
    return dict(params)


_config = [
    ('Standard', 'DRV_STANDARD', _num_int),
    ('Initialization', 'DRV_INITIALIZATION_PARAMS', _sep_list_of(_num_hex)),
]


_code_params = [
    ('ldpc', 'DRV_LDPC_PARAMS', _ldpc_param_table)
]


def _set_params(obj, params, config, *args):
    for c in config:
        setattr(obj, c[0], c[2].parse(params[c[1].format(*args)]))


def populate_params(obj, params):
    """Populates a given SdFec instance with parameters from an HWH file.
    
    Parameters include Basic IP config settings (XSdFec_Config struct), and
    LDPC parameter table (a dict of named XSdFecLdpcParameters)

    Parameters
    ----------
    obj: SdFec
        An instance of SdFec
    params: dict
        Dictionary based on the HWH file snippet.

    """
    obj._config = _ffi.new('XSdFec_Config*')
    obj._code_params = type('', (), {})
    _set_params(obj._config, params, _config)
    _set_params(obj._code_params, params, _code_params)


_c_array_weakkeydict = weakref.WeakKeyDictionary()


def _pack_ldpc_param(param_dict: dict):
    """Returns a cdata XSdFecLdpcParameters version of the given dict"""
    key_lookup = {
        'k': 'K',
        'n': 'N',
        'p': 'PSize',
        'nlayers': 'NLayers',
        'nqc': 'NQC',
        'nmqc': 'NMQC',
        'nm': 'NM',
        'norm_type': 'NormType',
        'no_packing': 'NoPacking',
        'special_qc': 'SpecialQC',
        'no_final_parity': 'NoFinalParity',
        'max_schedule': 'MaxSchedule',
        'sc_table': 'SCTable',
        'la_table': 'LATable',
        'qc_table': 'QCTable',
    }

    # Flush non-struct keys
    sub_dict = {key_lookup[key]: param_dict[key] for key in param_dict
                if key in key_lookup.keys()}
    
    # Pack tables as C arrays
    def to_c_array(lst):
        # Convert scalars to singleton lists
        if not isinstance(lst, list):
            lst = [lst]
        # Copy to C array
        c_arr = _ffi.new('u32[]', len(lst))
        for i, x in enumerate(lst):
            c_arr[i] = x
        return c_arr
    
    for table_key in filter(lambda k: k.endswith('Table'), sub_dict.keys()):
        sub_dict[table_key] = to_c_array(sub_dict[table_key])
    
    c_struct = _pack_value('XSdFecLdpcParameters', sub_dict)
    
    _c_array_weakkeydict[c_struct] = \
        [sub_dict[table_key] for table_key in filter(
            lambda k: k.endswith('Table'), sub_dict.keys())]
    
    return c_struct


# Read in C function declarations
_THIS_DIR = os.path.dirname(__file__)
with open(os.path.join(_THIS_DIR, 'xsdfec_functions.c'), 'r') as f:
    _header_text = f.read()
_ffi = cffi.FFI()
_ffi.cdef(_header_text)
_lib = _ffi.dlopen(os.path.join(_THIS_DIR, 'libxsdfec.so'))


def _safe_wrapper(name: str, *args, check_return: bool = True, **kwargs):
    """Wrapper to call C functions, checking if they exist and their return.

    Parameters
    ----------
    name : str
        C function name
    check_return:
        Flag to treat return value as a status (non-zero is failure)

    Returns
    -------
        C function return value

    """
    with sys_pipes():
        if not hasattr(_lib, name):
            raise RuntimeError(f"Function {name} not in library")
        ret = getattr(_lib, name)(*args, **kwargs)
        if check_return and ret:
            raise RuntimeError(f"Function {name} call failed")
        return ret
    

def _pack_value(typename: str, value: any):
    """Pack a python object as a given C representation
    
    typename: Name of the C type (we can use type introspection
              to detect the Python type)
    value:    Python object to pack
    return:   C value
    """
    if isinstance(value, dict):
        c_value = _ffi.new("{}*".format(typename))
        for k, v in value.items():
            setattr(c_value, k, v)
        value = c_value
    return value


def _unpack_value(typename: str, value: any):
    """Unpack given C data to a Python representation

    Parameters
    ----------
    typename: str
        Name of the C type (we can use type introspection
        to detect the Python type)
    value: list
        C value to unpack

    Returns
    -------
        Python object

    """
    if dir(value):
        return dict({k: getattr(value, k) for k in dir(value)})
    else:
        return value[0]


class SdFec(pynq.DefaultIP):
    """SD FEC driver

    Check https://www.xilinx.com/products/intellectual-property/sd-fec.html
    for more information on the IP itself.

    """
    bindto = ["xilinx.com:ip:sd_fec:1.1"]

    def __init__(self, description: dict):
        """Make an SD FEC instance as described by a HWH file snippet

        """
        super().__init__(description)
        if 'parameters' in description:
            populate_params(self, description['parameters'])
        else:
            warnings.warn("Cannot get parameters from IP description"
                          " so the default configuration will be used.")
            self._config = _lib.XSdFecLookupConfig(0)

        self._instance = _ffi.new("XSdFec*")
        self._config.BaseAddress = self.mmio.array.ctypes.data
        _lib.XSdFecCfgInitialize(self._instance, self._config)

    def _call_function(self, name: str, *args, **kwargs):
        """Helper function to call CFFI functions

        Parameters
        ----------
        name: str
            C function name (without "XSdFec" prefix).

        """
        return _safe_wrapper("XSdFec{}".format(name),
                             self._instance, *args, **kwargs)
    
    def available_ldpc_params(self):
        """List the available LDPC code names.

        """
        return list(self._code_params.ldpc.keys())
    
    def add_ldpc_params(self, code_id: int, sc_offset: int, la_offset: int,
                        qc_offset: int, ldpc_param_name: str):
        """Add a named LDPC code at the given table offsets

        Fpr names of LDPC code to add, you can use available_ldpc_params()
        for valid options.

        Parameters
        ----------
        code_id: int
            Integer ID for new code
        sc_offset: int
            Offset into SC table for new code
        la_offset: int
            Offset into LA table for new code
        qc_offset: int
            Offset into QC table for new code
        ldpc_param_name: str
            Name of LDPC code to add.

        """
        ldpc_c_param = _pack_ldpc_param(self._code_params.ldpc[ldpc_param_name])
        self._call_function('AddLdpcParams',
                            code_id, sc_offset, la_offset, qc_offset,
                            ldpc_c_param)
    
    def set_turbo_params(self, turbo_params: dict):
        """Stub for setting Turbo code parameters

        """
        pass

    def share_table_size(self, ldpc_param_name: str):
        """Helper function to get table sizes of a given LDPC code

        Useful for calculating table offsets when adding new LDPC codes.

        Parameters
        ----------
        ldpc_param_name: str
            Name of LDPC code (see available_ldpc_params() for valid options).

        Returns
        -------
            Dict with SC, LA, and QC table sizes

        """
        sc_size, la_size, qc_size = (_ffi.new('u32*'),
                                     _ffi.new('u32*'), _ffi.new('u32*'))
        _safe_wrapper('XSdFecShareTableSize',
                      _pack_ldpc_param(self._code_params.ldpc[ldpc_param_name]),
                      sc_size, la_size, qc_size)
        return dict(sc_size=_unpack_value('u32*', sc_size),
                    la_size=_unpack_value('u32*', la_size),
                    qc_size=_unpack_value('u32*', qc_size))

    def interrupt_classifier(self):
        """Get interrupt type information
        
        Returns
        -------
            Dict with interrupt type info

        """
        return _unpack_value(
            'XSdFecInterruptClass',
            self._call_function('InterruptClassifier', check_return=False)
        )


class PropAccess(Enum):
    RW = 0
    RO = 1
    WO = 2


_core_props = [
    ("CORE_AXI_WR_PROTECT",           "u32", PropAccess.RW),
    ("CORE_CODE_WR_PROTECT",          "u32", PropAccess.RW),
    ("CORE_ACTIVE",                   "u32", PropAccess.RO),
    ("CORE_AXIS_WIDTH_DIN",           "u32", PropAccess.RW),
    ("CORE_AXIS_WIDTH_DIN_WORDS",     "u32", PropAccess.RW),
    ("CORE_AXIS_WIDTH_DOUT",          "u32", PropAccess.RW),
    ("CORE_AXIS_WIDTH_DOUT_WORDS",    "u32", PropAccess.RW),
    ("CORE_AXIS_WIDTH",               "u32", PropAccess.RW),
    ("CORE_AXIS_ENABLE_CTRL",         "u32", PropAccess.RW),
    ("CORE_AXIS_ENABLE_DIN",          "u32", PropAccess.RW),
    ("CORE_AXIS_ENABLE_DIN_WORDS",    "u32", PropAccess.RW),
    ("CORE_AXIS_ENABLE_STATUS",       "u32", PropAccess.RW),
    ("CORE_AXIS_ENABLE_DOUT",         "u32", PropAccess.RW),
    ("CORE_AXIS_ENABLE_DOUT_WORDS",   "u32", PropAccess.RW),
    ("CORE_AXIS_ENABLE",              "u32", PropAccess.RW),
    ("CORE_ORDER",                    "u32", PropAccess.RW),
    ("CORE_ISR",                      "u32", PropAccess.RW),
    ("CORE_IER",                      "u32", PropAccess.WO),
    ("CORE_IDR",                      "u32", PropAccess.WO),
    ("CORE_IMR",                      "u32", PropAccess.RO),
    ("CORE_ECC_ISR",                  "u32", PropAccess.RW),
    ("CORE_ECC_IER",                  "u32", PropAccess.WO),
    ("CORE_ECC_IDR",                  "u32", PropAccess.WO),
    ("CORE_ECC_IMR",                  "u32", PropAccess.RO),
    ("CORE_BYPASS",                   "u32", PropAccess.RW),
    ("CORE_VERSION",                  "u32", PropAccess.RO),   
    ("TURBO",                         "u32", PropAccess.RW),
    ("TURBO_ALG",                     "u32", PropAccess.RW),
    ("TURBO_SCALE_FACTOR",            "u32", PropAccess.RW),
    
]


class _PropertyDict(dict):
    """Subclass of dict to support update callbacks to C driver.

    """
    def __init__(self, *args, **kwargs):
        self.callback = lambda _: 0
        self.update(*args, **kwargs)

    def set_callback(self, callback):
        """Set the callback function triggered on __setitem__

        """
        self.callback = callback

    def __setitem__(self, key, val):
        dict.__setitem__(self, key, val)
        self.callback(self)


def _create_c_property(name: str, typename: str, access: PropAccess):
    """Create a getter and setter for a register description
    
    name:     Name of register
    typename: Name of C type that represents register value
    access:   Access control of the register (RW/RO/WO)
    return:   Python property for register
    """
    def _get(self):
        value = _safe_wrapper("XSdFecGet_{}".format(name),
                              self._config.BaseAddress, check_return=False)
        if isinstance(value, dict):
            value = _PropertyDict(value)
            value.set_callback(lambda value: c_func(
                "Set{}".format(name), _pack_value(typename, value)))
        return value

    def _set(self, value):
        _safe_wrapper("XSdFecSet_{}".format(name),
                      self._config.BaseAddress, _pack_value(typename, value))

    if access == PropAccess.RO:
        return property(fget=_get)
    elif access == PropAccess.WO:
        return property(fset=_set)
    else:
        return property(_get, _set)


# Attach all registers as properties of SdFec class
for (prop_name, type_name, access) in _core_props:
    setattr(SdFec, prop_name, _create_c_property(prop_name, type_name, access))


# Define a list of all properties that get/set an entire array
_core_array_props = [
    ("LDPC_CODE_REG0",                       508/4, "u32", PropAccess.RW),
    ("LDPC_CODE_REG0_N",                     508/4, "u32", PropAccess.RW),
    ("LDPC_CODE_REG0_K",                     508/4, "u32", PropAccess.RW),
    ("LDPC_CODE_REG1",                       508/4, "u32", PropAccess.RW),
    ("LDPC_CODE_REG1_PSIZE",                 508/4, "u32", PropAccess.RW),
    ("LDPC_CODE_REG1_NO_PACKING",            508/4, "u32", PropAccess.RW),
    ("LDPC_CODE_REG1_NM",                    508/4, "u32", PropAccess.RW),
    ("LDPC_CODE_REG2",                       508/4, "u32", PropAccess.RW),
    ("LDPC_CODE_REG2_NLAYERS",               508/4, "u32", PropAccess.RW),
    ("LDPC_CODE_REG2_NMQC",                  508/4, "u32", PropAccess.RW),
    ("LDPC_CODE_REG2_NORM_TYPE",             508/4, "u32", PropAccess.RW),
    ("LDPC_CODE_REG2_SPECIAL_QC",            508/4, "u32", PropAccess.RW),
    ("LDPC_CODE_REG2_NO_FINAL_PARITY_CHECK", 508/4, "u32", PropAccess.RW),
    ("LDPC_CODE_REG2_MAX_SCHEDULE",          508/4, "u32", PropAccess.RW),
    ("LDPC_CODE_REG3",                       508/4, "u32", PropAccess.RW),
    ("LDPC_CODE_REG3_SC_OFF",                508/4, "u32", PropAccess.RW),
    ("LDPC_CODE_REG3_LA_OFF",                508/4, "u32", PropAccess.RW),
    ("LDPC_CODE_REG3_QC_OFF",                508/4, "u32", PropAccess.RW),
    ("LDPC_SC_TABLE",                        256/4, "u32", PropAccess.RW),
    ("LDPC_LA_TABLE",                       1024/4, "u32", PropAccess.RW),
    ("LDPC_QC_TABLE",                       8192/4, "u32", PropAccess.RW),
]


def _create_c_array_property(name: str, max_length: int,
                             typename: str, access: PropAccess):
    """Create a getter and setter for an array description
    
    name:     Name of array
    length:   Number of elements in array
    typename: Name of C type that represents a single element
    access:   Access control of the register (RW/RO/WO)
    return:   Python property for array
    """
    def _get(self):
        word_offset = 0
        c_array = _ffi.new(typename+"[]", max_length)
        read_length = _safe_wrapper("XSdFecRead_{}".format(name),
                                    self._config.BaseAddress, word_offset,
                                    c_array, max_length, check_return=False)
        return [c_array[i] for i in range(read_length)]

    def _set(self, value):
        word_offset = 0
        c_array = _ffi.new(typename+"[]", len(value))
        for i, e in enumerate(value):
            c_array[i] = e
        _safe_wrapper("XSdFecWrite_{}".format(name),
                      self._config.BaseAddress, word_offset, c_array,
                      len(value), check_return=False)

    if access == PropAccess.RO:
        return property(fget=_get)
    elif access == PropAccess.WO:
        return property(fset=_set)
    else:
        return property(_get, _set)


# Attach all registers as properties of SdFec class
for (prop_name, max_len, type_name, access) in _core_array_props:
    setattr(SdFec, prop_name,
            _create_c_array_property(prop_name+'_Words',
                                     int(max_len), type_name, access))


