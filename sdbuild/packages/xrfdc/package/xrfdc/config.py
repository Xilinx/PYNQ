#   Copyright (c) 2018, Xilinx, Inc.
#   SPDX-License-Identifier: BSD-3-Clause




_DAC_ADP = [
    ('BlockAvailable', 'C_DAC_Slice{}{}_Enable', 'int'),
    ('InvSyncEnable', 'C_DAC_Invsinc_Ctrl{}{}', 'int'),
    ('MixMode', 'C_DAC_Mixer_Mode{}{}', 'int'),
    ('DecoderMode', 'C_DAC_Decoder_Mode{}{}', 'int')
]

_DAC_DDP = [
    ('MixerInputDataType', 'C_DAC_Data_Type{}{}', 'int'),
    ('DataWidth', 'C_DAC_Data_Width{}{}', 'int'),
    ('InterpolationMode', 'C_DAC_Interpolation_Mode{}{}', 'int'),
    ('MixerType', 'C_DAC_Mixer_Type{}{}', 'int')
]

_ADC_ADP = [
    ('BlockAvailable', 'C_ADC_Slice{}{}_Enable', 'int'),
    ('MixMode', 'C_ADC_Mixer_Mode{}{}', 'int')
]

_ADC_DDP = [
    ('MixerInputDataType', 'C_ADC_Data_Type{}{}', 'int'),
    ('DataWidth', 'C_ADC_Data_Width{}{}', 'int'),
    ('DecimationMode', 'C_ADC_Decimation_Mode{}{}', 'int'),
    ('MixerType', 'C_ADC_Mixer_Type{}{}', 'int')
]

_DAC_Tile = [
    ('Enable', 'C_DAC{}_Enable', 'int'),
    ('PLLEnable', 'C_DAC{}_PLL_Enable', 'int'),
    ('SamplingRate', 'C_DAC{}_Sampling_Rate', 'double'),
    ('RefClkFreq', 'C_DAC{}_Refclk_Freq', 'double'),
    ('FabClkFreq', 'C_DAC{}_Fabric_Freq', 'double'),
    ('FeedbackDiv', 'C_DAC{}_FBDIV', 'int'),
    ('OutputDiv', 'C_DAC{}_OutDiv', 'int'),
    ('RefClkDiv', 'C_DAC{}_Refclk_Div', 'int'),
    ('MultibandConfig', 'C_DAC{}_Band', 'int'),
    ('MaxSampleRate', 'C_DAC{}_Fs_Max', 'double'),
    ('NumSlices', 'C_DAC{}_Slices', 'int')
]

_ADC_Tile = [
    ('Enable', 'C_ADC{}_Enable', 'int'),
    ('PLLEnable', 'C_ADC{}_PLL_Enable', 'int'),
    ('SamplingRate', 'C_ADC{}_Sampling_Rate', 'double'),
    ('RefClkFreq', 'C_ADC{}_Refclk_Freq', 'double'),
    ('FabClkFreq', 'C_ADC{}_Fabric_Freq', 'double'),
    ('FeedbackDiv', 'C_ADC{}_FBDIV', 'int'),
    ('OutputDiv', 'C_ADC{}_OutDiv', 'int'),
    ('RefClkDiv', 'C_ADC{}_Refclk_Div', 'int'),
    ('MultibandConfig', 'C_ADC{}_Band', 'int'),
    ('MaxSampleRate', 'C_ADC{}_Fs_Max', 'double'),
    ('NumSlices', 'C_ADC{}_Slices', 'int')
]

_Config = [
    ('ADCType', 'C_High_Speed_ADC', 'int'),
    ('ADCSysRefSource', 'C_Sysref_Source', 'int'),
    ('DACSysRefSource', 'C_Sysref_Source', 'int'),
    ('IPType', 'C_IP_Type', 'int'),
    ('SiRevision', 'C_Silicon_Revision', 'int')
]

_bool_dict = {
    'true': 1,
    'false': 0
}


def _to_value(val, dtype):
    if dtype == 'int':
        if val in _bool_dict:
            return _bool_dict[val]
        return int(val, 0)
    elif dtype == 'double':
        return float(val)
    else:
        raise ValueError(f"{dtype} is not int or double")


def _set_configs(obj, params, config, *args):
    for c in config:
        setattr(obj, c[0], _to_value(params[c[1].format(*args)], c[2]))


def populate_config(obj, params):
    _set_configs(obj, params, _Config)
    for i in range(4):
        _set_configs(obj.DACTile_Config[i], params, _DAC_Tile, i)
        _set_configs(obj.ADCTile_Config[i], params, _ADC_Tile, i)
        for j in range(4):
            _set_configs(obj.DACTile_Config[i].DACBlock_Analog_Config[j],
                         params, _DAC_ADP, i, j)
            _set_configs(obj.DACTile_Config[i].DACBlock_Digital_Config[j],
                         params, _DAC_DDP, i, j)
            _set_configs(obj.ADCTile_Config[i].ADCBlock_Analog_Config[j],
                         params, _ADC_ADP, i, j)
            _set_configs(obj.ADCTile_Config[i].ADCBlock_Digital_Config[j],
                         params, _ADC_DDP, i, j)


