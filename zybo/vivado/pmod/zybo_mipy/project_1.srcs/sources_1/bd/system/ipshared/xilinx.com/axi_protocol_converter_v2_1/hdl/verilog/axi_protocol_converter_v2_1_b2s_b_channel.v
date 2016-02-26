///////////////////////////////////////////////////////////////////////////////
//
// File name: axi_protocol_converter_v2_1_6_b2s_b_channel.v
//
///////////////////////////////////////////////////////////////////////////////
`timescale 1ps/1ps
`default_nettype none

(* DowngradeIPIdentifiedWarnings="yes" *) 
module axi_protocol_converter_v2_1_6_b2s_b_channel #
(
///////////////////////////////////////////////////////////////////////////////
// Parameter Definitions
///////////////////////////////////////////////////////////////////////////////
                    // Width of ID signals.
                    // Range: >= 1.
  parameter integer C_ID_WIDTH                = 4
)
(
///////////////////////////////////////////////////////////////////////////////
// Port Declarations
///////////////////////////////////////////////////////////////////////////////
  input  wire                                 clk,
  input  wire                                 reset,

  // AXI signals
  output wire [C_ID_WIDTH-1:0]                s_bid,
  output wire [1:0]                           s_bresp,
  output wire                                 s_bvalid,
  input  wire                                 s_bready,

  input  wire [1:0]                           m_bresp,
  input  wire                                 m_bvalid,
  output wire                                 m_bready,


  // Signals to/from the axi_protocol_converter_v2_1_6_b2s_aw_channel modules
  input  wire                                 b_push,
  input  wire [C_ID_WIDTH-1:0]                b_awid,
  input  wire [7:0]                           b_awlen,
  input  wire                                 b_resp_rdy,
  output wire                                 b_full

);

////////////////////////////////////////////////////////////////////////////////
// Local parameters
////////////////////////////////////////////////////////////////////////////////
// AXI protocol responses:
localparam [1:0] LP_RESP_OKAY        = 2'b00;
localparam [1:0] LP_RESP_EXOKAY      = 2'b01;
localparam [1:0] LP_RESP_SLVERROR    = 2'b10;
localparam [1:0] LP_RESP_DECERR      = 2'b11;

// FIFO settings
localparam P_WIDTH  = C_ID_WIDTH + 8;
localparam P_DEPTH  = 4;
localparam P_AWIDTH = 2;

localparam P_RWIDTH  = 2;
localparam P_RDEPTH  = 4;
localparam P_RAWIDTH = 2;

////////////////////////////////////////////////////////////////////////////////
// Wire and register declarations
////////////////////////////////////////////////////////////////////////////////
reg                     bvalid_i;
wire [C_ID_WIDTH-1:0]   bid_i;
wire                    shandshake;
reg                     shandshake_r;
wire                    mhandshake;
reg                     mhandshake_r;

wire                    b_empty;
wire                    bresp_full;
wire                    bresp_empty;
wire [7:0]              b_awlen_i;
reg  [7:0]              bresp_cnt;

reg  [1:0]              s_bresp_acc;
wire [1:0]              s_bresp_acc_r;
reg  [1:0]              s_bresp_i;
wire                    need_to_update_bresp;
wire                    bresp_push;


////////////////////////////////////////////////////////////////////////////////
// BEGIN RTL
////////////////////////////////////////////////////////////////////////////////

// assign AXI outputs
assign s_bid      = bid_i;
assign s_bresp    = s_bresp_acc_r;
assign s_bvalid   = bvalid_i;
assign shandshake = s_bvalid & s_bready;
assign mhandshake = m_bvalid & m_bready;

always @(posedge clk) begin
  if (reset | shandshake) begin
    bvalid_i <= 1'b0;
  end else if (~b_empty & ~shandshake_r & ~bresp_empty) begin
    bvalid_i <= 1'b1;
  end
end

always @(posedge clk) begin
  shandshake_r <= shandshake;
  mhandshake_r <= mhandshake;
end

axi_protocol_converter_v2_1_6_b2s_simple_fifo #(
  .C_WIDTH                  (P_WIDTH),
  .C_AWIDTH                 (P_AWIDTH),
  .C_DEPTH                  (P_DEPTH)
)
bid_fifo_0
(
  .clk     ( clk          ) ,
  .rst     ( reset        ) ,
  .wr_en   ( b_push       ) ,
  .rd_en   ( shandshake_r ) ,
  .din     ( {b_awid, b_awlen} ) ,
  .dout    ( {bid_i, b_awlen_i}) ,
  .a_full  (              ) ,
  .full    ( b_full       ) ,
  .a_empty (              ) ,
  .empty   ( b_empty        )
);

assign m_bready = ~mhandshake_r & bresp_empty;

/////////////////////////////////////////////////////////////////////////////
// Update if more critical.
assign need_to_update_bresp = ( m_bresp > s_bresp_acc );

// Select accumultated or direct depending on setting.
always @( * ) begin
  if ( need_to_update_bresp ) begin
    s_bresp_i = m_bresp;
  end else begin
    s_bresp_i = s_bresp_acc;
  end
end

/////////////////////////////////////////////////////////////////////////////
// Accumulate MI-side BRESP.
always @ (posedge clk) begin
  if (reset | bresp_push ) begin
    s_bresp_acc <= LP_RESP_OKAY;
  end else if ( mhandshake ) begin
    s_bresp_acc <= s_bresp_i;
  end
end

assign bresp_push = ( mhandshake_r ) & (bresp_cnt == b_awlen_i) & ~b_empty;

always @ (posedge clk) begin
  if (reset | bresp_push ) begin
    bresp_cnt <= 8'h00;
  end else if ( mhandshake_r ) begin
    bresp_cnt <= bresp_cnt + 1'b1;
  end
end

axi_protocol_converter_v2_1_6_b2s_simple_fifo #(
  .C_WIDTH                  (P_RWIDTH),
  .C_AWIDTH                 (P_RAWIDTH),
  .C_DEPTH                  (P_RDEPTH)
)
bresp_fifo_0
(
  .clk     ( clk          ) ,
  .rst     ( reset        ) ,
  .wr_en   ( bresp_push   ) ,
  .rd_en   ( shandshake_r ) ,
  .din     ( s_bresp_acc  ) ,
  .dout    ( s_bresp_acc_r) ,
  .a_full  (              ) ,
  .full    ( bresp_full   ) ,
  .a_empty (              ) ,
  .empty   ( bresp_empty  )
);


endmodule

`default_nettype wire
