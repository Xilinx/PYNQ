`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Xilinx Inc
// Design Name: MIPY_ZYBO_DEBUG
// Module Name: top
// Project Name: MIPY
// Target Devices: ZC7010
// Tool Versions: 2015.4
// Description: 
//////////////////////////////////////////////////////////////////////////////////

module top(
    BCLK,
    DDR_addr,
    DDR_ba,
    DDR_cas_n,
    DDR_ck_n,
    DDR_ck_p,
    DDR_cke,
    DDR_cs_n,
    DDR_dm,
    DDR_dq,
    DDR_dqs_n,
    DDR_dqs_p,
    DDR_odt,
    DDR_ras_n,
    DDR_reset_n,
    DDR_we_n,
    FIXED_IO_ddr_vrn,
    FIXED_IO_ddr_vrp,
    FCLK_CLK3,
    FIXED_IO_mio,
    FIXED_IO_ps_clk,
    FIXED_IO_ps_porb,
    FIXED_IO_ps_srstb,
    btns_4bits_tri_i,
    leds_4bits_tri_o,
    iic_1_scl_io,
    iic_1_sda_io,
    HDMI_OEN,
    PBDATA,
    PBLRCLK,
    RECDAT,
    RECLRCLK,
    TMDS_clk_n,
    TMDS_clk_p,
    TMDS_data_n,
    TMDS_data_p,
    codec_out,
    ddc_scl_io,
    ddc_sda_io,
    hdmi_hpd_tri_o,
    pmodJB,
    vga_b,
    vga_g,
    vga_hs,
    vga_r,
    vga_vs,
    sws_4bits_tri_i);
  output BCLK;
  inout [14:0]DDR_addr;
  inout [2:0]DDR_ba;
  inout DDR_cas_n;
  inout DDR_ck_n;
  inout DDR_ck_p;
  inout DDR_cke;
  inout DDR_cs_n;
  inout [3:0]DDR_dm;
  inout [31:0]DDR_dq;
  inout [3:0]DDR_dqs_n;
  inout [3:0]DDR_dqs_p;
  inout DDR_odt;
  inout DDR_ras_n;
  inout DDR_reset_n;
  inout DDR_we_n;
  inout FIXED_IO_ddr_vrn;
  inout FIXED_IO_ddr_vrp;
  inout [53:0]FIXED_IO_mio;
  inout FIXED_IO_ps_clk;
  inout FIXED_IO_ps_porb;
  inout FIXED_IO_ps_srstb;
  inout iic_1_scl_io;
  inout iic_1_sda_io;
  input [3:0]btns_4bits_tri_i;
  output [3:0]leds_4bits_tri_o;
  output [0:0]HDMI_OEN;
  output PBDATA;
  output PBLRCLK;
  input RECDAT;
  output RECLRCLK;
  output FCLK_CLK3;
  output [0:0] codec_out;
  input TMDS_clk_n;
  input TMDS_clk_p;
  input [2:0]TMDS_data_n;
  input [2:0]TMDS_data_p;
  inout ddc_scl_io;
  inout ddc_sda_io;
  output [0:0]hdmi_hpd_tri_o;
  input [3:0]sws_4bits_tri_i;
  inout [7:0]pmodJB;
  output [4:0]vga_b;
  output [5:0]vga_g;
  output vga_hs;
  output [4:0]vga_r;
  output vga_vs;

  wire BCLK;
  wire [14:0]DDR_addr;
  wire [2:0]DDR_ba;
  wire DDR_cas_n;
  wire DDR_ck_n;
  wire DDR_ck_p;
  wire DDR_cke;
  wire DDR_cs_n;
  wire [3:0]DDR_dm;
  wire [31:0]DDR_dq;
  wire [3:0]DDR_dqs_n;
  wire [3:0]DDR_dqs_p;
  wire DDR_odt;
  wire DDR_ras_n;
  wire DDR_reset_n;
  wire DDR_we_n;
  wire FCLK_CLK3;
  wire FIXED_IO_ddr_vrn;
  wire FIXED_IO_ddr_vrp;
  wire [53:0]FIXED_IO_mio;
  wire FIXED_IO_ps_clk;
  wire FIXED_IO_ps_porb;
  wire FIXED_IO_ps_srstb;
  wire [0:0]HDMI_OEN;
  wire PBDATA;
  wire PBLRCLK;
  wire RECDAT;
  wire RECLRCLK;
  wire [0:0]codec_out;
  wire TMDS_clk_n;
  wire TMDS_clk_p;
  wire [2:0]TMDS_data_n;
  wire [2:0]TMDS_data_p;
  wire ddc_scl_i;
  wire ddc_scl_io;
  wire ddc_scl_o;
  wire ddc_scl_t;
  wire ddc_sda_i;
  wire ddc_sda_io;
  wire ddc_sda_o;
  wire ddc_sda_t;
  wire [0:0]hdmi_hpd_tri_o;
  wire iic_1_scl_i;
  wire iic_1_scl_io;
  wire iic_1_scl_o;
  wire iic_1_scl_t;
  wire iic_1_sda_i;
  wire iic_1_sda_io;
  wire iic_1_sda_o;
  wire iic_1_sda_t;
  wire [3:0]btns_4bits_tri_i;
  wire [3:0]leds_4bits_tri_o;
  wire [3:0]sws_4bits_tri_i;
  wire [7:0]pmodJB_data_in;
  wire [7:0]pmodJB_data_out;
  wire [7:0]pmodJB_tri_out;
  wire [7:0]pmodJB;
  wire [4:0]vga_b;
  wire [5:0]vga_g;
  wire vga_hs;
  wire [4:0]vga_r;
  wire vga_vs;

// IIC0 (from PS) for HDMI
  IOBUF ddc_scl_iobuf
       (.I(ddc_scl_o),
        .IO(ddc_scl_io),
        .O(ddc_scl_i),
        .T(ddc_scl_t));
  IOBUF ddc_sda_iobuf
       (.I(ddc_sda_o),
        .IO(ddc_sda_io),
        .O(ddc_sda_i),
        .T(ddc_sda_t));

// IIC1 (from PS) for audio CODEC
  IOBUF iic_1_scl_iobuf
       (.I(iic_1_scl_o),
        .IO(iic_1_scl_io),
        .O(iic_1_scl_i),
        .T(iic_1_scl_t));
  IOBUF iic_1_sda_iobuf
       (.I(iic_1_sda_o),
        .IO(iic_1_sda_io),
        .O(iic_1_sda_i),
        .T(iic_1_sda_t));

// pmodJB related iobufs
  IOBUF pmodJB_data_iobuf_0
       (.I(pmodJB_data_out[0]),
        .IO(pmodJB[0]),
        .O(pmodJB_data_in[0]),
        .T(pmodJB_tri_out[0]));
  IOBUF pmodJB_data_iobuf_1
       (.I(pmodJB_data_out[1]),
        .IO(pmodJB[1]),
        .O(pmodJB_data_in[1]),
        .T(pmodJB_tri_out[1]));
  IOBUF pmodJB_data_iobuf2
       (.I(pmodJB_data_out[2]),
        .IO(pmodJB[2]),
        .O(pmodJB_data_in[2]),
        .T(pmodJB_tri_out[2]));
  IOBUF pmodJB_data_iobuf_3
       (.I(pmodJB_data_out[3]),
        .IO(pmodJB[3]),
        .O(pmodJB_data_in[3]),
        .T(pmodJB_tri_out[3]));
  IOBUF pmodJB_data_iobuf_4
       (.I(pmodJB_data_out[4]),
        .IO(pmodJB[4]),
        .O(pmodJB_data_in[4]),
        .T(pmodJB_tri_out[4]));
  IOBUF pmodJB_data_iobuf_5
       (.I(pmodJB_data_out[5]),
        .IO(pmodJB[5]),
        .O(pmodJB_data_in[5]),
        .T(pmodJB_tri_out[5]));
  IOBUF pmodJB_data_iobuf_6
       (.I(pmodJB_data_out[6]),
        .IO(pmodJB[6]),
        .O(pmodJB_data_in[6]),
        .T(pmodJB_tri_out[6]));
  IOBUF pmodJB_data_iobuf_7
       (.I(pmodJB_data_out[7]),
        .IO(pmodJB[7]),
        .O(pmodJB_data_in[7]),
        .T(pmodJB_tri_out[7]));

  system system_i
       (.BCLK(BCLK),
        .DDC_scl_i(ddc_scl_i),
        .DDC_scl_o(ddc_scl_o),
        .DDC_scl_t(ddc_scl_t),
        .DDC_sda_i(ddc_sda_i),
        .DDC_sda_o(ddc_sda_o),
        .DDC_sda_t(ddc_sda_t),
        .DDR_addr(DDR_addr),
        .DDR_ba(DDR_ba),
        .DDR_cas_n(DDR_cas_n),
        .DDR_ck_n(DDR_ck_n),
        .DDR_ck_p(DDR_ck_p),
        .DDR_cke(DDR_cke),
        .DDR_cs_n(DDR_cs_n),
        .DDR_dm(DDR_dm),
        .DDR_dq(DDR_dq),
        .DDR_dqs_n(DDR_dqs_n),
        .DDR_dqs_p(DDR_dqs_p),
        .DDR_odt(DDR_odt),
        .DDR_ras_n(DDR_ras_n),
        .DDR_reset_n(DDR_reset_n),
        .DDR_we_n(DDR_we_n),
        .FCLK_CLK3(FCLK_CLK3),
        .FIXED_IO_ddr_vrn(FIXED_IO_ddr_vrn),
        .FIXED_IO_ddr_vrp(FIXED_IO_ddr_vrp),
        .FIXED_IO_mio(FIXED_IO_mio),
        .FIXED_IO_ps_clk(FIXED_IO_ps_clk),
        .FIXED_IO_ps_porb(FIXED_IO_ps_porb),
        .FIXED_IO_ps_srstb(FIXED_IO_ps_srstb),
        .IIC_1_scl_i(iic_1_scl_i),
        .IIC_1_scl_o(iic_1_scl_o),
        .IIC_1_scl_t(iic_1_scl_t),
        .IIC_1_sda_i(iic_1_sda_i),
        .IIC_1_sda_o(iic_1_sda_o),
        .IIC_1_sda_t(iic_1_sda_t),
        .HDMI_OEN(HDMI_OEN),
        .PBDATA(PBDATA),
        .PBLRCLK(PBLRCLK),
        .RECDAT(RECDAT),
        .RECLRCLK(RECLRCLK),
        .codec_out(codec_out),
        .TMDS_clk_n(TMDS_clk_n),
        .TMDS_clk_p(TMDS_clk_p),
        .TMDS_data_n(TMDS_data_n),
        .TMDS_data_p(TMDS_data_p),
        .hdmi_hpd_tri_o(hdmi_hpd_tri_o),
        .btns_4bits_tri_i(btns_4bits_tri_i),
        .leds_4bits_tri_o(leds_4bits_tri_o),
        .pmodJB_data_in(pmodJB_data_in),
        .pmodJB_data_out(pmodJB_data_out),
        .pmodJB_tri_out(pmodJB_tri_out),
        .vga_b(vga_b),
        .vga_g(vga_g),
        .vga_hs(vga_hs),
        .vga_r(vga_r),
        .vga_vs(vga_vs),
        .sws_4bits_tri_i(sws_4bits_tri_i));
        
endmodule
