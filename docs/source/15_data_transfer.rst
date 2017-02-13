*******************************
Data Transfer
*******************************

.. contents:: Table of Contents
   :depth: 2
   
Introduction
==================

Data can be transferred from pynq to an overlay in two main ways. The python ``MMIO`` *Memory Mapped Input/Output*, and ``xlnk`` classes in the pynq package can be used for simple and streamed data transfer. 

MMIO
======
MMIO can be used read/write a single memory mapped location in an overlay. MMIO is most appropriate for reading and small amounts of data. Each MMIO read or write command can transfer 32 bits of data. 

The following examples sets up the MMIO to access memory location 0x40000000 - 0x40001000.

Some *data* (0xdeadbeef) is sent to location ADDRESS_OFFSET (0x10). ADDRESS_OFFSET is offset from the start of the MMIO area (0x40000000). This means 0xdeadbeef will be written to 0x40000010. 

The same location is then read and stored in *result*. 

.. code-block:: Python

   ACCELERATOR_ADDRESS 0x40000000
   MEMORY_SIZE = 0x1000
   ADDRESS_OFFSET = 0x10
   
   from pynq import MMIO   
   mmio = MMIO(ACCELERATOR_ADDRESS,MEMORY_SIZE) 

   data = 0xdeadbeef
   self.mmio.write(ADDRESS_OFFSET, data)
   result = self.mmio.read(ADDRESS_OFFSET)

This example assumes the memory mapped area defined for the MMIO, 0x40000000 - 0x40001000, is accessible to the PS. 

xlnk
=============

``xlnk`` can be used to control a DMA in the overlay. 

To transfer data from a DMA to a location in an overlay, a memory buffer needs to be allocated in the main DDR memory. xlnk can be used to allocate a contiguous memory buffer. 

Once the buffer has been allocated, any data to be sent to the overlay can be written to the buffer from Python. When the data is ready to be sent, xlnk can start the DMA memory transfer. 

The DMA can also be used to transfer data from an overlay to the DDR memory buffer. 

xlnk basic example
-------------------

.. code-block:: Python

   MEMORY_SIZE = 0x1000
   
   from pynq import Xlnk
   mmu = Xlnk()   
   
   bufptr = mmu.cma_alloc(MEMORY_SIZE)
   phy_addr = mmu.cma_get_phy_addr(buf_ptr)
   
   
   for i in range(MEMORY_SIZE):
      bufptr[i] = i
   

Data can be written to the buffer, and the physical address can be sent to a block in the accelerator (for example and IOP) which could then access the buffer from DDR memory. 


xlnx DMA example
-----------------

This example assumes the overlay contains the `AXI Direct Memory Access (7.1) <https://www.xilinx.com/support/documentation/ip_documentation/axi_dma/v7_1/pg021_axi_dma.pdf>`_ IP. This IP can be used to connect to AXI streams in an overlay. 

.. code-block:: Python

   MEMORY_SIZE = 0x1000
   OVERLAY_MEMORY_LOCATION = 0x40000000
   
   from pynq import Xlnk
   mmu = Xlnk()   
   
   ps_bufptr = mmu.cma_alloc(MEMORY_SIZE)
   overlay_bufptr = mmu.cma_alloc(MEMORY_SIZE)
   
   for i in range(MEMORY_SIZE):
      ps_bufptr[i] = i
      
   mmu.cma_memcopy(overlay_bufptr,ps_bufptr,MEMORY_SIZE)
   

