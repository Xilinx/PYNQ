#   Copyright (c) 2018, Xilinx, Inc.
#   SPDX-License-Identifier: BSD-3-Clause

"""
Remote gRPC driver for Xilinx RF Data Converter IP.
Mirrors the classic PYNQ xrfdc API using data-driven property generation.
"""

from . import xrfdc_pb2, xrfdc_pb2_grpc
from pynq.overlay import DefaultIP

# ============================================================================
# Constants (matching C driver / classic xrfdc)
# ============================================================================

XRFDC_ADC_TILE = 0
XRFDC_DAC_TILE = 1

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

XRFDC_CAL_BLOCK_OCB1 = 0
XRFDC_CAL_BLOCK_OCB2 = 1
XRFDC_CAL_BLOCK_GCB  = 2
XRFDC_CAL_BLOCK_TSCB = 3


# ============================================================================
# Helpers
# ============================================================================

class PropertyDict(dict):
    """Compatibility dict that triggers callback on updates."""
    def __init__(self, *args, **kwargs):
        self.callback = lambda _: 0
        self.update(*args, **kwargs)

    def set_callback(self, callback):
        self.callback = callback

    def __setitem__(self, key, value):
        dict.__setitem__(self, key, value)
        self.callback(self)

    def update(self, *args, **kwargs):
        dict.update(self, *args, **kwargs)
        self.callback(self)


def _as_property_dict(value, callback=None):
    dct = PropertyDict(value)
    if callback is not None:
        dct.set_callback(callback)
    return dct


class CalCoeffStruct(dict):
    """Dict that also supports attribute access like CFFI struct.
    Supports both cal['coeff0'] and cal.Coeff0.
    """
    def __getattr__(self, name):
        if name.startswith('Coeff'):
            key = name.lower()
            if key in self:
                return self[key]
        raise AttributeError(f"'{type(self).__name__}' object has no attribute '{name}'")


# ============================================================================
# HWH Config parsing (populates protobuf RFdcConfig from HWH parameters)
# ============================================================================

_DAC_ADP = [
    ('block_available', 'C_DAC_Slice{}{}_Enable', 'int'),
    ('inv_sync_enable', 'C_DAC_Invsinc_Ctrl{}{}', 'int'),
    ('mix_mode', 'C_DAC_Mixer_Mode{}{}', 'int'),
    ('decoder_mode', 'C_DAC_Decoder_Mode{}{}', 'int')
]

_DAC_DDP = [
    ('mixer_input_data_type', 'C_DAC_Data_Type{}{}', 'int'),
    ('data_width', 'C_DAC_Data_Width{}{}', 'int'),
    ('interpolation_mode', 'C_DAC_Interpolation_Mode{}{}', 'int'),
    ('mixer_type', 'C_DAC_Mixer_Type{}{}', 'int')
]

_ADC_ADP = [
    ('block_available', 'C_ADC_Slice{}{}_Enable', 'int'),
    ('mix_mode', 'C_ADC_Mixer_Mode{}{}', 'int')
]

_ADC_DDP = [
    ('mixer_input_data_type', 'C_ADC_Data_Type{}{}', 'int'),
    ('data_width', 'C_ADC_Data_Width{}{}', 'int'),
    ('decimation_mode', 'C_ADC_Decimation_Mode{}{}', 'int'),
    ('mixer_type', 'C_ADC_Mixer_Type{}{}', 'int')
]

_DAC_Tile = [
    ('enable', 'C_DAC{}_Enable', 'int'),
    ('pll_enable', 'C_DAC{}_PLL_Enable', 'int'),
    ('sampling_rate', 'C_DAC{}_Sampling_Rate', 'double'),
    ('ref_clk_freq', 'C_DAC{}_Refclk_Freq', 'double'),
    ('fab_clk_freq', 'C_DAC{}_Fabric_Freq', 'double'),
    ('feedback_div', 'C_DAC{}_FBDIV', 'int'),
    ('output_div', 'C_DAC{}_OutDiv', 'int'),
    ('ref_clk_div', 'C_DAC{}_Refclk_Div', 'int'),
    ('multiband_config', 'C_DAC{}_Band', 'int'),
    ('max_sample_rate', 'C_DAC{}_Fs_Max', 'double'),
    ('num_slices', 'C_DAC{}_Slices', 'int')
]

_ADC_Tile = [
    ('enable', 'C_ADC{}_Enable', 'int'),
    ('pll_enable', 'C_ADC{}_PLL_Enable', 'int'),
    ('sampling_rate', 'C_ADC{}_Sampling_Rate', 'double'),
    ('ref_clk_freq', 'C_ADC{}_Refclk_Freq', 'double'),
    ('fab_clk_freq', 'C_ADC{}_Fabric_Freq', 'double'),
    ('feedback_div', 'C_ADC{}_FBDIV', 'int'),
    ('output_div', 'C_ADC{}_OutDiv', 'int'),
    ('ref_clk_div', 'C_ADC{}_Refclk_Div', 'int'),
    ('multiband_config', 'C_ADC{}_Band', 'int'),
    ('max_sample_rate', 'C_ADC{}_Fs_Max', 'double'),
    ('num_slices', 'C_ADC{}_Slices', 'int')
]

_Config = [
    ('adc_type', 'C_High_Speed_ADC', 'int'),
    ('adc_sysref_source', 'C_Sysref_Source', 'int'),
    ('dac_sysref_source', 'C_Sysref_Source', 'int'),
    ('ip_type', 'C_IP_Type', 'int'),
    ('si_revision', 'C_Silicon_Revision', 'int')
]

_bool_dict = {'true': 1, 'false': 0}


def _to_value(val, dtype):
    if dtype == 'int':
        return _bool_dict[val] if val in _bool_dict else int(val, 0)
    elif dtype == 'double':
        return float(val)
    raise ValueError(f"{dtype} is not int or double")


def _set_configs(obj, params, config, *args):
    for c in config:
        setattr(obj, c[0], _to_value(params[c[1].format(*args)], c[2]))


def populate_config(obj, params):
    _set_configs(obj, params, _Config)
    for i in range(4):
        dac_tile = obj.dac_tile_config.add()
        _set_configs(dac_tile, params, _DAC_Tile, i)
        adc_tile = obj.adc_tile_config.add()
        _set_configs(adc_tile, params, _ADC_Tile, i)
        for j in range(4):
            dac_analog = dac_tile.dac_block_analog_config.add()
            _set_configs(dac_analog, params, _DAC_ADP, i, j)
            dac_digital = dac_tile.dac_block_digital_config.add()
            _set_configs(dac_digital, params, _DAC_DDP, i, j)
            adc_analog = adc_tile.adc_block_analog_config.add()
            _set_configs(adc_analog, params, _ADC_ADP, i, j)
            adc_digital = adc_tile.adc_block_digital_config.add()
            _set_configs(adc_digital, params, _ADC_DDP, i, j)


# ============================================================================
# Property factory functions (mirrors classic xrfdc's _create_c_property)
# ============================================================================

def _create_scalar_property(name, get_stub, get_field, set_stub=None,
                            set_req=None, set_kwarg=None):
    """Generate a scalar property. Getter returns resp.<get_field>,
    setter passes {set_kwarg: value} to the set request."""
    def _get(self):
        return getattr(self._call_grpc(get_stub), get_field)

    if set_stub is None:
        return property(_get)

    def _set(self, value):
        self._call_grpc(set_stub, getattr(xrfdc_pb2, set_req),
                        **{set_kwarg: value})
    return property(_get, _set)


def _create_dict_property(name, get_stub, resp_attr, field_map,
                          set_stub=None, set_req=None, set_msg=None,
                          readonly=True, callback_event=None):
    """Generate a dict property with PropertyDict callback support.
    field_map: {PythonKey: grpc_field} for both get and set directions."""
    inv_map = {v: k for k, v in field_map.items()}

    def _do_get(self):
        resp = self._call_grpc(get_stub)
        src = getattr(resp, resp_attr) if resp_attr else resp
        return {py_key: getattr(src, grpc_key) for py_key, grpc_key in field_map.items()}

    def _do_set(self, value):
        kwargs = {grpc: value[inv_map[grpc]] for grpc in inv_map}
        msg = getattr(xrfdc_pb2, set_msg)(**kwargs)
        self._call_grpc(set_stub, getattr(xrfdc_pb2, set_req), settings=msg)
        if callback_event is not None:
            self.UpdateEvent(callback_event)

    def _get(self):
        result = _do_get(self)
        if readonly:
            return _as_property_dict(result)
        return _as_property_dict(result, callback=lambda v: _do_set(self, v))

    if readonly:
        return property(_get)

    def _set(self, value):
        _do_set(self, value)
    return property(_get, _set)


# ============================================================================
# Property spec tables
# ============================================================================

# Block-level scalar properties: (name, get_stub, get_field, set_stub, set_req, set_kwarg)
_block_scalar_props = [
    ('NyquistZone',       'GetNyquistZone',       'nyquist_zone',
                          'SetNyquistZone',        'SetNyquistZoneRequest', 'nyquist_zone'),
    ('EnabledInterrupts', 'GetEnabledInterrupts',  'value'),
]

# Block-level dict properties: (name, get_stub, resp_attr, field_map, set_stub, set_req, set_msg, readonly, callback_event)
_block_dict_props = [
    ('MixerSettings', 'GetMixerSettings', 'settings',
     {'Freq': 'freq', 'PhaseOffset': 'phase_offset', 'EventSource': 'event_source',
      'CoarseMixFreq': 'coarse_mix_freq', 'MixerMode': 'mixer_mode',
      'FineMixerScale': 'fine_mixer_scale', 'MixerType': 'mixer_type'},
     'SetMixerSettings', 'SetMixerSettingsRequest', 'MixerSettings', False, EVENT_MIXER),
    ('QMCSettings', 'GetQMCSettings', 'settings',
     {'EnablePhase': 'enable_phase', 'EnableGain': 'enable_gain',
      'EnableOffsetCorr': 'enable_offset_corr',
      'GainCorrectionFactor': 'gain_correction_factor',
      'PhaseCorrectionFactor': 'phase_correction_factor',
      'OffsetCorrectionFactor': 'offset_correction_factor',
      'EventSource': 'event_source'},
     'SetQMCSettings', 'SetQMCSettingsRequest', 'QMCSettings', False, None),
    ('CoarseDelaySettings', 'GetCoarseDelaySettings', 'settings',
     {'CoarseDelay': 'coarse_delay', 'EventSource': 'event_source'},
     'SetCoarseDelaySettings', 'SetCoarseDelaySettingsRequest', 'CoarseDelaySettings',
     False, None),
    ('PwrMode', 'GetPwrMode', 'settings',
     {'DisableIPControl': 'disable_ip_control', 'PwrMode': 'pwr_mode'},
     'SetPwrMode', 'SetPwrModeRequest', 'PwrModeSettings', False, None),
]

# ADC block scalar properties
_adc_scalar_props = [
    ('DecimationFactor',    'GetDecimationFactor',    'dec_factor',
                            'SetDecimationFactor',    'SetDecimationFactorRequest', 'dec_factor'),
    ('CalibrationMode',     'GetCalibrationMode',     'value',
                            'SetCalibrationMode',     'SetCalibrationModeRequest',  'value'),
    ('FabRdVldWords',       'GetFabRdVldWords',       'value',
                            'SetFabRdVldWords',       'SetFabRdVldWordsRequest',    'value'),
    ('FabWrVldWords',       'GetFabWrVldWords',       'value'),
    ('DecimationFactorObs', 'GetDecimationFactorObs', 'dec_factor',
                            'SetDecimationFactorObs', 'SetDecimationFactorRequest', 'dec_factor'),
    ('FabRdVldWordsObs',    'GetFabRdVldWordsObs',    'value',
                            'SetFabRdVldWordsObs',    'SetFabRdVldWordsRequest',    'value'),
    ('FabWrVldWordsObs',    'GetFabWrVldWordsObs',    'value'),
    ('Dither',              'GetDither',              'value',
                            'SetDither',              'SetDitherRequest',           'value'),
]

# ADC block dict properties
_adc_dict_props = [
    ('CalFreeze', 'GetCalFreeze', 'settings',
     {'CalFrozen': 'cal_frozen', 'DisableFreezePin': 'disable_freeze_pin',
      'FreezeCalibration': 'freeze_calibration'},
     'SetCalFreeze', 'SetCalFreezeRequest', 'CalFreezeSettings', False, None),
    ('DSA', 'GetDSA', 'settings',
     {'DisableRTS': 'disable_rts', 'Attenuation': 'attenuation'},
     'SetDSA', 'SetDSARequest', 'DSASettings', False, None),
]

# DAC block scalar properties
_dac_scalar_props = [
    ('InterpolationFactor', 'GetInterpolationFactor', 'interp_factor',
                            'SetInterpolationFactor', 'SetInterpolationFactorRequest', 'interp_factor'),
    ('DecoderMode',         'GetDecoderMode',         'value',
                            'SetDecoderMode',         'SetDecoderModeRequest',         'value'),
    ('OutputCurr',          'GetOutputCurr',          'value'),
    ('InvSincFIR',          'GetInvSincFIR',          'value',
                            'SetInvSincFIR',          'SetInvSincFIRRequest',          'value'),
    ('FabRdVldWords',       'GetFabRdVldWords',       'value'),
    ('FabWrVldWords',       'GetFabWrVldWords',       'value',
                            'SetFabWrVldWords',       'SetFabWrVldWordsRequest',       'value'),
    ('DataPathMode',        'GetDataPathMode',        'value',
                            'SetDataPathMode',        'SetDataPathModeRequest',        'value'),
    ('IMRPassMode',         'GetIMRPassMode',         'value',
                            'SetIMRPassMode',         'SetIMRPassModeRequest',         'value'),
    ('DACCompMode',         'GetDACCompMode',         'value',
                            'SetDACCompMode',         'SetDACCompModeRequest',         'value'),
]

# Tile scalar properties
_tile_scalar_props = [
    ('FabClkOutDiv',  'GetFabClkOutDiv',  'fab_clk_div',
                      'SetFabClkOutDiv',  'SetFabClkOutDivRequest', 'fab_clk_div'),
    ('FIFOStatus',    'GetFIFOStatus',    'enable'),
    ('ClockSource',   'GetClockSource',   'clock_source'),
    ('PLLLockStatus', 'GetPLLLockStatus', 'lock_status'),
]

# Tile dict properties
_tile_dict_props = [
    ('PLLConfig', 'GetPLLConfig', 'settings',
     {'Enabled': 'enabled', 'RefClkFreq': 'ref_clk_freq', 'SampleRate': 'sample_rate',
      'RefClkDivider': 'ref_clk_divider', 'FeedbackDivider': 'feedback_divider',
      'OutputDivider': 'output_divider', 'FractionalMode': 'fractional_mode',
      'FractionalData': 'fractional_data', 'FractWidth': 'fract_width'},
     None, None, None, True, None),
]


# ============================================================================
# Tile and Block Hierarchy
# ============================================================================

class RFdcThreshold:
    def __init__(self, parent, index):
        self._parent = parent
        self._index = index

    def SetClrMode(self, clr_mode):
        self._parent._call_grpc(
            'SetThresholdClrMode', xrfdc_pb2.SetThresholdClrModeRequest,
            threshold_to_update=self._index + 1, clr_mode=clr_mode)

    def StickyClear(self):
        self._parent._call_grpc(
            'ThresholdStickyClear', xrfdc_pb2.ThresholdStickyClearRequest,
            threshold_to_update=self._index + 1)

    @property
    def Settings(self):
        raw = self._parent.GetThresholdSettings()
        return {
            'ThresholdMode': raw['ThresholdMode'][self._index],
            'ThresholdAvgVal': raw['ThresholdAvgVal'][self._index],
            'ThresholdUnderVal': raw['ThresholdUnderVal'][self._index],
            'ThresholdOverVal': raw['ThresholdOverVal'][self._index],
        }

    @Settings.setter
    def Settings(self, settings):
        self._parent.SetThresholdSettings(
            update_threshold=self._index + 1,
            threshold_mode=settings['ThresholdMode'],
            threshold_avg_val=settings['ThresholdAvgVal'],
            threshold_under_val=settings['ThresholdUnderVal'],
            threshold_over_val=settings['ThresholdOverVal'])


class RFdcBlock:
    """Base class for RFdc block — shared by ADC and DAC blocks."""
    def __init__(self, parent, index):
        self._parent = parent
        self._index = index

    def _call_grpc(self, method_name, req_class=None, **kwargs):
        if req_class is None:
            req_class = xrfdc_pb2.BlockRequest
        # Build block-identification fields, only including those the
        # protobuf message actually defines (some Set* messages omit
        # tile_type because they are ADC-only or DAC-only).
        descriptor = req_class.DESCRIPTOR
        field_names = {f.name for f in descriptor.fields}
        id_fields = {}
        if 'tile_type' in field_names:
            id_fields['tile_type'] = self._parent._type
        if 'tile_id' in field_names:
            id_fields['tile_id'] = self._parent._index
        if 'block_id' in field_names:
            id_fields['block_id'] = self._index
        req = req_class(**id_fields, **kwargs)
        resp = getattr(self._parent._parent._stub, method_name)(req)
        if resp.status.code != 0:
            raise RuntimeError(f"{method_name} failed: {resp.status.message}")
        return resp

    # --- Explicit methods (unique logic or keyword-arg API) ---

    def SetupFIFO(self, enable):
        self._call_grpc('SetupFIFO', xrfdc_pb2.SetupFIFORequest, enable=enable)

    def GetBlockStatus(self):
        resp = self._call_grpc('GetBlockStatus')
        samp_freq = resp.sampling_freq
        if samp_freq == 0:
            rfdc = self._parent._parent
            if hasattr(rfdc, 'config_pb'):
                tile_id = self._parent._index
                try:
                    if self._parent._type == XRFDC_DAC_TILE:
                        hwh_rate = rfdc.config_pb.dac_tile_config[tile_id].sampling_rate
                    else:
                        hwh_rate = rfdc.config_pb.adc_tile_config[tile_id].sampling_rate
                    if hwh_rate > 0:
                        samp_freq = hwh_rate
                except (IndexError, AttributeError):
                    pass
        return {
            'SamplingFreq': samp_freq,
            'AnalogDataPathStatus': resp.analog_data_path_status,
            'DigitalDataPathStatus': resp.digital_data_path_status,
            'DataPathClocksStatus': resp.data_path_clocks_status,
            'IsFIFOFlagsEnabled': resp.is_fifo_flags_enabled,
            'IsFIFOFlagsAsserted': resp.is_fifo_flags_asserted,
        }

    @property
    def BlockStatus(self):
        return _as_property_dict(self.GetBlockStatus())

    def GetFIFOStatus(self):
        resp = self._call_grpc('GetFIFOStatus')
        return {'Enable': resp.enable}

    def SetMixerSettings(self, freq, phase_offset=0.0, event_source=EVNT_SRC_IMMEDIATE,
                         coarse_mix_freq=COARSE_MIX_OFF, mixer_mode=MIXER_MODE_C2C,
                         fine_mixer_scale=MIXER_SCALE_AUTO, mixer_type=MIXER_TYPE_FINE):
        settings = xrfdc_pb2.MixerSettings(
            freq=freq, phase_offset=phase_offset, event_source=event_source,
            coarse_mix_freq=coarse_mix_freq, mixer_mode=mixer_mode,
            fine_mixer_scale=fine_mixer_scale, mixer_type=mixer_type)
        self._call_grpc('SetMixerSettings', xrfdc_pb2.SetMixerSettingsRequest,
                        settings=settings)

    def GetMixerSettings(self):
        s = self._call_grpc('GetMixerSettings').settings
        return {'Freq': s.freq, 'PhaseOffset': s.phase_offset,
                'EventSource': s.event_source, 'CoarseMixFreq': s.coarse_mix_freq,
                'MixerMode': s.mixer_mode, 'FineMixerScale': s.fine_mixer_scale,
                'MixerType': s.mixer_type}

    def SetQMCSettings(self, enable_phase=False, enable_gain=False, enable_offset_corr=False,
                       gain_correction_factor=0.0, phase_correction_factor=0.0,
                       offset_correction_factor=0, event_source=EVNT_SRC_IMMEDIATE):
        settings = xrfdc_pb2.QMCSettings(
            enable_phase=enable_phase, enable_gain=enable_gain,
            enable_offset_corr=enable_offset_corr,
            gain_correction_factor=gain_correction_factor,
            phase_correction_factor=phase_correction_factor,
            offset_correction_factor=offset_correction_factor,
            event_source=event_source)
        self._call_grpc('SetQMCSettings', xrfdc_pb2.SetQMCSettingsRequest,
                        settings=settings)

    def GetQMCSettings(self):
        s = self._call_grpc('GetQMCSettings').settings
        return {'EnablePhase': s.enable_phase, 'EnableGain': s.enable_gain,
                'EnableOffsetCorr': s.enable_offset_corr,
                'GainCorrectionFactor': s.gain_correction_factor,
                'PhaseCorrectionFactor': s.phase_correction_factor,
                'OffsetCorrectionFactor': s.offset_correction_factor,
                'EventSource': s.event_source}

    def SetCoarseDelaySettings(self, coarse_delay, event_source=EVNT_SRC_IMMEDIATE):
        settings = xrfdc_pb2.CoarseDelaySettings(
            coarse_delay=coarse_delay, event_source=event_source)
        self._call_grpc('SetCoarseDelaySettings',
                        xrfdc_pb2.SetCoarseDelaySettingsRequest, settings=settings)

    def GetCoarseDelaySettings(self):
        s = self._call_grpc('GetCoarseDelaySettings',
                            xrfdc_pb2.GetCoarseDelaySettingsRequest).settings
        return {'CoarseDelay': s.coarse_delay, 'EventSource': s.event_source}

    def GetPwrMode(self):
        s = self._call_grpc('GetPwrMode').settings
        return {'DisableIPControl': s.disable_ip_control, 'PwrMode': s.pwr_mode}

    def SetPwrMode(self, disable_ip_control, pwr_mode):
        settings = xrfdc_pb2.PwrModeSettings(
            disable_ip_control=disable_ip_control, pwr_mode=pwr_mode)
        self._call_grpc('SetPwrMode', xrfdc_pb2.SetPwrModeRequest, settings=settings)

    def ResetNCOPhase(self):
        self._call_grpc('ResetNCOPhase', xrfdc_pb2.ResetNCOPhaseRequest)

    def UpdateEvent(self, Event):
        self._call_grpc('UpdateEvent', xrfdc_pb2.UpdateEventRequest, event=Event)

    def ResetInternalFIFOWidth(self):
        self._call_grpc('ResetInternalFIFOWidth')

    def GetConnectedIData(self):
        return self._call_grpc('GetConnectedIData').value

    def GetConnectedQData(self):
        return self._call_grpc('GetConnectedQData').value


class RFdcAdcBlock(RFdcBlock):
    """ADC block with ADC-specific methods."""
    def __init__(self, parent, index):
        super().__init__(parent, index)
        self.thresholds = [RFdcThreshold(self, i) for i in range(2)]

    def SetDecimationFactor(self, dec_factor):
        self._call_grpc('SetDecimationFactor',
                        xrfdc_pb2.SetDecimationFactorRequest, dec_factor=dec_factor)

    def GetDecimationFactor(self):
        return self._call_grpc('GetDecimationFactor').dec_factor

    def SetThresholdSettings(self, update_threshold, threshold_mode,
                             threshold_avg_val, threshold_under_val=0,
                             threshold_over_val=0):
        def _pack(value):
            if update_threshold == 1:
                return [value, 0]
            if update_threshold == 2:
                return [0, value]
            if update_threshold == 3:
                return [value, value]
            raise ValueError("update_threshold must be 1, 2, or 3.")

        settings = xrfdc_pb2.ThresholdSettings(
            update_threshold=update_threshold,
            threshold_mode=_pack(threshold_mode),
            threshold_avg_val=_pack(threshold_avg_val),
            threshold_under_val=_pack(threshold_under_val),
            threshold_over_val=_pack(threshold_over_val))
        self._call_grpc('SetThresholdSettings',
                        xrfdc_pb2.SetThresholdSettingsRequest, settings=settings)

    def GetThresholdSettings(self):
        s = self._call_grpc('GetThresholdSettings').settings
        return {'UpdateThreshold': s.update_threshold,
                'ThresholdMode': list(s.threshold_mode),
                'ThresholdAvgVal': list(s.threshold_avg_val),
                'ThresholdUnderVal': list(s.threshold_under_val),
                'ThresholdOverVal': list(s.threshold_over_val)}

    def SetDecimationFactorObs(self, dec_factor):
        self._call_grpc('SetDecimationFactorObs',
                        xrfdc_pb2.SetDecimationFactorRequest, dec_factor=dec_factor)

    def DisableCoefficientsOverride(self, CalibrationBlock):
        self._call_grpc('DisableCoefficientsOverride',
                        xrfdc_pb2.DisableCoefficientsOverrideRequest,
                        calibration_block=CalibrationBlock)

    def ResetInternalFIFOWidthObs(self):
        self._call_grpc('ResetInternalFIFOWidthObs')

    def SetCalCoefficients(self, CalibrationBlock, *args, **kwargs):
        """Set calibration coefficients.
        Supports: (block, struct), (block, c0..c7), (block, coeff0=v, ...)
        """
        if len(args) == 1 and hasattr(args[0], 'Coeff0'):
            coeffs_list = [getattr(args[0], f'Coeff{i}', 0) for i in range(8)]
        elif len(args) >= 7:
            coeffs_list = list(args[:8]) + [0] * (8 - len(args))
        elif kwargs:
            coeffs_list = [kwargs.get(f'coeff{i}', 0) for i in range(8)]
        else:
            raise ValueError(
                "SetCalCoefficients requires: (1) CFFI struct with Coeff0-Coeff7, "
                "(2) 7-8 positional values, or (3) keyword args coeff0-coeff7")
        coeffs = xrfdc_pb2.CalibrationCoefficients(
            **{f'coeff{i}': coeffs_list[i] for i in range(8)})
        self._call_grpc('SetCalCoefficients',
                        xrfdc_pb2.SetCalCoefficientsRequest,
                        calibration_block=CalibrationBlock, coeffs=coeffs)

    def GetCalCoefficients(self, CalibrationBlock):
        resp = self._call_grpc('GetCalCoefficients',
                               xrfdc_pb2.GetCalCoefficientsRequest,
                               calibration_block=CalibrationBlock)
        return CalCoeffStruct({f'coeff{i}': getattr(resp.coeffs, f'coeff{i}')
                               for i in range(8)})

    def IntrHandler(self, *args, **kwargs):
        raise NotImplementedError(
            "Interrupt handlers are not supported in PYNQ.remote mode.")

    def IntrEnable(self, *args, **kwargs):
        raise NotImplementedError(
            "Interrupt control is not supported in PYNQ.remote mode.")

    def IntrDisable(self, *args, **kwargs):
        raise NotImplementedError(
            "Interrupt control is not supported in PYNQ.remote mode.")

    def IntrClear(self, *args, **kwargs):
        raise NotImplementedError(
            "Interrupt control is not supported in PYNQ.remote mode.")


class RFdcDacBlock(RFdcBlock):
    """DAC block with DAC-specific methods."""

    def SetInterpolationFactor(self, interp_factor):
        self._call_grpc('SetInterpolationFactor',
                        xrfdc_pb2.SetInterpolationFactorRequest,
                        interp_factor=interp_factor)

    def GetInterpolationFactor(self):
        return self._call_grpc('GetInterpolationFactor').interp_factor

    def SetDACVOP(self, uACurrent):
        self._call_grpc('SetDACVOP', xrfdc_pb2.SetDACVOPRequest,
                        uA_current=uACurrent)


class RFdcTile:
    """Base tile class."""
    def __init__(self, parent, index):
        self._parent = parent
        self._index = index
        self._type = None  # Set by subclass

    def _call_grpc(self, method_name, req_class=None, **kwargs):
        if req_class is None:
            req_class = xrfdc_pb2.TileRequest
        req = req_class(tile_type=self._type, tile_id=self._index, **kwargs)
        resp = getattr(self._parent._stub, method_name)(req)
        if resp.status.code != 0:
            raise RuntimeError(f"{method_name} failed: {resp.status.message}")
        return resp

    def StartUp(self):
        self._call_grpc('StartUp', xrfdc_pb2.TileControlRequest)

    def Shutdown(self):
        self._call_grpc('Shutdown', xrfdc_pb2.TileControlRequest)

    def ShutDown(self):
        self.Shutdown()

    def Reset(self):
        self._call_grpc('Reset', xrfdc_pb2.TileControlRequest)

    def SetupFIFO(self, Enable, block_id=0):
        self._call_grpc('SetupFIFO', xrfdc_pb2.SetupFIFORequest,
                        enable=Enable, block_id=block_id)

    def DynamicPLLConfig(self, source, ref_clk_freq, samp_rate):
        """Configure PLL dynamically. Auto-calls StartUp() for cold tiles."""
        from time import sleep
        self._call_grpc('DynamicPLLConfig', xrfdc_pb2.DynamicPLLConfigRequest,
                        source=source, ref_clk_freq=ref_clk_freq, samp_rate=samp_rate)
        sleep(0.6)
        self.StartUp()

    def DumpRegs(self):
        self._call_grpc('DumpRegs')

    def GetPLLConfig(self):
        s = self._call_grpc('GetPLLConfig').settings
        return {'Enabled': s.enabled, 'RefClkFreq': s.ref_clk_freq,
                'SampleRate': s.sample_rate, 'RefClkDivider': s.ref_clk_divider,
                'FeedbackDivider': s.feedback_divider,
                'OutputDivider': s.output_divider,
                'FractionalMode': s.fractional_mode,
                'FractionalData': s.fractional_data, 'FractWidth': s.fract_width}


class RFdcAdcTile(RFdcTile):
    """ADC tile with blocks."""
    def __init__(self, parent, index):
        super().__init__(parent, index)
        self._type = XRFDC_ADC_TILE
        self.blocks = [RFdcAdcBlock(self, i) for i in range(4)]

    def SetupFIFOObs(self, Enable):
        self._call_grpc('SetupFIFOObs', xrfdc_pb2.SetupFIFORequest,
                        enable=Enable, block_id=0)

    def SetupFIFOBoth(self, Enable):
        self._call_grpc('SetupFIFOBoth', xrfdc_pb2.SetupFIFORequest,
                        enable=Enable, block_id=0)

    def GetFIFOStatusObs(self):
        resp = self._call_grpc('GetFIFOStatusObs')
        return {'Enable': resp.enable}


class RFdcDacTile(RFdcTile):
    """DAC tile with blocks."""
    def __init__(self, parent, index):
        super().__init__(parent, index)
        self._type = XRFDC_DAC_TILE
        self.blocks = [RFdcDacBlock(self, i) for i in range(4)]


# ============================================================================
# Attach data-driven properties to classes (like classic xrfdc)
# ============================================================================

for spec in _block_scalar_props:
    setattr(RFdcBlock, spec[0], _create_scalar_property(*spec))
for spec in _block_dict_props:
    setattr(RFdcBlock, spec[0], _create_dict_property(*spec))

for spec in _adc_scalar_props:
    setattr(RFdcAdcBlock, spec[0], _create_scalar_property(*spec))
for spec in _adc_dict_props:
    setattr(RFdcAdcBlock, spec[0], _create_dict_property(*spec))

for spec in _dac_scalar_props:
    setattr(RFdcDacBlock, spec[0], _create_scalar_property(*spec))

for spec in _tile_scalar_props:
    setattr(RFdcTile, spec[0], _create_scalar_property(*spec))
for spec in _tile_dict_props:
    setattr(RFdcTile, spec[0], _create_dict_property(*spec))


# ============================================================================
# Top-Level RFdc Class
# ============================================================================

class RFdc(DefaultIP):
    """Remote driver for Xilinx RF Data Converter with automatic initialization.

    Communicates with RFdc hardware via gRPC. API-compatible with classic
    xrfdc.RFdc. RFDC is automatically configured upon instantiation.
    """

    bindto = ["xilinx.com:ip:usp_rf_data_converter:2.6",
              "xilinx.com:ip:usp_rf_data_converter:2.4",
              "xilinx.com:ip:usp_rf_data_converter:2.3"]

    def __init__(self, description, clock_config=None, enabled_tiles=None):
        if 'parameters' not in description:
            raise ValueError("RFdc requires HWH parameters in description")

        super().__init__(description)

        # Create/get stub
        if not hasattr(self.device, '_stub'):
            self.device._stub = {}
        if 'xrfdc' not in self.device._stub:
            self.device._stub['xrfdc'] = xrfdc_pb2_grpc.XrfdcStub(
                self.device.client.channel)
        self._stub = self.device._stub['xrfdc']

        # Extract base address
        if 'phys_addr' in description:
            base_addr = description['phys_addr']
        elif 'addr_range' in description:
            base_addr = description['addr_range'][0]
        else:
            raise ValueError("Cannot determine base address from description")

        # Extract size
        if 'addr_range' in description:
            ar = description['addr_range']
            if isinstance(ar, list) and len(ar) >= 2:
                size = ar[1] - ar[0]
            elif isinstance(ar, int):
                size = ar
            else:
                raise ValueError(f"Unexpected addr_range shape: {ar!r}")
        elif 'size' in description:
            size = description['size']
        else:
            raise ValueError("Cannot determine RFDC register region size from description")

        # Build config from HWH parameters
        self.config_pb = xrfdc_pb2.RFdcConfig()
        populate_config(self.config_pb, description['parameters'])
        self.config_pb.base_addr = base_addr

        # Initialize remote instance
        req = xrfdc_pb2.CfgInitializeRequest(config=self.config_pb, size=size)
        resp = self._stub.CfgInitialize(req)
        if resp.status.code != 0:
            raise RuntimeError(f"Remote RFdc init failed: {resp.status.message}")

        # Create tile hierarchy (length comes from the populated HWH config)
        self.adc_tiles = [RFdcAdcTile(self, i)
                          for i in range(len(self.config_pb.adc_tile_config))]
        self.dac_tiles = [RFdcDacTile(self, i)
                          for i in range(len(self.config_pb.dac_tile_config))]

    def _detect_enabled_tiles(self):
        """Auto-detect which tiles are enabled from HWH configuration."""
        return {
            'dac': [i for i, tc in enumerate(self.config_pb.dac_tile_config) if tc.enable],
            'adc': [i for i, tc in enumerate(self.config_pb.adc_tile_config) if tc.enable],
        }

    def startup_tiles(self, enabled_tiles=None):
        """Configure and start the enabled RFDC tiles from the HWH clock settings.

        ref_clk_freq is MHz; sampling_rate is GHz and DynamicPLLConfig wants MSPS.
        """
        from time import sleep
        if enabled_tiles is None:
            enabled_tiles = self._detect_enabled_tiles()

        for tile_id in enabled_tiles.get('dac', []):
            tile = self.dac_tiles[tile_id]
            tc = self.config_pb.dac_tile_config[tile_id]
            try:
                tile.ShutDown()
                sleep(0.2)
            except Exception:
                pass
            tile.DynamicPLLConfig(CLK_SRC_PLL, tc.ref_clk_freq, tc.sampling_rate * 1000)
            try:
                tile.SetupFIFO(True)
            except Exception:
                pass

        for tile_id in enabled_tiles.get('adc', []):
            tile = self.adc_tiles[tile_id]
            tc = self.config_pb.adc_tile_config[tile_id]
            try:
                tile.ShutDown()
                sleep(0.2)
            except Exception:
                pass
            tile.DynamicPLLConfig(CLK_SRC_PLL, tc.ref_clk_freq, tc.sampling_rate * 1000)
            try:
                tile.SetupFIFO(True)
            except Exception:
                pass

    @property
    def IPStatus(self):
        req = xrfdc_pb2.GetIPStatusRequest()
        resp = self._stub.GetIPStatus(req)
        if resp.status.code != 0:
            raise RuntimeError(f"GetIPStatus failed: {resp.status.message}")

        def _tile_status(tile):
            blocks = []
            for b in tile.block_status:
                blocks.append({
                    'SamplingFreq': b.sampling_freq,
                    'AnalogDataPathStatus': int(b.analog_data_path_status),
                    'DigitalDataPathStatus': int(b.digital_data_path_status),
                    'DataPathClocksStatus': b.data_path_clocks_status,
                    'IsFIFOFlagsEnabled': int(b.is_fifo_flags_enabled),
                    'IsFIFOFlagsAsserted': int(b.is_fifo_flags_asserted),
                })
            return {
                'IsEnabled': tile.is_enabled,
                'TileState': tile.tile_state,
                'BlockStatusMask': tile.block_status_mask,
                'PowerUpState': tile.power_up_state,
                'PLLState': tile.pll_state,
                'BlockStatus': blocks,
            }

        return _as_property_dict({
            'DACTileStatus': [_tile_status(t) for t in resp.ip_status.dac_tile_status],
            'ADCTileStatus': [_tile_status(t) for t in resp.ip_status.adc_tile_status],
            'State': resp.ip_status.state,
        })

    def GetClkDistribution(self):
        req = xrfdc_pb2.GetClkDistributionRequest()
        resp = self._stub.GetClkDistribution(req)
        if resp.status.code != 0:
            raise RuntimeError(f"GetClkDistribution failed: {resp.status.message}")

        def _tile_clk(ts):
            return {'SourceType': ts.source_type, 'SourceTile': ts.source_tile,
                    'PLLEnable': ts.pll_enable, 'RefClkFreq': ts.ref_clk_freq,
                    'SampleRate': ts.sample_rate, 'DivisionFactor': ts.division_factor,
                    'DistributedClock': ts.distributed_clock, 'Delay': ts.delay}

        dist = resp.settings.distribution_info
        return {
            'DAC': [_tile_clk(t) for t in resp.settings.dac],
            'ADC': [_tile_clk(t) for t in resp.settings.adc],
            'DistributionInfo': {
                'Source': dist.source, 'UpperBound': dist.upper_bound,
                'LowerBound': dist.lower_bound, 'MaxDelay': dist.max_delay,
                'MinDelay': dist.min_delay, 'IsDelayBalanced': dist.is_delay_balanced,
            },
        }

    def SetClkDistribution(self, distribution_settings):
        settings = xrfdc_pb2.ClkDistributionSettings()
        _CLK_DIST_FIELDS = {
            'SourceType': 'source_type', 'SourceTile': 'source_tile',
            'PLLEnable': 'pll_enable', 'RefClkFreq': 'ref_clk_freq',
            'SampleRate': 'sample_rate', 'DivisionFactor': 'division_factor',
            'DistributedClock': 'distributed_clock', 'Delay': 'delay',
        }
        for d in distribution_settings.get('DAC', []):
            t = settings.dac.add()
            for k, v in d.items():
                setattr(t, _CLK_DIST_FIELDS[k], v)
        for d in distribution_settings.get('ADC', []):
            t = settings.adc.add()
            for k, v in d.items():
                setattr(t, _CLK_DIST_FIELDS[k], v)
        if 'DistributionInfo' in distribution_settings:
            di = distribution_settings['DistributionInfo']
            settings.distribution_info.source = di.get('Source', 0)
            settings.distribution_info.upper_bound = di.get('UpperBound', 0)
            settings.distribution_info.lower_bound = di.get('LowerBound', 0)
            settings.distribution_info.max_delay = di.get('MaxDelay', 0)
            settings.distribution_info.min_delay = di.get('MinDelay', 0)
            settings.distribution_info.is_delay_balanced = di.get('IsDelayBalanced', 0)

        req = xrfdc_pb2.SetClkDistributionRequest(settings=settings)
        resp = self._stub.SetClkDistribution(req)
        if resp.status.code != 0:
            raise RuntimeError(f"SetClkDistribution failed: {resp.status.message}")

    @property
    def ClkDistribution(self):
        settings = self.GetClkDistribution()
        return _as_property_dict(settings, callback=lambda v: self.SetClkDistribution(v))

    @ClkDistribution.setter
    def ClkDistribution(self, value):
        self.SetClkDistribution(value)
