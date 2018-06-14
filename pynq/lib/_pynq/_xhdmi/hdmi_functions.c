#include <xv_hdmitxss.h>
#include <xv_hdmirxss.h>
#include <xvphy.h>
#include <stdio.h>
#include <libxlnk_cma.h>

unsigned char edid_1920x1080[] = {
	0x00, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0x00,
	0x61, 0x98, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
	0x01, 0x18, 0x01, 0x03, 0xa1, 0x00, 0x00, 0x80,
	0x06, 0xee, 0x91, 0xa3, 0x54, 0x4c, 0x99, 0x26,
	0x0f, 0x50, 0x54, 0x21, 0x80, 0x00, 0xd1, 0x00,
	0xd1, 0xc0, 0x81, 0x00, 0x81, 0xc0, 0x01, 0x01,
	0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x02, 0x3a,
	0x80, 0x18, 0x71, 0x38, 0x2d, 0x40, 0x58, 0x2c,
	0x45, 0x00, 0x55, 0x50, 0x21, 0x00, 0x00, 0x1e,
	0x08, 0xe8, 0x00, 0x30, 0xf2, 0x70, 0x5a, 0x80,
	0xb0, 0x58, 0x8a, 0x00, 0x55, 0x50, 0x21, 0x00,
	0x00, 0x1e, 0x00, 0x00, 0x00, 0xfc, 0x00, 0x58,
	0x69, 0x6c, 0x69, 0x6e, 0x78, 0x20, 0x50, 0x59,
	0x4e, 0x51, 0x0a, 0x20, 0x00, 0x00, 0x00, 0xfd,
	0x00, 0x1d, 0x56, 0x1e, 0x8c, 0x3c, 0x00, 0x0a,
	0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x01, 0x34,
	0x02, 0x03, 0x42, 0xf1, 0x51, 0x61, 0x60, 0x5f,
	0x5e, 0x5d, 0x10, 0x1f, 0x20, 0x05, 0x14, 0x04,
	0x13, 0x12, 0x11, 0x03, 0x02, 0x01, 0x23, 0x09,
	0x1f, 0x07, 0x83, 0x01, 0x00, 0x00, 0x6d, 0x03,
	0x0c, 0x00, 0x10, 0x00, 0x38, 0x3c, 0x20, 0x00,
	0x60, 0x01, 0x02, 0x03, 0x67, 0xd8, 0x5d, 0xc4,
	0x01, 0x78, 0x80, 0x03, 0xe2, 0x0f, 0x03, 0xe3,
	0x05, 0xff, 0x01, 0xe6, 0x06, 0x07, 0x01, 0x8b,
	0x60, 0x11, 0x56, 0x5e, 0x00, 0xa0, 0xa0, 0xa0,
	0x29, 0x50, 0x30, 0x20, 0x35, 0x00, 0x55, 0x50,
	0x21, 0x00, 0x00, 0x1a, 0x11, 0x44, 0x00, 0xa0,
	0x80, 0x00, 0x1f, 0x50, 0x30, 0x20, 0x36, 0x00,
	0x55, 0x50, 0x21, 0x00, 0x00, 0x1a, 0xbf, 0x16,
	0x00, 0xa0, 0x80, 0x38, 0x13, 0x40, 0x30, 0x20,
	0x3a, 0x00, 0x55, 0x50, 0x21, 0x00, 0x00, 0x1a,
	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xca
};

unsigned int edid_1920x1080_len = 256;

typedef struct {
	XVphy Vphy;
	XVphy_Config config;
} HdmiPhy;

typedef struct {
	XV_HdmiRxSs HdmiRxSs;
	XV_HdmiRxSs_Config config;
	HdmiPhy* phy;
} HdmiRx;

typedef struct {
	XV_HdmiTxSs HdmiTxSs;
	XV_HdmiTxSs_Config config;
	HdmiPhy* phy;
} HdmiTx;

void VphyHdmiTxInitCallback(void *CallbackRef) {
	HdmiTx* tx = (HdmiTx*)CallbackRef;
	XV_HdmiTxSs_RefClockChangeInit(&tx->HdmiTxSs);
}

void RxStreamInitCallback(void* CallbackRef) {
	HdmiRx* rx = (HdmiRx*)CallbackRef;

	XVidC_VideoStream *rxStream = XV_HdmiRxSs_GetVideoStream(&rx->HdmiRxSs);
	unsigned int status = XVphy_HdmiCfgCalcMmcmParam(&rx->phy->Vphy, 0, XVPHY_CHANNEL_ID_CH1,
			XVPHY_DIR_RX, rxStream->PixPerClk, rxStream->ColorDepth);
	if (status == XST_FAILURE) {
		printf("Stream Init Failed\n");
	}
	XVphy_MmcmStart(&rx->phy->Vphy, 0, XVPHY_DIR_RX);
}

void VphyHdmiRxInitCallback(void *CallbackRef) {
	HdmiRx* rx = (HdmiRx*)CallbackRef;

        XV_HdmiRxSs_RefClockChangeInit(&rx->HdmiRxSs);
        rx->phy->Vphy.HdmiRxTmdsClockRatio = rx->HdmiRxSs.TMDSClockRatio;
}

void VphyHdmiRxReadyCallback(void *CallbackRef) {
	HdmiRx* rx = (HdmiRx*)CallbackRef;
        XVphy_PllType RxPllType;

	printf("RX Clock: %d\n", rx->phy->Vphy.HdmiRxRefClkHz);

        RxPllType = XVphy_GetPllType(&rx->phy->Vphy, 0, XVPHY_DIR_RX,
                                                                 XVPHY_CHANNEL_ID_CH1);
        if (!(RxPllType == XVPHY_PLL_TYPE_CPLL)) {
                XV_HdmiRxSs_SetStream(&rx->HdmiRxSs, rx->phy->Vphy.HdmiRxRefClkHz,
                        (XVphy_GetLineRateHz(&rx->phy->Vphy, 0, XVPHY_CHANNEL_ID_CMN0)/1000000));

        } else {
                XV_HdmiRxSs_SetStream(&rx->HdmiRxSs, rx->phy->Vphy.HdmiRxRefClkHz,
                         (XVphy_GetLineRateHz(&rx->phy->Vphy, 0, XVPHY_CHANNEL_ID_CH1)/1000000));
        }
}

void TxVsCallback(void *CallbackRef) {
	HdmiTx* tx = (HdmiTx*)CallbackRef;
	XHdmiC_AVI_InfoFrame *AviInfoFramePtr;
	AviInfoFramePtr = XV_HdmiTxSs_GetAviInfoframe(&tx->HdmiTxSs);
	XHdmiC_Aux info_frame = XV_HdmiC_AVIIF_GeneratePacket(AviInfoFramePtr);
	XV_HdmiTxSs_SendGenericAuxInfoframe(&tx->HdmiTxSs, &info_frame);
}

void* HdmiPhy_new(unsigned long BaseAddress) {
	HdmiPhy* phy = (HdmiPhy*)calloc(1, sizeof(HdmiPhy));
	if (!phy) return 0;
	phy->config = *XVphy_LookupConfig(XPAR_VPHY_0_DEVICE_ID);
	long offset = BaseAddress - phy->config.BaseAddr;
	phy->config.BaseAddr += offset;
	int status = XVphy_Hdmi_CfgInitialize(&phy->Vphy, 0, &phy->config);
	if (status != XST_SUCCESS) {
		free(phy);
		return 0;
	}
	return phy;
}

void HdmiPhy_free(void* handle) {
	free(handle);
}

void HdmiPhy_handle_events(void* handle) {
	HdmiPhy* phy = (HdmiPhy*)handle;
	XVphy_InterruptHandler(&phy->Vphy);
}

void HdmiPhy_report(void* handle) {
	HdmiPhy* phy = (HdmiPhy*)handle;
	XVphy_HdmiDebugInfo(&phy->Vphy, 0, XVPHY_CHANNEL_ID_CH1);
}

void* HdmiRx_new(unsigned long BaseAddress, void* phy_handle) {
	HdmiRx* rx = (HdmiRx*)calloc(1, sizeof(HdmiRx));
	if (!rx) return 0;
	rx->config = *XV_HdmiRxSs_LookupConfig(XPAR_XV_HDMIRX_0_DEVICE_ID);
	long offset = BaseAddress - rx->config.BaseAddress;
	rx->config.BaseAddress += offset;
	rx->config.HighAddress += offset;
	rx->config.HdmiRx.AbsAddr += offset;
	int status = XV_HdmiRxSs_CfgInitialize(&rx->HdmiRxSs, &rx->config, BaseAddress);
	if (status != XST_SUCCESS) {
		free(rx);
		return 0;
	}
	XV_HdmiRxSs_SetEdidParam(&rx->HdmiRxSs, edid_1920x1080, edid_1920x1080_len);
	XV_HdmiRxSs_LoadDefaultEdid(&rx->HdmiRxSs);
	rx->phy = (HdmiPhy*)phy_handle;
        XVphy_SetHdmiCallback(&rx->phy->Vphy,
		XVPHY_HDMI_HANDLER_RXREADY,
		(void *)VphyHdmiRxReadyCallback,
		(void *)rx);
        XVphy_SetHdmiCallback(&rx->phy->Vphy,
		XVPHY_HDMI_HANDLER_RXINIT,
		(void *)VphyHdmiRxInitCallback,
		(void *)rx);
	XV_HdmiRxSs_SetCallback(&rx->HdmiRxSs, XV_HDMIRXSS_HANDLER_STREAM_INIT,
		(void *)RxStreamInitCallback, (void *)rx);
	XV_HdmiRxSs_SetHpd(&rx->HdmiRxSs, FALSE);
	return rx;
}

void HdmiRx_free(void* handle) {
	free(handle);
}

void HdmiRx_handle_events(void* handle) {
	HdmiRx* rx = (HdmiRx*)handle;
	HdmiPhy_handle_events(rx->phy);
	XV_HdmiRxSS_HdmiRxIntrHandler(&rx->HdmiRxSs);
}

int HdmiRx_connected(void* handle) {
	HdmiRx* rx = (HdmiRx*)handle;
	return XV_HdmiRxSs_IsStreamConnected(&rx->HdmiRxSs);
}

int HdmiRx_ready(void* handle) {
	HdmiRx* rx = (HdmiRx*)handle;
	return XV_HdmiRxSs_IsStreamUp(&rx->HdmiRxSs);
}

int HdmiRx_hsize(void* handle) {
	HdmiRx* rx = (HdmiRx*)handle;
	XVidC_VideoStream *stream = XV_HdmiRxSs_GetVideoStream(&rx->HdmiRxSs);
	return stream->Timing.HActive;
}

int HdmiRx_vsize(void* handle) {
	HdmiRx* rx = (HdmiRx*)handle;
	XVidC_VideoStream *stream = XV_HdmiRxSs_GetVideoStream(&rx->HdmiRxSs);
	return stream->Timing.VActive;
}

int HdmiRx_fps(void* handle) {
	HdmiRx* rx = (HdmiRx*)handle;
	XVidC_VideoStream *stream = XV_HdmiRxSs_GetVideoStream(&rx->HdmiRxSs);
	return stream->FrameRate;
}

void HdmiRx_report(void* handle) {
	HdmiRx* rx = (HdmiRx*)handle;
	XV_HdmiRxSs_ReportInfo(&rx->HdmiRxSs);
}

void HdmiRx_load_edid(void* handle, unsigned char* data, unsigned length) {
	HdmiRx* rx = (HdmiRx*)handle;
	XV_HdmiRxSs_LoadEdid(&rx->HdmiRxSs, data, length);
}

void HdmiRx_set_hpd(void* handle, unsigned value) {
	HdmiRx* rx = (HdmiRx*)handle;
	XV_HdmiRxSs_SetHpd(&rx->HdmiRxSs, value);
}

void* HdmiTx_new(unsigned long BaseAddress, void* phy_handle) {
	HdmiTx* tx = (HdmiTx*)calloc(1, sizeof(HdmiTx));
	if (!tx) return 0;
	tx->config = *XV_HdmiTxSs_LookupConfig(XPAR_XV_HDMITX_0_DEVICE_ID);
	long offset = BaseAddress - tx->config.BaseAddress;
	tx->config.BaseAddress += offset;
	tx->config.HighAddress += offset;
	tx->config.HdmiTx.AbsAddr += offset;
	tx->config.Vtc.AbsAddr += offset;
	int status = XV_HdmiTxSs_CfgInitialize(&tx->HdmiTxSs, &tx->config, BaseAddress);
	if (status != XST_SUCCESS) {
		free(tx);
		return 0;
	}
	tx->phy = (HdmiPhy*)phy_handle;

        XVphy_SetHdmiCallback(&tx->phy->Vphy,
		XVPHY_HDMI_HANDLER_TXINIT,
		(void *)VphyHdmiTxInitCallback,
		(void *)tx);

	XV_HdmiTxSs_SetCallback(&tx->HdmiTxSs,
			XV_HDMITXSS_HANDLER_VS,
			(void*) TxVsCallback,
			(void*) tx);
	return tx;
}

void HdmiTx_free(void* handle) {
	free(handle);
}

void HdmiTx_handle_events(void* handle) {
	HdmiTx* tx = (HdmiTx*)handle;
	HdmiPhy_handle_events(tx->phy);
	XV_HdmiTxSS_HdmiTxIntrHandler(&tx->HdmiTxSs);
}

int HdmiTx_connected(void* handle) {
	HdmiTx* tx = (HdmiTx*)handle;
	return XV_HdmiTxSs_IsStreamConnected(&tx->HdmiTxSs);
}

int HdmiTx_set_format(void* handle, int hsize, int vsize, int fps) {
	XVidC_VideoMode mode = XVidC_GetVideoModeId(hsize, vsize, fps, 0);
	XHdmiC_AVI_InfoFrame *AviInfoFramePtr;
	if (mode == XVIDC_VM_NOT_SUPPORTED) return -1;
	
	HdmiTx* tx = (HdmiTx*)handle;
	XV_HdmiTxSs_DetectHdmi20(&tx->HdmiTxSs);
	AviInfoFramePtr = XV_HdmiTxSs_GetAviInfoframe(&tx->HdmiTxSs);
	int clock = XV_HdmiTxSs_SetStream(&tx->HdmiTxSs, mode, XVIDC_CSF_RGB, XVIDC_BPC_8, NULL);

	tx->phy->Vphy.HdmiTxRefClkHz = clock;
	int status = XVphy_SetHdmiTxParam(&tx->phy->Vphy, 0, XVPHY_CHANNEL_ID_CHA, 2, 8, XVIDC_CSF_RGB);
	if (status != XST_SUCCESS) {
		return -2;
	}
	AviInfoFramePtr->Version = 2;
	AviInfoFramePtr->ColorSpace = XV_HdmiC_XVidC_To_IfColorformat(XVIDC_CSF_RGB);
	AviInfoFramePtr->VIC = tx->HdmiTxSs.HdmiTxPtr->Stream.Vic;
	return tx->phy->Vphy.HdmiTxRefClkHz;
}

unsigned long long HdmiTx_line_rate(void* handle) {
	HdmiTx* tx = (HdmiTx*)handle;
	XVphy_PllType TxPllType;
	TxPllType = XVphy_GetPllType(&tx->phy->Vphy, 0, XVPHY_DIR_TX, XVPHY_CHANNEL_ID_CH1);
	if ((TxPllType == XVPHY_PLL_TYPE_CPLL)) {
		return XVphy_GetLineRateHz(&tx->phy->Vphy, 0, XVPHY_CHANNEL_ID_CH1);
	} else if((TxPllType == XVPHY_PLL_TYPE_QPLL) ||
			  (TxPllType == XVPHY_PLL_TYPE_QPLL0) ||
			  (TxPllType == XVPHY_PLL_TYPE_PLL0)) {
		return XVphy_GetLineRateHz(&tx->phy->Vphy, 0, XVPHY_CHANNEL_ID_CMN0);
	} else {
		return XVphy_GetLineRateHz(&tx->phy->Vphy, 0, XVPHY_CHANNEL_ID_CMN1);
	}

}

int HdmiTx_start(void* handle) {
	HdmiTx* tx = (HdmiTx*)handle;
	XVphy_Clkout1OBufTdsEnable(&tx->phy->Vphy, XVPHY_DIR_TX, (TRUE));
	XVphy_IBufDsEnable(&tx->phy->Vphy, 0, XVPHY_DIR_TX, (TRUE));
	XV_HdmiTxSs_SetSamplingRate(&tx->HdmiTxSs, tx->phy->Vphy.HdmiTxSampleRate);
	XV_HdmiTxSs_StreamStart(&tx->HdmiTxSs);
	XV_HdmiTxSs_AudioMute(&tx->HdmiTxSs, TRUE);
	return 1;
}

void HdmiTx_stop(void* handle) {
	HdmiTx* tx = (HdmiTx*)handle;
	XVphy_Clkout1OBufTdsEnable(&tx->phy->Vphy, XVPHY_DIR_TX, (FALSE));
}

void HdmiTx_dvi_mode(void* handle) {
	HdmiTx* tx = (HdmiTx*)handle;
	XV_HdmiTxSS_SetDviMode(&tx->HdmiTxSs);
}

void HdmiTx_hdmi_mode(void* handle) {
	HdmiTx* tx = (HdmiTx*)handle;
	XV_HdmiTxSS_SetHdmiMode(&tx->HdmiTxSs);
}

int HdmiTx_read_edid(void* handle, unsigned char* data) {
	HdmiTx* tx = (HdmiTx*)handle;
	return XV_HdmiTxSs_ReadEdid(&tx->HdmiTxSs, data);
}


int HdmiTx_ready(void* handle) {
	HdmiTx* tx = (HdmiTx*)handle;
	return XV_HdmiTxSs_IsStreamUp(&tx->HdmiTxSs);
}

void HdmiTx_report(void* handle) {
	HdmiTx* tx = (HdmiTx*)handle;
	XV_HdmiTxSs_ReportInfo(&tx->HdmiTxSs);
}

