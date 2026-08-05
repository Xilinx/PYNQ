#include "xrfdc.h"

// ============================================================================
// libxrfdcManager Implementation
// ============================================================================

libxrfdcManager::libxrfdcManager() : handle_(nullptr) {
    XRFdc_LookupConfig = nullptr;
    XRFdc_CfgInitialize = nullptr;
    XRFdc_GetIPStatus = nullptr;
    XRFdc_GetBlockStatus = nullptr;
    XRFdc_StartUp = nullptr;
    XRFdc_Shutdown = nullptr;
    XRFdc_Reset = nullptr;
    XRFdc_SetupFIFO = nullptr;
    XRFdc_DynamicPLLConfig = nullptr;
    XRFdc_GetFIFOStatus = nullptr;
    XRFdc_GetPLLLockStatus = nullptr;
    XRFdc_GetClockSource = nullptr;
    XRFdc_SetFabClkOutDiv = nullptr;
    XRFdc_GetFabClkOutDiv = nullptr;
    XRFdc_SetMixerSettings = nullptr;
    XRFdc_GetMixerSettings = nullptr;
    XRFdc_ResetNCOPhase = nullptr;
    XRFdc_SetNyquistZone = nullptr;
    XRFdc_GetNyquistZone = nullptr;
    XRFdc_SetInterpolationFactor = nullptr;
    XRFdc_GetInterpolationFactor = nullptr;
    XRFdc_SetDecimationFactor = nullptr;
    XRFdc_GetDecimationFactor = nullptr;
    XRFdc_SetQMCSettings = nullptr;
    XRFdc_GetQMCSettings = nullptr;
    XRFdc_SetThresholdSettings = nullptr;
    XRFdc_GetThresholdSettings = nullptr;

    // Initialize additional function pointers
    XRFdc_SetThresholdClrMode = nullptr;
    XRFdc_ThresholdStickyClear = nullptr;
    XRFdc_GetCoarseDelaySettings = nullptr;
    XRFdc_SetCoarseDelaySettings = nullptr;
    XRFdc_GetEnabledInterrupts = nullptr;
    XRFdc_GetPwrMode = nullptr;
    XRFdc_SetPwrMode = nullptr;
    XRFdc_UpdateEvent = nullptr;
    XRFdc_ResetInternalFIFOWidth = nullptr;
    XRFdc_GetConnectedIData = nullptr;
    XRFdc_GetConnectedQData = nullptr;
    XRFdc_GetCalibrationMode = nullptr;
    XRFdc_SetCalibrationMode = nullptr;
    XRFdc_GetFabRdVldWords = nullptr;
    XRFdc_SetFabRdVldWords = nullptr;
    XRFdc_GetFabWrVldWords = nullptr;
    XRFdc_SetFabWrVldWords = nullptr;
    XRFdc_GetDecimationFactorObs = nullptr;
    XRFdc_SetDecimationFactorObs = nullptr;
    XRFdc_GetFabRdVldWordsObs = nullptr;
    XRFdc_SetFabRdVldWordsObs = nullptr;
    XRFdc_GetFabWrVldWordsObs = nullptr;
    XRFdc_GetDither = nullptr;
    XRFdc_SetDither = nullptr;
    XRFdc_GetCalFreeze = nullptr;
    XRFdc_SetCalFreeze = nullptr;
    XRFdc_GetDSA = nullptr;
    XRFdc_SetDSA = nullptr;
    XRFdc_DisableCoefficientsOverride = nullptr;
    XRFdc_ResetInternalFIFOWidthObs = nullptr;
    XRFdc_SetCalCoefficients = nullptr;
    XRFdc_GetCalCoefficients = nullptr;
    XRFdc_GetDecoderMode = nullptr;
    XRFdc_SetDecoderMode = nullptr;
    XRFdc_GetOutputCurr = nullptr;
    XRFdc_GetInvSincFIR = nullptr;
    XRFdc_SetInvSincFIR = nullptr;
    XRFdc_GetDataPathMode = nullptr;
    XRFdc_SetDataPathMode = nullptr;
    XRFdc_GetIMRPassMode = nullptr;
    XRFdc_SetIMRPassMode = nullptr;
    XRFdc_GetDACCompMode = nullptr;
    XRFdc_SetDACCompMode = nullptr;
    XRFdc_SetDACVOP = nullptr;
    XRFdc_DumpRegs = nullptr;
    XRFdc_GetPLLConfig = nullptr;
    XRFdc_SetupFIFOObs = nullptr;
    XRFdc_SetupFIFOBoth = nullptr;
    XRFdc_GetFIFOStatusObs = nullptr;
    XRFdc_GetClkDistribution = nullptr;
    XRFdc_SetClkDistribution = nullptr;
}

libxrfdcManager::~libxrfdcManager() {
    unloadLibrary();
}

void libxrfdcManager::loadLibrary() {
#ifdef DEBUG
    std::cout << "Loading librfdc.so..." << std::endl;
#endif

    handle_ = dlopen("librfdc.so", RTLD_LAZY);
    if (!handle_) {
        throw std::runtime_error(std::string("Failed to load librfdc.so: ") + dlerror());
    }

    // Load function pointers
    XRFdc_LookupConfig = (XRFdc_LookupConfig_t)dlsym(handle_, "XRFdc_LookupConfig");
    XRFdc_CfgInitialize = (XRFdc_CfgInitialize_t)dlsym(handle_, "XRFdc_CfgInitialize");
    XRFdc_GetIPStatus = (XRFdc_GetIPStatus_t)dlsym(handle_, "XRFdc_GetIPStatus");
    XRFdc_GetBlockStatus = (XRFdc_GetBlockStatus_t)dlsym(handle_, "XRFdc_GetBlockStatus");
    XRFdc_StartUp = (XRFdc_StartUp_t)dlsym(handle_, "XRFdc_StartUp");
    XRFdc_Shutdown = (XRFdc_Shutdown_t)dlsym(handle_, "XRFdc_Shutdown");
    XRFdc_Reset = (XRFdc_Reset_t)dlsym(handle_, "XRFdc_Reset");
    XRFdc_SetupFIFO = (XRFdc_SetupFIFO_t)dlsym(handle_, "XRFdc_SetupFIFO");
    XRFdc_DynamicPLLConfig = (XRFdc_DynamicPLLConfig_t)dlsym(handle_, "XRFdc_DynamicPLLConfig");
    XRFdc_GetFIFOStatus = (XRFdc_GetFIFOStatus_t)dlsym(handle_, "XRFdc_GetFIFOStatus");
    XRFdc_GetPLLLockStatus = (XRFdc_GetPLLLockStatus_t)dlsym(handle_, "XRFdc_GetPLLLockStatus");
    XRFdc_GetClockSource = (XRFdc_GetClockSource_t)dlsym(handle_, "XRFdc_GetClockSource");
    XRFdc_SetFabClkOutDiv = (XRFdc_SetFabClkOutDiv_t)dlsym(handle_, "XRFdc_SetFabClkOutDiv");
    XRFdc_GetFabClkOutDiv = (XRFdc_GetFabClkOutDiv_t)dlsym(handle_, "XRFdc_GetFabClkOutDiv");
    XRFdc_SetMixerSettings = (XRFdc_SetMixerSettings_t)dlsym(handle_, "XRFdc_SetMixerSettings");
    XRFdc_GetMixerSettings = (XRFdc_GetMixerSettings_t)dlsym(handle_, "XRFdc_GetMixerSettings");
    XRFdc_ResetNCOPhase = (XRFdc_ResetNCOPhase_t)dlsym(handle_, "XRFdc_ResetNCOPhase");
    XRFdc_SetNyquistZone = (XRFdc_SetNyquistZone_t)dlsym(handle_, "XRFdc_SetNyquistZone");
    XRFdc_GetNyquistZone = (XRFdc_GetNyquistZone_t)dlsym(handle_, "XRFdc_GetNyquistZone");
    XRFdc_SetInterpolationFactor = (XRFdc_SetInterpolationFactor_t)dlsym(handle_, "XRFdc_SetInterpolationFactor");
    XRFdc_GetInterpolationFactor = (XRFdc_GetInterpolationFactor_t)dlsym(handle_, "XRFdc_GetInterpolationFactor");
    XRFdc_SetDecimationFactor = (XRFdc_SetDecimationFactor_t)dlsym(handle_, "XRFdc_SetDecimationFactor");
    XRFdc_GetDecimationFactor = (XRFdc_GetDecimationFactor_t)dlsym(handle_, "XRFdc_GetDecimationFactor");
    XRFdc_SetQMCSettings = (XRFdc_SetQMCSettings_t)dlsym(handle_, "XRFdc_SetQMCSettings");
    XRFdc_GetQMCSettings = (XRFdc_GetQMCSettings_t)dlsym(handle_, "XRFdc_GetQMCSettings");
    XRFdc_SetThresholdSettings = (XRFdc_SetThresholdSettings_t)dlsym(handle_, "XRFdc_SetThresholdSettings");
    XRFdc_GetThresholdSettings = (XRFdc_GetThresholdSettings_t)dlsym(handle_, "XRFdc_GetThresholdSettings");

    // Load additional function pointers (these may not all exist in older library versions)
    XRFdc_SetThresholdClrMode = (XRFdc_SetThresholdClrMode_t)dlsym(handle_, "XRFdc_SetThresholdClrMode");
    XRFdc_ThresholdStickyClear = (XRFdc_ThresholdStickyClear_t)dlsym(handle_, "XRFdc_ThresholdStickyClear");
    XRFdc_GetCoarseDelaySettings = (XRFdc_GetCoarseDelaySettings_t)dlsym(handle_, "XRFdc_GetCoarseDelaySettings");
    XRFdc_SetCoarseDelaySettings = (XRFdc_SetCoarseDelaySettings_t)dlsym(handle_, "XRFdc_SetCoarseDelaySettings");
    XRFdc_GetEnabledInterrupts = (XRFdc_GetEnabledInterrupts_t)dlsym(handle_, "XRFdc_GetEnabledInterrupts");
    XRFdc_GetPwrMode = (XRFdc_GetPwrMode_t)dlsym(handle_, "XRFdc_GetPwrMode");
    XRFdc_SetPwrMode = (XRFdc_SetPwrMode_t)dlsym(handle_, "XRFdc_SetPwrMode");
    XRFdc_UpdateEvent = (XRFdc_UpdateEvent_t)dlsym(handle_, "XRFdc_UpdateEvent");
    XRFdc_ResetInternalFIFOWidth = (XRFdc_ResetInternalFIFOWidth_t)dlsym(handle_, "XRFdc_ResetInternalFIFOWidth");
    XRFdc_GetConnectedIData = (XRFdc_GetConnectedIData_t)dlsym(handle_, "XRFdc_GetConnectedIData");
    XRFdc_GetConnectedQData = (XRFdc_GetConnectedQData_t)dlsym(handle_, "XRFdc_GetConnectedQData");
    XRFdc_GetCalibrationMode = (XRFdc_GetCalibrationMode_t)dlsym(handle_, "XRFdc_GetCalibrationMode");
    XRFdc_SetCalibrationMode = (XRFdc_SetCalibrationMode_t)dlsym(handle_, "XRFdc_SetCalibrationMode");
    XRFdc_GetFabRdVldWords = (XRFdc_GetFabRdVldWords_t)dlsym(handle_, "XRFdc_GetFabRdVldWords");
    XRFdc_SetFabRdVldWords = (XRFdc_SetFabRdVldWords_t)dlsym(handle_, "XRFdc_SetFabRdVldWords");
    XRFdc_GetFabWrVldWords = (XRFdc_GetFabWrVldWords_t)dlsym(handle_, "XRFdc_GetFabWrVldWords");
    XRFdc_SetFabWrVldWords = (XRFdc_SetFabWrVldWords_t)dlsym(handle_, "XRFdc_SetFabWrVldWords");
    XRFdc_GetDecimationFactorObs = (XRFdc_GetDecimationFactorObs_t)dlsym(handle_, "XRFdc_GetDecimationFactorObs");
    XRFdc_SetDecimationFactorObs = (XRFdc_SetDecimationFactorObs_t)dlsym(handle_, "XRFdc_SetDecimationFactorObs");
    XRFdc_GetFabRdVldWordsObs = (XRFdc_GetFabRdVldWordsObs_t)dlsym(handle_, "XRFdc_GetFabRdVldWordsObs");
    XRFdc_SetFabRdVldWordsObs = (XRFdc_SetFabRdVldWordsObs_t)dlsym(handle_, "XRFdc_SetFabRdVldWordsObs");
    XRFdc_GetFabWrVldWordsObs = (XRFdc_GetFabWrVldWordsObs_t)dlsym(handle_, "XRFdc_GetFabWrVldWordsObs");
    XRFdc_GetDither = (XRFdc_GetDither_t)dlsym(handle_, "XRFdc_GetDither");
    XRFdc_SetDither = (XRFdc_SetDither_t)dlsym(handle_, "XRFdc_SetDither");
    XRFdc_GetCalFreeze = (XRFdc_GetCalFreeze_t)dlsym(handle_, "XRFdc_GetCalFreeze");
    XRFdc_SetCalFreeze = (XRFdc_SetCalFreeze_t)dlsym(handle_, "XRFdc_SetCalFreeze");
    XRFdc_GetDSA = (XRFdc_GetDSA_t)dlsym(handle_, "XRFdc_GetDSA");
    XRFdc_SetDSA = (XRFdc_SetDSA_t)dlsym(handle_, "XRFdc_SetDSA");
    XRFdc_DisableCoefficientsOverride = (XRFdc_DisableCoefficientsOverride_t)dlsym(handle_, "XRFdc_DisableCoefficientsOverride");
    XRFdc_ResetInternalFIFOWidthObs = (XRFdc_ResetInternalFIFOWidthObs_t)dlsym(handle_, "XRFdc_ResetInternalFIFOWidthObs");
    XRFdc_SetCalCoefficients = (XRFdc_SetCalCoefficients_t)dlsym(handle_, "XRFdc_SetCalCoefficients");
    XRFdc_GetCalCoefficients = (XRFdc_GetCalCoefficients_t)dlsym(handle_, "XRFdc_GetCalCoefficients");
    XRFdc_GetDecoderMode = (XRFdc_GetDecoderMode_t)dlsym(handle_, "XRFdc_GetDecoderMode");
    XRFdc_SetDecoderMode = (XRFdc_SetDecoderMode_t)dlsym(handle_, "XRFdc_SetDecoderMode");
    XRFdc_GetOutputCurr = (XRFdc_GetOutputCurr_t)dlsym(handle_, "XRFdc_GetOutputCurr");
    XRFdc_GetInvSincFIR = (XRFdc_GetInvSincFIR_t)dlsym(handle_, "XRFdc_GetInvSincFIR");
    XRFdc_SetInvSincFIR = (XRFdc_SetInvSincFIR_t)dlsym(handle_, "XRFdc_SetInvSincFIR");
    XRFdc_GetDataPathMode = (XRFdc_GetDataPathMode_t)dlsym(handle_, "XRFdc_GetDataPathMode");
    XRFdc_SetDataPathMode = (XRFdc_SetDataPathMode_t)dlsym(handle_, "XRFdc_SetDataPathMode");
    XRFdc_GetIMRPassMode = (XRFdc_GetIMRPassMode_t)dlsym(handle_, "XRFdc_GetIMRPassMode");
    XRFdc_SetIMRPassMode = (XRFdc_SetIMRPassMode_t)dlsym(handle_, "XRFdc_SetIMRPassMode");
    XRFdc_GetDACCompMode = (XRFdc_GetDACCompMode_t)dlsym(handle_, "XRFdc_GetDACCompMode");
    XRFdc_SetDACCompMode = (XRFdc_SetDACCompMode_t)dlsym(handle_, "XRFdc_SetDACCompMode");
    XRFdc_SetDACVOP = (XRFdc_SetDACVOP_t)dlsym(handle_, "XRFdc_SetDACVOP");
    XRFdc_DumpRegs = (XRFdc_DumpRegs_t)dlsym(handle_, "XRFdc_DumpRegs");
    XRFdc_GetPLLConfig = (XRFdc_GetPLLConfig_t)dlsym(handle_, "XRFdc_GetPLLConfig");
    XRFdc_SetupFIFOObs = (XRFdc_SetupFIFOObs_t)dlsym(handle_, "XRFdc_SetupFIFOObs");
    XRFdc_SetupFIFOBoth = (XRFdc_SetupFIFOBoth_t)dlsym(handle_, "XRFdc_SetupFIFOBoth");
    XRFdc_GetFIFOStatusObs = (XRFdc_GetFIFOStatusObs_t)dlsym(handle_, "XRFdc_GetFIFOStatusObs");
    XRFdc_GetClkDistribution = (XRFdc_GetClkDistribution_t)dlsym(handle_, "XRFdc_GetClkDistribution");
    XRFdc_SetClkDistribution = (XRFdc_SetClkDistribution_t)dlsym(handle_, "XRFdc_SetClkDistribution");

    if (!XRFdc_LookupConfig || !XRFdc_CfgInitialize ||
        !XRFdc_GetIPStatus || !XRFdc_GetBlockStatus ||
        !XRFdc_StartUp || !XRFdc_Shutdown || !XRFdc_Reset ||
        !XRFdc_SetupFIFO || !XRFdc_DynamicPLLConfig) {
        unloadLibrary();
        throw std::runtime_error("Failed to load required XRFdc functions");
    }

#ifdef DEBUG
    std::cout << "librfdc.so loaded successfully" << std::endl;
#endif
}

void libxrfdcManager::unloadLibrary() {
    if (handle_) {
#ifdef DEBUG
        std::cout << "Unloading librfdc.so..." << std::endl;
#endif
        dlclose(handle_);
        handle_ = nullptr;
    }
}

// ============================================================================
// XrfdcRemote Implementation
// ============================================================================

XrfdcRemote::XrfdcRemote()
    : rfdc_inst_(nullptr), config_(nullptr), device_id_(0),
      io_(nullptr), mem_fd_(-1), mapped_base_(nullptr), mapped_size_(0) {
#ifdef DEBUG
    std::cout << "XrfdcRemote: Loading librfdc.so" << std::endl;
#endif
    lib_manager_.loadLibrary();
#ifdef DEBUG
    std::cout << "XrfdcRemote initialized" << std::endl;
#endif
}

XrfdcRemote::~XrfdcRemote() {
#ifdef DEBUG
    std::cout << "XrfdcRemote: Unloading library" << std::endl;
#endif
    cleanup();
    lib_manager_.unloadLibrary();
#ifdef DEBUG
    std::cout << "XrfdcRemote destroyed" << std::endl;
#endif
}

void XrfdcRemote::cleanup() {
    if (config_) {
        free(config_);
        config_ = nullptr;
    }
    if (rfdc_inst_) {
        free(rfdc_inst_);
        rfdc_inst_ = nullptr;
    }
    if (io_) {
        free(io_);
        io_ = nullptr;
    }
    if (mapped_base_ && mapped_size_ > 0) {
        munmap(mapped_base_, mapped_size_);
        mapped_base_ = nullptr;
    }
    mapped_size_ = 0;
    if (mem_fd_ >= 0) {
        close(mem_fd_);
        mem_fd_ = -1;
    }
}

void XrfdcRemote::Invalidate() {
    cleanup();
}

struct metal_io_region* XrfdcRemote::create_io_region_from_devmem(
    void *virt_addr, uint64_t phys_addr, size_t size) {
    struct metal_io_region *io;
    metal_phys_addr_t phys = phys_addr;

    io = (struct metal_io_region*)malloc(sizeof(struct metal_io_region));
    if (!io) return nullptr;

    metal_io_init(io, virt_addr, &phys, size,
                  sizeof(metal_phys_addr_t) << 3, 0, nullptr);

    return io;
}

XRFdc_Config* XrfdcRemote::ConvertProtoToConfig(const xrfdc::RFdcConfig& proto_config) {
    XRFdc_Config *Config = (XRFdc_Config*)malloc(sizeof(XRFdc_Config));
    if (!Config) return nullptr;

    memset(Config, 0, sizeof(XRFdc_Config));

    // Top-level configuration
    Config->DeviceId = proto_config.device_id();
    Config->BaseAddr = proto_config.base_addr();
    Config->ADCType = proto_config.adc_type();
    Config->MasterADCTile = proto_config.master_adc_tile();
    Config->MasterDACTile = proto_config.master_dac_tile();
    Config->ADCSysRefSource = proto_config.adc_sysref_source();
    Config->DACSysRefSource = proto_config.dac_sysref_source();
    Config->IPType = proto_config.ip_type();
    Config->SiRevision = proto_config.si_revision();

    // DAC Tile configurations (4 tiles)
    for (int tile = 0; tile < 4 && tile < proto_config.dac_tile_config_size(); tile++) {
        const xrfdc::DACTileConfig& proto_tile = proto_config.dac_tile_config(tile);
        XRFdc_DACTile_Config& c_tile = Config->DACTile_Config[tile];

        // Tile-level fields
        c_tile.Enable = proto_tile.enable();
        c_tile.PLLEnable = proto_tile.pll_enable();
        c_tile.SamplingRate = proto_tile.sampling_rate();
        c_tile.RefClkFreq = proto_tile.ref_clk_freq();
        c_tile.FabClkFreq = proto_tile.fab_clk_freq();
        c_tile.FeedbackDiv = proto_tile.feedback_div();
        c_tile.OutputDiv = proto_tile.output_div();
        c_tile.RefClkDiv = proto_tile.ref_clk_div();
        c_tile.MultibandConfig = proto_tile.multiband_config();
        c_tile.MaxSampleRate = proto_tile.max_sample_rate();
        c_tile.NumSlices = proto_tile.num_slices();

        // DAC Block Analog config (4 blocks per tile)
        for (int block = 0; block < 4 && block < proto_tile.dac_block_analog_config_size(); block++) {
            const xrfdc::DACBlockAnalogDataPathConfig& proto_analog = proto_tile.dac_block_analog_config(block);
            XRFdc_DACBlock_AnalogDataPath_Config& c_analog = c_tile.DACBlock_Analog_Config[block];

            c_analog.BlockAvailable = proto_analog.block_available();
            c_analog.InvSyncEnable = proto_analog.inv_sync_enable();
            c_analog.MixMode = proto_analog.mix_mode();
            c_analog.DecoderMode = proto_analog.decoder_mode();
        }

        // DAC Block Digital config (4 blocks per tile)
        for (int block = 0; block < 4 && block < proto_tile.dac_block_digital_config_size(); block++) {
            const xrfdc::DACBlockDigitalDataPathConfig& proto_digital = proto_tile.dac_block_digital_config(block);
            XRFdc_DACBlock_DigitalDataPath_Config& c_digital = c_tile.DACBlock_Digital_Config[block];

            c_digital.MixerInputDataType = proto_digital.mixer_input_data_type();
            c_digital.DataWidth = proto_digital.data_width();
            c_digital.InterpolationMode = proto_digital.interpolation_mode();
            c_digital.FifoEnable = proto_digital.fifo_enable();
            c_digital.AdderEnable = proto_digital.adder_enable();
            c_digital.MixerType = proto_digital.mixer_type();
        }
    }

    // ADC Tile configurations (4 tiles)
    for (int tile = 0; tile < 4 && tile < proto_config.adc_tile_config_size(); tile++) {
        const xrfdc::ADCTileConfig& proto_tile = proto_config.adc_tile_config(tile);
        XRFdc_ADCTile_Config& c_tile = Config->ADCTile_Config[tile];

        // Tile-level fields
        c_tile.Enable = proto_tile.enable();
        c_tile.PLLEnable = proto_tile.pll_enable();
        c_tile.SamplingRate = proto_tile.sampling_rate();
        c_tile.RefClkFreq = proto_tile.ref_clk_freq();
        c_tile.FabClkFreq = proto_tile.fab_clk_freq();
        c_tile.FeedbackDiv = proto_tile.feedback_div();
        c_tile.OutputDiv = proto_tile.output_div();
        c_tile.RefClkDiv = proto_tile.ref_clk_div();
        c_tile.MultibandConfig = proto_tile.multiband_config();
        c_tile.MaxSampleRate = proto_tile.max_sample_rate();
        c_tile.NumSlices = proto_tile.num_slices();

        // ADC Block Analog config (4 blocks per tile)
        for (int block = 0; block < 4 && block < proto_tile.adc_block_analog_config_size(); block++) {
            const xrfdc::ADCBlockAnalogDataPathConfig& proto_analog = proto_tile.adc_block_analog_config(block);
            XRFdc_ADCBlock_AnalogDataPath_Config& c_analog = c_tile.ADCBlock_Analog_Config[block];

            c_analog.BlockAvailable = proto_analog.block_available();
            c_analog.MixMode = proto_analog.mix_mode();
        }

        // ADC Block Digital config (4 blocks per tile)
        for (int block = 0; block < 4 && block < proto_tile.adc_block_digital_config_size(); block++) {
            const xrfdc::ADCBlockDigitalDataPathConfig& proto_digital = proto_tile.adc_block_digital_config(block);
            XRFdc_ADCBlock_DigitalDataPath_Config& c_digital = c_tile.ADCBlock_Digital_Config[block];

            c_digital.MixerInputDataType = proto_digital.mixer_input_data_type();
            c_digital.DataWidth = proto_digital.data_width();
            c_digital.DecimationMode = proto_digital.decimation_mode();
            c_digital.FifoEnable = proto_digital.fifo_enable();
            c_digital.MixerType = proto_digital.mixer_type();
        }
    }

    return Config;
}

// ============================================================================
// Helper Functions: C Structures -> Protobuf Messages
// ============================================================================

void XrfdcRemote::ConvertBlockStatus(const XRFdc_BlockStatus& c_block, xrfdc::BlockStatus* proto_block) {
    proto_block->set_sampling_freq(c_block.SamplingFreq);
    proto_block->set_analog_data_path_status(c_block.AnalogDataPathStatus);
    proto_block->set_digital_data_path_status(c_block.DigitalDataPathStatus);
    proto_block->set_data_path_clocks_status(c_block.DataPathClocksStatus);
    proto_block->set_is_fifo_flags_enabled(c_block.IsFIFOFlagsEnabled);
    proto_block->set_is_fifo_flags_asserted(c_block.IsFIFOFlagsAsserted);
}

void XrfdcRemote::ConvertTileStatus(const XRFdc_TileStatus& c_tile,
                                     xrfdc::TileStatus* proto_tile,
                                     u32 tile_type, u32 tile_id) {
    proto_tile->set_is_enabled(c_tile.IsEnabled != 0);
    proto_tile->set_tile_state(static_cast<u32>(c_tile.TileState));
    proto_tile->set_block_status_mask(c_tile.BlockStatusMask);
    proto_tile->set_power_up_state(c_tile.PowerUpState);
    proto_tile->set_pll_state(static_cast<u32>(c_tile.PLLState));

    // Get detailed block status for each active block
    for (int block = 0; block < 4; block++) {
        if (c_tile.BlockStatusMask & (1 << block)) {
            XRFdc_BlockStatus BlockStatus;
            int ret = lib_manager_.XRFdc_GetBlockStatus(rfdc_inst_, tile_type, tile_id, block, &BlockStatus);
            if (ret == XRFDC_SUCCESS) {
                xrfdc::BlockStatus* proto_block = proto_tile->add_block_status();
                ConvertBlockStatus(BlockStatus, proto_block);
            }
        }
    }
}

void XrfdcRemote::ConvertIPStatus(const XRFdc_IPStatus& c_status, xrfdc::IPStatus* proto_status) {
    // Convert 4 DAC tiles
    for (int i = 0; i < 4; i++) {
        xrfdc::TileStatus* dac_tile = proto_status->add_dac_tile_status();
        ConvertTileStatus(c_status.DACTileStatus[i], dac_tile, XRFDC_DAC_TILE, i);
    }

    // Convert 4 ADC tiles
    for (int i = 0; i < 4; i++) {
        xrfdc::TileStatus* adc_tile = proto_status->add_adc_tile_status();
        ConvertTileStatus(c_status.ADCTileStatus[i], adc_tile, XRFDC_ADC_TILE, i);
    }

    // Set overall IP state
    proto_status->set_state(c_status.State);
}

void XrfdcRemote::CfgInitialize(const xrfdc::CfgInitializeRequest& request) {
    cleanup();

    try {
        const auto& proto_config = request.config();
        u32 base_addr = proto_config.base_addr();

        // Get size from request, default to 256KB if not provided
        u32 size = request.size() > 0 ? request.size() : 0x40000;

#ifdef DEBUG
        std::cout << "CfgInitialize called with base_addr: 0x"
                  << std::hex << base_addr
                  << " size: 0x" << size << std::dec << std::endl;
#endif

        // Store the size for cleanup
        mapped_size_ = size;

        // Open /dev/mem
        mem_fd_ = open("/dev/mem", O_RDWR | O_SYNC);
        if (mem_fd_ == -1) {
            throw std::runtime_error("Failed to open /dev/mem");
        }

        // Map RFDC registers with dynamic size
        mapped_base_ = mmap(nullptr, size, PROT_READ | PROT_WRITE, MAP_SHARED, mem_fd_, base_addr);
        if (mapped_base_ == MAP_FAILED) {
            mapped_base_ = nullptr;
            throw std::runtime_error("Failed to map RFDC registers");
        }

        // Create libmetal I/O region with dynamic size
        io_ = create_io_region_from_devmem(mapped_base_, base_addr, size);
        if (!io_) {
            throw std::runtime_error("Failed to create I/O region");
        }

        // Prepare RFDC instance
        rfdc_inst_ = (XRFdc*)malloc(sizeof(XRFdc));
        if (!rfdc_inst_) {
            throw std::runtime_error("Failed to allocate RFDC instance");
        }
        memset(rfdc_inst_, 0, sizeof(XRFdc));
        rfdc_inst_->io = io_;
        rfdc_inst_->BaseAddr = base_addr;

        // Convert protobuf config to C structure
        config_ = ConvertProtoToConfig(proto_config);
        if (!config_) {
            throw std::runtime_error("Failed to convert protobuf configuration");
        }

        // Initialize RFDC driver
        int status = lib_manager_.XRFdc_CfgInitialize(rfdc_inst_, config_);
        if (status != XRFDC_SUCCESS) {
            throw std::runtime_error("XRFdc_CfgInitialize failed with code " +
                                     std::to_string(status));
        }
    } catch (...) {
        cleanup();
        throw;
    }

#ifdef DEBUG
    std::cout << "CfgInitialize successful" << std::endl;
#endif
}

xrfdc::IPStatus XrfdcRemote::GetIPStatus(){
#ifdef DEBUG
    std::cout << "GetIPStatus called" << std::endl;
#endif

    if (!rfdc_inst_) {
        throw std::runtime_error("RFDC not initialized. Call CfgInitialize first.");
    }

    XRFdc_IPStatus c_status;
    memset(&c_status, 0, sizeof(XRFdc_IPStatus));

    int status = lib_manager_.XRFdc_GetIPStatus(rfdc_inst_, &c_status);
    if (status != XRFDC_SUCCESS) {
        throw std::runtime_error("XRFdc_GetIPStatus failed with code " + std::to_string(status));
    }

    xrfdc::IPStatus proto_status;
    ConvertIPStatus(c_status, &proto_status);

#ifdef DEBUG
    std::cout << "GetIPStatus successful" << std::endl;
#endif

    return proto_status;
}

// ============================================================================
// Tile Control Methods
// ============================================================================

int XrfdcRemote::StartUp(u32 tile_type, u32 tile_id) {
#ifdef DEBUG
    std::cout << "StartUp called: type=" << tile_type << " id=" << tile_id << std::endl;
#endif

    if (!rfdc_inst_) {
        throw std::runtime_error("RFDC not initialized. Call CfgInitialize first.");
    }

    int status = lib_manager_.XRFdc_StartUp(rfdc_inst_, tile_type, tile_id);

#ifdef DEBUG
    std::cout << "StartUp returned: " << status << std::endl;
#endif

    return status;
}

int XrfdcRemote::Shutdown(u32 tile_type, u32 tile_id) {
#ifdef DEBUG
    std::cout << "Shutdown called: type=" << tile_type << " id=" << tile_id << std::endl;
#endif

    if (!rfdc_inst_) {
        throw std::runtime_error("RFDC not initialized. Call CfgInitialize first.");
    }

    int status = lib_manager_.XRFdc_Shutdown(rfdc_inst_, tile_type, tile_id);

#ifdef DEBUG
    std::cout << "Shutdown returned: " << status << std::endl;
#endif

    return status;
}

int XrfdcRemote::Reset(u32 tile_type, u32 tile_id) {
#ifdef DEBUG
    std::cout << "Reset called: type=" << tile_type << " id=" << tile_id << std::endl;
#endif

    if (!rfdc_inst_) {
        throw std::runtime_error("RFDC not initialized. Call CfgInitialize first.");
    }

    int status = lib_manager_.XRFdc_Reset(rfdc_inst_, tile_type, tile_id);

#ifdef DEBUG
    std::cout << "Reset returned: " << status << std::endl;
#endif

    return status;
}

int XrfdcRemote::SetupFIFO(u32 tile_type, u32 tile_id, bool enable) {
#ifdef DEBUG
    std::cout << "SetupFIFO called: type=" << tile_type << " id=" << tile_id
              << " enable=" << enable << std::endl;
#endif

    if (!rfdc_inst_) {
        throw std::runtime_error("RFDC not initialized. Call CfgInitialize first.");
    }

    int status = lib_manager_.XRFdc_SetupFIFO(rfdc_inst_, tile_type, tile_id,
                                              enable ? 1 : 0);

#ifdef DEBUG
    std::cout << "SetupFIFO returned: " << status << std::endl;
#endif

    return status;
}

int XrfdcRemote::DynamicPLLConfig(u32 tile_type, u32 tile_id,
                                  u32 source, double ref_clk_freq,
                                  double samp_rate) {
#ifdef DEBUG
    std::cout << "DynamicPLLConfig called: type=" << tile_type << " id=" << tile_id
              << " source=" << source << " ref_clk=" << ref_clk_freq
              << " samp_rate=" << samp_rate << std::endl;
#endif

    if (!rfdc_inst_) {
        throw std::runtime_error("RFDC not initialized. Call CfgInitialize first.");
    }

    int status = lib_manager_.XRFdc_DynamicPLLConfig(rfdc_inst_, tile_type, tile_id,
                                                     source, ref_clk_freq, samp_rate);

#ifdef DEBUG
    std::cout << "DynamicPLLConfig returned: " << status << std::endl;
#endif

    return status;
}

// ============================================================================
// Status/Monitoring Methods
// ============================================================================

int XrfdcRemote::GetBlockStatus(u32 tile_type, u32 tile_id,
                                u32 block_id, XRFdc_BlockStatus* block_status) {
#ifdef DEBUG
    std::cout << "GetBlockStatus called: type=" << tile_type << " tile=" << tile_id
              << " block=" << block_id << std::endl;
#endif

    if (!rfdc_inst_) {
        throw std::runtime_error("RFDC not initialized. Call CfgInitialize first.");
    }

    if (!lib_manager_.XRFdc_GetBlockStatus || !block_status) {
        return XRFDC_FAILURE;
    }

    int status = lib_manager_.XRFdc_GetBlockStatus(rfdc_inst_, tile_type, tile_id,
                                                   block_id, block_status);

#ifdef DEBUG
    std::cout << "GetBlockStatus returned: " << status << std::endl;
#endif

    return status;
}

int XrfdcRemote::GetFIFOStatus(u32 tile_type, u32 tile_id,
                               u32 block_id, bool* enable) {
#ifdef DEBUG
    std::cout << "GetFIFOStatus called: type=" << tile_type << " tile=" << tile_id
              << " block=" << block_id << std::endl;
#endif

    if (!rfdc_inst_) {
        throw std::runtime_error("RFDC not initialized. Call CfgInitialize first.");
    }

    if (!lib_manager_.XRFdc_GetFIFOStatus) {
        return XRFDC_FAILURE;
    }

    uint8_t enable_u8 = 0;
    int status = lib_manager_.XRFdc_GetFIFOStatus(rfdc_inst_, tile_type, tile_id, &enable_u8);
    if (enable) {
        *enable = (enable_u8 != 0);
    }

#ifdef DEBUG
    std::cout << "GetFIFOStatus returned: " << status << " enable=" << (int)enable_u8 << std::endl;
#endif

    return status;
}

int XrfdcRemote::GetPLLLockStatus(u32 tile_type, u32 tile_id, u32* lock_status) {
#ifdef DEBUG
    std::cout << "GetPLLLockStatus called: type=" << tile_type << " tile=" << tile_id << std::endl;
#endif

    if (!rfdc_inst_) {
        throw std::runtime_error("RFDC not initialized. Call CfgInitialize first.");
    }

    if (!lib_manager_.XRFdc_GetPLLLockStatus || !lock_status) {
        return XRFDC_FAILURE;
    }

    *lock_status = 0;
    int status = lib_manager_.XRFdc_GetPLLLockStatus(rfdc_inst_, tile_type, tile_id, lock_status);

#ifdef DEBUG
    std::cout << "GetPLLLockStatus returned: " << status << " lock_status=" << *lock_status << std::endl;
#endif

    return status;
}

int XrfdcRemote::GetClockSource(u32 tile_type, u32 tile_id, u32* clock_source) {
#ifdef DEBUG
    std::cout << "GetClockSource called: type=" << tile_type << " tile=" << tile_id << std::endl;
#endif

    if (!rfdc_inst_) {
        throw std::runtime_error("RFDC not initialized. Call CfgInitialize first.");
    }

    if (!lib_manager_.XRFdc_GetClockSource || !clock_source) {
        return XRFDC_FAILURE;
    }

    *clock_source = 0;
    int status = lib_manager_.XRFdc_GetClockSource(rfdc_inst_, tile_type, tile_id, clock_source);

#ifdef DEBUG
    std::cout << "GetClockSource returned: " << status << " clock_source=" << *clock_source << std::endl;
#endif

    return status;
}

// ============================================================================
// Clock Configuration Methods
// ============================================================================

int XrfdcRemote::SetFabClkOutDiv(u32 tile_type, u32 tile_id, u32 fab_clk_div) {
#ifdef DEBUG
    std::cout << "SetFabClkOutDiv called: type=" << tile_type << " tile=" << tile_id
              << " div=" << fab_clk_div << std::endl;
#endif

    if (!rfdc_inst_) {
        throw std::runtime_error("RFDC not initialized. Call CfgInitialize first.");
    }

    if (!lib_manager_.XRFdc_SetFabClkOutDiv) {
        return XRFDC_FAILURE;
    }

    int status = lib_manager_.XRFdc_SetFabClkOutDiv(rfdc_inst_, tile_type, tile_id,
                                                    static_cast<uint16_t>(fab_clk_div));

#ifdef DEBUG
    std::cout << "SetFabClkOutDiv returned: " << status << std::endl;
#endif

    return status;
}

int XrfdcRemote::GetFabClkOutDiv(u32 tile_type, u32 tile_id, u32* fab_clk_div) {
#ifdef DEBUG
    std::cout << "GetFabClkOutDiv called: type=" << tile_type << " tile=" << tile_id << std::endl;
#endif

    if (!rfdc_inst_) {
        throw std::runtime_error("RFDC not initialized. Call CfgInitialize first.");
    }

    if (!lib_manager_.XRFdc_GetFabClkOutDiv) {
        return XRFDC_FAILURE;
    }

    uint16_t div_u16 = 0;
    int status = lib_manager_.XRFdc_GetFabClkOutDiv(rfdc_inst_, tile_type, tile_id, &div_u16);
    if (fab_clk_div) {
        *fab_clk_div = static_cast<u32>(div_u16);
    }

#ifdef DEBUG
    std::cout << "GetFabClkOutDiv returned: " << status << " div=" << div_u16 << std::endl;
#endif

    return status;
}

// ============================================================================
// Mixer Methods
// ============================================================================

int XrfdcRemote::SetMixerSettings(u32 tile_type, u32 tile_id, u32 block_id,
                                  const xrfdc::MixerSettings& settings) {
#ifdef DEBUG
    std::cout << "SetMixerSettings called: type=" << tile_type << " tile=" << tile_id
              << " block=" << block_id << " freq=" << settings.freq() << std::endl;
#endif

    if (!rfdc_inst_) {
        throw std::runtime_error("RFDC not initialized. Call CfgInitialize first.");
    }

    if (!lib_manager_.XRFdc_SetMixerSettings) {
        return XRFDC_FAILURE;
    }

    XRFdc_Mixer_Settings c_settings;
    memset(&c_settings, 0, sizeof(XRFdc_Mixer_Settings));

    c_settings.Freq = settings.freq();
    c_settings.PhaseOffset = settings.phase_offset();
    c_settings.EventSource = settings.event_source();
    c_settings.CoarseMixFreq = settings.coarse_mix_freq();
    c_settings.MixerMode = settings.mixer_mode();
    c_settings.FineMixerScale = settings.fine_mixer_scale();
    c_settings.MixerType = settings.mixer_type();

    int status = lib_manager_.XRFdc_SetMixerSettings(rfdc_inst_, tile_type, tile_id,
                                                     block_id, &c_settings);

#ifdef DEBUG
    std::cout << "SetMixerSettings returned: " << status << std::endl;
#endif

    return status;
}

int XrfdcRemote::GetMixerSettings(u32 tile_type, u32 tile_id, u32 block_id,
                                  xrfdc::MixerSettings* settings) {
#ifdef DEBUG
    std::cout << "GetMixerSettings called: type=" << tile_type << " tile=" << tile_id
              << " block=" << block_id << std::endl;
#endif

    if (!rfdc_inst_) {
        throw std::runtime_error("RFDC not initialized. Call CfgInitialize first.");
    }

    if (!lib_manager_.XRFdc_GetMixerSettings || !settings) {
        return XRFDC_FAILURE;
    }

    XRFdc_Mixer_Settings c_settings;
    memset(&c_settings, 0, sizeof(XRFdc_Mixer_Settings));

    int status = lib_manager_.XRFdc_GetMixerSettings(rfdc_inst_, tile_type, tile_id,
                                                     block_id, &c_settings);

    if (status == XRFDC_SUCCESS) {
        settings->set_freq(c_settings.Freq);
        settings->set_phase_offset(c_settings.PhaseOffset);
        settings->set_event_source(c_settings.EventSource);
        settings->set_coarse_mix_freq(c_settings.CoarseMixFreq);
        settings->set_mixer_mode(c_settings.MixerMode);
        settings->set_fine_mixer_scale(c_settings.FineMixerScale);
        settings->set_mixer_type(c_settings.MixerType);
    }

#ifdef DEBUG
    std::cout << "GetMixerSettings returned: " << status << std::endl;
#endif

    return status;
}

int XrfdcRemote::ResetNCOPhase(u32 tile_type, u32 tile_id, u32 block_id) {
#ifdef DEBUG
    std::cout << "ResetNCOPhase called: type=" << tile_type << " tile=" << tile_id
              << " block=" << block_id << std::endl;
#endif

    if (!rfdc_inst_) {
        throw std::runtime_error("RFDC not initialized. Call CfgInitialize first.");
    }

    if (!lib_manager_.XRFdc_ResetNCOPhase) {
        return XRFDC_FAILURE;
    }

    int status = lib_manager_.XRFdc_ResetNCOPhase(rfdc_inst_, tile_type, tile_id, block_id);

#ifdef DEBUG
    std::cout << "ResetNCOPhase returned: " << status << std::endl;
#endif

    return status;
}

// ============================================================================
// Nyquist Zone Methods
// ============================================================================

int XrfdcRemote::SetNyquistZone(u32 tile_type, u32 tile_id, u32 block_id,
                                u32 nyquist_zone) {
#ifdef DEBUG
    std::cout << "SetNyquistZone called: type=" << tile_type << " tile=" << tile_id
              << " block=" << block_id << " zone=" << nyquist_zone << std::endl;
#endif

    if (!rfdc_inst_) {
        throw std::runtime_error("RFDC not initialized. Call CfgInitialize first.");
    }

    if (!lib_manager_.XRFdc_SetNyquistZone) {
        return XRFDC_FAILURE;
    }

    int status = lib_manager_.XRFdc_SetNyquistZone(rfdc_inst_, tile_type, tile_id,
                                                   block_id, nyquist_zone);

#ifdef DEBUG
    std::cout << "SetNyquistZone returned: " << status << std::endl;
#endif

    return status;
}

int XrfdcRemote::GetNyquistZone(u32 tile_type, u32 tile_id, u32 block_id,
                                u32* nyquist_zone) {
#ifdef DEBUG
    std::cout << "GetNyquistZone called: type=" << tile_type << " tile=" << tile_id
              << " block=" << block_id << std::endl;
#endif

    if (!rfdc_inst_) {
        throw std::runtime_error("RFDC not initialized. Call CfgInitialize first.");
    }

    if (!lib_manager_.XRFdc_GetNyquistZone) {
        return XRFDC_FAILURE;
    }

    int status = lib_manager_.XRFdc_GetNyquistZone(rfdc_inst_, tile_type, tile_id,
                                                   block_id, nyquist_zone);

#ifdef DEBUG
    std::cout << "GetNyquistZone returned: " << status << std::endl;
#endif

    return status;
}

// ============================================================================
// Interpolation/Decimation Methods
// ============================================================================

int XrfdcRemote::SetInterpolationFactor(u32 tile_id, u32 block_id,
                                        u32 interp_factor) {
#ifdef DEBUG
    std::cout << "SetInterpolationFactor called: tile=" << tile_id << " block=" << block_id
              << " factor=" << interp_factor << std::endl;
#endif

    if (!rfdc_inst_) {
        throw std::runtime_error("RFDC not initialized. Call CfgInitialize first.");
    }

    if (!lib_manager_.XRFdc_SetInterpolationFactor) {
        return XRFDC_FAILURE;
    }

    int status = lib_manager_.XRFdc_SetInterpolationFactor(rfdc_inst_, tile_id, block_id,
                                                           interp_factor);

#ifdef DEBUG
    std::cout << "SetInterpolationFactor returned: " << status << std::endl;
#endif

    return status;
}

int XrfdcRemote::GetInterpolationFactor(u32 tile_id, u32 block_id,
                                        u32* interp_factor) {
#ifdef DEBUG
    std::cout << "GetInterpolationFactor called: tile=" << tile_id << " block=" << block_id << std::endl;
#endif

    if (!rfdc_inst_) {
        throw std::runtime_error("RFDC not initialized. Call CfgInitialize first.");
    }

    if (!lib_manager_.XRFdc_GetInterpolationFactor) {
        return XRFDC_FAILURE;
    }

    int status = lib_manager_.XRFdc_GetInterpolationFactor(rfdc_inst_, tile_id, block_id,
                                                           interp_factor);

#ifdef DEBUG
    std::cout << "GetInterpolationFactor returned: " << status << std::endl;
#endif

    return status;
}

int XrfdcRemote::SetDecimationFactor(u32 tile_id, u32 block_id,
                                     u32 dec_factor) {
#ifdef DEBUG
    std::cout << "SetDecimationFactor called: tile=" << tile_id << " block=" << block_id
              << " factor=" << dec_factor << std::endl;
#endif

    if (!rfdc_inst_) {
        throw std::runtime_error("RFDC not initialized. Call CfgInitialize first.");
    }

    if (!lib_manager_.XRFdc_SetDecimationFactor) {
        return XRFDC_FAILURE;
    }

    int status = lib_manager_.XRFdc_SetDecimationFactor(rfdc_inst_, tile_id, block_id,
                                                        dec_factor);

#ifdef DEBUG
    std::cout << "SetDecimationFactor returned: " << status << std::endl;
#endif

    return status;
}

int XrfdcRemote::GetDecimationFactor(u32 tile_id, u32 block_id,
                                     u32* dec_factor) {
#ifdef DEBUG
    std::cout << "GetDecimationFactor called: tile=" << tile_id << " block=" << block_id << std::endl;
#endif

    if (!rfdc_inst_) {
        throw std::runtime_error("RFDC not initialized. Call CfgInitialize first.");
    }

    if (!lib_manager_.XRFdc_GetDecimationFactor) {
        return XRFDC_FAILURE;
    }

    int status = lib_manager_.XRFdc_GetDecimationFactor(rfdc_inst_, tile_id, block_id,
                                                        dec_factor);

#ifdef DEBUG
    std::cout << "GetDecimationFactor returned: " << status << std::endl;
#endif

    return status;
}

// ============================================================================
// QMC Methods
// ============================================================================

int XrfdcRemote::SetQMCSettings(u32 tile_type, u32 tile_id, u32 block_id,
                                const xrfdc::QMCSettings& settings) {
#ifdef DEBUG
    std::cout << "SetQMCSettings called: type=" << tile_type << " tile=" << tile_id
              << " block=" << block_id << std::endl;
#endif

    if (!rfdc_inst_) {
        throw std::runtime_error("RFDC not initialized. Call CfgInitialize first.");
    }

    if (!lib_manager_.XRFdc_SetQMCSettings) {
        return XRFDC_FAILURE;
    }

    XRFdc_QMC_Settings c_settings;
    memset(&c_settings, 0, sizeof(XRFdc_QMC_Settings));

    c_settings.EnablePhase = settings.enable_phase() ? 1 : 0;
    c_settings.EnableGain = settings.enable_gain() ? 1 : 0;
    c_settings.GainCorrectionFactor = settings.gain_correction_factor();
    c_settings.PhaseCorrectionFactor = settings.phase_correction_factor();
    c_settings.OffsetCorrectionFactor = settings.offset_correction_factor();
    c_settings.EventSource = settings.event_source();

    int status = lib_manager_.XRFdc_SetQMCSettings(rfdc_inst_, tile_type, tile_id,
                                                   block_id, &c_settings);

#ifdef DEBUG
    std::cout << "SetQMCSettings returned: " << status << std::endl;
#endif

    return status;
}

int XrfdcRemote::GetQMCSettings(u32 tile_type, u32 tile_id, u32 block_id,
                                xrfdc::QMCSettings* settings) {
#ifdef DEBUG
    std::cout << "GetQMCSettings called: type=" << tile_type << " tile=" << tile_id
              << " block=" << block_id << std::endl;
#endif

    if (!rfdc_inst_) {
        throw std::runtime_error("RFDC not initialized. Call CfgInitialize first.");
    }

    if (!lib_manager_.XRFdc_GetQMCSettings || !settings) {
        return XRFDC_FAILURE;
    }

    XRFdc_QMC_Settings c_settings;
    memset(&c_settings, 0, sizeof(XRFdc_QMC_Settings));

    int status = lib_manager_.XRFdc_GetQMCSettings(rfdc_inst_, tile_type, tile_id,
                                                   block_id, &c_settings);

    if (status == XRFDC_SUCCESS) {
        settings->set_enable_phase(c_settings.EnablePhase != 0);
        settings->set_enable_gain(c_settings.EnableGain != 0);
        settings->set_gain_correction_factor(c_settings.GainCorrectionFactor);
        settings->set_phase_correction_factor(c_settings.PhaseCorrectionFactor);
        settings->set_offset_correction_factor(c_settings.OffsetCorrectionFactor);
        settings->set_event_source(c_settings.EventSource);
    }

#ifdef DEBUG
    std::cout << "GetQMCSettings returned: " << status << std::endl;
#endif

    return status;
}

// ============================================================================
// Threshold Methods (ADC only)
// ============================================================================

int XrfdcRemote::SetThresholdSettings(u32 tile_id, u32 block_id,
                                      const xrfdc::ThresholdSettings& settings) {
#ifdef DEBUG
    std::cout << "SetThresholdSettings called: tile=" << tile_id << " block=" << block_id << std::endl;
#endif

    if (!rfdc_inst_) {
        throw std::runtime_error("RFDC not initialized. Call CfgInitialize first.");
    }

    if (!lib_manager_.XRFdc_SetThresholdSettings) {
        return XRFDC_FAILURE;
    }

    XRFdc_Threshold_Settings c_settings;
    memset(&c_settings, 0, sizeof(XRFdc_Threshold_Settings));

    c_settings.UpdateThreshold = settings.update_threshold();
    for (int i = 0; i < 2; ++i) {
        c_settings.ThresholdMode[i] =
            settings.threshold_mode_size() > i ? settings.threshold_mode(i) : 0;
        c_settings.ThresholdAvgVal[i] =
            settings.threshold_avg_val_size() > i ? settings.threshold_avg_val(i) : 0;
        c_settings.ThresholdUnderVal[i] =
            settings.threshold_under_val_size() > i ? settings.threshold_under_val(i) : 0;
        c_settings.ThresholdOverVal[i] =
            settings.threshold_over_val_size() > i ? settings.threshold_over_val(i) : 0;
    }

    int status = lib_manager_.XRFdc_SetThresholdSettings(rfdc_inst_, tile_id, block_id,
                                                         &c_settings);

#ifdef DEBUG
    std::cout << "SetThresholdSettings returned: " << status << std::endl;
#endif

    return status;
}

int XrfdcRemote::GetThresholdSettings(u32 tile_id, u32 block_id,
                                      xrfdc::ThresholdSettings* settings) {
#ifdef DEBUG
    std::cout << "GetThresholdSettings called: tile=" << tile_id << " block=" << block_id << std::endl;
#endif

    if (!rfdc_inst_) {
        throw std::runtime_error("RFDC not initialized. Call CfgInitialize first.");
    }

    if (!lib_manager_.XRFdc_GetThresholdSettings || !settings) {
        return XRFDC_FAILURE;
    }

    XRFdc_Threshold_Settings c_settings;
    memset(&c_settings, 0, sizeof(XRFdc_Threshold_Settings));

    int status = lib_manager_.XRFdc_GetThresholdSettings(rfdc_inst_, tile_id, block_id,
                                                         &c_settings);

    if (status == XRFDC_SUCCESS) {
        settings->set_update_threshold(c_settings.UpdateThreshold);
        for (int i = 0; i < 2; ++i) {
            settings->add_threshold_mode(c_settings.ThresholdMode[i]);
            settings->add_threshold_avg_val(c_settings.ThresholdAvgVal[i]);
            settings->add_threshold_under_val(c_settings.ThresholdUnderVal[i]);
            settings->add_threshold_over_val(c_settings.ThresholdOverVal[i]);
        }
    }

#ifdef DEBUG
    std::cout << "GetThresholdSettings returned: " << status << std::endl;
#endif

    return status;
}


// ============================================================================
// Additional XrfdcRemote Wrapper Methods
// ============================================================================

u32 XrfdcRemote::SetThresholdClrMode(u32 tile_id, u32 block_id,
                                     u32 threshold_to_update, u32 clr_mode) {
    if (!rfdc_inst_) {
        throw std::runtime_error("RFDC not initialized");
    }
    if (!lib_manager_.XRFdc_SetThresholdClrMode) {
        return XRFDC_FAILURE;
    }
    return lib_manager_.XRFdc_SetThresholdClrMode(rfdc_inst_, tile_id, block_id,
                                                  threshold_to_update, clr_mode);
}

u32 XrfdcRemote::ThresholdStickyClear(u32 tile_id, u32 block_id,
                                      u32 threshold_to_update) {
    if (!rfdc_inst_) {
        throw std::runtime_error("RFDC not initialized");
    }
    if (!lib_manager_.XRFdc_ThresholdStickyClear) {
        return XRFDC_FAILURE;
    }
    return lib_manager_.XRFdc_ThresholdStickyClear(rfdc_inst_, tile_id, block_id,
                                                   threshold_to_update);
}

u32 XrfdcRemote::GetEnabledInterrupts(u32 tile_type, u32 tile_id, u32 block_id) {
    if (!rfdc_inst_) {
        throw std::runtime_error("RFDC not initialized");
    }
    if (!lib_manager_.XRFdc_GetEnabledInterrupts) {
        return 0;
    }
    u32 intr_mask = 0;
    u32 status = lib_manager_.XRFdc_GetEnabledInterrupts(rfdc_inst_, tile_type, tile_id, block_id, &intr_mask);
    if (status != XRFDC_SUCCESS) {
        return 0;
    }
    return intr_mask;
}

u32 XrfdcRemote::UpdateEvent(u32 tile_type, u32 tile_id, u32 block_id, u32 event) {
    if (!rfdc_inst_) {
        throw std::runtime_error("RFDC not initialized");
    }
    if (!lib_manager_.XRFdc_UpdateEvent) {
        return XRFDC_FAILURE;
    }
    return lib_manager_.XRFdc_UpdateEvent(rfdc_inst_, tile_type, tile_id, block_id, event);
}

u32 XrfdcRemote::ResetInternalFIFOWidth(u32 tile_type, u32 tile_id, u32 block_id) {
    if (!rfdc_inst_) {
        throw std::runtime_error("RFDC not initialized");
    }
    if (!lib_manager_.XRFdc_ResetInternalFIFOWidth) {
        return XRFDC_FAILURE;
    }
    return lib_manager_.XRFdc_ResetInternalFIFOWidth(rfdc_inst_, tile_type, tile_id, block_id);
}

int XrfdcRemote::GetConnectedIData(u32 tile_type, u32 tile_id, u32 block_id) {
    if (!rfdc_inst_) {
        throw std::runtime_error("RFDC not initialized");
    }
    if (!lib_manager_.XRFdc_GetConnectedIData) {
        return -1;
    }
    return lib_manager_.XRFdc_GetConnectedIData(rfdc_inst_, tile_type, tile_id, block_id);
}

int XrfdcRemote::GetConnectedQData(u32 tile_type, u32 tile_id, u32 block_id) {
    if (!rfdc_inst_) {
        throw std::runtime_error("RFDC not initialized");
    }
    if (!lib_manager_.XRFdc_GetConnectedQData) {
        return -1;
    }
    return lib_manager_.XRFdc_GetConnectedQData(rfdc_inst_, tile_type, tile_id, block_id);
}

void XrfdcRemote::DumpRegs(u32 tile_type, u32 tile_id) {
    if (!rfdc_inst_) {
        throw std::runtime_error("RFDC not initialized");
    }
    if (lib_manager_.XRFdc_DumpRegs) {
        lib_manager_.XRFdc_DumpRegs(rfdc_inst_, tile_type, tile_id);
    }
}

// Note: Some functions might not be available in all versions of librfdc.so
// Functions will return FAILURE or default values if not loaded

// ADC-specific methods
uint8_t XrfdcRemote::GetCalibrationMode(u32 tile_id, u32 block_id) {
    if (!rfdc_inst_ || !lib_manager_.XRFdc_GetCalibrationMode) return 0;
    uint8_t mode = 0;
    u32 status = lib_manager_.XRFdc_GetCalibrationMode(rfdc_inst_, tile_id, block_id, &mode);
    if (status != XRFDC_SUCCESS) return 0;
    return mode;
}

u32 XrfdcRemote::SetCalibrationMode(u32 tile_id, u32 block_id, uint8_t mode) {
    if (!rfdc_inst_ || !lib_manager_.XRFdc_SetCalibrationMode) return XRFDC_FAILURE;
    return lib_manager_.XRFdc_SetCalibrationMode(rfdc_inst_, tile_id, block_id, mode);
}

u32 XrfdcRemote::GetFabRdVldWords(u32 tile_type, u32 tile_id, u32 block_id) {
    if (!rfdc_inst_ || !lib_manager_.XRFdc_GetFabRdVldWords) return 0;
    u32 words = 0;
    u32 status = lib_manager_.XRFdc_GetFabRdVldWords(rfdc_inst_, tile_type, tile_id, block_id, &words);
    if (status != XRFDC_SUCCESS) return 0;
    return words;
}

u32 XrfdcRemote::SetFabRdVldWords(u32 tile_type, u32 tile_id, u32 block_id, u32 words) {
    if (!rfdc_inst_ || !lib_manager_.XRFdc_SetFabRdVldWords) return XRFDC_FAILURE;
    (void)tile_type;
    return lib_manager_.XRFdc_SetFabRdVldWords(rfdc_inst_, tile_id, block_id, words);
}

u32 XrfdcRemote::GetFabWrVldWords(u32 tile_type, u32 tile_id, u32 block_id) {
    if (!rfdc_inst_ || !lib_manager_.XRFdc_GetFabWrVldWords) return 0;
    u32 words = 0;
    u32 status = lib_manager_.XRFdc_GetFabWrVldWords(rfdc_inst_, tile_type, tile_id, block_id, &words);
    if (status != XRFDC_SUCCESS) return 0;
    return words;
}

u32 XrfdcRemote::SetFabWrVldWords(u32 tile_type, u32 tile_id, u32 block_id, u32 words) {
    if (!rfdc_inst_ || !lib_manager_.XRFdc_SetFabWrVldWords) return XRFDC_FAILURE;
    (void)tile_type;
    return lib_manager_.XRFdc_SetFabWrVldWords(rfdc_inst_, tile_id, block_id, words);
}

u32 XrfdcRemote::GetDither(u32 tile_id, u32 block_id) {
    if (!rfdc_inst_ || !lib_manager_.XRFdc_GetDither) return 0;
    u32 mode = 0;
    u32 status = lib_manager_.XRFdc_GetDither(rfdc_inst_, tile_id, block_id, &mode);
    if (status != XRFDC_SUCCESS) return 0;
    return mode;
}

u32 XrfdcRemote::SetDither(u32 tile_id, u32 block_id, u32 mode) {
    if (!rfdc_inst_ || !lib_manager_.XRFdc_SetDither) return XRFDC_FAILURE;
    return lib_manager_.XRFdc_SetDither(rfdc_inst_, tile_id, block_id, mode);
}

// DAC-specific methods
u32 XrfdcRemote::GetDecoderMode(u32 tile_id, u32 block_id) {
    if (!rfdc_inst_ || !lib_manager_.XRFdc_GetDecoderMode) return 0;
    u32 mode = 0;
    u32 status = lib_manager_.XRFdc_GetDecoderMode(rfdc_inst_, tile_id, block_id, &mode);
    if (status != XRFDC_SUCCESS) return 0;
    return mode;
}

u32 XrfdcRemote::SetDecoderMode(u32 tile_id, u32 block_id, u32 mode) {
    if (!rfdc_inst_ || !lib_manager_.XRFdc_SetDecoderMode) return XRFDC_FAILURE;
    return lib_manager_.XRFdc_SetDecoderMode(rfdc_inst_, tile_id, block_id, mode);
}

u32 XrfdcRemote::GetOutputCurr(u32 tile_id, u32 block_id) {
    if (!rfdc_inst_ || !lib_manager_.XRFdc_GetOutputCurr) return 0;
    u32 curr = 0;
    u32 status = lib_manager_.XRFdc_GetOutputCurr(rfdc_inst_, tile_id, block_id, &curr);
    if (status != XRFDC_SUCCESS) return 0;
    return curr;
}

uint16_t XrfdcRemote::GetInvSincFIR(u32 tile_id, u32 block_id) {
    if (!rfdc_inst_ || !lib_manager_.XRFdc_GetInvSincFIR) return 0;
    uint16_t mode = 0;
    u32 status = lib_manager_.XRFdc_GetInvSincFIR(rfdc_inst_, tile_id, block_id, &mode);
    if (status != XRFDC_SUCCESS) return 0;
    return mode;
}

u32 XrfdcRemote::SetInvSincFIR(u32 tile_id, u32 block_id, uint16_t mode) {
    if (!rfdc_inst_ || !lib_manager_.XRFdc_SetInvSincFIR) return XRFDC_FAILURE;
    return lib_manager_.XRFdc_SetInvSincFIR(rfdc_inst_, tile_id, block_id, mode);
}

u32 XrfdcRemote::GetDataPathMode(u32 tile_id, u32 block_id) {
    if (!rfdc_inst_ || !lib_manager_.XRFdc_GetDataPathMode) return 0;
    u32 mode = 0;
    u32 status = lib_manager_.XRFdc_GetDataPathMode(rfdc_inst_, tile_id, block_id, &mode);
    if (status != XRFDC_SUCCESS) return 0;
    return mode;
}

u32 XrfdcRemote::SetDataPathMode(u32 tile_id, u32 block_id, u32 mode) {
    if (!rfdc_inst_ || !lib_manager_.XRFdc_SetDataPathMode) return XRFDC_FAILURE;
    return lib_manager_.XRFdc_SetDataPathMode(rfdc_inst_, tile_id, block_id, mode);
}

u32 XrfdcRemote::GetIMRPassMode(u32 tile_id, u32 block_id) {
    if (!rfdc_inst_ || !lib_manager_.XRFdc_GetIMRPassMode) return 0;
    u32 mode = 0;
    u32 status = lib_manager_.XRFdc_GetIMRPassMode(rfdc_inst_, tile_id, block_id, &mode);
    if (status != XRFDC_SUCCESS) return 0;
    return mode;
}

u32 XrfdcRemote::SetIMRPassMode(u32 tile_id, u32 block_id, u32 mode) {
    if (!rfdc_inst_ || !lib_manager_.XRFdc_SetIMRPassMode) return XRFDC_FAILURE;
    return lib_manager_.XRFdc_SetIMRPassMode(rfdc_inst_, tile_id, block_id, mode);
}

u32 XrfdcRemote::GetDACCompMode(u32 tile_id, u32 block_id) {
    if (!rfdc_inst_ || !lib_manager_.XRFdc_GetDACCompMode) return 0;
    u32 enabled = 0;
    u32 status = lib_manager_.XRFdc_GetDACCompMode(rfdc_inst_, tile_id, block_id, &enabled);
    if (status != XRFDC_SUCCESS) return 0;
    return enabled;
}

u32 XrfdcRemote::SetDACCompMode(u32 tile_id, u32 block_id, u32 mode) {
    if (!rfdc_inst_ || !lib_manager_.XRFdc_SetDACCompMode) return XRFDC_FAILURE;
    return lib_manager_.XRFdc_SetDACCompMode(rfdc_inst_, tile_id, block_id, mode);
}

u32 XrfdcRemote::SetDACVOP(u32 tile_id, u32 block_id, u32 uACurrent) {
    if (!rfdc_inst_ || !lib_manager_.XRFdc_SetDACVOP) return XRFDC_FAILURE;
    return lib_manager_.XRFdc_SetDACVOP(rfdc_inst_, tile_id, block_id, uACurrent);
}

u32 XrfdcRemote::SetupFIFOObs(u32 tile_type, u32 tile_id, uint8_t enable) {
    if (!rfdc_inst_ || !lib_manager_.XRFdc_SetupFIFOObs) return XRFDC_FAILURE;
    return lib_manager_.XRFdc_SetupFIFOObs(rfdc_inst_, tile_type, tile_id, enable);
}

u32 XrfdcRemote::SetupFIFOBoth(u32 tile_type, u32 tile_id, uint8_t enable) {
    if (!rfdc_inst_ || !lib_manager_.XRFdc_SetupFIFOBoth) return XRFDC_FAILURE;
    return lib_manager_.XRFdc_SetupFIFOBoth(rfdc_inst_, tile_type, tile_id, enable);
}

u32 XrfdcRemote::GetFIFOStatusObs(u32 tile_type, u32 tile_id, uint8_t* enable) {
    if (!rfdc_inst_ || !lib_manager_.XRFdc_GetFIFOStatusObs || !enable) return XRFDC_FAILURE;
    return lib_manager_.XRFdc_GetFIFOStatusObs(rfdc_inst_, tile_type, tile_id, enable);
}

// ============================================================================
// Missing Methods Implementation
// ============================================================================

u32 XrfdcRemote::GetPLLConfig(u32 tile_type, u32 tile_id, XRFdc_PLL_Settings* settings) {
    if (!rfdc_inst_ || !lib_manager_.XRFdc_GetPLLConfig || !settings) return XRFDC_FAILURE;
    return lib_manager_.XRFdc_GetPLLConfig(rfdc_inst_, tile_type, tile_id, settings);
}

u32 XrfdcRemote::GetCoarseDelaySettings(u32 tile_type, u32 tile_id, u32 block_id, XRFdc_CoarseDelay_Settings* settings) {
    if (!rfdc_inst_ || !lib_manager_.XRFdc_GetCoarseDelaySettings || !settings) return XRFDC_FAILURE;
    return lib_manager_.XRFdc_GetCoarseDelaySettings(rfdc_inst_, tile_type, tile_id, block_id, settings);
}

u32 XrfdcRemote::SetCoarseDelaySettings(u32 tile_type, u32 tile_id, u32 block_id, const XRFdc_CoarseDelay_Settings* settings) {
    if (!rfdc_inst_ || !lib_manager_.XRFdc_SetCoarseDelaySettings || !settings) return XRFDC_FAILURE;
    return lib_manager_.XRFdc_SetCoarseDelaySettings(rfdc_inst_, tile_type, tile_id, block_id, const_cast<XRFdc_CoarseDelay_Settings*>(settings));
}

u32 XrfdcRemote::GetPwrMode(u32 tile_type, u32 tile_id, u32 block_id, XRFdc_Pwr_Mode_Settings* settings) {
    if (!rfdc_inst_ || !lib_manager_.XRFdc_GetPwrMode || !settings) return XRFDC_FAILURE;
    return lib_manager_.XRFdc_GetPwrMode(rfdc_inst_, tile_type, tile_id, block_id, settings);
}

u32 XrfdcRemote::SetPwrMode(u32 tile_type, u32 tile_id, u32 block_id, const XRFdc_Pwr_Mode_Settings* settings) {
    if (!rfdc_inst_ || !lib_manager_.XRFdc_SetPwrMode || !settings) return XRFDC_FAILURE;
    return lib_manager_.XRFdc_SetPwrMode(rfdc_inst_, tile_type, tile_id, block_id, const_cast<XRFdc_Pwr_Mode_Settings*>(settings));
}

u32 XrfdcRemote::GetDecimationFactorObs(u32 tile_id, u32 block_id, u32* dec_factor) {
    if (!rfdc_inst_ || !lib_manager_.XRFdc_GetDecimationFactorObs || !dec_factor) return XRFDC_FAILURE;
    return lib_manager_.XRFdc_GetDecimationFactorObs(rfdc_inst_, tile_id, block_id, dec_factor);
}

u32 XrfdcRemote::SetDecimationFactorObs(u32 tile_id, u32 block_id, u32 dec_factor) {
    if (!rfdc_inst_ || !lib_manager_.XRFdc_SetDecimationFactorObs) return XRFDC_FAILURE;
    return lib_manager_.XRFdc_SetDecimationFactorObs(rfdc_inst_, tile_id, block_id, dec_factor);
}

u32 XrfdcRemote::GetFabRdVldWordsObs(u32 tile_type, u32 tile_id, u32 block_id, u32* words) {
    if (!rfdc_inst_ || !lib_manager_.XRFdc_GetFabRdVldWordsObs || !words) return XRFDC_FAILURE;
    return lib_manager_.XRFdc_GetFabRdVldWordsObs(rfdc_inst_, tile_type, tile_id, block_id, words);
}

u32 XrfdcRemote::SetFabRdVldWordsObs(u32 tile_type, u32 tile_id, u32 block_id, u32 words) {
    if (!rfdc_inst_ || !lib_manager_.XRFdc_SetFabRdVldWordsObs) return XRFDC_FAILURE;
    (void)tile_type;
    return lib_manager_.XRFdc_SetFabRdVldWordsObs(rfdc_inst_, tile_id, block_id, words);
}

u32 XrfdcRemote::GetFabWrVldWordsObs(u32 tile_type, u32 tile_id, u32 block_id, u32* words) {
    if (!rfdc_inst_ || !lib_manager_.XRFdc_GetFabWrVldWordsObs || !words) return XRFDC_FAILURE;
    return lib_manager_.XRFdc_GetFabWrVldWordsObs(rfdc_inst_, tile_type, tile_id, block_id, words);
}

u32 XrfdcRemote::GetCalFreeze(u32 tile_id, u32 block_id, XRFdc_Cal_Freeze_Settings* settings) {
    if (!rfdc_inst_ || !lib_manager_.XRFdc_GetCalFreeze || !settings) return XRFDC_FAILURE;
    return lib_manager_.XRFdc_GetCalFreeze(rfdc_inst_, tile_id, block_id, settings);
}

u32 XrfdcRemote::SetCalFreeze(u32 tile_id, u32 block_id, const XRFdc_Cal_Freeze_Settings* settings) {
    if (!rfdc_inst_ || !lib_manager_.XRFdc_SetCalFreeze || !settings) return XRFDC_FAILURE;
    return lib_manager_.XRFdc_SetCalFreeze(rfdc_inst_, tile_id, block_id, const_cast<XRFdc_Cal_Freeze_Settings*>(settings));
}

u32 XrfdcRemote::GetDSA(u32 tile_id, u32 block_id, XRFdc_DSA_Settings* settings) {
    if (!rfdc_inst_ || !lib_manager_.XRFdc_GetDSA || !settings) return XRFDC_FAILURE;
    return lib_manager_.XRFdc_GetDSA(rfdc_inst_, tile_id, block_id, settings);
}

u32 XrfdcRemote::SetDSA(u32 tile_id, u32 block_id, const XRFdc_DSA_Settings* settings) {
    if (!rfdc_inst_ || !lib_manager_.XRFdc_SetDSA || !settings) return XRFDC_FAILURE;
    return lib_manager_.XRFdc_SetDSA(rfdc_inst_, tile_id, block_id, const_cast<XRFdc_DSA_Settings*>(settings));
}

u32 XrfdcRemote::DisableCoefficientsOverride(u32 tile_id, u32 block_id, u32 calibration_block) {
    if (!rfdc_inst_ || !lib_manager_.XRFdc_DisableCoefficientsOverride) return XRFDC_FAILURE;
    return lib_manager_.XRFdc_DisableCoefficientsOverride(rfdc_inst_, tile_id, block_id, calibration_block);
}

u32 XrfdcRemote::ResetInternalFIFOWidthObs(u32 tile_type, u32 tile_id, u32 block_id) {
    if (!rfdc_inst_ || !lib_manager_.XRFdc_ResetInternalFIFOWidthObs) return XRFDC_FAILURE;
    (void)tile_type;
    return lib_manager_.XRFdc_ResetInternalFIFOWidthObs(rfdc_inst_, tile_id, block_id);
}

u32 XrfdcRemote::SetCalCoefficients(u32 tile_id, u32 block_id, u32 calibration_block, const XRFdc_Calibration_Coefficients* coeffs) {
    if (!rfdc_inst_ || !lib_manager_.XRFdc_SetCalCoefficients || !coeffs) return XRFDC_FAILURE;
    return lib_manager_.XRFdc_SetCalCoefficients(rfdc_inst_, tile_id, block_id, calibration_block, const_cast<XRFdc_Calibration_Coefficients*>(coeffs));
}

u32 XrfdcRemote::GetCalCoefficients(u32 tile_id, u32 block_id, u32 calibration_block, XRFdc_Calibration_Coefficients* coeffs) {
    if (!rfdc_inst_ || !lib_manager_.XRFdc_GetCalCoefficients || !coeffs) return XRFDC_FAILURE;
    return lib_manager_.XRFdc_GetCalCoefficients(rfdc_inst_, tile_id, block_id, calibration_block, coeffs);
}

u32 XrfdcRemote::GetClkDistribution(XRFdc_Distribution_Settings* settings) {
    if (!rfdc_inst_ || !lib_manager_.XRFdc_GetClkDistribution || !settings) return XRFDC_FAILURE;
    return lib_manager_.XRFdc_GetClkDistribution(rfdc_inst_, settings);
}

u32 XrfdcRemote::SetClkDistribution(const XRFdc_Distribution_Settings* settings) {
    if (!rfdc_inst_ || !lib_manager_.XRFdc_SetClkDistribution || !settings) return XRFDC_FAILURE;
    return lib_manager_.XRFdc_SetClkDistribution(rfdc_inst_, const_cast<XRFdc_Distribution_Settings*>(settings));
}

// ============================================================================
// Enhanced Error Handling
// ============================================================================

void XrfdcRemote::PopulateStatus(xrfdc::Status* status,
                                 const std::string& operation,
                                 uint32_t code,
                                 uint32_t tile_type,
                                 int32_t tile_id,
                                 int32_t block_id) {
    status->set_code(code);
    status->set_operation(operation);
    status->set_tile_type_name(TileTypeName(tile_type));
    status->set_tile_id(tile_id);
    status->set_block_id(block_id);

    // Build message only on failure to avoid unnecessary allocation
    if (code == 0) {
        status->set_message("OK");
    } else {
        status->set_message(FormatXrfdcError(operation, code, tile_type,
                                             tile_id, block_id));
    }
}

using grpc::ServerContext;
using xrfdc::CfgInitializeRequest;
using xrfdc::CfgInitializeResponse;
using xrfdc::GetIPStatusRequest;
using xrfdc::GetIPStatusResponse;
using xrfdc::TileControlRequest;
using xrfdc::TileControlResponse;
using xrfdc::SetupFIFORequest;
using xrfdc::DynamicPLLConfigRequest;
using xrfdc::GetFabRdVldWordsResponse;
using xrfdc::GetFabWrVldWordsResponse;
using xrfdc::GetDitherResponse;
using xrfdc::GetDecoderModeResponse;
using xrfdc::GetOutputCurrResponse;
using xrfdc::GetInvSincFIRResponse;
using xrfdc::GetDataPathModeResponse;
using xrfdc::GetIMRPassModeResponse;
using xrfdc::GetDACCompModeResponse;


XrfdcImpl::XrfdcImpl() : initialized_(false), rfdc_remote_(std::make_unique<::XrfdcRemote>()) {
        #ifdef DEBUG
        std::cout << "XrfdcImpl: Service created" << std::endl;
        #endif
    }

XrfdcImpl::~XrfdcImpl() {
        #ifdef DEBUG
        std::cout << "XrfdcImpl: Service destroyed" << std::endl;
        #endif
    }

void XrfdcImpl::invalidate() {
    std::lock_guard<std::mutex> lk(mu_);
    initialized_ = false;
    if (rfdc_remote_) {
        rfdc_remote_->Invalidate();
    }
}

    /**
     * @brief Initialize the RFDC hardware.
     *
     * @param context gRPC server context
     * @param request Configuration request containing complete RFdcConfig
     * @param response Status response
     * @return grpc::Status indicating success or failure
     */
grpc::Status XrfdcImpl::CfgInitialize(ServerContext* context,
                               const CfgInitializeRequest* request,
                               CfgInitializeResponse* response) {
        std::lock_guard<std::mutex> lk(mu_);

        #ifdef DEBUG
        std::cout << "CfgInitialize RPC called" << std::endl;
        #endif

        try {
            // Validate that config is provided
            if (!request->has_config()) {
                throw std::runtime_error("RFdcConfig is required in CfgInitializeRequest");
            }

            // Pass the entire request (includes config and size) to CfgInitialize
            initialized_ = false;
            rfdc_remote_->CfgInitialize(*request);
            initialized_ = true;

            auto* status = response->mutable_status();
            status->set_code(0);
            status->set_message("RFDC initialized successfully");

            #ifdef DEBUG
            std::cout << "CfgInitialize RPC completed successfully" << std::endl;
            #endif
            return grpc::Status::OK;

        } catch (const std::exception& e) {
            auto* status = response->mutable_status();
            status->set_code(1);
            status->set_message(std::string("Initialization failed: ") + e.what());

            std::cerr << "CfgInitialize RPC failed: " << e.what() << std::endl;
            return grpc::Status(grpc::StatusCode::INTERNAL, e.what());
        }
    }

    /**
     * @brief Get comprehensive IP status including all tiles and blocks.
     *
     * @param context gRPC server context
     * @param request Status request (empty)
     * @param response Status response with complete IP status
     * @return grpc::Status indicating success or failure
     */
grpc::Status XrfdcImpl::GetIPStatus(ServerContext* context,
                            const GetIPStatusRequest* request,
                            GetIPStatusResponse* response) {
        std::lock_guard<std::mutex> lk(mu_);

        #ifdef DEBUG
        std::cout << "GetIPStatus RPC called" << std::endl;
        #endif

        if (!initialized_) {
            auto* status = response->mutable_status();
            status->set_code(1);
            status->set_message("RFDC not initialized. Call CfgInitialize first.");

            return grpc::Status(grpc::StatusCode::FAILED_PRECONDITION,
                              "RFDC not initialized");
        }

        try {
            // Get IP status from hardware
            xrfdc::IPStatus ip_status = rfdc_remote_->GetIPStatus();

            // Copy to response
            response->mutable_ip_status()->CopyFrom(ip_status);

            // Set success status
            auto* status = response->mutable_status();
            status->set_code(0);
            status->set_message("IP status retrieved successfully");

            #ifdef DEBUG
            std::cout << "GetIPStatus RPC completed successfully" << std::endl;
            #endif
            return grpc::Status::OK;

        } catch (const std::exception& e) {
            auto* status = response->mutable_status();
            status->set_code(1);
            status->set_message(std::string("Failed to get IP status: ") + e.what());

            std::cerr << "GetIPStatus RPC failed: " << e.what() << std::endl;
            return grpc::Status(grpc::StatusCode::INTERNAL, e.what());
        }
    }

    /**
     * @brief Start up a tile.
     */
grpc::Status XrfdcImpl::StartUp(ServerContext* context,
                        const TileControlRequest* request,
                        TileControlResponse* response) {
        std::lock_guard<std::mutex> lk(mu_);

        #ifdef DEBUG
        std::cout << "StartUp RPC called: type=" << request->tile_type()
                  << " id=" << request->tile_id() << std::endl;
        #endif

        if (!initialized_) {
            auto* status = response->mutable_status();
            status->set_code(1);
            status->set_message("RFDC not initialized. Call CfgInitialize first.");
            return grpc::Status(grpc::StatusCode::FAILED_PRECONDITION,
                              "RFDC not initialized");
        }

        try {
            int ret = rfdc_remote_->StartUp(request->tile_type(), request->tile_id());

            rfdc_remote_->PopulateStatus(
                response->mutable_status(),
                "StartUp",
                ret,
                request->tile_type(),
                request->tile_id(),
                -1  // Tile-level operation, no block_id
            );

            return grpc::Status::OK;

        } catch (const std::exception& e) {
            auto* status = response->mutable_status();
            status->set_code(1);
            status->set_message(std::string("StartUp failed: ") + e.what());
            return grpc::Status(grpc::StatusCode::INTERNAL, e.what());
        }
    }

    /**
     * @brief Shut down a tile.
     */
grpc::Status XrfdcImpl::Shutdown(ServerContext* context,
                         const TileControlRequest* request,
                         TileControlResponse* response) {
        std::lock_guard<std::mutex> lk(mu_);

        #ifdef DEBUG
        std::cout << "Shutdown RPC called: type=" << request->tile_type()
                  << " id=" << request->tile_id() << std::endl;
        #endif

        if (!initialized_) {
            auto* status = response->mutable_status();
            status->set_code(1);
            status->set_message("RFDC not initialized. Call CfgInitialize first.");
            return grpc::Status(grpc::StatusCode::FAILED_PRECONDITION,
                              "RFDC not initialized");
        }

        try {
            int ret = rfdc_remote_->Shutdown(request->tile_type(), request->tile_id());

            rfdc_remote_->PopulateStatus(
                response->mutable_status(),
                "Shutdown",
                ret,
                request->tile_type(),
                request->tile_id(),
                -1
            );

            return grpc::Status::OK;

        } catch (const std::exception& e) {
            auto* status = response->mutable_status();
            status->set_code(1);
            status->set_message(std::string("Shutdown failed: ") + e.what());
            return grpc::Status(grpc::StatusCode::INTERNAL, e.what());
        }
    }

    /**
     * @brief Reset a tile.
     */
grpc::Status XrfdcImpl::Reset(ServerContext* context,
                      const TileControlRequest* request,
                      TileControlResponse* response) {
        std::lock_guard<std::mutex> lk(mu_);

        #ifdef DEBUG
        std::cout << "Reset RPC called: type=" << request->tile_type()
                  << " id=" << request->tile_id() << std::endl;
        #endif

        if (!initialized_) {
            auto* status = response->mutable_status();
            status->set_code(1);
            status->set_message("RFDC not initialized. Call CfgInitialize first.");
            return grpc::Status(grpc::StatusCode::FAILED_PRECONDITION,
                              "RFDC not initialized");
        }

        try {
            int ret = rfdc_remote_->Reset(request->tile_type(), request->tile_id());

            rfdc_remote_->PopulateStatus(
                response->mutable_status(),
                "Reset",
                ret,
                request->tile_type(),
                request->tile_id(),
                -1
            );

            return grpc::Status::OK;

        } catch (const std::exception& e) {
            auto* status = response->mutable_status();
            status->set_code(1);
            status->set_message(std::string("Reset failed: ") + e.what());
            return grpc::Status(grpc::StatusCode::INTERNAL, e.what());
        }
    }

    /**
     * @brief Setup FIFO for a tile.
     */
grpc::Status XrfdcImpl::SetupFIFO(ServerContext* context,
                          const SetupFIFORequest* request,
                          TileControlResponse* response) {
        std::lock_guard<std::mutex> lk(mu_);

        #ifdef DEBUG
        std::cout << "SetupFIFO RPC called: type=" << request->tile_type()
                  << " id=" << request->tile_id() << " enable=" << request->enable()
                  << std::endl;
        #endif

        if (!initialized_) {
            auto* status = response->mutable_status();
            status->set_code(1);
            status->set_message("RFDC not initialized. Call CfgInitialize first.");
            return grpc::Status(grpc::StatusCode::FAILED_PRECONDITION,
                              "RFDC not initialized");
        }

        try {
            int ret = rfdc_remote_->SetupFIFO(request->tile_type(), request->tile_id(),
                                             request->enable());

            rfdc_remote_->PopulateStatus(
                response->mutable_status(),
                "SetupFIFO",
                ret,
                request->tile_type(),
                request->tile_id(),
                -1  // Tile-level operation
            );

            return grpc::Status::OK;

        } catch (const std::exception& e) {
            auto* status = response->mutable_status();
            status->set_code(1);
            status->set_message(std::string("SetupFIFO failed: ") + e.what());
            return grpc::Status(grpc::StatusCode::INTERNAL, e.what());
        }
    }

    /**
     * @brief Configure PLL dynamically.
     */
grpc::Status XrfdcImpl::DynamicPLLConfig(ServerContext* context,
                                 const DynamicPLLConfigRequest* request,
                                 TileControlResponse* response) {
        std::lock_guard<std::mutex> lk(mu_);

#ifdef DEBUG
        std::cerr << "[XRFDC] DynamicPLLConfig called: tile_type=" << request->tile_type()
                  << " tile_id=" << request->tile_id() << " source=" << request->source()
                  << " ref_clk=" << request->ref_clk_freq() << " MHz"
                  << " samp_rate=" << request->samp_rate() << " MSPS" << std::endl;
#endif

        if (!initialized_) {
#ifdef DEBUG
            std::cerr << "[XRFDC] ERROR: RFDC not initialized!" << std::endl;
#endif
            auto* status = response->mutable_status();
            status->set_code(1);
            status->set_message("RFDC not initialized. Call CfgInitialize first.");
            return grpc::Status(grpc::StatusCode::FAILED_PRECONDITION,
                              "RFDC not initialized");
        }

        try {
            int ret = rfdc_remote_->DynamicPLLConfig(request->tile_type(),
                                                    request->tile_id(),
                                                    request->source(),
                                                    request->ref_clk_freq(),
                                                    request->samp_rate());

#ifdef DEBUG
            std::cerr << "[XRFDC] DynamicPLLConfig returned: " << ret
                      << (ret == 0 ? " (SUCCESS)" : " (FAILED)") << std::endl;
#endif

            rfdc_remote_->PopulateStatus(
                response->mutable_status(),
                "DynamicPLLConfig",
                ret,
                request->tile_type(),
                request->tile_id(),
                -1
            );

            return grpc::Status::OK;

        } catch (const std::exception& e) {
#ifdef DEBUG
            std::cerr << "[XRFDC] DynamicPLLConfig exception: " << e.what() << std::endl;
#endif
            auto* status = response->mutable_status();
            status->set_code(1);
            status->set_message(std::string("DynamicPLLConfig failed: ") + e.what());
            return grpc::Status(grpc::StatusCode::INTERNAL, e.what());
        }
    }

grpc::Status XrfdcImpl::GetBlockStatus(ServerContext* context,
                                const xrfdc::BlockRequest* request,
                                xrfdc::GetBlockStatusResponse* response) {
        std::lock_guard<std::mutex> lk(mu_);

        if (!initialized_) {
            auto* status = response->mutable_status();
            status->set_code(1);
            status->set_message("RFDC not initialized. Call CfgInitialize first.");
            return grpc::Status(grpc::StatusCode::FAILED_PRECONDITION, "RFDC not initialized");
        }
        try {
            XRFdc_BlockStatus c_status;
            memset(&c_status, 0, sizeof(XRFdc_BlockStatus));
            int ret = rfdc_remote_->GetBlockStatus(request->tile_type(), request->tile_id(),
                                                  request->block_id(), &c_status);

            rfdc_remote_->PopulateStatus(
                response->mutable_status(),
                "GetBlockStatus",
                ret,
                request->tile_type(),
                request->tile_id(),
                request->block_id()
            );

            if (ret == 0) {
                response->set_sampling_freq(c_status.SamplingFreq);
                response->set_analog_data_path_status(c_status.AnalogDataPathStatus);
                response->set_digital_data_path_status(c_status.DigitalDataPathStatus);
                response->set_data_path_clocks_status(c_status.DataPathClocksStatus);
                response->set_is_fifo_flags_enabled(c_status.IsFIFOFlagsEnabled);
                response->set_is_fifo_flags_asserted(c_status.IsFIFOFlagsAsserted);
            }
            return grpc::Status::OK;
        } catch (const std::exception& e) {
            auto* status = response->mutable_status();
            status->set_code(1);
            status->set_message(std::string("GetBlockStatus failed: ") + e.what());
            return grpc::Status(grpc::StatusCode::INTERNAL, e.what());
        }
    }

grpc::Status XrfdcImpl::GetFIFOStatus(ServerContext* context,
                               const xrfdc::TileRequest* request,
                               xrfdc::GetFIFOStatusResponse* response) {
        std::lock_guard<std::mutex> lk(mu_);

        if (!initialized_) {
            auto* status = response->mutable_status();
            status->set_code(1);
            status->set_message("RFDC not initialized. Call CfgInitialize first.");
            return grpc::Status(grpc::StatusCode::FAILED_PRECONDITION, "RFDC not initialized");
        }
        try {
            bool enable = false;
            int ret = rfdc_remote_->GetFIFOStatus(request->tile_type(), request->tile_id(), 0, &enable);

            rfdc_remote_->PopulateStatus(
                response->mutable_status(),
                "GetFIFOStatus",
                ret,
                request->tile_type(),
                request->tile_id(),
                -1  // Tile-level operation
            );

            response->set_enable(enable);
            return grpc::Status::OK;
        } catch (const std::exception& e) {
            auto* status = response->mutable_status();
            status->set_code(1);
            status->set_message(std::string("GetFIFOStatus failed: ") + e.what());
            return grpc::Status(grpc::StatusCode::INTERNAL, e.what());
        }
    }

grpc::Status XrfdcImpl::GetPLLLockStatus(ServerContext* context,
                                  const xrfdc::TileRequest* request,
                                  xrfdc::GetPLLLockStatusResponse* response) {
        std::lock_guard<std::mutex> lk(mu_);

        if (!initialized_) {
            auto* status = response->mutable_status();
            status->set_code(1);
            status->set_message("RFDC not initialized. Call CfgInitialize first.");
            return grpc::Status(grpc::StatusCode::FAILED_PRECONDITION, "RFDC not initialized");
        }
        try {
            uint32_t lock_status = 0;
            int ret = rfdc_remote_->GetPLLLockStatus(request->tile_type(), request->tile_id(), &lock_status);

            rfdc_remote_->PopulateStatus(
                response->mutable_status(),
                "GetPLLLockStatus",
                ret,
                request->tile_type(),
                request->tile_id(),
                -1  // Tile-level operation
            );

            response->set_lock_status(lock_status);
            return grpc::Status::OK;
        } catch (const std::exception& e) {
            auto* status = response->mutable_status();
            status->set_code(1);
            status->set_message(std::string("GetPLLLockStatus failed: ") + e.what());
            return grpc::Status(grpc::StatusCode::INTERNAL, e.what());
        }
    }

grpc::Status XrfdcImpl::GetClockSource(ServerContext* context,
                                const xrfdc::TileRequest* request,
                                xrfdc::GetClockSourceResponse* response) {
        std::lock_guard<std::mutex> lk(mu_);

        if (!initialized_) {
            auto* status = response->mutable_status();
            status->set_code(1);
            status->set_message("RFDC not initialized. Call CfgInitialize first.");
            return grpc::Status(grpc::StatusCode::FAILED_PRECONDITION, "RFDC not initialized");
        }
        try {
            uint32_t clock_source = 0;
            int ret = rfdc_remote_->GetClockSource(request->tile_type(), request->tile_id(), &clock_source);

            rfdc_remote_->PopulateStatus(
                response->mutable_status(),
                "GetClockSource",
                ret,
                request->tile_type(),
                request->tile_id(),
                -1  // Tile-level operation
            );

            response->set_clock_source(clock_source);
            return grpc::Status::OK;
        } catch (const std::exception& e) {
            auto* status = response->mutable_status();
            status->set_code(1);
            status->set_message(std::string("GetClockSource failed: ") + e.what());
            return grpc::Status(grpc::StatusCode::INTERNAL, e.what());
        }
    }

grpc::Status XrfdcImpl::SetFabClkOutDiv(ServerContext* context,
                                 const xrfdc::SetFabClkOutDivRequest* request,
                                 xrfdc::TileControlResponse* response) {
        std::lock_guard<std::mutex> lk(mu_);

        if (!initialized_) {
            auto* status = response->mutable_status();
            status->set_code(1);
            status->set_message("RFDC not initialized. Call CfgInitialize first.");
            return grpc::Status(grpc::StatusCode::FAILED_PRECONDITION, "RFDC not initialized");
        }
        try {
            int ret = rfdc_remote_->SetFabClkOutDiv(request->tile_type(), request->tile_id(), request->fab_clk_div());

            rfdc_remote_->PopulateStatus(
                response->mutable_status(),
                "SetFabClkOutDiv",
                ret,
                request->tile_type(),
                request->tile_id(),
                -1  // Tile-level operation
            );

            return grpc::Status::OK;
        } catch (const std::exception& e) {
            auto* status = response->mutable_status();
            status->set_code(1);
            status->set_message(std::string("SetFabClkOutDiv failed: ") + e.what());
            return grpc::Status(grpc::StatusCode::INTERNAL, e.what());
        }
    }

grpc::Status XrfdcImpl::GetFabClkOutDiv(ServerContext* context,
                                 const xrfdc::TileRequest* request,
                                 xrfdc::GetFabClkOutDivResponse* response) {
        std::lock_guard<std::mutex> lk(mu_);

        if (!initialized_) {
            auto* status = response->mutable_status();
            status->set_code(1);
            status->set_message("RFDC not initialized. Call CfgInitialize first.");
            return grpc::Status(grpc::StatusCode::FAILED_PRECONDITION, "RFDC not initialized");
        }
        try {
            uint32_t div = 0;
            int ret = rfdc_remote_->GetFabClkOutDiv(request->tile_type(), request->tile_id(), &div);

            rfdc_remote_->PopulateStatus(
                response->mutable_status(),
                "GetFabClkOutDiv",
                ret,
                request->tile_type(),
                request->tile_id(),
                -1  // Tile-level operation
            );

            response->set_fab_clk_div(div);
            return grpc::Status::OK;
        } catch (const std::exception& e) {
            auto* status = response->mutable_status();
            status->set_code(1);
            status->set_message(std::string("GetFabClkOutDiv failed: ") + e.what());
            return grpc::Status(grpc::StatusCode::INTERNAL, e.what());
        }
    }

grpc::Status XrfdcImpl::SetMixerSettings(ServerContext* context,
                                  const xrfdc::SetMixerSettingsRequest* request,
                                  xrfdc::TileControlResponse* response) {
        std::lock_guard<std::mutex> lk(mu_);

        std::cerr << "[XRFDC] SetMixerSettings called: tile_type=" << request->tile_type()
                  << " tile_id=" << request->tile_id() << " block_id=" << request->block_id() << std::endl;
        std::cerr << "[XRFDC]   Settings: freq=" << request->settings().freq()
                  << " phase_offset=" << request->settings().phase_offset()
                  << " event_source=" << request->settings().event_source()
                  << " coarse_mix_freq=" << request->settings().coarse_mix_freq()
                  << " mixer_mode=" << request->settings().mixer_mode()
                  << " fine_mixer_scale=" << request->settings().fine_mixer_scale()
                  << " mixer_type=" << request->settings().mixer_type() << std::endl;

        if (!initialized_) {
            std::cerr << "[XRFDC] ERROR: RFDC not initialized!" << std::endl;
            auto* status = response->mutable_status();
            status->set_code(1);
            status->set_message("RFDC not initialized. Call CfgInitialize first.");
            return grpc::Status(grpc::StatusCode::FAILED_PRECONDITION, "RFDC not initialized");
        }
        try {
            int ret = rfdc_remote_->SetMixerSettings(request->tile_type(), request->tile_id(),
                                                    request->block_id(), request->settings());
            std::cerr << "[XRFDC] SetMixerSettings returned: " << ret
                      << (ret == 0 ? " (SUCCESS)" : " (FAILED)") << std::endl;

            // Use helper to populate status with full context
            rfdc_remote_->PopulateStatus(
                response->mutable_status(),
                "SetMixerSettings",
                ret,
                request->tile_type(),
                request->tile_id(),
                request->block_id()
            );

            return grpc::Status::OK;
        } catch (const std::exception& e) {
            std::cerr << "[XRFDC] SetMixerSettings exception: " << e.what() << std::endl;
            auto* status = response->mutable_status();
            status->set_code(1);
            status->set_message(std::string("SetMixerSettings failed: ") + e.what());
            return grpc::Status(grpc::StatusCode::INTERNAL, e.what());
        }
    }

grpc::Status XrfdcImpl::GetMixerSettings(ServerContext* context,
                                  const xrfdc::BlockRequest* request,
                                  xrfdc::GetMixerSettingsResponse* response) {
        std::lock_guard<std::mutex> lk(mu_);

        std::cerr << "[XRFDC] GetMixerSettings called: tile_type=" << request->tile_type()
                  << " tile_id=" << request->tile_id() << " block_id=" << request->block_id() << std::endl;

        if (!initialized_) {
            std::cerr << "[XRFDC] ERROR: RFDC not initialized!" << std::endl;
            auto* status = response->mutable_status();
            status->set_code(1);
            status->set_message("RFDC not initialized. Call CfgInitialize first.");
            return grpc::Status(grpc::StatusCode::FAILED_PRECONDITION, "RFDC not initialized");
        }
        try {
            int ret = rfdc_remote_->GetMixerSettings(request->tile_type(), request->tile_id(),
                                                    request->block_id(), response->mutable_settings());
            std::cerr << "[XRFDC] GetMixerSettings returned: " << ret
                      << (ret == 0 ? " (SUCCESS)" : " (FAILED)") << std::endl;
            if (ret == 0) {
                const auto& settings = response->settings();
                std::cerr << "[XRFDC]   Retrieved: freq=" << settings.freq()
                          << " phase_offset=" << settings.phase_offset()
                          << " event_source=" << settings.event_source()
                          << " coarse_mix_freq=" << settings.coarse_mix_freq()
                          << " mixer_mode=" << settings.mixer_mode()
                          << " fine_mixer_scale=" << settings.fine_mixer_scale()
                          << " mixer_type=" << settings.mixer_type() << std::endl;
            }

            rfdc_remote_->PopulateStatus(
                response->mutable_status(),
                "GetMixerSettings",
                ret,
                request->tile_type(),
                request->tile_id(),
                request->block_id()
            );

            return grpc::Status::OK;
        } catch (const std::exception& e) {
            std::cerr << "[XRFDC] GetMixerSettings exception: " << e.what() << std::endl;
            auto* status = response->mutable_status();
            status->set_code(1);
            status->set_message(std::string("GetMixerSettings failed: ") + e.what());
            return grpc::Status(grpc::StatusCode::INTERNAL, e.what());
        }
    }

grpc::Status XrfdcImpl::ResetNCOPhase(ServerContext* context,
                               const xrfdc::BlockRequest* request,
                               xrfdc::TileControlResponse* response) {
        std::lock_guard<std::mutex> lk(mu_);

        if (!initialized_) {
            auto* status = response->mutable_status();
            status->set_code(1);
            status->set_message("RFDC not initialized. Call CfgInitialize first.");
            return grpc::Status(grpc::StatusCode::FAILED_PRECONDITION, "RFDC not initialized");
        }
        try {
            int ret = rfdc_remote_->ResetNCOPhase(request->tile_type(), request->tile_id(), request->block_id());

            rfdc_remote_->PopulateStatus(
                response->mutable_status(),
                "ResetNCOPhase",
                ret,
                request->tile_type(),
                request->tile_id(),
                request->block_id()
            );

            return grpc::Status::OK;
        } catch (const std::exception& e) {
            auto* status = response->mutable_status();
            status->set_code(1);
            status->set_message(std::string("ResetNCOPhase failed: ") + e.what());
            return grpc::Status(grpc::StatusCode::INTERNAL, e.what());
        }
    }

grpc::Status XrfdcImpl::SetNyquistZone(ServerContext* context,
                                const xrfdc::SetNyquistZoneRequest* request,
                                xrfdc::TileControlResponse* response) {
        std::lock_guard<std::mutex> lk(mu_);

        if (!initialized_) {
            auto* status = response->mutable_status();
            status->set_code(1);
            status->set_message("RFDC not initialized. Call CfgInitialize first.");
            return grpc::Status(grpc::StatusCode::FAILED_PRECONDITION, "RFDC not initialized");
        }
        try {
            int ret = rfdc_remote_->SetNyquistZone(request->tile_type(), request->tile_id(),
                                                  request->block_id(), request->nyquist_zone());

            rfdc_remote_->PopulateStatus(
                response->mutable_status(),
                "SetNyquistZone",
                ret,
                request->tile_type(),
                request->tile_id(),
                request->block_id()
            );

            return grpc::Status::OK;
        } catch (const std::exception& e) {
            auto* status = response->mutable_status();
            status->set_code(1);
            status->set_message(std::string("SetNyquistZone failed: ") + e.what());
            return grpc::Status(grpc::StatusCode::INTERNAL, e.what());
        }
    }

grpc::Status XrfdcImpl::GetNyquistZone(ServerContext* context,
                                const xrfdc::BlockRequest* request,
                                xrfdc::GetNyquistZoneResponse* response) {
        std::lock_guard<std::mutex> lk(mu_);

        if (!initialized_) {
            auto* status = response->mutable_status();
            status->set_code(1);
            status->set_message("RFDC not initialized. Call CfgInitialize first.");
            return grpc::Status(grpc::StatusCode::FAILED_PRECONDITION, "RFDC not initialized");
        }
        try {
            uint32_t zone = 0;
            int ret = rfdc_remote_->GetNyquistZone(request->tile_type(), request->tile_id(), request->block_id(), &zone);

            rfdc_remote_->PopulateStatus(
                response->mutable_status(),
                "GetNyquistZone",
                ret,
                request->tile_type(),
                request->tile_id(),
                request->block_id()
            );

            response->set_nyquist_zone(zone);
            return grpc::Status::OK;
        } catch (const std::exception& e) {
            auto* status = response->mutable_status();
            status->set_code(1);
            status->set_message(std::string("GetNyquistZone failed: ") + e.what());
            return grpc::Status(grpc::StatusCode::INTERNAL, e.what());
        }
    }

grpc::Status XrfdcImpl::SetInterpolationFactor(ServerContext* context,
                                        const xrfdc::SetInterpolationFactorRequest* request,
                                        xrfdc::TileControlResponse* response) {
        std::lock_guard<std::mutex> lk(mu_);

        if (!initialized_) {
            auto* status = response->mutable_status();
            status->set_code(1);
            status->set_message("RFDC not initialized. Call CfgInitialize first.");
            return grpc::Status(grpc::StatusCode::FAILED_PRECONDITION, "RFDC not initialized");
        }
        try {
            int ret = rfdc_remote_->SetInterpolationFactor(request->tile_id(), request->block_id(), request->interp_factor());

            rfdc_remote_->PopulateStatus(
                response->mutable_status(),
                "SetInterpolationFactor",
                ret,
                XRFDC_DAC_TILE,  // Interpolation is DAC-only
                request->tile_id(),
                request->block_id()
            );

            return grpc::Status::OK;
        } catch (const std::exception& e) {
            auto* status = response->mutable_status();
            status->set_code(1);
            status->set_message(std::string("SetInterpolationFactor failed: ") + e.what());
            return grpc::Status(grpc::StatusCode::INTERNAL, e.what());
        }
    }

grpc::Status XrfdcImpl::GetInterpolationFactor(ServerContext* context,
                                        const xrfdc::BlockRequest* request,
                                        xrfdc::GetInterpolationFactorResponse* response) {
        std::lock_guard<std::mutex> lk(mu_);

        if (!initialized_) {
            auto* status = response->mutable_status();
            status->set_code(1);
            status->set_message("RFDC not initialized. Call CfgInitialize first.");
            return grpc::Status(grpc::StatusCode::FAILED_PRECONDITION, "RFDC not initialized");
        }
        try {
            uint32_t factor = 0;
            int ret = rfdc_remote_->GetInterpolationFactor(request->tile_id(), request->block_id(), &factor);

            rfdc_remote_->PopulateStatus(
                response->mutable_status(),
                "GetInterpolationFactor",
                ret,
                XRFDC_DAC_TILE,  // Interpolation is DAC-only
                request->tile_id(),
                request->block_id()
            );

            response->set_interp_factor(factor);
            return grpc::Status::OK;
        } catch (const std::exception& e) {
            auto* status = response->mutable_status();
            status->set_code(1);
            status->set_message(std::string("GetInterpolationFactor failed: ") + e.what());
            return grpc::Status(grpc::StatusCode::INTERNAL, e.what());
        }
    }

grpc::Status XrfdcImpl::SetDecimationFactor(ServerContext* context,
                                     const xrfdc::SetDecimationFactorRequest* request,
                                     xrfdc::TileControlResponse* response) {
        std::lock_guard<std::mutex> lk(mu_);

        if (!initialized_) {
            auto* status = response->mutable_status();
            status->set_code(1);
            status->set_message("RFDC not initialized. Call CfgInitialize first.");
            return grpc::Status(grpc::StatusCode::FAILED_PRECONDITION, "RFDC not initialized");
        }
        try {
            int ret = rfdc_remote_->SetDecimationFactor(request->tile_id(), request->block_id(), request->dec_factor());

            rfdc_remote_->PopulateStatus(
                response->mutable_status(),
                "SetDecimationFactor",
                ret,
                XRFDC_ADC_TILE,  // Decimation is ADC-only
                request->tile_id(),
                request->block_id()
            );

            return grpc::Status::OK;
        } catch (const std::exception& e) {
            auto* status = response->mutable_status();
            status->set_code(1);
            status->set_message(std::string("SetDecimationFactor failed: ") + e.what());
            return grpc::Status(grpc::StatusCode::INTERNAL, e.what());
        }
    }

grpc::Status XrfdcImpl::GetDecimationFactor(ServerContext* context,
                                     const xrfdc::BlockRequest* request,
                                     xrfdc::GetDecimationFactorResponse* response) {
        std::lock_guard<std::mutex> lk(mu_);

        if (!initialized_) {
            auto* status = response->mutable_status();
            status->set_code(1);
            status->set_message("RFDC not initialized. Call CfgInitialize first.");
            return grpc::Status(grpc::StatusCode::FAILED_PRECONDITION, "RFDC not initialized");
        }
        try {
            uint32_t factor = 0;
            int ret = rfdc_remote_->GetDecimationFactor(request->tile_id(), request->block_id(), &factor);

            rfdc_remote_->PopulateStatus(
                response->mutable_status(),
                "GetDecimationFactor",
                ret,
                XRFDC_ADC_TILE,  // Decimation is ADC-only
                request->tile_id(),
                request->block_id()
            );

            response->set_dec_factor(factor);
            return grpc::Status::OK;
        } catch (const std::exception& e) {
            auto* status = response->mutable_status();
            status->set_code(1);
            status->set_message(std::string("GetDecimationFactor failed: ") + e.what());
            return grpc::Status(grpc::StatusCode::INTERNAL, e.what());
        }
    }

grpc::Status XrfdcImpl::SetQMCSettings(ServerContext* context,
                                const xrfdc::SetQMCSettingsRequest* request,
                                xrfdc::TileControlResponse* response) {
        std::lock_guard<std::mutex> lk(mu_);

        if (!initialized_) {
            auto* status = response->mutable_status();
            status->set_code(1);
            status->set_message("RFDC not initialized. Call CfgInitialize first.");
            return grpc::Status(grpc::StatusCode::FAILED_PRECONDITION, "RFDC not initialized");
        }
        try {
            int ret = rfdc_remote_->SetQMCSettings(request->tile_type(), request->tile_id(),
                                                  request->block_id(), request->settings());

            rfdc_remote_->PopulateStatus(
                response->mutable_status(),
                "SetQMCSettings",
                ret,
                request->tile_type(),
                request->tile_id(),
                request->block_id()
            );

            return grpc::Status::OK;
        } catch (const std::exception& e) {
            auto* status = response->mutable_status();
            status->set_code(1);
            status->set_message(std::string("SetQMCSettings failed: ") + e.what());
            return grpc::Status(grpc::StatusCode::INTERNAL, e.what());
        }
    }

grpc::Status XrfdcImpl::GetQMCSettings(ServerContext* context,
                                const xrfdc::BlockRequest* request,
                                xrfdc::GetQMCSettingsResponse* response) {
        std::lock_guard<std::mutex> lk(mu_);

        if (!initialized_) {
            auto* status = response->mutable_status();
            status->set_code(1);
            status->set_message("RFDC not initialized. Call CfgInitialize first.");
            return grpc::Status(grpc::StatusCode::FAILED_PRECONDITION, "RFDC not initialized");
        }
        try {
            int ret = rfdc_remote_->GetQMCSettings(request->tile_type(), request->tile_id(),
                                                  request->block_id(), response->mutable_settings());

            rfdc_remote_->PopulateStatus(
                response->mutable_status(),
                "GetQMCSettings",
                ret,
                request->tile_type(),
                request->tile_id(),
                request->block_id()
            );

            return grpc::Status::OK;
        } catch (const std::exception& e) {
            auto* status = response->mutable_status();
            status->set_code(1);
            status->set_message(std::string("GetQMCSettings failed: ") + e.what());
            return grpc::Status(grpc::StatusCode::INTERNAL, e.what());
        }
    }

grpc::Status XrfdcImpl::SetThresholdSettings(ServerContext* context,
                                      const xrfdc::SetThresholdSettingsRequest* request,
                                      xrfdc::TileControlResponse* response) {
        std::lock_guard<std::mutex> lk(mu_);

        if (!initialized_) {
            auto* status = response->mutable_status();
            status->set_code(1);
            status->set_message("RFDC not initialized. Call CfgInitialize first.");
            return grpc::Status(grpc::StatusCode::FAILED_PRECONDITION, "RFDC not initialized");
        }
        try {
            int ret = rfdc_remote_->SetThresholdSettings(request->tile_id(), request->block_id(), request->settings());

            rfdc_remote_->PopulateStatus(
                response->mutable_status(),
                "SetThresholdSettings",
                ret,
                XRFDC_ADC_TILE,  // Threshold is ADC-only
                request->tile_id(),
                request->block_id()
            );

            return grpc::Status::OK;
        } catch (const std::exception& e) {
            auto* status = response->mutable_status();
            status->set_code(1);
            status->set_message(std::string("SetThresholdSettings failed: ") + e.what());
            return grpc::Status(grpc::StatusCode::INTERNAL, e.what());
        }
    }

grpc::Status XrfdcImpl::GetThresholdSettings(ServerContext* context,
                                      const xrfdc::BlockRequest* request,
                                      xrfdc::GetThresholdSettingsResponse* response) {
        std::lock_guard<std::mutex> lk(mu_);

        if (!initialized_) {
            auto* status = response->mutable_status();
            status->set_code(1);
            status->set_message("RFDC not initialized. Call CfgInitialize first.");
            return grpc::Status(grpc::StatusCode::FAILED_PRECONDITION, "RFDC not initialized");
        }
        try {
            int ret = rfdc_remote_->GetThresholdSettings(request->tile_id(), request->block_id(),
                                                        response->mutable_settings());

            rfdc_remote_->PopulateStatus(
                response->mutable_status(),
                "GetThresholdSettings",
                ret,
                XRFDC_ADC_TILE,  // Threshold is ADC-only
                request->tile_id(),
                request->block_id()
            );

            return grpc::Status::OK;
        } catch (const std::exception& e) {
            auto* status = response->mutable_status();
            status->set_code(1);
            status->set_message(std::string("GetThresholdSettings failed: ") + e.what());
            return grpc::Status(grpc::StatusCode::INTERNAL, e.what());
        }
    }

    // ========================================================================
    // Additional RPC Handlers
    // ========================================================================

grpc::Status XrfdcImpl::SetThresholdClrMode(ServerContext* context,
                                     const xrfdc::SetThresholdClrModeRequest* request,
                                     xrfdc::SetThresholdClrModeResponse* response) {
        std::lock_guard<std::mutex> lk(mu_);

        if (!initialized_) {
            auto* status = response->mutable_status();
            status->set_code(1);
            status->set_message("RFDC not initialized. Call CfgInitialize first.");
            return grpc::Status(grpc::StatusCode::FAILED_PRECONDITION, "RFDC not initialized");
        }
        try {
            u32 ret = rfdc_remote_->SetThresholdClrMode(request->tile_id(), request->block_id(),
                                                        request->threshold_to_update(), request->clr_mode());

            rfdc_remote_->PopulateStatus(
                response->mutable_status(),
                "SetThresholdClrMode",
                ret,
                XRFDC_ADC_TILE,  // Threshold is ADC-only
                request->tile_id(),
                request->block_id()
            );

            return grpc::Status::OK;
        } catch (const std::exception& e) {
            auto* status = response->mutable_status();
            status->set_code(1);
            status->set_message(std::string("SetThresholdClrMode failed: ") + e.what());
            return grpc::Status(grpc::StatusCode::INTERNAL, e.what());
        }
    }

grpc::Status XrfdcImpl::ThresholdStickyClear(ServerContext* context,
                                      const xrfdc::ThresholdStickyClearRequest* request,
                                      xrfdc::ThresholdStickyClearResponse* response) {
        std::lock_guard<std::mutex> lk(mu_);

        if (!initialized_) {
            auto* status = response->mutable_status();
            status->set_code(1);
            status->set_message("RFDC not initialized. Call CfgInitialize first.");
            return grpc::Status(grpc::StatusCode::FAILED_PRECONDITION, "RFDC not initialized");
        }
        try {
            int ret = rfdc_remote_->ThresholdStickyClear(request->tile_id(), request->block_id(),
                                                         request->threshold_to_update());

            rfdc_remote_->PopulateStatus(
                response->mutable_status(),
                "ThresholdStickyClear",
                ret,
                XRFDC_ADC_TILE,  // Threshold is ADC-only
                request->tile_id(),
                request->block_id()
            );

            return grpc::Status::OK;
        } catch (const std::exception& e) {
            auto* status = response->mutable_status();
            status->set_code(1);
            status->set_message(std::string("ThresholdStickyClear failed: ") + e.what());
            return grpc::Status(grpc::StatusCode::INTERNAL, e.what());
        }
    }

grpc::Status XrfdcImpl::GetEnabledInterrupts(ServerContext* context,
                                      const xrfdc::BlockRequest* request,
                                      xrfdc::GetEnabledInterruptsResponse* response) {
        std::lock_guard<std::mutex> lk(mu_);

        if (!initialized_) {
            auto* status = response->mutable_status();
            status->set_code(1);
            status->set_message("RFDC not initialized. Call CfgInitialize first.");
            return grpc::Status(grpc::StatusCode::FAILED_PRECONDITION, "RFDC not initialized");
        }
        try {
            uint32_t interrupts = rfdc_remote_->GetEnabledInterrupts(request->tile_type(),
                                                                     request->tile_id(), request->block_id());

            rfdc_remote_->PopulateStatus(
                response->mutable_status(),
                "GetEnabledInterrupts",
                0,  // GetEnabledInterrupts doesn't return error code
                request->tile_type(),
                request->tile_id(),
                request->block_id()
            );

            response->set_value(interrupts);
            return grpc::Status::OK;
        } catch (const std::exception& e) {
            auto* status = response->mutable_status();
            status->set_code(1);
            status->set_message(std::string("GetEnabledInterrupts failed: ") + e.what());
            return grpc::Status(grpc::StatusCode::INTERNAL, e.what());
        }
    }

grpc::Status XrfdcImpl::UpdateEvent(ServerContext* context,
                             const xrfdc::UpdateEventRequest* request,
                             xrfdc::TileControlResponse* response) {
        std::lock_guard<std::mutex> lk(mu_);

        std::cerr << "[XRFDC] UpdateEvent called: tile_type=" << request->tile_type()
                  << " tile_id=" << request->tile_id() << " block_id=" << request->block_id()
                  << " event=" << request->event() << std::endl;

        if (!initialized_) {
            std::cerr << "[XRFDC] ERROR: RFDC not initialized!" << std::endl;
            auto* status = response->mutable_status();
            status->set_code(1);
            status->set_message("RFDC not initialized. Call CfgInitialize first.");
            return grpc::Status(grpc::StatusCode::FAILED_PRECONDITION, "RFDC not initialized");
        }
        try {
            u32 ret = rfdc_remote_->UpdateEvent(request->tile_type(), request->tile_id(),
                                                request->block_id(), request->event());
            std::cerr << "[XRFDC] UpdateEvent returned: " << ret
                      << (ret == 0 ? " (SUCCESS)" : " (FAILED)") << std::endl;

            rfdc_remote_->PopulateStatus(
                response->mutable_status(),
                "UpdateEvent",
                ret,
                request->tile_type(),
                request->tile_id(),
                request->block_id()
            );

            return grpc::Status::OK;
        } catch (const std::exception& e) {
            std::cerr << "[XRFDC] UpdateEvent exception: " << e.what() << std::endl;
            auto* status = response->mutable_status();
            status->set_code(1);
            status->set_message(std::string("UpdateEvent failed: ") + e.what());
            return grpc::Status(grpc::StatusCode::INTERNAL, e.what());
        }
    }

grpc::Status XrfdcImpl::ResetInternalFIFOWidth(ServerContext* context,
                                        const xrfdc::BlockRequest* request,
                                        xrfdc::TileControlResponse* response) {
        std::lock_guard<std::mutex> lk(mu_);

        if (!initialized_) {
            auto* status = response->mutable_status();
            status->set_code(1);
            status->set_message("RFDC not initialized. Call CfgInitialize first.");
            return grpc::Status(grpc::StatusCode::FAILED_PRECONDITION, "RFDC not initialized");
        }
        try {
            u32 ret = rfdc_remote_->ResetInternalFIFOWidth(request->tile_type(), request->tile_id(), request->block_id());

            rfdc_remote_->PopulateStatus(
                response->mutable_status(),
                "ResetInternalFIFOWidth",
                ret,
                request->tile_type(),
                request->tile_id(),
                request->block_id()
            );

            return grpc::Status::OK;
        } catch (const std::exception& e) {
            auto* status = response->mutable_status();
            status->set_code(1);
            status->set_message(std::string("ResetInternalFIFOWidth failed: ") + e.what());
            return grpc::Status(grpc::StatusCode::INTERNAL, e.what());
        }
    }

grpc::Status XrfdcImpl::GetConnectedIData(ServerContext* context,
                                   const xrfdc::BlockRequest* request,
                                   xrfdc::GetConnectedDataResponse* response) {
        std::lock_guard<std::mutex> lk(mu_);

        if (!initialized_) {
            auto* status = response->mutable_status();
            status->set_code(1);
            status->set_message("RFDC not initialized. Call CfgInitialize first.");
            return grpc::Status(grpc::StatusCode::FAILED_PRECONDITION, "RFDC not initialized");
        }
        try {
            int value = rfdc_remote_->GetConnectedIData(request->tile_type(), request->tile_id(), request->block_id());

            rfdc_remote_->PopulateStatus(
                response->mutable_status(),
                "GetConnectedIData",
                0,  // GetConnectedIData doesn't return error code
                request->tile_type(),
                request->tile_id(),
                request->block_id()
            );

            response->set_value(value);
            return grpc::Status::OK;
        } catch (const std::exception& e) {
            auto* status = response->mutable_status();
            status->set_code(1);
            status->set_message(std::string("GetConnectedIData failed: ") + e.what());
            return grpc::Status(grpc::StatusCode::INTERNAL, e.what());
        }
    }

grpc::Status XrfdcImpl::GetConnectedQData(ServerContext* context,
                                   const xrfdc::BlockRequest* request,
                                   xrfdc::GetConnectedDataResponse* response) {
        std::lock_guard<std::mutex> lk(mu_);

        if (!initialized_) {
            auto* status = response->mutable_status();
            status->set_code(1);
            status->set_message("RFDC not initialized. Call CfgInitialize first.");
            return grpc::Status(grpc::StatusCode::FAILED_PRECONDITION, "RFDC not initialized");
        }
        try {
            int value = rfdc_remote_->GetConnectedQData(request->tile_type(), request->tile_id(), request->block_id());

            rfdc_remote_->PopulateStatus(
                response->mutable_status(),
                "GetConnectedQData",
                0,  // GetConnectedQData doesn't return error code
                request->tile_type(),
                request->tile_id(),
                request->block_id()
            );

            response->set_value(value);
            return grpc::Status::OK;
        } catch (const std::exception& e) {
            auto* status = response->mutable_status();
            status->set_code(1);
            status->set_message(std::string("GetConnectedQData failed: ") + e.what());
            return grpc::Status(grpc::StatusCode::INTERNAL, e.what());
        }
    }

grpc::Status XrfdcImpl::GetCalibrationMode(ServerContext* context,
                                    const xrfdc::BlockRequest* request,
                                    xrfdc::GetCalibrationModeResponse* response) {
        std::lock_guard<std::mutex> lk(mu_);

        if (!initialized_) {
            auto* status = response->mutable_status();
            status->set_code(1);
            status->set_message("RFDC not initialized. Call CfgInitialize first.");
            return grpc::Status(grpc::StatusCode::FAILED_PRECONDITION, "RFDC not initialized");
        }
        try {
            uint8_t mode = rfdc_remote_->GetCalibrationMode(request->tile_id(), request->block_id());

            rfdc_remote_->PopulateStatus(
                response->mutable_status(),
                "GetCalibrationMode",
                0,  // GetCalibrationMode doesn't return error code
                XRFDC_ADC_TILE,  // Calibration is ADC-only
                request->tile_id(),
                request->block_id()
            );

            response->set_value(mode);
            return grpc::Status::OK;
        } catch (const std::exception& e) {
            auto* status = response->mutable_status();
            status->set_code(1);
            status->set_message(std::string("GetCalibrationMode failed: ") + e.what());
            return grpc::Status(grpc::StatusCode::INTERNAL, e.what());
        }
    }

grpc::Status XrfdcImpl::SetCalibrationMode(ServerContext* context,
                                    const xrfdc::SetCalibrationModeRequest* request,
                                    xrfdc::TileControlResponse* response) {
        std::lock_guard<std::mutex> lk(mu_);

        if (!initialized_) {
            auto* status = response->mutable_status();
            status->set_code(1);
            status->set_message("RFDC not initialized. Call CfgInitialize first.");
            return grpc::Status(grpc::StatusCode::FAILED_PRECONDITION, "RFDC not initialized");
        }
        try {
            u32 ret = rfdc_remote_->SetCalibrationMode(request->tile_id(), request->block_id(), request->value());

            rfdc_remote_->PopulateStatus(
                response->mutable_status(),
                "SetCalibrationMode",
                ret,
                XRFDC_ADC_TILE,  // Calibration is ADC-only
                request->tile_id(),
                request->block_id()
            );

            return grpc::Status::OK;
        } catch (const std::exception& e) {
            auto* status = response->mutable_status();
            status->set_code(1);
            status->set_message(std::string("SetCalibrationMode failed: ") + e.what());
            return grpc::Status(grpc::StatusCode::INTERNAL, e.what());
        }
    }

grpc::Status XrfdcImpl::GetFabRdVldWords(ServerContext* context,
                                  const xrfdc::BlockRequest* request,
                                  xrfdc::GetFabRdVldWordsResponse* response) {
        std::lock_guard<std::mutex> lk(mu_);

        if (!initialized_) {
            auto* status = response->mutable_status();
            status->set_code(1);
            status->set_message("RFDC not initialized. Call CfgInitialize first.");
            return grpc::Status(grpc::StatusCode::FAILED_PRECONDITION, "RFDC not initialized");
        }
        try {
            uint32_t words = rfdc_remote_->GetFabRdVldWords(request->tile_type(), request->tile_id(), request->block_id());

            rfdc_remote_->PopulateStatus(
                response->mutable_status(),
                "GetFabRdVldWords",
                0,  // GetFabRdVldWords doesn't return error code
                request->tile_type(),
                request->tile_id(),
                request->block_id()
            );

            response->set_value(words);
            return grpc::Status::OK;
        } catch (const std::exception& e) {
            auto* status = response->mutable_status();
            status->set_code(1);
            status->set_message(std::string("GetFabRdVldWords failed: ") + e.what());
            return grpc::Status(grpc::StatusCode::INTERNAL, e.what());
        }
    }

grpc::Status XrfdcImpl::SetFabRdVldWords(ServerContext* context,
                                  const xrfdc::SetFabRdVldWordsRequest* request,
                                  xrfdc::TileControlResponse* response) {
        std::lock_guard<std::mutex> lk(mu_);

        if (!initialized_) {
            auto* status = response->mutable_status();
            status->set_code(1);
            status->set_message("RFDC not initialized. Call CfgInitialize first.");
            return grpc::Status(grpc::StatusCode::FAILED_PRECONDITION, "RFDC not initialized");
        }
        try {
            u32 ret = rfdc_remote_->SetFabRdVldWords(XRFDC_ADC_TILE, request->tile_id(),
                                                     request->block_id(), request->value());

            rfdc_remote_->PopulateStatus(
                response->mutable_status(),
                "SetFabRdVldWords",
                ret,
                XRFDC_ADC_TILE,  // FabRdVldWords is ADC-only
                request->tile_id(),
                request->block_id()
            );

            return grpc::Status::OK;
        } catch (const std::exception& e) {
            auto* status = response->mutable_status();
            status->set_code(1);
            status->set_message(std::string("SetFabRdVldWords failed: ") + e.what());
            return grpc::Status(grpc::StatusCode::INTERNAL, e.what());
        }
    }

grpc::Status XrfdcImpl::GetFabWrVldWords(ServerContext* context,
                                  const xrfdc::BlockRequest* request,
                                  xrfdc::GetFabWrVldWordsResponse* response) {
        std::lock_guard<std::mutex> lk(mu_);

        if (!initialized_) {
            auto* status = response->mutable_status();
            status->set_code(1);
            status->set_message("RFDC not initialized. Call CfgInitialize first.");
            return grpc::Status(grpc::StatusCode::FAILED_PRECONDITION, "RFDC not initialized");
        }
        try {
            uint32_t words = rfdc_remote_->GetFabWrVldWords(request->tile_type(), request->tile_id(), request->block_id());

            rfdc_remote_->PopulateStatus(
                response->mutable_status(),
                "GetFabWrVldWords",
                0,  // GetFabWrVldWords doesn't return error code
                request->tile_type(),
                request->tile_id(),
                request->block_id()
            );

            response->set_value(words);
            return grpc::Status::OK;
        } catch (const std::exception& e) {
            auto* status = response->mutable_status();
            status->set_code(1);
            status->set_message(std::string("GetFabWrVldWords failed: ") + e.what());
            return grpc::Status(grpc::StatusCode::INTERNAL, e.what());
        }
    }

grpc::Status XrfdcImpl::SetFabWrVldWords(ServerContext* context,
                                  const xrfdc::SetFabWrVldWordsRequest* request,
                                  xrfdc::TileControlResponse* response) {
        std::lock_guard<std::mutex> lk(mu_);

        if (!initialized_) {
            auto* status = response->mutable_status();
            status->set_code(1);
            status->set_message("RFDC not initialized. Call CfgInitialize first.");
            return grpc::Status(grpc::StatusCode::FAILED_PRECONDITION, "RFDC not initialized");
        }
        try {
            u32 ret = rfdc_remote_->SetFabWrVldWords(XRFDC_DAC_TILE, request->tile_id(),
                                                     request->block_id(), request->value());

            rfdc_remote_->PopulateStatus(
                response->mutable_status(),
                "SetFabWrVldWords",
                ret,
                XRFDC_DAC_TILE,  // FabWrVldWords is DAC-only
                request->tile_id(),
                request->block_id()
            );

            return grpc::Status::OK;
        } catch (const std::exception& e) {
            auto* status = response->mutable_status();
            status->set_code(1);
            status->set_message(std::string("SetFabWrVldWords failed: ") + e.what());
            return grpc::Status(grpc::StatusCode::INTERNAL, e.what());
        }
    }

grpc::Status XrfdcImpl::GetDither(ServerContext* context,
                           const xrfdc::BlockRequest* request,
                           xrfdc::GetDitherResponse* response) {
        std::lock_guard<std::mutex> lk(mu_);

        if (!initialized_) {
            auto* status = response->mutable_status();
            status->set_code(1);
            status->set_message("RFDC not initialized. Call CfgInitialize first.");
            return grpc::Status(grpc::StatusCode::FAILED_PRECONDITION, "RFDC not initialized");
        }
        try {
            uint32_t dither = rfdc_remote_->GetDither(request->tile_id(), request->block_id());

            rfdc_remote_->PopulateStatus(
                response->mutable_status(),
                "GetDither",
                0,  // GetDither doesn't return error code
                XRFDC_DAC_TILE,  // Dither is DAC-only
                request->tile_id(),
                request->block_id()
            );

            response->set_value(dither);
            return grpc::Status::OK;
        } catch (const std::exception& e) {
            auto* status = response->mutable_status();
            status->set_code(1);
            status->set_message(std::string("GetDither failed: ") + e.what());
            return grpc::Status(grpc::StatusCode::INTERNAL, e.what());
        }
    }

grpc::Status XrfdcImpl::SetDither(ServerContext* context,
                           const xrfdc::SetDitherRequest* request,
                           xrfdc::TileControlResponse* response) {
        std::lock_guard<std::mutex> lk(mu_);

        if (!initialized_) {
            auto* status = response->mutable_status();
            status->set_code(1);
            status->set_message("RFDC not initialized. Call CfgInitialize first.");
            return grpc::Status(grpc::StatusCode::FAILED_PRECONDITION, "RFDC not initialized");
        }
        try {
            u32 ret = rfdc_remote_->SetDither(request->tile_id(), request->block_id(), request->value());

            rfdc_remote_->PopulateStatus(
                response->mutable_status(),
                "SetDither",
                ret,
                XRFDC_DAC_TILE,  // Dither is DAC-only
                request->tile_id(),
                request->block_id()
            );

            return grpc::Status::OK;
        } catch (const std::exception& e) {
            auto* status = response->mutable_status();
            status->set_code(1);
            status->set_message(std::string("SetDither failed: ") + e.what());
            return grpc::Status(grpc::StatusCode::INTERNAL, e.what());
        }
    }

grpc::Status XrfdcImpl::GetDecoderMode(ServerContext* context,
                                const xrfdc::BlockRequest* request,
                                xrfdc::GetDecoderModeResponse* response) {
        std::lock_guard<std::mutex> lk(mu_);

        if (!initialized_) {
            auto* status = response->mutable_status();
            status->set_code(1);
            status->set_message("RFDC not initialized. Call CfgInitialize first.");
            return grpc::Status(grpc::StatusCode::FAILED_PRECONDITION, "RFDC not initialized");
        }
        try {
            uint32_t mode = rfdc_remote_->GetDecoderMode(request->tile_id(), request->block_id());

            rfdc_remote_->PopulateStatus(
                response->mutable_status(),
                "GetDecoderMode",
                0,  // GetDecoderMode doesn't return error code
                XRFDC_ADC_TILE,  // Decoder is ADC-only
                request->tile_id(),
                request->block_id()
            );

            response->set_value(mode);
            return grpc::Status::OK;
        } catch (const std::exception& e) {
            auto* status = response->mutable_status();
            status->set_code(1);
            status->set_message(std::string("GetDecoderMode failed: ") + e.what());
            return grpc::Status(grpc::StatusCode::INTERNAL, e.what());
        }
    }

grpc::Status XrfdcImpl::SetDecoderMode(ServerContext* context,
                                const xrfdc::SetDecoderModeRequest* request,
                                xrfdc::TileControlResponse* response) {
        std::lock_guard<std::mutex> lk(mu_);

        if (!initialized_) {
            auto* status = response->mutable_status();
            status->set_code(1);
            status->set_message("RFDC not initialized. Call CfgInitialize first.");
            return grpc::Status(grpc::StatusCode::FAILED_PRECONDITION, "RFDC not initialized");
        }
        try {
            u32 ret = rfdc_remote_->SetDecoderMode(request->tile_id(), request->block_id(), request->value());

            rfdc_remote_->PopulateStatus(
                response->mutable_status(),
                "SetDecoderMode",
                ret,
                XRFDC_ADC_TILE,  // Decoder is ADC-only
                request->tile_id(),
                request->block_id()
            );

            return grpc::Status::OK;
        } catch (const std::exception& e) {
            auto* status = response->mutable_status();
            status->set_code(1);
            status->set_message(std::string("SetDecoderMode failed: ") + e.what());
            return grpc::Status(grpc::StatusCode::INTERNAL, e.what());
        }
    }

grpc::Status XrfdcImpl::GetOutputCurr(ServerContext* context,
                               const xrfdc::BlockRequest* request,
                               xrfdc::GetOutputCurrResponse* response) {
        std::lock_guard<std::mutex> lk(mu_);

        if (!initialized_) {
            auto* status = response->mutable_status();
            status->set_code(1);
            status->set_message("RFDC not initialized. Call CfgInitialize first.");
            return grpc::Status(grpc::StatusCode::FAILED_PRECONDITION, "RFDC not initialized");
        }
        try {
            int current = rfdc_remote_->GetOutputCurr(request->tile_id(), request->block_id());

            rfdc_remote_->PopulateStatus(
                response->mutable_status(),
                "GetOutputCurr",
                0,  // GetOutputCurr doesn't return error code
                XRFDC_DAC_TILE,  // Output current is DAC-only
                request->tile_id(),
                request->block_id()
            );

            response->set_value(current);
            return grpc::Status::OK;
        } catch (const std::exception& e) {
            auto* status = response->mutable_status();
            status->set_code(1);
            status->set_message(std::string("GetOutputCurr failed: ") + e.what());
            return grpc::Status(grpc::StatusCode::INTERNAL, e.what());
        }
    }

grpc::Status XrfdcImpl::GetInvSincFIR(ServerContext* context,
                               const xrfdc::BlockRequest* request,
                               xrfdc::GetInvSincFIRResponse* response) {
        std::lock_guard<std::mutex> lk(mu_);

        if (!initialized_) {
            auto* status = response->mutable_status();
            status->set_code(1);
            status->set_message("RFDC not initialized. Call CfgInitialize first.");
            return grpc::Status(grpc::StatusCode::FAILED_PRECONDITION, "RFDC not initialized");
        }
        try {
            uint16_t mode = rfdc_remote_->GetInvSincFIR(request->tile_id(), request->block_id());

            rfdc_remote_->PopulateStatus(
                response->mutable_status(),
                "GetInvSincFIR",
                0,  // GetInvSincFIR doesn't return error code
                XRFDC_DAC_TILE,  // InvSincFIR is DAC-only
                request->tile_id(),
                request->block_id()
            );

            response->set_value(mode);
            return grpc::Status::OK;
        } catch (const std::exception& e) {
            auto* status = response->mutable_status();
            status->set_code(1);
            status->set_message(std::string("GetInvSincFIR failed: ") + e.what());
            return grpc::Status(grpc::StatusCode::INTERNAL, e.what());
        }
    }

grpc::Status XrfdcImpl::SetInvSincFIR(ServerContext* context,
                               const xrfdc::SetInvSincFIRRequest* request,
                               xrfdc::TileControlResponse* response) {
        std::lock_guard<std::mutex> lk(mu_);

        if (!initialized_) {
            auto* status = response->mutable_status();
            status->set_code(1);
            status->set_message("RFDC not initialized. Call CfgInitialize first.");
            return grpc::Status(grpc::StatusCode::FAILED_PRECONDITION, "RFDC not initialized");
        }
        try {
            u32 ret = rfdc_remote_->SetInvSincFIR(request->tile_id(), request->block_id(), request->value());

            rfdc_remote_->PopulateStatus(
                response->mutable_status(),
                "SetInvSincFIR",
                ret,
                XRFDC_DAC_TILE,  // InvSincFIR is DAC-only
                request->tile_id(),
                request->block_id()
            );

            return grpc::Status::OK;
        } catch (const std::exception& e) {
            auto* status = response->mutable_status();
            status->set_code(1);
            status->set_message(std::string("SetInvSincFIR failed: ") + e.what());
            return grpc::Status(grpc::StatusCode::INTERNAL, e.what());
        }
    }

grpc::Status XrfdcImpl::GetDataPathMode(ServerContext* context,
                                 const xrfdc::BlockRequest* request,
                                 xrfdc::GetDataPathModeResponse* response) {
        std::lock_guard<std::mutex> lk(mu_);

        if (!initialized_) {
            auto* status = response->mutable_status();
            status->set_code(1);
            status->set_message("RFDC not initialized. Call CfgInitialize first.");
            return grpc::Status(grpc::StatusCode::FAILED_PRECONDITION, "RFDC not initialized");
        }
        try {
            uint32_t mode = rfdc_remote_->GetDataPathMode(request->tile_id(), request->block_id());

            rfdc_remote_->PopulateStatus(
                response->mutable_status(),
                "GetDataPathMode",
                0,  // GetDataPathMode doesn't return error code
                XRFDC_ADC_TILE,  // DataPathMode is ADC-only
                request->tile_id(),
                request->block_id()
            );

            response->set_value(mode);
            return grpc::Status::OK;
        } catch (const std::exception& e) {
            auto* status = response->mutable_status();
            status->set_code(1);
            status->set_message(std::string("GetDataPathMode failed: ") + e.what());
            return grpc::Status(grpc::StatusCode::INTERNAL, e.what());
        }
    }

grpc::Status XrfdcImpl::SetDataPathMode(ServerContext* context,
                                 const xrfdc::SetDataPathModeRequest* request,
                                 xrfdc::TileControlResponse* response) {
        std::lock_guard<std::mutex> lk(mu_);

        if (!initialized_) {
            auto* status = response->mutable_status();
            status->set_code(1);
            status->set_message("RFDC not initialized. Call CfgInitialize first.");
            return grpc::Status(grpc::StatusCode::FAILED_PRECONDITION, "RFDC not initialized");
        }
        try {
            u32 ret = rfdc_remote_->SetDataPathMode(request->tile_id(), request->block_id(), request->value());

            rfdc_remote_->PopulateStatus(
                response->mutable_status(),
                "SetDataPathMode",
                ret,
                XRFDC_ADC_TILE,  // DataPathMode is ADC-only
                request->tile_id(),
                request->block_id()
            );

            return grpc::Status::OK;
        } catch (const std::exception& e) {
            auto* status = response->mutable_status();
            status->set_code(1);
            status->set_message(std::string("SetDataPathMode failed: ") + e.what());
            return grpc::Status(grpc::StatusCode::INTERNAL, e.what());
        }
    }

grpc::Status XrfdcImpl::GetIMRPassMode(ServerContext* context,
                                const xrfdc::BlockRequest* request,
                                xrfdc::GetIMRPassModeResponse* response) {
        std::lock_guard<std::mutex> lk(mu_);

        if (!initialized_) {
            auto* status = response->mutable_status();
            status->set_code(1);
            status->set_message("RFDC not initialized. Call CfgInitialize first.");
            return grpc::Status(grpc::StatusCode::FAILED_PRECONDITION, "RFDC not initialized");
        }
        try {
            uint32_t mode = rfdc_remote_->GetIMRPassMode(request->tile_id(), request->block_id());

            rfdc_remote_->PopulateStatus(
                response->mutable_status(),
                "GetIMRPassMode",
                0,  // GetIMRPassMode doesn't return error code
                XRFDC_ADC_TILE,  // IMRPassMode is ADC-only
                request->tile_id(),
                request->block_id()
            );

            response->set_value(mode);
            return grpc::Status::OK;
        } catch (const std::exception& e) {
            auto* status = response->mutable_status();
            status->set_code(1);
            status->set_message(std::string("GetIMRPassMode failed: ") + e.what());
            return grpc::Status(grpc::StatusCode::INTERNAL, e.what());
        }
    }

grpc::Status XrfdcImpl::SetIMRPassMode(ServerContext* context,
                                const xrfdc::SetIMRPassModeRequest* request,
                                xrfdc::TileControlResponse* response) {
        std::lock_guard<std::mutex> lk(mu_);

        if (!initialized_) {
            auto* status = response->mutable_status();
            status->set_code(1);
            status->set_message("RFDC not initialized. Call CfgInitialize first.");
            return grpc::Status(grpc::StatusCode::FAILED_PRECONDITION, "RFDC not initialized");
        }
        try {
            u32 ret = rfdc_remote_->SetIMRPassMode(request->tile_id(), request->block_id(), request->value());

            rfdc_remote_->PopulateStatus(
                response->mutable_status(),
                "SetIMRPassMode",
                ret,
                XRFDC_ADC_TILE,  // IMRPassMode is ADC-only
                request->tile_id(),
                request->block_id()
            );

            return grpc::Status::OK;
        } catch (const std::exception& e) {
            auto* status = response->mutable_status();
            status->set_code(1);
            status->set_message(std::string("SetIMRPassMode failed: ") + e.what());
            return grpc::Status(grpc::StatusCode::INTERNAL, e.what());
        }
    }

grpc::Status XrfdcImpl::GetDACCompMode(ServerContext* context,
                                const xrfdc::BlockRequest* request,
                                xrfdc::GetDACCompModeResponse* response) {
        std::lock_guard<std::mutex> lk(mu_);

        if (!initialized_) {
            auto* status = response->mutable_status();
            status->set_code(1);
            status->set_message("RFDC not initialized. Call CfgInitialize first.");
            return grpc::Status(grpc::StatusCode::FAILED_PRECONDITION, "RFDC not initialized");
        }
        try {
            uint32_t mode = rfdc_remote_->GetDACCompMode(request->tile_id(), request->block_id());

            rfdc_remote_->PopulateStatus(
                response->mutable_status(),
                "GetDACCompMode",
                0,  // GetDACCompMode doesn't return error code
                XRFDC_DAC_TILE,  // DACCompMode is DAC-only
                request->tile_id(),
                request->block_id()
            );

            response->set_value(mode);
            return grpc::Status::OK;
        } catch (const std::exception& e) {
            auto* status = response->mutable_status();
            status->set_code(1);
            status->set_message(std::string("GetDACCompMode failed: ") + e.what());
            return grpc::Status(grpc::StatusCode::INTERNAL, e.what());
        }
    }

grpc::Status XrfdcImpl::SetDACCompMode(ServerContext* context,
                                const xrfdc::SetDACCompModeRequest* request,
                                xrfdc::TileControlResponse* response) {
        std::lock_guard<std::mutex> lk(mu_);

        if (!initialized_) {
            auto* status = response->mutable_status();
            status->set_code(1);
            status->set_message("RFDC not initialized. Call CfgInitialize first.");
            return grpc::Status(grpc::StatusCode::FAILED_PRECONDITION, "RFDC not initialized");
        }
        try {
            u32 ret = rfdc_remote_->SetDACCompMode(request->tile_id(), request->block_id(), request->value());

            rfdc_remote_->PopulateStatus(
                response->mutable_status(),
                "SetDACCompMode",
                ret,
                XRFDC_DAC_TILE,  // DACCompMode is DAC-only
                request->tile_id(),
                request->block_id()
            );

            return grpc::Status::OK;
        } catch (const std::exception& e) {
            auto* status = response->mutable_status();
            status->set_code(1);
            status->set_message(std::string("SetDACCompMode failed: ") + e.what());
            return grpc::Status(grpc::StatusCode::INTERNAL, e.what());
        }
    }

grpc::Status XrfdcImpl::SetDACVOP(ServerContext* context,
                           const xrfdc::SetDACVOPRequest* request,
                           xrfdc::TileControlResponse* response) {
        std::lock_guard<std::mutex> lk(mu_);

        if (!initialized_) {
            auto* status = response->mutable_status();
            status->set_code(1);
            status->set_message("RFDC not initialized. Call CfgInitialize first.");
            return grpc::Status(grpc::StatusCode::FAILED_PRECONDITION, "RFDC not initialized");
        }
        try {
            u32 ret = rfdc_remote_->SetDACVOP(request->tile_id(), request->block_id(), request->ua_current());

            rfdc_remote_->PopulateStatus(
                response->mutable_status(),
                "SetDACVOP",
                ret,
                XRFDC_DAC_TILE,  // DACVOP is DAC-only
                request->tile_id(),
                request->block_id()
            );

            return grpc::Status::OK;
        } catch (const std::exception& e) {
            auto* status = response->mutable_status();
            status->set_code(1);
            status->set_message(std::string("SetDACVOP failed: ") + e.what());
            return grpc::Status(grpc::StatusCode::INTERNAL, e.what());
        }
    }

grpc::Status XrfdcImpl::DumpRegs(ServerContext* context,
                          const xrfdc::TileRequest* request,
                          xrfdc::TileControlResponse* response) {
        std::lock_guard<std::mutex> lk(mu_);

        if (!initialized_) {
            auto* status = response->mutable_status();
            status->set_code(1);
            status->set_message("RFDC not initialized. Call CfgInitialize first.");
            return grpc::Status(grpc::StatusCode::FAILED_PRECONDITION, "RFDC not initialized");
        }
        try {
            rfdc_remote_->DumpRegs(request->tile_type(), request->tile_id());
            auto* status = response->mutable_status();
            status->set_code(0);
            status->set_message("Registers dumped successfully");
            return grpc::Status::OK;
        } catch (const std::exception& e) {
            auto* status = response->mutable_status();
            status->set_code(1);
            status->set_message(std::string("DumpRegs failed: ") + e.what());
            return grpc::Status(grpc::StatusCode::INTERNAL, e.what());
        }
    }

grpc::Status XrfdcImpl::SetupFIFOObs(ServerContext* context,
                              const xrfdc::SetupFIFORequest* request,
                              xrfdc::TileControlResponse* response) {
        std::lock_guard<std::mutex> lk(mu_);

        if (!initialized_) {
            auto* status = response->mutable_status();
            status->set_code(1);
            status->set_message("RFDC not initialized. Call CfgInitialize first.");
            return grpc::Status(grpc::StatusCode::FAILED_PRECONDITION, "RFDC not initialized");
        }
        try {
            u32 ret = rfdc_remote_->SetupFIFOObs(request->tile_type(), request->tile_id(), request->enable() ? 1 : 0);

            rfdc_remote_->PopulateStatus(
                response->mutable_status(),
                "SetupFIFOObs",
                ret,
                request->tile_type(),
                request->tile_id(),
                -1  // Tile-level operation
            );

            return grpc::Status::OK;
        } catch (const std::exception& e) {
            auto* status = response->mutable_status();
            status->set_code(1);
            status->set_message(std::string("SetupFIFOObs failed: ") + e.what());
            return grpc::Status(grpc::StatusCode::INTERNAL, e.what());
        }
    }

grpc::Status XrfdcImpl::SetupFIFOBoth(ServerContext* context,
                               const xrfdc::SetupFIFORequest* request,
                               xrfdc::TileControlResponse* response) {
        std::lock_guard<std::mutex> lk(mu_);

        if (!initialized_) {
            auto* status = response->mutable_status();
            status->set_code(1);
            status->set_message("RFDC not initialized. Call CfgInitialize first.");
            return grpc::Status(grpc::StatusCode::FAILED_PRECONDITION, "RFDC not initialized");
        }
        try {
            u32 ret = rfdc_remote_->SetupFIFOBoth(request->tile_type(), request->tile_id(), request->enable() ? 1 : 0);

            rfdc_remote_->PopulateStatus(
                response->mutable_status(),
                "SetupFIFOBoth",
                ret,
                request->tile_type(),
                request->tile_id(),
                -1  // Tile-level operation
            );

            return grpc::Status::OK;
        } catch (const std::exception& e) {
            auto* status = response->mutable_status();
            status->set_code(1);
            status->set_message(std::string("SetupFIFOBoth failed: ") + e.what());
            return grpc::Status(grpc::StatusCode::INTERNAL, e.what());
        }
    }

grpc::Status XrfdcImpl::GetFIFOStatusObs(ServerContext* context,
                                  const xrfdc::TileRequest* request,
                                  xrfdc::GetFIFOStatusResponse* response) {
        std::lock_guard<std::mutex> lk(mu_);

        if (!initialized_) {
            auto* status = response->mutable_status();
            status->set_code(1);
            status->set_message("RFDC not initialized. Call CfgInitialize first.");
            return grpc::Status(grpc::StatusCode::FAILED_PRECONDITION, "RFDC not initialized");
        }
        try {
            uint8_t enable = 0;
            u32 ret = rfdc_remote_->GetFIFOStatusObs(request->tile_type(), request->tile_id(), &enable);

            rfdc_remote_->PopulateStatus(
                response->mutable_status(),
                "GetFIFOStatusObs",
                ret,
                request->tile_type(),
                request->tile_id(),
                -1  // Tile-level operation
            );

            response->set_enable(enable != 0);
            return grpc::Status::OK;
        } catch (const std::exception& e) {
            auto* status = response->mutable_status();
            status->set_code(1);
            status->set_message(std::string("GetFIFOStatusObs failed: ") + e.what());
            return grpc::Status(grpc::StatusCode::INTERNAL, e.what());
        }
    }

    // ============================================================================
    // Missing gRPC Service Method Implementations
    // ============================================================================

grpc::Status XrfdcImpl::GetPLLConfig(ServerContext* context,
                              const xrfdc::TileRequest* request,
                              xrfdc::GetPLLConfigResponse* response) {
        std::lock_guard<std::mutex> lk(mu_);

        std::cerr << "[XRFDC] GetPLLConfig called: tile_type=" << request->tile_type()
                  << " tile_id=" << request->tile_id() << std::endl;

        if (!initialized_) {
            std::cerr << "[XRFDC] ERROR: RFDC not initialized!" << std::endl;
            auto* status = response->mutable_status();
            status->set_code(1);
            status->set_message("RFDC not initialized. Call CfgInitialize first.");
            return grpc::Status(grpc::StatusCode::FAILED_PRECONDITION, "RFDC not initialized");
        }
        try {
            XRFdc_PLL_Settings pll_settings;
            u32 ret = rfdc_remote_->GetPLLConfig(request->tile_type(), request->tile_id(), &pll_settings);
            std::cerr << "[XRFDC] GetPLLConfig returned: " << ret
                      << (ret == 0 ? " (SUCCESS)" : " (FAILED)") << std::endl;

            rfdc_remote_->PopulateStatus(
                response->mutable_status(),
                "GetPLLConfig",
                ret,
                request->tile_type(),
                request->tile_id(),
                -1  // Tile-level operation
            );

            if (ret == 0) {
                auto* settings = response->mutable_settings();
                settings->set_enabled(pll_settings.Enabled);
                settings->set_ref_clk_freq(pll_settings.RefClkFreq);
                settings->set_sample_rate(pll_settings.SampleRate);
                settings->set_ref_clk_divider(pll_settings.RefClkDivider);
                settings->set_feedback_divider(pll_settings.FeedbackDivider);
                settings->set_output_divider(pll_settings.OutputDivider);
                settings->set_fractional_mode(pll_settings.FractionalMode);
                settings->set_fractional_data(pll_settings.FractionalData);
                settings->set_fract_width(pll_settings.FractWidth);

                std::cerr << "[XRFDC]   PLL Settings: enabled=" << pll_settings.Enabled
                          << " ref_clk=" << pll_settings.RefClkFreq << " MHz"
                          << " sample_rate=" << pll_settings.SampleRate << " MSPS"
                          << " ref_div=" << pll_settings.RefClkDivider
                          << " fb_div=" << pll_settings.FeedbackDivider
                          << " out_div=" << pll_settings.OutputDivider << std::endl;
            }
            return grpc::Status::OK;
        } catch (const std::exception& e) {
            std::cerr << "[XRFDC] GetPLLConfig exception: " << e.what() << std::endl;
            auto* status = response->mutable_status();
            status->set_code(1);
            status->set_message(std::string("GetPLLConfig failed: ") + e.what());
            return grpc::Status(grpc::StatusCode::INTERNAL, e.what());
        }
    }

grpc::Status XrfdcImpl::GetCoarseDelaySettings(ServerContext* context,
                                        const xrfdc::GetCoarseDelaySettingsRequest* request,
                                        xrfdc::GetCoarseDelaySettingsResponse* response) {
        std::lock_guard<std::mutex> lk(mu_);

        if (!initialized_) {
            auto* status = response->mutable_status();
            status->set_code(1);
            status->set_message("RFDC not initialized. Call CfgInitialize first.");
            return grpc::Status(grpc::StatusCode::FAILED_PRECONDITION, "RFDC not initialized");
        }
        try {
            XRFdc_CoarseDelay_Settings settings;
            u32 ret = rfdc_remote_->GetCoarseDelaySettings(request->tile_type(), request->tile_id(),
                                                           request->block_id(), &settings);

            rfdc_remote_->PopulateStatus(
                response->mutable_status(),
                "GetCoarseDelaySettings",
                ret,
                request->tile_type(),
                request->tile_id(),
                request->block_id()
            );

            if (ret == 0) {
                auto* delay_settings = response->mutable_settings();
                delay_settings->set_coarse_delay(settings.CoarseDelay);
                delay_settings->set_event_source(settings.EventSource);
            }
            return grpc::Status::OK;
        } catch (const std::exception& e) {
            auto* status = response->mutable_status();
            status->set_code(1);
            status->set_message(std::string("GetCoarseDelaySettings failed: ") + e.what());
            return grpc::Status(grpc::StatusCode::INTERNAL, e.what());
        }
    }

grpc::Status XrfdcImpl::SetCoarseDelaySettings(ServerContext* context,
                                        const xrfdc::SetCoarseDelaySettingsRequest* request,
                                        xrfdc::SetCoarseDelaySettingsResponse* response) {
        std::lock_guard<std::mutex> lk(mu_);

        if (!initialized_) {
            auto* status = response->mutable_status();
            status->set_code(1);
            status->set_message("RFDC not initialized. Call CfgInitialize first.");
            return grpc::Status(grpc::StatusCode::FAILED_PRECONDITION, "RFDC not initialized");
        }
        try {
            XRFdc_CoarseDelay_Settings settings;
            settings.CoarseDelay = request->settings().coarse_delay();
            settings.EventSource = request->settings().event_source();
            u32 ret = rfdc_remote_->SetCoarseDelaySettings(request->tile_type(), request->tile_id(),
                                                           request->block_id(), &settings);

            rfdc_remote_->PopulateStatus(
                response->mutable_status(),
                "SetCoarseDelaySettings",
                ret,
                request->tile_type(),
                request->tile_id(),
                request->block_id()
            );

            return grpc::Status::OK;
        } catch (const std::exception& e) {
            auto* status = response->mutable_status();
            status->set_code(1);
            status->set_message(std::string("SetCoarseDelaySettings failed: ") + e.what());
            return grpc::Status(grpc::StatusCode::INTERNAL, e.what());
        }
    }

grpc::Status XrfdcImpl::GetPwrMode(ServerContext* context,
                            const xrfdc::BlockRequest* request,
                            xrfdc::GetPwrModeResponse* response) {
        std::lock_guard<std::mutex> lk(mu_);

        if (!initialized_) {
            auto* status = response->mutable_status();
            status->set_code(1);
            status->set_message("RFDC not initialized. Call CfgInitialize first.");
            return grpc::Status(grpc::StatusCode::FAILED_PRECONDITION, "RFDC not initialized");
        }
        try {
            XRFdc_Pwr_Mode_Settings settings;
            u32 ret = rfdc_remote_->GetPwrMode(request->tile_type(), request->tile_id(),
                                               request->block_id(), &settings);

            rfdc_remote_->PopulateStatus(
                response->mutable_status(),
                "GetPwrMode",
                ret,
                request->tile_type(),
                request->tile_id(),
                request->block_id()
            );

            if (ret == 0) {
                auto* pwr_settings = response->mutable_settings();
                pwr_settings->set_disable_ip_control(settings.DisableIPControl);
                pwr_settings->set_pwr_mode(settings.PwrMode);
            }
            return grpc::Status::OK;
        } catch (const std::exception& e) {
            auto* status = response->mutable_status();
            status->set_code(1);
            status->set_message(std::string("GetPwrMode failed: ") + e.what());
            return grpc::Status(grpc::StatusCode::INTERNAL, e.what());
        }
    }

grpc::Status XrfdcImpl::SetPwrMode(ServerContext* context,
                            const xrfdc::SetPwrModeRequest* request,
                            xrfdc::TileControlResponse* response) {
        std::lock_guard<std::mutex> lk(mu_);

        if (!initialized_) {
            auto* status = response->mutable_status();
            status->set_code(1);
            status->set_message("RFDC not initialized. Call CfgInitialize first.");
            return grpc::Status(grpc::StatusCode::FAILED_PRECONDITION, "RFDC not initialized");
        }
        try {
            XRFdc_Pwr_Mode_Settings settings;
            settings.DisableIPControl = request->settings().disable_ip_control();
            settings.PwrMode = request->settings().pwr_mode();
            u32 ret = rfdc_remote_->SetPwrMode(request->tile_type(), request->tile_id(),
                                               request->block_id(), &settings);

            rfdc_remote_->PopulateStatus(
                response->mutable_status(),
                "SetPwrMode",
                ret,
                request->tile_type(),
                request->tile_id(),
                request->block_id()
            );

            return grpc::Status::OK;
        } catch (const std::exception& e) {
            auto* status = response->mutable_status();
            status->set_code(1);
            status->set_message(std::string("SetPwrMode failed: ") + e.what());
            return grpc::Status(grpc::StatusCode::INTERNAL, e.what());
        }
    }

grpc::Status XrfdcImpl::GetDecimationFactorObs(ServerContext* context,
                                        const xrfdc::BlockRequest* request,
                                        xrfdc::GetDecimationFactorResponse* response) {
        std::lock_guard<std::mutex> lk(mu_);

        if (!initialized_) {
            auto* status = response->mutable_status();
            status->set_code(1);
            status->set_message("RFDC not initialized. Call CfgInitialize first.");
            return grpc::Status(grpc::StatusCode::FAILED_PRECONDITION, "RFDC not initialized");
        }
        try {
            uint32_t dec_factor = 0;
            u32 ret = rfdc_remote_->GetDecimationFactorObs(request->tile_id(), request->block_id(), &dec_factor);

            rfdc_remote_->PopulateStatus(
                response->mutable_status(),
                "GetDecimationFactorObs",
                ret,
                XRFDC_ADC_TILE,  // Obs decimation is ADC-only
                request->tile_id(),
                request->block_id()
            );

            response->set_dec_factor(dec_factor);
            return grpc::Status::OK;
        } catch (const std::exception& e) {
            auto* status = response->mutable_status();
            status->set_code(1);
            status->set_message(std::string("GetDecimationFactorObs failed: ") + e.what());
            return grpc::Status(grpc::StatusCode::INTERNAL, e.what());
        }
    }

grpc::Status XrfdcImpl::SetDecimationFactorObs(ServerContext* context,
                                        const xrfdc::SetDecimationFactorRequest* request,
                                        xrfdc::TileControlResponse* response) {
        std::lock_guard<std::mutex> lk(mu_);

        if (!initialized_) {
            auto* status = response->mutable_status();
            status->set_code(1);
            status->set_message("RFDC not initialized. Call CfgInitialize first.");
            return grpc::Status(grpc::StatusCode::FAILED_PRECONDITION, "RFDC not initialized");
        }
        try {
            u32 ret = rfdc_remote_->SetDecimationFactorObs(request->tile_id(), request->block_id(),
                                                           request->dec_factor());

            rfdc_remote_->PopulateStatus(
                response->mutable_status(),
                "SetDecimationFactorObs",
                ret,
                XRFDC_ADC_TILE,  // Obs decimation is ADC-only
                request->tile_id(),
                request->block_id()
            );

            return grpc::Status::OK;
        } catch (const std::exception& e) {
            auto* status = response->mutable_status();
            status->set_code(1);
            status->set_message(std::string("SetDecimationFactorObs failed: ") + e.what());
            return grpc::Status(grpc::StatusCode::INTERNAL, e.what());
        }
    }

grpc::Status XrfdcImpl::GetFabRdVldWordsObs(ServerContext* context,
                                     const xrfdc::BlockRequest* request,
                                     xrfdc::GetFabRdVldWordsObsResponse* response) {
        std::lock_guard<std::mutex> lk(mu_);

        if (!initialized_) {
            auto* status = response->mutable_status();
            status->set_code(1);
            status->set_message("RFDC not initialized. Call CfgInitialize first.");
            return grpc::Status(grpc::StatusCode::FAILED_PRECONDITION, "RFDC not initialized");
        }
        try {
            uint32_t words = 0;
            u32 ret = rfdc_remote_->GetFabRdVldWordsObs(request->tile_type(), request->tile_id(),
                                                        request->block_id(), &words);

            rfdc_remote_->PopulateStatus(
                response->mutable_status(),
                "GetFabRdVldWordsObs",
                ret,
                request->tile_type(),
                request->tile_id(),
                request->block_id()
            );

            response->set_value(words);
            return grpc::Status::OK;
        } catch (const std::exception& e) {
            auto* status = response->mutable_status();
            status->set_code(1);
            status->set_message(std::string("GetFabRdVldWordsObs failed: ") + e.what());
            return grpc::Status(grpc::StatusCode::INTERNAL, e.what());
        }
    }

grpc::Status XrfdcImpl::SetFabRdVldWordsObs(ServerContext* context,
                                     const xrfdc::SetFabRdVldWordsObsRequest* request,
                                     xrfdc::TileControlResponse* response) {
        std::lock_guard<std::mutex> lk(mu_);

        if (!initialized_) {
            auto* status = response->mutable_status();
            status->set_code(1);
            status->set_message("RFDC not initialized. Call CfgInitialize first.");
            return grpc::Status(grpc::StatusCode::FAILED_PRECONDITION, "RFDC not initialized");
        }
        try {
            u32 ret = rfdc_remote_->SetFabRdVldWordsObs(XRFDC_ADC_TILE, request->tile_id(),
                                                        request->block_id(), request->value());

            rfdc_remote_->PopulateStatus(
                response->mutable_status(),
                "SetFabRdVldWordsObs",
                ret,
                XRFDC_ADC_TILE,  // Obs is ADC-only
                request->tile_id(),
                request->block_id()
            );

            return grpc::Status::OK;
        } catch (const std::exception& e) {
            auto* status = response->mutable_status();
            status->set_code(1);
            status->set_message(std::string("SetFabRdVldWordsObs failed: ") + e.what());
            return grpc::Status(grpc::StatusCode::INTERNAL, e.what());
        }
    }

grpc::Status XrfdcImpl::GetFabWrVldWordsObs(ServerContext* context,
                                     const xrfdc::BlockRequest* request,
                                     xrfdc::GetFabWrVldWordsObsResponse* response) {
        std::lock_guard<std::mutex> lk(mu_);

        if (!initialized_) {
            auto* status = response->mutable_status();
            status->set_code(1);
            status->set_message("RFDC not initialized. Call CfgInitialize first.");
            return grpc::Status(grpc::StatusCode::FAILED_PRECONDITION, "RFDC not initialized");
        }
        try {
            uint32_t words = 0;
            u32 ret = rfdc_remote_->GetFabWrVldWordsObs(request->tile_type(), request->tile_id(),
                                                        request->block_id(), &words);

            rfdc_remote_->PopulateStatus(
                response->mutable_status(),
                "GetFabWrVldWordsObs",
                ret,
                request->tile_type(),
                request->tile_id(),
                request->block_id()
            );

            response->set_value(words);
            return grpc::Status::OK;
        } catch (const std::exception& e) {
            auto* status = response->mutable_status();
            status->set_code(1);
            status->set_message(std::string("GetFabWrVldWordsObs failed: ") + e.what());
            return grpc::Status(grpc::StatusCode::INTERNAL, e.what());
        }
    }

grpc::Status XrfdcImpl::GetCalFreeze(ServerContext* context,
                              const xrfdc::BlockRequest* request,
                              xrfdc::GetCalFreezeResponse* response) {
        std::lock_guard<std::mutex> lk(mu_);

        if (!initialized_) {
            auto* status = response->mutable_status();
            status->set_code(1);
            status->set_message("RFDC not initialized. Call CfgInitialize first.");
            return grpc::Status(grpc::StatusCode::FAILED_PRECONDITION, "RFDC not initialized");
        }
        try {
            XRFdc_Cal_Freeze_Settings settings;
            u32 ret = rfdc_remote_->GetCalFreeze(request->tile_id(), request->block_id(), &settings);

            rfdc_remote_->PopulateStatus(
                response->mutable_status(),
                "GetCalFreeze",
                ret,
                XRFDC_ADC_TILE,  // CalFreeze is ADC-only
                request->tile_id(),
                request->block_id()
            );

            if (ret == 0) {
                auto* freeze_settings = response->mutable_settings();
                freeze_settings->set_cal_frozen(settings.CalFrozen);
                freeze_settings->set_disable_freeze_pin(settings.DisableFreezePin);
                freeze_settings->set_freeze_calibration(settings.FreezeCalibration);
            }
            return grpc::Status::OK;
        } catch (const std::exception& e) {
            auto* status = response->mutable_status();
            status->set_code(1);
            status->set_message(std::string("GetCalFreeze failed: ") + e.what());
            return grpc::Status(grpc::StatusCode::INTERNAL, e.what());
        }
    }

grpc::Status XrfdcImpl::SetCalFreeze(ServerContext* context,
                              const xrfdc::SetCalFreezeRequest* request,
                              xrfdc::TileControlResponse* response) {
        std::lock_guard<std::mutex> lk(mu_);

        if (!initialized_) {
            auto* status = response->mutable_status();
            status->set_code(1);
            status->set_message("RFDC not initialized. Call CfgInitialize first.");
            return grpc::Status(grpc::StatusCode::FAILED_PRECONDITION, "RFDC not initialized");
        }
        try {
            XRFdc_Cal_Freeze_Settings settings;
            settings.CalFrozen = request->settings().cal_frozen();
            settings.DisableFreezePin = request->settings().disable_freeze_pin();
            settings.FreezeCalibration = request->settings().freeze_calibration();
            u32 ret = rfdc_remote_->SetCalFreeze(request->tile_id(), request->block_id(), &settings);

            rfdc_remote_->PopulateStatus(
                response->mutable_status(),
                "SetCalFreeze",
                ret,
                XRFDC_ADC_TILE,  // CalFreeze is ADC-only
                request->tile_id(),
                request->block_id()
            );

            return grpc::Status::OK;
        } catch (const std::exception& e) {
            auto* status = response->mutable_status();
            status->set_code(1);
            status->set_message(std::string("SetCalFreeze failed: ") + e.what());
            return grpc::Status(grpc::StatusCode::INTERNAL, e.what());
        }
    }

grpc::Status XrfdcImpl::GetDSA(ServerContext* context,
                        const xrfdc::BlockRequest* request,
                        xrfdc::GetDSAResponse* response) {
        std::lock_guard<std::mutex> lk(mu_);

        if (!initialized_) {
            auto* status = response->mutable_status();
            status->set_code(1);
            status->set_message("RFDC not initialized. Call CfgInitialize first.");
            return grpc::Status(grpc::StatusCode::FAILED_PRECONDITION, "RFDC not initialized");
        }
        try {
            XRFdc_DSA_Settings settings;
            u32 ret = rfdc_remote_->GetDSA(request->tile_id(), request->block_id(), &settings);

            rfdc_remote_->PopulateStatus(
                response->mutable_status(),
                "GetDSA",
                ret,
                XRFDC_DAC_TILE,  // DSA is DAC-only
                request->tile_id(),
                request->block_id()
            );

            if (ret == 0) {
                auto* dsa_settings = response->mutable_settings();
                dsa_settings->set_disable_rts(settings.DisableRTS);
                dsa_settings->set_attenuation(settings.Attenuation);
            }
            return grpc::Status::OK;
        } catch (const std::exception& e) {
            auto* status = response->mutable_status();
            status->set_code(1);
            status->set_message(std::string("GetDSA failed: ") + e.what());
            return grpc::Status(grpc::StatusCode::INTERNAL, e.what());
        }
    }

grpc::Status XrfdcImpl::SetDSA(ServerContext* context,
                        const xrfdc::SetDSARequest* request,
                        xrfdc::TileControlResponse* response) {
        std::lock_guard<std::mutex> lk(mu_);

        if (!initialized_) {
            auto* status = response->mutable_status();
            status->set_code(1);
            status->set_message("RFDC not initialized. Call CfgInitialize first.");
            return grpc::Status(grpc::StatusCode::FAILED_PRECONDITION, "RFDC not initialized");
        }
        try {
            XRFdc_DSA_Settings settings;
            settings.DisableRTS = request->settings().disable_rts();
            settings.Attenuation = request->settings().attenuation();
            u32 ret = rfdc_remote_->SetDSA(request->tile_id(), request->block_id(), &settings);

            rfdc_remote_->PopulateStatus(
                response->mutable_status(),
                "SetDSA",
                ret,
                XRFDC_DAC_TILE,  // DSA is DAC-only
                request->tile_id(),
                request->block_id()
            );

            return grpc::Status::OK;
        } catch (const std::exception& e) {
            auto* status = response->mutable_status();
            status->set_code(1);
            status->set_message(std::string("SetDSA failed: ") + e.what());
            return grpc::Status(grpc::StatusCode::INTERNAL, e.what());
        }
    }

grpc::Status XrfdcImpl::DisableCoefficientsOverride(ServerContext* context,
                                             const xrfdc::DisableCoefficientsOverrideRequest* request,
                                             xrfdc::TileControlResponse* response) {
        std::lock_guard<std::mutex> lk(mu_);

        if (!initialized_) {
            auto* status = response->mutable_status();
            status->set_code(1);
            status->set_message("RFDC not initialized. Call CfgInitialize first.");
            return grpc::Status(grpc::StatusCode::FAILED_PRECONDITION, "RFDC not initialized");
        }
        try {
            u32 ret = rfdc_remote_->DisableCoefficientsOverride(request->tile_id(), request->block_id(),
                                                                request->calibration_block());

            rfdc_remote_->PopulateStatus(
                response->mutable_status(),
                "DisableCoefficientsOverride",
                ret,
                XRFDC_ADC_TILE,  // Coefficients are ADC-only
                request->tile_id(),
                request->block_id()
            );

            return grpc::Status::OK;
        } catch (const std::exception& e) {
            auto* status = response->mutable_status();
            status->set_code(1);
            status->set_message(std::string("DisableCoefficientsOverride failed: ") + e.what());
            return grpc::Status(grpc::StatusCode::INTERNAL, e.what());
        }
    }

grpc::Status XrfdcImpl::ResetInternalFIFOWidthObs(ServerContext* context,
                                           const xrfdc::BlockRequest* request,
                                           xrfdc::TileControlResponse* response) {
        std::lock_guard<std::mutex> lk(mu_);

        if (!initialized_) {
            auto* status = response->mutable_status();
            status->set_code(1);
            status->set_message("RFDC not initialized. Call CfgInitialize first.");
            return grpc::Status(grpc::StatusCode::FAILED_PRECONDITION, "RFDC not initialized");
        }
        try {
            u32 ret = rfdc_remote_->ResetInternalFIFOWidthObs(request->tile_type(), request->tile_id(),
                                                              request->block_id());

            rfdc_remote_->PopulateStatus(
                response->mutable_status(),
                "ResetInternalFIFOWidthObs",
                ret,
                request->tile_type(),
                request->tile_id(),
                request->block_id()
            );

            return grpc::Status::OK;
        } catch (const std::exception& e) {
            auto* status = response->mutable_status();
            status->set_code(1);
            status->set_message(std::string("ResetInternalFIFOWidthObs failed: ") + e.what());
            return grpc::Status(grpc::StatusCode::INTERNAL, e.what());
        }
    }

grpc::Status XrfdcImpl::SetCalCoefficients(ServerContext* context,
                                    const xrfdc::SetCalCoefficientsRequest* request,
                                    xrfdc::TileControlResponse* response) {
        std::lock_guard<std::mutex> lk(mu_);

        if (!initialized_) {
            auto* status = response->mutable_status();
            status->set_code(1);
            status->set_message("RFDC not initialized. Call CfgInitialize first.");
            return grpc::Status(grpc::StatusCode::FAILED_PRECONDITION, "RFDC not initialized");
        }
        try {
            XRFdc_Calibration_Coefficients coeffs;
            coeffs.Coeff0 = request->coeffs().coeff0();
            coeffs.Coeff1 = request->coeffs().coeff1();
            coeffs.Coeff2 = request->coeffs().coeff2();
            coeffs.Coeff3 = request->coeffs().coeff3();
            coeffs.Coeff4 = request->coeffs().coeff4();
            coeffs.Coeff5 = request->coeffs().coeff5();
            coeffs.Coeff6 = request->coeffs().coeff6();
            coeffs.Coeff7 = request->coeffs().coeff7();
            u32 ret = rfdc_remote_->SetCalCoefficients(request->tile_id(), request->block_id(),
                                                       request->calibration_block(), &coeffs);

            rfdc_remote_->PopulateStatus(
                response->mutable_status(),
                "SetCalCoefficients",
                ret,
                XRFDC_ADC_TILE,  // Calibration is ADC-only
                request->tile_id(),
                request->block_id()
            );

            return grpc::Status::OK;
        } catch (const std::exception& e) {
            auto* status = response->mutable_status();
            status->set_code(1);
            status->set_message(std::string("SetCalCoefficients failed: ") + e.what());
            return grpc::Status(grpc::StatusCode::INTERNAL, e.what());
        }
    }

grpc::Status XrfdcImpl::GetCalCoefficients(ServerContext* context,
                                    const xrfdc::GetCalCoefficientsRequest* request,
                                    xrfdc::GetCalCoefficientsResponse* response) {
        std::lock_guard<std::mutex> lk(mu_);

        if (!initialized_) {
            auto* status = response->mutable_status();
            status->set_code(1);
            status->set_message("RFDC not initialized. Call CfgInitialize first.");
            return grpc::Status(grpc::StatusCode::FAILED_PRECONDITION, "RFDC not initialized");
        }
        try {
            XRFdc_Calibration_Coefficients coeffs;
            u32 ret = rfdc_remote_->GetCalCoefficients(request->tile_id(), request->block_id(),
                                                       request->calibration_block(), &coeffs);

            rfdc_remote_->PopulateStatus(
                response->mutable_status(),
                "GetCalCoefficients",
                ret,
                XRFDC_ADC_TILE,  // Calibration is ADC-only
                request->tile_id(),
                request->block_id()
            );

            if (ret == 0) {
                auto* cal_coeffs = response->mutable_coeffs();
                cal_coeffs->set_coeff0(coeffs.Coeff0);
                cal_coeffs->set_coeff1(coeffs.Coeff1);
                cal_coeffs->set_coeff2(coeffs.Coeff2);
                cal_coeffs->set_coeff3(coeffs.Coeff3);
                cal_coeffs->set_coeff4(coeffs.Coeff4);
                cal_coeffs->set_coeff5(coeffs.Coeff5);
                cal_coeffs->set_coeff6(coeffs.Coeff6);
                cal_coeffs->set_coeff7(coeffs.Coeff7);
            }
            return grpc::Status::OK;
        } catch (const std::exception& e) {
            auto* status = response->mutable_status();
            status->set_code(1);
            status->set_message(std::string("GetCalCoefficients failed: ") + e.what());
            return grpc::Status(grpc::StatusCode::INTERNAL, e.what());
        }
    }

grpc::Status XrfdcImpl::GetClkDistribution(ServerContext* context,
                                    const xrfdc::GetClkDistributionRequest* request,
                                    xrfdc::GetClkDistributionResponse* response) {
        std::lock_guard<std::mutex> lk(mu_);

        if (!initialized_) {
            auto* status = response->mutable_status();
            status->set_code(1);
            status->set_message("RFDC not initialized. Call CfgInitialize first.");
            return grpc::Status(grpc::StatusCode::FAILED_PRECONDITION, "RFDC not initialized");
        }
        try {
            XRFdc_Distribution_Settings settings;
            u32 ret = rfdc_remote_->GetClkDistribution(&settings);

            rfdc_remote_->PopulateStatus(
                response->mutable_status(),
                "GetClkDistribution",
                ret,
                0,  // IP-wide operation
                -1,  // No tile
                -1   // No block
            );

            if (ret == 0) {
                auto* dist_settings = response->mutable_settings();
                // Populate DAC tile settings
                for (int i = 0; i < 4; i++) {
                    auto* dac_tile = dist_settings->add_dac();
                    const auto& dac_clk = settings.Info.ClkSettings[XRFDC_DAC_TILE][i];
                    dac_tile->set_source_type(dac_clk.SourceType);
                    dac_tile->set_source_tile(dac_clk.SourceTile);
                    dac_tile->set_pll_enable(dac_clk.PLLEnable);
                    dac_tile->set_ref_clk_freq(dac_clk.RefClkFreq);
                    dac_tile->set_sample_rate(dac_clk.SampleRate);
                    dac_tile->set_division_factor(dac_clk.DivisionFactor);
                    dac_tile->set_delay(dac_clk.Delay);
                    dac_tile->set_distributed_clock(dac_clk.DistributedClock);
                }
                // Populate ADC tile settings
                for (int i = 0; i < 4; i++) {
                    auto* adc_tile = dist_settings->add_adc();
                    const auto& adc_clk = settings.Info.ClkSettings[XRFDC_ADC_TILE][i];
                    adc_tile->set_source_type(adc_clk.SourceType);
                    adc_tile->set_source_tile(adc_clk.SourceTile);
                    adc_tile->set_pll_enable(adc_clk.PLLEnable);
                    adc_tile->set_ref_clk_freq(adc_clk.RefClkFreq);
                    adc_tile->set_sample_rate(adc_clk.SampleRate);
                    adc_tile->set_division_factor(adc_clk.DivisionFactor);
                    adc_tile->set_delay(adc_clk.Delay);
                    adc_tile->set_distributed_clock(adc_clk.DistributedClock);
                }
                // Populate distribution status
                {
                    auto* dist_status = dist_settings->mutable_distribution_info();
                    const auto& dist_info = settings.Info;
                    dist_status->set_source(dist_info.Source);
                    dist_status->set_upper_bound(dist_info.UpperBound);
                    dist_status->set_lower_bound(dist_info.LowerBound);
                    dist_status->set_max_delay(dist_info.MaxDelay);
                    dist_status->set_min_delay(dist_info.MinDelay);
                    dist_status->set_is_delay_balanced(dist_info.IsDelayBalanced);
                }
            }
            return grpc::Status::OK;
        } catch (const std::exception& e) {
            auto* status = response->mutable_status();
            status->set_code(1);
            status->set_message(std::string("GetClkDistribution failed: ") + e.what());
            return grpc::Status(grpc::StatusCode::INTERNAL, e.what());
        }
    }

grpc::Status XrfdcImpl::SetClkDistribution(ServerContext* context,
                                    const xrfdc::SetClkDistributionRequest* request,
                                    xrfdc::TileControlResponse* response) {
        std::lock_guard<std::mutex> lk(mu_);

        if (!initialized_) {
            auto* status = response->mutable_status();
            status->set_code(1);
            status->set_message("RFDC not initialized. Call CfgInitialize first.");
            return grpc::Status(grpc::StatusCode::FAILED_PRECONDITION, "RFDC not initialized");
        }
        try {
            XRFdc_Distribution_Settings settings;
            memset(&settings, 0, sizeof(settings));

            // Populate DAC tile settings from request
            for (int i = 0; i < 4 && i < request->settings().dac_size(); i++) {
                const auto& dac = request->settings().dac(i);
                auto& dac_clk = settings.Info.ClkSettings[XRFDC_DAC_TILE][i];
                dac_clk.SourceType = dac.source_type();
                dac_clk.SourceTile = dac.source_tile();
                dac_clk.PLLEnable = dac.pll_enable();
                dac_clk.DivisionFactor = dac.division_factor();
                dac_clk.Delay = dac.delay();
                dac_clk.DistributedClock = dac.distributed_clock();
                dac_clk.RefClkFreq = dac.ref_clk_freq();
                dac_clk.SampleRate = dac.sample_rate();
            }
            // Populate ADC tile settings from request
            for (int i = 0; i < 4 && i < request->settings().adc_size(); i++) {
                const auto& adc = request->settings().adc(i);
                auto& adc_clk = settings.Info.ClkSettings[XRFDC_ADC_TILE][i];
                adc_clk.SourceType = adc.source_type();
                adc_clk.SourceTile = adc.source_tile();
                adc_clk.PLLEnable = adc.pll_enable();
                adc_clk.DivisionFactor = adc.division_factor();
                adc_clk.Delay = adc.delay();
                adc_clk.DistributedClock = adc.distributed_clock();
                adc_clk.RefClkFreq = adc.ref_clk_freq();
                adc_clk.SampleRate = adc.sample_rate();
            }

            // Populate distribution status from request
            const auto& dist = request->settings().distribution_info();
            auto& dist_info = settings.Info;
            dist_info.Source = dist.source();
            dist_info.UpperBound = dist.upper_bound();
            dist_info.LowerBound = dist.lower_bound();
            dist_info.MaxDelay = dist.max_delay();
            dist_info.MinDelay = dist.min_delay();
            dist_info.IsDelayBalanced = dist.is_delay_balanced();

            u32 ret = rfdc_remote_->SetClkDistribution(&settings);

            rfdc_remote_->PopulateStatus(
                response->mutable_status(),
                "SetClkDistribution",
                ret,
                0,  // IP-wide operation
                -1,  // No tile
                -1   // No block
            );

            return grpc::Status::OK;
        } catch (const std::exception& e) {
            auto* status = response->mutable_status();
            status->set_code(1);
            status->set_message(std::string("SetClkDistribution failed: ") + e.what());
            return grpc::Status(grpc::StatusCode::INTERNAL, e.what());
        }
    }
