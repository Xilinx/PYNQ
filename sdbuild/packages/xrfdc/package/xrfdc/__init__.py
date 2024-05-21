#   Copyright (c) 2018, Xilinx, Inc.
#   SPDX-License-Identifier: BSD-3-Clause


import cffi
import os
import pynq
import warnings
from wurlitzer import pipes




_THIS_DIR = os.path.dirname(__file__)

with open(os.path.join(_THIS_DIR, 'xrfdc_functions.c'), 'r') as f:
    header_text = f.read()

_ffi = cffi.FFI()
_ffi.cdef(header_text)

_lib = _ffi.dlopen(os.path.join(_THIS_DIR, 'libxrfdc.so'))


# Next stage is a simple wrapper function which checks the existance of the
# function in the library and the return code and throws an exception if either
# fails.

def _safe_wrapper(name, *args, **kwargs):
    with pipes() as (c1, c2):
        if not hasattr(_lib, name):
            raise RuntimeError(f"Function {name} not in library")
        ret = getattr(_lib, name)(*args, **kwargs)
    if ret:
        message = f"Function {name} call failed"
        stdout = c1.read()
        stderr = c2.read()
        if stdout:
            message += f"\nstdout: {stdout}"
        if stderr:
            message += f"\nstderr: {stderr}"
        raise RuntimeError(message)


# To reduce the amount of typing we define the properties we want for each
# class in the hierarchy. Each element of the array is a tuple consisting of
# the property name, the type of the property, whether or not it is
# read-only, whether or not it is write-only, whether or not it is an implicit read,
# and whether or not it is an implicit write. These should match the specification 
# of the C API but without the `XRFdc_` prefix in the case of the function name.

#    Name                 , C Type                      , RO   , WO   , ImpR , ImpW
_block_props = [
    ("BlockStatus"        , "XRFdc_BlockStatus"         , True                      ),
    ("MixerSettings"      , "XRFdc_Mixer_Settings"      , False                     ),
    ("QMCSettings"        , "XRFdc_QMC_Settings"        , False                     ),
    ("CoarseDelaySettings", "XRFdc_CoarseDelay_Settings", False                     ),
    ("NyquistZone"        , "u32"                       , False                     ),
    ("EnabledInterrupts"  , "u32"                       , True                      ),
    ("PwrMode"            , "XRFdc_Pwr_Mode_Settings"   , False                     )
]

_adc_props = [
    ("DecimationFactor"   , "u32"                       , False, False, True , True ),
    ("CalibrationMode"    , "u8"                        , False, False, True , True ),
    ("FabRdVldWords"      , "u32"                       , False, False, False, True ),
    ("FabWrVldWords"      , "u32"                       , True , False, False, False),
    ("DecimationFactorObs", "u32"                       , False, False, True , True ),
    ("FabRdVldWordsObs"   , "u32"                       , False, False, False, True ),
    ("FabWrVldWordsObs"   , "u32"                       , True , False, False, False),
    ("Dither"             , "u32"                       , False, False, True , True ),
    ("CalFreeze"          , "XRFdc_Cal_Freeze_Settings" , False, False, True , True ),
    ("DSA"                , "XRFdc_DSA_Settings"        , False, False, True , True )
]

_dac_props = [
    ("InterpolationFactor", "u32"                       , False, False, True , True ),
    ("DecoderMode"        , "u32"                       , False, False, True , True ),
    ("OutputCurr"         , "int"                       , True , False, True , True ),
    ("InvSincFIR"         , "u16"                       , False, False, True , True ),
    ("FabRdVldWords"      , "u32"                       , True , False, False, False),
    ("FabWrVldWords"      , "u32"                       , False, False, False, True ),
    ("DataPathMode"       , "u32"                       , False, False, True , True ),
    ("IMRPassMode"        , "u32"                       , False, False, True , True ),
    ("DACCompMode"        , "u32"                       , False, False, True , True )
]

_tile_props = [
    ("FabClkOutDiv"       , "u16"                       , False                     ),
    ("FIFOStatus"         , "u8"                        , True                      ),
    ("ClockSource"        , "u32"                       , True                      ),
    ("PLLLockStatus"      , "u32"                       , True                      ),
    ("PLLConfig"          , "XRFdc_PLL_Settings"        , True                      )
]

_rfdc_props = [
    ("IPStatus"           , "XRFdc_IPStatus"             , True                      ),
    ("ClkDistribution"    , "XRFdc_Distribution_Settings", False                     )
]

# Next we define some helper functions for creating properties and
# packing/unpacking Python types into C structures

class PropertyDict(dict):
    """Subclass of dict to support update callbacks to C driver"""
    def __init__(self, *args, **kwargs):
        self.callback = lambda _:0
        self.update(*args, **kwargs)

    def set_callback(self, callback):
        """Set the callback function triggered on __setitem__""" 
        self.callback = callback

    def __setitem__(self, key, val):
        dict.__setitem__(self, key, val)
        self.callback(self)

    def update(self, *args, **kwargs):
        dict.update(self, *args, **kwargs)
        self.callback(self)


def _pack_value(typename, value):
    if isinstance(value, dict):
        c_value = _ffi.new(f"{typename}*")
        for k, v in value.items():
            setattr(c_value, k, v)
        value = c_value
    return value


def _unpack_value(value):
    
    # Guard against python primitives
    if type(value) in [int,str,bool]:
        return value

    ctype = _ffi.typeof(value)

    # Dereference pointers
    if ctype.kind == 'pointer':
        return _unpack_value(value[0])

    # Struct -> Dict
    elif ctype.kind == 'struct':
        return PropertyDict({
            k: _unpack_value(getattr(value, k)) if ktype.type.kind != 'primitive' else \
                             getattr(value, k)
            for (k,ktype) in ctype.fields
        })

    # Array -> List
    elif ctype.kind == 'array':
        return [
            _unpack_value(value[i]) if ctype.item.kind != 'primitive' else \
                          value[i]
            for i in range(ctype.length)
        ]

    # C primitive
    else:
        return value[0]

# The underlying C functions for generic behaviour (applies to both DAC
# and ADC blocks) expect an argument for the type of block used.
# Other functions leave the type of block implicit. We handle this distinction
# by bubbling up through either `_call_function` or `_call_function_implicit`
# calls. 


def _create_c_property(name, typename, readonly, writeonly=False, implicit_read=False, implicit_write=False):
    def _get(self):
        value = _ffi.new(f"{typename}*")
        c_func = self._call_function if not implicit_read else \
            self._call_function_implicit
        c_func(f"Get{name}", value)
        value = _unpack_value(value)
        if isinstance(value, PropertyDict):
            value.set_callback(lambda value: c_func(
                f"Set{name}", _pack_value(typename, value)))
        return value

    def _set(self, value):
        if not implicit_write:
            self._call_function(f"Set{name}", _pack_value(typename, value))
        else:
            self._call_function_implicit(f"Set{name}", _pack_value(typename, value))

    if readonly:
        return property(_get)
    elif writeonly:
        return property(_set)
    else:
        return property(_get, _set)

# Finally we can define the object hierarchy. Each element of the object
# hierarchy has a `_call_function` method which handles adding the
# block/tile/toplevel arguments to the list of function parameters.

class RFdcThreshold:
    def __init__(self, parent, index):
        self._parent = parent
        self._index = index

        self._call_function = parent._call_function
        self._call_function_implicit = parent._call_function_implicit
        setattr(RFdcThreshold, '_settings',
                _create_c_property('ThresholdSettings', 'XRFdc_Threshold_Settings',
                False, False, True, True
        ))


    def SetClrMode(self, clr_mode):
        self._parent._call_function_implicit("SetThresholdClrMode", self._index+1, clr_mode)

    def StickyClear(self):
        self._parent._call_function_implicit("ThresholdStickyClear", self._index+1)

    @property
    def Settings(self):
        raw_settings = self._settings
        return {
            'ThresholdMode'    : raw_settings['ThresholdMode'    ][self._index],
            'ThresholdAvgVal'  : raw_settings['ThresholdAvgVal'  ][self._index],
            'ThresholdUnderVal': raw_settings['ThresholdUnderVal'][self._index],
            'ThresholdOverVal' : raw_settings['ThresholdOverVal' ][self._index]
        }

    @Settings.setter
    def Settings(self, settings):
        kpack = lambda x, i : [x,0] if i==0 else [0,x]
        self._settings = {
            'UpdateThreshold'  : self._index+1,
            'ThresholdMode'    : kpack(settings['ThresholdMode'    ], self._index),
            'ThresholdAvgVal'  : kpack(settings['ThresholdAvgVal'  ], self._index),
            'ThresholdUnderVal': kpack(settings['ThresholdUnderVal'], self._index),
            'ThresholdOverVal' : kpack(settings['ThresholdOverVal' ], self._index)
        }


class RFdcBlock:
    def __init__(self, parent, index):
        self._parent = parent
        self._index = index

    def _call_function(self, name, *args):
        return self._parent._call_function(name, self._index, *args)
    
    def ResetNCOPhase(self):
        self._call_function("ResetNCOPhase")

    def UpdateEvent(self, Event):
        self._call_function("UpdateEvent", Event)
        
    def ResetInternalFIFOWidth(self):
        self._call_function("ResetInternalFIFOWidth")
        
    def GetConnectedIData(self):
        self._call_function("GetConnectedIData")
        
    def GetConnectedQData(self):
        self._call_function("GetConnectedQData")


class RFdcDacBlock(RFdcBlock):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)

    def _call_function_implicit(self, name, *args):
        return self._parent._call_function_implicit(name, self._index, *args)
    
    def SetDACVOP(self, uACurrent):
        self._call_function_implicit("SetDACVOP", uACurrent)


class RFdcAdcBlock(RFdcBlock):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        self.thresholds = [RFdcThreshold(self, i) for i in range(2)]

    def _call_function_implicit(self, name, *args):
        return self._parent._call_function_implicit(name, self._index, *args)
        
    def DisableCoefficientsOverride(self, CalibrationBlock):
        self._call_function_implicit("DisableCoefficientsOverride", CalibrationBlock)
        
    def ResetInternalFIFOWidthObs(self):
        self._call_function("ResetInternalFIFOWidthObs")
        
    def SetCalCoefficients(self, CalibrationBlock, *CoeffPtr):
        self._call_function_implicit("SetCalCoefficients", CalibrationBlock, *CoeffPtr)
        
    def GetCalCoefficients(self, CalibrationBlock, *CoeffPtr):
        self._call_function_implicit("GetCalCoefficients", CalibrationBlock, *CoeffPtr)



class RFdcTile:
    def __init__(self, parent, index):
        self._index = index
        self._parent = parent

    def _call_function(self, name, *args):
        return self._parent._call_function(name, self._type, self._index, *args)

    def _call_function_implicit(self, name, *args):
        return self._parent._call_function(name, self._index, *args)

    def StartUp(self):
        self._call_function("StartUp")

    def ShutDown(self):
        self._call_function("Shutdown")

    def Reset(self):
        self._call_function("Reset")
    
    def SetupFIFO(self, Enable):
        self._call_function("SetupFIFO", Enable)

    def DumpRegs(self):
        self._call_function("DumpRegs")

    def DynamicPLLConfig(self, source, ref_clk_freq, samp_rate):
        self._call_function("DynamicPLLConfig", source, ref_clk_freq, samp_rate)


class RFdcDacTile(RFdcTile):
    def __init__(self, *args):
        super().__init__(*args)
        self._type = _lib.XRFDC_DAC_TILE
        self.blocks = [RFdcDacBlock(self, i) for i in range(4)]


class RFdcAdcTile(RFdcTile):
    def __init__(self, *args):
        super().__init__(*args)
        self._type = _lib.XRFDC_ADC_TILE
        self.blocks = [RFdcAdcBlock(self, i) for i in range(4)]
        
    def SetupFIFOObs(self, Enable):
        self._call_function("SetupFIFOObs", Enable)
        
    def SetupFIFOBoth(self, Enable):
        self._call_function("SetupFIFOBoth", Enable)
        
    def GetFIFOStatusObs(self, *EnablePtr):
        self._call_function("GetFIFOStatusObs", *EnablePtr)


class RFdc(pynq.DefaultIP):
    """The class RFdc is bound to the IP xilinx.com:ip:usp_rf_data_converter:2.3,
    xilinx.com:ip:usp_rf_data_converter:2.4 or xilinx.com:ip:usp_rf_data_converter:2.6.
    Once the overlay is loaded, the data converter IP will be allocated the driver
    code implemented in this class.

    For a complete list of wrapped functions see:
    https://github.com/Xilinx/PYNQ/tree/master/sdbuild/packages/xrfdc/package
    """
    
    bindto = ["xilinx.com:ip:usp_rf_data_converter:2.6",
              "xilinx.com:ip:usp_rf_data_converter:2.4", 
              "xilinx.com:ip:usp_rf_data_converter:2.3"]

    def __init__(self, description):
        super().__init__(description)
        if 'parameters' in description:
            from .config import populate_config
            self._config = _ffi.new('XRFdc_Config*')
            populate_config(self._config, description['parameters'])
            pass
        else:
            warnings.warn("Please use an hwh file with the RFSoC driver"
                          " the driver cannot be loaded")
            raise pynq.UnsupportedConfiguration()
        self._instance = _ffi.new("XRFdc*")
        self._config.BaseAddr = self.mmio.array.ctypes.data
        _lib.XRFdc_CfgInitialize(self._instance, self._config)
        self.adc_tiles = [RFdcAdcTile(self, i) for i in range(4)]
        self.dac_tiles = [RFdcDacTile(self, i) for i in range(4)]

    def _call_function(self, name, *args):
        _safe_wrapper(f"XRFdc_{name}", self._instance, *args)


# Finally we can add our data-driven properties to each class in the hierarchy

for (name, typename, readonly) in _block_props:
    setattr(RFdcBlock, name, _create_c_property(name, typename, readonly))

for (name, typename, readonly, writeonly, implicit_read, implicit_write) in _adc_props:
    setattr(RFdcAdcBlock, name, _create_c_property(name, typename, readonly, writeonly,
        implicit_read, implicit_write))

for (name, typename, readonly, writeonly, implicit_read, implicit_write) in _dac_props:
    setattr(RFdcDacBlock, name, _create_c_property(name, typename, readonly, writeonly,
        implicit_read, implicit_write))

for (name, typename, readonly) in _tile_props:
    setattr(RFdcTile, name, _create_c_property(name, typename, readonly))

for (name, typename, readonly) in _rfdc_props:
    setattr(RFdc, name, _create_c_property(name, typename, readonly))

# Some of our more important #define constants
CLK_SRC_PLL = 0x1
CLK_SRC_EXT = 0x2

EVNT_SRC_IMMEDIATE = 0x00000000
EVNT_SRC_SLICE     = 0x00000001
EVNT_SRC_TILE      = 0x00000002
EVNT_SRC_SYSREF    = 0x00000003
EVNT_SRC_MARKER    = 0x00000004
EVNT_SRC_PL        = 0x00000005
EVENT_MIXER        = 0x00000001
EVENT_CRSE_DLY     = 0x00000002
EVENT_QMC          = 0x00000004

MIXER_MODE_OFF = 0x0
MIXER_MODE_C2C = 0x1
MIXER_MODE_C2R = 0x2
MIXER_MODE_R2C = 0x3
MIXER_MODE_R2R = 0x4

MIXER_TYPE_COARSE = 0x1
MIXER_TYPE_FINE   = 0x2
MIXER_TYPE_OFF    = 0x3

COARSE_MIX_OFF                     = 0x0
COARSE_MIX_SAMPLE_FREQ_BY_TWO      = 0x2
COARSE_MIX_SAMPLE_FREQ_BY_FOUR     = 0x4
COARSE_MIX_MIN_SAMPLE_FREQ_BY_FOUR = 0x8
COARSE_MIX_BYPASS                  = 0x10

MIXER_SCALE_AUTO = 0x0
MIXER_SCALE_1P0  = 0x1
MIXER_SCALE_0P7  = 0x2

FAB_CLK_DIV1   = 0x1
FAB_CLK_DIV2   = 0x2
FAB_CLK_DIV4   = 0x3
FAB_CLK_DIV8   = 0x4
FAB_CLK_DIV16  = 0x5

THRESHOLD_CLRMD_MANUAL_CLR = 0x1
THRESHOLD_CLRMD_AUTO_CLR   = 0x2
TRSHD_OFF                  = 0x0
TRSHD_STICKY_OVER          = 0x1
TRSHD_STICKY_UNDER         = 0x2
TRSHD_HYSTERISIS           = 0x3



