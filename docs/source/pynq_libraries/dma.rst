.. _pynq-libraries-dma:

DMA
===

PYNQ supports the AXI central DMA IP with the PYNQ *DMA* class. DMA can be used for 
high performance burst transfers between PS DRAM and the PL. 

The *DMA* class supports simple mode only.

Block Diagram
-------------

The DMA has an AXI lite control interface, and a read and write channel which consist
of a AXI master port to access the memory location, and a stream port to connect to 
an IP. 

.. image:: ../images/dma.png
   :align: center

The read channel will read from PS DRAM, and write to a stream. The write channel 
will read from a stream, and write back to PS DRAM. 

Note that the DMA expects any streaming IP connected to the DMA (write channel) to 
set the AXI TLAST 
signal when the transaction is complete. 
If this is not set, the DMA will never complete the transaction. 
This is important when using HLS to generate the IP - the TLAST signal must be set 
in the C code. 

Examples
--------

This example assumes the overlay contains an AXI Direct Memory Access IP, 
with a read channel (from DRAM), and an AXI Master stream interface (for an output
stream), and the other with a write channel (to DRAM), and an AXI Slave stream
interface (for an input stream). 

In the Python code, two contiguous memory buffers are created using ``allocate``. The
DMA will read the input_buffer and send the data to the AXI stream master. The
DMA will write back to the output_buffer from the AXI stream slave.

The AXI streams are connected in loopback so that after sending and receiving data
via the DMA the contents of the input buffer will have been transferred to the
output buffer. 

Note that when instantiating a DMA, the default maximum transaction size is
14-bits (i.e. 2^14 = 16KB). For larger DMA transactions, make sure to increase
this value when configuring the DMA in your Vivado IPI design.

In the following example, let's assume the *example.bit* contains a DMA 
IP block with both send and receive channels enabled.

.. code-block:: Python

   import numpy as np
   from pynq import allocate
   from pynq import Overlay

   overlay = Overlay('example.bit')
   dma = overlay.axi_dma

   input_buffer = allocate(shape=(5,), dtype=np.uint32)
   output_buffer = allocate(shape=(5,), dtype=np.uint32)

Write some data to the array:
   
.. code-block:: Python

      for i in range(5):
         input_buffer[i] = i

.. code-block:: console

      Input buffer will contain:  [0 1 2 3 4]

Transfer the input_buffer to the send DMA, and read back from the receive 
DMA to the output buffer. The wait() method ensures the DMA transactions 
have completed.

.. code-block:: Python

      dma.sendchannel.transfer(input_buffer)
      dma.recvchannel.transfer(output_buffer)
      dma.sendchannel.wait()
      dma.recvchannel.wait()

.. code-block:: console

      Output buffer will contain: [0 1 2 3 4]


More information about the DMA module can be found in the :ref:`pynq-lib-dma` sections
