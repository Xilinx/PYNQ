`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Xilinx
// Engineer: Parimal Patel
// Create Date: 01/10/2017 10:11:16 AM
// Design Name: 
// Module Name: pg_fsm
// Project Name: PYNQ
//////////////////////////////////////////////////////////////////////////////////

module pg_fsm #(parameter ADDR_WIDTH = 18)(
    input clk,
    input [2:0] gpio_control,           // [0] = start, [1] = continue, [2] = stop, multiple clocks wide
    input [ADDR_WIDTH-1:0] numSample,   // Maximum number of samples = BRAM depth = 128K Words
    input single_b,                     // =0 means single time, =1 multiple times
    input reset_n,
    output [ADDR_WIDTH-1:0] addrB,  // 64K Words, 256K Bytes
    output reg enb_1d,
    output reg enb
    );
    
    reg pause;
    
    wire start;
    wire continue;
    wire stop;
    wire cnt_done;
    reg [ADDR_WIDTH-1:0] count;
    reg single_cnt_done;
    
    // pulsed output generation
    pulse_gen sync_start(.async_in(gpio_control[0]), .sync_clk(clk), .pulsed_out(start));
    pulse_gen sync_continue(.async_in(gpio_control[1]), .sync_clk(clk), .pulsed_out(continue));
    pulse_gen sync_stop(.async_in(gpio_control[2]), .sync_clk(clk), .pulsed_out(stop));

    assign cnt_done = (count == (numSample-1)) ? 1'b1 : 1'b0;
    assign addrB = (enb)? count : 0;
    
    always @(posedge clk)
    if (!reset_n)
        enb_1d <= 0;
    else 
        enb_1d <= enb;

    always @(posedge clk)
    if (!reset_n)
        count <= 0;
    else if((start) || (cnt_done))
        count <= 0;
    else if(enb)
        count <= count + 1;
    else 
        count <= count;
                
    always @(posedge clk)
        if ((!reset_n) || (start))
            single_cnt_done <= 0;
        else if((!single_b) && (cnt_done))
            single_cnt_done <= 1;

    always @(posedge clk)
    if (!reset_n)
    begin
        pause <= 0;
        enb <= 0;    
    end
    else
    begin
        if(start)         // start asserted
        begin
            pause <= 0;
            enb <= 1;
        end
        else if(stop)    // stop asserted
        begin
            pause <= 1;
            enb <= 0;
        end
        else if(continue && single_b)    // continue asserted
        begin
            pause <= 0;
            enb <= 1;
        end
        else if(continue && (!single_b) && (!single_cnt_done))    // continue asserted
        begin
            pause <= 0;
            enb <= 1;
        end
        else if ((cnt_done) && (single_b==0))
        begin
            enb <= 0;
        end
        else if((cnt_done) && (single_b))
        begin
            pause <= 0;
            enb <= 1;
        end
        else
        begin
            pause <= pause;
            enb <= enb;
        end       
    end
endmodule
