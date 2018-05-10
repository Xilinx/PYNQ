.. _pynq-libraries-pl:

PL and Bitstream classes
========================

The *PL* is mainly an internal class used by the Overlay class. The PL class
launches a *PL server* which manages the loaded overlay. The PL server can stop
multiple overlays from different applications from overwriting the currently
loaded overlay. 

The overlay Tcl file is parsed by the PL class to generate the IP, clock,
interrupts, and gpio dictionaries (lists of information about IP, clocks and
signals in the overlay).

The *Bitstream* class can be found in the pl.py source file, and can be used
instead of the overlay class to download a bitstream file to the PL without
requiring an overlay Tcl file. This can be used for testing, but these
attributes can also be accessed through the Overlay class (which inherits from
this class). Using the Overlay class is the recommended way to access these
attributes.

Examples
--------

PL
^^

.. code-block:: Python

   PL.timestamp # Get the timestamp when the current overlay was loaded

   PL.ip_dict # List IP in the overlay

   PL.gpio_dict # List GPIO in the overlay

   PL.interrupt_controllers # List interrupt controllers in the overlay

   PL.interrupt_pins # List interrupt pins in the overlay

   PL.hierarchy_dict # List the hierarchies in the overlay


Bitstream
^^^^^^^^^

.. code-block:: Python

   from pynq import Bitstream

   bit = Bitstream("base.bit") # No overlay Tcl file required

   bit.download()

   bit.bitfile_name
   
'/opt/python3.6/lib/python3.6/site-packages/pynq/overlays/base/base.bit'


More information about the PL module can be found in the :ref:`pynq-pl`
sections.
