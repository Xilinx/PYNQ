`timescale 1ns / 1ps

module interface_slice(
// gpio type
gpio_w_i,
gpio_w_o,
gpio_w_t,

gpio_i,
gpio_o,
gpio_t,

// iic type
scl_w_i,
scl_w_o,
scl_w_t,
sda_w_i,
sda_w_o,
sda_w_t,

scl_i,
scl_o,
scl_t,
sda_i,
sda_o,
sda_t,

// spi type
spi0_w_i,
spi0_w_o,
spi0_w_t,
spi1_w_i,
spi1_w_o,
spi1_w_t,
sck_w_i,
sck_w_o,
sck_w_t,
ss_w_i,
ss_w_o,
ss_w_t,

spi0_i,
spi0_o,
spi0_t,
spi1_i,
spi1_o,
spi1_t,
sck_i,
sck_o,
sck_t,
ss_i,
ss_o,
ss_t
);

parameter TYPE = 1;
parameter WIDTH = 1;

// gpio type
input [WIDTH-1:0] gpio_w_i;
input[WIDTH-1:0] gpio_w_o;
input[WIDTH-1:0] gpio_w_t;
output reg [WIDTH-1:0] gpio_i;
output reg [WIDTH-1:0] gpio_o;
output reg [WIDTH-1:0] gpio_t;
// iic type
input scl_w_i;
input scl_w_o;
input scl_w_t;
input sda_w_i;
input sda_w_o;
input sda_w_t;
output reg scl_i;
output reg scl_o;
output reg scl_t;
output reg sda_i;
output reg sda_o;
output reg sda_t;
// spi type
input spi0_w_i;
input spi0_w_o;
input spi0_w_t;
input spi1_w_i;
input spi1_w_o;
input spi1_w_t;
input sck_w_i;
input sck_w_o;
input sck_w_t;
input ss_w_i;
input ss_w_o;
input ss_w_t;
output reg spi0_i;
output reg spi0_o;
output reg spi0_t;
output reg spi1_i;
output reg spi1_o;
output reg spi1_t;
output reg sck_i;
output reg sck_o;
output reg sck_t;
output reg ss_i;
output reg ss_o;
output reg ss_t;


genvar i;
generate
case(TYPE)
    1: begin: GPIO
        for (i=0; i < WIDTH; i=i+1)
            begin: GPIO_SLICE
                always@(*) begin
                    gpio_i <= gpio_w_i;
                    gpio_o <= gpio_w_o;
                    gpio_t <= gpio_w_t;
                end
            end
       end
    2: begin: IIC
        always@(*) begin
            scl_i <= scl_w_i;
            scl_o <= scl_w_o;
            scl_t <= scl_w_t;
            sda_i <= sda_w_i;
            sda_o <= sda_w_o;
            sda_t <= sda_w_t;
        end
       end
    3: begin: SPI
        always@(*) begin
            spi0_i <= spi0_w_i;
            spi0_o <= spi0_w_o;
            spi0_t <= spi0_w_t;
            spi1_i <= spi1_w_i;
            spi1_o <= spi1_w_o;
            spi1_t <= spi1_w_t;
            sck_i <= sck_w_i;
            sck_o <= sck_w_o;
            sck_t <= sck_w_t;
            ss_i <= ss_w_i;
            ss_o <= ss_w_o;
            ss_t <= ss_w_t;
        end
       end
endcase
endgenerate
endmodule
