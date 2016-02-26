/*****************************************************************************
 * File : processing_system7_bfm_v2_0_5_processing_system7_bfm.v
 *
 * Date : 2012-11
 *
 * Description : Processing_system7_bfm Top (zynq_bfm top)
 *
 *****************************************************************************/
 `timescale 1ns/1ps

module processing_system7_bfm_v2_0_5_processing_system7_bfm
  (
    CAN0_PHY_TX,
    CAN0_PHY_RX,
    CAN1_PHY_TX,
    CAN1_PHY_RX,
    ENET0_GMII_TX_EN,
    ENET0_GMII_TX_ER,
    ENET0_MDIO_MDC,
    ENET0_MDIO_O,
    ENET0_MDIO_T,
    ENET0_PTP_DELAY_REQ_RX,
    ENET0_PTP_DELAY_REQ_TX,
    ENET0_PTP_PDELAY_REQ_RX,
    ENET0_PTP_PDELAY_REQ_TX,
    ENET0_PTP_PDELAY_RESP_RX,
    ENET0_PTP_PDELAY_RESP_TX,
    ENET0_PTP_SYNC_FRAME_RX,
    ENET0_PTP_SYNC_FRAME_TX,
    ENET0_SOF_RX,
    ENET0_SOF_TX,
    ENET0_GMII_TXD,
    ENET0_GMII_COL,
    ENET0_GMII_CRS,
    ENET0_EXT_INTIN,
    ENET0_GMII_RX_CLK,
    ENET0_GMII_RX_DV,
    ENET0_GMII_RX_ER,
    ENET0_GMII_TX_CLK,
    ENET0_MDIO_I,
    ENET0_GMII_RXD,
    ENET1_GMII_TX_EN,
    ENET1_GMII_TX_ER,
    ENET1_MDIO_MDC,
    ENET1_MDIO_O,
    ENET1_MDIO_T,
    ENET1_PTP_DELAY_REQ_RX,
    ENET1_PTP_DELAY_REQ_TX,
    ENET1_PTP_PDELAY_REQ_RX,
    ENET1_PTP_PDELAY_REQ_TX,
    ENET1_PTP_PDELAY_RESP_RX,
    ENET1_PTP_PDELAY_RESP_TX,
    ENET1_PTP_SYNC_FRAME_RX,
    ENET1_PTP_SYNC_FRAME_TX,
    ENET1_SOF_RX,
    ENET1_SOF_TX,
    ENET1_GMII_TXD,
    ENET1_GMII_COL,
    ENET1_GMII_CRS,
    ENET1_EXT_INTIN,
    ENET1_GMII_RX_CLK,
    ENET1_GMII_RX_DV,
    ENET1_GMII_RX_ER,
    ENET1_GMII_TX_CLK,
    ENET1_MDIO_I,
    ENET1_GMII_RXD,
    GPIO_I,
    GPIO_O,
    GPIO_T,
    I2C0_SDA_I,
    I2C0_SDA_O,
    I2C0_SDA_T,
    I2C0_SCL_I,
    I2C0_SCL_O,
    I2C0_SCL_T,
    I2C1_SDA_I,
    I2C1_SDA_O,
    I2C1_SDA_T,
    I2C1_SCL_I,
    I2C1_SCL_O,
    I2C1_SCL_T,
    PJTAG_TCK,
    PJTAG_TMS,
    PJTAG_TD_I,
    PJTAG_TD_T,
    PJTAG_TD_O,
    SDIO0_CLK,
    SDIO0_CLK_FB,
    SDIO0_CMD_O,
    SDIO0_CMD_I,
    SDIO0_CMD_T,
    SDIO0_DATA_I,
    SDIO0_DATA_O,
    SDIO0_DATA_T,
    SDIO0_LED,
    SDIO0_CDN,
    SDIO0_WP,
    SDIO0_BUSPOW,
    SDIO0_BUSVOLT,
    SDIO1_CLK,
    SDIO1_CLK_FB,
    SDIO1_CMD_O,
    SDIO1_CMD_I,
    SDIO1_CMD_T,
    SDIO1_DATA_I,
    SDIO1_DATA_O,
    SDIO1_DATA_T,
    SDIO1_LED,
    SDIO1_CDN,
    SDIO1_WP,
    SDIO1_BUSPOW,
    SDIO1_BUSVOLT,
    SPI0_SCLK_I,
    SPI0_SCLK_O,
    SPI0_SCLK_T,
    SPI0_MOSI_I,
    SPI0_MOSI_O,
    SPI0_MOSI_T,
    SPI0_MISO_I,
    SPI0_MISO_O,
    SPI0_MISO_T,
    SPI0_SS_I,
    SPI0_SS_O,
    SPI0_SS1_O,
    SPI0_SS2_O,
    SPI0_SS_T,
    SPI1_SCLK_I,
    SPI1_SCLK_O,
    SPI1_SCLK_T,
    SPI1_MOSI_I,
    SPI1_MOSI_O,
    SPI1_MOSI_T,
    SPI1_MISO_I,
    SPI1_MISO_O,
    SPI1_MISO_T,
    SPI1_SS_I,
    SPI1_SS_O,
    SPI1_SS1_O,
    SPI1_SS2_O,
    SPI1_SS_T,
    UART0_DTRN,
    UART0_RTSN,
    UART0_TX,
    UART0_CTSN,
    UART0_DCDN,
    UART0_DSRN,
    UART0_RIN,
    UART0_RX,
    UART1_DTRN,
    UART1_RTSN,
    UART1_TX,
    UART1_CTSN,
    UART1_DCDN,
    UART1_DSRN,
    UART1_RIN,
    UART1_RX,
    TTC0_WAVE0_OUT,
    TTC0_WAVE1_OUT,
    TTC0_WAVE2_OUT,
    TTC0_CLK0_IN,
    TTC0_CLK1_IN,
    TTC0_CLK2_IN,
    TTC1_WAVE0_OUT,
    TTC1_WAVE1_OUT,
    TTC1_WAVE2_OUT,
    TTC1_CLK0_IN,
    TTC1_CLK1_IN,
    TTC1_CLK2_IN,
    WDT_CLK_IN,
    WDT_RST_OUT,
    TRACE_CLK,
    TRACE_CTL,
    TRACE_DATA,
    USB0_PORT_INDCTL,
    USB1_PORT_INDCTL,
    USB0_VBUS_PWRSELECT,
    USB1_VBUS_PWRSELECT,
    USB0_VBUS_PWRFAULT,
    USB1_VBUS_PWRFAULT,
    SRAM_INTIN,
    M_AXI_GP0_ARVALID,
    M_AXI_GP0_AWVALID,
    M_AXI_GP0_BREADY,
    M_AXI_GP0_RREADY,
    M_AXI_GP0_WLAST,
    M_AXI_GP0_WVALID,
    M_AXI_GP0_ARID,
    M_AXI_GP0_AWID,
    M_AXI_GP0_WID,
    M_AXI_GP0_ARBURST,
    M_AXI_GP0_ARLOCK,
    M_AXI_GP0_ARSIZE,
    M_AXI_GP0_AWBURST,
    M_AXI_GP0_AWLOCK,
    M_AXI_GP0_AWSIZE,
    M_AXI_GP0_ARPROT,
    M_AXI_GP0_AWPROT,
    M_AXI_GP0_ARADDR,
    M_AXI_GP0_AWADDR,
    M_AXI_GP0_WDATA,
    M_AXI_GP0_ARCACHE,
    M_AXI_GP0_ARLEN,
    M_AXI_GP0_ARQOS,
    M_AXI_GP0_AWCACHE,
    M_AXI_GP0_AWLEN,
    M_AXI_GP0_AWQOS,
    M_AXI_GP0_WSTRB,
    M_AXI_GP0_ACLK,
    M_AXI_GP0_ARREADY,
    M_AXI_GP0_AWREADY,
    M_AXI_GP0_BVALID,
    M_AXI_GP0_RLAST,
    M_AXI_GP0_RVALID,
    M_AXI_GP0_WREADY,
    M_AXI_GP0_BID,
    M_AXI_GP0_RID,
    M_AXI_GP0_BRESP,
    M_AXI_GP0_RRESP,
    M_AXI_GP0_RDATA,
    M_AXI_GP1_ARVALID,
    M_AXI_GP1_AWVALID,
    M_AXI_GP1_BREADY,
    M_AXI_GP1_RREADY,
    M_AXI_GP1_WLAST,
    M_AXI_GP1_WVALID,
    M_AXI_GP1_ARID,
    M_AXI_GP1_AWID,
    M_AXI_GP1_WID,
    M_AXI_GP1_ARBURST,
    M_AXI_GP1_ARLOCK,
    M_AXI_GP1_ARSIZE,
    M_AXI_GP1_AWBURST,
    M_AXI_GP1_AWLOCK,
    M_AXI_GP1_AWSIZE,
    M_AXI_GP1_ARPROT,
    M_AXI_GP1_AWPROT,
    M_AXI_GP1_ARADDR,
    M_AXI_GP1_AWADDR,
    M_AXI_GP1_WDATA,
    M_AXI_GP1_ARCACHE,
    M_AXI_GP1_ARLEN,
    M_AXI_GP1_ARQOS,
    M_AXI_GP1_AWCACHE,
    M_AXI_GP1_AWLEN,
    M_AXI_GP1_AWQOS,
    M_AXI_GP1_WSTRB,
    M_AXI_GP1_ACLK,
    M_AXI_GP1_ARREADY,
    M_AXI_GP1_AWREADY,
    M_AXI_GP1_BVALID,
    M_AXI_GP1_RLAST,
    M_AXI_GP1_RVALID,
    M_AXI_GP1_WREADY,
    M_AXI_GP1_BID,
    M_AXI_GP1_RID,
    M_AXI_GP1_BRESP,
    M_AXI_GP1_RRESP,
    M_AXI_GP1_RDATA,
    S_AXI_GP0_ARREADY,
    S_AXI_GP0_AWREADY,
    S_AXI_GP0_BVALID,
    S_AXI_GP0_RLAST,
    S_AXI_GP0_RVALID,
    S_AXI_GP0_WREADY,
    S_AXI_GP0_BRESP,
    S_AXI_GP0_RRESP,
    S_AXI_GP0_RDATA,
    S_AXI_GP0_BID,
    S_AXI_GP0_RID,
    S_AXI_GP0_ACLK,
    S_AXI_GP0_ARVALID,
    S_AXI_GP0_AWVALID,
    S_AXI_GP0_BREADY,
    S_AXI_GP0_RREADY,
    S_AXI_GP0_WLAST,
    S_AXI_GP0_WVALID,
    S_AXI_GP0_ARBURST,
    S_AXI_GP0_ARLOCK,
    S_AXI_GP0_ARSIZE,
    S_AXI_GP0_AWBURST,
    S_AXI_GP0_AWLOCK,
    S_AXI_GP0_AWSIZE,
    S_AXI_GP0_ARPROT,
    S_AXI_GP0_AWPROT,
    S_AXI_GP0_ARADDR,
    S_AXI_GP0_AWADDR,
    S_AXI_GP0_WDATA,
    S_AXI_GP0_ARCACHE,
    S_AXI_GP0_ARLEN,
    S_AXI_GP0_ARQOS,
    S_AXI_GP0_AWCACHE,
    S_AXI_GP0_AWLEN,
    S_AXI_GP0_AWQOS,
    S_AXI_GP0_WSTRB,
    S_AXI_GP0_ARID,
    S_AXI_GP0_AWID,
    S_AXI_GP0_WID,
    S_AXI_GP1_ARREADY,
    S_AXI_GP1_AWREADY,
    S_AXI_GP1_BVALID,
    S_AXI_GP1_RLAST,
    S_AXI_GP1_RVALID,
    S_AXI_GP1_WREADY,
    S_AXI_GP1_BRESP,
    S_AXI_GP1_RRESP,
    S_AXI_GP1_RDATA,
    S_AXI_GP1_BID,
    S_AXI_GP1_RID,
    S_AXI_GP1_ACLK,
    S_AXI_GP1_ARVALID,
    S_AXI_GP1_AWVALID,
    S_AXI_GP1_BREADY,
    S_AXI_GP1_RREADY,
    S_AXI_GP1_WLAST,
    S_AXI_GP1_WVALID,
    S_AXI_GP1_ARBURST,
    S_AXI_GP1_ARLOCK,
    S_AXI_GP1_ARSIZE,
    S_AXI_GP1_AWBURST,
    S_AXI_GP1_AWLOCK,
    S_AXI_GP1_AWSIZE,
    S_AXI_GP1_ARPROT,
    S_AXI_GP1_AWPROT,
    S_AXI_GP1_ARADDR,
    S_AXI_GP1_AWADDR,
    S_AXI_GP1_WDATA,
    S_AXI_GP1_ARCACHE,
    S_AXI_GP1_ARLEN,
    S_AXI_GP1_ARQOS,
    S_AXI_GP1_AWCACHE,
    S_AXI_GP1_AWLEN,
    S_AXI_GP1_AWQOS,
    S_AXI_GP1_WSTRB,
    S_AXI_GP1_ARID,
    S_AXI_GP1_AWID,
    S_AXI_GP1_WID,
    S_AXI_ACP_AWREADY,
    S_AXI_ACP_ARREADY,
    S_AXI_ACP_BVALID,
    S_AXI_ACP_RLAST,
    S_AXI_ACP_RVALID,
    S_AXI_ACP_WREADY,
    S_AXI_ACP_BRESP,
    S_AXI_ACP_RRESP,
    S_AXI_ACP_BID,
    S_AXI_ACP_RID,
    S_AXI_ACP_RDATA,
    S_AXI_ACP_ACLK,
    S_AXI_ACP_ARVALID,
    S_AXI_ACP_AWVALID,
    S_AXI_ACP_BREADY,
    S_AXI_ACP_RREADY,
    S_AXI_ACP_WLAST,
    S_AXI_ACP_WVALID,
    S_AXI_ACP_ARID,
    S_AXI_ACP_ARPROT,
    S_AXI_ACP_AWID,
    S_AXI_ACP_AWPROT,
    S_AXI_ACP_WID,
    S_AXI_ACP_ARADDR,
    S_AXI_ACP_AWADDR,
    S_AXI_ACP_ARCACHE,
    S_AXI_ACP_ARLEN,
    S_AXI_ACP_ARQOS,
    S_AXI_ACP_AWCACHE,
    S_AXI_ACP_AWLEN,
    S_AXI_ACP_AWQOS,
    S_AXI_ACP_ARBURST,
    S_AXI_ACP_ARLOCK,
    S_AXI_ACP_ARSIZE,
    S_AXI_ACP_AWBURST,
    S_AXI_ACP_AWLOCK,
    S_AXI_ACP_AWSIZE,
    S_AXI_ACP_ARUSER,
    S_AXI_ACP_AWUSER,
    S_AXI_ACP_WDATA,
    S_AXI_ACP_WSTRB,
    S_AXI_HP0_ARREADY,
    S_AXI_HP0_AWREADY,
    S_AXI_HP0_BVALID,
    S_AXI_HP0_RLAST,
    S_AXI_HP0_RVALID,
    S_AXI_HP0_WREADY,
    S_AXI_HP0_BRESP,
    S_AXI_HP0_RRESP,
    S_AXI_HP0_BID,
    S_AXI_HP0_RID,
    S_AXI_HP0_RDATA,
    S_AXI_HP0_RCOUNT,
    S_AXI_HP0_WCOUNT,
    S_AXI_HP0_RACOUNT,
    S_AXI_HP0_WACOUNT,
    S_AXI_HP0_ACLK,
    S_AXI_HP0_ARVALID,
    S_AXI_HP0_AWVALID,
    S_AXI_HP0_BREADY,
    S_AXI_HP0_RDISSUECAP1_EN,
    S_AXI_HP0_RREADY,
    S_AXI_HP0_WLAST,
    S_AXI_HP0_WRISSUECAP1_EN,
    S_AXI_HP0_WVALID,
    S_AXI_HP0_ARBURST,
    S_AXI_HP0_ARLOCK,
    S_AXI_HP0_ARSIZE,
    S_AXI_HP0_AWBURST,
    S_AXI_HP0_AWLOCK,
    S_AXI_HP0_AWSIZE,
    S_AXI_HP0_ARPROT,
    S_AXI_HP0_AWPROT,
    S_AXI_HP0_ARADDR,
    S_AXI_HP0_AWADDR,
    S_AXI_HP0_ARCACHE,
    S_AXI_HP0_ARLEN,
    S_AXI_HP0_ARQOS,
    S_AXI_HP0_AWCACHE,
    S_AXI_HP0_AWLEN,
    S_AXI_HP0_AWQOS,
    S_AXI_HP0_ARID,
    S_AXI_HP0_AWID,
    S_AXI_HP0_WID,
    S_AXI_HP0_WDATA,
    S_AXI_HP0_WSTRB,
    S_AXI_HP1_ARREADY,
    S_AXI_HP1_AWREADY,
    S_AXI_HP1_BVALID,
    S_AXI_HP1_RLAST,
    S_AXI_HP1_RVALID,
    S_AXI_HP1_WREADY,
    S_AXI_HP1_BRESP,
    S_AXI_HP1_RRESP,
    S_AXI_HP1_BID,
    S_AXI_HP1_RID,
    S_AXI_HP1_RDATA,
    S_AXI_HP1_RCOUNT,
    S_AXI_HP1_WCOUNT,
    S_AXI_HP1_RACOUNT,
    S_AXI_HP1_WACOUNT,
    S_AXI_HP1_ACLK,
    S_AXI_HP1_ARVALID,
    S_AXI_HP1_AWVALID,
    S_AXI_HP1_BREADY,
    S_AXI_HP1_RDISSUECAP1_EN,
    S_AXI_HP1_RREADY,
    S_AXI_HP1_WLAST,
    S_AXI_HP1_WRISSUECAP1_EN,
    S_AXI_HP1_WVALID,
    S_AXI_HP1_ARBURST,
    S_AXI_HP1_ARLOCK,
    S_AXI_HP1_ARSIZE,
    S_AXI_HP1_AWBURST,
    S_AXI_HP1_AWLOCK,
    S_AXI_HP1_AWSIZE,
    S_AXI_HP1_ARPROT,
    S_AXI_HP1_AWPROT,
    S_AXI_HP1_ARADDR,
    S_AXI_HP1_AWADDR,
    S_AXI_HP1_ARCACHE,
    S_AXI_HP1_ARLEN,
    S_AXI_HP1_ARQOS,
    S_AXI_HP1_AWCACHE,
    S_AXI_HP1_AWLEN,
    S_AXI_HP1_AWQOS,
    S_AXI_HP1_ARID,
    S_AXI_HP1_AWID,
    S_AXI_HP1_WID,
    S_AXI_HP1_WDATA,
    S_AXI_HP1_WSTRB,
    S_AXI_HP2_ARREADY,
    S_AXI_HP2_AWREADY,
    S_AXI_HP2_BVALID,
    S_AXI_HP2_RLAST,
    S_AXI_HP2_RVALID,
    S_AXI_HP2_WREADY,
    S_AXI_HP2_BRESP,
    S_AXI_HP2_RRESP,
    S_AXI_HP2_BID,
    S_AXI_HP2_RID,
    S_AXI_HP2_RDATA,
    S_AXI_HP2_RCOUNT,
    S_AXI_HP2_WCOUNT,
    S_AXI_HP2_RACOUNT,
    S_AXI_HP2_WACOUNT,
    S_AXI_HP2_ACLK,
    S_AXI_HP2_ARVALID,
    S_AXI_HP2_AWVALID,
    S_AXI_HP2_BREADY,
    S_AXI_HP2_RDISSUECAP1_EN,
    S_AXI_HP2_RREADY,
    S_AXI_HP2_WLAST,
    S_AXI_HP2_WRISSUECAP1_EN,
    S_AXI_HP2_WVALID,
    S_AXI_HP2_ARBURST,
    S_AXI_HP2_ARLOCK,
    S_AXI_HP2_ARSIZE,
    S_AXI_HP2_AWBURST,
    S_AXI_HP2_AWLOCK,
    S_AXI_HP2_AWSIZE,
    S_AXI_HP2_ARPROT,
    S_AXI_HP2_AWPROT,
    S_AXI_HP2_ARADDR,
    S_AXI_HP2_AWADDR,
    S_AXI_HP2_ARCACHE,
    S_AXI_HP2_ARLEN,
    S_AXI_HP2_ARQOS,
    S_AXI_HP2_AWCACHE,
    S_AXI_HP2_AWLEN,
    S_AXI_HP2_AWQOS,
    S_AXI_HP2_ARID,
    S_AXI_HP2_AWID,
    S_AXI_HP2_WID,
    S_AXI_HP2_WDATA,
    S_AXI_HP2_WSTRB,
    S_AXI_HP3_ARREADY,
    S_AXI_HP3_AWREADY,
    S_AXI_HP3_BVALID,
    S_AXI_HP3_RLAST,
    S_AXI_HP3_RVALID,
    S_AXI_HP3_WREADY,
    S_AXI_HP3_BRESP,
    S_AXI_HP3_RRESP,
    S_AXI_HP3_BID,
    S_AXI_HP3_RID,
    S_AXI_HP3_RDATA,
    S_AXI_HP3_RCOUNT,
    S_AXI_HP3_WCOUNT,
    S_AXI_HP3_RACOUNT,
    S_AXI_HP3_WACOUNT,
    S_AXI_HP3_ACLK,
    S_AXI_HP3_ARVALID,
    S_AXI_HP3_AWVALID,
    S_AXI_HP3_BREADY,
    S_AXI_HP3_RDISSUECAP1_EN,
    S_AXI_HP3_RREADY,
    S_AXI_HP3_WLAST,
    S_AXI_HP3_WRISSUECAP1_EN,
    S_AXI_HP3_WVALID,
    S_AXI_HP3_ARBURST,
    S_AXI_HP3_ARLOCK,
    S_AXI_HP3_ARSIZE,
    S_AXI_HP3_AWBURST,
    S_AXI_HP3_AWLOCK,
    S_AXI_HP3_AWSIZE,
    S_AXI_HP3_ARPROT,
    S_AXI_HP3_AWPROT,
    S_AXI_HP3_ARADDR,
    S_AXI_HP3_AWADDR,
    S_AXI_HP3_ARCACHE,
    S_AXI_HP3_ARLEN,
    S_AXI_HP3_ARQOS,
    S_AXI_HP3_AWCACHE,
    S_AXI_HP3_AWLEN,
    S_AXI_HP3_AWQOS,
    S_AXI_HP3_ARID,
    S_AXI_HP3_AWID,
    S_AXI_HP3_WID,
    S_AXI_HP3_WDATA,
    S_AXI_HP3_WSTRB,
    DMA0_DATYPE,
    DMA0_DAVALID,
    DMA0_DRREADY,
    DMA0_ACLK,
    DMA0_DAREADY,
    DMA0_DRLAST,
    DMA0_DRVALID,
    DMA0_DRTYPE,
    DMA1_DATYPE,
    DMA1_DAVALID,
    DMA1_DRREADY,
    DMA1_ACLK,
    DMA1_DAREADY,
    DMA1_DRLAST,
    DMA1_DRVALID,
    DMA1_DRTYPE,
    DMA2_DATYPE,
    DMA2_DAVALID,
    DMA2_DRREADY,
    DMA2_ACLK,
    DMA2_DAREADY,
    DMA2_DRLAST,
    DMA2_DRVALID,
    DMA3_DRVALID,
    DMA3_DATYPE,
    DMA3_DAVALID,
    DMA3_DRREADY,
    DMA3_ACLK,
    DMA3_DAREADY,
    DMA3_DRLAST,
    DMA2_DRTYPE,
    DMA3_DRTYPE,
    FTMD_TRACEIN_DATA,
    FTMD_TRACEIN_VALID,
    FTMD_TRACEIN_CLK,
    FTMD_TRACEIN_ATID,
    FTMT_F2P_TRIG,
    FTMT_F2P_TRIGACK,
    FTMT_F2P_DEBUG,
    FTMT_P2F_TRIGACK,
    FTMT_P2F_TRIG,
    FTMT_P2F_DEBUG,
    FCLK_CLK3,
    FCLK_CLK2,
    FCLK_CLK1,
    FCLK_CLK0,
    FCLK_CLKTRIG3_N,
    FCLK_CLKTRIG2_N,
    FCLK_CLKTRIG1_N,
    FCLK_CLKTRIG0_N,
    FCLK_RESET3_N,
    FCLK_RESET2_N,
    FCLK_RESET1_N,
    FCLK_RESET0_N,
    FPGA_IDLE_N,
    DDR_ARB,
    IRQ_F2P,
    Core0_nFIQ,
    Core0_nIRQ,
    Core1_nFIQ,
    Core1_nIRQ,
    EVENT_EVENTO,
    EVENT_STANDBYWFE,
    EVENT_STANDBYWFI,
    EVENT_EVENTI,
    MIO,
    DDR_Clk,
    DDR_Clk_n,
    DDR_CKE,
    DDR_CS_n,
    DDR_RAS_n,
    DDR_CAS_n,
    DDR_WEB,
    DDR_BankAddr,
    DDR_Addr,
    DDR_ODT,
    DDR_DRSTB,
    DDR_DQ,
    DDR_DM,
    DDR_DQS,
    DDR_DQS_n,
    DDR_VRN,
    DDR_VRP,
    PS_SRSTB,
    PS_CLK,
    PS_PORB,
    IRQ_P2F_DMAC_ABORT,
    IRQ_P2F_DMAC0,
    IRQ_P2F_DMAC1,
    IRQ_P2F_DMAC2,
    IRQ_P2F_DMAC3,
    IRQ_P2F_DMAC4,
    IRQ_P2F_DMAC5,
    IRQ_P2F_DMAC6,
    IRQ_P2F_DMAC7,
    IRQ_P2F_SMC,
    IRQ_P2F_QSPI,
    IRQ_P2F_CTI,
    IRQ_P2F_GPIO,
    IRQ_P2F_USB0,
    IRQ_P2F_ENET0,
    IRQ_P2F_ENET_WAKE0,
    IRQ_P2F_SDIO0,
    IRQ_P2F_I2C0,
    IRQ_P2F_SPI0,
    IRQ_P2F_UART0,
    IRQ_P2F_CAN0,
    IRQ_P2F_USB1,
    IRQ_P2F_ENET1,
    IRQ_P2F_ENET_WAKE1,
    IRQ_P2F_SDIO1,
    IRQ_P2F_I2C1,
    IRQ_P2F_SPI1,
    IRQ_P2F_UART1,
    IRQ_P2F_CAN1
  );


  /* parameters for gen_clk */
  parameter C_FCLK_CLK0_FREQ = 50;
  parameter C_FCLK_CLK1_FREQ = 50;
  parameter C_FCLK_CLK3_FREQ = 50;
  parameter C_FCLK_CLK2_FREQ = 50;

  parameter C_HIGH_OCM_EN    = 0;


  /* parameters for HP ports */
  parameter C_USE_S_AXI_HP0 = 0;
  parameter C_USE_S_AXI_HP1 = 0;
  parameter C_USE_S_AXI_HP2 = 0;
  parameter C_USE_S_AXI_HP3 = 0;

  parameter C_S_AXI_HP0_DATA_WIDTH = 32;
  parameter C_S_AXI_HP1_DATA_WIDTH = 32;
  parameter C_S_AXI_HP2_DATA_WIDTH = 32;
  parameter C_S_AXI_HP3_DATA_WIDTH = 32;
  
  parameter C_M_AXI_GP0_THREAD_ID_WIDTH = 12;
  parameter C_M_AXI_GP1_THREAD_ID_WIDTH = 12; 
  parameter C_M_AXI_GP0_ENABLE_STATIC_REMAP = 0;
  parameter C_M_AXI_GP1_ENABLE_STATIC_REMAP = 0; 
  
/* Do we need these 
  parameter C_S_AXI_HP0_ENABLE_HIGHOCM = 0;
  parameter C_S_AXI_HP1_ENABLE_HIGHOCM = 0;
  parameter C_S_AXI_HP2_ENABLE_HIGHOCM = 0;
  parameter C_S_AXI_HP3_ENABLE_HIGHOCM = 0; */

  parameter C_S_AXI_HP0_BASEADDR = 32'h0000_0000;
  parameter C_S_AXI_HP1_BASEADDR = 32'h0000_0000;
  parameter C_S_AXI_HP2_BASEADDR = 32'h0000_0000;
  parameter C_S_AXI_HP3_BASEADDR = 32'h0000_0000;
  
  parameter C_S_AXI_HP0_HIGHADDR = 32'hFFFF_FFFF;
  parameter C_S_AXI_HP1_HIGHADDR = 32'hFFFF_FFFF;
  parameter C_S_AXI_HP2_HIGHADDR = 32'hFFFF_FFFF;
  parameter C_S_AXI_HP3_HIGHADDR = 32'hFFFF_FFFF;
 
  /* parameters for GP and ACP ports */
  parameter C_USE_M_AXI_GP0 = 0;
  parameter C_USE_M_AXI_GP1 = 0;
  parameter C_USE_S_AXI_GP0 = 1;
  parameter C_USE_S_AXI_GP1 = 1;
  
  /* Do we need this?
  parameter C_M_AXI_GP0_ENABLE_HIGHOCM = 0;
  parameter C_M_AXI_GP1_ENABLE_HIGHOCM = 0;
  parameter C_S_AXI_GP0_ENABLE_HIGHOCM = 0;
  parameter C_S_AXI_GP1_ENABLE_HIGHOCM = 0;
  
  parameter C_S_AXI_ACP_ENABLE_HIGHOCM = 0;*/

  parameter C_S_AXI_GP0_BASEADDR = 32'h0000_0000;
  parameter C_S_AXI_GP1_BASEADDR = 32'h0000_0000;
  
  parameter C_S_AXI_GP0_HIGHADDR = 32'hFFFF_FFFF;
  parameter C_S_AXI_GP1_HIGHADDR = 32'hFFFF_FFFF;
  
  parameter C_USE_S_AXI_ACP = 1;
  parameter C_S_AXI_ACP_BASEADDR = 32'h0000_0000;
  parameter C_S_AXI_ACP_HIGHADDR = 32'hFFFF_FFFF;
 
  `include "processing_system7_bfm_v2_0_5_local_params.v"

  output CAN0_PHY_TX;
  input CAN0_PHY_RX;
  output CAN1_PHY_TX;
  input CAN1_PHY_RX;
  output ENET0_GMII_TX_EN;
  output ENET0_GMII_TX_ER;
  output ENET0_MDIO_MDC;
  output ENET0_MDIO_O;
  output ENET0_MDIO_T;
  output ENET0_PTP_DELAY_REQ_RX;
  output ENET0_PTP_DELAY_REQ_TX;
  output ENET0_PTP_PDELAY_REQ_RX;
  output ENET0_PTP_PDELAY_REQ_TX;
  output ENET0_PTP_PDELAY_RESP_RX;
  output ENET0_PTP_PDELAY_RESP_TX;
  output ENET0_PTP_SYNC_FRAME_RX;
  output ENET0_PTP_SYNC_FRAME_TX;
  output ENET0_SOF_RX;
  output ENET0_SOF_TX;
  output [7:0] ENET0_GMII_TXD;
  input ENET0_GMII_COL;
  input ENET0_GMII_CRS;
  input ENET0_EXT_INTIN;
  input ENET0_GMII_RX_CLK;
  input ENET0_GMII_RX_DV;
  input ENET0_GMII_RX_ER;
  input ENET0_GMII_TX_CLK;
  input ENET0_MDIO_I;
  input [7:0] ENET0_GMII_RXD;
  output ENET1_GMII_TX_EN;
  output ENET1_GMII_TX_ER;
  output ENET1_MDIO_MDC;
  output ENET1_MDIO_O;
  output ENET1_MDIO_T;
  output ENET1_PTP_DELAY_REQ_RX;
  output ENET1_PTP_DELAY_REQ_TX;
  output ENET1_PTP_PDELAY_REQ_RX;
  output ENET1_PTP_PDELAY_REQ_TX;
  output ENET1_PTP_PDELAY_RESP_RX;
  output ENET1_PTP_PDELAY_RESP_TX;
  output ENET1_PTP_SYNC_FRAME_RX;
  output ENET1_PTP_SYNC_FRAME_TX;
  output ENET1_SOF_RX;
  output ENET1_SOF_TX;
  output [7:0] ENET1_GMII_TXD;
  input ENET1_GMII_COL;
  input ENET1_GMII_CRS;
  input ENET1_EXT_INTIN;
  input ENET1_GMII_RX_CLK;
  input ENET1_GMII_RX_DV;
  input ENET1_GMII_RX_ER;
  input ENET1_GMII_TX_CLK;
  input ENET1_MDIO_I;
  input [7:0] ENET1_GMII_RXD;
  input [63:0] GPIO_I;
  output [63:0] GPIO_O;
  output [63:0] GPIO_T;
  input I2C0_SDA_I;
  output I2C0_SDA_O;
  output I2C0_SDA_T;
  input I2C0_SCL_I;
  output I2C0_SCL_O;
  output I2C0_SCL_T;
  input I2C1_SDA_I;
  output I2C1_SDA_O;
  output I2C1_SDA_T;
  input I2C1_SCL_I;
  output I2C1_SCL_O;
  output I2C1_SCL_T;
  input PJTAG_TCK;
  input PJTAG_TMS;
  input PJTAG_TD_I;
  output PJTAG_TD_T;
  output PJTAG_TD_O;
  output SDIO0_CLK;
  input SDIO0_CLK_FB;
  output SDIO0_CMD_O;
  input SDIO0_CMD_I;
  output SDIO0_CMD_T;
  input [3:0] SDIO0_DATA_I;
  output [3:0] SDIO0_DATA_O;
  output [3:0] SDIO0_DATA_T;
  output SDIO0_LED;
  input SDIO0_CDN;
  input SDIO0_WP;
  output SDIO0_BUSPOW;
  output [2:0] SDIO0_BUSVOLT;
  output SDIO1_CLK;
  input SDIO1_CLK_FB;
  output SDIO1_CMD_O;
  input SDIO1_CMD_I;
  output SDIO1_CMD_T;
  input [3:0] SDIO1_DATA_I;
  output [3:0] SDIO1_DATA_O;
  output [3:0] SDIO1_DATA_T;
  output SDIO1_LED;
  input SDIO1_CDN;
  input SDIO1_WP;
  output SDIO1_BUSPOW;
  output [2:0] SDIO1_BUSVOLT;
  input SPI0_SCLK_I;
  output SPI0_SCLK_O;
  output SPI0_SCLK_T;
  input SPI0_MOSI_I;
  output SPI0_MOSI_O;
  output SPI0_MOSI_T;
  input SPI0_MISO_I;
  output SPI0_MISO_O;
  output SPI0_MISO_T;
  input SPI0_SS_I;
  output SPI0_SS_O;
  output SPI0_SS1_O;
  output SPI0_SS2_O;
  output SPI0_SS_T;
  input SPI1_SCLK_I;
  output SPI1_SCLK_O;
  output SPI1_SCLK_T;
  input SPI1_MOSI_I;
  output SPI1_MOSI_O;
  output SPI1_MOSI_T;
  input SPI1_MISO_I;
  output SPI1_MISO_O;
  output SPI1_MISO_T;
  input SPI1_SS_I;
  output SPI1_SS_O;
  output SPI1_SS1_O;
  output SPI1_SS2_O;
  output SPI1_SS_T;
  output UART0_DTRN;
  output UART0_RTSN;
  output UART0_TX;
  input UART0_CTSN;
  input UART0_DCDN;
  input UART0_DSRN;
  input UART0_RIN;
  input UART0_RX;
  output UART1_DTRN;
  output UART1_RTSN;
  output UART1_TX;
  input UART1_CTSN;
  input UART1_DCDN;
  input UART1_DSRN;
  input UART1_RIN;
  input UART1_RX;
  output TTC0_WAVE0_OUT;
  output TTC0_WAVE1_OUT;
  output TTC0_WAVE2_OUT;
  input TTC0_CLK0_IN;
  input TTC0_CLK1_IN;
  input TTC0_CLK2_IN;
  output TTC1_WAVE0_OUT;
  output TTC1_WAVE1_OUT;
  output TTC1_WAVE2_OUT;
  input TTC1_CLK0_IN;
  input TTC1_CLK1_IN;
  input TTC1_CLK2_IN;
  input WDT_CLK_IN;
  output WDT_RST_OUT;
  input TRACE_CLK;
  output TRACE_CTL;
  output [31:0] TRACE_DATA;
  output [1:0] USB0_PORT_INDCTL;
  output [1:0] USB1_PORT_INDCTL;
  output USB0_VBUS_PWRSELECT;
  output USB1_VBUS_PWRSELECT;
  input USB0_VBUS_PWRFAULT;
  input USB1_VBUS_PWRFAULT;
  input SRAM_INTIN;
  output M_AXI_GP0_ARVALID;
  output M_AXI_GP0_AWVALID;
  output M_AXI_GP0_BREADY;
  output M_AXI_GP0_RREADY;
  output M_AXI_GP0_WLAST;
  output M_AXI_GP0_WVALID;
  output [C_M_AXI_GP0_THREAD_ID_WIDTH-1:0] M_AXI_GP0_ARID;
  output [C_M_AXI_GP0_THREAD_ID_WIDTH-1:0] M_AXI_GP0_AWID;
  output [C_M_AXI_GP0_THREAD_ID_WIDTH-1:0] M_AXI_GP0_WID;
  output [1:0] M_AXI_GP0_ARBURST;
  output [1:0] M_AXI_GP0_ARLOCK;
  output [2:0] M_AXI_GP0_ARSIZE;
  output [1:0] M_AXI_GP0_AWBURST;
  output [1:0] M_AXI_GP0_AWLOCK;
  output [2:0] M_AXI_GP0_AWSIZE;
  output [2:0] M_AXI_GP0_ARPROT;
  output [2:0] M_AXI_GP0_AWPROT;
  output [31:0] M_AXI_GP0_ARADDR;
  output [31:0] M_AXI_GP0_AWADDR;
  output [31:0] M_AXI_GP0_WDATA;
  output [3:0] M_AXI_GP0_ARCACHE;
  output [3:0] M_AXI_GP0_ARLEN;
  output [3:0] M_AXI_GP0_ARQOS;
  output [3:0] M_AXI_GP0_AWCACHE;
  output [3:0] M_AXI_GP0_AWLEN;
  output [3:0] M_AXI_GP0_AWQOS;
  output [3:0] M_AXI_GP0_WSTRB;
  input M_AXI_GP0_ACLK;
  input M_AXI_GP0_ARREADY;
  input M_AXI_GP0_AWREADY;
  input M_AXI_GP0_BVALID;
  input M_AXI_GP0_RLAST;
  input M_AXI_GP0_RVALID;
  input M_AXI_GP0_WREADY;
  input [C_M_AXI_GP0_THREAD_ID_WIDTH-1:0] M_AXI_GP0_BID;
  input [C_M_AXI_GP0_THREAD_ID_WIDTH-1:0] M_AXI_GP0_RID;
  input [1:0] M_AXI_GP0_BRESP;
  input [1:0] M_AXI_GP0_RRESP;
  input [31:0] M_AXI_GP0_RDATA;
  output M_AXI_GP1_ARVALID;
  output M_AXI_GP1_AWVALID;
  output M_AXI_GP1_BREADY;
  output M_AXI_GP1_RREADY;
  output M_AXI_GP1_WLAST;
  output M_AXI_GP1_WVALID;
  output [C_M_AXI_GP1_THREAD_ID_WIDTH-1:0] M_AXI_GP1_ARID;
  output [C_M_AXI_GP1_THREAD_ID_WIDTH-1:0] M_AXI_GP1_AWID;
  output [C_M_AXI_GP1_THREAD_ID_WIDTH-1:0] M_AXI_GP1_WID;
  output [1:0] M_AXI_GP1_ARBURST;
  output [1:0] M_AXI_GP1_ARLOCK;
  output [2:0] M_AXI_GP1_ARSIZE;
  output [1:0] M_AXI_GP1_AWBURST;
  output [1:0] M_AXI_GP1_AWLOCK;
  output [2:0] M_AXI_GP1_AWSIZE;
  output [2:0] M_AXI_GP1_ARPROT;
  output [2:0] M_AXI_GP1_AWPROT;
  output [31:0] M_AXI_GP1_ARADDR;
  output [31:0] M_AXI_GP1_AWADDR;
  output [31:0] M_AXI_GP1_WDATA;
  output [3:0] M_AXI_GP1_ARCACHE;
  output [3:0] M_AXI_GP1_ARLEN;
  output [3:0] M_AXI_GP1_ARQOS;
  output [3:0] M_AXI_GP1_AWCACHE;
  output [3:0] M_AXI_GP1_AWLEN;
  output [3:0] M_AXI_GP1_AWQOS;
  output [3:0] M_AXI_GP1_WSTRB;
  input M_AXI_GP1_ACLK;
  input M_AXI_GP1_ARREADY;
  input M_AXI_GP1_AWREADY;
  input M_AXI_GP1_BVALID;
  input M_AXI_GP1_RLAST;
  input M_AXI_GP1_RVALID;
  input M_AXI_GP1_WREADY;
  input [C_M_AXI_GP1_THREAD_ID_WIDTH-1:0] M_AXI_GP1_BID;
  input [C_M_AXI_GP1_THREAD_ID_WIDTH-1:0] M_AXI_GP1_RID;
  input [1:0] M_AXI_GP1_BRESP;
  input [1:0] M_AXI_GP1_RRESP;
  input [31:0] M_AXI_GP1_RDATA;
  output S_AXI_GP0_ARREADY;
  output S_AXI_GP0_AWREADY;
  output S_AXI_GP0_BVALID;
  output S_AXI_GP0_RLAST;
  output S_AXI_GP0_RVALID;
  output S_AXI_GP0_WREADY;
  output [1:0] S_AXI_GP0_BRESP;
  output [1:0] S_AXI_GP0_RRESP;
  output [31:0] S_AXI_GP0_RDATA;
  output [5:0] S_AXI_GP0_BID;
  output [5:0] S_AXI_GP0_RID;
  input S_AXI_GP0_ACLK;
  input S_AXI_GP0_ARVALID;
  input S_AXI_GP0_AWVALID;
  input S_AXI_GP0_BREADY;
  input S_AXI_GP0_RREADY;
  input S_AXI_GP0_WLAST;
  input S_AXI_GP0_WVALID;
  input [1:0] S_AXI_GP0_ARBURST;
  input [1:0] S_AXI_GP0_ARLOCK;
  input [2:0] S_AXI_GP0_ARSIZE;
  input [1:0] S_AXI_GP0_AWBURST;
  input [1:0] S_AXI_GP0_AWLOCK;
  input [2:0] S_AXI_GP0_AWSIZE;
  input [2:0] S_AXI_GP0_ARPROT;
  input [2:0] S_AXI_GP0_AWPROT;
  input [31:0] S_AXI_GP0_ARADDR;
  input [31:0] S_AXI_GP0_AWADDR;
  input [31:0] S_AXI_GP0_WDATA;
  input [3:0] S_AXI_GP0_ARCACHE;
  input [3:0] S_AXI_GP0_ARLEN;
  input [3:0] S_AXI_GP0_ARQOS;
  input [3:0] S_AXI_GP0_AWCACHE;
  input [3:0] S_AXI_GP0_AWLEN;
  input [3:0] S_AXI_GP0_AWQOS;
  input [3:0] S_AXI_GP0_WSTRB;
  input [5:0] S_AXI_GP0_ARID;
  input [5:0] S_AXI_GP0_AWID;
  input [5:0] S_AXI_GP0_WID;
  output S_AXI_GP1_ARREADY;
  output S_AXI_GP1_AWREADY;
  output S_AXI_GP1_BVALID;
  output S_AXI_GP1_RLAST;
  output S_AXI_GP1_RVALID;
  output S_AXI_GP1_WREADY;
  output [1:0] S_AXI_GP1_BRESP;
  output [1:0] S_AXI_GP1_RRESP;
  output [31:0] S_AXI_GP1_RDATA;
  output [5:0] S_AXI_GP1_BID;
  output [5:0] S_AXI_GP1_RID;
  input S_AXI_GP1_ACLK;
  input S_AXI_GP1_ARVALID;
  input S_AXI_GP1_AWVALID;
  input S_AXI_GP1_BREADY;
  input S_AXI_GP1_RREADY;
  input S_AXI_GP1_WLAST;
  input S_AXI_GP1_WVALID;
  input [1:0] S_AXI_GP1_ARBURST;
  input [1:0] S_AXI_GP1_ARLOCK;
  input [2:0] S_AXI_GP1_ARSIZE;
  input [1:0] S_AXI_GP1_AWBURST;
  input [1:0] S_AXI_GP1_AWLOCK;
  input [2:0] S_AXI_GP1_AWSIZE;
  input [2:0] S_AXI_GP1_ARPROT;
  input [2:0] S_AXI_GP1_AWPROT;
  input [31:0] S_AXI_GP1_ARADDR;
  input [31:0] S_AXI_GP1_AWADDR;
  input [31:0] S_AXI_GP1_WDATA;
  input [3:0] S_AXI_GP1_ARCACHE;
  input [3:0] S_AXI_GP1_ARLEN;
  input [3:0] S_AXI_GP1_ARQOS;
  input [3:0] S_AXI_GP1_AWCACHE;
  input [3:0] S_AXI_GP1_AWLEN;
  input [3:0] S_AXI_GP1_AWQOS;
  input [3:0] S_AXI_GP1_WSTRB;
  input [5:0] S_AXI_GP1_ARID;
  input [5:0] S_AXI_GP1_AWID;
  input [5:0] S_AXI_GP1_WID;
  output S_AXI_ACP_AWREADY;
  output S_AXI_ACP_ARREADY;
  output S_AXI_ACP_BVALID;
  output S_AXI_ACP_RLAST;
  output S_AXI_ACP_RVALID;
  output S_AXI_ACP_WREADY;
  output [1:0] S_AXI_ACP_BRESP;
  output [1:0] S_AXI_ACP_RRESP;
  output [2:0] S_AXI_ACP_BID;
  output [2:0] S_AXI_ACP_RID;
  output [63:0] S_AXI_ACP_RDATA;
  input S_AXI_ACP_ACLK;
  input S_AXI_ACP_ARVALID;
  input S_AXI_ACP_AWVALID;
  input S_AXI_ACP_BREADY;
  input S_AXI_ACP_RREADY;
  input S_AXI_ACP_WLAST;
  input S_AXI_ACP_WVALID;
  input [2:0] S_AXI_ACP_ARID;
  input [2:0] S_AXI_ACP_ARPROT;
  input [2:0] S_AXI_ACP_AWID;
  input [2:0] S_AXI_ACP_AWPROT;
  input [2:0] S_AXI_ACP_WID;
  input [31:0] S_AXI_ACP_ARADDR;
  input [31:0] S_AXI_ACP_AWADDR;
  input [3:0] S_AXI_ACP_ARCACHE;
  input [3:0] S_AXI_ACP_ARLEN;
  input [3:0] S_AXI_ACP_ARQOS;
  input [3:0] S_AXI_ACP_AWCACHE;
  input [3:0] S_AXI_ACP_AWLEN;
  input [3:0] S_AXI_ACP_AWQOS;
  input [1:0] S_AXI_ACP_ARBURST;
  input [1:0] S_AXI_ACP_ARLOCK;
  input [2:0] S_AXI_ACP_ARSIZE;
  input [1:0] S_AXI_ACP_AWBURST;
  input [1:0] S_AXI_ACP_AWLOCK;
  input [2:0] S_AXI_ACP_AWSIZE;
  input [4:0] S_AXI_ACP_ARUSER;
  input [4:0] S_AXI_ACP_AWUSER;
  input [63:0] S_AXI_ACP_WDATA;
  input [7:0] S_AXI_ACP_WSTRB;
  output S_AXI_HP0_ARREADY;
  output S_AXI_HP0_AWREADY;
  output S_AXI_HP0_BVALID;
  output S_AXI_HP0_RLAST;
  output S_AXI_HP0_RVALID;
  output S_AXI_HP0_WREADY;
  output [1:0] S_AXI_HP0_BRESP;
  output [1:0] S_AXI_HP0_RRESP;
  output [5:0] S_AXI_HP0_BID;
  output [5:0] S_AXI_HP0_RID;
  output [C_S_AXI_HP0_DATA_WIDTH-1:0] S_AXI_HP0_RDATA;
  output [7:0] S_AXI_HP0_RCOUNT;
  output [7:0] S_AXI_HP0_WCOUNT;
  output [2:0] S_AXI_HP0_RACOUNT;
  output [5:0] S_AXI_HP0_WACOUNT;
  input S_AXI_HP0_ACLK;
  input S_AXI_HP0_ARVALID;
  input S_AXI_HP0_AWVALID;
  input S_AXI_HP0_BREADY;
  input S_AXI_HP0_RDISSUECAP1_EN;
  input S_AXI_HP0_RREADY;
  input S_AXI_HP0_WLAST;
  input S_AXI_HP0_WRISSUECAP1_EN;
  input S_AXI_HP0_WVALID;
  input [1:0] S_AXI_HP0_ARBURST;
  input [1:0] S_AXI_HP0_ARLOCK;
  input [2:0] S_AXI_HP0_ARSIZE;
  input [1:0] S_AXI_HP0_AWBURST;
  input [1:0] S_AXI_HP0_AWLOCK;
  input [2:0] S_AXI_HP0_AWSIZE;
  input [2:0] S_AXI_HP0_ARPROT;
  input [2:0] S_AXI_HP0_AWPROT;
  input [31:0] S_AXI_HP0_ARADDR;
  input [31:0] S_AXI_HP0_AWADDR;
  input [3:0] S_AXI_HP0_ARCACHE;
  input [3:0] S_AXI_HP0_ARLEN;
  input [3:0] S_AXI_HP0_ARQOS;
  input [3:0] S_AXI_HP0_AWCACHE;
  input [3:0] S_AXI_HP0_AWLEN;
  input [3:0] S_AXI_HP0_AWQOS;
  input [5:0] S_AXI_HP0_ARID;
  input [5:0] S_AXI_HP0_AWID;
  input [5:0] S_AXI_HP0_WID;
  input [C_S_AXI_HP0_DATA_WIDTH-1:0] S_AXI_HP0_WDATA;
  input [C_S_AXI_HP0_DATA_WIDTH/8-1:0] S_AXI_HP0_WSTRB;
  output S_AXI_HP1_ARREADY;
  output S_AXI_HP1_AWREADY;
  output S_AXI_HP1_BVALID;
  output S_AXI_HP1_RLAST;
  output S_AXI_HP1_RVALID;
  output S_AXI_HP1_WREADY;
  output [1:0] S_AXI_HP1_BRESP;
  output [1:0] S_AXI_HP1_RRESP;
  output [5:0] S_AXI_HP1_BID;
  output [5:0] S_AXI_HP1_RID;
  output [C_S_AXI_HP1_DATA_WIDTH-1:0] S_AXI_HP1_RDATA;
  output [7:0] S_AXI_HP1_RCOUNT;
  output [7:0] S_AXI_HP1_WCOUNT;
  output [2:0] S_AXI_HP1_RACOUNT;
  output [5:0] S_AXI_HP1_WACOUNT;
  input S_AXI_HP1_ACLK;
  input S_AXI_HP1_ARVALID;
  input S_AXI_HP1_AWVALID;
  input S_AXI_HP1_BREADY;
  input S_AXI_HP1_RDISSUECAP1_EN;
  input S_AXI_HP1_RREADY;
  input S_AXI_HP1_WLAST;
  input S_AXI_HP1_WRISSUECAP1_EN;
  input S_AXI_HP1_WVALID;
  input [1:0] S_AXI_HP1_ARBURST;
  input [1:0] S_AXI_HP1_ARLOCK;
  input [2:0] S_AXI_HP1_ARSIZE;
  input [1:0] S_AXI_HP1_AWBURST;
  input [1:0] S_AXI_HP1_AWLOCK;
  input [2:0] S_AXI_HP1_AWSIZE;
  input [2:0] S_AXI_HP1_ARPROT;
  input [2:0] S_AXI_HP1_AWPROT;
  input [31:0] S_AXI_HP1_ARADDR;
  input [31:0] S_AXI_HP1_AWADDR;
  input [3:0] S_AXI_HP1_ARCACHE;
  input [3:0] S_AXI_HP1_ARLEN;
  input [3:0] S_AXI_HP1_ARQOS;
  input [3:0] S_AXI_HP1_AWCACHE;
  input [3:0] S_AXI_HP1_AWLEN;
  input [3:0] S_AXI_HP1_AWQOS;
  input [5:0] S_AXI_HP1_ARID;
  input [5:0] S_AXI_HP1_AWID;
  input [5:0] S_AXI_HP1_WID;
  input [C_S_AXI_HP1_DATA_WIDTH-1:0] S_AXI_HP1_WDATA;
  input [C_S_AXI_HP1_DATA_WIDTH/8-1:0] S_AXI_HP1_WSTRB;
  output S_AXI_HP2_ARREADY;
  output S_AXI_HP2_AWREADY;
  output S_AXI_HP2_BVALID;
  output S_AXI_HP2_RLAST;
  output S_AXI_HP2_RVALID;
  output S_AXI_HP2_WREADY;
  output [1:0] S_AXI_HP2_BRESP;
  output [1:0] S_AXI_HP2_RRESP;
  output [5:0] S_AXI_HP2_BID;
  output [5:0] S_AXI_HP2_RID;
  output [C_S_AXI_HP2_DATA_WIDTH-1:0] S_AXI_HP2_RDATA;
  output [7:0] S_AXI_HP2_RCOUNT;
  output [7:0] S_AXI_HP2_WCOUNT;
  output [2:0] S_AXI_HP2_RACOUNT;
  output [5:0] S_AXI_HP2_WACOUNT;
  input S_AXI_HP2_ACLK;
  input S_AXI_HP2_ARVALID;
  input S_AXI_HP2_AWVALID;
  input S_AXI_HP2_BREADY;
  input S_AXI_HP2_RDISSUECAP1_EN;
  input S_AXI_HP2_RREADY;
  input S_AXI_HP2_WLAST;
  input S_AXI_HP2_WRISSUECAP1_EN;
  input S_AXI_HP2_WVALID;
  input [1:0] S_AXI_HP2_ARBURST;
  input [1:0] S_AXI_HP2_ARLOCK;
  input [2:0] S_AXI_HP2_ARSIZE;
  input [1:0] S_AXI_HP2_AWBURST;
  input [1:0] S_AXI_HP2_AWLOCK;
  input [2:0] S_AXI_HP2_AWSIZE;
  input [2:0] S_AXI_HP2_ARPROT;
  input [2:0] S_AXI_HP2_AWPROT;
  input [31:0] S_AXI_HP2_ARADDR;
  input [31:0] S_AXI_HP2_AWADDR;
  input [3:0] S_AXI_HP2_ARCACHE;
  input [3:0] S_AXI_HP2_ARLEN;
  input [3:0] S_AXI_HP2_ARQOS;
  input [3:0] S_AXI_HP2_AWCACHE;
  input [3:0] S_AXI_HP2_AWLEN;
  input [3:0] S_AXI_HP2_AWQOS;
  input [5:0] S_AXI_HP2_ARID;
  input [5:0] S_AXI_HP2_AWID;
  input [5:0] S_AXI_HP2_WID;
  input [C_S_AXI_HP2_DATA_WIDTH-1:0] S_AXI_HP2_WDATA;
  input [C_S_AXI_HP2_DATA_WIDTH/8-1:0] S_AXI_HP2_WSTRB;
  output S_AXI_HP3_ARREADY;
  output S_AXI_HP3_AWREADY;
  output S_AXI_HP3_BVALID;
  output S_AXI_HP3_RLAST;
  output S_AXI_HP3_RVALID;
  output S_AXI_HP3_WREADY;
  output [1:0] S_AXI_HP3_BRESP;
  output [1:0] S_AXI_HP3_RRESP;
  output [5:0] S_AXI_HP3_BID;
  output [5:0] S_AXI_HP3_RID;
  output [C_S_AXI_HP3_DATA_WIDTH-1:0] S_AXI_HP3_RDATA;
  output [7:0] S_AXI_HP3_RCOUNT;
  output [7:0] S_AXI_HP3_WCOUNT;
  output [2:0] S_AXI_HP3_RACOUNT;
  output [5:0] S_AXI_HP3_WACOUNT;
  input S_AXI_HP3_ACLK;
  input S_AXI_HP3_ARVALID;
  input S_AXI_HP3_AWVALID;
  input S_AXI_HP3_BREADY;
  input S_AXI_HP3_RDISSUECAP1_EN;
  input S_AXI_HP3_RREADY;
  input S_AXI_HP3_WLAST;
  input S_AXI_HP3_WRISSUECAP1_EN;
  input S_AXI_HP3_WVALID;
  input [1:0] S_AXI_HP3_ARBURST;
  input [1:0] S_AXI_HP3_ARLOCK;
  input [2:0] S_AXI_HP3_ARSIZE;
  input [1:0] S_AXI_HP3_AWBURST;
  input [1:0] S_AXI_HP3_AWLOCK;
  input [2:0] S_AXI_HP3_AWSIZE;
  input [2:0] S_AXI_HP3_ARPROT;
  input [2:0] S_AXI_HP3_AWPROT;
  input [31:0] S_AXI_HP3_ARADDR;
  input [31:0] S_AXI_HP3_AWADDR;
  input [3:0] S_AXI_HP3_ARCACHE;
  input [3:0] S_AXI_HP3_ARLEN;
  input [3:0] S_AXI_HP3_ARQOS;
  input [3:0] S_AXI_HP3_AWCACHE;
  input [3:0] S_AXI_HP3_AWLEN;
  input [3:0] S_AXI_HP3_AWQOS;
  input [5:0] S_AXI_HP3_ARID;
  input [5:0] S_AXI_HP3_AWID;
  input [5:0] S_AXI_HP3_WID;
  input [C_S_AXI_HP3_DATA_WIDTH-1:0] S_AXI_HP3_WDATA;
  input [C_S_AXI_HP3_DATA_WIDTH/8-1:0] S_AXI_HP3_WSTRB;
  output [1:0] DMA0_DATYPE;
  output DMA0_DAVALID;
  output DMA0_DRREADY;
  input DMA0_ACLK;
  input DMA0_DAREADY;
  input DMA0_DRLAST;
  input DMA0_DRVALID;
  input [1:0] DMA0_DRTYPE;
  output [1:0] DMA1_DATYPE;
  output DMA1_DAVALID;
  output DMA1_DRREADY;
  input DMA1_ACLK;
  input DMA1_DAREADY;
  input DMA1_DRLAST;
  input DMA1_DRVALID;
  input [1:0] DMA1_DRTYPE;
  output [1:0] DMA2_DATYPE;
  output DMA2_DAVALID;
  output DMA2_DRREADY;
  input DMA2_ACLK;
  input DMA2_DAREADY;
  input DMA2_DRLAST;
  input DMA2_DRVALID;
  input DMA3_DRVALID;
  output [1:0] DMA3_DATYPE;
  output DMA3_DAVALID;
  output DMA3_DRREADY;
  input DMA3_ACLK;
  input DMA3_DAREADY;
  input DMA3_DRLAST;
  input [1:0] DMA2_DRTYPE;
  input [1:0] DMA3_DRTYPE;
  input [31:0] FTMD_TRACEIN_DATA;
  input FTMD_TRACEIN_VALID;
  input FTMD_TRACEIN_CLK;
  input [3:0] FTMD_TRACEIN_ATID;
  input [3:0] FTMT_F2P_TRIG;
  output [3:0] FTMT_F2P_TRIGACK;
  input [31:0] FTMT_F2P_DEBUG;
  input [3:0] FTMT_P2F_TRIGACK;
  output [3:0] FTMT_P2F_TRIG;
  output [31:0] FTMT_P2F_DEBUG;
  output FCLK_CLK3;
  output FCLK_CLK2;
  output FCLK_CLK1;
  output FCLK_CLK0;
  input FCLK_CLKTRIG3_N;
  input FCLK_CLKTRIG2_N;
  input FCLK_CLKTRIG1_N;
  input FCLK_CLKTRIG0_N;
  output FCLK_RESET3_N;
  output FCLK_RESET2_N;
  output FCLK_RESET1_N;
  output FCLK_RESET0_N;
  input FPGA_IDLE_N;
  input [3:0] DDR_ARB;
  input [irq_width-1:0] IRQ_F2P;
  input Core0_nFIQ;
  input Core0_nIRQ;
  input Core1_nFIQ;
  input Core1_nIRQ;
  output EVENT_EVENTO;
  output [1:0] EVENT_STANDBYWFE;
  output [1:0] EVENT_STANDBYWFI;
  input EVENT_EVENTI;
  inout [53:0] MIO;
  inout DDR_Clk;
  inout DDR_Clk_n;
  inout DDR_CKE;
  inout DDR_CS_n;
  inout DDR_RAS_n;
  inout DDR_CAS_n;
  output DDR_WEB;
  inout [2:0] DDR_BankAddr;
  inout [14:0] DDR_Addr;
  inout DDR_ODT;
  inout DDR_DRSTB;
  inout [31:0] DDR_DQ;
  inout [3:0] DDR_DM;
  inout [3:0] DDR_DQS;
  inout [3:0] DDR_DQS_n;
  inout DDR_VRN;
  inout DDR_VRP;
/* Reset Input & Clock Input */
  input PS_SRSTB;
  input PS_CLK;
  input PS_PORB;
  output IRQ_P2F_DMAC_ABORT;
  output IRQ_P2F_DMAC0;
  output IRQ_P2F_DMAC1;
  output IRQ_P2F_DMAC2;
  output IRQ_P2F_DMAC3;
  output IRQ_P2F_DMAC4;
  output IRQ_P2F_DMAC5;
  output IRQ_P2F_DMAC6;
  output IRQ_P2F_DMAC7;
  output IRQ_P2F_SMC;
  output IRQ_P2F_QSPI;
  output IRQ_P2F_CTI;
  output IRQ_P2F_GPIO;
  output IRQ_P2F_USB0;
  output IRQ_P2F_ENET0;
  output IRQ_P2F_ENET_WAKE0;
  output IRQ_P2F_SDIO0;
  output IRQ_P2F_I2C0;
  output IRQ_P2F_SPI0;
  output IRQ_P2F_UART0;
  output IRQ_P2F_CAN0;
  output IRQ_P2F_USB1;
  output IRQ_P2F_ENET1;
  output IRQ_P2F_ENET_WAKE1;
  output IRQ_P2F_SDIO1;
  output IRQ_P2F_I2C1;
  output IRQ_P2F_SPI1;
  output IRQ_P2F_UART1;
  output IRQ_P2F_CAN1;


  /* Internal wires/nets used for connectivity */
  wire net_rstn;
  wire net_sw_clk;
  wire net_ocm_clk;
  wire net_arbiter_clk;

  wire net_axi_mgp0_rstn;
  wire net_axi_mgp1_rstn;
  wire net_axi_gp0_rstn;
  wire net_axi_gp1_rstn;
  wire net_axi_hp0_rstn;
  wire net_axi_hp1_rstn;
  wire net_axi_hp2_rstn;
  wire net_axi_hp3_rstn;
  wire net_axi_acp_rstn;
  wire [4:0] net_axi_acp_awuser;
  wire [4:0] net_axi_acp_aruser;


  /* Dummy */
  assign net_axi_acp_awuser = S_AXI_ACP_AWUSER;
  assign net_axi_acp_aruser = S_AXI_ACP_ARUSER;

  /* Global variables */
  reg DEBUG_INFO = 1;
  reg STOP_ON_ERROR = 1;
  
  /* local variable acting as semaphore for wait_mem_update and wait_reg_update task */ 
  reg mem_update_key = 1; 
  reg reg_update_key_0 = 1; 
  reg reg_update_key_1 = 1; 
  
  /* assignments and semantic checks for unused ports */
  `include "processing_system7_bfm_v2_0_5_unused_ports.v"
 
  /* include api definition */
  `include "processing_system7_bfm_v2_0_5_apis.v"
 
  /* Reset Generator */
  processing_system7_bfm_v2_0_5_gen_reset gen_rst(.por_rst_n(PS_PORB),
                    .sys_rst_n(PS_SRSTB),
                    .rst_out_n(net_rstn),

                    .m_axi_gp0_clk(M_AXI_GP0_ACLK),
                    .m_axi_gp1_clk(M_AXI_GP1_ACLK),
                    .s_axi_gp0_clk(S_AXI_GP0_ACLK),
                    .s_axi_gp1_clk(S_AXI_GP1_ACLK),
                    .s_axi_hp0_clk(S_AXI_HP0_ACLK),
                    .s_axi_hp1_clk(S_AXI_HP1_ACLK),
                    .s_axi_hp2_clk(S_AXI_HP2_ACLK),
                    .s_axi_hp3_clk(S_AXI_HP3_ACLK),
                    .s_axi_acp_clk(S_AXI_ACP_ACLK),

                    .m_axi_gp0_rstn(net_axi_mgp0_rstn),
                    .m_axi_gp1_rstn(net_axi_mgp1_rstn),
                    .s_axi_gp0_rstn(net_axi_gp0_rstn),
                    .s_axi_gp1_rstn(net_axi_gp1_rstn),
                    .s_axi_hp0_rstn(net_axi_hp0_rstn),
                    .s_axi_hp1_rstn(net_axi_hp1_rstn),
                    .s_axi_hp2_rstn(net_axi_hp2_rstn),
                    .s_axi_hp3_rstn(net_axi_hp3_rstn),
                    .s_axi_acp_rstn(net_axi_acp_rstn),

                    .fclk_reset3_n(FCLK_RESET3_N),
                    .fclk_reset2_n(FCLK_RESET2_N),
                    .fclk_reset1_n(FCLK_RESET1_N),
                    .fclk_reset0_n(FCLK_RESET0_N),

                    .fpga_acp_reset_n(),   ////S_AXI_ACP_ARESETN), (These are removed from Zynq IP)
                    .fpga_gp_m0_reset_n(), ////M_AXI_GP0_ARESETN),
                    .fpga_gp_m1_reset_n(), ////M_AXI_GP1_ARESETN),
                    .fpga_gp_s0_reset_n(), ////S_AXI_GP0_ARESETN),
                    .fpga_gp_s1_reset_n(), ////S_AXI_GP1_ARESETN),
                    .fpga_hp_s0_reset_n(), ////S_AXI_HP0_ARESETN),
                    .fpga_hp_s1_reset_n(), ////S_AXI_HP1_ARESETN),
                    .fpga_hp_s2_reset_n(), ////S_AXI_HP2_ARESETN),
                    .fpga_hp_s3_reset_n()  ////S_AXI_HP3_ARESETN)
                   );

  /* Clock Generator */
  processing_system7_bfm_v2_0_5_gen_clock #(C_FCLK_CLK3_FREQ, C_FCLK_CLK2_FREQ, C_FCLK_CLK1_FREQ, C_FCLK_CLK0_FREQ)
            gen_clk(.ps_clk(PS_CLK),
                    .sw_clk(net_sw_clk),

                    .fclk_clk3(FCLK_CLK3),
                    .fclk_clk2(FCLK_CLK2),
                    .fclk_clk1(FCLK_CLK1),
                    .fclk_clk0(FCLK_CLK0)
                    );

  wire net_wr_ack_ocm_gp0, net_wr_ack_ddr_gp0, net_wr_ack_ocm_gp1, net_wr_ack_ddr_gp1;
  wire net_wr_dv_ocm_gp0, net_wr_dv_ddr_gp0, net_wr_dv_ocm_gp1, net_wr_dv_ddr_gp1;
  wire [max_burst_bits-1:0] net_wr_data_gp0, net_wr_data_gp1;
  wire [addr_width-1:0] net_wr_addr_gp0, net_wr_addr_gp1;
  wire [max_burst_bytes_width:0] net_wr_bytes_gp0, net_wr_bytes_gp1;
  wire [axi_qos_width-1:0] net_wr_qos_gp0, net_wr_qos_gp1;

  wire net_rd_req_ddr_gp0, net_rd_req_ddr_gp1;
  wire net_rd_req_ocm_gp0, net_rd_req_ocm_gp1;
  wire net_rd_req_reg_gp0, net_rd_req_reg_gp1;
  wire [addr_width-1:0] net_rd_addr_gp0, net_rd_addr_gp1;
  wire [max_burst_bytes_width:0] net_rd_bytes_gp0, net_rd_bytes_gp1;
  wire [max_burst_bits-1:0] net_rd_data_ddr_gp0, net_rd_data_ddr_gp1;
  wire [max_burst_bits-1:0] net_rd_data_ocm_gp0, net_rd_data_ocm_gp1;
  wire [max_burst_bits-1:0] net_rd_data_reg_gp0, net_rd_data_reg_gp1;
  wire  net_rd_dv_ddr_gp0, net_rd_dv_ddr_gp1;
  wire  net_rd_dv_ocm_gp0, net_rd_dv_ocm_gp1;
  wire  net_rd_dv_reg_gp0, net_rd_dv_reg_gp1;
  wire [axi_qos_width-1:0] net_rd_qos_gp0, net_rd_qos_gp1;
  
  wire net_wr_ack_ddr_hp0, net_wr_ack_ddr_hp1, net_wr_ack_ddr_hp2, net_wr_ack_ddr_hp3;
  wire net_wr_ack_ocm_hp0, net_wr_ack_ocm_hp1, net_wr_ack_ocm_hp2, net_wr_ack_ocm_hp3;
  wire net_wr_dv_ddr_hp0, net_wr_dv_ddr_hp1, net_wr_dv_ddr_hp2, net_wr_dv_ddr_hp3;
  wire net_wr_dv_ocm_hp0, net_wr_dv_ocm_hp1, net_wr_dv_ocm_hp2, net_wr_dv_ocm_hp3;
  wire [max_burst_bits-1:0] net_wr_data_hp0, net_wr_data_hp1, net_wr_data_hp2, net_wr_data_hp3;
  wire [addr_width-1:0] net_wr_addr_hp0, net_wr_addr_hp1, net_wr_addr_hp2, net_wr_addr_hp3;
  wire [max_burst_bytes_width:0] net_wr_bytes_hp0, net_wr_bytes_hp1, net_wr_bytes_hp2, net_wr_bytes_hp3;
  wire [axi_qos_width-1:0] net_wr_qos_hp0, net_wr_qos_hp1, net_wr_qos_hp2, net_wr_qos_hp3;
  
  wire net_rd_req_ddr_hp0, net_rd_req_ddr_hp1, net_rd_req_ddr_hp2, net_rd_req_ddr_hp3;
  wire net_rd_req_ocm_hp0, net_rd_req_ocm_hp1, net_rd_req_ocm_hp2, net_rd_req_ocm_hp3;
  wire [addr_width-1:0] net_rd_addr_hp0, net_rd_addr_hp1, net_rd_addr_hp2, net_rd_addr_hp3;
  wire [max_burst_bytes_width:0] net_rd_bytes_hp0, net_rd_bytes_hp1, net_rd_bytes_hp2, net_rd_bytes_hp3;
  wire [max_burst_bits-1:0] net_rd_data_ddr_hp0, net_rd_data_ddr_hp1, net_rd_data_ddr_hp2, net_rd_data_ddr_hp3;
  wire [max_burst_bits-1:0] net_rd_data_ocm_hp0, net_rd_data_ocm_hp1, net_rd_data_ocm_hp2, net_rd_data_ocm_hp3;
  wire  net_rd_dv_ddr_hp0, net_rd_dv_ddr_hp1, net_rd_dv_ddr_hp2, net_rd_dv_ddr_hp3;
  wire  net_rd_dv_ocm_hp0, net_rd_dv_ocm_hp1, net_rd_dv_ocm_hp2, net_rd_dv_ocm_hp3;
  wire [axi_qos_width-1:0] net_rd_qos_hp0, net_rd_qos_hp1, net_rd_qos_hp2, net_rd_qos_hp3;

  wire net_wr_ack_ddr_acp,net_wr_ack_ocm_acp;
  wire net_wr_dv_ddr_acp,net_wr_dv_ocm_acp;
  wire [max_burst_bits-1:0] net_wr_data_acp;
  wire [addr_width-1:0] net_wr_addr_acp;
  wire [max_burst_bytes_width:0] net_wr_bytes_acp;
  wire [axi_qos_width-1:0] net_wr_qos_acp;
  
  wire net_rd_req_ddr_acp, net_rd_req_ocm_acp;
  wire [addr_width-1:0] net_rd_addr_acp;
  wire [max_burst_bytes_width:0] net_rd_bytes_acp;
  wire [max_burst_bits-1:0] net_rd_data_ddr_acp;
  wire [max_burst_bits-1:0] net_rd_data_ocm_acp;
  wire  net_rd_dv_ddr_acp,net_rd_dv_ocm_acp;
  wire [axi_qos_width-1:0] net_rd_qos_acp;
  
  wire ocm_wr_ack_port0;
  wire ocm_wr_dv_port0;
  wire ocm_rd_req_port0;
  wire ocm_rd_dv_port0;
  wire [addr_width-1:0] ocm_wr_addr_port0;
  wire [max_burst_bits-1:0] ocm_wr_data_port0;
  wire [max_burst_bytes_width:0] ocm_wr_bytes_port0;
  wire [addr_width-1:0] ocm_rd_addr_port0;
  wire [max_burst_bits-1:0] ocm_rd_data_port0;
  wire [max_burst_bytes_width:0] ocm_rd_bytes_port0;
  wire [axi_qos_width-1:0] ocm_wr_qos_port0;
  wire [axi_qos_width-1:0] ocm_rd_qos_port0;

  wire ocm_wr_ack_port1;
  wire ocm_wr_dv_port1;
  wire ocm_rd_req_port1;
  wire ocm_rd_dv_port1;
  wire [addr_width-1:0] ocm_wr_addr_port1;
  wire [max_burst_bits-1:0] ocm_wr_data_port1;
  wire [max_burst_bytes_width:0] ocm_wr_bytes_port1;
  wire [addr_width-1:0] ocm_rd_addr_port1;
  wire [max_burst_bits-1:0] ocm_rd_data_port1;
  wire [max_burst_bytes_width:0] ocm_rd_bytes_port1;
  wire [axi_qos_width-1:0] ocm_wr_qos_port1;
  wire [axi_qos_width-1:0] ocm_rd_qos_port1;

  wire ddr_wr_ack_port0;
  wire ddr_wr_dv_port0;
  wire ddr_rd_req_port0;
  wire ddr_rd_dv_port0;
  wire[addr_width-1:0] ddr_wr_addr_port0;
  wire[max_burst_bits-1:0] ddr_wr_data_port0;
  wire[max_burst_bytes_width:0] ddr_wr_bytes_port0;
  wire[addr_width-1:0] ddr_rd_addr_port0;
  wire[max_burst_bits-1:0] ddr_rd_data_port0;
  wire[max_burst_bytes_width:0] ddr_rd_bytes_port0;
  wire [axi_qos_width-1:0] ddr_wr_qos_port0;
  wire [axi_qos_width-1:0] ddr_rd_qos_port0;

  wire ddr_wr_ack_port1;
  wire ddr_wr_dv_port1;
  wire ddr_rd_req_port1;
  wire ddr_rd_dv_port1;
  wire[addr_width-1:0] ddr_wr_addr_port1;
  wire[max_burst_bits-1:0] ddr_wr_data_port1;
  wire[max_burst_bytes_width:0] ddr_wr_bytes_port1;
  wire[addr_width-1:0] ddr_rd_addr_port1;
  wire[max_burst_bits-1:0] ddr_rd_data_port1;
  wire[max_burst_bytes_width:0] ddr_rd_bytes_port1;
  wire[axi_qos_width-1:0] ddr_wr_qos_port1;
  wire[axi_qos_width-1:0] ddr_rd_qos_port1;
  
  wire ddr_wr_ack_port2;
  wire ddr_wr_dv_port2;
  wire ddr_rd_req_port2;
  wire ddr_rd_dv_port2;
  wire[addr_width-1:0] ddr_wr_addr_port2;
  wire[max_burst_bits-1:0] ddr_wr_data_port2;
  wire[max_burst_bytes_width:0] ddr_wr_bytes_port2;
  wire[addr_width-1:0] ddr_rd_addr_port2;
  wire[max_burst_bits-1:0] ddr_rd_data_port2;
  wire[max_burst_bytes_width:0] ddr_rd_bytes_port2;
  wire[axi_qos_width-1:0] ddr_wr_qos_port2;
  wire[axi_qos_width-1:0] ddr_rd_qos_port2;
  
  wire ddr_wr_ack_port3;
  wire ddr_wr_dv_port3;
  wire ddr_rd_req_port3;
  wire ddr_rd_dv_port3;
  wire[addr_width-1:0] ddr_wr_addr_port3;
  wire[max_burst_bits-1:0] ddr_wr_data_port3;
  wire[max_burst_bytes_width:0] ddr_wr_bytes_port3;
  wire[addr_width-1:0] ddr_rd_addr_port3;
  wire[max_burst_bits-1:0] ddr_rd_data_port3;
  wire[max_burst_bytes_width:0] ddr_rd_bytes_port3;
  wire[axi_qos_width-1:0] ddr_wr_qos_port3;
  wire[axi_qos_width-1:0] ddr_rd_qos_port3;

  wire reg_rd_req_port0;
  wire reg_rd_dv_port0;
  wire[addr_width-1:0] reg_rd_addr_port0;
  wire[max_burst_bits-1:0] reg_rd_data_port0;
  wire[max_burst_bytes_width:0] reg_rd_bytes_port0;
  wire [axi_qos_width-1:0] reg_rd_qos_port0;

  wire reg_rd_req_port1;
  wire reg_rd_dv_port1;
  wire[addr_width-1:0] reg_rd_addr_port1;
  wire[max_burst_bits-1:0] reg_rd_data_port1;
  wire[max_burst_bytes_width:0] reg_rd_bytes_port1;
  wire [axi_qos_width-1:0] reg_rd_qos_port1;

  wire [11:0]  M_AXI_GP0_AWID_FULL;
  wire [11:0]  M_AXI_GP0_WID_FULL;
  wire [11:0]  M_AXI_GP0_ARID_FULL;
  
  wire [11:0]  M_AXI_GP0_BID_FULL;
  wire [11:0]  M_AXI_GP0_RID_FULL;
  
  wire [11:0]  M_AXI_GP1_AWID_FULL;
  wire [11:0]  M_AXI_GP1_WID_FULL;
  wire [11:0]  M_AXI_GP1_ARID_FULL;
  
  wire [11:0]  M_AXI_GP1_BID_FULL;
  wire [11:0]  M_AXI_GP1_RID_FULL;

  
  function [5:0] compress_id; 
  	input [11:0] id; 
  		begin 
  			compress_id = id[5:0]; 
  		end 
  endfunction 
  
  function [11:0] uncompress_id; 
  	input [5:0] id; 
  		begin 
  		    uncompress_id = {6'b110000, id[5:0]};
  		end 
  endfunction

  assign M_AXI_GP0_AWID        = (C_M_AXI_GP0_ENABLE_STATIC_REMAP == 1) ? compress_id(M_AXI_GP0_AWID_FULL) : M_AXI_GP0_AWID_FULL;
  assign M_AXI_GP0_WID         = (C_M_AXI_GP0_ENABLE_STATIC_REMAP == 1) ? compress_id(M_AXI_GP0_WID_FULL)  : M_AXI_GP0_WID_FULL;   
  assign M_AXI_GP0_ARID        = (C_M_AXI_GP0_ENABLE_STATIC_REMAP == 1) ? compress_id(M_AXI_GP0_ARID_FULL) : M_AXI_GP0_ARID_FULL;      
  assign M_AXI_GP0_BID_FULL    = (C_M_AXI_GP0_ENABLE_STATIC_REMAP == 1) ? uncompress_id(M_AXI_GP0_BID)     : M_AXI_GP0_BID;
  assign M_AXI_GP0_RID_FULL    = (C_M_AXI_GP0_ENABLE_STATIC_REMAP == 1) ? uncompress_id(M_AXI_GP0_RID)     : M_AXI_GP0_RID;      


  assign M_AXI_GP1_AWID        = (C_M_AXI_GP1_ENABLE_STATIC_REMAP == 1) ? compress_id(M_AXI_GP1_AWID_FULL) : M_AXI_GP1_AWID_FULL;
  assign M_AXI_GP1_WID         = (C_M_AXI_GP1_ENABLE_STATIC_REMAP == 1) ? compress_id(M_AXI_GP1_WID_FULL)  : M_AXI_GP1_WID_FULL;   
  assign M_AXI_GP1_ARID        = (C_M_AXI_GP1_ENABLE_STATIC_REMAP == 1) ? compress_id(M_AXI_GP1_ARID_FULL) : M_AXI_GP1_ARID_FULL;      
  assign M_AXI_GP1_BID_FULL    = (C_M_AXI_GP1_ENABLE_STATIC_REMAP == 1) ? uncompress_id(M_AXI_GP1_BID)     : M_AXI_GP1_BID;
  assign M_AXI_GP1_RID_FULL    = (C_M_AXI_GP1_ENABLE_STATIC_REMAP == 1) ? uncompress_id(M_AXI_GP1_RID)     : M_AXI_GP1_RID;      




  processing_system7_bfm_v2_0_5_interconnect_model icm (
                 .rstn(net_rstn),
                 .sw_clk(net_sw_clk),

                 .w_qos_gp0(net_wr_qos_gp0),
                 .w_qos_gp1(net_wr_qos_gp1),
                 .w_qos_hp0(net_wr_qos_hp0),
                 .w_qos_hp1(net_wr_qos_hp1),
                 .w_qos_hp2(net_wr_qos_hp2),
                 .w_qos_hp3(net_wr_qos_hp3),
                                            
                 .r_qos_gp0(net_rd_qos_gp0),
                 .r_qos_gp1(net_rd_qos_gp1),
                 .r_qos_hp0(net_rd_qos_hp0),
                 .r_qos_hp1(net_rd_qos_hp1),
                 .r_qos_hp2(net_rd_qos_hp2),
                 .r_qos_hp3(net_rd_qos_hp3),

              /* GP Slave ports access */
                 .wr_ack_ddr_gp0(net_wr_ack_ddr_gp0),
                 .wr_ack_ocm_gp0(net_wr_ack_ocm_gp0),
                 .wr_data_gp0(net_wr_data_gp0),
                 .wr_addr_gp0(net_wr_addr_gp0),
                 .wr_bytes_gp0(net_wr_bytes_gp0),
                 .wr_dv_ddr_gp0(net_wr_dv_ddr_gp0),
                 .wr_dv_ocm_gp0(net_wr_dv_ocm_gp0),
                 .rd_req_ddr_gp0(net_rd_req_ddr_gp0),
                 .rd_req_ocm_gp0(net_rd_req_ocm_gp0),
                 .rd_req_reg_gp0(net_rd_req_reg_gp0),
                 .rd_addr_gp0(net_rd_addr_gp0),
                 .rd_bytes_gp0(net_rd_bytes_gp0),
                 .rd_data_ddr_gp0(net_rd_data_ddr_gp0),
                 .rd_data_ocm_gp0(net_rd_data_ocm_gp0),
                 .rd_data_reg_gp0(net_rd_data_reg_gp0),
                 .rd_dv_ddr_gp0(net_rd_dv_ddr_gp0),
                 .rd_dv_ocm_gp0(net_rd_dv_ocm_gp0),
                 .rd_dv_reg_gp0(net_rd_dv_reg_gp0),

                 .wr_ack_ddr_gp1(net_wr_ack_ddr_gp1),
                 .wr_ack_ocm_gp1(net_wr_ack_ocm_gp1),
                 .wr_data_gp1(net_wr_data_gp1), 
                 .wr_addr_gp1(net_wr_addr_gp1),
                 .wr_bytes_gp1(net_wr_bytes_gp1),
                 .wr_dv_ddr_gp1(net_wr_dv_ddr_gp1),
                 .wr_dv_ocm_gp1(net_wr_dv_ocm_gp1),
                 .rd_req_ddr_gp1(net_rd_req_ddr_gp1),
                 .rd_req_ocm_gp1(net_rd_req_ocm_gp1),
                 .rd_req_reg_gp1(net_rd_req_reg_gp1),
                 .rd_addr_gp1(net_rd_addr_gp1),
                 .rd_bytes_gp1(net_rd_bytes_gp1),
                 .rd_data_ddr_gp1(net_rd_data_ddr_gp1),
                 .rd_data_ocm_gp1(net_rd_data_ocm_gp1),
                 .rd_data_reg_gp1(net_rd_data_reg_gp1),
                 .rd_dv_ddr_gp1(net_rd_dv_ddr_gp1),
                 .rd_dv_ocm_gp1(net_rd_dv_ocm_gp1),
                 .rd_dv_reg_gp1(net_rd_dv_reg_gp1),

              /* HP Slave ports access */
                 .wr_ack_ddr_hp0(net_wr_ack_ddr_hp0),
                 .wr_ack_ocm_hp0(net_wr_ack_ocm_hp0),
                 .wr_data_hp0(net_wr_data_hp0),
                 .wr_addr_hp0(net_wr_addr_hp0),
                 .wr_bytes_hp0(net_wr_bytes_hp0),
                 .wr_dv_ddr_hp0(net_wr_dv_ddr_hp0),
                 .wr_dv_ocm_hp0(net_wr_dv_ocm_hp0),
                 .rd_req_ddr_hp0(net_rd_req_ddr_hp0),
                 .rd_req_ocm_hp0(net_rd_req_ocm_hp0),
                 .rd_addr_hp0(net_rd_addr_hp0),
                 .rd_bytes_hp0(net_rd_bytes_hp0),
                 .rd_data_ddr_hp0(net_rd_data_ddr_hp0),
                 .rd_data_ocm_hp0(net_rd_data_ocm_hp0),
                 .rd_dv_ddr_hp0(net_rd_dv_ddr_hp0),
                 .rd_dv_ocm_hp0(net_rd_dv_ocm_hp0),

                 .wr_ack_ddr_hp1(net_wr_ack_ddr_hp1),
                 .wr_ack_ocm_hp1(net_wr_ack_ocm_hp1),
                 .wr_data_hp1(net_wr_data_hp1),
                 .wr_addr_hp1(net_wr_addr_hp1),
                 .wr_bytes_hp1(net_wr_bytes_hp1),
                 .wr_dv_ddr_hp1(net_wr_dv_ddr_hp1),
                 .wr_dv_ocm_hp1(net_wr_dv_ocm_hp1),
                 .rd_req_ddr_hp1(net_rd_req_ddr_hp1),
                 .rd_req_ocm_hp1(net_rd_req_ocm_hp1),
                 .rd_addr_hp1(net_rd_addr_hp1),
                 .rd_bytes_hp1(net_rd_bytes_hp1),
                 .rd_data_ddr_hp1(net_rd_data_ddr_hp1),
                 .rd_data_ocm_hp1(net_rd_data_ocm_hp1),
                 .rd_dv_ocm_hp1(net_rd_dv_ocm_hp1),
                 .rd_dv_ddr_hp1(net_rd_dv_ddr_hp1),

                 .wr_ack_ddr_hp2(net_wr_ack_ddr_hp2),
                 .wr_ack_ocm_hp2(net_wr_ack_ocm_hp2),
                 .wr_data_hp2(net_wr_data_hp2),
                 .wr_addr_hp2(net_wr_addr_hp2),
                 .wr_bytes_hp2(net_wr_bytes_hp2),
                 .wr_dv_ocm_hp2(net_wr_dv_ocm_hp2),
                 .wr_dv_ddr_hp2(net_wr_dv_ddr_hp2),
                 .rd_req_ddr_hp2(net_rd_req_ddr_hp2),
                 .rd_req_ocm_hp2(net_rd_req_ocm_hp2),
                 .rd_addr_hp2(net_rd_addr_hp2),
                 .rd_bytes_hp2(net_rd_bytes_hp2),
                 .rd_data_ddr_hp2(net_rd_data_ddr_hp2),
                 .rd_data_ocm_hp2(net_rd_data_ocm_hp2),
                 .rd_dv_ddr_hp2(net_rd_dv_ddr_hp2),
                 .rd_dv_ocm_hp2(net_rd_dv_ocm_hp2),

                 .wr_ack_ocm_hp3(net_wr_ack_ocm_hp3),
                 .wr_ack_ddr_hp3(net_wr_ack_ddr_hp3),
                 .wr_data_hp3(net_wr_data_hp3),
                 .wr_addr_hp3(net_wr_addr_hp3),
                 .wr_bytes_hp3(net_wr_bytes_hp3),
                 .wr_dv_ddr_hp3(net_wr_dv_ddr_hp3),
                 .wr_dv_ocm_hp3(net_wr_dv_ocm_hp3),
                 .rd_req_ddr_hp3(net_rd_req_ddr_hp3),
                 .rd_req_ocm_hp3(net_rd_req_ocm_hp3),
                 .rd_addr_hp3(net_rd_addr_hp3),
                 .rd_bytes_hp3(net_rd_bytes_hp3),
                 .rd_data_ddr_hp3(net_rd_data_ddr_hp3),
                 .rd_data_ocm_hp3(net_rd_data_ocm_hp3),
                 .rd_dv_ddr_hp3(net_rd_dv_ddr_hp3),
                 .rd_dv_ocm_hp3(net_rd_dv_ocm_hp3),

                 /* Goes to port 1 of DDR */
                 .ddr_wr_ack_port1(ddr_wr_ack_port1),
                 .ddr_wr_dv_port1(ddr_wr_dv_port1),
                 .ddr_rd_req_port1(ddr_rd_req_port1),
                 .ddr_rd_dv_port1 (ddr_rd_dv_port1),
                 .ddr_wr_addr_port1(ddr_wr_addr_port1),
                 .ddr_wr_data_port1(ddr_wr_data_port1),
                 .ddr_wr_bytes_port1(ddr_wr_bytes_port1),
                 .ddr_rd_addr_port1(ddr_rd_addr_port1),
                 .ddr_rd_data_port1(ddr_rd_data_port1),
                 .ddr_rd_bytes_port1(ddr_rd_bytes_port1),
                 .ddr_wr_qos_port1(ddr_wr_qos_port1),
                 .ddr_rd_qos_port1(ddr_rd_qos_port1),
                 
                /* Goes to port2 of DDR */
                 .ddr_wr_ack_port2 (ddr_wr_ack_port2),
                 .ddr_wr_dv_port2  (ddr_wr_dv_port2),
                 .ddr_rd_req_port2 (ddr_rd_req_port2),
                 .ddr_rd_dv_port2  (ddr_rd_dv_port2),
                 .ddr_wr_addr_port2(ddr_wr_addr_port2),
                 .ddr_wr_data_port2(ddr_wr_data_port2),
                 .ddr_wr_bytes_port2(ddr_wr_bytes_port2),
                 .ddr_rd_addr_port2(ddr_rd_addr_port2),
                 .ddr_rd_data_port2(ddr_rd_data_port2),
                 .ddr_rd_bytes_port2(ddr_rd_bytes_port2),
                 .ddr_wr_qos_port2 (ddr_wr_qos_port2),
                 .ddr_rd_qos_port2 (ddr_rd_qos_port2),
                
                /* Goes to port3 of DDR */
                 .ddr_wr_ack_port3 (ddr_wr_ack_port3),
                 .ddr_wr_dv_port3  (ddr_wr_dv_port3),
                 .ddr_rd_req_port3 (ddr_rd_req_port3),
                 .ddr_rd_dv_port3  (ddr_rd_dv_port3),
                 .ddr_wr_addr_port3(ddr_wr_addr_port3),
                 .ddr_wr_data_port3(ddr_wr_data_port3),
                 .ddr_wr_bytes_port3(ddr_wr_bytes_port3),
                 .ddr_rd_addr_port3(ddr_rd_addr_port3),
                 .ddr_rd_data_port3(ddr_rd_data_port3),
                 .ddr_rd_bytes_port3(ddr_rd_bytes_port3),
                 .ddr_wr_qos_port3 (ddr_wr_qos_port3),
                 .ddr_rd_qos_port3 (ddr_rd_qos_port3),

                /* Goes to port 0 of OCM */
                 .ocm_wr_ack_port1 (ocm_wr_ack_port1),
                 .ocm_wr_dv_port1  (ocm_wr_dv_port1),
                 .ocm_rd_req_port1 (ocm_rd_req_port1),
                 .ocm_rd_dv_port1  (ocm_rd_dv_port1),
                 .ocm_wr_addr_port1(ocm_wr_addr_port1),
                 .ocm_wr_data_port1(ocm_wr_data_port1),
                 .ocm_wr_bytes_port1(ocm_wr_bytes_port1),
                 .ocm_rd_addr_port1(ocm_rd_addr_port1),
                 .ocm_rd_data_port1(ocm_rd_data_port1),
                 .ocm_rd_bytes_port1(ocm_rd_bytes_port1),
                 .ocm_wr_qos_port1(ocm_wr_qos_port1),
                 .ocm_rd_qos_port1(ocm_rd_qos_port1), 

                /* Goes to port 0 of REG */
                 .reg_rd_qos_port1 (reg_rd_qos_port1) ,
                 .reg_rd_req_port1 (reg_rd_req_port1),
                 .reg_rd_dv_port1  (reg_rd_dv_port1),
                 .reg_rd_addr_port1(reg_rd_addr_port1),
                 .reg_rd_data_port1(reg_rd_data_port1),
                 .reg_rd_bytes_port1(reg_rd_bytes_port1)
                 ); 

  processing_system7_bfm_v2_0_5_ddrc ddrc (
           .rstn(net_rstn),
           .sw_clk(net_sw_clk),
          
          /* Goes to port 0 of DDR */
           .ddr_wr_ack_port0 (ddr_wr_ack_port0),
           .ddr_wr_dv_port0  (ddr_wr_dv_port0),
           .ddr_rd_req_port0 (ddr_rd_req_port0),
           .ddr_rd_dv_port0  (ddr_rd_dv_port0),

           .ddr_wr_addr_port0(net_wr_addr_acp),
           .ddr_wr_data_port0(net_wr_data_acp),
           .ddr_wr_bytes_port0(net_wr_bytes_acp),

           .ddr_rd_addr_port0(net_rd_addr_acp),
           .ddr_rd_bytes_port0(net_rd_bytes_acp),
           
           .ddr_rd_data_port0(ddr_rd_data_port0),

           .ddr_wr_qos_port0 (net_wr_qos_acp),
           .ddr_rd_qos_port0 (net_rd_qos_acp),
          
          
          /* Goes to port 1 of DDR */
           .ddr_wr_ack_port1 (ddr_wr_ack_port1),
           .ddr_wr_dv_port1  (ddr_wr_dv_port1),
           .ddr_rd_req_port1 (ddr_rd_req_port1),
           .ddr_rd_dv_port1  (ddr_rd_dv_port1),
           .ddr_wr_addr_port1(ddr_wr_addr_port1),
           .ddr_wr_data_port1(ddr_wr_data_port1),
           .ddr_wr_bytes_port1(ddr_wr_bytes_port1),
           .ddr_rd_addr_port1(ddr_rd_addr_port1),
           .ddr_rd_data_port1(ddr_rd_data_port1),
           .ddr_rd_bytes_port1(ddr_rd_bytes_port1),
           .ddr_wr_qos_port1 (ddr_wr_qos_port1),
           .ddr_rd_qos_port1 (ddr_rd_qos_port1),
          
          /* Goes to port2 of DDR */
           .ddr_wr_ack_port2 (ddr_wr_ack_port2),
           .ddr_wr_dv_port2  (ddr_wr_dv_port2),
           .ddr_rd_req_port2 (ddr_rd_req_port2),
           .ddr_rd_dv_port2  (ddr_rd_dv_port2),
           .ddr_wr_addr_port2(ddr_wr_addr_port2),
           .ddr_wr_data_port2(ddr_wr_data_port2),
           .ddr_wr_bytes_port2(ddr_wr_bytes_port2),
           .ddr_rd_addr_port2(ddr_rd_addr_port2),
           .ddr_rd_data_port2(ddr_rd_data_port2),
           .ddr_rd_bytes_port2(ddr_rd_bytes_port2),
           .ddr_wr_qos_port2 (ddr_wr_qos_port2),
           .ddr_rd_qos_port2 (ddr_rd_qos_port2),
          
          /* Goes to port3 of DDR */
           .ddr_wr_ack_port3 (ddr_wr_ack_port3),
           .ddr_wr_dv_port3  (ddr_wr_dv_port3),
           .ddr_rd_req_port3 (ddr_rd_req_port3),
           .ddr_rd_dv_port3  (ddr_rd_dv_port3),
           .ddr_wr_addr_port3(ddr_wr_addr_port3),
           .ddr_wr_data_port3(ddr_wr_data_port3),
           .ddr_wr_bytes_port3(ddr_wr_bytes_port3),
           .ddr_rd_addr_port3(ddr_rd_addr_port3),
           .ddr_rd_data_port3(ddr_rd_data_port3),
           .ddr_rd_bytes_port3(ddr_rd_bytes_port3),
           .ddr_wr_qos_port3 (ddr_wr_qos_port3),
           .ddr_rd_qos_port3 (ddr_rd_qos_port3)
          
            );

  processing_system7_bfm_v2_0_5_ocmc ocmc (
           .rstn(net_rstn),
           .sw_clk(net_sw_clk),
    
    /* Goes to port 0 of OCM */
           .ocm_wr_ack_port0 (ocm_wr_ack_port0),
           .ocm_wr_dv_port0  (ocm_wr_dv_port0),
           .ocm_rd_req_port0 (ocm_rd_req_port0),
           .ocm_rd_dv_port0  (ocm_rd_dv_port0),

           .ocm_wr_addr_port0(net_wr_addr_acp),
           .ocm_wr_data_port0(net_wr_data_acp),
           .ocm_wr_bytes_port0(net_wr_bytes_acp),

           .ocm_rd_addr_port0(net_rd_addr_acp),
           .ocm_rd_bytes_port0(net_rd_bytes_acp),
           
           .ocm_rd_data_port0(ocm_rd_data_port0),

           .ocm_wr_qos_port0 (net_wr_qos_acp),
           .ocm_rd_qos_port0 (net_rd_qos_acp),
          
            /* Goes to port 1 of OCM */
           .ocm_wr_ack_port1 (ocm_wr_ack_port1),
           .ocm_wr_dv_port1  (ocm_wr_dv_port1),
           .ocm_rd_req_port1 (ocm_rd_req_port1),
           .ocm_rd_dv_port1  (ocm_rd_dv_port1),
           .ocm_wr_addr_port1(ocm_wr_addr_port1),
           .ocm_wr_data_port1(ocm_wr_data_port1),
           .ocm_wr_bytes_port1(ocm_wr_bytes_port1),
           .ocm_rd_addr_port1(ocm_rd_addr_port1),
           .ocm_rd_data_port1(ocm_rd_data_port1),
           .ocm_rd_bytes_port1(ocm_rd_bytes_port1),
           .ocm_wr_qos_port1(ocm_wr_qos_port1),
           .ocm_rd_qos_port1(ocm_rd_qos_port1) 
    
  );

  processing_system7_bfm_v2_0_5_regc regc (
           .rstn(net_rstn),
           .sw_clk(net_sw_clk),
    
            /* Goes to port 0 of REG */
           .reg_rd_req_port0 (reg_rd_req_port0),
           .reg_rd_dv_port0  (reg_rd_dv_port0),
           .reg_rd_addr_port0(net_rd_addr_acp),
           .reg_rd_bytes_port0(net_rd_bytes_acp),
           .reg_rd_data_port0(reg_rd_data_port0),
           .reg_rd_qos_port0 (net_rd_qos_acp),
          
            /* Goes to port 1 of REG */
           .reg_rd_req_port1 (reg_rd_req_port1),
           .reg_rd_dv_port1  (reg_rd_dv_port1),
           .reg_rd_addr_port1(reg_rd_addr_port1),
           .reg_rd_data_port1(reg_rd_data_port1),
           .reg_rd_bytes_port1(reg_rd_bytes_port1),
           .reg_rd_qos_port1(reg_rd_qos_port1) 
    
  );
 
  /* include axi_gp port instantiations */
  `include "processing_system7_bfm_v2_0_5_axi_gp.v"

  /* include axi_hp port instantiations */
  `include "processing_system7_bfm_v2_0_5_axi_hp.v"

  /* include axi_acp port instantiations */
  `include "processing_system7_bfm_v2_0_5_axi_acp.v"

endmodule
