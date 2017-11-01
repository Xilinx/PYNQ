`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Xilinx Inc
// Design Name: PYNQ
// Module Name: top
// Project Name: PYNQ-Z2
// Target Devices: ZC7020
// Tool Versions: 2016.1
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
    FIXED_IO_mio,
    FIXED_IO_ps_clk,
    FIXED_IO_ps_porb,
    FIXED_IO_ps_srstb,
    LRCLK,
    SDATA_I,
    SDATA_O,
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
    audio_clk_10MHz,
    btns_4bits_tri_i,
    codec_addr,
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
//    hdmi_out_ddc_scl_io,
//    hdmi_out_ddc_sda_io,
    hdmi_out_hpd,
    iic_1_scl_io,
    iic_1_sda_io,
    iic_sw_shield_scl_io,
    iic_sw_shield_sda_io,
    leds_4bits_tri_o,
    spi_sw_shield_io0_io,
    spi_sw_shield_io1_io,
    spi_sw_shield_sck_io,
    spi_sw_shield_ss_io,
    rp_gpio_io_13_4,
    rp_gpio_io_23_16,
    rp_gpio_io_27_26,
    pmodJA,
    pmodJB,
    rgbleds_6bits_tri_o,
    sws_2bits_tri_i);
    
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
  output LRCLK;
  input SDATA_I;
  output SDATA_O;  
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
  output audio_clk_10MHz;
  input [3:0]btns_4bits_tri_i;
  output [1:0]codec_addr;
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
//  inout hdmi_out_ddc_scl_io;
//  inout hdmi_out_ddc_sda_io;
  output [0:0]hdmi_out_hpd;
  inout [13:4] rp_gpio_io_13_4;
  inout [23:16] rp_gpio_io_23_16;
  inout [27:26] rp_gpio_io_27_26;
  inout iic_1_scl_io;
  inout iic_1_sda_io;
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
  output [5:0]rgbleds_6bits_tri_o;
  
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
  wire FIXED_IO_ddr_vrn;
  wire FIXED_IO_ddr_vrp;
  wire [53:0]FIXED_IO_mio;
  wire FIXED_IO_ps_clk;
  wire FIXED_IO_ps_porb;
  wire FIXED_IO_ps_srstb;
  wire LRCLK;
  wire SDATA_I;
  wire SDATA_O;  
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
  wire audio_clk_10MHz;
  wire [3:0]btns_4bits_tri_i;
  wire [1:0]codec_addr;
  wire [5:0]shield2sw_data_in_a5_a0;
  wire [11:0]shield2sw_data_in_d13_d2;
  wire [1:0]shield2sw_data_in_d1_d0;
  wire [5:0]sw2shield_data_out_a5_a0;
  wire [11:0]sw2shield_data_out_d13_d2;
  wire [1:0]sw2shield_data_out_d1_d0;
  wire [5:0]sw2shield_tri_out_a5_a0;
  wire [11:0]sw2shield_tri_out_d13_d2;
  wire [1:0]sw2shield_tri_out_d1_d0;
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
//  wire hdmi_out_ddc_scl_i;
//  wire hdmi_out_ddc_scl_io;
//  wire hdmi_out_ddc_scl_o;
//  wire hdmi_out_ddc_scl_t;
//  wire hdmi_out_ddc_sda_i;
//  wire hdmi_out_ddc_sda_io;
//  wire hdmi_out_ddc_sda_o;
//  wire hdmi_out_ddc_sda_t;
  wire [0:0]hdmi_out_hpd;
  wire shield2sw_scl_i_in;
  wire shield2sw_sda_i_in;
  wire sw2shield_scl_o_out;
  wire sw2shield_scl_t_out;
  wire sw2shield_sda_o_out;
  wire sw2shield_sda_t_out;
  wire iic_1_scl_i;
  wire iic_1_scl_io;
  wire iic_1_scl_o;
  wire iic_1_scl_t;
  wire iic_1_sda_i;
  wire iic_1_sda_io;
  wire iic_1_sda_o;
  wire iic_1_sda_t;
  wire iic_id_scl_o;
  wire iic_id_scl_t;
  wire iic_id_sda_o;
  wire iic_id_sda_t;
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
  wire [5:0]rgbleds_6bits_tri_o;
  wire pmoda_rp_pin_sel;
  wire [27:0]sw2rp_data_out;
  wire [27:0]sw2rp_tri_out;
  wire [27:0]rp2sw_data_in;
  wire [13:4] rp_gpio_io_13_4;
  wire [23:16] rp_gpio_io_23_16;
  wire [27:26] rp_gpio_io_27_26;
  wire [7:0] pmodJA_data_out_int;
  wire [7:0] pmodJA_tri_out_int;

  genvar i;
// IIC for audio codec
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
        
    // RP GPIO
    generate
        for (i=4; i < 14; i=i+1)
        begin: rp_iobuf
            IOBUF rp_i(
                .I(sw2rp_data_out[i]), 
                .IO(rp_gpio_io_13_4[i]), 
                .O(rp2sw_data_in[i]), 
                .T(sw2rp_tri_out[i]) 
                );
        end
    endgenerate
    generate
        for (i=16; i < 24; i=i+1)
        begin: rp_iobuf_1
            IOBUF rp_i(
                .I(sw2rp_data_out[i]), 
                .IO(rp_gpio_io_23_16[i]), 
                .O(rp2sw_data_in[i]), 
                .T(sw2rp_tri_out[i]) 
                );
        end
    endgenerate
    generate
        for (i=26; i < 28; i=i+1)
        begin: rp_iobuf_2
            IOBUF rp_i(
                .I(sw2rp_data_out[i]), 
                .IO(rp_gpio_io_27_26[i]), 
                .O(rp2sw_data_in[i]), 
                .T(sw2rp_tri_out[i]) 
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
//    IOBUF hdmi_out_ddc_scl_iobuf
//       (.I(hdmi_out_ddc_scl_o),
//        .IO(hdmi_out_ddc_scl_io),
//        .O(hdmi_out_ddc_scl_i),
//        .T(hdmi_out_ddc_scl_t));
//    IOBUF hdmi_out_ddc_sda_iobuf
//       (.I(hdmi_out_ddc_sda_o),
//        .IO(hdmi_out_ddc_sda_io),
//        .O(hdmi_out_ddc_sda_i),
//        .T(hdmi_out_ddc_sda_t));

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
                .I(pmodJA_data_out_int[i]), 
                .IO(pmodJA[i]), 
                .O(pmodJA_data_in[i]), 
                .T(pmodJA_tri_out_int[i]) 
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

    assign pmodJA_data_out_int[0] = (pmodJA_data_out[0] & ~pmoda_rp_pin_sel) | (sw2rp_data_out[14] & pmoda_rp_pin_sel);
    assign pmodJA_data_out_int[1] = (pmodJA_data_out[1] & ~pmoda_rp_pin_sel) | (sw2rp_data_out[15] & pmoda_rp_pin_sel);
    assign pmodJA_data_out_int[2] = (pmodJA_data_out[2] & ~pmoda_rp_pin_sel) | (sw2rp_data_out[0] & pmoda_rp_pin_sel);
    assign pmodJA_data_out_int[3] = (pmodJA_data_out[3] & ~pmoda_rp_pin_sel) | (sw2rp_data_out[1] & pmoda_rp_pin_sel);
    assign pmodJA_data_out_int[4] = (pmodJA_data_out[4] & ~pmoda_rp_pin_sel) | (sw2rp_data_out[24] & pmoda_rp_pin_sel);
    assign pmodJA_data_out_int[5] = (pmodJA_data_out[5] & ~pmoda_rp_pin_sel) | (sw2rp_data_out[25] & pmoda_rp_pin_sel);
    assign pmodJA_data_out_int[6] = (pmodJA_data_out[6] & ~pmoda_rp_pin_sel) | (sw2rp_data_out[2] & pmoda_rp_pin_sel);
    assign pmodJA_data_out_int[7] = (pmodJA_data_out[7] & ~pmoda_rp_pin_sel) | (sw2rp_data_out[3] & pmoda_rp_pin_sel);

    assign pmodJA_tri_out_int[0] = (pmodJA_tri_out[0] & ~pmoda_rp_pin_sel) | (sw2rp_tri_out[14] & pmoda_rp_pin_sel);
    assign pmodJA_tri_out_int[1] = (pmodJA_tri_out[1] & ~pmoda_rp_pin_sel) | (sw2rp_tri_out[15] & pmoda_rp_pin_sel);
    assign pmodJA_tri_out_int[2] = (pmodJA_tri_out[2] & ~pmoda_rp_pin_sel) | (sw2rp_tri_out[0] & pmoda_rp_pin_sel);
    assign pmodJA_tri_out_int[3] = (pmodJA_tri_out[3] & ~pmoda_rp_pin_sel) | (sw2rp_tri_out[1] & pmoda_rp_pin_sel);
    assign pmodJA_tri_out_int[4] = (pmodJA_tri_out[4] & ~pmoda_rp_pin_sel) | (sw2rp_tri_out[24] & pmoda_rp_pin_sel);
    assign pmodJA_tri_out_int[5] = (pmodJA_tri_out[5] & ~pmoda_rp_pin_sel) | (sw2rp_tri_out[25] & pmoda_rp_pin_sel);
    assign pmodJA_tri_out_int[6] = (pmodJA_tri_out[6] & ~pmoda_rp_pin_sel) | (sw2rp_tri_out[2] & pmoda_rp_pin_sel);
    assign pmodJA_tri_out_int[7] = (pmodJA_tri_out[7] & ~pmoda_rp_pin_sel) | (sw2rp_tri_out[3] & pmoda_rp_pin_sel);
    
system system_i
   (.BCLK(BCLK),
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
    .LRCLK(LRCLK),
    .SDATA_I(SDATA_I),
    .SDATA_O(SDATA_O),   
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
    .audio_clk_10MHz(audio_clk_10MHz),
    .btns_4bits_tri_i(btns_4bits_tri_i),
    .codec_addr(codec_addr),
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
//    .hdmi_out_ddc_scl_i(hdmi_out_ddc_scl_i),
//    .hdmi_out_ddc_scl_o(hdmi_out_ddc_scl_o),
//    .hdmi_out_ddc_scl_t(hdmi_out_ddc_scl_t),
//    .hdmi_out_ddc_sda_i(hdmi_out_ddc_sda_i),
//    .hdmi_out_ddc_sda_o(hdmi_out_ddc_sda_o),
//    .hdmi_out_ddc_sda_t(hdmi_out_ddc_sda_t),
    .hdmi_out_hpd(hdmi_out_hpd),
    .leds_4bits_tri_o(leds_4bits_tri_o),
    .pmodJA_data_in(pmodJA_data_in),
    .pmodJA_data_out(pmodJA_data_out),
    .pmodJA_tri_out(pmodJA_tri_out),
    .pmodJB_data_in(pmodJB_data_in),
    .pmodJB_data_out(pmodJB_data_out),
    .pmodJB_tri_out(pmodJB_tri_out),
    .pmoda_rp_pin_sel(pmoda_rp_pin_sel),
    .rp2sw_data_in({rp2sw_data_in[27:26],pmodJA_data_in[5:4],rp2sw_data_in[23:16],pmodJA_data_in[1:0],rp2sw_data_in[13:4],pmodJA_data_in[7:6],pmodJA_data_in[3:2]}),
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
    .sw2rp_data_out(sw2rp_data_out),
    .sw2rp_tri_out(sw2rp_tri_out),
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
