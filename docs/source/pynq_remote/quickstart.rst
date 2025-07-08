.. _quickstart:

Quick Start
===========

This page shows the fastest way to get up and running with PYNQ.remote.

Prerequisites
-------------

* Host machine running Linux, Windows, or macOS
* Python 3.10 or newer
* Supported AMD FPGA-based device with network access
* Network connection between host and target
* SD card

Step 1: Install PYNQ.remote on the Host
---------------------------------------

.. note::

    PYNQ.remote relies on environment variables for installation and target device identification.
    For installation you need to have either ``PYNQ_REMOTE`` or ``PYNQ_REMOTE_DEVICES`` environment variables set.

Download PYNQ from GitHub and install the ``pynq`` package using pip. It is recommended to use a 
`Python virtual environment <https://docs.python.org/3/library/venv.html>`_.

.. code-block:: bash

   git clone http://github/com/Xilinx/PYNQ.git
   cd PYNQ
   pip install .

Step 2: Prepare and Boot the Target Device 
------------------------------------------

* Create a PYNQ.remote image using the instructions in :doc:`image_build`.
* Flash the image to your SD card.
* Insert the SD card and power on the device (make sure it is connected to your network).

Step 3: Connect from Host and Run Your Code
-------------------------------------------

In your Python environment on the host, you can now use PYNQ.remote.

PYNQ.remote aims to provide an identical API to classic PYNQ. This means that you should be able to run your existing PYNQ code with minimal changes. However, not all PYNQ features are supported yet, and so some adjustments may be necessary.

In order for PYNQ to connect to the remote device, you need to specify the IP address of the target. The simplest way to do this is with the use of the ``PYNQ_REMOTE_DEVICES`` environment variable, which should be set as a string containing one or more IP addresses, separated by commas. For example:

.. code-block:: bash

   PYNQ_REMOTE_DEVICES="192.168.2.99, 10.42.0.99"

This can be set in your shell or in your Python script **before** importing the ``pynq`` package. For more information on how to set environment variables, refer to :ref:`env_variables`.

Once the environment variable is set, you can use the ``pynq`` package as usual. For example, to load an overlay and print the ``ip_dict``, you can do the following:

.. code-block:: python

    import os 
    os.environ['PYNQ_REMOTE_DEVICES'] = "192.168.2.99"

    from pynq import Overlay
    overlay = Overlay('my_overlay.xsa')
    print(ol.ip_dict)

* Replace ``192.168.2.99`` with your target device’s IP address.
* Replace ``my_overlay.xsa`` with your overlay

That's it! You can now run your PYNQ code remotely, just like on a classic PYNQ board.
