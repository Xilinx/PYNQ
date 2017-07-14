Base Overlay overview
======================

The base overlay design is intended to include the hardware IP to control the board peripherals, and connects these IP blocks to the Zynq PS. If a base overlay is available for a board, peripherals can be used from the Python environment immediately after the system boots. 

Board peripherals typically include GPIO devices (LEDs, Switches, Buttons), Video, Audio, and any other custom interfaces. In the case of a general purpose interfaces, for example Pmod and Arduino headers, the base overlay may include an IOP for the interface, or a simple GPIO interface.

Base overlay project files
^^^^^^^^^^^^^^^^^^^^^^^^^^^^

All project source files for the base overlay can be found here:

    ``<GitHub Repository>/boards/<board>/base``

The makefile and/or .tcl file in the directory can be used to rebuild the overlay. 

The base overlay can include IP from the Vivado library, and custom IP. Any custom IP for overlays can be found here:

    ``<GitHub Repository>/boards/ip`` 

For more details on rebuilding the overlay, or creating a new overlay, see the `Creating Overlays <../../creating_overlays_index.html>`_ section. 
