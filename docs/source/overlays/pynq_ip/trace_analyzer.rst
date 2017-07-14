Trace Analyzer
==================

   
Introduction
----------------

Traditional on-chip debug allows FPGA resources to be used to monitor internal or external signals in a design for debug. The debug circuitry taps into signals in a design under test, and saves the signal data as the system is operating. The debug data is saved to on-chip memory, and can be read out later for offline debug and analysis. One of the limitations of traditional on-chip debug is that amount of local memory usually available on chip is relatively small. This means only a limited amount of debug data can be captured (typically a few Kilobytes).

The on-chip debug concept has been extended to allow trace debug data to be saved to DDR memory. This allows more debug data to be captured. The data can then be analyzed using Python. 

Trace Analyzer 
-----------------
A trace analyzer is included in the base overlay. It is connected to the pin connections of the Pmod ports and the Arduino ports. This allows it to monitor the signals to and from the FPGA pins. The trace analyzer has a connection to DDR memory where captured data will be stored.

  
??? 8MB of DDR memory is available for the trace analyzer. The DDR memory is allocated from the kernel, and is fixed when the kernel is compiled. 

Trace IOBs
^^^^^^^^^^^^^

The trace analyzer monitors the external PL Input/Output Blocks (IOBs) on the PMod and Arduino interfaces. The IOBs are tri-state. This means three internal signals are associated with each pin; an input (I), and output (O) and a tri-state signal (T). The Tri-state signal controls whether the pin is being used as a input or output. 

The trace analyzer is connected to all 3 signals for each IOP (Pmod and Arduino).

.. image:: ../../images/trace_analyzer.png
   :align: center

This allows the trace analyzer to read the tri-state, determine if the IOB is in input, or output mode, and read the appropriate trace data. 

Ports
^^^^^^^^^^

The ports for the Trace Analyzer can be seen on the following image:

.. image:: ../../images/trace_analyzer_ipi.png
   :align: center

* s_axi_lite_dma - axi connection to MicroBlaze subsystem that controls this block
* axi_resetn - reset for s_axi interfaces

* axi_reset_n ???
* mem_interconnect_ARESETN - ???
* reset_n ???

* controls_input ???
* nunSample ???
* sample_clk - ??? 

* switch_data_i - input signals to the FSM
* switch_data_o - output signals from the FSM (may be "state" data, or FSM outputs)
* switch_data_tri_o - tri-state control signals for output data

* M00_AXI_HP2 - connection back to PS Memory controller


Supported protocols
^^^^^^^^^^^^^^^^^^^^^^^

The trace analyzer uses the `sigrok Python package <https://sigrok.org>`_. It can recognise different bus protocols and highlight and format the data appropriately. 

Currently supported protocols are ``I2C`` and ``SPI``. 

Trace analyzer operation
^^^^^^^^^^^^^^^^^^^^^^^^^

The trace analyzer is instantiated with the interface, pins to monitor and labels, the data protocol, and sample rate defined. 
                      
When triggered or started, the trace analyzer captures all data on the interface port.

The data can then be formatted based on the specified protocol and displayed in a notebook. 

Trace analyzer example
----------------------

To use the trace analyzer, instantiate the TraceAnalyzer class, specifying the interface it is connected to, the pins to monitor, the protocol, and the sample rate. 

.. code-block:: Python

   from pynq.drivers import TraceAnalyzer
      tr_buf = TraceAnalyzer(PMODA,pins=[2,3],probes=['SCL','SDA'],
                      protocol="i2c",rate=1000000)
                      
The trace analyzer runs at 100 MHz. The sample rate is the number of samples stored out of every sample captured. E.g. rate = 1 will store samples at 100 Msps. rate = 2 will store samples at 83 Msps etc.  

.. code-block :: console
    
    Samples captured = 100 MHz/rate


Once you are ready to start collecting data, start the trace analyzer.
   
.. code-block:: Python
  
   # Start the trace analyzer
   tr_buf.start()

Once you are finished collecting data, stop the trace analyzer.

.. code-block:: Python

   # Stop the trace analyzer
   tr_buf.stop()


The data is first parsed into a .csv file. The start and stop positions are provided to select the region of interest. The .csv file is then decoded into a .pd file 

.. code-block:: Python

   # Set up samples
   start = 500
   stop = 3500

   # Parsing and decoding samples
   tr_buf.parse("i2c_trace.csv",start,stop)
   tr_buf.decode("i2c_trace.pd")

The first sample is stored in location 1, so the starting sample to display must be equal to 1 or more. The end sample to display must be less than the total number of samples collected. 


The data can be displayed in a notebook. This is done using the Python WaveDrom package. 

.. code-block:: Python

    tr_buf.display()


Example notebooks
-----------------------

???

