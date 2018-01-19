`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Module Name: io_switch_bit
// Project Name: PYNQ
// Description: IO switch supporting PMOD, Dual PMOD, Arduino, RaspberryPi
//////////////////////////////////////////////////////////////////////////////////
// gpio_sel[7:0] 
//          00000000 = GPIO
//          00000001 = Interrupt In
//			00000010 = UART0_TX
//			00000011 = UART0_RX
//          00000100 = SPICK0 (output ony)
//          00000101 = MISO0 (input only)
//          00000110 = MOSI0 (output only)
//          00000111 = SS0[0] (output only)
//          00001000 = SPICK1 (output ony)
//          00001001 = MISO1 (input only)
//          00001010 = MOSI1 (output only)
//          00001011 = SS1 (output only)
//          00001100 = I2C SDA0
//          00001101 = I2C SCL0
//          00001110 = I2C SDA1
//          00001111 = I2C SCL1

//          00010000 = PWM0 (output only)
//          00010001 = PWM1 (output only)
//          00010010 = PWM2 (output only)
//          00010011 = PWM3 (output only)
//          00010100 = PWM4 (output only)
//          00010101 = PWM5 (output only)
//          00010110 = Not used
//          00010111 = SS0[1] (output only)

//          00011000 = Output Compare/GCLK0 (output) 
//          00011001 = Output Compare/GCLK1 (output) 
//          00011010 = Output Compare/GCLK2 (output) 
//          00011011 = Output Compare/GCLK3 (output) 
//          00011100 = Output Compare/GCLK4 (output) 
//          00011101 = Output Compare/GCLK5 (output) 
//          00011110 = Output Compare/GCLK6 (output) 
//          00011111 = Output Compare/GCLK7 (output) 

//			00100010 = UART1_TX
//			00100011 = UART1_RX

//          00111000 = Input Capture0 (Input) 
//          00111001 = Input Capture1 (Input) 
//          00111010 = Input Capture2 (Input) 
//          00111011 = Input Capture3 (Input) 
//          00111100 = Input Capture4 (Input) 
//          00111101 = Input Capture5 (Input) 
//          00111110 = Input Capture6 (Input) 
//          00111111 = Input Capture7 (Input) 

//          rest for future expansion

module io_switch_bit #(
    parameter C_NUM_PWMS = 6,
    parameter C_NUM_TIMERS = 8,
    parameter C_NUM_SS = 2
    )
    (
// configuration
    input [7:0] gpio_sel,
// connector side
    input io_data_i,
    output reg io_data_o,
    output reg io_tri_o,
// PL side
    // digital I/O
    output gpio_data_i,
    input gpio_data_o,
    input gpio_tri_o,
    // UART0 
    output uart0_rx_i,
    input uart0_tx_o,
    // UART1 
    output uart1_rx_i,
    input uart1_tx_o,
    // SPI0
    output  sck0_i,
    input  sck0_o,
    input  sck0_t,
    output  miso0_i,
    input  miso0_o,
    input  miso0_t,
    output  mosi0_i,
    input  mosi0_o,
    input  mosi0_t,
    output  ss0_i,
    input [C_NUM_SS-1:0] ss0_o,
    input  ss0_t,
    // SPI1
    output  sck1_i,
    input  sck1_o,
    input  sck1_t,
    output  miso1_i,
    input  miso1_o,
    input  miso1_t,
    output  mosi1_i,
    input  mosi1_o,
    input  mosi1_t,
    output  ss1_i,
    input  ss1_o,
    input  ss1_t,
    // Interrupts
    output interrupt_i,
    // i2c0 
    output sda0_i,
    input sda0_o,
    input sda0_t,
    output scl0_i,
    input scl0_o,
    input scl0_t,
    // i2c1
    output sda1_i,
    input sda1_o,
    input sda1_t,
    output scl1_i,
    input scl1_o,
    input scl1_t,
    // PWM
    input [C_NUM_PWMS-1:0] pwm_o,
    // Timer
    output timer_i_0, // Input capture
    output timer_i_1, // Input capture
    output timer_i_2, // Input capture
    output timer_i_3, // Input capture
    output timer_i_4, // Input capture
    output timer_i_5, // Input capture
    output timer_i_6, // Input capture
    output timer_i_7, // Input capture

    input [C_NUM_TIMERS-1:0] timer_o  // output compare
    );

    reg [23:0] i_demux;

    always @(gpio_sel, uart0_tx_o, uart1_tx_o, sda1_o, scl1_o, sda0_o, scl0_o, gpio_data_o, pwm_o, timer_o, sck1_o, miso1_o, mosi1_o, ss1_o, sck0_o, miso0_o, mosi0_o, ss0_o)
       case (gpio_sel)
          8'h00: io_data_o = gpio_data_o;
          8'h01: io_data_o = 1'b0;       // interrupt is input only 
		  8'h02: io_data_o = uart0_tx_o;
//          8'h03: io_data_o = uart1_tx_o;
          8'h04: io_data_o = sck0_o;
          8'h05: io_data_o = miso0_o;
          8'h06: io_data_o = mosi0_o;
          8'h07: io_data_o = ss0_o[0];
		  8'h08: io_data_o = sck1_o;
		  8'h09: io_data_o = miso1_o;
          8'h0a: io_data_o = mosi1_o;
          8'h0b: io_data_o = ss1_o;	  
		  8'h0c: io_data_o = sda0_o;
		  8'h0d: io_data_o = scl0_o;
		  8'h0e: io_data_o = sda1_o;
		  8'h0f: io_data_o = scl1_o;
		  
          8'h10: io_data_o = pwm_o[0];
          8'h11: io_data_o = pwm_o[1];        
          8'h12: io_data_o = pwm_o[2];
          8'h13: io_data_o = pwm_o[3];
          8'h14: io_data_o = pwm_o[4];
          8'h15: io_data_o = pwm_o[5];
          8'h17: io_data_o = ss0_o[1];

          8'h18: io_data_o = timer_o[0];
          8'h19: io_data_o = timer_o[1];
          8'h1a: io_data_o = timer_o[2];
          8'h1b: io_data_o = timer_o[3];      
          8'h1c: io_data_o = timer_o[4];
          8'h1d: io_data_o = timer_o[5];
          8'h1e: io_data_o = timer_o[6];
          8'h1f: io_data_o = timer_o[7];

          8'h22: io_data_o = uart1_tx_o;

          default: io_data_o = gpio_data_o;
       endcase

//    assign {timer_i, scl1_i, sda1_i, scl0_i, sda0_i, ss1_i,mosi1_i,miso1_i,sck1_i, ss0_i,mosi0_i,miso0_i,sck0_i,uart1_rx_i, uart0_rx_i, interrupt_i,gpio_data_i} = i_demux;
    assign {timer_i_7, timer_i_6, timer_i_5, timer_i_4, timer_i_3, timer_i_2, timer_i_1, timer_i_0, scl1_i, sda1_i, scl0_i, sda0_i, ss1_i,mosi1_i,miso1_i,sck1_i, ss0_i,mosi0_i,miso0_i,sck0_i,uart1_rx_i, uart0_rx_i, interrupt_i,gpio_data_i} = i_demux;

    always @(gpio_sel, io_data_i)
    begin
       i_demux = {24{1'b0}};
       case (gpio_sel)
          8'h00: i_demux[0] = io_data_i;
          8'h01: i_demux[1] = io_data_i;
          8'h03: i_demux[2] = io_data_i;   // uart0_rx_i
//          8'h03: i_demux[3] = io_data_i;   
          8'h04: i_demux[4] = io_data_i;
          8'h05: i_demux[5] = io_data_i;
          8'h06: i_demux[6] = io_data_i;
          8'h07: i_demux[7] = io_data_i;
		  8'h08: i_demux[8] = io_data_i;
          8'h09: i_demux[9] = io_data_i;
          8'h0a: i_demux[10] = io_data_i;
          8'h0b: i_demux[11] = io_data_i;
          8'h0c: i_demux[12] = io_data_i;
          8'h0d: i_demux[13] = io_data_i;	
          8'h0e: i_demux[14] = io_data_i;	
          8'h0f: i_demux[15] = io_data_i;	

          8'h23: i_demux[3] = io_data_i;   // uart1_rx_i

          8'h38: i_demux[16] = io_data_i;	// timer input capture
          8'h39: i_demux[17] = io_data_i;	
          8'h3a: i_demux[18] = io_data_i;   
          8'h3b: i_demux[19] = io_data_i;   
          8'h3c: i_demux[20] = io_data_i;
          8'h3d: i_demux[21] = io_data_i;
          8'h3e: i_demux[22] = io_data_i;
          8'h3f: i_demux[23] = io_data_i;
          
          default: i_demux[0] = io_data_i;
       endcase
    end

    always @(gpio_sel, sda1_t, scl1_t, sda0_t, scl0_t, gpio_tri_o, sck1_t, miso1_t, mosi1_t, ss1_t, sck0_t, miso0_t, mosi0_t, ss0_t)
       case (gpio_sel)
          8'h00: io_tri_o = gpio_tri_o;
          8'h01: io_tri_o = 1'b1;   // interrupt is input only so tristate it
		  8'h02: io_tri_o = 1'b0;     // uart0_tx
          8'h03: io_tri_o = 1'b1;     // uart0_rx
          8'h04: io_tri_o = sck0_t;
          8'h05: io_tri_o = miso0_t;
          8'h06: io_tri_o = mosi0_t;
          8'h07: io_tri_o = ss0_t;
          8'h08: io_tri_o = sck1_t;
          8'h09: io_tri_o = miso1_t;
          8'h0a: io_tri_o = mosi1_t;
          8'h0b: io_tri_o = ss1_t;      
          8'h0c: io_tri_o = sda0_t;
          8'h0d: io_tri_o = scl0_t;
          8'h0e: io_tri_o = sda1_t;
          8'h0f: io_tri_o = scl1_t;
          
          8'h10: io_tri_o = 1'b0; // pwm_t[0];        
          8'h11: io_tri_o = 1'b0; // pwm_t[1];        
          8'h12: io_tri_o = 1'b0; // pwm_t[2];
          8'h13: io_tri_o = 1'b0; // pwm_t[3];
          8'h14: io_tri_o = 1'b0; // pwm_t[4];
          8'h15: io_tri_o = 1'b0; // pwm_t[5];

          8'h18: io_tri_o = 1'b0; // for output capture[0]
          8'h19: io_tri_o = 1'b0; // for output capture[1];
          8'h1a: io_tri_o = 1'b0; // for output capture[2];
          8'h1b: io_tri_o = 1'b0; // for output capture[3];      
          8'h1c: io_tri_o = 1'b0; // for output capture[4];
          8'h1d: io_tri_o = 1'b0; // for output capture[5];
          8'h1e: io_tri_o = 1'b0; // for output capture[6];
          8'h1f: io_tri_o = 1'b0; // for output capture[7];

 		  8'h22: io_tri_o = 1'b0; // uart1_tx_o;
          8'h23: io_tri_o = 1'b1; // uart1_rx_i;

          8'h38: io_tri_o = 1'b1; // for input capture[0]
          8'h39: io_tri_o = 1'b1; // for input capture[1]
          8'h3a: io_tri_o = 1'b1; // for input capture[2]
          8'h3b: io_tri_o = 1'b1; // for input capture[3]      
          8'h3c: io_tri_o = 1'b1; // for input capture[4]
          8'h3d: io_tri_o = 1'b1; // for input capture[5]
          8'h3e: io_tri_o = 1'b1; // for input capture[6]
          8'h3f: io_tri_o = 1'b1; // for input capture[7]

         default: io_tri_o = gpio_tri_o;
       endcase
    
endmodule
