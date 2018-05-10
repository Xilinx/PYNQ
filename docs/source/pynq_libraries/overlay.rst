.. _pynq-libraries-overlay:

Overlay
=======

The *Overlay* class is used to load PYNQ overlays to the PL, and manage and 
control existing overlays. 
The class is instantiated with the .bit file for an overlay. By default the
overlay Tcl file will be parsed, and the bitstream will be downloaded to the
PL. This means that to use the overlay class, a .bit and .tcl must be provided
for an overlay. 

To instantiate the Overlay only without downloading the .bit file, pass the
parameter *download=False* when instantiating the Overlay class.

On downloading the bitstream, the clock settings provided in the overlay .tcl
file will also be applied before the bitstream is downloaded. 


Examples
--------

.. code-block:: Python

   from pynq import Overlay

   base = Overlay("base.bit") # bitstream implicitly downloaded to PL

The .bit file path can be provided as a relative, or absolute path. The Overlay
class will also search the packages directory for installed packages, and
download an overlay found in this location. The .bit file is used to locate the
package.

.. code-block:: Python

   base = Overlay("base.bit", download=False) # Overlay is instantiated, but bitstream is not downloaded to PL

   base.download() # Explicitly download bitstream to PL
   
   base.is_loaded() # Checks if a bitstream is loaded
   
   base.reset() # Resets all the dictionaries kept int he overlay
   
   base.load_ip_data(myIP, data) # Provides a function to write data to the memory space of an IP
                                 # data is assumed to be in binary format

The *ip_dict* contains a list of IP in the overlay, and can be used to determine
the IP driver, physical address, version, if GPIO, or interrupts are connected
to the IP. 

.. code-block:: Python

   base.ip_dict


More information about the Overlay module can be found in the 
:ref:`pynq-overlay` sections.
