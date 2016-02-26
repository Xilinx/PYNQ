///////////////////////////////////////////////////////////////////////////////
//
// File name: axi_protocol_converter_v2_1_6_b2s_rd_cmd_fsm.v
//
///////////////////////////////////////////////////////////////////////////////
`timescale 1ps/1ps
`default_nettype none

(* DowngradeIPIdentifiedWarnings="yes" *) 
module axi_protocol_converter_v2_1_6_b2s_rd_cmd_fsm (
///////////////////////////////////////////////////////////////////////////////
// Port Declarations
///////////////////////////////////////////////////////////////////////////////
  input  wire                                 clk           ,
  input  wire                                 reset         ,
  output wire                                 s_arready       ,
  input  wire                                 s_arvalid       ,
  input  wire [7:0]                           s_arlen         ,
  output wire                                 m_arvalid        ,
  input  wire                                 m_arready      ,
  // signal to increment to the next mc transaction
  output wire                                 next          ,
  // signal to the fsm there is another transaction required
  input  wire                                 next_pending  ,
  // Write Data portion has completed or Read FIFO has a slot available (not
  // full)
  input  wire                                 data_ready    ,
  // status signal for w_channel when command is written.
  output wire                                 a_push        ,
  output wire                                 r_push
);

////////////////////////////////////////////////////////////////////////////////
// Local parameters
////////////////////////////////////////////////////////////////////////////////
// States
localparam SM_IDLE                = 2'b00;
localparam SM_CMD_EN              = 2'b01;
localparam SM_CMD_ACCEPTED        = 2'b10;
localparam SM_DONE                = 2'b11;

////////////////////////////////////////////////////////////////////////////////
// Wires/Reg declarations
////////////////////////////////////////////////////////////////////////////////
reg [1:0]       state;
// synthesis attribute MAX_FANOUT of state is 20;
reg [1:0]       state_r1;
reg [1:0]       next_state;
reg [7:0]       s_arlen_r;

////////////////////////////////////////////////////////////////////////////////
// BEGIN RTL
///////////////////////////////////////////////////////////////////////////////


// register for timing
always @(posedge clk) begin
  if (reset) begin
    state <= SM_IDLE;
    state_r1 <= SM_IDLE;
    s_arlen_r  <= 0;
  end else begin
    state <= next_state;
    state_r1 <= state;
    s_arlen_r  <= s_arlen;
  end
end

// Next state transitions.
always @( * ) begin
  next_state = state;
  case (state)
    SM_IDLE:
      if (s_arvalid & data_ready) begin
        next_state = SM_CMD_EN;
      end else begin
        next_state = state;
      end
    SM_CMD_EN:
    ///////////////////////////////////////////////////////////////////
    // Drive m_arvalid downstream in this state
      ///////////////////////////////////////////////////////////////////
      //If there is no fifo space
      if (~data_ready & m_arready & next_pending) begin
        ///////////////////////////////////////////////////////////////////
        //There is more to do, wait until data space is available drop valid
        next_state = SM_CMD_ACCEPTED;
      end else if (m_arready & ~next_pending)begin
         next_state = SM_DONE;
      end else if (m_arready & next_pending) begin
        next_state = SM_CMD_EN;
      end else begin
        next_state = state;
      end

    SM_CMD_ACCEPTED:
      if (data_ready) begin
        next_state = SM_CMD_EN;
      end else begin
        next_state = state;
      end

    SM_DONE:
        next_state = SM_IDLE;

      default:
        next_state = SM_IDLE;
  endcase
end

// Assign outputs based on current state.

assign m_arvalid  = (state == SM_CMD_EN);
assign next    = m_arready && (state == SM_CMD_EN);
assign         r_push  = next;
assign a_push  = (state == SM_IDLE);
assign s_arready = ((state == SM_CMD_EN) || (state == SM_DONE))  && (next_state == SM_IDLE);

endmodule
`default_nettype wire


