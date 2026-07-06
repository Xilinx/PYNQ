#ifndef XRFDC_H
#define XRFDC_H

#include <memory>
#include <mutex>
#include <cstdint>
#include <chrono>
#include <cstring>
#include <sstream>
#include <dlfcn.h>
#include <stdexcept>
#include <fcntl.h>
#include <sys/mman.h>
#include <unistd.h>
#include <grpcpp/grpcpp.h>
#include <xrfdc.grpc.pb.h>
#include <xrfdc.pb.h>

#include <iostream>

// Include XRFdc C API headers
extern "C" {
    #include <xrfdc.h>  // Xilinx C library header from librfdc.so
    #include <metal/io.h>
}

class libxrfdcManager
{
private:
    void* handle_;
public:

    libxrfdcManager();
    ~libxrfdcManager();

    // Load and unload the shared library
    void loadLibrary();
    void unloadLibrary();

    // Function pointers for XRFdc C API functions
    typedef XRFdc_Config* (*XRFdc_LookupConfig_t)(u16 DeviceId);
    typedef u32 (*XRFdc_CfgInitialize_t)(XRFdc* InstancePtr, XRFdc_Config* ConfigPtr);
    typedef u32 (*XRFdc_GetIPStatus_t)(XRFdc* InstancePtr, XRFdc_IPStatus* StatusPtr);
    typedef u32 (*XRFdc_GetBlockStatus_t)(XRFdc* InstancePtr, u32 Type, u32 Tile_Id, u32 Block_Id, XRFdc_BlockStatus* BlockStatusPtr);
    typedef u32 (*XRFdc_StartUp_t)(XRFdc* InstancePtr, u32 Type, int Tile_Id);
    typedef u32 (*XRFdc_Shutdown_t)(XRFdc* InstancePtr, u32 Type, int Tile_Id);
    typedef u32 (*XRFdc_Reset_t)(XRFdc* InstancePtr, u32 Type, int Tile_Id);
    typedef u32 (*XRFdc_SetupFIFO_t)(XRFdc* InstancePtr, u32 Type, int Tile_Id, u8 Enable);
    typedef u32 (*XRFdc_DynamicPLLConfig_t)(XRFdc* InstancePtr, u32 Type, u32 Tile_Id, u8 Source, double RefClkFreq, double SamplingRate);
    typedef u32 (*XRFdc_GetFIFOStatus_t)(XRFdc* InstancePtr, u32 Type, u32 Tile_Id, u8* EnablePtr);
    typedef u32 (*XRFdc_GetPLLLockStatus_t)(XRFdc* InstancePtr, u32 Type, u32 Tile_Id, u32* LockStatusPtr);
    typedef u32 (*XRFdc_GetClockSource_t)(XRFdc* InstancePtr, u32 Type, u32 Tile_Id, u32* ClockSourcePtr);
    typedef u32 (*XRFdc_SetFabClkOutDiv_t)(XRFdc* InstancePtr, u32 Type, u32 Tile_Id, u16 FabClkDiv);
    typedef u32 (*XRFdc_GetFabClkOutDiv_t)(XRFdc* InstancePtr, u32 Type, u32 Tile_Id, u16* FabClkDivPtr);
    typedef u32 (*XRFdc_SetMixerSettings_t)(XRFdc* InstancePtr, u32 Type, u32 Tile_Id, u32 Block_Id, XRFdc_Mixer_Settings* MixerSettingsPtr);
    typedef u32 (*XRFdc_GetMixerSettings_t)(XRFdc* InstancePtr, u32 Type, u32 Tile_Id, u32 Block_Id, XRFdc_Mixer_Settings* MixerSettingsPtr);
    typedef u32 (*XRFdc_ResetNCOPhase_t)(XRFdc* InstancePtr, u32 Type, u32 Tile_Id, u32 Block_Id);
    typedef u32 (*XRFdc_SetNyquistZone_t)(XRFdc* InstancePtr, u32 Type, u32 Tile_Id, u32 Block_Id, u32 NyquistZone);
    typedef u32 (*XRFdc_GetNyquistZone_t)(XRFdc* InstancePtr, u32 Type, u32 Tile_Id, u32 Block_Id, u32* NyquistZonePtr);
    typedef u32 (*XRFdc_SetInterpolationFactor_t)(XRFdc* InstancePtr, u32 Tile_Id, u32 Block_Id, u32 InterpolationFactor);
    typedef u32 (*XRFdc_GetInterpolationFactor_t)(XRFdc* InstancePtr, u32 Tile_Id, u32 Block_Id, u32* InterpolationFactorPtr);
    typedef u32 (*XRFdc_SetDecimationFactor_t)(XRFdc* InstancePtr, u32 Tile_Id, u32 Block_Id, u32 DecimationFactor);
    typedef u32 (*XRFdc_GetDecimationFactor_t)(XRFdc* InstancePtr, u32 Tile_Id, u32 Block_Id, u32* DecimationFactorPtr);
    typedef u32 (*XRFdc_SetQMCSettings_t)(XRFdc* InstancePtr, u32 Type, u32 Tile_Id, u32 Block_Id, XRFdc_QMC_Settings* QMCSettingsPtr);
    typedef u32 (*XRFdc_GetQMCSettings_t)(XRFdc* InstancePtr, u32 Type, u32 Tile_Id, u32 Block_Id, XRFdc_QMC_Settings* QMCSettingsPtr);
    typedef u32 (*XRFdc_SetThresholdSettings_t)(XRFdc* InstancePtr, u32 Tile_Id, u32 Block_Id, XRFdc_Threshold_Settings* ThresholdSettingsPtr);
    typedef u32 (*XRFdc_GetThresholdSettings_t)(XRFdc* InstancePtr, u32 Tile_Id, u32 Block_Id, XRFdc_Threshold_Settings* ThresholdSettingsPtr);
    typedef u32 (*XRFdc_SetThresholdClrMode_t)(XRFdc* InstancePtr, u32 Tile_Id, u32 Block_Id, u32 ThresholdToUpdate, u32 ClrMode);
    typedef u32 (*XRFdc_ThresholdStickyClear_t)(XRFdc* InstancePtr, u32 Tile_Id, u32 Block_Id, u32 ThresholdToUpdate);
    typedef u32 (*XRFdc_GetCoarseDelaySettings_t)(XRFdc* InstancePtr, u32 Type, u32 Tile_Id, u32 Block_Id, XRFdc_CoarseDelay_Settings* CoarseDelaySettingsPtr);
    typedef u32 (*XRFdc_SetCoarseDelaySettings_t)(XRFdc* InstancePtr, u32 Type, u32 Tile_Id, u32 Block_Id, XRFdc_CoarseDelay_Settings* CoarseDelaySettingsPtr);
    typedef u32 (*XRFdc_GetEnabledInterrupts_t)(XRFdc* InstancePtr, u32 Type, u32 Tile_Id, u32 Block_Id, u32* IntrMask);
    typedef u32 (*XRFdc_GetPwrMode_t)(XRFdc* InstancePtr, u32 Type, u32 Tile_Id, u32 Block_Id, XRFdc_Pwr_Mode_Settings* SettingsPtr);
    typedef u32 (*XRFdc_SetPwrMode_t)(XRFdc* InstancePtr, u32 Type, u32 Tile_Id, u32 Block_Id, XRFdc_Pwr_Mode_Settings* SettingsPtr);
    typedef u32 (*XRFdc_UpdateEvent_t)(XRFdc* InstancePtr, u32 Type, u32 Tile_Id, u32 Block_Id, u32 Event);
    typedef u32 (*XRFdc_ResetInternalFIFOWidth_t)(XRFdc* InstancePtr, u32 Type, u32 Tile_Id, u32 Block_Id);
    typedef int (*XRFdc_GetConnectedIData_t)(XRFdc* InstancePtr, u32 Type, u32 Tile_Id, u32 Block_Id);
    typedef int (*XRFdc_GetConnectedQData_t)(XRFdc* InstancePtr, u32 Type, u32 Tile_Id, u32 Block_Id);
    typedef u32 (*XRFdc_GetCalibrationMode_t)(XRFdc* InstancePtr, u32 Tile_Id, u32 Block_Id, u8* CalibrationModePtr);
    typedef u32 (*XRFdc_SetCalibrationMode_t)(XRFdc* InstancePtr, u32 Tile_Id, u32 Block_Id, u8 CalibrationMode);
    typedef u32 (*XRFdc_GetFabRdVldWords_t)(XRFdc* InstancePtr, u32 Type, u32 Tile_Id, u32 Block_Id, u32* FabricDataRatePtr);
    typedef u32 (*XRFdc_SetFabRdVldWords_t)(XRFdc* InstancePtr, u32 Tile_Id, u32 Block_Id, u32 FabricRdVldWords);
    typedef u32 (*XRFdc_GetFabWrVldWords_t)(XRFdc* InstancePtr, u32 Type, u32 Tile_Id, u32 Block_Id, u32* FabricDataRatePtr);
    typedef u32 (*XRFdc_SetFabWrVldWords_t)(XRFdc* InstancePtr, u32 Tile_Id, u32 Block_Id, u32 FabricWrVldWords);
    typedef u32 (*XRFdc_GetDecimationFactorObs_t)(XRFdc* InstancePtr, u32 Tile_Id, u32 Block_Id, u32* DecimationFactorPtr);
    typedef u32 (*XRFdc_SetDecimationFactorObs_t)(XRFdc* InstancePtr, u32 Tile_Id, u32 Block_Id, u32 DecimationFactor);
    typedef u32 (*XRFdc_GetFabRdVldWordsObs_t)(XRFdc* InstancePtr, u32 Type, u32 Tile_Id, u32 Block_Id, u32* FabricDataRatePtr);
    typedef u32 (*XRFdc_SetFabRdVldWordsObs_t)(XRFdc* InstancePtr, u32 Tile_Id, u32 Block_Id, u32 FabricRdVldWords);
    typedef u32 (*XRFdc_GetFabWrVldWordsObs_t)(XRFdc* InstancePtr, u32 Type, u32 Tile_Id, u32 Block_Id, u32* FabricDataRatePtr);
    typedef u32 (*XRFdc_GetDither_t)(XRFdc* InstancePtr, u32 Tile_Id, u32 Block_Id, u32* ModePtr);
    typedef u32 (*XRFdc_SetDither_t)(XRFdc* InstancePtr, u32 Tile_Id, u32 Block_Id, u32 Mode);
    typedef u32 (*XRFdc_GetCalFreeze_t)(XRFdc* InstancePtr, u32 Tile_Id, u32 Block_Id, XRFdc_Cal_Freeze_Settings* SettingsPtr);
    typedef u32 (*XRFdc_SetCalFreeze_t)(XRFdc* InstancePtr, u32 Tile_Id, u32 Block_Id, XRFdc_Cal_Freeze_Settings* SettingsPtr);
    typedef u32 (*XRFdc_GetDSA_t)(XRFdc* InstancePtr, u32 Tile_Id, u32 Block_Id, XRFdc_DSA_Settings* SettingsPtr);
    typedef u32 (*XRFdc_SetDSA_t)(XRFdc* InstancePtr, u32 Tile_Id, u32 Block_Id, XRFdc_DSA_Settings* SettingsPtr);
    typedef u32 (*XRFdc_DisableCoefficientsOverride_t)(XRFdc* InstancePtr, u32 Tile_Id, u32 Block_Id, u32 CalibrationBlock);
    typedef u32 (*XRFdc_ResetInternalFIFOWidthObs_t)(XRFdc* InstancePtr, u32 Tile_Id, u32 Block_Id);
    typedef u32 (*XRFdc_SetCalCoefficients_t)(XRFdc* InstancePtr, u32 Tile_Id, u32 Block_Id, u32 CalibrationBlock, XRFdc_Calibration_Coefficients* CoeffPtr);
    typedef u32 (*XRFdc_GetCalCoefficients_t)(XRFdc* InstancePtr, u32 Tile_Id, u32 Block_Id, u32 CalibrationBlock, XRFdc_Calibration_Coefficients* CoeffPtr);
    typedef u32 (*XRFdc_GetDecoderMode_t)(XRFdc* InstancePtr, u32 Tile_Id, u32 Block_Id, u32* DecoderModePtr);
    typedef u32 (*XRFdc_SetDecoderMode_t)(XRFdc* InstancePtr, u32 Tile_Id, u32 Block_Id, u32 DecoderMode);
    typedef u32 (*XRFdc_GetOutputCurr_t)(XRFdc* InstancePtr, u32 Tile_Id, u32 Block_Id, u32* OutputCurrPtr);
    typedef u32 (*XRFdc_GetInvSincFIR_t)(XRFdc* InstancePtr, u32 Tile_Id, u32 Block_Id, u16* ModePtr);
    typedef u32 (*XRFdc_SetInvSincFIR_t)(XRFdc* InstancePtr, u32 Tile_Id, u32 Block_Id, u16 Mode);
    typedef u32 (*XRFdc_GetDataPathMode_t)(XRFdc* InstancePtr, u32 Tile_Id, u32 Block_Id, u32* ModePtr);
    typedef u32 (*XRFdc_SetDataPathMode_t)(XRFdc* InstancePtr, u32 Tile_Id, u32 Block_Id, u32 Mode);
    typedef u32 (*XRFdc_GetIMRPassMode_t)(XRFdc* InstancePtr, u32 Tile_Id, u32 Block_Id, u32* ModePtr);
    typedef u32 (*XRFdc_SetIMRPassMode_t)(XRFdc* InstancePtr, u32 Tile_Id, u32 Block_Id, u32 Mode);
    typedef u32 (*XRFdc_GetDACCompMode_t)(XRFdc* InstancePtr, u32 Tile_Id, u32 Block_Id, u32* EnabledPtr);
    typedef u32 (*XRFdc_SetDACCompMode_t)(XRFdc* InstancePtr, u32 Tile_Id, u32 Block_Id, u32 Mode);
    typedef u32 (*XRFdc_SetDACVOP_t)(XRFdc* InstancePtr, u32 Tile_Id, u32 Block_Id, u32 uACurrent);
    typedef void (*XRFdc_DumpRegs_t)(XRFdc* InstancePtr, u32 Type, int Tile_Id);
    typedef u32 (*XRFdc_GetPLLConfig_t)(XRFdc* InstancePtr, u32 Type, u32 Tile_Id, XRFdc_PLL_Settings* SettingsPtr);
    typedef u32 (*XRFdc_SetupFIFOObs_t)(XRFdc* InstancePtr, u32 Type, int Tile_Id, u8 Enable);
    typedef u32 (*XRFdc_SetupFIFOBoth_t)(XRFdc* InstancePtr, u32 Type, int Tile_Id, u8 Enable);
    typedef u32 (*XRFdc_GetFIFOStatusObs_t)(XRFdc* InstancePtr, u32 Type, u32 Tile_Id, u8* EnablePtr);
    typedef u32 (*XRFdc_GetClkDistribution_t)(XRFdc* InstancePtr, XRFdc_Distribution_Settings* DistributionSettingsPtr);
    typedef u32 (*XRFdc_SetClkDistribution_t)(XRFdc* InstancePtr, XRFdc_Distribution_Settings* DistributionSettingsPtr);

    XRFdc_LookupConfig_t XRFdc_LookupConfig;
    XRFdc_CfgInitialize_t XRFdc_CfgInitialize;
    XRFdc_GetIPStatus_t XRFdc_GetIPStatus;
    XRFdc_GetBlockStatus_t XRFdc_GetBlockStatus;
    XRFdc_StartUp_t XRFdc_StartUp;
    XRFdc_Shutdown_t XRFdc_Shutdown;
    XRFdc_Reset_t XRFdc_Reset;
    XRFdc_SetupFIFO_t XRFdc_SetupFIFO;
    XRFdc_DynamicPLLConfig_t XRFdc_DynamicPLLConfig;
    XRFdc_GetFIFOStatus_t XRFdc_GetFIFOStatus;
    XRFdc_GetPLLLockStatus_t XRFdc_GetPLLLockStatus;
    XRFdc_GetClockSource_t XRFdc_GetClockSource;
    XRFdc_SetFabClkOutDiv_t XRFdc_SetFabClkOutDiv;
    XRFdc_GetFabClkOutDiv_t XRFdc_GetFabClkOutDiv;
    XRFdc_SetMixerSettings_t XRFdc_SetMixerSettings;
    XRFdc_GetMixerSettings_t XRFdc_GetMixerSettings;
    XRFdc_ResetNCOPhase_t XRFdc_ResetNCOPhase;
    XRFdc_SetNyquistZone_t XRFdc_SetNyquistZone;
    XRFdc_GetNyquistZone_t XRFdc_GetNyquistZone;
    XRFdc_SetInterpolationFactor_t XRFdc_SetInterpolationFactor;
    XRFdc_GetInterpolationFactor_t XRFdc_GetInterpolationFactor;
    XRFdc_SetDecimationFactor_t XRFdc_SetDecimationFactor;
    XRFdc_GetDecimationFactor_t XRFdc_GetDecimationFactor;
    XRFdc_SetQMCSettings_t XRFdc_SetQMCSettings;
    XRFdc_GetQMCSettings_t XRFdc_GetQMCSettings;
    XRFdc_SetThresholdSettings_t XRFdc_SetThresholdSettings;
    XRFdc_GetThresholdSettings_t XRFdc_GetThresholdSettings;
    XRFdc_SetThresholdClrMode_t XRFdc_SetThresholdClrMode;
    XRFdc_ThresholdStickyClear_t XRFdc_ThresholdStickyClear;
    XRFdc_GetCoarseDelaySettings_t XRFdc_GetCoarseDelaySettings;
    XRFdc_SetCoarseDelaySettings_t XRFdc_SetCoarseDelaySettings;
    XRFdc_GetEnabledInterrupts_t XRFdc_GetEnabledInterrupts;
    XRFdc_GetPwrMode_t XRFdc_GetPwrMode;
    XRFdc_SetPwrMode_t XRFdc_SetPwrMode;
    XRFdc_UpdateEvent_t XRFdc_UpdateEvent;
    XRFdc_ResetInternalFIFOWidth_t XRFdc_ResetInternalFIFOWidth;
    XRFdc_GetConnectedIData_t XRFdc_GetConnectedIData;
    XRFdc_GetConnectedQData_t XRFdc_GetConnectedQData;
    XRFdc_GetCalibrationMode_t XRFdc_GetCalibrationMode;
    XRFdc_SetCalibrationMode_t XRFdc_SetCalibrationMode;
    XRFdc_GetFabRdVldWords_t XRFdc_GetFabRdVldWords;
    XRFdc_SetFabRdVldWords_t XRFdc_SetFabRdVldWords;
    XRFdc_GetFabWrVldWords_t XRFdc_GetFabWrVldWords;
    XRFdc_SetFabWrVldWords_t XRFdc_SetFabWrVldWords;
    XRFdc_GetDecimationFactorObs_t XRFdc_GetDecimationFactorObs;
    XRFdc_SetDecimationFactorObs_t XRFdc_SetDecimationFactorObs;
    XRFdc_GetFabRdVldWordsObs_t XRFdc_GetFabRdVldWordsObs;
    XRFdc_SetFabRdVldWordsObs_t XRFdc_SetFabRdVldWordsObs;
    XRFdc_GetFabWrVldWordsObs_t XRFdc_GetFabWrVldWordsObs;
    XRFdc_GetDither_t XRFdc_GetDither;
    XRFdc_SetDither_t XRFdc_SetDither;
    XRFdc_GetCalFreeze_t XRFdc_GetCalFreeze;
    XRFdc_SetCalFreeze_t XRFdc_SetCalFreeze;
    XRFdc_GetDSA_t XRFdc_GetDSA;
    XRFdc_SetDSA_t XRFdc_SetDSA;
    XRFdc_DisableCoefficientsOverride_t XRFdc_DisableCoefficientsOverride;
    XRFdc_ResetInternalFIFOWidthObs_t XRFdc_ResetInternalFIFOWidthObs;
    XRFdc_SetCalCoefficients_t XRFdc_SetCalCoefficients;
    XRFdc_GetCalCoefficients_t XRFdc_GetCalCoefficients;
    XRFdc_GetDecoderMode_t XRFdc_GetDecoderMode;
    XRFdc_SetDecoderMode_t XRFdc_SetDecoderMode;
    XRFdc_GetOutputCurr_t XRFdc_GetOutputCurr;
    XRFdc_GetInvSincFIR_t XRFdc_GetInvSincFIR;
    XRFdc_SetInvSincFIR_t XRFdc_SetInvSincFIR;
    XRFdc_GetDataPathMode_t XRFdc_GetDataPathMode;
    XRFdc_SetDataPathMode_t XRFdc_SetDataPathMode;
    XRFdc_GetIMRPassMode_t XRFdc_GetIMRPassMode;
    XRFdc_SetIMRPassMode_t XRFdc_SetIMRPassMode;
    XRFdc_GetDACCompMode_t XRFdc_GetDACCompMode;
    XRFdc_SetDACCompMode_t XRFdc_SetDACCompMode;
    XRFdc_SetDACVOP_t XRFdc_SetDACVOP;
    XRFdc_DumpRegs_t XRFdc_DumpRegs;
    XRFdc_GetPLLConfig_t XRFdc_GetPLLConfig;
    XRFdc_SetupFIFOObs_t XRFdc_SetupFIFOObs;
    XRFdc_SetupFIFOBoth_t XRFdc_SetupFIFOBoth;
    XRFdc_GetFIFOStatusObs_t XRFdc_GetFIFOStatusObs;
    XRFdc_GetClkDistribution_t XRFdc_GetClkDistribution;
    XRFdc_SetClkDistribution_t XRFdc_SetClkDistribution;
};

// ============================================================================
// Error Code Translation
// ============================================================================

/**
 * @brief Map XRFdc error code to human-readable message
 *
 * The Xilinx XRFdc driver only defines two return codes:
 * - 0 = XRFDC_SUCCESS
 * - 1 = XRFDC_FAILURE
 */
inline std::string XrfdcErrorToString(uint32_t code) {
    switch (code) {
        case 0:  return "Success";
        case 1:  return "Operation failed (XRFDC_FAILURE)";
        default: return "Unknown error code: " + std::to_string(code);
    }
}

/**
 * @brief Get human-readable tile type name
 */
inline std::string TileTypeName(uint32_t tile_type) {
    return (tile_type == 0) ? "ADC" : (tile_type == 1) ? "DAC" : "Unknown";
}

/**
 * @brief Format complete error message with context
 */
inline std::string FormatXrfdcError(const std::string& operation,
                                    uint32_t code,
                                    uint32_t tile_type,
                                    int32_t tile_id,
                                    int32_t block_id = -1) {
    std::ostringstream oss;
    oss << operation << " failed on " << TileTypeName(tile_type)
        << " Tile " << tile_id;

    if (block_id >= 0) {
        oss << " Block " << block_id;
    }

    oss << ": " << XrfdcErrorToString(code) << " (code: " << code << ")";
    return oss.str();
}

/**
 * @class XrfdcRemote
 * @brief gRPC service implementation for Xilinx RF Data Converter.
 *
 * This class implements the Xrfdc service defined in xrfdc.proto,
 * providing remote access to the XRFdc C API via gRPC.
 */
class XrfdcRemote
{
private:
    XRFdc* rfdc_inst_;
    XRFdc_Config* config_;
    libxrfdcManager lib_manager_;
    uint16_t device_id_;
    struct metal_io_region* io_;
    int mem_fd_;
    void* mapped_base_;
    size_t mapped_size_;  // Store size for cleanup

    // Helper methods
    void cleanup();
    struct metal_io_region* create_io_region_from_devmem(void *virt_addr, uint64_t phys_addr, size_t size);
    XRFdc_Config* ConvertProtoToConfig(const xrfdc::RFdcConfig& proto_config);
    void ConvertBlockStatus(const XRFdc_BlockStatus& c_block, xrfdc::BlockStatus* proto_block);
    void ConvertTileStatus(const XRFdc_TileStatus& c_tile, xrfdc::TileStatus* proto_tile,
                          u32 tile_type, u32 tile_id);
    void ConvertIPStatus(const XRFdc_IPStatus& c_status, xrfdc::IPStatus* proto_status);

public:
    /**
     * @brief Constructor for XrfdcRemote.
     */
    XrfdcRemote();

    /**
     * @brief Destructor for XrfdcRemote.
     */
    ~XrfdcRemote();

    /**
     * @brief Populate Status message with comprehensive error details
     *
     * @param status Protobuf Status message to populate
     * @param operation Operation name (e.g., "SetMixerSettings")
     * @param code XRFdc C API return code (0 = success)
     * @param tile_type Tile type (XRFDC_ADC_TILE=0 or XRFDC_DAC_TILE=1)
     * @param tile_id Tile index (0-3), use -1 if N/A
     * @param block_id Block index (0-3), use -1 if tile-level operation
     */
    void PopulateStatus(xrfdc::Status* status,
                       const std::string& operation,
                       uint32_t code,
                       uint32_t tile_type,
                       int32_t tile_id,
                       int32_t block_id = -1);

    /**
     * @brief Initialize the RFDC with the given configuration.
     * @param request CfgInitializeRequest containing config and memory size
     */
    void CfgInitialize(const xrfdc::CfgInitializeRequest& request);

    /**
     * @brief Get the current IP status including all tile and block details.
     * @return IPStatus protobuf message
     */
    xrfdc::IPStatus GetIPStatus();

    /**
     * @brief Start up a tile.
     * @param tile_type Type of tile (XRFDC_ADC_TILE or XRFDC_DAC_TILE)
     * @param tile_id Tile index (0-3)
     * @return Status code (0 = success)
     */
    int StartUp(u32 tile_type, u32 tile_id);

    /**
     * @brief Shut down a tile.
     * @param tile_type Type of tile (XRFDC_ADC_TILE or XRFDC_DAC_TILE)
     * @param tile_id Tile index (0-3)
     * @return Status code (0 = success)
     */
    int Shutdown(u32 tile_type, u32 tile_id);

    /**
     * @brief Reset a tile.
     * @param tile_type Type of tile (XRFDC_ADC_TILE or XRFDC_DAC_TILE)
     * @param tile_id Tile index (0-3)
     * @return Status code (0 = success)
     */
    int Reset(u32 tile_type, u32 tile_id);

    /**
     * @brief Setup FIFO for a tile.
     * @param tile_type Type of tile (XRFDC_ADC_TILE or XRFDC_DAC_TILE)
     * @param tile_id Tile index (0-3)
     * @param enable true to enable FIFO, false to disable
     * @return Status code (0 = success)
     */
    int SetupFIFO(u32 tile_type, u32 tile_id, bool enable);

    /**
     * @brief Configure PLL dynamically.
     * @param tile_type Type of tile (XRFDC_ADC_TILE or XRFDC_DAC_TILE)
     * @param tile_id Tile index (0-3)
     * @param source Clock source (0x1 = PLL, 0x2 = External)
     * @param ref_clk_freq Reference clock frequency in MHz
     * @param samp_rate Sampling rate in MSPS
     * @return Status code (0 = success)
     */
    int DynamicPLLConfig(u32 tile_type, u32 tile_id, u32 source,
                        double ref_clk_freq, double samp_rate);

    // Status/Monitoring Methods
    int GetBlockStatus(u32 tile_type, u32 tile_id, u32 block_id,
                      XRFdc_BlockStatus* block_status);
    int GetFIFOStatus(u32 tile_type, u32 tile_id, u32 block_id, bool* enable);
    int GetPLLLockStatus(u32 tile_type, u32 tile_id, u32* lock_status);
    int GetClockSource(u32 tile_type, u32 tile_id, u32* clock_source);

    // Clock Configuration Methods
    int SetFabClkOutDiv(u32 tile_type, u32 tile_id, u32 fab_clk_div);
    int GetFabClkOutDiv(u32 tile_type, u32 tile_id, u32* fab_clk_div);

    // Mixer Methods
    int SetMixerSettings(u32 tile_type, u32 tile_id, u32 block_id,
                        const xrfdc::MixerSettings& settings);
    int GetMixerSettings(u32 tile_type, u32 tile_id, u32 block_id,
                        xrfdc::MixerSettings* settings);
    int ResetNCOPhase(u32 tile_type, u32 tile_id, u32 block_id);

    // Nyquist Zone Methods
    int SetNyquistZone(u32 tile_type, u32 tile_id, u32 block_id, u32 nyquist_zone);
    int GetNyquistZone(u32 tile_type, u32 tile_id, u32 block_id, u32* nyquist_zone);

    // Interpolation/Decimation Methods
    int SetInterpolationFactor(u32 tile_id, u32 block_id, u32 interp_factor);
    int GetInterpolationFactor(u32 tile_id, u32 block_id, u32* interp_factor);
    int SetDecimationFactor(u32 tile_id, u32 block_id, u32 dec_factor);
    int GetDecimationFactor(u32 tile_id, u32 block_id, u32* dec_factor);

    // QMC Methods
    int SetQMCSettings(u32 tile_type, u32 tile_id, u32 block_id,
                      const xrfdc::QMCSettings& settings);
    int GetQMCSettings(u32 tile_type, u32 tile_id, u32 block_id,
                      xrfdc::QMCSettings* settings);

    // Threshold Methods (ADC only)
    int SetThresholdSettings(u32 tile_id, u32 block_id,
                            const xrfdc::ThresholdSettings& settings);
    int GetThresholdSettings(u32 tile_id, u32 block_id,
                            xrfdc::ThresholdSettings* settings);

    u32 SetThresholdClrMode(u32 tile_id, u32 block_id, u32 threshold_to_update, u32 clr_mode);
    u32 ThresholdStickyClear(u32 tile_id, u32 block_id, u32 threshold_to_update);
    u32 GetEnabledInterrupts(u32 tile_type, u32 tile_id, u32 block_id);
    u32 UpdateEvent(u32 tile_type, u32 tile_id, u32 block_id, u32 event);
    u32 ResetInternalFIFOWidth(u32 tile_type, u32 tile_id, u32 block_id);
    int GetConnectedIData(u32 tile_type, u32 tile_id, u32 block_id);
    int GetConnectedQData(u32 tile_type, u32 tile_id, u32 block_id);
    uint8_t GetCalibrationMode(u32 tile_id, u32 block_id);
    u32 SetCalibrationMode(u32 tile_id, u32 block_id, uint8_t mode);
    u32 GetFabRdVldWords(u32 tile_type, u32 tile_id, u32 block_id);
    u32 SetFabRdVldWords(u32 tile_type, u32 tile_id, u32 block_id, u32 words);
    u32 GetFabWrVldWords(u32 tile_type, u32 tile_id, u32 block_id);
    u32 SetFabWrVldWords(u32 tile_type, u32 tile_id, u32 block_id, u32 words);
    u32 GetDither(u32 tile_id, u32 block_id);
    u32 SetDither(u32 tile_id, u32 block_id, u32 mode);
    u32 GetDecoderMode(u32 tile_id, u32 block_id);
    u32 SetDecoderMode(u32 tile_id, u32 block_id, u32 mode);
    u32 GetOutputCurr(u32 tile_id, u32 block_id);
    uint16_t GetInvSincFIR(u32 tile_id, u32 block_id);
    u32 SetInvSincFIR(u32 tile_id, u32 block_id, uint16_t mode);
    u32 GetDataPathMode(u32 tile_id, u32 block_id);
    u32 SetDataPathMode(u32 tile_id, u32 block_id, u32 mode);
    u32 GetIMRPassMode(u32 tile_id, u32 block_id);
    u32 SetIMRPassMode(u32 tile_id, u32 block_id, u32 mode);
    u32 GetDACCompMode(u32 tile_id, u32 block_id);
    u32 SetDACCompMode(u32 tile_id, u32 block_id, u32 mode);
    u32 SetDACVOP(u32 tile_id, u32 block_id, u32 uACurrent);
    void DumpRegs(u32 tile_type, u32 tile_id);
    u32 SetupFIFOObs(u32 tile_type, u32 tile_id, uint8_t enable);
    u32 SetupFIFOBoth(u32 tile_type, u32 tile_id, uint8_t enable);
    u32 GetFIFOStatusObs(u32 tile_type, u32 tile_id, uint8_t* enable);

    // Missing method declarations
    u32 GetPLLConfig(u32 tile_type, u32 tile_id, XRFdc_PLL_Settings* settings);
    u32 GetCoarseDelaySettings(u32 tile_type, u32 tile_id, u32 block_id, XRFdc_CoarseDelay_Settings* settings);
    u32 SetCoarseDelaySettings(u32 tile_type, u32 tile_id, u32 block_id, const XRFdc_CoarseDelay_Settings* settings);
    u32 GetPwrMode(u32 tile_type, u32 tile_id, u32 block_id, XRFdc_Pwr_Mode_Settings* settings);
    u32 SetPwrMode(u32 tile_type, u32 tile_id, u32 block_id, const XRFdc_Pwr_Mode_Settings* settings);
    u32 GetDecimationFactorObs(u32 tile_id, u32 block_id, u32* dec_factor);
    u32 SetDecimationFactorObs(u32 tile_id, u32 block_id, u32 dec_factor);
    u32 GetFabRdVldWordsObs(u32 tile_type, u32 tile_id, u32 block_id, u32* words);
    u32 SetFabRdVldWordsObs(u32 tile_type, u32 tile_id, u32 block_id, u32 words);
    u32 GetFabWrVldWordsObs(u32 tile_type, u32 tile_id, u32 block_id, u32* words);
    u32 GetCalFreeze(u32 tile_id, u32 block_id, XRFdc_Cal_Freeze_Settings* settings);
    u32 SetCalFreeze(u32 tile_id, u32 block_id, const XRFdc_Cal_Freeze_Settings* settings);
    u32 GetDSA(u32 tile_id, u32 block_id, XRFdc_DSA_Settings* settings);
    u32 SetDSA(u32 tile_id, u32 block_id, const XRFdc_DSA_Settings* settings);
    u32 DisableCoefficientsOverride(u32 tile_id, u32 block_id, u32 calibration_block);
    u32 ResetInternalFIFOWidthObs(u32 tile_type, u32 tile_id, u32 block_id);
    u32 SetCalCoefficients(u32 tile_id, u32 block_id, u32 calibration_block, const XRFdc_Calibration_Coefficients* coeffs);
    u32 GetCalCoefficients(u32 tile_id, u32 block_id, u32 calibration_block, XRFdc_Calibration_Coefficients* coeffs);
    u32 GetClkDistribution(XRFdc_Distribution_Settings* settings);
    u32 SetClkDistribution(const XRFdc_Distribution_Settings* settings);

    /**
     * @brief Tear down the current RFDC mapping and instance.
     *
     * Frees rfdc_inst_, config_, io_, the mmap region and /dev/mem fd so the
     * next CfgInitialize() call rebuilds against the freshly-loaded PL.
     * Does not unload librfdc.so.
     */
    void Invalidate();
};

class XrfdcImpl final : public xrfdc::Xrfdc::Service
{
private:
    std::unique_ptr<::XrfdcRemote> rfdc_remote_;
    bool initialized_;
    std::mutex mu_;

public:
    XrfdcImpl();
    ~XrfdcImpl();

    /**
     * @brief Invalidate the current RFDC state after a bitstream reload.
     *
     * Called by the download RPC after the PL has been reprogrammed: drops
     * the cached XRFdc instance (which was bound to the previous overlay's
     * mapping) and clears initialized_ so the next service call returns
     * FAILED_PRECONDITION until the client re-runs CfgInitialize.
     */
    void invalidate();

    grpc::Status CfgInitialize(grpc::ServerContext* context, const xrfdc::CfgInitializeRequest* request, xrfdc::CfgInitializeResponse* response) override;
    grpc::Status GetIPStatus(grpc::ServerContext* context, const xrfdc::GetIPStatusRequest* request, xrfdc::GetIPStatusResponse* response) override;
    grpc::Status StartUp(grpc::ServerContext* context, const xrfdc::TileControlRequest* request, xrfdc::TileControlResponse* response) override;
    grpc::Status Shutdown(grpc::ServerContext* context, const xrfdc::TileControlRequest* request, xrfdc::TileControlResponse* response) override;
    grpc::Status Reset(grpc::ServerContext* context, const xrfdc::TileControlRequest* request, xrfdc::TileControlResponse* response) override;
    grpc::Status SetupFIFO(grpc::ServerContext* context, const xrfdc::SetupFIFORequest* request, xrfdc::TileControlResponse* response) override;
    grpc::Status DynamicPLLConfig(grpc::ServerContext* context, const xrfdc::DynamicPLLConfigRequest* request, xrfdc::TileControlResponse* response) override;
    grpc::Status GetBlockStatus(grpc::ServerContext* context, const xrfdc::BlockRequest* request, xrfdc::GetBlockStatusResponse* response) override;
    grpc::Status GetFIFOStatus(grpc::ServerContext* context, const xrfdc::TileRequest* request, xrfdc::GetFIFOStatusResponse* response) override;
    grpc::Status GetPLLLockStatus(grpc::ServerContext* context, const xrfdc::TileRequest* request, xrfdc::GetPLLLockStatusResponse* response) override;
    grpc::Status GetClockSource(grpc::ServerContext* context, const xrfdc::TileRequest* request, xrfdc::GetClockSourceResponse* response) override;
    grpc::Status SetFabClkOutDiv(grpc::ServerContext* context, const xrfdc::SetFabClkOutDivRequest* request, xrfdc::TileControlResponse* response) override;
    grpc::Status GetFabClkOutDiv(grpc::ServerContext* context, const xrfdc::TileRequest* request, xrfdc::GetFabClkOutDivResponse* response) override;
    grpc::Status SetMixerSettings(grpc::ServerContext* context, const xrfdc::SetMixerSettingsRequest* request, xrfdc::TileControlResponse* response) override;
    grpc::Status GetMixerSettings(grpc::ServerContext* context, const xrfdc::BlockRequest* request, xrfdc::GetMixerSettingsResponse* response) override;
    grpc::Status ResetNCOPhase(grpc::ServerContext* context, const xrfdc::BlockRequest* request, xrfdc::TileControlResponse* response) override;
    grpc::Status SetNyquistZone(grpc::ServerContext* context, const xrfdc::SetNyquistZoneRequest* request, xrfdc::TileControlResponse* response) override;
    grpc::Status GetNyquistZone(grpc::ServerContext* context, const xrfdc::BlockRequest* request, xrfdc::GetNyquistZoneResponse* response) override;
    grpc::Status SetInterpolationFactor(grpc::ServerContext* context, const xrfdc::SetInterpolationFactorRequest* request, xrfdc::TileControlResponse* response) override;
    grpc::Status GetInterpolationFactor(grpc::ServerContext* context, const xrfdc::BlockRequest* request, xrfdc::GetInterpolationFactorResponse* response) override;
    grpc::Status SetDecimationFactor(grpc::ServerContext* context, const xrfdc::SetDecimationFactorRequest* request, xrfdc::TileControlResponse* response) override;
    grpc::Status GetDecimationFactor(grpc::ServerContext* context, const xrfdc::BlockRequest* request, xrfdc::GetDecimationFactorResponse* response) override;
    grpc::Status SetQMCSettings(grpc::ServerContext* context, const xrfdc::SetQMCSettingsRequest* request, xrfdc::TileControlResponse* response) override;
    grpc::Status GetQMCSettings(grpc::ServerContext* context, const xrfdc::BlockRequest* request, xrfdc::GetQMCSettingsResponse* response) override;
    grpc::Status SetThresholdSettings(grpc::ServerContext* context, const xrfdc::SetThresholdSettingsRequest* request, xrfdc::TileControlResponse* response) override;
    grpc::Status GetThresholdSettings(grpc::ServerContext* context, const xrfdc::BlockRequest* request, xrfdc::GetThresholdSettingsResponse* response) override;
    grpc::Status SetThresholdClrMode(grpc::ServerContext* context, const xrfdc::SetThresholdClrModeRequest* request, xrfdc::SetThresholdClrModeResponse* response) override;
    grpc::Status ThresholdStickyClear(grpc::ServerContext* context, const xrfdc::ThresholdStickyClearRequest* request, xrfdc::ThresholdStickyClearResponse* response) override;
    grpc::Status GetEnabledInterrupts(grpc::ServerContext* context, const xrfdc::BlockRequest* request, xrfdc::GetEnabledInterruptsResponse* response) override;
    grpc::Status UpdateEvent(grpc::ServerContext* context, const xrfdc::UpdateEventRequest* request, xrfdc::TileControlResponse* response) override;
    grpc::Status ResetInternalFIFOWidth(grpc::ServerContext* context, const xrfdc::BlockRequest* request, xrfdc::TileControlResponse* response) override;
    grpc::Status GetConnectedIData(grpc::ServerContext* context, const xrfdc::BlockRequest* request, xrfdc::GetConnectedDataResponse* response) override;
    grpc::Status GetConnectedQData(grpc::ServerContext* context, const xrfdc::BlockRequest* request, xrfdc::GetConnectedDataResponse* response) override;
    grpc::Status GetCalibrationMode(grpc::ServerContext* context, const xrfdc::BlockRequest* request, xrfdc::GetCalibrationModeResponse* response) override;
    grpc::Status SetCalibrationMode(grpc::ServerContext* context, const xrfdc::SetCalibrationModeRequest* request, xrfdc::TileControlResponse* response) override;
    grpc::Status GetFabRdVldWords(grpc::ServerContext* context, const xrfdc::BlockRequest* request, xrfdc::GetFabRdVldWordsResponse* response) override;
    grpc::Status SetFabRdVldWords(grpc::ServerContext* context, const xrfdc::SetFabRdVldWordsRequest* request, xrfdc::TileControlResponse* response) override;
    grpc::Status GetFabWrVldWords(grpc::ServerContext* context, const xrfdc::BlockRequest* request, xrfdc::GetFabWrVldWordsResponse* response) override;
    grpc::Status SetFabWrVldWords(grpc::ServerContext* context, const xrfdc::SetFabWrVldWordsRequest* request, xrfdc::TileControlResponse* response) override;
    grpc::Status GetDither(grpc::ServerContext* context, const xrfdc::BlockRequest* request, xrfdc::GetDitherResponse* response) override;
    grpc::Status SetDither(grpc::ServerContext* context, const xrfdc::SetDitherRequest* request, xrfdc::TileControlResponse* response) override;
    grpc::Status GetDecoderMode(grpc::ServerContext* context, const xrfdc::BlockRequest* request, xrfdc::GetDecoderModeResponse* response) override;
    grpc::Status SetDecoderMode(grpc::ServerContext* context, const xrfdc::SetDecoderModeRequest* request, xrfdc::TileControlResponse* response) override;
    grpc::Status GetOutputCurr(grpc::ServerContext* context, const xrfdc::BlockRequest* request, xrfdc::GetOutputCurrResponse* response) override;
    grpc::Status GetInvSincFIR(grpc::ServerContext* context, const xrfdc::BlockRequest* request, xrfdc::GetInvSincFIRResponse* response) override;
    grpc::Status SetInvSincFIR(grpc::ServerContext* context, const xrfdc::SetInvSincFIRRequest* request, xrfdc::TileControlResponse* response) override;
    grpc::Status GetDataPathMode(grpc::ServerContext* context, const xrfdc::BlockRequest* request, xrfdc::GetDataPathModeResponse* response) override;
    grpc::Status SetDataPathMode(grpc::ServerContext* context, const xrfdc::SetDataPathModeRequest* request, xrfdc::TileControlResponse* response) override;
    grpc::Status GetIMRPassMode(grpc::ServerContext* context, const xrfdc::BlockRequest* request, xrfdc::GetIMRPassModeResponse* response) override;
    grpc::Status SetIMRPassMode(grpc::ServerContext* context, const xrfdc::SetIMRPassModeRequest* request, xrfdc::TileControlResponse* response) override;
    grpc::Status GetDACCompMode(grpc::ServerContext* context, const xrfdc::BlockRequest* request, xrfdc::GetDACCompModeResponse* response) override;
    grpc::Status SetDACCompMode(grpc::ServerContext* context, const xrfdc::SetDACCompModeRequest* request, xrfdc::TileControlResponse* response) override;
    grpc::Status SetDACVOP(grpc::ServerContext* context, const xrfdc::SetDACVOPRequest* request, xrfdc::TileControlResponse* response) override;
    grpc::Status DumpRegs(grpc::ServerContext* context, const xrfdc::TileRequest* request, xrfdc::TileControlResponse* response) override;
    grpc::Status SetupFIFOObs(grpc::ServerContext* context, const xrfdc::SetupFIFORequest* request, xrfdc::TileControlResponse* response) override;
    grpc::Status SetupFIFOBoth(grpc::ServerContext* context, const xrfdc::SetupFIFORequest* request, xrfdc::TileControlResponse* response) override;
    grpc::Status GetFIFOStatusObs(grpc::ServerContext* context, const xrfdc::TileRequest* request, xrfdc::GetFIFOStatusResponse* response) override;
    grpc::Status GetPLLConfig(grpc::ServerContext* context, const xrfdc::TileRequest* request, xrfdc::GetPLLConfigResponse* response) override;
    grpc::Status GetCoarseDelaySettings(grpc::ServerContext* context, const xrfdc::GetCoarseDelaySettingsRequest* request, xrfdc::GetCoarseDelaySettingsResponse* response) override;
    grpc::Status SetCoarseDelaySettings(grpc::ServerContext* context, const xrfdc::SetCoarseDelaySettingsRequest* request, xrfdc::SetCoarseDelaySettingsResponse* response) override;
    grpc::Status GetPwrMode(grpc::ServerContext* context, const xrfdc::BlockRequest* request, xrfdc::GetPwrModeResponse* response) override;
    grpc::Status SetPwrMode(grpc::ServerContext* context, const xrfdc::SetPwrModeRequest* request, xrfdc::TileControlResponse* response) override;
    grpc::Status GetDecimationFactorObs(grpc::ServerContext* context, const xrfdc::BlockRequest* request, xrfdc::GetDecimationFactorResponse* response) override;
    grpc::Status SetDecimationFactorObs(grpc::ServerContext* context, const xrfdc::SetDecimationFactorRequest* request, xrfdc::TileControlResponse* response) override;
    grpc::Status GetFabRdVldWordsObs(grpc::ServerContext* context, const xrfdc::BlockRequest* request, xrfdc::GetFabRdVldWordsObsResponse* response) override;
    grpc::Status SetFabRdVldWordsObs(grpc::ServerContext* context, const xrfdc::SetFabRdVldWordsObsRequest* request, xrfdc::TileControlResponse* response) override;
    grpc::Status GetFabWrVldWordsObs(grpc::ServerContext* context, const xrfdc::BlockRequest* request, xrfdc::GetFabWrVldWordsObsResponse* response) override;
    grpc::Status GetCalFreeze(grpc::ServerContext* context, const xrfdc::BlockRequest* request, xrfdc::GetCalFreezeResponse* response) override;
    grpc::Status SetCalFreeze(grpc::ServerContext* context, const xrfdc::SetCalFreezeRequest* request, xrfdc::TileControlResponse* response) override;
    grpc::Status GetDSA(grpc::ServerContext* context, const xrfdc::BlockRequest* request, xrfdc::GetDSAResponse* response) override;
    grpc::Status SetDSA(grpc::ServerContext* context, const xrfdc::SetDSARequest* request, xrfdc::TileControlResponse* response) override;
    grpc::Status DisableCoefficientsOverride(grpc::ServerContext* context, const xrfdc::DisableCoefficientsOverrideRequest* request, xrfdc::TileControlResponse* response) override;
    grpc::Status ResetInternalFIFOWidthObs(grpc::ServerContext* context, const xrfdc::BlockRequest* request, xrfdc::TileControlResponse* response) override;
    grpc::Status SetCalCoefficients(grpc::ServerContext* context, const xrfdc::SetCalCoefficientsRequest* request, xrfdc::TileControlResponse* response) override;
    grpc::Status GetCalCoefficients(grpc::ServerContext* context, const xrfdc::GetCalCoefficientsRequest* request, xrfdc::GetCalCoefficientsResponse* response) override;
    grpc::Status GetClkDistribution(grpc::ServerContext* context, const xrfdc::GetClkDistributionRequest* request, xrfdc::GetClkDistributionResponse* response) override;
    grpc::Status SetClkDistribution(grpc::ServerContext* context, const xrfdc::SetClkDistributionRequest* request, xrfdc::TileControlResponse* response) override;
};

#endif // XRFDC_H
