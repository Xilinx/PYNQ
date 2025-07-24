.. _quickstart:

Quick Start
===========

This page shows the fastest way to get up and running with PYNQ.remote. We will use the ZCU104 and the `PYNQ-HelloWorld <https://github.com/Xilinx/PYNQ-HelloWorld>`_ overlay as an example, but the steps are similar for other supported AMD adaptive SoCs and overlays. See :doc:`status` for a list of supported platforms.

Prerequisites
-------------

* Host machine running Linux, Windows, or macOS
* Python 3.10 or newer
* Supported AMD adaptive SoCs with network access
* Network connection between host and target

Step 1: Install PYNQ.remote on the Host
---------------------------------------

.. note::

    PYNQ.remote relies on environment variables for installation and target device identification.
    For installation you need to have the ``PYNQ_REMOTE_DEVICES`` environment variables set. See :doc:`env_variables` for more information.

Download PYNQ from GitHub and install the ``pynq`` package using pip. It is recommended to use a 
`Python virtual environment <https://docs.python.org/3/library/venv.html>`_.

To install the latest release version of PYNQ simply run:

.. code-block:: bash

   pip install pynq

If you want to install the latest development version of PYNQ, you can clone the repository and install it from source:

.. code-block:: bash

   git clone https://github.com/Xilinx/PYNQ.git
   cd PYNQ
   pip install .

Step 2: Prepare and Boot the Target Device 
------------------------------------------

* Create a PYNQ.remote image using the instructions in :doc:`image_build`.
* Flash the image to your SD card.
* Insert the SD card and power on the device (make sure it is connected to your network).
* Wait for the device to boot up. You can check the device's IP address using a serial console (e.g. `minicom <https://help.ubuntu.com/community/Minicom>`_ or `PuTTY <https://www.putty.org/>`_) or by checking your router's DHCP client list.

.. note::

    Your board must be connected to the same network as your host machine. If you are using a direct connection, you may need to set a static IP address on both the host and the target device.

Step 3: Connect from Host and Run Your Code
-------------------------------------------

In your Python environment on the host, you can now use PYNQ.remote.

PYNQ.remote aims to provide an identical API to classic PYNQ. This means that you should be able to run your existing PYNQ code with minimal changes. However, not all PYNQ features are supported yet, and so some adjustments may be necessary. See :doc:`status` for a list of supported features.

In order for PYNQ to connect to the remote device, you need to specify the IP address of the target. The simplest way to do this is with the use of the ``PYNQ_REMOTE_DEVICES`` environment variable, which should be set as a string containing your board's IP address. For example:

.. code-block:: bash

   PYNQ_REMOTE_DEVICES="192.168.2.99"

This can be set in your shell or in your Python script **before** importing the ``pynq`` package. For more information on how to set environment variables, refer to :ref:`env_variables`.

Once the environment variable is set, you can use the ``pynq`` package as usual. For example, to load an overlay and print the ``ip_dict``, you can do the following:

.. code-block:: python

    import os 
    os.environ['PYNQ_REMOTE_DEVICES'] = "192.168.2.99"

    from pynq import Overlay
    ol = Overlay('my_overlay.xsa')
    print(ol.ip_dict)

* Replace ``192.168.2.99`` with your target device’s IP address.
* Replace ``my_overlay.xsa`` with your overlay

That's it! You can now run your PYNQ code remotely, just like on a classic PYNQ board.
