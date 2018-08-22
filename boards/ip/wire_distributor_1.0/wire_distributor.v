`timescale 1ns / 1ps

module wire_distributor(
gpio_i_i,
gpio_i_o,
gpio_i_t,
wire_o_i,
wire_o_o,
wire_o_t,

wire_i_i,
wire_i_o,
wire_i_t,
gpio_o_i,
gpio_o_o,
gpio_o_t
);

parameter TYPE = 0;
parameter WIDTH = 1;

output reg [WIDTH-1:0] gpio_i_i;
input [WIDTH-1:0] gpio_i_o;
input [WIDTH-1:0] gpio_i_t;
input [WIDTH-1:0] wire_o_i;
output reg [WIDTH-1:0] wire_o_o;
output reg [WIDTH-1:0] wire_o_t;

output reg [WIDTH-1:0] wire_i_i;
input [WIDTH-1:0] wire_i_o;
input [WIDTH-1:0] wire_i_t;
input [WIDTH-1:0] gpio_o_i;
output reg [WIDTH-1:0] gpio_o_o;
output reg [WIDTH-1:0] gpio_o_t;

genvar i;
generate
        for (i=0; i < WIDTH; i=i+1)
            begin
                always@(*) begin
                    gpio_i_i <= wire_o_i;
                    wire_o_o <= gpio_i_o;
                    wire_o_t <= gpio_i_t;
                    wire_i_i <= gpio_o_i;
                    gpio_o_o <= wire_i_o;
                    gpio_o_t <= wire_i_t;
                end
            end
endgenerate
endmodule
