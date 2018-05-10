.. _pynq-libraries-xlnk:

Xlnk
====

The *Xlnk* class Is used to allocated contiguous memory. 

IP connected to the AXI Master (HP or ACP ports) has access to PS DRAM. Before 
IP in the PL accesses DRAM, some memory must first be allocated (reserved) for 
the IP to use and the size, and address of the memory passed to the IP. An 
array in Python, or Numpy, will be allocated somewhere in virtual memory. The 
physical memory address of the allocated memory must be provided to IP in the PL.

Xlnk can allocate memory, and also provide the physical pointer. It also 
allocates contiguous memory which is more efficient for PL IP to use. 

Xlnk can allocate arrays using the Python ``NumPy`` package. This allows the data
type, and size/shape of the array to be specified using NumPy.

Xlnk is also used implicitly by the DMA class to allocate memory. 

Example
-------

Create an Xlnk instance and use ``cma_array()`` to allocate a *unsigned
32-bit int* contiguous block of memory of 5 elements:

Allocating the memory buffer:

   .. code-block:: Python

      from pynq import Xlnk
      import numpy as np

      xlnk = Xlnk()
      input_buffer = xlnk.cma_array(shape=(5,), dtype=np.uint32)


``physical_address`` property of the memory buffer:

   .. code-block:: Python
   
      input_buffer.physical_address

Writing data to the buffer:

   .. code-block:: Python
   
      for i in range(5):
          input_buffer[i] = i
          
      # Input buffer:  [0 1 2 3 4]

More information about the MMIO module can be found in the :ref:`pynq-xlnk` sections.
