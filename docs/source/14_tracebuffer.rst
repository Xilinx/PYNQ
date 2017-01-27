*******************************
Tracebuffer
*******************************

.. contents:: Table of Contents
   :depth: 2
   
Introduction
==================

On-chip debug allows FPGA resources to be used to used to monitor internal or external signals in a design for debug. The debug circuitry taps into signals in a design under test, and saves the signal data as the system is operating. The debug data is saved to on-chip memory, and can be read out later for offline debug and analysis. One of the limitations of traditional on-chip debug is that amount of local memory usually available on chip is relatively small. This means only a limited amount of debug data can be captured (typically a few Kilobytes).

In PYNQ, the onchip debug concept has been extended to allow trace debug data to be saved to DRAM. This allows more debug data to be captured. The data can then be analyzed using Python. 

Tracebuffer 
==================
A tracebuffer is included in the base overlay. It is connected to the pin connections of the Pmod ports and the Arduino ports. This allows it to monitor the signals to and from the FPGA pins. The tracebuffer has a connection to DDR memory where captured data will be stored.

.. image:: ./images/trace_buffer_overview_placeholder.jpg
   :align: center
   
8MB of DDR memory is available for the tracebuffer. The DDR memory is allocated from the kernel, and is fixed when the kernel is compiled. 

Supported protocols
---------------------

The tracebuffer uses the SigRock Python package. It can recognise different bus protocols and highlight and format the data appropriately. Check the SigRok webpages for a list of `SigRok supported protocols <https://sigrok.org/wiki/Protocol_decoders>`_

PL IOBs
----------------------

The external PL Input/Output Blocks (IOBs) are tri-state. This means three internal signals are associated with each pin; an input (I), and output (O) and a tri-state signal (T). The Tri-state signal controls whether the pin is beinng used as a input or output. 

The tracebuffer is connected to all 3 signals for each IOP (Pmod and Arduino).

.. image:: ./images/trace_buffer.jpg
   :align: center

This allows the tracebuffer to read the tri-state, determine if the IOB is in input, or output mode, and read the appropriate trace data. 

Tracebuffer operation
======================

When trigger, the tracebuffer captures all data on the signals it monitors. THe signals are captured as raw data. 

The first step is to mask out bits that are not required using the tracebuffer .parse() function.

The data can then be formatted based on the specified protocol. This can be doen using sigrok with the tracebuffer .decode() function. 

The data can then be displayed in a notebook with wavedrom by using the tracebuffer .display() function. 

Tracebuffer example
======================

To use the tracebuffer, instantiate the tracebuffer class, specifying the interface it is connected to, the protocol, and the sample rate. 

.. code-block:: Python

   from pynq.drivers import Trace_Buffer
   
   tr_buf = Trace_Buffer(PMODA,"i2c",samplerate=1000000)

Once you are ready to start collecting data, start the tracebuffer.
   
.. code-block:: Python

   # Start the trace buffer
   tr_buf.start()

Once you are finished collecting data, stop the tracebuffer.

.. code-block:: Python

   # Stop the trace buffer
   tr_buf.stop()


Set up the mask values. This will determine which data will be displayed. 

.. code-block:: Python

   start = 600
   stop = 10000
   tri_sel=[0x40000,0x80000]
   tri_0=[0x4,0x8]
   tri_1=[0x400,0x800]
   mask = 0x0

.. code-block:: Python

   tr_buf.parse("i2c_trace.csv",start,stop,mask,tri_sel,tri_0,tri_1)
   tr_buf.set_metadata(['SDA','SCL'])
   tr_buf.decode("i2c_trace.pd")


Display the tracebuffer data in a notebook using wavedrom. The first sample is stored in location 1, so the starting sample to display must be equal to 1 or more. The end sample to display must be less than the total number of samples collected. 

.. code-block:: Python

    tr_buf.display(0,5000)

This code displays samples from 1 to 5000. 


Example notebooks
======================

There are two notebooks available in the example notebooks directory in the Jupyter home area showing how to use the tracebuffer; *tracebuffer_i2c.ipynb* and *tracebuffer_spi.ipynb *. 
One shows an IIC example, and the other shows a SPI example. 
