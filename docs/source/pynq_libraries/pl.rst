.. _pynq-libraries-pl:

Device, Bitstream and PL classes
================================

Device
------

The *Device* is a class representing the device containing the PL, and is mainly
used by the Overlay class. Each instance of the Device class downloads overlays
to the PL, and keeps track of the overlay loaded by the current Python process.

The overlay metadata is parsed by the Device class to generate the IP, GPIO,
interrupt, hierarchy and memory dictionaries (lists of information about IP,
signals and memories in the overlay). Metadata is parsed from the Hardware
Handoff (``.hwh``) file, the Xilinx Support Archive (``.xsa``), or an
``.xclbin`` file provided with the overlay.

The dictionaries of the Device are populated when an overlay is instantiated.

.. code-block:: Python

   from pynq import Device, Overlay

   ol = Overlay("base.bit") # base.pdi on Versal

   dev = Device.active_device # Retrieve the currently used device

   dev.timestamp # Get the timestamp when the current overlay was loaded

   dev.ip_dict # List IP in the overlay

   dev.gpio_dict # List GPIO in the overlay

   dev.interrupt_controllers # List interrupt controllers in the overlay

   dev.interrupt_pins # List interrupt pins in the overlay

   dev.hierarchy_dict # List the hierarchies in the overlay

   dev.mem_dict # List the memories in the overlay

Device Types
^^^^^^^^^^^^

There are three types of *Devices* supported by PYNQ.

1. ``VersalDevice``: used for Versal devices and programmed with a ``.pdi``
   file.
2. ``EmbeddedDevice``: used for Zynq UltraScale+ devices and programmed with a ``.bit``
   file.
3. ``RemoteDevice``: used to control a PYNQ board from a host computer over gRPC. More details
   on remote devices in :ref:`pynq_remote`

The Linux FPGA Manager is used to program the PL for both Versal and Zynq UltraScale+
devices. ``/dev/mem`` is used to access IP in the PL, and XRT is used to allocate memory.

Bitstream
---------

The *Bitstream* class can be found in the bitstream.py source file, and can also be
used instead of the *Overlay* class to download a bitstream (``.bit``) or Programmable
Device Image (``.pdi``) file to the PL without requiring a HWH file. This can be used
for testing, but the Bitstream methods and attributes can also be accessed through the
Overlay class (which inherits from the Bitstream class). Using the Overlay class is the
recommended way to access them.

Below is an example of directly downloading a bitstream file on Zynq UltraScale+.

.. code-block:: Python

   from pynq import Bitstream

   bit = Bitstream("base.bit") # No overlay HWH file required, base.pdi on Versal

   bit.download()

   bit.bitfile_name

.. code-block:: Python

   '/usr/local/share/pynq-venv/lib/python3.12/site-packages/pynq/overlays/base/base.bit'

PL
--

When a bitstream is downloaded, the Device saves the details of the loaded
overlay to a global state file in the ``pynq/pl_server`` directory. This includes
the bitstream path, a hash of the bitstream, the download timestamp, etc. Parsed
metadata is also stored in ``_current_metadata.pkl``.

The *PL* class reads from these files, making information about the currently loaded
overlay available.

.. code-block:: Python

   from pynq import PL

   PL.bitfile_name # Get the path of the bitstream currently loaded on the PL

   PL.timestamp # Get the timestamp when the current overlay was loaded

   PL.ip_dict # List IP in the overlay currently loaded on the PL
   
If an overlay is loaded and its hash matches the hash currently stored, the
stored metadata is used to avoid parsing the HWH files again. ``PL.reset()`` can
be called to clear the global state file.

More information about devices and bitstreams can be found in the
:ref:`pynq-bitstream` and :ref:`pynq-pl_server` sections.
