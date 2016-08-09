`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Xilinx Inc
// Design Name: PYNQ
// Module Name: top
// Project Name: PYNQ
// Target Devices: ZC7020
// Tool Versions: 2016.1
// Description: 
//////////////////////////////////////////////////////////////////////////////////

module top(
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
    FIXED_IO_mio,
    FIXED_IO_ps_clk,
    FIXED_IO_ps_porb,
    FIXED_IO_ps_srstb,
    Vaux13_v_n,
    Vaux13_v_p,
    Vaux15_v_n,
    Vaux15_v_p,
    Vaux1_v_n,
    Vaux1_v_p,
    Vaux5_v_n,
    Vaux5_v_p,
    Vaux6_v_n,
    Vaux6_v_p,
    Vaux9_v_n,
    Vaux9_v_p,
    Vp_Vn_v_n,
    Vp_Vn_v_p,
    btns_4bits_tri_i,
    gpio_shield_sw_a5_a0_tri_io,
    gpio_shield_sw_d13_d2_tri_io,
    gpio_shield_sw_d1_d0_tri_io,
    hdmi_in_clk_n,
    hdmi_in_clk_p,
    hdmi_in_data_n,
    hdmi_in_data_p,
    hdmi_in_ddc_scl_io,
    hdmi_in_ddc_sda_io,
    hdmi_in_hpd,
    hdmi_out_clk_n,
    hdmi_out_clk_p,
    hdmi_out_data_n,
    hdmi_out_data_p,
    hdmi_out_ddc_scl_io,
    hdmi_out_ddc_sda_io,
    hdmi_out_hpd,
    iic_sw_shield_scl_io,
    iic_sw_shield_sda_io,
    leds_4bits_tri_o,
    spi_sw_shield_io0_io,
    spi_sw_shield_io1_io,
    spi_sw_shield_sck_io,
    spi_sw_shield_ss_io,
    pmodJA,
    pmodJB,
    pdm_audio_shutdown,
    pdm_m_clk,
    pdm_m_data_i,
    pwm_audio_o,
    rgbleds_6bits_tri_o,
    sws_2bits_tri_i);
    
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
  input Vaux13_v_n;
  input Vaux13_v_p;
  input Vaux15_v_n;
  input Vaux15_v_p;
  input Vaux1_v_n;
  input Vaux1_v_p;
  input Vaux5_v_n;
  input Vaux5_v_p;
  input Vaux6_v_n;
  input Vaux6_v_p;
  input Vaux9_v_n;
  input Vaux9_v_p;
  input Vp_Vn_v_n;
  input Vp_Vn_v_p;
  input [3:0]btns_4bits_tri_i;
  inout [5:0]gpio_shield_sw_a5_a0_tri_io;
  inout [11:0]gpio_shield_sw_d13_d2_tri_io;
  inout [1:0]gpio_shield_sw_d1_d0_tri_io;
  input hdmi_in_clk_n;
  input hdmi_in_clk_p;
  input [2:0]hdmi_in_data_n;
  input [2:0]hdmi_in_data_p;
  inout hdmi_in_ddc_scl_io;
  inout hdmi_in_ddc_sda_io;
  output [0:0]hdmi_in_hpd;
  output hdmi_out_clk_n;
  output hdmi_out_clk_p;
  output [2:0]hdmi_out_data_n;
  output [2:0]hdmi_out_data_p;
  inout hdmi_out_ddc_scl_io;
  inout hdmi_out_ddc_sda_io;
  output [0:0]hdmi_out_hpd;
  inout iic_sw_shield_scl_io;
  inout iic_sw_shield_sda_io;
  output [3:0]leds_4bits_tri_o;
  input [1:0]sws_2bits_tri_i;
  inout spi_sw_shield_io0_io;
  inout spi_sw_shield_io1_io;
  inout spi_sw_shield_sck_io;
  inout spi_sw_shield_ss_io;
  inout [7:0]pmodJA;
  inout [7:0]pmodJB;
  output [0:0]pdm_audio_shutdown;
  output [0:0]pdm_m_clk;
  input pdm_m_data_i;
  output [5:0]rgbleds_6bits_tri_o;
  output [0:0]pwm_audio_o;
  
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
  wire FIXED_IO_ddr_vrn;
  wire FIXED_IO_ddr_vrp;
  wire [53:0]FIXED_IO_mio;
  wire FIXED_IO_ps_clk;
  wire FIXED_IO_ps_porb;
  wire FIXED_IO_ps_srstb;
  wire Vaux13_v_n;
  wire Vaux13_v_p;
  wire Vaux15_v_n;
  wire Vaux15_v_p;
  wire Vaux1_v_n;
  wire Vaux1_v_p;
  wire Vaux5_v_n;
  wire Vaux5_v_p;
  wire Vaux6_v_n;
  wire Vaux6_v_p;
  wire Vaux9_v_n;
  wire Vaux9_v_p;
  wire Vp_Vn_v_n;
  wire Vp_Vn_v_p;
  wire [3:0]btns_4bits_tri_i;
  wire [5:0]shield2sw_data_in_a5_a0;
  wire [11:0]shield2sw_data_in_d13_d2;
  wire [1:0]shield2sw_data_in_d1_d0;
  wire [5:0]sw2shield_data_out_a5_a0;
  wire [11:0]sw2shield_data_out_d13_d2;
  wire [1:0]sw2shield_data_out_d1_d0;
  wire [5:0]sw2shield_tri_out_a5_a0;
  wire [11:0]sw2shield_tri_out_d13_d2;
  wire [1:0]sw2shield_tri_out_d1_d0;

//  wire [0:0]gpio_shield_sw_a5_a0_tri_i_0;
//  wire [1:1]gpio_shield_sw_a5_a0_tri_i_1;
//  wire [2:2]gpio_shield_sw_a5_a0_tri_i_2;
//  wire [3:3]gpio_shield_sw_a5_a0_tri_i_3;
//  wire [4:4]gpio_shield_sw_a5_a0_tri_i_4;
//  wire [5:5]gpio_shield_sw_a5_a0_tri_i_5;
//  wire [0:0]gpio_shield_sw_a5_a0_tri_io_0;
//  wire [1:1]gpio_shield_sw_a5_a0_tri_io_1;
//  wire [2:2]gpio_shield_sw_a5_a0_tri_io_2;
//  wire [3:3]gpio_shield_sw_a5_a0_tri_io_3;
//  wire [4:4]gpio_shield_sw_a5_a0_tri_io_4;
//  wire [5:5]gpio_shield_sw_a5_a0_tri_io_5;
//  wire [0:0]gpio_shield_sw_a5_a0_tri_o_0;
//  wire [1:1]gpio_shield_sw_a5_a0_tri_o_1;
//  wire [2:2]gpio_shield_sw_a5_a0_tri_o_2;
//  wire [3:3]gpio_shield_sw_a5_a0_tri_o_3;
//  wire [4:4]gpio_shield_sw_a5_a0_tri_o_4;
//  wire [5:5]gpio_shield_sw_a5_a0_tri_o_5;
//  wire [0:0]gpio_shield_sw_a5_a0_tri_t_0;
//  wire [1:1]gpio_shield_sw_a5_a0_tri_t_1;
//  wire [2:2]gpio_shield_sw_a5_a0_tri_t_2;
//  wire [3:3]gpio_shield_sw_a5_a0_tri_t_3;
//  wire [4:4]gpio_shield_sw_a5_a0_tri_t_4;
//  wire [5:5]gpio_shield_sw_a5_a0_tri_t_5;
//  wire [0:0]gpio_shield_sw_d13_d2_tri_i_0;
//  wire [1:1]gpio_shield_sw_d13_d2_tri_i_1;
//  wire [10:10]gpio_shield_sw_d13_d2_tri_i_10;
//  wire [11:11]gpio_shield_sw_d13_d2_tri_i_11;
//  wire [2:2]gpio_shield_sw_d13_d2_tri_i_2;
//  wire [3:3]gpio_shield_sw_d13_d2_tri_i_3;
//  wire [4:4]gpio_shield_sw_d13_d2_tri_i_4;
//  wire [5:5]gpio_shield_sw_d13_d2_tri_i_5;
//  wire [6:6]gpio_shield_sw_d13_d2_tri_i_6;
//  wire [7:7]gpio_shield_sw_d13_d2_tri_i_7;
//  wire [8:8]gpio_shield_sw_d13_d2_tri_i_8;
//  wire [9:9]gpio_shield_sw_d13_d2_tri_i_9;
//  wire [0:0]gpio_shield_sw_d13_d2_tri_io_0;
//  wire [1:1]gpio_shield_sw_d13_d2_tri_io_1;
//  wire [10:10]gpio_shield_sw_d13_d2_tri_io_10;
//  wire [11:11]gpio_shield_sw_d13_d2_tri_io_11;
//  wire [2:2]gpio_shield_sw_d13_d2_tri_io_2;
//  wire [3:3]gpio_shield_sw_d13_d2_tri_io_3;
//  wire [4:4]gpio_shield_sw_d13_d2_tri_io_4;
//  wire [5:5]gpio_shield_sw_d13_d2_tri_io_5;
//  wire [6:6]gpio_shield_sw_d13_d2_tri_io_6;
//  wire [7:7]gpio_shield_sw_d13_d2_tri_io_7;
//  wire [8:8]gpio_shield_sw_d13_d2_tri_io_8;
//  wire [9:9]gpio_shield_sw_d13_d2_tri_io_9;
//  wire [0:0]gpio_shield_sw_d13_d2_tri_o_0;
//  wire [1:1]gpio_shield_sw_d13_d2_tri_o_1;
//  wire [10:10]gpio_shield_sw_d13_d2_tri_o_10;
//  wire [11:11]gpio_shield_sw_d13_d2_tri_o_11;
//  wire [2:2]gpio_shield_sw_d13_d2_tri_o_2;
//  wire [3:3]gpio_shield_sw_d13_d2_tri_o_3;
//  wire [4:4]gpio_shield_sw_d13_d2_tri_o_4;
//  wire [5:5]gpio_shield_sw_d13_d2_tri_o_5;
//  wire [6:6]gpio_shield_sw_d13_d2_tri_o_6;
//  wire [7:7]gpio_shield_sw_d13_d2_tri_o_7;
//  wire [8:8]gpio_shield_sw_d13_d2_tri_o_8;
//  wire [9:9]gpio_shield_sw_d13_d2_tri_o_9;
//  wire [0:0]gpio_shield_sw_d13_d2_tri_t_0;
//  wire [1:1]gpio_shield_sw_d13_d2_tri_t_1;
//  wire [10:10]gpio_shield_sw_d13_d2_tri_t_10;
//  wire [11:11]gpio_shield_sw_d13_d2_tri_t_11;
//  wire [2:2]gpio_shield_sw_d13_d2_tri_t_2;
//  wire [3:3]gpio_shield_sw_d13_d2_tri_t_3;
//  wire [4:4]gpio_shield_sw_d13_d2_tri_t_4;
//  wire [5:5]gpio_shield_sw_d13_d2_tri_t_5;
//  wire [6:6]gpio_shield_sw_d13_d2_tri_t_6;
//  wire [7:7]gpio_shield_sw_d13_d2_tri_t_7;
//  wire [8:8]gpio_shield_sw_d13_d2_tri_t_8;
//  wire [9:9]gpio_shield_sw_d13_d2_tri_t_9;
//  wire [0:0]gpio_shield_sw_d1_d0_tri_i_0;
//  wire [1:1]gpio_shield_sw_d1_d0_tri_i_1;
//  wire [0:0]gpio_shield_sw_d1_d0_tri_io_0;
//  wire [1:1]gpio_shield_sw_d1_d0_tri_io_1;
//  wire [0:0]gpio_shield_sw_d1_d0_tri_o_0;
//  wire [1:1]gpio_shield_sw_d1_d0_tri_o_1;
//  wire [0:0]gpio_shield_sw_d1_d0_tri_t_0;
//  wire [1:1]gpio_shield_sw_d1_d0_tri_t_1;
  wire hdmi_in_clk_n;
  wire hdmi_in_clk_p;
  wire [2:0]hdmi_in_data_n;
  wire [2:0]hdmi_in_data_p;
  wire hdmi_in_ddc_scl_i;
  wire hdmi_in_ddc_scl_io;
  wire hdmi_in_ddc_scl_o;
  wire hdmi_in_ddc_scl_t;
  wire hdmi_in_ddc_sda_i;
  wire hdmi_in_ddc_sda_io;
  wire hdmi_in_ddc_sda_o;
  wire hdmi_in_ddc_sda_t;
  wire [0:0]hdmi_in_hpd;
  wire hdmi_out_clk_n;
  wire hdmi_out_clk_p;
  wire [2:0]hdmi_out_data_n;
  wire [2:0]hdmi_out_data_p;
  wire hdmi_out_ddc_scl_i;
  wire hdmi_out_ddc_scl_io;
  wire hdmi_out_ddc_scl_o;
  wire hdmi_out_ddc_scl_t;
  wire hdmi_out_ddc_sda_i;
  wire hdmi_out_ddc_sda_io;
  wire hdmi_out_ddc_sda_o;
  wire hdmi_out_ddc_sda_t;
  wire [0:0]hdmi_out_hpd;
  wire shield2sw_scl_i_in;
  wire shield2sw_sda_i_in;
  wire sw2shield_scl_o_out;
  wire sw2shield_scl_t_out;
  wire sw2shield_sda_o_out;
  wire sw2shield_sda_t_out;

//  wire iic_sw_shield_scl_i;
  wire iic_sw_shield_scl_io;
//  wire iic_sw_shield_scl_o;
//  wire iic_sw_shield_scl_t;
//  wire iic_sw_shield_sda_i;
  wire iic_sw_shield_sda_io;
//  wire iic_sw_shield_sda_o;
//  wire iic_sw_shield_sda_t;
  wire [3:0]leds_4bits_tri_o;
  wire [7:0]pmodJA_data_in;
  wire [7:0]pmodJA_data_out;
  wire [7:0]pmodJA_tri_out;
  wire [7:0]pmodJB_data_in;
  wire [7:0]pmodJB_data_out;
  wire [7:0]pmodJB_tri_out;
  wire spi_sw_shield_io0_i;
  wire spi_sw_shield_io0_io;
  wire spi_sw_shield_io0_o;
  wire spi_sw_shield_io0_t;
  wire spi_sw_shield_io1_i;
  wire spi_sw_shield_io1_io;
  wire spi_sw_shield_io1_o;
  wire spi_sw_shield_io1_t;
  wire spi_sw_shield_sck_i;
  wire spi_sw_shield_sck_io;
  wire spi_sw_shield_sck_o;
  wire spi_sw_shield_sck_t;
  wire spi_sw_shield_ss_i;
  wire spi_sw_shield_ss_io;
  wire spi_sw_shield_ss_o;
  wire spi_sw_shield_ss_t;
  wire [1:0]sws_2bits_tri_i;  
  wire [7:0]pmodJA;
  wire [7:0]pmodJB;
  wire [0:0]pdm_audio_shutdown;
  wire [0:0]pdm_m_clk;
  wire pdm_m_data_i;
  wire [5:0]rgbleds_6bits_tri_o;
  wire [0:0]pwm_audio_o;

// for HDMI in
IOBUF hdmi_in_ddc_scl_iobuf
 (.I(hdmi_in_ddc_scl_o),
  .IO(hdmi_in_ddc_scl_io),
  .O(hdmi_in_ddc_scl_i),
  .T(hdmi_in_ddc_scl_t));
IOBUF hdmi_in_ddc_sda_iobuf
 (.I(hdmi_in_ddc_sda_o),
  .IO(hdmi_in_ddc_sda_io),
  .O(hdmi_in_ddc_sda_i),
  .T(hdmi_in_ddc_sda_t));
// for HDMI out
IOBUF hdmi_out_ddc_scl_iobuf
   (.I(hdmi_out_ddc_scl_o),
    .IO(hdmi_out_ddc_scl_io),
    .O(hdmi_out_ddc_scl_i),
    .T(hdmi_out_ddc_scl_t));
IOBUF hdmi_out_ddc_sda_iobuf
   (.I(hdmi_out_ddc_sda_o),
    .IO(hdmi_out_ddc_sda_io),
    .O(hdmi_out_ddc_sda_i),
    .T(hdmi_out_ddc_sda_t));
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
// pmodJA related iobufs
IOBUF pmodJA_data_iobuf_0
     (.I(pmodJA_data_out[0]),
      .IO(pmodJA[0]),
      .O(pmodJA_data_in[0]),
      .T(pmodJA_tri_out[0]));
IOBUF pmodJA_data_iobuf_1
     (.I(pmodJA_data_out[1]),
      .IO(pmodJA[1]),
      .O(pmodJA_data_in[1]),
      .T(pmodJA_tri_out[1]));
IOBUF pmodJA_data_iobuf2
     (.I(pmodJA_data_out[2]),
      .IO(pmodJA[2]),
      .O(pmodJA_data_in[2]),
      .T(pmodJA_tri_out[2]));
IOBUF pmodJA_data_iobuf_3
     (.I(pmodJA_data_out[3]),
      .IO(pmodJA[3]),
      .O(pmodJA_data_in[3]),
      .T(pmodJA_tri_out[3]));
IOBUF pmodJA_data_iobuf_4
     (.I(pmodJA_data_out[4]),
      .IO(pmodJA[4]),
      .O(pmodJA_data_in[4]),
      .T(pmodJA_tri_out[4]));
IOBUF pmodJA_data_iobuf_5
     (.I(pmodJA_data_out[5]),
      .IO(pmodJA[5]),
      .O(pmodJA_data_in[5]),
      .T(pmodJA_tri_out[5]));
IOBUF pmodJA_data_iobuf_6
     (.I(pmodJA_data_out[6]),
      .IO(pmodJA[6]),
      .O(pmodJA_data_in[6]),
      .T(pmodJA_tri_out[6]));
IOBUF pmodJA_data_iobuf_7
     (.I(pmodJA_data_out[7]),
      .IO(pmodJA[7]),
      .O(pmodJA_data_in[7]),
      .T(pmodJA_tri_out[7]));        
// Arduino shield related iobufs
IOBUF gpio_shield_sw_a5_a0_tri_iobuf_0
     (.I(sw2shield_data_out_a5_a0[0]),
      .IO(gpio_shield_sw_a5_a0_tri_io[0]),
      .O(shield2sw_data_in_a5_a0[0]),
      .T(sw2shield_tri_out_a5_a0[0]));
IOBUF gpio_shield_sw_a5_a0_tri_iobuf_1
     (.I(sw2shield_data_out_a5_a0[1]),
      .IO(gpio_shield_sw_a5_a0_tri_io[1]),
      .O(shield2sw_data_in_a5_a0[1]),
      .T(sw2shield_tri_out_a5_a0[1]));
IOBUF gpio_shield_sw_a5_a0_tri_iobuf_2
     (.I(sw2shield_data_out_a5_a0[2]),
      .IO(gpio_shield_sw_a5_a0_tri_io[2]),
      .O(shield2sw_data_in_a5_a0[2]),
      .T(sw2shield_tri_out_a5_a0[2]));
IOBUF gpio_shield_sw_a5_a0_tri_iobuf_3
     (.I(sw2shield_data_out_a5_a0[3]),
      .IO(gpio_shield_sw_a5_a0_tri_io[3]),
      .O(shield2sw_data_in_a5_a0[3]),
      .T(sw2shield_tri_out_a5_a0[3]));
IOBUF gpio_shield_sw_a5_a0_tri_iobuf_4
     (.I(sw2shield_data_out_a5_a0[4]),
      .IO(gpio_shield_sw_a5_a0_tri_io[4]),
      .O(shield2sw_data_in_a5_a0[4]),
      .T(sw2shield_tri_out_a5_a0[4]));
IOBUF gpio_shield_sw_a5_a0_tri_iobuf_5
     (.I(sw2shield_data_out_a5_a0[5]),
      .IO(gpio_shield_sw_a5_a0_tri_io[5]),
      .O(shield2sw_data_in_a5_a0[5]),
      .T(sw2shield_tri_out_a5_a0[5]));
IOBUF gpio_shield_sw_d13_d2_tri_iobuf_0
     (.I(sw2shield_data_out_d13_d2[0]),
      .IO(gpio_shield_sw_d13_d2_tri_io[0]),
      .O(shield2sw_data_in_d13_d2[0]),
      .T(sw2shield_tri_out_d13_d2[0]));
IOBUF gpio_shield_sw_d13_d2_tri_iobuf_1
     (.I(sw2shield_data_out_d13_d2[1]),
      .IO(gpio_shield_sw_d13_d2_tri_io[1]),
      .O(shield2sw_data_in_d13_d2[1]),
      .T(sw2shield_tri_out_d13_d2[1]));
IOBUF gpio_shield_sw_d13_d2_tri_iobuf_10
     (.I(sw2shield_data_out_d13_d2[10]),
      .IO(gpio_shield_sw_d13_d2_tri_io[10]),
      .O(shield2sw_data_in_d13_d2[10]),
      .T(sw2shield_tri_out_d13_d2[10]));
IOBUF gpio_shield_sw_d13_d2_tri_iobuf_11
     (.I(sw2shield_data_out_d13_d2[11]),
      .IO(gpio_shield_sw_d13_d2_tri_io[11]),
      .O(shield2sw_data_in_d13_d2[11]),
      .T(sw2shield_tri_out_d13_d2[11]));
IOBUF gpio_shield_sw_d13_d2_tri_iobuf_2
     (.I(sw2shield_data_out_d13_d2[2]),
      .IO(gpio_shield_sw_d13_d2_tri_io[2]),
      .O(shield2sw_data_in_d13_d2[2]),
      .T(sw2shield_tri_out_d13_d2[2]));
IOBUF gpio_shield_sw_d13_d2_tri_iobuf_3
     (.I(sw2shield_data_out_d13_d2[3]),
      .IO(gpio_shield_sw_d13_d2_tri_io[3]),
      .O(shield2sw_data_in_d13_d2[3]),
      .T(sw2shield_tri_out_d13_d2[3]));
IOBUF gpio_shield_sw_d13_d2_tri_iobuf_4
     (.I(sw2shield_data_out_d13_d2[4]),
      .IO(gpio_shield_sw_d13_d2_tri_io[4]),
      .O(shield2sw_data_in_d13_d2[4]),
      .T(sw2shield_tri_out_d13_d2[4]));
IOBUF gpio_shield_sw_d13_d2_tri_iobuf_5
     (.I(sw2shield_data_out_d13_d2[5]),
      .IO(gpio_shield_sw_d13_d2_tri_io[5]),
      .O(shield2sw_data_in_d13_d2[5]),
      .T(sw2shield_tri_out_d13_d2[5]));
IOBUF gpio_shield_sw_d13_d2_tri_iobuf_6
     (.I(sw2shield_data_out_d13_d2[6]),
      .IO(gpio_shield_sw_d13_d2_tri_io[6]),
      .O(shield2sw_data_in_d13_d2[6]),
      .T(sw2shield_tri_out_d13_d2[6]));
IOBUF gpio_shield_sw_d13_d2_tri_iobuf_7
     (.I(sw2shield_data_out_d13_d2[7]),
      .IO(gpio_shield_sw_d13_d2_tri_io[7]),
      .O(shield2sw_data_in_d13_d2[7]),
      .T(sw2shield_tri_out_d13_d2[7]));
IOBUF gpio_shield_sw_d13_d2_tri_iobuf_8
     (.I(sw2shield_data_out_d13_d2[8]),
      .IO(gpio_shield_sw_d13_d2_tri_io[8]),
      .O(shield2sw_data_in_d13_d2[8]),
      .T(sw2shield_tri_out_d13_d2[8]));
IOBUF gpio_shield_sw_d13_d2_tri_iobuf_9
     (.I(sw2shield_data_out_d13_d2[9]),
      .IO(gpio_shield_sw_d13_d2_tri_io[9]),
      .O(shield2sw_data_in_d13_d2[9]),
      .T(sw2shield_tri_out_d13_d2[9]));
IOBUF gpio_shield_sw_d1_d0_tri_iobuf_0
     (.I(sw2shield_data_out_d1_d0[0]),
      .IO(gpio_shield_sw_d1_d0_tri_io[0]),
      .O(shield2sw_data_in_d1_d0[0]),
      .T(sw2shield_tri_out_d1_d0[0]));
IOBUF gpio_shield_sw_d1_d0_tri_iobuf_1
     (.I(sw2shield_data_out_d1_d0[1]),
      .IO(gpio_shield_sw_d1_d0_tri_io[1]),
      .O(shield2sw_data_in_d1_d0[1]),
      .T(sw2shield_tri_out_d1_d0[1]));
// Dedicated Arduino IIC shield2sw_scl_i_in
IOBUF iic_sw_shield_scl_iobuf
     (.I(sw2shield_scl_o_out),
      .IO(iic_sw_shield_scl_io),
      .O(shield2sw_scl_i_in),
      .T(sw2shield_scl_t_out));
IOBUF iic_sw_shield_sda_iobuf
     (.I(sw2shield_sda_o_out),
      .IO(iic_sw_shield_sda_io),
      .O(shield2sw_sda_i_in),
      .T(sw2shield_sda_t_out));
// Dedicated Arduino SPI
IOBUF spi_sw_shield_io0_iobuf
     (.I(spi_sw_shield_io0_o),
      .IO(spi_sw_shield_io0_io),
      .O(spi_sw_shield_io0_i),
      .T(spi_sw_shield_io0_t));
IOBUF spi_sw_shield_io1_iobuf
     (.I(spi_sw_shield_io1_o),
      .IO(spi_sw_shield_io1_io),
      .O(spi_sw_shield_io1_i),
      .T(spi_sw_shield_io1_t));
IOBUF spi_sw_shield_sck_iobuf
     (.I(spi_sw_shield_sck_o),
      .IO(spi_sw_shield_sck_io),
      .O(spi_sw_shield_sck_i),
      .T(spi_sw_shield_sck_t));
IOBUF spi_sw_shield_ss_iobuf
     (.I(spi_sw_shield_ss_o),
      .IO(spi_sw_shield_ss_io),
      .O(spi_sw_shield_ss_i),
      .T(spi_sw_shield_ss_t));                          

system system_i
   (.DDR_addr(DDR_addr),
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
    .FIXED_IO_ddr_vrn(FIXED_IO_ddr_vrn),
    .FIXED_IO_ddr_vrp(FIXED_IO_ddr_vrp),
    .FIXED_IO_mio(FIXED_IO_mio),
    .FIXED_IO_ps_clk(FIXED_IO_ps_clk),
    .FIXED_IO_ps_porb(FIXED_IO_ps_porb),
    .FIXED_IO_ps_srstb(FIXED_IO_ps_srstb),
    .Vaux13_v_n(Vaux13_v_n),
    .Vaux13_v_p(Vaux13_v_p),
    .Vaux15_v_n(Vaux15_v_n),
    .Vaux15_v_p(Vaux15_v_p),
    .Vaux1_v_n(Vaux1_v_n),
    .Vaux1_v_p(Vaux1_v_p),
    .Vaux5_v_n(Vaux5_v_n),
    .Vaux5_v_p(Vaux5_v_p),
    .Vaux6_v_n(Vaux6_v_n),
    .Vaux6_v_p(Vaux6_v_p),
    .Vaux9_v_n(Vaux9_v_n),
    .Vaux9_v_p(Vaux9_v_p),
    .Vp_Vn_v_n(Vp_Vn_v_n),
    .Vp_Vn_v_p(Vp_Vn_v_p),
    .btns_4bits_tri_i(btns_4bits_tri_i),
//    .gpio_shield_sw_a5_a0_tri_i({gpio_shield_sw_a5_a0_tri_i_5,gpio_shield_sw_a5_a0_tri_i_4,gpio_shield_sw_a5_a0_tri_i_3,gpio_shield_sw_a5_a0_tri_i_2,gpio_shield_sw_a5_a0_tri_i_1,gpio_shield_sw_a5_a0_tri_i_0}),
//    .gpio_shield_sw_a5_a0_tri_o({gpio_shield_sw_a5_a0_tri_o_5,gpio_shield_sw_a5_a0_tri_o_4,gpio_shield_sw_a5_a0_tri_o_3,gpio_shield_sw_a5_a0_tri_o_2,gpio_shield_sw_a5_a0_tri_o_1,gpio_shield_sw_a5_a0_tri_o_0}),
//    .gpio_shield_sw_a5_a0_tri_t({gpio_shield_sw_a5_a0_tri_t_5,gpio_shield_sw_a5_a0_tri_t_4,gpio_shield_sw_a5_a0_tri_t_3,gpio_shield_sw_a5_a0_tri_t_2,gpio_shield_sw_a5_a0_tri_t_1,gpio_shield_sw_a5_a0_tri_t_0}),
//    .gpio_shield_sw_d13_d2_tri_i({gpio_shield_sw_d13_d2_tri_i_11,gpio_shield_sw_d13_d2_tri_i_10,gpio_shield_sw_d13_d2_tri_i_9,gpio_shield_sw_d13_d2_tri_i_8,gpio_shield_sw_d13_d2_tri_i_7,gpio_shield_sw_d13_d2_tri_i_6,gpio_shield_sw_d13_d2_tri_i_5,gpio_shield_sw_d13_d2_tri_i_4,gpio_shield_sw_d13_d2_tri_i_3,gpio_shield_sw_d13_d2_tri_i_2,gpio_shield_sw_d13_d2_tri_i_1,gpio_shield_sw_d13_d2_tri_i_0}),
//    .gpio_shield_sw_d13_d2_tri_o({gpio_shield_sw_d13_d2_tri_o_11,gpio_shield_sw_d13_d2_tri_o_10,gpio_shield_sw_d13_d2_tri_o_9,gpio_shield_sw_d13_d2_tri_o_8,gpio_shield_sw_d13_d2_tri_o_7,gpio_shield_sw_d13_d2_tri_o_6,gpio_shield_sw_d13_d2_tri_o_5,gpio_shield_sw_d13_d2_tri_o_4,gpio_shield_sw_d13_d2_tri_o_3,gpio_shield_sw_d13_d2_tri_o_2,gpio_shield_sw_d13_d2_tri_o_1,gpio_shield_sw_d13_d2_tri_o_0}),
//    .gpio_shield_sw_d13_d2_tri_t({gpio_shield_sw_d13_d2_tri_t_11,gpio_shield_sw_d13_d2_tri_t_10,gpio_shield_sw_d13_d2_tri_t_9,gpio_shield_sw_d13_d2_tri_t_8,gpio_shield_sw_d13_d2_tri_t_7,gpio_shield_sw_d13_d2_tri_t_6,gpio_shield_sw_d13_d2_tri_t_5,gpio_shield_sw_d13_d2_tri_t_4,gpio_shield_sw_d13_d2_tri_t_3,gpio_shield_sw_d13_d2_tri_t_2,gpio_shield_sw_d13_d2_tri_t_1,gpio_shield_sw_d13_d2_tri_t_0}),
//    .gpio_shield_sw_d1_d0_tri_i({gpio_shield_sw_d1_d0_tri_i_1,gpio_shield_sw_d1_d0_tri_i_0}),
//    .gpio_shield_sw_d1_d0_tri_o({gpio_shield_sw_d1_d0_tri_o_1,gpio_shield_sw_d1_d0_tri_o_0}),
//    .gpio_shield_sw_d1_d0_tri_t({gpio_shield_sw_d1_d0_tri_t_1,gpio_shield_sw_d1_d0_tri_t_0}),
    .shield2sw_data_in_a5_a0(shield2sw_data_in_a5_a0),
    .shield2sw_data_in_d13_d2(shield2sw_data_in_d13_d2),
    .shield2sw_data_in_d1_d0(shield2sw_data_in_d1_d0),
    .sw2shield_data_out_a5_a0(sw2shield_data_out_a5_a0),
    .sw2shield_data_out_d13_d2(sw2shield_data_out_d13_d2),
    .sw2shield_data_out_d1_d0(sw2shield_data_out_d1_d0),
    .sw2shield_tri_out_a5_a0(sw2shield_tri_out_a5_a0),
    .sw2shield_tri_out_d13_d2(sw2shield_tri_out_d13_d2),
    .sw2shield_tri_out_d1_d0(sw2shield_tri_out_d1_d0),
    .hdmi_in_clk_n(hdmi_in_clk_n),
    .hdmi_in_clk_p(hdmi_in_clk_p),
    .hdmi_in_data_n(hdmi_in_data_n),
    .hdmi_in_data_p(hdmi_in_data_p),
    .hdmi_in_ddc_scl_i(hdmi_in_ddc_scl_i),
    .hdmi_in_ddc_scl_o(hdmi_in_ddc_scl_o),
    .hdmi_in_ddc_scl_t(hdmi_in_ddc_scl_t),
    .hdmi_in_ddc_sda_i(hdmi_in_ddc_sda_i),
    .hdmi_in_ddc_sda_o(hdmi_in_ddc_sda_o),
    .hdmi_in_ddc_sda_t(hdmi_in_ddc_sda_t),
    .hdmi_in_hpd(hdmi_in_hpd),
    .hdmi_out_clk_n(hdmi_out_clk_n),
    .hdmi_out_clk_p(hdmi_out_clk_p),
    .hdmi_out_data_n(hdmi_out_data_n),
    .hdmi_out_data_p(hdmi_out_data_p),
    .hdmi_out_ddc_scl_i(hdmi_out_ddc_scl_i),
    .hdmi_out_ddc_scl_o(hdmi_out_ddc_scl_o),
    .hdmi_out_ddc_scl_t(hdmi_out_ddc_scl_t),
    .hdmi_out_ddc_sda_i(hdmi_out_ddc_sda_i),
    .hdmi_out_ddc_sda_o(hdmi_out_ddc_sda_o),
    .hdmi_out_ddc_sda_t(hdmi_out_ddc_sda_t),
    .hdmi_out_hpd(hdmi_out_hpd),
//    .iic_sw_shield_scl_i(iic_sw_shield_scl_i),
//    .iic_sw_shield_scl_o(iic_sw_shield_scl_o),
//    .iic_sw_shield_scl_t(iic_sw_shield_scl_t),
//    .iic_sw_shield_sda_i(iic_sw_shield_sda_i),
//    .iic_sw_shield_sda_o(iic_sw_shield_sda_o),
//    .iic_sw_shield_sda_t(iic_sw_shield_sda_t),
    .shield2sw_scl_i_in(shield2sw_scl_i_in),
    .shield2sw_sda_i_in(shield2sw_sda_i_in),
    .sw2shield_scl_o_out(sw2shield_scl_o_out),
    .sw2shield_scl_t_out(sw2shield_scl_t_out),
    .sw2shield_sda_o_out(sw2shield_sda_o_out),
    .sw2shield_sda_t_out(sw2shield_sda_t_out),
    .leds_4bits_tri_o(leds_4bits_tri_o),
    .pmodJB_data_in(pmodJB_data_in),
    .pmodJB_data_out(pmodJB_data_out),
    .pmodJB_tri_out(pmodJB_tri_out),
    .pmodJA_data_in(pmodJA_data_in),
    .pmodJA_data_out(pmodJA_data_out),
    .pmodJA_tri_out(pmodJA_tri_out),
    .pdm_audio_shutdown(pdm_audio_shutdown),
    .pdm_m_clk(pdm_m_clk),
    .pdm_m_data_i(pdm_m_data_i),
    .rgbleds_6bits_tri_o(rgbleds_6bits_tri_o),    
    .pwm_audio_o(pwm_audio_o),
    .spi_sw_shield_io0_i(spi_sw_shield_io0_i),
    .spi_sw_shield_io0_o(spi_sw_shield_io0_o),
    .spi_sw_shield_io0_t(spi_sw_shield_io0_t),
    .spi_sw_shield_io1_i(spi_sw_shield_io1_i),
    .spi_sw_shield_io1_o(spi_sw_shield_io1_o),
    .spi_sw_shield_io1_t(spi_sw_shield_io1_t),
    .spi_sw_shield_sck_i(spi_sw_shield_sck_i),
    .spi_sw_shield_sck_o(spi_sw_shield_sck_o),
    .spi_sw_shield_sck_t(spi_sw_shield_sck_t),
    .spi_sw_shield_ss_i(spi_sw_shield_ss_i),
    .spi_sw_shield_ss_o(spi_sw_shield_ss_o),
    .spi_sw_shield_ss_t(spi_sw_shield_ss_t),
    .sws_2bits_tri_i(sws_2bits_tri_i));
        
endmodule
