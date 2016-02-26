/*****************************************************************************
 * File : processing_system7_bfm_v2_0_5_unused_ports.v
 *
 * Date : 2012-11
 *
 * Description : Semantic checks for unused ports.
 *
 *****************************************************************************/

/* CAN */
assign CAN0_PHY_TX = 0;
assign CAN1_PHY_TX = 0;
always @(CAN0_PHY_RX or CAN1_PHY_RX)
begin 
 if(CAN0_PHY_RX | CAN1_PHY_RX)
  $display("[%0d] : %0s : CAN Interface is not supported.",$time, DISP_ERR);
end

/* ------------------------------------------- */
/* ETHERNET */
/* ------------------------------------------- */

assign ENET0_GMII_TX_EN = 0;
assign ENET0_GMII_TX_ER = 0;
assign ENET0_MDIO_MDC = 0;
assign ENET0_MDIO_O = 0; /// confirm
assign ENET0_MDIO_T = 0;
assign ENET0_PTP_DELAY_REQ_RX = 0;
assign ENET0_PTP_DELAY_REQ_TX = 0;
assign ENET0_PTP_PDELAY_REQ_RX = 0;
assign ENET0_PTP_PDELAY_REQ_TX = 0;
assign ENET0_PTP_PDELAY_RESP_RX = 0;
assign ENET0_PTP_PDELAY_RESP_TX = 0;
assign ENET0_PTP_SYNC_FRAME_RX = 0;
assign ENET0_PTP_SYNC_FRAME_TX = 0;
assign ENET0_SOF_RX = 0;
assign ENET0_SOF_TX = 0;
assign ENET0_GMII_TXD = 0;
always@(ENET0_GMII_COL or ENET0_GMII_CRS or ENET0_EXT_INTIN or 
        ENET0_GMII_RX_CLK or ENET0_GMII_RX_DV or ENET0_GMII_RX_ER or
        ENET0_GMII_TX_CLK or ENET0_MDIO_I or ENET0_GMII_RXD)
begin 
 if(ENET0_GMII_COL | ENET0_GMII_CRS | ENET0_EXT_INTIN | 
        ENET0_GMII_RX_CLK | ENET0_GMII_RX_DV | ENET0_GMII_RX_ER |
        ENET0_GMII_TX_CLK | ENET0_MDIO_I )
  $display("[%0d] : %0s : ETHERNET Interface is not supported.",$time, DISP_ERR);
end

assign ENET1_GMII_TX_EN = 0;
assign ENET1_GMII_TX_ER = 0;
assign ENET1_MDIO_MDC = 0;
assign ENET1_MDIO_O = 0;/// confirm
assign ENET1_MDIO_T = 0;
assign ENET1_PTP_DELAY_REQ_RX = 0;
assign ENET1_PTP_DELAY_REQ_TX = 0;
assign ENET1_PTP_PDELAY_REQ_RX = 0;
assign ENET1_PTP_PDELAY_REQ_TX = 0;
assign ENET1_PTP_PDELAY_RESP_RX = 0;
assign ENET1_PTP_PDELAY_RESP_TX = 0;
assign ENET1_PTP_SYNC_FRAME_RX = 0;
assign ENET1_PTP_SYNC_FRAME_TX = 0;
assign ENET1_SOF_RX = 0;
assign ENET1_SOF_TX = 0;
assign ENET1_GMII_TXD = 0;
always@(ENET1_GMII_COL or ENET1_GMII_CRS or ENET1_EXT_INTIN or 
        ENET1_GMII_RX_CLK or ENET1_GMII_RX_DV or ENET1_GMII_RX_ER or
        ENET1_GMII_TX_CLK or ENET1_MDIO_I or ENET1_GMII_RXD)
begin 
 if(ENET1_GMII_COL | ENET1_GMII_CRS | ENET1_EXT_INTIN | 
        ENET1_GMII_RX_CLK | ENET1_GMII_RX_DV | ENET1_GMII_RX_ER |
        ENET1_GMII_TX_CLK | ENET1_MDIO_I )
  $display("[%0d] : %0s : ETHERNET Interface is not supported.",$time, DISP_ERR);
end

/* ------------------------------------------- */
/* GPIO */
/* ------------------------------------------- */

assign GPIO_O = 0;
assign GPIO_T = 0;
always@(GPIO_I)
begin
if(GPIO_I !== 0)
 $display("[%0d] : %0s : GPIO Interface is not supported.",$time, DISP_ERR);
end

/* ------------------------------------------- */
/* I2C */
/* ------------------------------------------- */

assign I2C0_SDA_O = 0;
assign I2C0_SDA_T = 0;
assign I2C0_SCL_O = 0;
assign I2C0_SCL_T = 0;
assign I2C1_SDA_O = 0;
assign I2C1_SDA_T = 0;
assign I2C1_SCL_O = 0;
assign I2C1_SCL_T = 0;
always@(I2C0_SDA_I or I2C0_SCL_I or I2C1_SDA_I or I2C1_SCL_I )
begin
 if(I2C0_SDA_I | I2C0_SCL_I | I2C1_SDA_I | I2C1_SCL_I)
  $display("[%0d] : %0s : I2C Interface is not supported.",$time, DISP_ERR);
end

/* ------------------------------------------- */
/* JTAG  */
/* ------------------------------------------- */

assign PJTAG_TD_T = 0;
assign PJTAG_TD_O = 0;
always@(PJTAG_TCK or PJTAG_TMS or PJTAG_TD_I)
begin
 if(PJTAG_TCK | PJTAG_TMS | PJTAG_TD_I)
  $display("[%0d] : %0s : JTAG Interface is not supported.",$time, DISP_ERR);
end

/* ------------------------------------------- */
/* SDIO  */
/* ------------------------------------------- */

assign SDIO0_CLK = 0;
assign SDIO0_CMD_O = 0;
assign SDIO0_CMD_T = 0;
assign SDIO0_DATA_O = 0;
assign SDIO0_DATA_T = 0;
assign SDIO0_LED = 0;
assign SDIO0_BUSPOW = 0;
assign SDIO0_BUSVOLT = 0;
always@(SDIO0_CLK_FB or SDIO0_CMD_I or SDIO0_DATA_I or SDIO0_CDN or SDIO0_WP )
begin
 if(SDIO0_CLK_FB | SDIO0_CMD_I | SDIO0_CDN | SDIO0_WP )
  $display("[%0d] : %0s : SDIO Interface is not supported.",$time, DISP_ERR);
end

assign SDIO1_CLK = 0;
assign SDIO1_CMD_O = 0;
assign SDIO1_CMD_T = 0;
assign SDIO1_DATA_O = 0;
assign SDIO1_DATA_T = 0;
assign SDIO1_LED = 0;
assign SDIO1_BUSPOW = 0;
assign SDIO1_BUSVOLT = 0;
always@(SDIO1_CLK_FB or SDIO1_CMD_I or SDIO1_DATA_I or SDIO1_CDN or SDIO1_WP )
begin
 if(SDIO1_CLK_FB | SDIO1_CMD_I | SDIO1_CDN | SDIO1_WP )
  $display("[%0d] : %0s : SDIO Interface is not supported.",$time, DISP_ERR);
end

/* ------------------------------------------- */
/* SPI  */
/* ------------------------------------------- */

assign SPI0_SCLK_O = 0;
assign SPI0_SCLK_T = 0;
assign SPI0_MOSI_O = 0;
assign SPI0_MOSI_T = 0;
assign SPI0_MISO_O = 0;
assign SPI0_MISO_T = 0;
assign SPI0_SS_O = 0; /// confirm
assign SPI0_SS1_O = 0;/// confirm
assign SPI0_SS2_O = 0;/// confirm
assign SPI0_SS_T = 0;
always@(SPI0_SCLK_I or SPI0_MOSI_I or SPI0_MISO_I or SPI0_SS_I)
begin
 if(SPI0_SCLK_I | SPI0_MOSI_I | SPI0_MISO_I | SPI0_SS_I)
  $display("[%0d] : %0s : SPI Interface is not supported.",$time, DISP_ERR);
end

assign SPI1_SCLK_O = 0;
assign SPI1_SCLK_T = 0;
assign SPI1_MOSI_O = 0;
assign SPI1_MOSI_T = 0;
assign SPI1_MISO_O = 0;
assign SPI1_MISO_T = 0;
assign SPI1_SS_O = 0;
assign SPI1_SS1_O = 0;
assign SPI1_SS2_O = 0;
assign SPI1_SS_T = 0;
always@(SPI1_SCLK_I or SPI1_MOSI_I or SPI1_MISO_I or SPI1_SS_I)
begin
 if(SPI1_SCLK_I | SPI1_MOSI_I | SPI1_MISO_I | SPI1_SS_I)
  $display("[%0d] : %0s : SPI Interface is not supported.",$time, DISP_ERR);
end

/* ------------------------------------------- */
/* UART  */
/* ------------------------------------------- */
/// confirm
assign UART0_DTRN = 0;
assign UART0_RTSN = 0;
assign UART0_TX = 0;
always@(UART0_CTSN or UART0_DCDN or UART0_DSRN or UART0_RIN or UART0_RX)
begin
 if(UART0_CTSN | UART0_DCDN | UART0_DSRN | UART0_RIN | UART0_RX)
  $display("[%0d] : %0s : UART Interface is not supported.",$time, DISP_ERR);
end

assign UART1_DTRN = 0;
assign UART1_RTSN = 0;
assign UART1_TX = 0;
always@(UART1_CTSN or UART1_DCDN or UART1_DSRN or UART1_RIN or UART1_RX)
begin
 if(UART1_CTSN | UART1_DCDN | UART1_DSRN | UART1_RIN | UART1_RX)
  $display("[%0d] : %0s : UART Interface is not supported.",$time, DISP_ERR);
end

/* ------------------------------------------- */
/* TTC  */
/* ------------------------------------------- */

assign TTC0_WAVE0_OUT = 0;
assign TTC0_WAVE1_OUT = 0;
assign TTC0_WAVE2_OUT = 0;
always@(TTC0_CLK0_IN or TTC0_CLK1_IN or TTC0_CLK2_IN)
begin
 if(TTC0_CLK0_IN | TTC0_CLK1_IN | TTC0_CLK2_IN)
  $display("[%0d] : %0s : TTC Interface is not supported.",$time, DISP_ERR);
end

assign TTC1_WAVE0_OUT = 0;
assign TTC1_WAVE1_OUT = 0;
assign TTC1_WAVE2_OUT = 0;
always@(TTC1_CLK0_IN or TTC1_CLK1_IN or TTC1_CLK2_IN)
begin
 if(TTC1_CLK0_IN | TTC1_CLK1_IN | TTC1_CLK2_IN)
  $display("[%0d] : %0s : TTC Interface is not supported.",$time, DISP_ERR);
end

/* ------------------------------------------- */
/* WDT  */
/* ------------------------------------------- */

assign WDT_RST_OUT = 0;
always@(WDT_CLK_IN)
begin
 if(WDT_CLK_IN)
  $display("[%0d] : %0s : WDT Interface is not supported.",$time, DISP_ERR);
end

/* ------------------------------------------- */
/* TRACE  */
/* ------------------------------------------- */

assign TRACE_CTL = 0;
assign TRACE_DATA = 0;
always@(TRACE_CLK)
begin
 if(TRACE_CLK)
  $display("[%0d] : %0s : TRACE Interface is not supported.",$time, DISP_ERR);
end

/* ------------------------------------------- */
/* USB  */
/* ------------------------------------------- */
assign USB0_PORT_INDCTL = 0;
assign USB0_VBUS_PWRSELECT = 0;
always@(USB0_VBUS_PWRFAULT)
begin
 if(USB0_VBUS_PWRFAULT)
  $display("[%0d] : %0s : USB Interface is not supported.",$time, DISP_ERR);
end

assign USB1_PORT_INDCTL = 0;
assign USB1_VBUS_PWRSELECT = 0;
always@(USB1_VBUS_PWRFAULT)
begin
 if(USB1_VBUS_PWRFAULT)
  $display("[%0d] : %0s : USB Interface is not supported.",$time, DISP_ERR);
end

always@(SRAM_INTIN)
begin
 if(SRAM_INTIN)
  $display("[%0d] : %0s : SRAM_INTIN is not supported.",$time, DISP_ERR);
end 

/* ------------------------------------------- */
/* DMA  */
/* ------------------------------------------- */

assign DMA0_DATYPE = 0;
assign DMA0_DAVALID = 0;
assign DMA0_DRREADY = 0;
assign DMA0_RSTN = 0;
always@(DMA0_ACLK or DMA0_DAREADY or DMA0_DRLAST or DMA0_DRVALID or DMA0_DRTYPE)
begin
 if(DMA0_ACLK | DMA0_DAREADY | DMA0_DRLAST | DMA0_DRVALID | DMA0_DRTYPE)
  $display("[%0d] : %0s : DMA Interface is not supported.",$time, DISP_ERR);
end

assign DMA1_DATYPE = 0;
assign DMA1_DAVALID = 0;
assign DMA1_DRREADY = 0;
assign DMA1_RSTN = 0;
always@(DMA1_ACLK or DMA1_DAREADY or DMA1_DRLAST or DMA1_DRVALID or DMA1_DRTYPE)
begin
 if(DMA1_ACLK | DMA1_DAREADY | DMA1_DRLAST | DMA1_DRVALID | DMA1_DRTYPE)
  $display("[%0d] : %0s : DMA Interface is not supported.",$time, DISP_ERR);
end

assign DMA2_DATYPE = 0;
assign DMA2_DAVALID = 0;
assign DMA2_DRREADY = 0;
assign DMA2_RSTN = 0;
always@(DMA2_ACLK or DMA2_DAREADY or DMA2_DRLAST or DMA2_DRVALID or DMA2_DRTYPE)
begin
 if(DMA2_ACLK | DMA2_DAREADY | DMA2_DRLAST | DMA2_DRVALID | DMA2_DRTYPE)
  $display("[%0d] : %0s : DMA Interface is not supported.",$time, DISP_ERR);
end

assign DMA3_DATYPE = 0;
assign DMA3_DAVALID = 0;
assign DMA3_DRREADY = 0;
assign DMA3_RSTN = 0;
always@(DMA3_ACLK or DMA3_DAREADY or DMA3_DRLAST or DMA3_DRVALID or DMA3_DRTYPE)
begin
 if(DMA3_ACLK | DMA3_DAREADY | DMA3_DRLAST | DMA3_DRVALID | DMA3_DRTYPE)
  $display("[%0d] : %0s : DMA Interface is not supported.",$time, DISP_ERR);
end

/* ------------------------------------------- */
/* FTM  */
/* ------------------------------------------- */

assign FTMT_F2P_TRIGACK = 0;
assign FTMT_P2F_TRIG = 0;
assign FTMT_P2F_DEBUG = 0;
always@(FTMD_TRACEIN_DATA or FTMD_TRACEIN_VALID or FTMD_TRACEIN_CLK or 
        FTMD_TRACEIN_ATID or FTMT_F2P_TRIG or FTMT_F2P_DEBUG or FTMT_P2F_TRIGACK)
begin
 if(FTMD_TRACEIN_DATA | FTMD_TRACEIN_VALID | FTMD_TRACEIN_CLK | FTMD_TRACEIN_ATID | FTMT_F2P_TRIG | FTMT_F2P_DEBUG | FTMT_P2F_TRIGACK)
  $display("[%0d] : %0s : FTM Interface is not supported.",$time, DISP_ERR);
end

/* ------------------------------------------- */
/* EVENT  */
/* ------------------------------------------- */

assign EVENT_EVENTO = 0;
assign EVENT_STANDBYWFE = 0;  
assign EVENT_STANDBYWFI = 0;
always@(EVENT_EVENTI)
begin
 if(EVENT_EVENTI)
  $display("[%0d] : %0s : EVENT Interface is not supported.",$time, DISP_ERR);
end

/* ------------------------------------------- */
/* MIO */
/* ------------------------------------------- */

always@(MIO)
begin
  if(MIO !== 0)
  $display("[%0d] : %0s : MIO is not supported.",$time, DISP_ERR);
end

/* ------------------------------------------- */
/* FCLK_TRIG */
/* ------------------------------------------- */

always@(FCLK_CLKTRIG3_N or FCLK_CLKTRIG2_N or FCLK_CLKTRIG1_N or FCLK_CLKTRIG0_N )
begin
 if(FCLK_CLKTRIG3_N | FCLK_CLKTRIG2_N | FCLK_CLKTRIG1_N | FCLK_CLKTRIG0_N )
  $display("[%0d] : %0s : FCLK_TRIG is not supported.",$time, DISP_ERR);
end

/* ------------------------------------------- */
/* MISC */
/* ------------------------------------------- */

always@(FPGA_IDLE_N)
begin
 if(FPGA_IDLE_N)
  $display("[%0d] : %0s : FPGA_IDLE_N is not supported.",$time, DISP_ERR);
end

always@(DDR_ARB)
begin
 if(DDR_ARB !== 0)
  $display("[%0d] : %0s : DDR_ARB is not supported.",$time, DISP_ERR);
end

always@(Core0_nFIQ or Core0_nIRQ or Core1_nFIQ or Core1_nIRQ )
begin
 if(Core0_nFIQ | Core0_nIRQ | Core1_nFIQ | Core1_nIRQ) 
  $display("[%0d] : %0s : CORE FIQ,IRQ is not supported.",$time, DISP_ERR);
end

/* ------------------------------------------- */
/* DDR */
/* ------------------------------------------- */

assign DDR_WEB = 0;
always@(DDR_Clk or DDR_CS_n)
begin
if(!DDR_CS_n)
 $display("[%0d] : %0s : EXTERNAL DDR is not supported.",$time, DISP_ERR);
end

/* ------------------------------------------- */
/* IRQ_P2F */
/* ------------------------------------------- */

assign IRQ_P2F_DMAC_ABORT = 0;
assign IRQ_P2F_DMAC0 = 0;
assign IRQ_P2F_DMAC1 = 0;
assign IRQ_P2F_DMAC2 = 0;
assign IRQ_P2F_DMAC3 = 0;
assign IRQ_P2F_DMAC4 = 0;
assign IRQ_P2F_DMAC5 = 0;
assign IRQ_P2F_DMAC6 = 0;
assign IRQ_P2F_DMAC7 = 0;
assign IRQ_P2F_SMC = 0;
assign IRQ_P2F_QSPI = 0;
assign IRQ_P2F_CTI = 0;
assign IRQ_P2F_GPIO = 0;
assign IRQ_P2F_USB0 = 0;
assign IRQ_P2F_ENET0 = 0;
assign IRQ_P2F_ENET_WAKE0 = 0;
assign IRQ_P2F_SDIO0 = 0;
assign IRQ_P2F_I2C0 = 0;
assign IRQ_P2F_SPI0 = 0;
assign IRQ_P2F_UART0 = 0;
assign IRQ_P2F_CAN0 = 0;
assign IRQ_P2F_USB1 = 0;
assign IRQ_P2F_ENET1 = 0;
assign IRQ_P2F_ENET_WAKE1 = 0;
assign IRQ_P2F_SDIO1 = 0;
assign IRQ_P2F_I2C1 = 0;
assign IRQ_P2F_SPI1 = 0;
assign IRQ_P2F_UART1 = 0;
assign IRQ_P2F_CAN1 = 0;
