*******************************
Tracebuffer
*******************************

.. contents:: Table of Contents
   :depth: 2
   
Introduction
==================

On chip trace capability has lonng been available in FPGA technology. This is where FPGA resources are used to tap into signals in the design under test and record data for debug as the system is operating. The debug data is saved to onchip memory, and can then be read out for offline analysis and debug. One of the limmitations of traditional onchip debug is that local memory available on chip is relitively small. This means only a limited amount of debug data can be captured (typically a few Kilobytes.).

In PYNQ, the onchip debug concept has been extended to allow debug data to be saved to DDR. This allows more debug data to be captured, and allows data to be analyzed using Python. 

Tracebuffer 
==================
The tracebuffer is connected to the pin connections of the Pmod ports and the Arduino ports. This allows it to monitor the signals to and from the FPGA pins. The tracebuffer has a connection to DDR memory where captured data will be stored.
8MB of DDR memory is available for the tracebuffer. The DDR memory is allocated from the kernel, and is fixed when the kernel is compiled. 

The tracebuffer uses wavedrom, and can recognise different bus protocols and format the data appropriately. CUrrently supported formats include:

xxx

Using the tracebuffer
======================

To use the tracebuffer, innstantiate the tracebuffer class. 

Set up the pins to be monitored. 

You must specify the direction of the pin. 


From Python, trigger the tracebuffer to begin capturing data:

Once data has been captured, view the data in Jupyter
xxx



Example notebook
======================

An example notebook showing how to use the tracebuffer can be found in the Examples folder. 