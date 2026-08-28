from google.protobuf.internal import containers as _containers
from google.protobuf import descriptor as _descriptor
from google.protobuf import message as _message
from collections.abc import Iterable as _Iterable, Mapping as _Mapping
from typing import ClassVar as _ClassVar, Optional as _Optional, Union as _Union

DESCRIPTOR: _descriptor.FileDescriptor

class Status(_message.Message):
    __slots__ = ("code", "message", "operation", "tile_type_name", "tile_id", "block_id")
    CODE_FIELD_NUMBER: _ClassVar[int]
    MESSAGE_FIELD_NUMBER: _ClassVar[int]
    OPERATION_FIELD_NUMBER: _ClassVar[int]
    TILE_TYPE_NAME_FIELD_NUMBER: _ClassVar[int]
    TILE_ID_FIELD_NUMBER: _ClassVar[int]
    BLOCK_ID_FIELD_NUMBER: _ClassVar[int]
    code: int
    message: str
    operation: str
    tile_type_name: str
    tile_id: int
    block_id: int
    def __init__(self, code: _Optional[int] = ..., message: _Optional[str] = ..., operation: _Optional[str] = ..., tile_type_name: _Optional[str] = ..., tile_id: _Optional[int] = ..., block_id: _Optional[int] = ...) -> None: ...

class BlockStatus(_message.Message):
    __slots__ = ("sampling_freq", "analog_data_path_status", "digital_data_path_status", "data_path_clocks_status", "is_fifo_flags_enabled", "ib_supply", "is_fifo_flags_asserted")
    SAMPLING_FREQ_FIELD_NUMBER: _ClassVar[int]
    ANALOG_DATA_PATH_STATUS_FIELD_NUMBER: _ClassVar[int]
    DIGITAL_DATA_PATH_STATUS_FIELD_NUMBER: _ClassVar[int]
    DATA_PATH_CLOCKS_STATUS_FIELD_NUMBER: _ClassVar[int]
    IS_FIFO_FLAGS_ENABLED_FIELD_NUMBER: _ClassVar[int]
    IB_SUPPLY_FIELD_NUMBER: _ClassVar[int]
    IS_FIFO_FLAGS_ASSERTED_FIELD_NUMBER: _ClassVar[int]
    sampling_freq: float
    analog_data_path_status: int
    digital_data_path_status: int
    data_path_clocks_status: int
    is_fifo_flags_enabled: int
    ib_supply: int
    is_fifo_flags_asserted: int
    def __init__(self, sampling_freq: _Optional[float] = ..., analog_data_path_status: _Optional[int] = ..., digital_data_path_status: _Optional[int] = ..., data_path_clocks_status: _Optional[int] = ..., is_fifo_flags_enabled: _Optional[int] = ..., ib_supply: _Optional[int] = ..., is_fifo_flags_asserted: _Optional[int] = ...) -> None: ...

class TileStatus(_message.Message):
    __slots__ = ("is_enabled", "tile_state", "block_status_mask", "power_up_state", "pll_state", "block_status")
    IS_ENABLED_FIELD_NUMBER: _ClassVar[int]
    TILE_STATE_FIELD_NUMBER: _ClassVar[int]
    BLOCK_STATUS_MASK_FIELD_NUMBER: _ClassVar[int]
    POWER_UP_STATE_FIELD_NUMBER: _ClassVar[int]
    PLL_STATE_FIELD_NUMBER: _ClassVar[int]
    BLOCK_STATUS_FIELD_NUMBER: _ClassVar[int]
    is_enabled: int
    tile_state: int
    block_status_mask: int
    power_up_state: int
    pll_state: int
    block_status: _containers.RepeatedCompositeFieldContainer[BlockStatus]
    def __init__(self, is_enabled: _Optional[int] = ..., tile_state: _Optional[int] = ..., block_status_mask: _Optional[int] = ..., power_up_state: _Optional[int] = ..., pll_state: _Optional[int] = ..., block_status: _Optional[_Iterable[_Union[BlockStatus, _Mapping]]] = ...) -> None: ...

class IPStatus(_message.Message):
    __slots__ = ("dac_tile_status", "adc_tile_status", "state")
    DAC_TILE_STATUS_FIELD_NUMBER: _ClassVar[int]
    ADC_TILE_STATUS_FIELD_NUMBER: _ClassVar[int]
    STATE_FIELD_NUMBER: _ClassVar[int]
    dac_tile_status: _containers.RepeatedCompositeFieldContainer[TileStatus]
    adc_tile_status: _containers.RepeatedCompositeFieldContainer[TileStatus]
    state: int
    def __init__(self, dac_tile_status: _Optional[_Iterable[_Union[TileStatus, _Mapping]]] = ..., adc_tile_status: _Optional[_Iterable[_Union[TileStatus, _Mapping]]] = ..., state: _Optional[int] = ...) -> None: ...

class DACBlockAnalogDataPathConfig(_message.Message):
    __slots__ = ("block_available", "inv_sync_enable", "mix_mode", "decoder_mode")
    BLOCK_AVAILABLE_FIELD_NUMBER: _ClassVar[int]
    INV_SYNC_ENABLE_FIELD_NUMBER: _ClassVar[int]
    MIX_MODE_FIELD_NUMBER: _ClassVar[int]
    DECODER_MODE_FIELD_NUMBER: _ClassVar[int]
    block_available: int
    inv_sync_enable: int
    mix_mode: int
    decoder_mode: int
    def __init__(self, block_available: _Optional[int] = ..., inv_sync_enable: _Optional[int] = ..., mix_mode: _Optional[int] = ..., decoder_mode: _Optional[int] = ...) -> None: ...

class DACBlockDigitalDataPathConfig(_message.Message):
    __slots__ = ("mixer_input_data_type", "data_width", "interpolation_mode", "fifo_enable", "adder_enable", "mixer_type")
    MIXER_INPUT_DATA_TYPE_FIELD_NUMBER: _ClassVar[int]
    DATA_WIDTH_FIELD_NUMBER: _ClassVar[int]
    INTERPOLATION_MODE_FIELD_NUMBER: _ClassVar[int]
    FIFO_ENABLE_FIELD_NUMBER: _ClassVar[int]
    ADDER_ENABLE_FIELD_NUMBER: _ClassVar[int]
    MIXER_TYPE_FIELD_NUMBER: _ClassVar[int]
    mixer_input_data_type: int
    data_width: int
    interpolation_mode: int
    fifo_enable: int
    adder_enable: int
    mixer_type: int
    def __init__(self, mixer_input_data_type: _Optional[int] = ..., data_width: _Optional[int] = ..., interpolation_mode: _Optional[int] = ..., fifo_enable: _Optional[int] = ..., adder_enable: _Optional[int] = ..., mixer_type: _Optional[int] = ...) -> None: ...

class ADCBlockAnalogDataPathConfig(_message.Message):
    __slots__ = ("block_available", "mix_mode")
    BLOCK_AVAILABLE_FIELD_NUMBER: _ClassVar[int]
    MIX_MODE_FIELD_NUMBER: _ClassVar[int]
    block_available: int
    mix_mode: int
    def __init__(self, block_available: _Optional[int] = ..., mix_mode: _Optional[int] = ...) -> None: ...

class ADCBlockDigitalDataPathConfig(_message.Message):
    __slots__ = ("mixer_input_data_type", "data_width", "decimation_mode", "fifo_enable", "mixer_type")
    MIXER_INPUT_DATA_TYPE_FIELD_NUMBER: _ClassVar[int]
    DATA_WIDTH_FIELD_NUMBER: _ClassVar[int]
    DECIMATION_MODE_FIELD_NUMBER: _ClassVar[int]
    FIFO_ENABLE_FIELD_NUMBER: _ClassVar[int]
    MIXER_TYPE_FIELD_NUMBER: _ClassVar[int]
    mixer_input_data_type: int
    data_width: int
    decimation_mode: int
    fifo_enable: int
    mixer_type: int
    def __init__(self, mixer_input_data_type: _Optional[int] = ..., data_width: _Optional[int] = ..., decimation_mode: _Optional[int] = ..., fifo_enable: _Optional[int] = ..., mixer_type: _Optional[int] = ...) -> None: ...

class DACTileConfig(_message.Message):
    __slots__ = ("enable", "pll_enable", "sampling_rate", "ref_clk_freq", "fab_clk_freq", "feedback_div", "output_div", "ref_clk_div", "multiband_config", "max_sample_rate", "num_slices", "dac_block_analog_config", "dac_block_digital_config")
    ENABLE_FIELD_NUMBER: _ClassVar[int]
    PLL_ENABLE_FIELD_NUMBER: _ClassVar[int]
    SAMPLING_RATE_FIELD_NUMBER: _ClassVar[int]
    REF_CLK_FREQ_FIELD_NUMBER: _ClassVar[int]
    FAB_CLK_FREQ_FIELD_NUMBER: _ClassVar[int]
    FEEDBACK_DIV_FIELD_NUMBER: _ClassVar[int]
    OUTPUT_DIV_FIELD_NUMBER: _ClassVar[int]
    REF_CLK_DIV_FIELD_NUMBER: _ClassVar[int]
    MULTIBAND_CONFIG_FIELD_NUMBER: _ClassVar[int]
    MAX_SAMPLE_RATE_FIELD_NUMBER: _ClassVar[int]
    NUM_SLICES_FIELD_NUMBER: _ClassVar[int]
    DAC_BLOCK_ANALOG_CONFIG_FIELD_NUMBER: _ClassVar[int]
    DAC_BLOCK_DIGITAL_CONFIG_FIELD_NUMBER: _ClassVar[int]
    enable: int
    pll_enable: int
    sampling_rate: float
    ref_clk_freq: float
    fab_clk_freq: float
    feedback_div: int
    output_div: int
    ref_clk_div: int
    multiband_config: int
    max_sample_rate: float
    num_slices: int
    dac_block_analog_config: _containers.RepeatedCompositeFieldContainer[DACBlockAnalogDataPathConfig]
    dac_block_digital_config: _containers.RepeatedCompositeFieldContainer[DACBlockDigitalDataPathConfig]
    def __init__(self, enable: _Optional[int] = ..., pll_enable: _Optional[int] = ..., sampling_rate: _Optional[float] = ..., ref_clk_freq: _Optional[float] = ..., fab_clk_freq: _Optional[float] = ..., feedback_div: _Optional[int] = ..., output_div: _Optional[int] = ..., ref_clk_div: _Optional[int] = ..., multiband_config: _Optional[int] = ..., max_sample_rate: _Optional[float] = ..., num_slices: _Optional[int] = ..., dac_block_analog_config: _Optional[_Iterable[_Union[DACBlockAnalogDataPathConfig, _Mapping]]] = ..., dac_block_digital_config: _Optional[_Iterable[_Union[DACBlockDigitalDataPathConfig, _Mapping]]] = ...) -> None: ...

class ADCTileConfig(_message.Message):
    __slots__ = ("enable", "pll_enable", "sampling_rate", "ref_clk_freq", "fab_clk_freq", "feedback_div", "output_div", "ref_clk_div", "multiband_config", "max_sample_rate", "num_slices", "adc_block_analog_config", "adc_block_digital_config")
    ENABLE_FIELD_NUMBER: _ClassVar[int]
    PLL_ENABLE_FIELD_NUMBER: _ClassVar[int]
    SAMPLING_RATE_FIELD_NUMBER: _ClassVar[int]
    REF_CLK_FREQ_FIELD_NUMBER: _ClassVar[int]
    FAB_CLK_FREQ_FIELD_NUMBER: _ClassVar[int]
    FEEDBACK_DIV_FIELD_NUMBER: _ClassVar[int]
    OUTPUT_DIV_FIELD_NUMBER: _ClassVar[int]
    REF_CLK_DIV_FIELD_NUMBER: _ClassVar[int]
    MULTIBAND_CONFIG_FIELD_NUMBER: _ClassVar[int]
    MAX_SAMPLE_RATE_FIELD_NUMBER: _ClassVar[int]
    NUM_SLICES_FIELD_NUMBER: _ClassVar[int]
    ADC_BLOCK_ANALOG_CONFIG_FIELD_NUMBER: _ClassVar[int]
    ADC_BLOCK_DIGITAL_CONFIG_FIELD_NUMBER: _ClassVar[int]
    enable: int
    pll_enable: int
    sampling_rate: float
    ref_clk_freq: float
    fab_clk_freq: float
    feedback_div: int
    output_div: int
    ref_clk_div: int
    multiband_config: int
    max_sample_rate: float
    num_slices: int
    adc_block_analog_config: _containers.RepeatedCompositeFieldContainer[ADCBlockAnalogDataPathConfig]
    adc_block_digital_config: _containers.RepeatedCompositeFieldContainer[ADCBlockDigitalDataPathConfig]
    def __init__(self, enable: _Optional[int] = ..., pll_enable: _Optional[int] = ..., sampling_rate: _Optional[float] = ..., ref_clk_freq: _Optional[float] = ..., fab_clk_freq: _Optional[float] = ..., feedback_div: _Optional[int] = ..., output_div: _Optional[int] = ..., ref_clk_div: _Optional[int] = ..., multiband_config: _Optional[int] = ..., max_sample_rate: _Optional[float] = ..., num_slices: _Optional[int] = ..., adc_block_analog_config: _Optional[_Iterable[_Union[ADCBlockAnalogDataPathConfig, _Mapping]]] = ..., adc_block_digital_config: _Optional[_Iterable[_Union[ADCBlockDigitalDataPathConfig, _Mapping]]] = ...) -> None: ...

class RFdcConfig(_message.Message):
    __slots__ = ("device_id", "base_addr", "adc_type", "master_adc_tile", "master_dac_tile", "adc_sysref_source", "dac_sysref_source", "ip_type", "si_revision", "dac_tile_config", "adc_tile_config")
    DEVICE_ID_FIELD_NUMBER: _ClassVar[int]
    BASE_ADDR_FIELD_NUMBER: _ClassVar[int]
    ADC_TYPE_FIELD_NUMBER: _ClassVar[int]
    MASTER_ADC_TILE_FIELD_NUMBER: _ClassVar[int]
    MASTER_DAC_TILE_FIELD_NUMBER: _ClassVar[int]
    ADC_SYSREF_SOURCE_FIELD_NUMBER: _ClassVar[int]
    DAC_SYSREF_SOURCE_FIELD_NUMBER: _ClassVar[int]
    IP_TYPE_FIELD_NUMBER: _ClassVar[int]
    SI_REVISION_FIELD_NUMBER: _ClassVar[int]
    DAC_TILE_CONFIG_FIELD_NUMBER: _ClassVar[int]
    ADC_TILE_CONFIG_FIELD_NUMBER: _ClassVar[int]
    device_id: int
    base_addr: int
    adc_type: int
    master_adc_tile: int
    master_dac_tile: int
    adc_sysref_source: int
    dac_sysref_source: int
    ip_type: int
    si_revision: int
    dac_tile_config: _containers.RepeatedCompositeFieldContainer[DACTileConfig]
    adc_tile_config: _containers.RepeatedCompositeFieldContainer[ADCTileConfig]
    def __init__(self, device_id: _Optional[int] = ..., base_addr: _Optional[int] = ..., adc_type: _Optional[int] = ..., master_adc_tile: _Optional[int] = ..., master_dac_tile: _Optional[int] = ..., adc_sysref_source: _Optional[int] = ..., dac_sysref_source: _Optional[int] = ..., ip_type: _Optional[int] = ..., si_revision: _Optional[int] = ..., dac_tile_config: _Optional[_Iterable[_Union[DACTileConfig, _Mapping]]] = ..., adc_tile_config: _Optional[_Iterable[_Union[ADCTileConfig, _Mapping]]] = ...) -> None: ...

class CfgInitializeRequest(_message.Message):
    __slots__ = ("config", "size")
    CONFIG_FIELD_NUMBER: _ClassVar[int]
    SIZE_FIELD_NUMBER: _ClassVar[int]
    config: RFdcConfig
    size: int
    def __init__(self, config: _Optional[_Union[RFdcConfig, _Mapping]] = ..., size: _Optional[int] = ...) -> None: ...

class CfgInitializeResponse(_message.Message):
    __slots__ = ("status",)
    STATUS_FIELD_NUMBER: _ClassVar[int]
    status: Status
    def __init__(self, status: _Optional[_Union[Status, _Mapping]] = ...) -> None: ...

class GetIPStatusRequest(_message.Message):
    __slots__ = ()
    def __init__(self) -> None: ...

class GetIPStatusResponse(_message.Message):
    __slots__ = ("status", "ip_status")
    STATUS_FIELD_NUMBER: _ClassVar[int]
    IP_STATUS_FIELD_NUMBER: _ClassVar[int]
    status: Status
    ip_status: IPStatus
    def __init__(self, status: _Optional[_Union[Status, _Mapping]] = ..., ip_status: _Optional[_Union[IPStatus, _Mapping]] = ...) -> None: ...

class TileControlRequest(_message.Message):
    __slots__ = ("tile_type", "tile_id")
    TILE_TYPE_FIELD_NUMBER: _ClassVar[int]
    TILE_ID_FIELD_NUMBER: _ClassVar[int]
    tile_type: int
    tile_id: int
    def __init__(self, tile_type: _Optional[int] = ..., tile_id: _Optional[int] = ...) -> None: ...

class TileControlResponse(_message.Message):
    __slots__ = ("status",)
    STATUS_FIELD_NUMBER: _ClassVar[int]
    status: Status
    def __init__(self, status: _Optional[_Union[Status, _Mapping]] = ...) -> None: ...

class SetupFIFORequest(_message.Message):
    __slots__ = ("tile_type", "tile_id", "enable", "block_id")
    TILE_TYPE_FIELD_NUMBER: _ClassVar[int]
    TILE_ID_FIELD_NUMBER: _ClassVar[int]
    ENABLE_FIELD_NUMBER: _ClassVar[int]
    BLOCK_ID_FIELD_NUMBER: _ClassVar[int]
    tile_type: int
    tile_id: int
    enable: bool
    block_id: int
    def __init__(self, tile_type: _Optional[int] = ..., tile_id: _Optional[int] = ..., enable: bool = ..., block_id: _Optional[int] = ...) -> None: ...

class DynamicPLLConfigRequest(_message.Message):
    __slots__ = ("tile_type", "tile_id", "source", "ref_clk_freq", "samp_rate")
    TILE_TYPE_FIELD_NUMBER: _ClassVar[int]
    TILE_ID_FIELD_NUMBER: _ClassVar[int]
    SOURCE_FIELD_NUMBER: _ClassVar[int]
    REF_CLK_FREQ_FIELD_NUMBER: _ClassVar[int]
    SAMP_RATE_FIELD_NUMBER: _ClassVar[int]
    tile_type: int
    tile_id: int
    source: int
    ref_clk_freq: float
    samp_rate: float
    def __init__(self, tile_type: _Optional[int] = ..., tile_id: _Optional[int] = ..., source: _Optional[int] = ..., ref_clk_freq: _Optional[float] = ..., samp_rate: _Optional[float] = ...) -> None: ...

class BlockRequest(_message.Message):
    __slots__ = ("tile_type", "tile_id", "block_id")
    TILE_TYPE_FIELD_NUMBER: _ClassVar[int]
    TILE_ID_FIELD_NUMBER: _ClassVar[int]
    BLOCK_ID_FIELD_NUMBER: _ClassVar[int]
    tile_type: int
    tile_id: int
    block_id: int
    def __init__(self, tile_type: _Optional[int] = ..., tile_id: _Optional[int] = ..., block_id: _Optional[int] = ...) -> None: ...

class TileRequest(_message.Message):
    __slots__ = ("tile_type", "tile_id")
    TILE_TYPE_FIELD_NUMBER: _ClassVar[int]
    TILE_ID_FIELD_NUMBER: _ClassVar[int]
    tile_type: int
    tile_id: int
    def __init__(self, tile_type: _Optional[int] = ..., tile_id: _Optional[int] = ...) -> None: ...

class GetBlockStatusResponse(_message.Message):
    __slots__ = ("status", "sampling_freq", "analog_data_path_status", "digital_data_path_status", "data_path_clocks_status", "is_fifo_flags_enabled", "is_fifo_flags_asserted")
    STATUS_FIELD_NUMBER: _ClassVar[int]
    SAMPLING_FREQ_FIELD_NUMBER: _ClassVar[int]
    ANALOG_DATA_PATH_STATUS_FIELD_NUMBER: _ClassVar[int]
    DIGITAL_DATA_PATH_STATUS_FIELD_NUMBER: _ClassVar[int]
    DATA_PATH_CLOCKS_STATUS_FIELD_NUMBER: _ClassVar[int]
    IS_FIFO_FLAGS_ENABLED_FIELD_NUMBER: _ClassVar[int]
    IS_FIFO_FLAGS_ASSERTED_FIELD_NUMBER: _ClassVar[int]
    status: Status
    sampling_freq: float
    analog_data_path_status: int
    digital_data_path_status: int
    data_path_clocks_status: int
    is_fifo_flags_enabled: int
    is_fifo_flags_asserted: int
    def __init__(self, status: _Optional[_Union[Status, _Mapping]] = ..., sampling_freq: _Optional[float] = ..., analog_data_path_status: _Optional[int] = ..., digital_data_path_status: _Optional[int] = ..., data_path_clocks_status: _Optional[int] = ..., is_fifo_flags_enabled: _Optional[int] = ..., is_fifo_flags_asserted: _Optional[int] = ...) -> None: ...

class GetFIFOStatusResponse(_message.Message):
    __slots__ = ("status", "enable")
    STATUS_FIELD_NUMBER: _ClassVar[int]
    ENABLE_FIELD_NUMBER: _ClassVar[int]
    status: Status
    enable: bool
    def __init__(self, status: _Optional[_Union[Status, _Mapping]] = ..., enable: bool = ...) -> None: ...

class GetPLLLockStatusResponse(_message.Message):
    __slots__ = ("status", "lock_status")
    STATUS_FIELD_NUMBER: _ClassVar[int]
    LOCK_STATUS_FIELD_NUMBER: _ClassVar[int]
    status: Status
    lock_status: int
    def __init__(self, status: _Optional[_Union[Status, _Mapping]] = ..., lock_status: _Optional[int] = ...) -> None: ...

class GetClockSourceResponse(_message.Message):
    __slots__ = ("status", "clock_source")
    STATUS_FIELD_NUMBER: _ClassVar[int]
    CLOCK_SOURCE_FIELD_NUMBER: _ClassVar[int]
    status: Status
    clock_source: int
    def __init__(self, status: _Optional[_Union[Status, _Mapping]] = ..., clock_source: _Optional[int] = ...) -> None: ...

class SetFabClkOutDivRequest(_message.Message):
    __slots__ = ("tile_type", "tile_id", "fab_clk_div")
    TILE_TYPE_FIELD_NUMBER: _ClassVar[int]
    TILE_ID_FIELD_NUMBER: _ClassVar[int]
    FAB_CLK_DIV_FIELD_NUMBER: _ClassVar[int]
    tile_type: int
    tile_id: int
    fab_clk_div: int
    def __init__(self, tile_type: _Optional[int] = ..., tile_id: _Optional[int] = ..., fab_clk_div: _Optional[int] = ...) -> None: ...

class GetFabClkOutDivResponse(_message.Message):
    __slots__ = ("status", "fab_clk_div")
    STATUS_FIELD_NUMBER: _ClassVar[int]
    FAB_CLK_DIV_FIELD_NUMBER: _ClassVar[int]
    status: Status
    fab_clk_div: int
    def __init__(self, status: _Optional[_Union[Status, _Mapping]] = ..., fab_clk_div: _Optional[int] = ...) -> None: ...

class MixerSettings(_message.Message):
    __slots__ = ("freq", "phase_offset", "event_source", "coarse_mix_freq", "mixer_mode", "fine_mixer_scale", "mixer_type")
    FREQ_FIELD_NUMBER: _ClassVar[int]
    PHASE_OFFSET_FIELD_NUMBER: _ClassVar[int]
    EVENT_SOURCE_FIELD_NUMBER: _ClassVar[int]
    COARSE_MIX_FREQ_FIELD_NUMBER: _ClassVar[int]
    MIXER_MODE_FIELD_NUMBER: _ClassVar[int]
    FINE_MIXER_SCALE_FIELD_NUMBER: _ClassVar[int]
    MIXER_TYPE_FIELD_NUMBER: _ClassVar[int]
    freq: float
    phase_offset: float
    event_source: int
    coarse_mix_freq: int
    mixer_mode: int
    fine_mixer_scale: int
    mixer_type: int
    def __init__(self, freq: _Optional[float] = ..., phase_offset: _Optional[float] = ..., event_source: _Optional[int] = ..., coarse_mix_freq: _Optional[int] = ..., mixer_mode: _Optional[int] = ..., fine_mixer_scale: _Optional[int] = ..., mixer_type: _Optional[int] = ...) -> None: ...

class SetMixerSettingsRequest(_message.Message):
    __slots__ = ("tile_type", "tile_id", "block_id", "settings")
    TILE_TYPE_FIELD_NUMBER: _ClassVar[int]
    TILE_ID_FIELD_NUMBER: _ClassVar[int]
    BLOCK_ID_FIELD_NUMBER: _ClassVar[int]
    SETTINGS_FIELD_NUMBER: _ClassVar[int]
    tile_type: int
    tile_id: int
    block_id: int
    settings: MixerSettings
    def __init__(self, tile_type: _Optional[int] = ..., tile_id: _Optional[int] = ..., block_id: _Optional[int] = ..., settings: _Optional[_Union[MixerSettings, _Mapping]] = ...) -> None: ...

class GetMixerSettingsResponse(_message.Message):
    __slots__ = ("status", "settings")
    STATUS_FIELD_NUMBER: _ClassVar[int]
    SETTINGS_FIELD_NUMBER: _ClassVar[int]
    status: Status
    settings: MixerSettings
    def __init__(self, status: _Optional[_Union[Status, _Mapping]] = ..., settings: _Optional[_Union[MixerSettings, _Mapping]] = ...) -> None: ...

class ResetNCOPhaseRequest(_message.Message):
    __slots__ = ("tile_type", "tile_id", "block_id")
    TILE_TYPE_FIELD_NUMBER: _ClassVar[int]
    TILE_ID_FIELD_NUMBER: _ClassVar[int]
    BLOCK_ID_FIELD_NUMBER: _ClassVar[int]
    tile_type: int
    tile_id: int
    block_id: int
    def __init__(self, tile_type: _Optional[int] = ..., tile_id: _Optional[int] = ..., block_id: _Optional[int] = ...) -> None: ...

class SetNyquistZoneRequest(_message.Message):
    __slots__ = ("tile_type", "tile_id", "block_id", "nyquist_zone")
    TILE_TYPE_FIELD_NUMBER: _ClassVar[int]
    TILE_ID_FIELD_NUMBER: _ClassVar[int]
    BLOCK_ID_FIELD_NUMBER: _ClassVar[int]
    NYQUIST_ZONE_FIELD_NUMBER: _ClassVar[int]
    tile_type: int
    tile_id: int
    block_id: int
    nyquist_zone: int
    def __init__(self, tile_type: _Optional[int] = ..., tile_id: _Optional[int] = ..., block_id: _Optional[int] = ..., nyquist_zone: _Optional[int] = ...) -> None: ...

class GetNyquistZoneResponse(_message.Message):
    __slots__ = ("status", "nyquist_zone")
    STATUS_FIELD_NUMBER: _ClassVar[int]
    NYQUIST_ZONE_FIELD_NUMBER: _ClassVar[int]
    status: Status
    nyquist_zone: int
    def __init__(self, status: _Optional[_Union[Status, _Mapping]] = ..., nyquist_zone: _Optional[int] = ...) -> None: ...

class SetInterpolationFactorRequest(_message.Message):
    __slots__ = ("tile_id", "block_id", "interp_factor")
    TILE_ID_FIELD_NUMBER: _ClassVar[int]
    BLOCK_ID_FIELD_NUMBER: _ClassVar[int]
    INTERP_FACTOR_FIELD_NUMBER: _ClassVar[int]
    tile_id: int
    block_id: int
    interp_factor: int
    def __init__(self, tile_id: _Optional[int] = ..., block_id: _Optional[int] = ..., interp_factor: _Optional[int] = ...) -> None: ...

class GetInterpolationFactorResponse(_message.Message):
    __slots__ = ("status", "interp_factor")
    STATUS_FIELD_NUMBER: _ClassVar[int]
    INTERP_FACTOR_FIELD_NUMBER: _ClassVar[int]
    status: Status
    interp_factor: int
    def __init__(self, status: _Optional[_Union[Status, _Mapping]] = ..., interp_factor: _Optional[int] = ...) -> None: ...

class SetDecimationFactorRequest(_message.Message):
    __slots__ = ("tile_id", "block_id", "dec_factor")
    TILE_ID_FIELD_NUMBER: _ClassVar[int]
    BLOCK_ID_FIELD_NUMBER: _ClassVar[int]
    DEC_FACTOR_FIELD_NUMBER: _ClassVar[int]
    tile_id: int
    block_id: int
    dec_factor: int
    def __init__(self, tile_id: _Optional[int] = ..., block_id: _Optional[int] = ..., dec_factor: _Optional[int] = ...) -> None: ...

class GetDecimationFactorResponse(_message.Message):
    __slots__ = ("status", "dec_factor")
    STATUS_FIELD_NUMBER: _ClassVar[int]
    DEC_FACTOR_FIELD_NUMBER: _ClassVar[int]
    status: Status
    dec_factor: int
    def __init__(self, status: _Optional[_Union[Status, _Mapping]] = ..., dec_factor: _Optional[int] = ...) -> None: ...

class QMCSettings(_message.Message):
    __slots__ = ("enable_phase", "enable_gain", "enable_offset_corr", "gain_correction_factor", "phase_correction_factor", "offset_correction_factor", "event_source")
    ENABLE_PHASE_FIELD_NUMBER: _ClassVar[int]
    ENABLE_GAIN_FIELD_NUMBER: _ClassVar[int]
    ENABLE_OFFSET_CORR_FIELD_NUMBER: _ClassVar[int]
    GAIN_CORRECTION_FACTOR_FIELD_NUMBER: _ClassVar[int]
    PHASE_CORRECTION_FACTOR_FIELD_NUMBER: _ClassVar[int]
    OFFSET_CORRECTION_FACTOR_FIELD_NUMBER: _ClassVar[int]
    EVENT_SOURCE_FIELD_NUMBER: _ClassVar[int]
    enable_phase: bool
    enable_gain: bool
    enable_offset_corr: bool
    gain_correction_factor: float
    phase_correction_factor: float
    offset_correction_factor: int
    event_source: int
    def __init__(self, enable_phase: bool = ..., enable_gain: bool = ..., enable_offset_corr: bool = ..., gain_correction_factor: _Optional[float] = ..., phase_correction_factor: _Optional[float] = ..., offset_correction_factor: _Optional[int] = ..., event_source: _Optional[int] = ...) -> None: ...

class SetQMCSettingsRequest(_message.Message):
    __slots__ = ("tile_type", "tile_id", "block_id", "settings")
    TILE_TYPE_FIELD_NUMBER: _ClassVar[int]
    TILE_ID_FIELD_NUMBER: _ClassVar[int]
    BLOCK_ID_FIELD_NUMBER: _ClassVar[int]
    SETTINGS_FIELD_NUMBER: _ClassVar[int]
    tile_type: int
    tile_id: int
    block_id: int
    settings: QMCSettings
    def __init__(self, tile_type: _Optional[int] = ..., tile_id: _Optional[int] = ..., block_id: _Optional[int] = ..., settings: _Optional[_Union[QMCSettings, _Mapping]] = ...) -> None: ...

class GetQMCSettingsResponse(_message.Message):
    __slots__ = ("status", "settings")
    STATUS_FIELD_NUMBER: _ClassVar[int]
    SETTINGS_FIELD_NUMBER: _ClassVar[int]
    status: Status
    settings: QMCSettings
    def __init__(self, status: _Optional[_Union[Status, _Mapping]] = ..., settings: _Optional[_Union[QMCSettings, _Mapping]] = ...) -> None: ...

class ThresholdSettings(_message.Message):
    __slots__ = ("update_threshold", "threshold_mode", "threshold_avg_val", "threshold_under_val", "threshold_over_val")
    UPDATE_THRESHOLD_FIELD_NUMBER: _ClassVar[int]
    THRESHOLD_MODE_FIELD_NUMBER: _ClassVar[int]
    THRESHOLD_AVG_VAL_FIELD_NUMBER: _ClassVar[int]
    THRESHOLD_UNDER_VAL_FIELD_NUMBER: _ClassVar[int]
    THRESHOLD_OVER_VAL_FIELD_NUMBER: _ClassVar[int]
    update_threshold: int
    threshold_mode: _containers.RepeatedScalarFieldContainer[int]
    threshold_avg_val: _containers.RepeatedScalarFieldContainer[int]
    threshold_under_val: _containers.RepeatedScalarFieldContainer[int]
    threshold_over_val: _containers.RepeatedScalarFieldContainer[int]
    def __init__(self, update_threshold: _Optional[int] = ..., threshold_mode: _Optional[_Iterable[int]] = ..., threshold_avg_val: _Optional[_Iterable[int]] = ..., threshold_under_val: _Optional[_Iterable[int]] = ..., threshold_over_val: _Optional[_Iterable[int]] = ...) -> None: ...

class SetThresholdSettingsRequest(_message.Message):
    __slots__ = ("tile_id", "block_id", "settings")
    TILE_ID_FIELD_NUMBER: _ClassVar[int]
    BLOCK_ID_FIELD_NUMBER: _ClassVar[int]
    SETTINGS_FIELD_NUMBER: _ClassVar[int]
    tile_id: int
    block_id: int
    settings: ThresholdSettings
    def __init__(self, tile_id: _Optional[int] = ..., block_id: _Optional[int] = ..., settings: _Optional[_Union[ThresholdSettings, _Mapping]] = ...) -> None: ...

class GetThresholdSettingsResponse(_message.Message):
    __slots__ = ("status", "settings")
    STATUS_FIELD_NUMBER: _ClassVar[int]
    SETTINGS_FIELD_NUMBER: _ClassVar[int]
    status: Status
    settings: ThresholdSettings
    def __init__(self, status: _Optional[_Union[Status, _Mapping]] = ..., settings: _Optional[_Union[ThresholdSettings, _Mapping]] = ...) -> None: ...

class CoarseDelaySettings(_message.Message):
    __slots__ = ("coarse_delay", "event_source")
    COARSE_DELAY_FIELD_NUMBER: _ClassVar[int]
    EVENT_SOURCE_FIELD_NUMBER: _ClassVar[int]
    coarse_delay: int
    event_source: int
    def __init__(self, coarse_delay: _Optional[int] = ..., event_source: _Optional[int] = ...) -> None: ...

class SetThresholdClrModeRequest(_message.Message):
    __slots__ = ("tile_id", "block_id", "threshold_to_update", "clr_mode")
    TILE_ID_FIELD_NUMBER: _ClassVar[int]
    BLOCK_ID_FIELD_NUMBER: _ClassVar[int]
    THRESHOLD_TO_UPDATE_FIELD_NUMBER: _ClassVar[int]
    CLR_MODE_FIELD_NUMBER: _ClassVar[int]
    tile_id: int
    block_id: int
    threshold_to_update: int
    clr_mode: int
    def __init__(self, tile_id: _Optional[int] = ..., block_id: _Optional[int] = ..., threshold_to_update: _Optional[int] = ..., clr_mode: _Optional[int] = ...) -> None: ...

class SetThresholdClrModeResponse(_message.Message):
    __slots__ = ("status",)
    STATUS_FIELD_NUMBER: _ClassVar[int]
    status: Status
    def __init__(self, status: _Optional[_Union[Status, _Mapping]] = ...) -> None: ...

class ThresholdStickyClearRequest(_message.Message):
    __slots__ = ("tile_id", "block_id", "threshold_to_update")
    TILE_ID_FIELD_NUMBER: _ClassVar[int]
    BLOCK_ID_FIELD_NUMBER: _ClassVar[int]
    THRESHOLD_TO_UPDATE_FIELD_NUMBER: _ClassVar[int]
    tile_id: int
    block_id: int
    threshold_to_update: int
    def __init__(self, tile_id: _Optional[int] = ..., block_id: _Optional[int] = ..., threshold_to_update: _Optional[int] = ...) -> None: ...

class ThresholdStickyClearResponse(_message.Message):
    __slots__ = ("status",)
    STATUS_FIELD_NUMBER: _ClassVar[int]
    status: Status
    def __init__(self, status: _Optional[_Union[Status, _Mapping]] = ...) -> None: ...

class GetCoarseDelaySettingsRequest(_message.Message):
    __slots__ = ("tile_type", "tile_id", "block_id")
    TILE_TYPE_FIELD_NUMBER: _ClassVar[int]
    TILE_ID_FIELD_NUMBER: _ClassVar[int]
    BLOCK_ID_FIELD_NUMBER: _ClassVar[int]
    tile_type: int
    tile_id: int
    block_id: int
    def __init__(self, tile_type: _Optional[int] = ..., tile_id: _Optional[int] = ..., block_id: _Optional[int] = ...) -> None: ...

class GetCoarseDelaySettingsResponse(_message.Message):
    __slots__ = ("status", "settings")
    STATUS_FIELD_NUMBER: _ClassVar[int]
    SETTINGS_FIELD_NUMBER: _ClassVar[int]
    status: Status
    settings: CoarseDelaySettings
    def __init__(self, status: _Optional[_Union[Status, _Mapping]] = ..., settings: _Optional[_Union[CoarseDelaySettings, _Mapping]] = ...) -> None: ...

class SetCoarseDelaySettingsRequest(_message.Message):
    __slots__ = ("tile_type", "tile_id", "block_id", "settings")
    TILE_TYPE_FIELD_NUMBER: _ClassVar[int]
    TILE_ID_FIELD_NUMBER: _ClassVar[int]
    BLOCK_ID_FIELD_NUMBER: _ClassVar[int]
    SETTINGS_FIELD_NUMBER: _ClassVar[int]
    tile_type: int
    tile_id: int
    block_id: int
    settings: CoarseDelaySettings
    def __init__(self, tile_type: _Optional[int] = ..., tile_id: _Optional[int] = ..., block_id: _Optional[int] = ..., settings: _Optional[_Union[CoarseDelaySettings, _Mapping]] = ...) -> None: ...

class SetCoarseDelaySettingsResponse(_message.Message):
    __slots__ = ("status",)
    STATUS_FIELD_NUMBER: _ClassVar[int]
    status: Status
    def __init__(self, status: _Optional[_Union[Status, _Mapping]] = ...) -> None: ...

class PwrModeSettings(_message.Message):
    __slots__ = ("disable_ip_control", "pwr_mode")
    DISABLE_IP_CONTROL_FIELD_NUMBER: _ClassVar[int]
    PWR_MODE_FIELD_NUMBER: _ClassVar[int]
    disable_ip_control: int
    pwr_mode: int
    def __init__(self, disable_ip_control: _Optional[int] = ..., pwr_mode: _Optional[int] = ...) -> None: ...

class GetPwrModeResponse(_message.Message):
    __slots__ = ("status", "settings")
    STATUS_FIELD_NUMBER: _ClassVar[int]
    SETTINGS_FIELD_NUMBER: _ClassVar[int]
    status: Status
    settings: PwrModeSettings
    def __init__(self, status: _Optional[_Union[Status, _Mapping]] = ..., settings: _Optional[_Union[PwrModeSettings, _Mapping]] = ...) -> None: ...

class SetPwrModeRequest(_message.Message):
    __slots__ = ("tile_type", "tile_id", "block_id", "settings")
    TILE_TYPE_FIELD_NUMBER: _ClassVar[int]
    TILE_ID_FIELD_NUMBER: _ClassVar[int]
    BLOCK_ID_FIELD_NUMBER: _ClassVar[int]
    SETTINGS_FIELD_NUMBER: _ClassVar[int]
    tile_type: int
    tile_id: int
    block_id: int
    settings: PwrModeSettings
    def __init__(self, tile_type: _Optional[int] = ..., tile_id: _Optional[int] = ..., block_id: _Optional[int] = ..., settings: _Optional[_Union[PwrModeSettings, _Mapping]] = ...) -> None: ...

class UpdateEventRequest(_message.Message):
    __slots__ = ("tile_type", "tile_id", "block_id", "event")
    TILE_TYPE_FIELD_NUMBER: _ClassVar[int]
    TILE_ID_FIELD_NUMBER: _ClassVar[int]
    BLOCK_ID_FIELD_NUMBER: _ClassVar[int]
    EVENT_FIELD_NUMBER: _ClassVar[int]
    tile_type: int
    tile_id: int
    block_id: int
    event: int
    def __init__(self, tile_type: _Optional[int] = ..., tile_id: _Optional[int] = ..., block_id: _Optional[int] = ..., event: _Optional[int] = ...) -> None: ...

class GetConnectedDataResponse(_message.Message):
    __slots__ = ("status", "value")
    STATUS_FIELD_NUMBER: _ClassVar[int]
    VALUE_FIELD_NUMBER: _ClassVar[int]
    status: Status
    value: int
    def __init__(self, status: _Optional[_Union[Status, _Mapping]] = ..., value: _Optional[int] = ...) -> None: ...

class GetEnabledInterruptsResponse(_message.Message):
    __slots__ = ("status", "value")
    STATUS_FIELD_NUMBER: _ClassVar[int]
    VALUE_FIELD_NUMBER: _ClassVar[int]
    status: Status
    value: int
    def __init__(self, status: _Optional[_Union[Status, _Mapping]] = ..., value: _Optional[int] = ...) -> None: ...

class GetCalibrationModeResponse(_message.Message):
    __slots__ = ("status", "value")
    STATUS_FIELD_NUMBER: _ClassVar[int]
    VALUE_FIELD_NUMBER: _ClassVar[int]
    status: Status
    value: int
    def __init__(self, status: _Optional[_Union[Status, _Mapping]] = ..., value: _Optional[int] = ...) -> None: ...

class SetCalibrationModeRequest(_message.Message):
    __slots__ = ("tile_id", "block_id", "value")
    TILE_ID_FIELD_NUMBER: _ClassVar[int]
    BLOCK_ID_FIELD_NUMBER: _ClassVar[int]
    VALUE_FIELD_NUMBER: _ClassVar[int]
    tile_id: int
    block_id: int
    value: int
    def __init__(self, tile_id: _Optional[int] = ..., block_id: _Optional[int] = ..., value: _Optional[int] = ...) -> None: ...

class GetFabRdVldWordsResponse(_message.Message):
    __slots__ = ("status", "value")
    STATUS_FIELD_NUMBER: _ClassVar[int]
    VALUE_FIELD_NUMBER: _ClassVar[int]
    status: Status
    value: int
    def __init__(self, status: _Optional[_Union[Status, _Mapping]] = ..., value: _Optional[int] = ...) -> None: ...

class SetFabRdVldWordsRequest(_message.Message):
    __slots__ = ("tile_id", "block_id", "value")
    TILE_ID_FIELD_NUMBER: _ClassVar[int]
    BLOCK_ID_FIELD_NUMBER: _ClassVar[int]
    VALUE_FIELD_NUMBER: _ClassVar[int]
    tile_id: int
    block_id: int
    value: int
    def __init__(self, tile_id: _Optional[int] = ..., block_id: _Optional[int] = ..., value: _Optional[int] = ...) -> None: ...

class GetFabWrVldWordsResponse(_message.Message):
    __slots__ = ("status", "value")
    STATUS_FIELD_NUMBER: _ClassVar[int]
    VALUE_FIELD_NUMBER: _ClassVar[int]
    status: Status
    value: int
    def __init__(self, status: _Optional[_Union[Status, _Mapping]] = ..., value: _Optional[int] = ...) -> None: ...

class SetFabWrVldWordsRequest(_message.Message):
    __slots__ = ("tile_id", "block_id", "value")
    TILE_ID_FIELD_NUMBER: _ClassVar[int]
    BLOCK_ID_FIELD_NUMBER: _ClassVar[int]
    VALUE_FIELD_NUMBER: _ClassVar[int]
    tile_id: int
    block_id: int
    value: int
    def __init__(self, tile_id: _Optional[int] = ..., block_id: _Optional[int] = ..., value: _Optional[int] = ...) -> None: ...

class GetFabRdVldWordsObsResponse(_message.Message):
    __slots__ = ("status", "value")
    STATUS_FIELD_NUMBER: _ClassVar[int]
    VALUE_FIELD_NUMBER: _ClassVar[int]
    status: Status
    value: int
    def __init__(self, status: _Optional[_Union[Status, _Mapping]] = ..., value: _Optional[int] = ...) -> None: ...

class SetFabRdVldWordsObsRequest(_message.Message):
    __slots__ = ("tile_id", "block_id", "value")
    TILE_ID_FIELD_NUMBER: _ClassVar[int]
    BLOCK_ID_FIELD_NUMBER: _ClassVar[int]
    VALUE_FIELD_NUMBER: _ClassVar[int]
    tile_id: int
    block_id: int
    value: int
    def __init__(self, tile_id: _Optional[int] = ..., block_id: _Optional[int] = ..., value: _Optional[int] = ...) -> None: ...

class GetFabWrVldWordsObsResponse(_message.Message):
    __slots__ = ("status", "value")
    STATUS_FIELD_NUMBER: _ClassVar[int]
    VALUE_FIELD_NUMBER: _ClassVar[int]
    status: Status
    value: int
    def __init__(self, status: _Optional[_Union[Status, _Mapping]] = ..., value: _Optional[int] = ...) -> None: ...

class SetDitherRequest(_message.Message):
    __slots__ = ("tile_id", "block_id", "value")
    TILE_ID_FIELD_NUMBER: _ClassVar[int]
    BLOCK_ID_FIELD_NUMBER: _ClassVar[int]
    VALUE_FIELD_NUMBER: _ClassVar[int]
    tile_id: int
    block_id: int
    value: int
    def __init__(self, tile_id: _Optional[int] = ..., block_id: _Optional[int] = ..., value: _Optional[int] = ...) -> None: ...

class GetDitherResponse(_message.Message):
    __slots__ = ("status", "value")
    STATUS_FIELD_NUMBER: _ClassVar[int]
    VALUE_FIELD_NUMBER: _ClassVar[int]
    status: Status
    value: int
    def __init__(self, status: _Optional[_Union[Status, _Mapping]] = ..., value: _Optional[int] = ...) -> None: ...

class SetDecoderModeRequest(_message.Message):
    __slots__ = ("tile_id", "block_id", "value")
    TILE_ID_FIELD_NUMBER: _ClassVar[int]
    BLOCK_ID_FIELD_NUMBER: _ClassVar[int]
    VALUE_FIELD_NUMBER: _ClassVar[int]
    tile_id: int
    block_id: int
    value: int
    def __init__(self, tile_id: _Optional[int] = ..., block_id: _Optional[int] = ..., value: _Optional[int] = ...) -> None: ...

class GetDecoderModeResponse(_message.Message):
    __slots__ = ("status", "value")
    STATUS_FIELD_NUMBER: _ClassVar[int]
    VALUE_FIELD_NUMBER: _ClassVar[int]
    status: Status
    value: int
    def __init__(self, status: _Optional[_Union[Status, _Mapping]] = ..., value: _Optional[int] = ...) -> None: ...

class GetOutputCurrResponse(_message.Message):
    __slots__ = ("status", "value")
    STATUS_FIELD_NUMBER: _ClassVar[int]
    VALUE_FIELD_NUMBER: _ClassVar[int]
    status: Status
    value: int
    def __init__(self, status: _Optional[_Union[Status, _Mapping]] = ..., value: _Optional[int] = ...) -> None: ...

class GetInvSincFIRResponse(_message.Message):
    __slots__ = ("status", "value")
    STATUS_FIELD_NUMBER: _ClassVar[int]
    VALUE_FIELD_NUMBER: _ClassVar[int]
    status: Status
    value: int
    def __init__(self, status: _Optional[_Union[Status, _Mapping]] = ..., value: _Optional[int] = ...) -> None: ...

class SetInvSincFIRRequest(_message.Message):
    __slots__ = ("tile_id", "block_id", "value")
    TILE_ID_FIELD_NUMBER: _ClassVar[int]
    BLOCK_ID_FIELD_NUMBER: _ClassVar[int]
    VALUE_FIELD_NUMBER: _ClassVar[int]
    tile_id: int
    block_id: int
    value: int
    def __init__(self, tile_id: _Optional[int] = ..., block_id: _Optional[int] = ..., value: _Optional[int] = ...) -> None: ...

class GetDataPathModeResponse(_message.Message):
    __slots__ = ("status", "value")
    STATUS_FIELD_NUMBER: _ClassVar[int]
    VALUE_FIELD_NUMBER: _ClassVar[int]
    status: Status
    value: int
    def __init__(self, status: _Optional[_Union[Status, _Mapping]] = ..., value: _Optional[int] = ...) -> None: ...

class SetDataPathModeRequest(_message.Message):
    __slots__ = ("tile_id", "block_id", "value")
    TILE_ID_FIELD_NUMBER: _ClassVar[int]
    BLOCK_ID_FIELD_NUMBER: _ClassVar[int]
    VALUE_FIELD_NUMBER: _ClassVar[int]
    tile_id: int
    block_id: int
    value: int
    def __init__(self, tile_id: _Optional[int] = ..., block_id: _Optional[int] = ..., value: _Optional[int] = ...) -> None: ...

class GetIMRPassModeResponse(_message.Message):
    __slots__ = ("status", "value")
    STATUS_FIELD_NUMBER: _ClassVar[int]
    VALUE_FIELD_NUMBER: _ClassVar[int]
    status: Status
    value: int
    def __init__(self, status: _Optional[_Union[Status, _Mapping]] = ..., value: _Optional[int] = ...) -> None: ...

class SetIMRPassModeRequest(_message.Message):
    __slots__ = ("tile_id", "block_id", "value")
    TILE_ID_FIELD_NUMBER: _ClassVar[int]
    BLOCK_ID_FIELD_NUMBER: _ClassVar[int]
    VALUE_FIELD_NUMBER: _ClassVar[int]
    tile_id: int
    block_id: int
    value: int
    def __init__(self, tile_id: _Optional[int] = ..., block_id: _Optional[int] = ..., value: _Optional[int] = ...) -> None: ...

class GetDACCompModeResponse(_message.Message):
    __slots__ = ("status", "value")
    STATUS_FIELD_NUMBER: _ClassVar[int]
    VALUE_FIELD_NUMBER: _ClassVar[int]
    status: Status
    value: int
    def __init__(self, status: _Optional[_Union[Status, _Mapping]] = ..., value: _Optional[int] = ...) -> None: ...

class SetDACCompModeRequest(_message.Message):
    __slots__ = ("tile_id", "block_id", "value")
    TILE_ID_FIELD_NUMBER: _ClassVar[int]
    BLOCK_ID_FIELD_NUMBER: _ClassVar[int]
    VALUE_FIELD_NUMBER: _ClassVar[int]
    tile_id: int
    block_id: int
    value: int
    def __init__(self, tile_id: _Optional[int] = ..., block_id: _Optional[int] = ..., value: _Optional[int] = ...) -> None: ...

class CalFreezeSettings(_message.Message):
    __slots__ = ("cal_frozen", "disable_freeze_pin", "freeze_calibration")
    CAL_FROZEN_FIELD_NUMBER: _ClassVar[int]
    DISABLE_FREEZE_PIN_FIELD_NUMBER: _ClassVar[int]
    FREEZE_CALIBRATION_FIELD_NUMBER: _ClassVar[int]
    cal_frozen: int
    disable_freeze_pin: int
    freeze_calibration: int
    def __init__(self, cal_frozen: _Optional[int] = ..., disable_freeze_pin: _Optional[int] = ..., freeze_calibration: _Optional[int] = ...) -> None: ...

class GetCalFreezeResponse(_message.Message):
    __slots__ = ("status", "settings")
    STATUS_FIELD_NUMBER: _ClassVar[int]
    SETTINGS_FIELD_NUMBER: _ClassVar[int]
    status: Status
    settings: CalFreezeSettings
    def __init__(self, status: _Optional[_Union[Status, _Mapping]] = ..., settings: _Optional[_Union[CalFreezeSettings, _Mapping]] = ...) -> None: ...

class SetCalFreezeRequest(_message.Message):
    __slots__ = ("tile_id", "block_id", "settings")
    TILE_ID_FIELD_NUMBER: _ClassVar[int]
    BLOCK_ID_FIELD_NUMBER: _ClassVar[int]
    SETTINGS_FIELD_NUMBER: _ClassVar[int]
    tile_id: int
    block_id: int
    settings: CalFreezeSettings
    def __init__(self, tile_id: _Optional[int] = ..., block_id: _Optional[int] = ..., settings: _Optional[_Union[CalFreezeSettings, _Mapping]] = ...) -> None: ...

class DSASettings(_message.Message):
    __slots__ = ("disable_rts", "attenuation")
    DISABLE_RTS_FIELD_NUMBER: _ClassVar[int]
    ATTENUATION_FIELD_NUMBER: _ClassVar[int]
    disable_rts: int
    attenuation: float
    def __init__(self, disable_rts: _Optional[int] = ..., attenuation: _Optional[float] = ...) -> None: ...

class GetDSAResponse(_message.Message):
    __slots__ = ("status", "settings")
    STATUS_FIELD_NUMBER: _ClassVar[int]
    SETTINGS_FIELD_NUMBER: _ClassVar[int]
    status: Status
    settings: DSASettings
    def __init__(self, status: _Optional[_Union[Status, _Mapping]] = ..., settings: _Optional[_Union[DSASettings, _Mapping]] = ...) -> None: ...

class SetDSARequest(_message.Message):
    __slots__ = ("tile_id", "block_id", "settings")
    TILE_ID_FIELD_NUMBER: _ClassVar[int]
    BLOCK_ID_FIELD_NUMBER: _ClassVar[int]
    SETTINGS_FIELD_NUMBER: _ClassVar[int]
    tile_id: int
    block_id: int
    settings: DSASettings
    def __init__(self, tile_id: _Optional[int] = ..., block_id: _Optional[int] = ..., settings: _Optional[_Union[DSASettings, _Mapping]] = ...) -> None: ...

class DisableCoefficientsOverrideRequest(_message.Message):
    __slots__ = ("tile_id", "block_id", "calibration_block")
    TILE_ID_FIELD_NUMBER: _ClassVar[int]
    BLOCK_ID_FIELD_NUMBER: _ClassVar[int]
    CALIBRATION_BLOCK_FIELD_NUMBER: _ClassVar[int]
    tile_id: int
    block_id: int
    calibration_block: int
    def __init__(self, tile_id: _Optional[int] = ..., block_id: _Optional[int] = ..., calibration_block: _Optional[int] = ...) -> None: ...

class CalibrationCoefficients(_message.Message):
    __slots__ = ("coeff0", "coeff1", "coeff2", "coeff3", "coeff4", "coeff5", "coeff6", "coeff7")
    COEFF0_FIELD_NUMBER: _ClassVar[int]
    COEFF1_FIELD_NUMBER: _ClassVar[int]
    COEFF2_FIELD_NUMBER: _ClassVar[int]
    COEFF3_FIELD_NUMBER: _ClassVar[int]
    COEFF4_FIELD_NUMBER: _ClassVar[int]
    COEFF5_FIELD_NUMBER: _ClassVar[int]
    COEFF6_FIELD_NUMBER: _ClassVar[int]
    COEFF7_FIELD_NUMBER: _ClassVar[int]
    coeff0: int
    coeff1: int
    coeff2: int
    coeff3: int
    coeff4: int
    coeff5: int
    coeff6: int
    coeff7: int
    def __init__(self, coeff0: _Optional[int] = ..., coeff1: _Optional[int] = ..., coeff2: _Optional[int] = ..., coeff3: _Optional[int] = ..., coeff4: _Optional[int] = ..., coeff5: _Optional[int] = ..., coeff6: _Optional[int] = ..., coeff7: _Optional[int] = ...) -> None: ...

class SetCalCoefficientsRequest(_message.Message):
    __slots__ = ("tile_id", "block_id", "calibration_block", "coeffs")
    TILE_ID_FIELD_NUMBER: _ClassVar[int]
    BLOCK_ID_FIELD_NUMBER: _ClassVar[int]
    CALIBRATION_BLOCK_FIELD_NUMBER: _ClassVar[int]
    COEFFS_FIELD_NUMBER: _ClassVar[int]
    tile_id: int
    block_id: int
    calibration_block: int
    coeffs: CalibrationCoefficients
    def __init__(self, tile_id: _Optional[int] = ..., block_id: _Optional[int] = ..., calibration_block: _Optional[int] = ..., coeffs: _Optional[_Union[CalibrationCoefficients, _Mapping]] = ...) -> None: ...

class GetCalCoefficientsRequest(_message.Message):
    __slots__ = ("tile_id", "block_id", "calibration_block")
    TILE_ID_FIELD_NUMBER: _ClassVar[int]
    BLOCK_ID_FIELD_NUMBER: _ClassVar[int]
    CALIBRATION_BLOCK_FIELD_NUMBER: _ClassVar[int]
    tile_id: int
    block_id: int
    calibration_block: int
    def __init__(self, tile_id: _Optional[int] = ..., block_id: _Optional[int] = ..., calibration_block: _Optional[int] = ...) -> None: ...

class GetCalCoefficientsResponse(_message.Message):
    __slots__ = ("status", "coeffs")
    STATUS_FIELD_NUMBER: _ClassVar[int]
    COEFFS_FIELD_NUMBER: _ClassVar[int]
    status: Status
    coeffs: CalibrationCoefficients
    def __init__(self, status: _Optional[_Union[Status, _Mapping]] = ..., coeffs: _Optional[_Union[CalibrationCoefficients, _Mapping]] = ...) -> None: ...

class SetDACVOPRequest(_message.Message):
    __slots__ = ("tile_id", "block_id", "uA_current")
    TILE_ID_FIELD_NUMBER: _ClassVar[int]
    BLOCK_ID_FIELD_NUMBER: _ClassVar[int]
    UA_CURRENT_FIELD_NUMBER: _ClassVar[int]
    tile_id: int
    block_id: int
    uA_current: int
    def __init__(self, tile_id: _Optional[int] = ..., block_id: _Optional[int] = ..., uA_current: _Optional[int] = ...) -> None: ...

class PLLSettings(_message.Message):
    __slots__ = ("enabled", "ref_clk_freq", "sample_rate", "ref_clk_divider", "feedback_divider", "output_divider", "fractional_mode", "fractional_data", "fract_width")
    ENABLED_FIELD_NUMBER: _ClassVar[int]
    REF_CLK_FREQ_FIELD_NUMBER: _ClassVar[int]
    SAMPLE_RATE_FIELD_NUMBER: _ClassVar[int]
    REF_CLK_DIVIDER_FIELD_NUMBER: _ClassVar[int]
    FEEDBACK_DIVIDER_FIELD_NUMBER: _ClassVar[int]
    OUTPUT_DIVIDER_FIELD_NUMBER: _ClassVar[int]
    FRACTIONAL_MODE_FIELD_NUMBER: _ClassVar[int]
    FRACTIONAL_DATA_FIELD_NUMBER: _ClassVar[int]
    FRACT_WIDTH_FIELD_NUMBER: _ClassVar[int]
    enabled: int
    ref_clk_freq: float
    sample_rate: float
    ref_clk_divider: int
    feedback_divider: int
    output_divider: int
    fractional_mode: int
    fractional_data: int
    fract_width: int
    def __init__(self, enabled: _Optional[int] = ..., ref_clk_freq: _Optional[float] = ..., sample_rate: _Optional[float] = ..., ref_clk_divider: _Optional[int] = ..., feedback_divider: _Optional[int] = ..., output_divider: _Optional[int] = ..., fractional_mode: _Optional[int] = ..., fractional_data: _Optional[int] = ..., fract_width: _Optional[int] = ...) -> None: ...

class GetPLLConfigResponse(_message.Message):
    __slots__ = ("status", "settings")
    STATUS_FIELD_NUMBER: _ClassVar[int]
    SETTINGS_FIELD_NUMBER: _ClassVar[int]
    status: Status
    settings: PLLSettings
    def __init__(self, status: _Optional[_Union[Status, _Mapping]] = ..., settings: _Optional[_Union[PLLSettings, _Mapping]] = ...) -> None: ...

class GetClkDistributionRequest(_message.Message):
    __slots__ = ()
    def __init__(self) -> None: ...

class Distribution(_message.Message):
    __slots__ = ("source", "upper_bound", "lower_bound", "max_delay", "min_delay", "is_delay_balanced")
    SOURCE_FIELD_NUMBER: _ClassVar[int]
    UPPER_BOUND_FIELD_NUMBER: _ClassVar[int]
    LOWER_BOUND_FIELD_NUMBER: _ClassVar[int]
    MAX_DELAY_FIELD_NUMBER: _ClassVar[int]
    MIN_DELAY_FIELD_NUMBER: _ClassVar[int]
    IS_DELAY_BALANCED_FIELD_NUMBER: _ClassVar[int]
    source: int
    upper_bound: int
    lower_bound: int
    max_delay: int
    min_delay: int
    is_delay_balanced: int
    def __init__(self, source: _Optional[int] = ..., upper_bound: _Optional[int] = ..., lower_bound: _Optional[int] = ..., max_delay: _Optional[int] = ..., min_delay: _Optional[int] = ..., is_delay_balanced: _Optional[int] = ...) -> None: ...

class TileClockSettings(_message.Message):
    __slots__ = ("source_type", "source_tile", "pll_enable", "ref_clk_freq", "sample_rate", "division_factor", "distributed_clock", "delay")
    SOURCE_TYPE_FIELD_NUMBER: _ClassVar[int]
    SOURCE_TILE_FIELD_NUMBER: _ClassVar[int]
    PLL_ENABLE_FIELD_NUMBER: _ClassVar[int]
    REF_CLK_FREQ_FIELD_NUMBER: _ClassVar[int]
    SAMPLE_RATE_FIELD_NUMBER: _ClassVar[int]
    DIVISION_FACTOR_FIELD_NUMBER: _ClassVar[int]
    DISTRIBUTED_CLOCK_FIELD_NUMBER: _ClassVar[int]
    DELAY_FIELD_NUMBER: _ClassVar[int]
    source_type: int
    source_tile: int
    pll_enable: int
    ref_clk_freq: float
    sample_rate: float
    division_factor: int
    distributed_clock: int
    delay: int
    def __init__(self, source_type: _Optional[int] = ..., source_tile: _Optional[int] = ..., pll_enable: _Optional[int] = ..., ref_clk_freq: _Optional[float] = ..., sample_rate: _Optional[float] = ..., division_factor: _Optional[int] = ..., distributed_clock: _Optional[int] = ..., delay: _Optional[int] = ...) -> None: ...

class ClkDistributionSettings(_message.Message):
    __slots__ = ("dac", "adc", "distribution_info")
    DAC_FIELD_NUMBER: _ClassVar[int]
    ADC_FIELD_NUMBER: _ClassVar[int]
    DISTRIBUTION_INFO_FIELD_NUMBER: _ClassVar[int]
    dac: _containers.RepeatedCompositeFieldContainer[TileClockSettings]
    adc: _containers.RepeatedCompositeFieldContainer[TileClockSettings]
    distribution_info: Distribution
    def __init__(self, dac: _Optional[_Iterable[_Union[TileClockSettings, _Mapping]]] = ..., adc: _Optional[_Iterable[_Union[TileClockSettings, _Mapping]]] = ..., distribution_info: _Optional[_Union[Distribution, _Mapping]] = ...) -> None: ...

class GetClkDistributionResponse(_message.Message):
    __slots__ = ("status", "settings")
    STATUS_FIELD_NUMBER: _ClassVar[int]
    SETTINGS_FIELD_NUMBER: _ClassVar[int]
    status: Status
    settings: ClkDistributionSettings
    def __init__(self, status: _Optional[_Union[Status, _Mapping]] = ..., settings: _Optional[_Union[ClkDistributionSettings, _Mapping]] = ...) -> None: ...

class SetClkDistributionRequest(_message.Message):
    __slots__ = ("settings",)
    SETTINGS_FIELD_NUMBER: _ClassVar[int]
    settings: ClkDistributionSettings
    def __init__(self, settings: _Optional[_Union[ClkDistributionSettings, _Mapping]] = ...) -> None: ...
