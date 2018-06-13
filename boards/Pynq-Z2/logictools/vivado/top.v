`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Module Name: top
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
    ar_pg_clk,
    rp_pg_clk,
    rp_gpio,
    pmodJB,
    led,
    pb_input,
    ar_shield
    );
    
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
    
    output ar_pg_clk;
    output rp_pg_clk;
    inout [25:0]rp_gpio;
    inout [7:0]pmodJB;
    output [3:0] led;
    inout [19:0] ar_shield;
    input [3:0] pb_input;
  
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
      
    wire rp_pg_clk;
    wire [25:0]rp_gpio;
    wire [25:0]rp_data_i;
    wire [25:0]rp_data_o;
    wire [25:0]rp_tri_o;

    wire [7:0]pmodJB;
    wire [7:0]pmodJB_data_in;
    wire [7:0]pmodJB_data_out;
    wire [7:0]pmodJB_tri_out;

    wire ar_pg_clk;
    wire [19:0] ar_shield;
    wire [19:0]arduino_data_i;
    wire [19:0]arduino_data_o;
    wire [19:0]arduino_tri_o;

    
// pmodJB related iobufs
    genvar i;
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

// RaspberryPi related iobufs
    generate
    for (i=0; i < 26; i=i+1)
    begin: rp_iobuf
        IOBUF rp_data_iobuf_i(
            .I(rp_data_o[i]), 
            .IO(rp_gpio[i]), 
            .O(rp_data_i[i]), 
            .T(rp_tri_o[i]) 
            );
    end
    endgenerate

// Arduino shield related iobufs
    generate
        for (i=0; i < 20; i=i+1)
        begin: shield_ar
            IOBUF shield_ar_i(
                .I(arduino_data_o[i]), 
                .IO(ar_shield[i]), 
                .O(arduino_data_i[i]), 
                .T(arduino_tri_o[i]) 
                );
        end
    endgenerate

    system system_i
         (
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

        .ar_pg_clk(ar_pg_clk),
        .rp_pg_clk(rp_pg_clk),
        .arduino_data_i(arduino_data_i),
        .led(led),
        .pb_in(pb_input),
        .rp_data_i(rp_data_i),
        .rp_data_o(rp_data_o),
        .rp_tri_o(rp_tri_o),
        .pmodJB_data_in(pmodJB_data_in),
        .pmodJB_data_out(pmodJB_data_out),
        .pmodJB_tri_out(pmodJB_tri_out),
        .arduino_data_o(arduino_data_o),
        .arduino_tri_o(arduino_tri_o)
        );
endmodule
