.. _pynq-libraries-overlay:

Overlay
=======

The *Overlay* class is used to load PYNQ overlays to the PL, and to manage and 
control existing overlays. The class is instantiated using either a Xilinx
Support Archive (``.xsa``), a bitstream (``.bit``) or a Programmable Device Image
(``.pdi``) file.

Bitstreams are used by the Zynq UltraScale+ devices, PDIs by the Versal devices,
and XSAs are exported from Vivado containing either a bitstream or a PDI depending
on the device being targeted.

Bitstreams and PDIs require corresponding metadata about the overlay in the form of a
Hardware Handoff (``.hwh``) file. The XSA is a zipped file format containing the ``.hwh``
file alongside either a bitstream or PDI file.

To instantiate the Overlay, an ``.xsa`` (recommended), ``.bit`` or ``.pdi`` file location
is passed to the Overlay class. This results in the HWH being parsed to obtain information
about the overlay, such as the PL clock settings. These clocks are programmed before the
overlay is downloaded to the PL. Additionally, the overlay can be instantiated without
downloading the overlay to the PL by passing ``download=False`` to the class. 

Examples
--------

.. code-block:: Python

   from pynq import Overlay

   base = Overlay("base.bit") # base.pdi on Versal

The ``.bit`` / ``.pdi`` file paths can be provided as relative or absolute paths.
The Overlay class will also search the packages directory for installed packages, and
download an overlay found in this location.

.. code-block:: Python

   base = Overlay("base.bit", download=False) # Overlay is instantiated, but bitstream is
   not downloaded to PL

   base.download() # Explicitly download bitstream to PL
   
   base.is_loaded() # Checks if a bitstream is loaded
   
   base.reset() # Resets all the dictionaries kept in the overlay
   
   base.load_ip_data(myIP, data) # Provides a function to write data to the memory space of an IP
                                 # data is assumed to be in binary format

The ``ip_dict`` contains a list of IP in the overlay, and can be used to determine
the IP driver, physical address, version, and whether GPIO or interrupts are connected
to the IP. 

.. code-block:: Python

   base.ip_dict


More information about the Overlay module can be found in the 
:ref:`pynq-overlay` section.
