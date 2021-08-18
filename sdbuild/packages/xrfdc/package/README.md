# `xrfdc` Package

This is a package implementing the drivers for RF data converter IP.

## Usage

The class `RFdc` is bound to the IP `xilinx.com:ip:usp_rf_data_converter:2.4`.
Once the overlay is loaded, the data converter IP will be allocated the driver
code implemented in this class.

To reduce the amount of typing we define the properties we want for each
class in the hierarchy. Each element of the array is a tuple consisting of
the property name, the type of the property and whether or not it is
read-only. These should match the specification of the C API but without the
`XRFdc_` prefix in the case of the function name. For example,
if the C function prototype is `XRFdc_StartUp()`, the Python wrapper API will
be `StartUp()`.

The class `RFdc` has wrapped up many C functions.
A complete list of available C function prototypes:

```c
XRFdc_Config *XRFdc_LookupConfig(u16 DeviceId);
u32 XRFdc_CfgInitialize(XRFdc *InstancePtr, XRFdc_Config *ConfigPtr);
u32 XRFdc_StartUp(XRFdc *InstancePtr, u32 Type, int Tile_Id);
u32 XRFdc_Shutdown(XRFdc *InstancePtr, u32 Type, int Tile_Id);
u32 XRFdc_Reset(XRFdc *InstancePtr, u32 Type, int Tile_Id);
u32 XRFdc_GetIPStatus(XRFdc *InstancePtr, XRFdc_IPStatus *IPStatusPtr);
u32 XRFdc_GetBlockStatus(XRFdc *InstancePtr, u32 Type, u32 Tile_Id,
				u32 Block_Id, XRFdc_BlockStatus *BlockStatusPtr);
u32 XRFdc_SetMixerSettings(XRFdc *InstancePtr, u32 Type, u32 Tile_Id,
			u32 Block_Id, XRFdc_Mixer_Settings *MixerSettingsPtr);
u32 XRFdc_GetMixerSettings(XRFdc *InstancePtr, u32 Type,
				u32 Tile_Id, u32 Block_Id,
				XRFdc_Mixer_Settings *MixerSettingsPtr);
u32 XRFdc_SetQMCSettings(XRFdc *InstancePtr, u32 Type, u32 Tile_Id,
				u32 Block_Id, XRFdc_QMC_Settings *QMCSettingsPtr);
u32 XRFdc_GetQMCSettings(XRFdc *InstancePtr, u32 Type, u32 Tile_Id,
				u32 Block_Id, XRFdc_QMC_Settings *QMCSettingsPtr);
u32 XRFdc_GetCoarseDelaySettings(XRFdc *InstancePtr, u32 Type,
				u32 Tile_Id, u32 Block_Id,
				XRFdc_CoarseDelay_Settings *CoarseDelaySettingsPtr);
u32 XRFdc_SetCoarseDelaySettings(XRFdc *InstancePtr, u32 Type, u32 Tile_Id,
				u32 Block_Id,
				XRFdc_CoarseDelay_Settings *CoarseDelaySettingsPtr);
u32 XRFdc_GetInterpolationFactor(XRFdc *InstancePtr, u32 Tile_Id,
				u32 Block_Id, u32 *InterpolationFactorPtr);
u32 XRFdc_GetDecimationFactor(XRFdc *InstancePtr, u32 Tile_Id,
				u32 Block_Id, u32 *DecimationFactorPtr);
u32 XRFdc_GetFabWrVldWords(XRFdc *InstancePtr, u32 Type,
				u32 Tile_Id, u32 Block_Id, u32 *FabricDataRatePtr);
u32 XRFdc_GetFabRdVldWords(XRFdc *InstancePtr, u32 Type,
				u32 Tile_Id, u32 Block_Id, u32 *FabricDataRatePtr);
u32 XRFdc_SetFabRdVldWords(XRFdc *InstancePtr, u32 Tile_Id, u32 Block_Id,
								u32 FabricRdVldWords);
u32 XRFdc_SetFabWrVldWords(XRFdc *InstancePtr, u32 Tile_Id, u32 Block_Id,
								u32 FabricWrVldWords);
u32 XRFdc_GetThresholdSettings(XRFdc *InstancePtr, u32 Tile_Id,
				u32 Block_Id, XRFdc_Threshold_Settings *ThresholdSettingsPtr);
u32 XRFdc_SetThresholdSettings(XRFdc *InstancePtr, u32 Tile_Id, u32 Block_Id,
				XRFdc_Threshold_Settings *ThresholdSettingsPtr);
u32 XRFdc_SetDecoderMode(XRFdc *InstancePtr, u32 Tile_Id, u32 Block_Id,
				u32 DecoderMode);
u32 XRFdc_UpdateEvent(XRFdc *InstancePtr, u32 Type, u32 Tile_Id, u32 Block_Id,
				u32 Event);
u32 XRFdc_GetDecoderMode(XRFdc *InstancePtr, u32 Tile_Id, u32 Block_Id,
				u32 *DecoderModePtr);
u32 XRFdc_ResetNCOPhase(XRFdc *InstancePtr, u32 Type, u32 Tile_Id,
				u32 Block_Id);
void XRFdc_DumpRegs(XRFdc *InstancePtr, u32 Type, int Tile_Id);
u32 XRFdc_MultiBand(XRFdc *InstancePtr, u32 Type, u32 Tile_Id,
		u8 DigitalDataPathMask, u32 DataType, u32 DataConverterMask);
u32 XRFdc_IntrHandler(u32 Vector, void *XRFdcPtr);
void XRFdc_IntrClr(XRFdc *InstancePtr, u32 Type, u32 Tile_Id,
								u32 Block_Id, u32 IntrMask);
u32 XRFdc_GetIntrStatus(XRFdc *InstancePtr, u32 Type, u32 Tile_Id,
								u32 Block_Id);
void XRFdc_IntrDisable(XRFdc *InstancePtr, u32 Type, u32 Tile_Id,
								u32 Block_Id, u32 IntrMask);
void XRFdc_IntrEnable(XRFdc *InstancePtr, u32 Type, u32 Tile_Id,
								u32 Block_Id, u32 IntrMask);
u32 XRFdc_SetThresholdClrMode(XRFdc *InstancePtr, u32 Tile_Id,
			u32 Block_Id, u32 ThresholdToUpdate, u32 ClrMode);
u32 XRFdc_ThresholdStickyClear(XRFdc *InstancePtr, u32 Tile_Id,
					u32 Block_Id, u32 ThresholdToUpdate);
void XRFdc_SetStatusHandler(XRFdc *InstancePtr, void *CallBackRef,
				XRFdc_StatusHandler FunctionPtr);
u32 XRFdc_SetupFIFO(XRFdc *InstancePtr, u32 Type, int Tile_Id, u8 Enable);
u32 XRFdc_GetFIFOStatus(XRFdc *InstancePtr, u32 Type,
				u32 Tile_Id, u8 *EnablePtr);
u32 XRFdc_SetNyquistZone(XRFdc *InstancePtr, u32 Type, u32 Tile_Id,
								u32 Block_Id, u32 NyquistZone);
u32 XRFdc_GetNyquistZone(XRFdc *InstancePtr, u32 Type, u32 Tile_Id,
								u32 Block_Id, u32 *NyquistZonePtr);
u32 XRFdc_GetOutputCurr(XRFdc *InstancePtr, u32 Tile_Id,
								u32 Block_Id, u32 *OutputCurrPtr);
u32 XRFdc_SetDecimationFactor(XRFdc *InstancePtr, u32 Tile_Id, u32 Block_Id,
						u32 DecimationFactor);
u32 XRFdc_SetInterpolationFactor(XRFdc *InstancePtr, u32 Tile_Id, 
						u32 Block_Id, u32 InterpolationFactor);
u32 XRFdc_SetFabClkOutDiv(XRFdc *InstancePtr, u32 Type, u32 Tile_Id,
								u16 FabClkDiv);
u32 XRFdc_SetCalibrationMode(XRFdc *InstancePtr, u32 Tile_Id, u32 Block_Id,
						u8 CalibrationMode);
u32 XRFdc_GetCalibrationMode(XRFdc *InstancePtr, u32 Tile_Id, u32 Block_Id,
						u8 *CalibrationModePtr);
u32 XRFdc_GetClockSource(XRFdc *InstancePtr, u32 Type, u32 Tile_Id,
								u32 *ClockSourcePtr);
u32 XRFdc_GetPLLLockStatus(XRFdc *InstancePtr, u32 Type, u32 Tile_Id,
							u32 *LockStatusPtr);

u32 XRFdc_DynamicPLLConfig(XRFdc *InstancePtr, u32 Type, u32 Tile_Id,
		u8 Source, double RefClkFreq, double SamplingRate);
u32 XRFdc_SetInvSincFIR(XRFdc *InstancePtr, u32 Tile_Id, u32 Block_Id,
								u16 Enable);
u32 XRFdc_GetInvSincFIR(XRFdc *InstancePtr, u32 Tile_Id, u32 Block_Id,
								u16 *EnablePtr);
u32 XRFdc_GetLinkCoupling(XRFdc *InstancePtr, u32 Tile_Id, u32 Block_Id,
								u32 *ModePtr);
u32 XRFdc_GetFabClkOutDiv(XRFdc *InstancePtr, u32 Type, u32 Tile_Id,
								u16 *FabClkDivPtr);
```

This list can also be found at the `Function Prototypes` section of 
`xrfdc/xrfdc_functions.c`.

The underlying C functions for generic behaviour (applies to both DAC
and ADC blocks) expect an argument for the type of block used.
Other functions leave the type of block implicit. We handle this distinction
by bubbling up through either `_call_function` or `_call_function_implicit`
calls. You can check `_create_c_property()` for more information.

Finally we define the object hierarchy. Each element of the object
hierarchy has a `_call_function` method which handles adding the
block/tile/toplevel arguments to the list of function parameters.

Some functions are Gen 3 specific. These are clearly labelled in the RFDC user guide. 
If attempting to use one of these functions on a Gen 1 board, the user will see the error:
metal: error:     
 Requested functionality not available for this IP 

Copyright (C) 2021 Xilinx, Inc

SPDX-License-Identifier: BSD-3-Clause
