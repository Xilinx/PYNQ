///////////////////////////////////////////////////////////////////////////////
//
// File name: axi_protocol_converter_v2_1_6_b2s_wr_cmd_fsm.v
//
///////////////////////////////////////////////////////////////////////////////
`timescale 1ps/1ps
`default_nettype none

(* DowngradeIPIdentifiedWarnings="yes" *) 
module axi_protocol_converter_v2_1_6_b2s_wr_cmd_fsm (
///////////////////////////////////////////////////////////////////////////////
// Port Declarations
///////////////////////////////////////////////////////////////////////////////
  input  wire                                 clk           ,
  input  wire                                 reset         ,
  output wire                                 s_awready       ,
  input  wire                                 s_awvalid       ,
  output wire                                 m_awvalid        ,
  input  wire                                 m_awready      ,
  // signal to increment to the next mc transaction
  output wire                                 next          ,
  // signal to the fsm there is another transaction required
  input  wire                                 next_pending  ,
  // Write Data portion has completed or Read FIFO has a slot available (not
  // full)
  output wire                                 b_push        ,
  input  wire                                 b_full        ,
  output wire                                 a_push
);

////////////////////////////////////////////////////////////////////////////////
// Local parameters
////////////////////////////////////////////////////////////////////////////////
// States
localparam SM_IDLE                = 2'b00;
localparam SM_CMD_EN              = 2'b01;
localparam SM_CMD_ACCEPTED        = 2'b10;
localparam SM_DONE_WAIT           = 2'b11;

////////////////////////////////////////////////////////////////////////////////
// Wires/Reg declarations
////////////////////////////////////////////////////////////////////////////////
reg [1:0]       state;
// synthesis attribute MAX_FANOUT of state is 20;
reg [1:0]       next_state;

////////////////////////////////////////////////////////////////////////////////
// BEGIN RTL
///////////////////////////////////////////////////////////////////////////////


always @(posedge clk) begin
  if (reset) begin
    state <= SM_IDLE;
  end else begin
    state <= next_state;
  end
end

// Next state transitions.
always @( * )
begin
  next_state = state;
  case (state)
    SM_IDLE:
      if (s_awvalid) begin
        next_state = SM_CMD_EN;
      end else
        next_state = state;

    SM_CMD_EN:
      if (m_awready & next_pending)
        next_state = SM_CMD_ACCEPTED;
      else if (m_awready & ~next_pending & b_full)
        next_state = SM_DONE_WAIT;
      else if (m_awready & ~next_pending & ~b_full)
        next_state = SM_IDLE;
      else
        next_state = state;

    SM_CMD_ACCEPTED:
      next_state = SM_CMD_EN;

    SM_DONE_WAIT:
      if (!b_full)
        next_state = SM_IDLE;
      else
        next_state = state;

      default:
        next_state = SM_IDLE;
  endcase
end

// Assign outputs based on current state.

assign m_awvalid  = (state == SM_CMD_EN);

assign next    = ((state == SM_CMD_ACCEPTED)
                 | (((state == SM_CMD_EN) | (state == SM_DONE_WAIT)) & (next_state == SM_IDLE))) ;

assign a_push  = (state == SM_IDLE);
assign s_awready = ((state == SM_CMD_EN) | (state == SM_DONE_WAIT)) & (next_state == SM_IDLE);
assign b_push  = ((state == SM_CMD_EN) | (state == SM_DONE_WAIT)) & (next_state == SM_IDLE);

endmodule
`default_nettype wire


