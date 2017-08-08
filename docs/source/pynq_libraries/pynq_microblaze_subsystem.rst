Pynq MicroBlaze Subsystem
=========================


A PYNQ MicroBlaze subsystem consists of a MicroBlaze processor, AXI
interconnect, Interrupt controller, an Interrupt Requester, and External System
Interface, and Block RAM and memory controllers.

The AXI interconnect connects the microblaze to the interrupt controller,
interrupt requester, and external interface.

* The Interrupt Controller is the interface for other communication or
  behavioral controllers connected to the MicroBlaze Processor.
* The Interrupt Requester sends interrupt requests to the Zynq Processing System.
* The External Interface allows the MicroBlaze subsystem to communicate with
  other communication, behavioral controllers, or DDR Memory.
* The Block RAM holds MicroBlaze Instructions and Data.

The Block RAMis dual-ported: One port connected to the MicroBlaze Instruction
and Data ports; The other port is connected to the ARM® Cortex®-A9 processor for
communication.

If the External Interface is connected to DDR Memory, DDR can be used to
transfer large data segments between the PS (Python) and the Subsystem.

Each Pynq MicroBlaze subsystem is contained within an IO Processor (IOP). An IOP
defines a set of communication and behavioral controllers that are controlled by
Python. There are currently three IOPs provided with Pynq: Arduino, PMOD, and
Logictools.

Block Diagram
-------------
.. image:: ../images/mb_subsystem.png
   :align: center

Examples
--------
The MicroBlaze subsystem can be controlled by the PynqMicroblaze module. 

The class is instantiated with the name of the MicroBlaze subsystem and program to run. 

.. code-block:: Python

   from pynq import Overlay
   from pynq.lib import PynqMicroblaze
   
   base = Overlay("base.bit")
   mb = PynqMicroblaze(base.pmoda._mb_info, "prog.bin")

This includes the following methods:

* ``program()`` - Writes the program specified during class instantiation to the shared memory of Microblaze.
* ``read(offset, length=1)`` - Reads data from the shared memory of Microblaze.
* ``reset()`` - Reset the Microblaze to stop it from running.
* ``run()`` - Start the Microblaze to run program loaded.
* ``write(offset, data)`` - Write data into the shared memory of the Microblaze.


