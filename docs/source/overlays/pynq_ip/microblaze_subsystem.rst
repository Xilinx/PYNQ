
MicroBlaze subsystem
============================

A MicroBlaze subsystem in PYNQ consists of a MicroBlaze, BRAM and controller, Interrupt controller, an AXI GPIO and d flip flop, and AXI interconnect. 

.. image:: ../../images/mb_subsystem.png
   :align: center

The Interrupt controller manages interrupts for peripherals local to the MicroBlaze. The AXI GPIO is used to signal an interrupt from the MicroBlaze to the PS interrupt controller. The MicroBlaze subsystem can be expanded, for example, by adding more peripherals to the AXI interconnect. 

The MicroBlaze subsystem can be controlled by the PynqMicroblaze module. 

The class is instantiated with the name of the MicroBlaze subsystem and program to run. 


.. code-block :: Python

   from pynq import Overlay
   from pynq.lib import PynqMicroblaze
   
   base = Overlay("base.bit")
   mb = PynqMicroblaze(base.pmoda._mb_info, "prog.bin")

The includes the following methods:

* ``program()`` - Writes the program specified during class instantiation to the shared memory of Microblaze.
* ``read(offset, length=1)`` - Reads data from the shared memory of Microblaze.
* ``reset()`` - Reset the Microblaze to stop it from running.
* ``run()`` - Start the Microblaze to run program loaded.
* ``write(offset, data)`` - Write data into the shared memory of the Microblaze.


