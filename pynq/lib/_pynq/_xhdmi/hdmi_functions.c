#include <xv_hdmitxss.h>
#include <xv_hdmirxss.h>
#include <xvphy.h>
#include <stdio.h>
#include <libxlnk_cma.h>

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

int HdmiTx_set_format(void* handle, int hsize, int vsize) {
	XVidC_VideoMode mode = XVidC_GetVideoModeId(hsize, vsize, 60, 0);
	if (mode == XVIDC_VM_NOT_SUPPORTED) return 0;
	
	HdmiTx* tx = (HdmiTx*)handle;
	int clock = XV_HdmiTxSs_SetStream(&tx->HdmiTxSs, mode, XVIDC_CSF_RGB, XVIDC_BPC_8, NULL);
	tx->phy->Vphy.HdmiTxRefClkHz = clock;
	return clock;
}

int HdmiTx_start(void* handle) {
	HdmiTx* tx = (HdmiTx*)handle;
	int status = XVphy_SetHdmiTxParam(&tx->phy->Vphy, 0, XVPHY_CHANNEL_ID_CHA, 2, 8, XVIDC_CSF_RGB);
	if (status != XST_SUCCESS) {
		return 0;
	}
	XVphy_Clkout1OBufTdsEnable(&tx->phy->Vphy, XVPHY_DIR_TX, (TRUE));
	XVphy_IBufDsEnable(&tx->phy->Vphy, 0, XVPHY_DIR_TX, (TRUE));
	XV_HdmiTxSs_StreamStart(&tx->HdmiTxSs);
}

int HdmiTx_ready(void* handle) {
	HdmiTx* tx = (HdmiTx*)handle;
	return XV_HdmiTxSs_IsStreamUp(&tx->HdmiTxSs);
}

