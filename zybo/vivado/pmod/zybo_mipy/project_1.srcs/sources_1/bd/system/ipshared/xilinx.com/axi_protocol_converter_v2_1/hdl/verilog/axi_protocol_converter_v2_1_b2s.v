///////////////////////////////////////////////////////////////////////////////
//
// File name: axi_protocol_converter_v2_1_6_b2s.v
//
// Description:
// To handle AXI4 transactions to external memory on Virtex-6 architectures
// requires a bridge to convert the AXI4 transactions to the memory
// controller(MC) user interface.  The MC user interface has bidirectional
// data path and supports data width of 256/128/64/32 bits.
// The bridge is designed to allow AXI4 IP masters to communicate with
// the MC user interface.
//
//
// Specifications:
// AXI4 Slave Side:
// Configurable data width of 32, 64, 128, 256
// Read acceptance depth is:
// Write acceptance depth is:
//
// Structure:
// axi_protocol_converter_v2_1_6_b2s
//   WRITE_BUNDLE
//     aw_channel_0
//       cmd_translator_0
//       rd_cmd_fsm_0
//     w_channel_0
//     b_channel_0
//   READ_BUNDLE
//     ar_channel_0
//       cmd_translator_0
//       rd_cmd_fsm_0
//     r_channel_0
//
///////////////////////////////////////////////////////////////////////////////
`timescale 1ps/1ps
`default_nettype none

(* DowngradeIPIdentifiedWarnings="yes" *) 
module axi_protocol_converter_v2_1_6_b2s #(
  parameter C_S_AXI_PROTOCOL                      = 0,
                    // Width of all master and slave ID signals.
                    // Range: >= 1.
  parameter integer C_AXI_ID_WIDTH                = 4,
  parameter integer C_AXI_ADDR_WIDTH              = 30,
  parameter integer C_AXI_DATA_WIDTH              = 32,
  parameter integer C_AXI_SUPPORTS_WRITE          = 1,
  parameter integer C_AXI_SUPPORTS_READ           = 1
)
(
///////////////////////////////////////////////////////////////////////////////
// Port Declarations
///////////////////////////////////////////////////////////////////////////////
  // AXI Slave Interface
  // Slave Interface System Signals
  input  wire                               aclk              ,
  input  wire                               aresetn           ,
  // Slave Interface Write Address Ports
  input  wire [C_AXI_ID_WIDTH-1:0]          s_axi_awid        ,
  input  wire [C_AXI_ADDR_WIDTH-1:0]        s_axi_awaddr      ,
  input  wire [((C_S_AXI_PROTOCOL == 1) ? 4 : 8)-1:0]  s_axi_awlen,
  input  wire [2:0]                         s_axi_awsize      ,
  input  wire [1:0]                         s_axi_awburst     ,
  input  wire [2:0]                         s_axi_awprot      ,
  input  wire                               s_axi_awvalid     ,
  output wire                               s_axi_awready     ,
  // Slave Interface Write Data Ports
  input  wire [C_AXI_DATA_WIDTH-1:0]        s_axi_wdata       ,
  input  wire [C_AXI_DATA_WIDTH/8-1:0]      s_axi_wstrb       ,
  input  wire                               s_axi_wlast       ,
  input  wire                               s_axi_wvalid      ,
  output wire                               s_axi_wready      ,
  // Slave Interface Write Response Ports
  output wire [C_AXI_ID_WIDTH-1:0]          s_axi_bid         ,
  output wire [1:0]                         s_axi_bresp       ,
  output wire                               s_axi_bvalid      ,
  input  wire                               s_axi_bready      ,
  // Slave Interface Read Address Ports
  input  wire [C_AXI_ID_WIDTH-1:0]          s_axi_arid        ,
  input  wire [C_AXI_ADDR_WIDTH-1:0]        s_axi_araddr      ,
  input  wire [((C_S_AXI_PROTOCOL == 1) ? 4 : 8)-1:0]  s_axi_arlen,
  input  wire [2:0]                         s_axi_arsize      ,
  input  wire [1:0]                         s_axi_arburst     ,
  input  wire [2:0]                         s_axi_arprot      ,
  input  wire                               s_axi_arvalid     ,
  output wire                               s_axi_arready     ,
  // Slave Interface Read Data Ports
  output wire [C_AXI_ID_WIDTH-1:0]          s_axi_rid         ,
  output wire [C_AXI_DATA_WIDTH-1:0]        s_axi_rdata       ,
  output wire [1:0]                         s_axi_rresp       ,
  output wire                               s_axi_rlast       ,
  output wire                               s_axi_rvalid      ,
  input  wire                               s_axi_rready      ,

  // Slave Interface Write Address Ports
  output wire [C_AXI_ADDR_WIDTH-1:0]        m_axi_awaddr      ,
  output wire [2:0]                         m_axi_awprot      ,
  output wire                               m_axi_awvalid     ,
  input  wire                               m_axi_awready     ,
  // Slave Interface Write Data Ports
  output wire [C_AXI_DATA_WIDTH-1:0]        m_axi_wdata       ,
  output wire [C_AXI_DATA_WIDTH/8-1:0]      m_axi_wstrb       ,
  output wire                               m_axi_wvalid      ,
  input  wire                               m_axi_wready      ,
  // Slave Interface Write Response Ports
  input  wire [1:0]                         m_axi_bresp       ,
  input  wire                               m_axi_bvalid      ,
  output wire                               m_axi_bready      ,
  // Slave Interface Read Address Ports
  output wire [C_AXI_ADDR_WIDTH-1:0]        m_axi_araddr      ,
  output wire [2:0]                         m_axi_arprot      ,
  output wire                               m_axi_arvalid     ,
  input  wire                               m_axi_arready     ,
  // Slave Interface Read Data Ports
  input  wire [C_AXI_DATA_WIDTH-1:0]        m_axi_rdata       ,
  input  wire [1:0]                         m_axi_rresp       ,
  input  wire                               m_axi_rvalid      ,
  output wire                               m_axi_rready
);

////////////////////////////////////////////////////////////////////////////////
// Wires/Reg declarations
////////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////////
// BEGIN RTL
reg                            areset_d1;

always @(posedge aclk)
  areset_d1 <= ~aresetn;


// AW/W/B channel internal communication
wire                                b_push;
wire [C_AXI_ID_WIDTH-1:0]           b_awid;
wire [7:0]                          b_awlen;
wire                                b_full;

wire [C_AXI_ID_WIDTH-1:0]                   si_rs_awid;
wire [C_AXI_ADDR_WIDTH-1:0]                 si_rs_awaddr;
wire [8-1:0]                                si_rs_awlen;
wire [3-1:0]                                si_rs_awsize;
wire [2-1:0]                                si_rs_awburst;
wire [3-1:0]                                si_rs_awprot;
wire                                        si_rs_awvalid;
wire                                        si_rs_awready;
wire [C_AXI_DATA_WIDTH-1:0]                 si_rs_wdata;
wire [C_AXI_DATA_WIDTH/8-1:0]               si_rs_wstrb;
wire                                        si_rs_wlast;
wire                                        si_rs_wvalid;
wire                                        si_rs_wready;
wire [C_AXI_ID_WIDTH-1:0]                   si_rs_bid;
wire [2-1:0]                                si_rs_bresp;
wire                                        si_rs_bvalid;
wire                                        si_rs_bready;
wire [C_AXI_ID_WIDTH-1:0]                   si_rs_arid;
wire [C_AXI_ADDR_WIDTH-1:0]                 si_rs_araddr;
wire [8-1:0]                                si_rs_arlen;
wire [3-1:0]                                si_rs_arsize;
wire [2-1:0]                                si_rs_arburst;
wire [3-1:0]                                si_rs_arprot;
wire                                        si_rs_arvalid;
wire                                        si_rs_arready;
wire [C_AXI_ID_WIDTH-1:0]                   si_rs_rid;
wire [C_AXI_DATA_WIDTH-1:0]                 si_rs_rdata;
wire [2-1:0]                                si_rs_rresp;
wire                                        si_rs_rlast;
wire                                        si_rs_rvalid;
wire                                        si_rs_rready;

wire [C_AXI_ADDR_WIDTH-1:0]                 rs_mi_awaddr;
wire                                        rs_mi_awvalid;
wire                                        rs_mi_awready;
wire [C_AXI_DATA_WIDTH-1:0]                 rs_mi_wdata;
wire [C_AXI_DATA_WIDTH/8-1:0]               rs_mi_wstrb;
wire                                        rs_mi_wvalid;
wire                                        rs_mi_wready;
wire [2-1:0]                                rs_mi_bresp;
wire                                        rs_mi_bvalid;
wire                                        rs_mi_bready;
wire [C_AXI_ADDR_WIDTH-1:0]                 rs_mi_araddr;
wire                                        rs_mi_arvalid;
wire                                        rs_mi_arready;
wire [C_AXI_DATA_WIDTH-1:0]                 rs_mi_rdata;
wire [2-1:0]                                rs_mi_rresp;
wire                                        rs_mi_rvalid;
wire                                        rs_mi_rready;


axi_register_slice_v2_1_6_axi_register_slice #(
  .C_AXI_PROTOCOL              ( C_S_AXI_PROTOCOL            ) ,
  .C_AXI_ID_WIDTH              ( C_AXI_ID_WIDTH              ) ,
  .C_AXI_ADDR_WIDTH            ( C_AXI_ADDR_WIDTH            ) ,
  .C_AXI_DATA_WIDTH            ( C_AXI_DATA_WIDTH            ) ,
  .C_AXI_SUPPORTS_USER_SIGNALS ( 0 ) ,
  .C_AXI_AWUSER_WIDTH          ( 1 ) ,
  .C_AXI_ARUSER_WIDTH          ( 1 ) ,
  .C_AXI_WUSER_WIDTH           ( 1 ) ,
  .C_AXI_RUSER_WIDTH           ( 1 ) ,
  .C_AXI_BUSER_WIDTH           ( 1 ) ,
  .C_REG_CONFIG_AW             ( 1 ) ,
  .C_REG_CONFIG_AR             ( 1 ) ,
  .C_REG_CONFIG_W              ( 0 ) ,
  .C_REG_CONFIG_R              ( 1 ) ,
  .C_REG_CONFIG_B              ( 1 )
) SI_REG (
  .aresetn                    ( aresetn     ) ,
  .aclk                       ( aclk          ) ,
  .s_axi_awid                 ( s_axi_awid    ) ,
  .s_axi_awaddr               ( s_axi_awaddr  ) ,
  .s_axi_awlen                ( s_axi_awlen   ) ,
  .s_axi_awsize               ( s_axi_awsize  ) ,
  .s_axi_awburst              ( s_axi_awburst ) ,
  .s_axi_awlock               ( {((C_S_AXI_PROTOCOL == 1) ? 2 : 1){1'b0}}  ) ,
  .s_axi_awcache              ( 4'h0 ) ,
  .s_axi_awprot               ( s_axi_awprot  ) ,
  .s_axi_awqos                ( 4'h0 ) ,
  .s_axi_awuser               ( 1'b0  ) ,
  .s_axi_awvalid              ( s_axi_awvalid ) ,
  .s_axi_awready              ( s_axi_awready ) ,
  .s_axi_awregion             ( 4'h0 ) ,
  .s_axi_wid                  ( {C_AXI_ID_WIDTH{1'b0}} ) ,
  .s_axi_wdata                ( s_axi_wdata   ) ,
  .s_axi_wstrb                ( s_axi_wstrb   ) ,
  .s_axi_wlast                ( s_axi_wlast   ) ,
  .s_axi_wuser                ( 1'b0  ) ,
  .s_axi_wvalid               ( s_axi_wvalid  ) ,
  .s_axi_wready               ( s_axi_wready  ) ,
  .s_axi_bid                  ( s_axi_bid     ) ,
  .s_axi_bresp                ( s_axi_bresp   ) ,
  .s_axi_buser                ( ) ,
  .s_axi_bvalid               ( s_axi_bvalid  ) ,
  .s_axi_bready               ( s_axi_bready  ) ,
  .s_axi_arid                 ( s_axi_arid    ) ,
  .s_axi_araddr               ( s_axi_araddr  ) ,
  .s_axi_arlen                ( s_axi_arlen   ) ,
  .s_axi_arsize               ( s_axi_arsize  ) ,
  .s_axi_arburst              ( s_axi_arburst ) ,
  .s_axi_arlock               ( {((C_S_AXI_PROTOCOL == 1) ? 2 : 1){1'b0}}  ) ,
  .s_axi_arcache              ( 4'h0 ) ,
  .s_axi_arprot               ( s_axi_arprot  ) ,
  .s_axi_arqos                ( 4'h0 ) ,
  .s_axi_aruser               ( 1'b0  ) ,
  .s_axi_arvalid              ( s_axi_arvalid ) ,
  .s_axi_arready              ( s_axi_arready ) ,
  .s_axi_arregion             ( 4'h0 ) ,
  .s_axi_rid                  ( s_axi_rid     ) ,
  .s_axi_rdata                ( s_axi_rdata   ) ,
  .s_axi_rresp                ( s_axi_rresp   ) ,
  .s_axi_rlast                ( s_axi_rlast   ) ,
  .s_axi_ruser                ( ) ,
  .s_axi_rvalid               ( s_axi_rvalid  ) ,
  .s_axi_rready               ( s_axi_rready  ) ,
  .m_axi_awid                 ( si_rs_awid    ) ,
  .m_axi_awaddr               ( si_rs_awaddr  ) ,
  .m_axi_awlen                ( si_rs_awlen[((C_S_AXI_PROTOCOL == 1) ? 4 : 8)-1:0] ) ,
  .m_axi_awsize               ( si_rs_awsize  ) ,
  .m_axi_awburst              ( si_rs_awburst ) ,
  .m_axi_awlock               ( ) ,
  .m_axi_awcache              ( ) ,
  .m_axi_awprot               ( si_rs_awprot  ) ,
  .m_axi_awqos                ( ) ,
  .m_axi_awuser               ( ) ,
  .m_axi_awvalid              ( si_rs_awvalid ) ,
  .m_axi_awready              ( si_rs_awready ) ,
  .m_axi_awregion             ( ) ,
  .m_axi_wid                  ( ) ,
  .m_axi_wdata                ( si_rs_wdata   ) ,
  .m_axi_wstrb                ( si_rs_wstrb   ) ,
  .m_axi_wlast                ( si_rs_wlast   ) ,
  .m_axi_wuser                ( ) ,
  .m_axi_wvalid               ( si_rs_wvalid  ) ,
  .m_axi_wready               ( si_rs_wready  ) ,
  .m_axi_bid                  ( si_rs_bid     ) ,
  .m_axi_bresp                ( si_rs_bresp   ) ,
  .m_axi_buser                ( 1'b0 ) ,
  .m_axi_bvalid               ( si_rs_bvalid  ) ,
  .m_axi_bready               ( si_rs_bready  ) ,
  .m_axi_arid                 ( si_rs_arid    ) ,
  .m_axi_araddr               ( si_rs_araddr  ) ,
  .m_axi_arlen                ( si_rs_arlen[((C_S_AXI_PROTOCOL == 1) ? 4 : 8)-1:0] ) ,
  .m_axi_arsize               ( si_rs_arsize  ) ,
  .m_axi_arburst              ( si_rs_arburst ) ,
  .m_axi_arlock               ( ) ,
  .m_axi_arcache              ( ) ,
  .m_axi_arprot               ( si_rs_arprot  ) ,
  .m_axi_arqos                ( ) ,
  .m_axi_aruser               ( ) ,
  .m_axi_arvalid              ( si_rs_arvalid ) ,
  .m_axi_arready              ( si_rs_arready ) ,
  .m_axi_arregion             ( ) ,
  .m_axi_rid                  ( si_rs_rid     ) ,
  .m_axi_rdata                ( si_rs_rdata   ) ,
  .m_axi_rresp                ( si_rs_rresp   ) ,
  .m_axi_rlast                ( si_rs_rlast   ) ,
  .m_axi_ruser                ( 1'b0 ) ,
  .m_axi_rvalid               ( si_rs_rvalid  ) ,
  .m_axi_rready               ( si_rs_rready  )
);

generate
  if (C_AXI_SUPPORTS_WRITE == 1) begin : WR
    axi_protocol_converter_v2_1_6_b2s_aw_channel #
    (
      .C_ID_WIDTH                       ( C_AXI_ID_WIDTH   ),
      .C_AXI_ADDR_WIDTH                 ( C_AXI_ADDR_WIDTH )
    )
    aw_channel_0
    (
      .clk                              ( aclk              ) ,
      .reset                            ( areset_d1         ) ,
      .s_awid                           ( si_rs_awid        ) ,
      .s_awaddr                         ( si_rs_awaddr      ) ,
      .s_awlen                          ( (C_S_AXI_PROTOCOL == 1) ? {4'h0,si_rs_awlen[3:0]} : si_rs_awlen),
      .s_awsize                         ( si_rs_awsize      ) ,
      .s_awburst                        ( si_rs_awburst     ) ,
      .s_awvalid                        ( si_rs_awvalid     ) ,
      .s_awready                        ( si_rs_awready     ) ,
      .m_awvalid                        ( rs_mi_awvalid     ) ,
      .m_awaddr                         ( rs_mi_awaddr      ) ,
      .m_awready                        ( rs_mi_awready     ) ,
      .b_push                           ( b_push            ) ,
      .b_awid                           ( b_awid            ) ,
      .b_awlen                          ( b_awlen           ) ,
      .b_full                           ( b_full            )
    );

    axi_protocol_converter_v2_1_6_b2s_b_channel #
    (
      .C_ID_WIDTH                       ( C_AXI_ID_WIDTH   )
    )
    b_channel_0
    (
      .clk                              ( aclk            ) ,
      .reset                            ( areset_d1       ) ,
      .s_bid                            ( si_rs_bid       ) ,
      .s_bresp                          ( si_rs_bresp     ) ,
      .s_bvalid                         ( si_rs_bvalid    ) ,
      .s_bready                         ( si_rs_bready    ) ,
      .m_bready                         ( rs_mi_bready    ) ,
      .m_bvalid                         ( rs_mi_bvalid    ) ,
      .m_bresp                          ( rs_mi_bresp     ) ,
      .b_push                           ( b_push          ) ,
      .b_awid                           ( b_awid          ) ,
      .b_awlen                          ( b_awlen         ) ,
      .b_full                           ( b_full          ) ,
      .b_resp_rdy                       ( si_rs_awready   )
    );
    
    assign rs_mi_wdata        = si_rs_wdata;
    assign rs_mi_wstrb        = si_rs_wstrb;
    assign rs_mi_wvalid       = si_rs_wvalid;
    assign si_rs_wready       = rs_mi_wready;

  end else begin : NO_WR
    assign rs_mi_awaddr       = {C_AXI_ADDR_WIDTH{1'b0}};
    assign rs_mi_awvalid      = 1'b0;
    assign si_rs_awready      = 1'b0;

    assign rs_mi_wdata        = {C_AXI_DATA_WIDTH{1'b0}};
    assign rs_mi_wstrb        = {C_AXI_DATA_WIDTH/8{1'b0}};
    assign rs_mi_wvalid       = 1'b0;
    assign si_rs_wready       = 1'b0;

    assign rs_mi_bready    = 1'b0;
    assign si_rs_bvalid       = 1'b0;
    assign si_rs_bresp        = 2'b00;
    assign si_rs_bid          = {C_AXI_ID_WIDTH{1'b0}};
  end
endgenerate


// AR/R channel communication
wire                                r_push        ;
wire [C_AXI_ID_WIDTH-1:0]           r_arid        ;
wire                                r_rlast       ;
wire                                r_full        ;

generate
  if (C_AXI_SUPPORTS_READ == 1) begin : RD
    axi_protocol_converter_v2_1_6_b2s_ar_channel #
    (
      .C_ID_WIDTH                       ( C_AXI_ID_WIDTH   ),
      .C_AXI_ADDR_WIDTH                 ( C_AXI_ADDR_WIDTH )
    
    )
    ar_channel_0
    (
      .clk                              ( aclk              ) ,
      .reset                            ( areset_d1         ) ,
      .s_arid                           ( si_rs_arid        ) ,
      .s_araddr                         ( si_rs_araddr      ) ,
      .s_arlen                          ( (C_S_AXI_PROTOCOL == 1) ? {4'h0,si_rs_arlen[3:0]} : si_rs_arlen),
      .s_arsize                         ( si_rs_arsize      ) ,
      .s_arburst                        ( si_rs_arburst     ) ,
      .s_arvalid                        ( si_rs_arvalid     ) ,
      .s_arready                        ( si_rs_arready     ) ,
      .m_arvalid                        ( rs_mi_arvalid     ) ,
      .m_araddr                         ( rs_mi_araddr      ) ,
      .m_arready                        ( rs_mi_arready     ) ,
      .r_push                           ( r_push            ) ,
      .r_arid                           ( r_arid            ) ,
      .r_rlast                          ( r_rlast           ) ,
      .r_full                           ( r_full            )
    );
    
    axi_protocol_converter_v2_1_6_b2s_r_channel #
    (
      .C_ID_WIDTH                       ( C_AXI_ID_WIDTH   ),
      .C_DATA_WIDTH                     ( C_AXI_DATA_WIDTH )
    )
    r_channel_0
    (
      .clk                              ( aclk            ) ,
      .reset                            ( areset_d1       ) ,
      .s_rid                            ( si_rs_rid       ) ,
      .s_rdata                          ( si_rs_rdata     ) ,
      .s_rresp                          ( si_rs_rresp     ) ,
      .s_rlast                          ( si_rs_rlast     ) ,
      .s_rvalid                         ( si_rs_rvalid    ) ,
      .s_rready                         ( si_rs_rready    ) ,
      .m_rvalid                         ( rs_mi_rvalid    ) ,
      .m_rready                         ( rs_mi_rready    ) ,
      .m_rdata                          ( rs_mi_rdata     ) ,
      .m_rresp                          ( rs_mi_rresp     ) ,
      .r_push                           ( r_push          ) ,
      .r_full                           ( r_full          ) ,
      .r_arid                           ( r_arid          ) ,
      .r_rlast                          ( r_rlast         )
    );
  end else begin : NO_RD
    assign rs_mi_araddr       = {C_AXI_ADDR_WIDTH{1'b0}};
    assign rs_mi_arvalid      = 1'b0;
    assign si_rs_arready      = 1'b0;
    assign si_rs_rlast        = 1'b1;

    assign si_rs_rdata        = {C_AXI_DATA_WIDTH{1'b0}};
    assign si_rs_rvalid       = 1'b0;
    assign si_rs_rresp        = 2'b00;
    assign si_rs_rid          = {C_AXI_ID_WIDTH{1'b0}};
    assign rs_mi_rready       = 1'b0;
  end
endgenerate

axi_register_slice_v2_1_6_axi_register_slice #(
  .C_AXI_PROTOCOL              ( 2 ) ,
  .C_AXI_ID_WIDTH              ( 1 ) ,
  .C_AXI_ADDR_WIDTH            ( C_AXI_ADDR_WIDTH            ) ,
  .C_AXI_DATA_WIDTH            ( C_AXI_DATA_WIDTH            ) ,
  .C_AXI_SUPPORTS_USER_SIGNALS ( 0 ) ,
  .C_AXI_AWUSER_WIDTH          ( 1 ) ,
  .C_AXI_ARUSER_WIDTH          ( 1 ) ,
  .C_AXI_WUSER_WIDTH           ( 1 ) ,
  .C_AXI_RUSER_WIDTH           ( 1 ) ,
  .C_AXI_BUSER_WIDTH           ( 1 ) ,
  .C_REG_CONFIG_AW             ( 0 ) ,
  .C_REG_CONFIG_AR             ( 0 ) ,
  .C_REG_CONFIG_W              ( 0 ) ,
  .C_REG_CONFIG_R              ( 0 ) ,
  .C_REG_CONFIG_B              ( 0 )
) MI_REG (
  .aresetn                    ( aresetn       ) ,
  .aclk                       ( aclk          ) ,
  .s_axi_awid                 ( 1'b0          ) ,
  .s_axi_awaddr               ( rs_mi_awaddr  ) ,
  .s_axi_awlen                ( 8'h00         ) ,
  .s_axi_awsize               ( 3'b000        ) ,
  .s_axi_awburst              ( 2'b01         ) ,
  .s_axi_awlock               ( 1'b0          ) ,
  .s_axi_awcache              ( 4'h0          ) ,
  .s_axi_awprot               ( si_rs_awprot  ) ,
  .s_axi_awqos                ( 4'h0          ) ,
  .s_axi_awuser               ( 1'b0          ) ,
  .s_axi_awvalid              ( rs_mi_awvalid ) ,
  .s_axi_awready              ( rs_mi_awready ) ,
  .s_axi_awregion             ( 4'h0          ) ,
  .s_axi_wid                  ( 1'b0          ) ,
  .s_axi_wdata                ( rs_mi_wdata   ) ,
  .s_axi_wstrb                ( rs_mi_wstrb   ) ,
  .s_axi_wlast                ( 1'b1          ) ,
  .s_axi_wuser                ( 1'b0          ) ,
  .s_axi_wvalid               ( rs_mi_wvalid  ) ,
  .s_axi_wready               ( rs_mi_wready  ) ,
  .s_axi_bid                  (               ) ,
  .s_axi_bresp                ( rs_mi_bresp   ) ,
  .s_axi_buser                (               ) ,
  .s_axi_bvalid               ( rs_mi_bvalid  ) ,
  .s_axi_bready               ( rs_mi_bready  ) ,
  .s_axi_arid                 ( 1'b0          ) ,
  .s_axi_araddr               ( rs_mi_araddr  ) ,
  .s_axi_arlen                ( 8'h00         ) ,
  .s_axi_arsize               ( 3'b000        ) ,
  .s_axi_arburst              ( 2'b01         ) ,
  .s_axi_arlock               ( 1'b0          ) ,
  .s_axi_arcache              ( 4'h0          ) ,
  .s_axi_arprot               ( si_rs_arprot  ) ,
  .s_axi_arqos                ( 4'h0          ) ,
  .s_axi_aruser               ( 1'b0          ) ,
  .s_axi_arvalid              ( rs_mi_arvalid ) ,
  .s_axi_arready              ( rs_mi_arready ) ,
  .s_axi_arregion             ( 4'h0          ) ,
  .s_axi_rid                  (               ) ,
  .s_axi_rdata                ( rs_mi_rdata   ) ,
  .s_axi_rresp                ( rs_mi_rresp   ) ,
  .s_axi_rlast                (               ) ,
  .s_axi_ruser                (               ) ,
  .s_axi_rvalid               ( rs_mi_rvalid  ) ,
  .s_axi_rready               ( rs_mi_rready  ) ,
  .m_axi_awid                 (               ) ,
  .m_axi_awaddr               ( m_axi_awaddr  ) ,
  .m_axi_awlen                (               ) ,
  .m_axi_awsize               (               ) ,
  .m_axi_awburst              (               ) ,
  .m_axi_awlock               (               ) ,
  .m_axi_awcache              (               ) ,
  .m_axi_awprot               ( m_axi_awprot  ) ,
  .m_axi_awqos                (               ) ,
  .m_axi_awuser               (               ) ,
  .m_axi_awvalid              ( m_axi_awvalid ) ,
  .m_axi_awready              ( m_axi_awready ) ,
  .m_axi_awregion             (               ) ,
  .m_axi_wid                  (               ) ,
  .m_axi_wdata                ( m_axi_wdata   ) ,
  .m_axi_wstrb                ( m_axi_wstrb   ) ,
  .m_axi_wlast                (               ) ,
  .m_axi_wuser                (               ) ,
  .m_axi_wvalid               ( m_axi_wvalid  ) ,
  .m_axi_wready               ( m_axi_wready  ) ,
  .m_axi_bid                  ( 1'b0          ) ,
  .m_axi_bresp                ( m_axi_bresp   ) ,
  .m_axi_buser                ( 1'b0          ) ,
  .m_axi_bvalid               ( m_axi_bvalid  ) ,
  .m_axi_bready               ( m_axi_bready  ) ,
  .m_axi_arid                 (               ) ,
  .m_axi_araddr               ( m_axi_araddr  ) ,
  .m_axi_arlen                (               ) ,
  .m_axi_arsize               (               ) ,
  .m_axi_arburst              (               ) ,
  .m_axi_arlock               (               ) ,
  .m_axi_arcache              (               ) ,
  .m_axi_arprot               ( m_axi_arprot  ) ,
  .m_axi_arqos                (               ) ,
  .m_axi_aruser               (               ) ,
  .m_axi_arvalid              ( m_axi_arvalid ) ,
  .m_axi_arready              ( m_axi_arready ) ,
  .m_axi_arregion             (               ) ,
  .m_axi_rid                  ( 1'b0          ) ,
  .m_axi_rdata                ( m_axi_rdata   ) ,
  .m_axi_rresp                ( m_axi_rresp   ) ,
  .m_axi_rlast                ( 1'b1          ) ,
  .m_axi_ruser                ( 1'b0          ) ,
  .m_axi_rvalid               ( m_axi_rvalid  ) ,
  .m_axi_rready               ( m_axi_rready  )
);

endmodule

`default_nettype wire
