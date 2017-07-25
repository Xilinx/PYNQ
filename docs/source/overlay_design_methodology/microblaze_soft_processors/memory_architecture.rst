Memory Architecture
===================


Each IOP has local memory (implemented in Xilinx BRAMs) and a connection to the
PS DDR memory.

The IOP instruction and data memory is implemented in a dual port Block RAM,
with one port connected to the IOP, and the other to the ARM processor. This
allows an executable binary file to be written from the ARM (i.e. the Pynq
environment) to the IOP instruction memory. The IOP can also be reset from Pynq,
allowing the IOP to start executing the new program.

The IOP data memory, either in local memory, or in DDR memory, can be used as a
mailbox for communication and data exchanges between the Pynq environment and
the IOP.

DDR memory is managed by the Linux kernel running on the Cortex-A9s.  Therefore,
the IOP must first be allocated memory regions to access DRAM. The PYNQ Xlnk
class is used to allocate memory in Linux. It also provides the physical address
of the memory. A PYNQ applications can send the physical address to an IOP, and
the IOP can then access the buffer.

DDR Memory
----------

The IOPs are connected to the DDR memory via the General Purpose AXI slave
port. This is a direct connection, and no DMA is available, so is only suitable
for simple data transfers from the IOP. I.e. The MicroBlaze can attempt to read
or write the DDR as quickly as possible in a loop, but there is no support for
bursts, or streaming data.

IOP Memory map
--------------

The local IOP memory is 64KB of shared data and instruction memory. Instruction
memory for the IOP starts at address 0x0.

Pynq and the application running on the IOP can write to anywhere in the shared
memory space. You should be careful not to write to the instruction memory
unintentionally as this will corrupt the running application.

When building the MicroBlaze project, the compiler will only ensure that the
application and *allocated* stack and heap fit into the BRAM and DDR if
used. For communication between the ARM and the MicroBlaze, a part of the shared
memory space must also be reserved within the MicroBlaze address space.

There is no memory management in the IOP. You must ensure the application,
including stack and heap, do not overflow into the defined data area. Remember
that declaring a stack and heap size only allocates space to the stack and
heap. No boundary is created, so if sufficient space was not allocated, the
stack and heap may overflow and corrupt your application.

If you need to modify the stack and heap for an application, the linker script
can be found in the ``<project>/src/`` directory.

It is recommended to follow the same convention for data communication between
the two processors via a MAILBOX.

   ================================= ========
   Instruction and data memory start 0x0
   Instruction and data memory size  0xf000
   Shared mailbox memory start       0xf000
   Shared mailbox memory size        0x1000
   Shared mailbox Command Address    0xfffc
   ================================= ========
   
These MAILBOX values for an IOP application are defined here:

.. code-block:: console

   <GitHub Repository>/boards/<board name>/vivado/ip/arduino_io_switch_1.0/  \
   drivers/arduino_io_switch_1.0/src/arduino.h
   <GitHub Repository>/boards/<board name>/vivado/ip/pmod_io_switch_1.0/  \
   drivers/pmod_io_switch_1.0/src/pmod.h

The corresponding Python constants are defined here:
   
.. code-block:: console

   <GitHub Repository>/python/pynq/iop/iop_const.py

The following example explains how Python could initiate a read from a peripheral connected to an IOP. 

1. Python writes a read command (e.g. 0x3) to the mailbox command address
   (0xfffc).
2. MicroBlaze application checks the command address, and reads and decodes the
   command.
3. MicroBlaze performs a read from the peripheral and places the data at the
   mailbox base address (0xf000).
4. MicroBlaze writes 0x0 to the mailbox command address (0xfffc) to confirm
   transaction is complete.
5. Python checks the command address (0xfffc), and sees that the MicroBlaze has
   written 0x0, indicating the read is complete, and data is available.
6. Python reads the data in the mailbox base address (0xf000), completing the
   read.

Running code on different IOPs
------------------------------

The MicroBlaze local BRAM memory is mapped into the MicroBlaze address space,
and also to the ARM address space.  These address spaces are independent, so the
local memory will be located at different addresses in each memory space. Some
example mappings are shown below to highlight the address translation between
MicroBlaze and ARM's memory spaces.

=================   =========================   ============================
IOP Base Address    MicroBlaze Address Space    ARM Equivalent Address Space
=================   =========================   ============================
0x4000_0000         0x0000_0000 - 0x0000_ffff   0x4000_0000 - 0x4000_ffff
0x4200_0000         0x0000_0000 - 0x0000_ffff   0x4200_0000 - 0x4200_ffff
0x4400_0000         0x0000_0000 - 0x0000_ffff   0x4400_0000 - 0x4400_ffff
=================   =========================   ============================

Note that each MicroBlaze has the same range for its address space. However, the
location of each IOPs address space in the ARM memory map is different for each
IOP. As the address space is the same for each IOP, any binary compiled for one
Pmod IOP will work on another Pmod IOP.

e.g. if IOP1 exists at 0x4000_0000, and IOP2 (a second instance of an IOP)
exists at 0x4200_0000, the same binary can run on IOP1 by writing the binary
from python to the 0x4000_0000 address space, and on IOP2 by writing to the
0x4200_0000.

