.. _pspl_interfaces:


PS/PL Interfaces
================

The Zynq has 9 AXI interfaces between the PS and the PL. On the PL side, there
are 4x AXI Master HP (High Performance) ports, 2x AXI GP (General Purpose) 
ports, 2x AXI Slave GP ports and 1x AXI Master ACP port. There are also GPIO 
controllers in the PS that are connected to the PL.

.. image:: ../images/zynq_interfaces.png
   :align: center

There are four ``pynq`` classes that are used to manage data movement between 
the Zynq PS (including the PS DRAM) and PL interfaces.

* GPIO - General Purpose Input/Output
* MMIO - Memory Mapped IO
* Xlnk - Memory allocation
* DMA  - Direct Memory Access

The class used depends on the Zynq PS interface the IP is connected to, and the
interface of the IP. 

Python code running on PYNQ can access IP connected to an AXI Slave connected 
to a GP port. *MMIO* can be used to do this. 

IP connected to an AXI Master port is not under direct control of the PS. The 
AXI Master port allows the IP to access DRAM directly. Before doing this, 
memory should be allocated for the IP to use. The *Xlnk* class can be used to 
do this. 
For higher performance data transfer between PS DRAM and an IP, DMAs can be 
used. PYNQ provides a DMA class. 

Each of these classes will be covered in more detail below. 

When designing your own overlay, you need to consider the type of IP you need, 
and how it will connect to the PS. You should then be able to determine which 
classes you need to use the IP. 

GPIO
----

Two 32 bit GPIO controllers are available in the Zynq PS and are connected to
the PL.

.. image:: ../images/gpio_interface.png
   :align: center

GPIO wires from the PS can be used as a very simple way to communicate between
PS and PL. For example, GPIO can be used as control signals for resets, or
interrupts.

IP does not have to be mapped into the system memory map to be connected to GPIO. 

More information about using PS GPIO can be found in the :ref:`pynq-libraries-psgpio` section.

MMIO
----

Any IP connected to the AXI Slave GP port will be mapped into the system memory
map. 
MMIO can be used read/write a memory mapped location. A MMIO read or write
command is a single transaction to transfer 32 bits of data to or from a memory
location. As burst instructions are not supported, MMIO is most appropriate for
reading and writing small amounts of data to/from IP connect to the AXI Slave 
GP ports. 

More information about using MMIO can be found in the :ref:`pynq-libraries-mmio` section.

Xlnk
----

Memory must be allocated before it can be accessed by the IP. ``Xlnk`` allows
memory buffers to be allocated. Xlnk allocates a contiguous memory buffer which
allows efficient transfers of data between PS and PL. Python or other code
running in Linux on the PS can access the memory buffer directly.

As PYNQ is running Linux, the buffer will exist in the Linux virtual memory. The
Zynq AXI Slave ports allow an AXI-master IP in an overlay to access physical
memory. Xlnk can also provide the physical memory pointer to the buffer which
can be sent to an IP in the overlay. The physical address is stored in the
``physical_address`` property of the allocated memory buffer instance. An IP in
an overlay can then access the same buffer using the physical address.

For example, a program running on a MicroBlaze processor in an overlay may need
to write data to main memory so that it could be read in Python. First, the
memory can be allocated in Linux using Xlnk. Then the physical pointer is sent
to the MicroBlaze, and finally the MicroBlaze program and write data to the
memory buffer using the pointer.

Xlnk is also used implicitly by the DMA class to allocate memory. If you are 
using the DMA it is useful to be aware of Xlnk, but you will not need to use it 
directly. 

More information about using Xlnk can be found in the :ref:`pynq-libraries-xlnk` section.

DMA
---

The ``pynq`` DMA class supports the `AXI Direct Memory Access IP
<https://www.xilinx.com/support/documentation/ip_documentation/axi_dma/v7_1/pg021_axi_dma.pdf>`_.
This allows data to be read from DRAM, and sent to an AXI stream, or received
from a stream and written to DRAM.

.. image:: ../images/axi_direct_memory_access.png
   :align: center

The DMA has an AXI lite control interface, a *Read* channel (MM2S: Memory Map to Stream) consisting of an AXI master to access PS DRAM, and an AXI Stream master to write to the IP, and a *Write* channel (S2MM: Stream to Memory Map) with an AXI Master to access PS DRAM again and an AXI Stream slave to receive data from the IP.

The DMA supports simple mode. Scatter gather is not currently supported. The 
DMA class can allocate memory buffers, and transfer data between the PS DRAM and 
an IP in the PL.

The DMA can be connected to the AXI Master HP ports allowing high performance 
data transfer between PS memory and IP. 

More information about using DMA can be found in the :ref:`pynq-libraries-dma` section.

Interrupt
---------

Finally there are dedicated interrupts which are linked with asyncio events in
the python environment. To integrate into the PYNQ framework Dedicated
interrupts must be attached to an AXI Interrupt controller which is in turn
attached to the first interrupt line to the processing system. If more than 32
interrupts are required then AXI interrupt controllers can be cascaded. This
arrangement leaves the other interrupts free for IP not controlled by PYNQ
directly such as SDSoC accelerators.

The ``Interrupt`` class represents a single interrupt pin in the block
design. It mimics a python ``Event`` by having a single ``wait`` function that
blocks until the interrupt is raised. The event will be cleared automatically
when the interrupt is cleared. To construct an event, pass in fully qualified
path to the pin in the block diagram, e.g. ``'my_ip/interrupt'`` as the only
argument.

An interrupt is only enabled for as long there is a thread or coroutine wating
on the corresponding event. The recommended approach to using interrupts is to
wait in a loop, checking and clearing the interrupt registers in the IP before
resuming the wait. As an example, the AxiGPIO class uses this approach to wait
for a desired value to be present.

   .. code-block:: Python

      class AxiGPIO(DefaultIP):
          # Rest of class definition

          def wait_for_level(self, value):
              while self.read() != value:
                  self._interrupt.wait()
                  # Clear interrupt
                  self._mmio.write(IP_ISR, 0x1)

The implementation is built on top of asyncio, a newly added part of the python
standard library. For more details on asyncio, how it can be used with PYNQ see
the :ref:`pynq-and-asyncio` section.


