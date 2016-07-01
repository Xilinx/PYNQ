`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// 
//////////////////////////////////////////////////////////////////////////////////
module arduino_switch_digital_uart_bit(
// configuration
    input gpio_sel,  // 0=digital I/O, 1= uart
// Shield connector side
    input tri_i_out,   // data from shield pin to switch
    output reg tri_o_out,   // data from switch to shield pin
    output reg tri_t_out,   // tri state control from switch to shield pin
// PL side
    // digital I/O
    output tri_i_in,   // data from switch to PL
    input tri_o_in,    // data from PL to switch
    input tri_t_in,    // tri state control from PL to switch
    // RX and TX of UART
    output rx_i_in,  // rx data from switch to UART 
    input tx_o_in,   // tx data from UART to switch
    input tx_t_in    // tx tri state control from UART to switch
    );

    reg [1:0] tri_i_out_demux;
    assign {rx_i_in, tri_i_in} = tri_i_out_demux;

    always @(gpio_sel, tri_o_in, tx_o_in)
       case (gpio_sel)
          1'h0: tri_o_out = tri_o_in;       // digital I/O
          1'h1: tri_o_out = tx_o_in;        // tx
       endcase

    always @(gpio_sel, tri_i_out)
    begin
       tri_i_out_demux = {2{1'b0}};
       case (gpio_sel)
          1'h0: tri_i_out_demux[0] = tri_i_out;     // digital I/O
          1'h1: tri_i_out_demux[1] = tri_i_out;     // rx
       endcase
    end

    always @(gpio_sel, tri_t_in, tx_t_in)
       case (gpio_sel)
          1'h0: tri_t_out = tri_t_in;       // digital I/O
          1'h1: tri_t_out = tx_t_in;        // tx
       endcase
    
endmodule
