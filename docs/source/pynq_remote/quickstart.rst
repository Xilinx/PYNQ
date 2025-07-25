.. _quickstart:

Quick Start
===========

This page how to get started with PYNQ.remote. We will use the ZCU104 and the `PYNQ-HelloWorld <https://github.com/Xilinx/PYNQ-HelloWorld>`_ overlay as an example, but the steps are similar for other supported AMD adaptive SoCs and overlays.

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

   pip install git+https://github.com/Xilinx/PYNQ.git

Step 2: Prepare and Boot the Target Device 
------------------------------------------

* Create a PYNQ.remote image using the instructions in :doc:`image_build`.
* Flash the image to your SD card (see :doc:`../appendix/sdcard` for instructions on how to flash the image).
* Insert the SD card and power on the device (make sure it is connected to your network).
* Wait for the device to boot up. You can check the device's IP address using a serial console (e.g. `minicom <https://help.ubuntu.com/community/Minicom>`_ or `PuTTY <https://www.putty.org/>`_) or by checking your router's DHCP client list.

.. note::

    Your board must be connected to the same network as your host machine. If you are using a direct connection, you may need to set a static IP address on both the host and the target device.

Step 3: Install and Run PYNQ-HelloWorld
---------------------------------------

In this step, we'll install the PYNQ-HelloWorld overlay and run it remotely using PYNQ.remote.

First, install the required dependencies in your Python virtual environment:

.. code-block:: bash

   pip install jupyterlab matplotlib pillow wheel

Next, install the PYNQ-HelloWorld overlay. You need to set the ``BOARD`` environment variable before installation so that PYNQ-Utils knows which board you are targeting:

**Windows:**

.. code-block:: bash

   # PowerShell:
   $env:BOARD="ZCU104"; pip install --no-build-isolation pynq-helloworld
   
   # Command Prompt:
   set BOARD=ZCU104 && pip install --no-build-isolation pynq-helloworld

**Linux/macOS:**

.. code-block:: bash

   BOARD=ZCU104 pip install --no-build-isolation pynq-helloworld

After installing the package, download the notebooks and overlay files:

.. code-block:: bash

   pynq get-notebooks pynq-helloworld -d ZCU104

The ``-d`` argument is required for PYNQ's get-notebooks function to know where to find the notebooks and overlay files.

After installation, the notebooks will be available in the current folder under ``pynq-notebooks/pynq-helloworld``. Start Jupyter Lab to access them:

.. code-block:: bash

   jupyter lab

   # On some shells it may be necessary to use:
   python -m jupyterlab

Modifying the Notebook for PYNQ.remote
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

When you open the ``resizer_pl.ipynb`` notebook, you need to make two changes to make it compatible with PYNQ.remote:

**1. Add the environment variable setting**

Find the cell with the imports and modify it to include the ``PYNQ_REMOTE_DEVICES`` environment variable:

.. code-block:: python

   # Original cell:
   from PIL import Image
   import numpy as np
   import matplotlib.pyplot as plt
   %matplotlib inline
   from pynq import allocate, Overlay

Change it to:

.. code-block:: python

   # Modified cell:
   from PIL import Image
   import numpy as np
   import matplotlib.pyplot as plt
   %matplotlib inline
   import os
   os.environ['PYNQ_REMOTE_DEVICES'] = "192.168.2.99"  # Replace with your board's IP
   from pynq import allocate, Overlay

**2. Fix the image display for RemoteBuffer**

Find the cell that creates the PIL Image from the output buffer and modify it to work with PYNQ.remote's RemoteBuffer:

.. code-block:: python

   # Original cell:
   run_kernel()
   resized_image = Image.fromarray(out_buffer)

Change it to:

.. code-block:: python

   # Modified cell:
   run_kernel()
   resized_image = Image.fromarray(out_buffer[:])

The ``[:]`` slice is necessary because PYNQ.remote's RemoteBuffer works slightly differently than PYNQ's PynqBuffer, and PIL won't be able to read the data correctly otherwise.

Once these changes are made, you should be able to run through the entire notebook and resize images completely remotely using PYNQ.remote!

* Remember to replace ``192.168.0.238`` with your target device's actual IP address.
