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
    Vaux0_v_n,
    Vaux0_v_p,
    Vaux12_v_n,
    Vaux12_v_p,
    Vaux8_v_n,
    Vaux8_v_p,
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
    ck_an_tri_io,
    ck_gpio_tri_io,	
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
  input Vaux0_v_n;
  input Vaux0_v_p;
  input Vaux12_v_n;
  input Vaux12_v_p;
  input Vaux8_v_n;
  input Vaux8_v_p;
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
  inout [5:0]ck_an_tri_io;
  inout [15:0]ck_gpio_tri_io;
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
  wire Vaux0_v_n;
  wire Vaux0_v_p;
  wire Vaux12_v_n;
  wire Vaux12_v_p;
  wire Vaux8_v_n;
  wire Vaux8_v_p;
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
  wire [15:0]ck_gpio_tri_i;
  wire [15:0]ck_gpio_tri_io;
  wire [15:0]ck_gpio_tri_o;
  wire [15:0]ck_gpio_tri_t;
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

  wire iic_sw_shield_scl_io;
  wire iic_sw_shield_sda_io;
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

  // ChipKit related header signals
  genvar i;
  generate
	for (i=0; i < 15; i=i+1)
	begin: ck_gpio_iobuf
		IOBUF ck_gpio_tri_iobuf_i(
			.I(ck_gpio_tri_o[i]), 
			.IO(ck_gpio_tri_io[i]), 
			.O(ck_gpio_tri_i[i]), 
			.T(ck_gpio_tri_t[i]) 
			);
	end
  endgenerate
  
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
    generate
        for (i=0; i < 8; i=i+1)
        begin: pmodJB_iobuf
            IOBUF pmodJB_data_iobuf_i(
                .I(pmodJB_data_out[i]), 
                .IO(pmodJB[i]), 
                .O(pmodJB_data_in[i]), 
                .T(pmodJB_tri_out[i]) 
                );
        end
    endgenerate
// pmodJA related iobufs
    generate
        for (i=0; i < 8; i=i+1)
        begin: pmodJA_iobuf
            IOBUF pmodJA_data_iobuf_i(
                .I(pmodJA_data_out[i]), 
                .IO(pmodJA[i]), 
                .O(pmodJA_data_in[i]), 
                .T(pmodJA_tri_out[i]) 
                );
        end
    endgenerate

// Arduino shield related iobufs
    generate
        for (i=0; i < 6; i=i+1)
        begin: gpio_shield_sw_a5_a0_iobuf
            IOBUF gpio_shield_sw_a5_a0_iobuf_i(
                .I(sw2shield_data_out_a5_a0[i]), 
                .IO(gpio_shield_sw_a5_a0_tri_io[i]), 
                .O(shield2sw_data_in_a5_a0[i]), 
                .T(sw2shield_tri_out_a5_a0[i]) 
                );
        end
    endgenerate
    generate
        for (i=0; i < 12; i=i+1)
        begin: gpio_shield_sw_d13_d2_iobuf
            IOBUF gpio_shield_sw_d13_d2_i(
                .I(sw2shield_data_out_d13_d2[i]), 
                .IO(gpio_shield_sw_d13_d2_tri_io[i]), 
                .O(shield2sw_data_in_d13_d2[i]), 
                .T(sw2shield_tri_out_d13_d2[i]) 
                );
        end
    endgenerate
    generate
        for (i=0; i < 2; i=i+1)
        begin: gpio_shield_sw_d1_d0_iobuf
            IOBUF gpio_shield_sw_d1_d0_i(
                .I(sw2shield_data_out_d1_d0[i]), 
                .IO(gpio_shield_sw_d1_d0_tri_io[i]), 
                .O(shield2sw_data_in_d1_d0[i]), 
                .T(sw2shield_tri_out_d1_d0[i]) 
                );
        end
    endgenerate
	  
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
        .Vaux0_v_n(Vaux0_v_n),
    .Vaux0_v_p(Vaux0_v_p),
    .Vaux12_v_n(Vaux12_v_n),
    .Vaux12_v_p(Vaux12_v_p),
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
    .Vaux8_v_n(Vaux8_v_n),
    .Vaux8_v_p(Vaux8_v_p),
    .Vaux9_v_n(Vaux9_v_n),
    .Vaux9_v_p(Vaux9_v_p),
    .Vp_Vn_v_n(Vp_Vn_v_n),
    .Vp_Vn_v_p(Vp_Vn_v_p),
    .btns_4bits_tri_i(btns_4bits_tri_i),
    .ck_gpio_tri_i({ck_gpio_tri_i[15],ck_gpio_tri_i[14],ck_gpio_tri_i[13],ck_gpio_tri_i[12],ck_gpio_tri_i[11],ck_gpio_tri_i[10],ck_gpio_tri_i[9],ck_gpio_tri_i[8],ck_gpio_tri_i[7],ck_gpio_tri_i[6],ck_gpio_tri_i[5],ck_gpio_tri_i[4],ck_gpio_tri_i[3],ck_gpio_tri_i[2],ck_gpio_tri_i[1],ck_gpio_tri_i[0]}),
    .ck_gpio_tri_o({ck_gpio_tri_o[15],ck_gpio_tri_o[14],ck_gpio_tri_o[13],ck_gpio_tri_o[12],ck_gpio_tri_o[11],ck_gpio_tri_o[10],ck_gpio_tri_o[9],ck_gpio_tri_o[8],ck_gpio_tri_o[7],ck_gpio_tri_o[6],ck_gpio_tri_o[5],ck_gpio_tri_o[4],ck_gpio_tri_o[3],ck_gpio_tri_o[2],ck_gpio_tri_o[1],ck_gpio_tri_o[0]}),
    .ck_gpio_tri_t({ck_gpio_tri_t[15],ck_gpio_tri_t[14],ck_gpio_tri_t[13],ck_gpio_tri_t[12],ck_gpio_tri_t[11],ck_gpio_tri_t[10],ck_gpio_tri_t[9],ck_gpio_tri_t[8],ck_gpio_tri_t[7],ck_gpio_tri_t[6],ck_gpio_tri_t[5],ck_gpio_tri_t[4],ck_gpio_tri_t[3],ck_gpio_tri_t[2],ck_gpio_tri_t[1],ck_gpio_tri_t[0]}),
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
    .leds_4bits_tri_o(leds_4bits_tri_o),
    .pdm_audio_shutdown(pdm_audio_shutdown),
    .pdm_m_clk(pdm_m_clk),
    .pdm_m_data_i(pdm_m_data_i),
    .pmodJA_data_in(pmodJA_data_in),
    .pmodJA_data_out(pmodJA_data_out),
    .pmodJA_tri_out(pmodJA_tri_out),
    .pmodJB_data_in(pmodJB_data_in),
    .pmodJB_data_out(pmodJB_data_out),
    .pmodJB_tri_out(pmodJB_tri_out),
    .pwm_audio_o(pwm_audio_o),
    .rgbleds_6bits_tri_o(rgbleds_6bits_tri_o),
    .shield2sw_data_in_a5_a0(shield2sw_data_in_a5_a0),
    .shield2sw_data_in_d13_d2(shield2sw_data_in_d13_d2),
    .shield2sw_data_in_d1_d0(shield2sw_data_in_d1_d0),
    .shield2sw_scl_i_in(shield2sw_scl_i_in),
    .shield2sw_sda_i_in(shield2sw_sda_i_in),
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
    .sw2shield_data_out_a5_a0(sw2shield_data_out_a5_a0),
    .sw2shield_data_out_d13_d2(sw2shield_data_out_d13_d2),
    .sw2shield_data_out_d1_d0(sw2shield_data_out_d1_d0),
    .sw2shield_scl_o_out(sw2shield_scl_o_out),
    .sw2shield_scl_t_out(sw2shield_scl_t_out),
    .sw2shield_sda_o_out(sw2shield_sda_o_out),
    .sw2shield_sda_t_out(sw2shield_sda_t_out),
    .sw2shield_tri_out_a5_a0(sw2shield_tri_out_a5_a0),
    .sw2shield_tri_out_d13_d2(sw2shield_tri_out_d13_d2),
    .sw2shield_tri_out_d1_d0(sw2shield_tri_out_d1_d0),
    .sws_2bits_tri_i(sws_2bits_tri_i));
        
endmodule
