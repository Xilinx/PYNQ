pynq.pl Module
==============

The pynq.pl module facilitates management of the Programmable Logic (PL). The PL
module manages the PL state through the PL class. The PL class is a singleton
for the Overlay class and Bitstream classes that provide user-facing methods for
bitstream and overlay manipulation. The TCL in the PL module parses overlay .tcl
files to determine the overlay IP, GPIO pins, Interrupts indices, and address
map. The Bitstream class within the PL module manages downloading of bitstreams
into the PL.

.. automodule:: pynq.pl
    :members:
    :undoc-members:
    :show-inheritance:
