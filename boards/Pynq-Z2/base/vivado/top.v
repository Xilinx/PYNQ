`timescale 1ns / 1ps
///////////////////////////////////////////////////////////////////////////////
// Company: Xilinx Inc
// Design Name: PYNQ
// Module Name: top
// Project Name: PYNQ-Z2
// Target Devices: ZC7020
// Tool Versions: 2017.4
// Note: This design is for the production boards where shared pins are 
//       different then the pre-production boards
// Description: 
///////////////////////////////////////////////////////////////////////////////

module top(
    bclk,
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
    lrclk,
    sdata_i,
    sdata_o,
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
    arduino,
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
    hdmi_out_hpd,
    iic_1_scl_io,
    iic_1_sda_io,
    arduino_direct_scl_io,
    arduino_direct_sda_io,
    leds_4bits_tri_o,
    arduino_direct_spi_io0_io,
    arduino_direct_spi_io1_io,
    arduino_direct_spi_sck_io,
    arduino_direct_spi_ss_io,
    rp_io_27_8,
    pmoda,
    pmodb,
    rgbleds_6bits_tri_o,
    sws_2bits_tri_i);
    
  output bclk;
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
  output lrclk;
  input sdata_i;
  output sdata_o;  
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
  inout [19:0]arduino;
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
  output [0:0]hdmi_out_hpd;
  inout [27:8] rp_io_27_8;
  inout iic_1_scl_io;
  inout iic_1_sda_io;
  inout arduino_direct_scl_io;
  inout arduino_direct_sda_io;
  output [3:0]leds_4bits_tri_o;
  input [1:0]sws_2bits_tri_i;
  inout arduino_direct_spi_io0_io;
  inout arduino_direct_spi_io1_io;
  inout arduino_direct_spi_sck_io;
  inout arduino_direct_spi_ss_io;
  inout [7:0]pmoda;
  inout [7:0]pmodb;
  output [5:0]rgbleds_6bits_tri_o;
  
  wire bclk;
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
  wire lrclk;
  wire sdata_i;
  wire sdata_o;  
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
  wire [19:0]arduino;
  wire [19:0]arduino_data_i;
  wire [19:0]arduino_data_o;
  wire [19:0]arduino_tri_o;
  wire [1:0]codec_addr;
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
  wire [0:0]hdmi_out_hpd;
  wire arduino_direct_iic_scl_i;
  wire arduino_direct_iic_sda_i;
  wire arduino_direct_iic_scl_o;
  wire arduino_direct_iic_scl_t;
  wire arduino_direct_iic_sda_o;
  wire arduino_direct_iic_sda_t;
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
  wire arduino_direct_scl_io;
  wire arduino_direct_sda_io;
  wire [3:0]leds_4bits_tri_o;
  wire [7:0]pmoda_data_i;
  wire [7:0]pmoda_data_o;
  wire [7:0]pmoda_tri_o;
  wire [7:0]pmodb_data_i;
  wire [7:0]pmodb_data_o;
  wire [7:0]pmodb_tri_o;
  wire arduino_direct_spi_io0_i;
  wire arduino_direct_spi_io0_io;
  wire arduino_direct_spi_io0_o;
  wire arduino_direct_spi_io0_t;
  wire arduino_direct_spi_io1_i;
  wire arduino_direct_spi_io1_io;
  wire arduino_direct_spi_io1_o;
  wire arduino_direct_spi_io1_t;
  wire arduino_direct_spi_sck_i;
  wire arduino_direct_spi_sck_io;
  wire arduino_direct_spi_sck_o;
  wire arduino_direct_spi_sck_t;
  wire arduino_direct_spi_ss_i;
  wire arduino_direct_spi_ss_io;
  wire arduino_direct_spi_ss_o;
  wire arduino_direct_spi_ss_t;
  wire [1:0]sws_2bits_tri_i;  
  wire [7:0]pmoda;
  wire [7:0]pmodb;
  wire [5:0]rgbleds_6bits_tri_o;
  wire pmoda_rp_pin_sel;
  wire [27:0]rpi_data_o;
  wire [27:0]rpi_tri_o;
  wire [27:0]rpi_data_i;
  wire [27:8]rp_io_27_8;
  wire [7:0] pmoda_data_o_int;
  wire [7:0] pmoda_tri_o_int;

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
        for (i=8; i < 28; i=i+1)
        begin: rp_iobuf
            IOBUF rp_i(
                .I(rpi_data_o[i]), 
                .IO(rp_io_27_8[i]), 
                .O(rpi_data_i[i]), 
                .T(rpi_tri_o[i]) 
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

// pmodb related iobufs
    generate
        for (i=0; i < 8; i=i+1)
        begin: pmodb_iobuf
            IOBUF pmodb_data_iobuf_i(
                .I(pmodb_data_o[i]), 
                .IO(pmodb[i]), 
                .O(pmodb_data_i[i]), 
                .T(pmodb_tri_o[i]) 
                );
        end
    endgenerate
// pmoda related iobufs
    generate
        for (i=0; i < 8; i=i+1)
        begin: pmoda_iobuf
            IOBUF pmoda_data_iobuf_i(
                .I(pmoda_data_o_int[i]), 
                .IO(pmoda[i]), 
                .O(pmoda_data_i[i]), 
                .T(pmoda_tri_o_int[i]) 
                );
        end
    endgenerate

// Arduino shield related iobufs
    generate
        for (i=0; i < 20; i=i+1)
        begin: gpio_shield_sw_a5_a0_d13_d0_iobuf_i
            IOBUF gpio_shield_sw_a5_a0_d13_d0_iobuf_i(
                .I(arduino_data_o[i]), 
                .IO(arduino[i]), 
                .O(arduino_data_i[i]), 
                .T(arduino_tri_o[i]) 
                );
        end
    endgenerate
	  
	// Arduino IIC Direct
	IOBUF arduino_direct_scl_iobuf
		 (.I(arduino_direct_iic_scl_o),
		  .IO(arduino_direct_scl_io),
		  .O(arduino_direct_iic_scl_i),
		  .T(arduino_direct_iic_scl_t));
	IOBUF arduino_direct_sda_iobuf
		 (.I(arduino_direct_iic_sda_o),
		  .IO(arduino_direct_sda_io),
		  .O(arduino_direct_iic_sda_i),
		  .T(arduino_direct_iic_sda_t));
	// Dedicated Arduino SPI
	IOBUF arduino_direct_spi_io0_iobuf
		 (.I(arduino_direct_spi_io0_o),
		  .IO(arduino_direct_spi_io0_io),
		  .O(arduino_direct_spi_io0_i),
		  .T(arduino_direct_spi_io0_t));
	IOBUF arduino_direct_spi_io1_iobuf
		 (.I(arduino_direct_spi_io1_o),
		  .IO(arduino_direct_spi_io1_io),
		  .O(arduino_direct_spi_io1_i),
		  .T(arduino_direct_spi_io1_t));
	IOBUF arduino_direct_spi_sck_iobuf
		 (.I(arduino_direct_spi_sck_o),
		  .IO(arduino_direct_spi_sck_io),
		  .O(arduino_direct_spi_sck_i),
		  .T(arduino_direct_spi_sck_t));
	IOBUF arduino_direct_spi_ss_iobuf
		 (.I(arduino_direct_spi_ss_o),
		  .IO(arduino_direct_spi_ss_io),
		  .O(arduino_direct_spi_ss_i),
		  .T(arduino_direct_spi_ss_t));                          

    assign pmoda_data_o_int[0] = (pmoda_data_o[0] & ~pmoda_rp_pin_sel) | (rpi_data_o[4] & pmoda_rp_pin_sel);
    assign pmoda_data_o_int[1] = (pmoda_data_o[1] & ~pmoda_rp_pin_sel) | (rpi_data_o[5] & pmoda_rp_pin_sel);
    assign pmoda_data_o_int[2] = (pmoda_data_o[2] & ~pmoda_rp_pin_sel) | (rpi_data_o[0] & pmoda_rp_pin_sel);
    assign pmoda_data_o_int[3] = (pmoda_data_o[3] & ~pmoda_rp_pin_sel) | (rpi_data_o[1] & pmoda_rp_pin_sel);
    assign pmoda_data_o_int[4] = (pmoda_data_o[4] & ~pmoda_rp_pin_sel) | (rpi_data_o[6] & pmoda_rp_pin_sel);
    assign pmoda_data_o_int[5] = (pmoda_data_o[5] & ~pmoda_rp_pin_sel) | (rpi_data_o[7] & pmoda_rp_pin_sel);
    assign pmoda_data_o_int[6] = (pmoda_data_o[6] & ~pmoda_rp_pin_sel) | (rpi_data_o[2] & pmoda_rp_pin_sel);
    assign pmoda_data_o_int[7] = (pmoda_data_o[7] & ~pmoda_rp_pin_sel) | (rpi_data_o[3] & pmoda_rp_pin_sel);

    assign pmoda_tri_o_int[0] = (pmoda_tri_o[0] & ~pmoda_rp_pin_sel) | (rpi_tri_o[4] & pmoda_rp_pin_sel);
    assign pmoda_tri_o_int[1] = (pmoda_tri_o[1] & ~pmoda_rp_pin_sel) | (rpi_tri_o[5] & pmoda_rp_pin_sel);
    assign pmoda_tri_o_int[2] = (pmoda_tri_o[2] & ~pmoda_rp_pin_sel) | (rpi_tri_o[0] & pmoda_rp_pin_sel);
    assign pmoda_tri_o_int[3] = (pmoda_tri_o[3] & ~pmoda_rp_pin_sel) | (rpi_tri_o[1] & pmoda_rp_pin_sel);
    assign pmoda_tri_o_int[4] = (pmoda_tri_o[4] & ~pmoda_rp_pin_sel) | (rpi_tri_o[6] & pmoda_rp_pin_sel);
    assign pmoda_tri_o_int[5] = (pmoda_tri_o[5] & ~pmoda_rp_pin_sel) | (rpi_tri_o[7] & pmoda_rp_pin_sel);
    assign pmoda_tri_o_int[6] = (pmoda_tri_o[6] & ~pmoda_rp_pin_sel) | (rpi_tri_o[2] & pmoda_rp_pin_sel);
    assign pmoda_tri_o_int[7] = (pmoda_tri_o[7] & ~pmoda_rp_pin_sel) | (rpi_tri_o[3] & pmoda_rp_pin_sel);
    
system system_i
   (.bclk(bclk),
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
    .lrclk(lrclk),
    .sdata_i(sdata_i),
    .sdata_o(sdata_o),   
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
    .hdmi_out_hpd(hdmi_out_hpd),
    .leds_4bits_tri_o(leds_4bits_tri_o),
    .pmoda_data_i(pmoda_data_i),
    .pmoda_data_o(pmoda_data_o),
    .pmoda_tri_o(pmoda_tri_o),
    .pmodb_data_i(pmodb_data_i),
    .pmodb_data_o(pmodb_data_o),
    .pmodb_tri_o(pmodb_tri_o),
    .pmoda_rp_pin_sel(pmoda_rp_pin_sel),
    .rpi_data_i({rpi_data_i[27:8],pmoda_data_i[5:4],pmoda_data_i[1:0],pmoda_data_i[7:6],pmoda_data_i[3:2]}),
    .rgbleds_6bits_tri_o(rgbleds_6bits_tri_o),
    .arduino_data_i(arduino_data_i),
    .arduino_direct_iic_scl_i(arduino_direct_iic_scl_i),
    .arduino_direct_iic_sda_i(arduino_direct_iic_sda_i),
    .arduino_direct_spi_io0_i(arduino_direct_spi_io0_i),
    .arduino_direct_spi_io0_o(arduino_direct_spi_io0_o),
    .arduino_direct_spi_io0_t(arduino_direct_spi_io0_t),
    .arduino_direct_spi_io1_i(arduino_direct_spi_io1_i),
    .arduino_direct_spi_io1_o(arduino_direct_spi_io1_o),
    .arduino_direct_spi_io1_t(arduino_direct_spi_io1_t),
    .arduino_direct_spi_sck_i(arduino_direct_spi_sck_i),
    .arduino_direct_spi_sck_o(arduino_direct_spi_sck_o),
    .arduino_direct_spi_sck_t(arduino_direct_spi_sck_t),
    .arduino_direct_spi_ss_i(arduino_direct_spi_ss_i),
    .arduino_direct_spi_ss_o(arduino_direct_spi_ss_o),
    .arduino_direct_spi_ss_t(arduino_direct_spi_ss_t),
    .rpi_data_o(rpi_data_o),
    .rpi_tri_o(rpi_tri_o),
    .arduino_data_o(arduino_data_o),
    .arduino_direct_iic_scl_o(arduino_direct_iic_scl_o),
    .arduino_direct_iic_scl_t(arduino_direct_iic_scl_t),
    .arduino_direct_iic_sda_o(arduino_direct_iic_sda_o),
    .arduino_direct_iic_sda_t(arduino_direct_iic_sda_t),
    .arduino_tri_o(arduino_tri_o),
    .sws_2bits_tri_i(sws_2bits_tri_i));
        
endmodule
