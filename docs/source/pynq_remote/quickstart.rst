.. _quickstart:

Quick Start
===========

This page shows how to get started with PYNQ.remote. We use the ZCU104 and the
`PYNQ-HelloWorld <https://github.com/Xilinx/PYNQ-HelloWorld>`_ overlay as an
example, but the steps are similar for other supported AMD adaptive SoCs and
overlays.

Prerequisites
-------------

* Host machine running Linux, Windows, or macOS
* Python 3.10 or newer
* Supported AMD adaptive SoC with network access
* Network connection between host and target

Step 1: Install PYNQ.remote on the Host
---------------------------------------

PYNQ.remote uses two environment variables at different stages. Set
``PYNQ_REMOTE=1`` when installing the ``pynq`` package on the host so that
remote client dependencies are installed and native board binaries are skipped.
Set ``PYNQ_REMOTE_DEVICES`` at runtime, before ``import pynq``, to identify the
target board. See :doc:`env_variables` for platform-specific ways to set
``PYNQ_REMOTE_DEVICES``.

It is recommended to use a
`Python virtual environment <https://docs.python.org/3/library/venv.html>`_.

**Linux/macOS:**

.. code-block:: bash

   PYNQ_REMOTE=1 pip install pynq

To install the development version from source:

.. code-block:: bash

   git clone --recursive https://github.com/Xilinx/PYNQ.git
   cd PYNQ
   PYNQ_REMOTE=1 pip install .

**Windows (PowerShell):**

.. code-block:: powershell

   $env:PYNQ_REMOTE="1"; pip install pynq

Step 2: Prepare and Boot the Target Device
------------------------------------------

* Create a PYNQ.remote image using the instructions in :doc:`image_build`.
* Flash the image to your SD card (see :doc:`../appendix/sdcard`).
* Insert the SD card and power on the device.

Remote images configure both a static address of ``192.168.2.99`` and DHCP.
If your host is on the ``192.168.2.0/24`` network, continue to Step 3 and use
that address in ``PYNQ_REMOTE_DEVICES``.

If the board is on a different network, use the DHCP address from your router's
client list. See :doc:`troubleshooting` if you need to use a USB serial console.
The first time you connect over serial, log in as ``amd-edf`` and set a password
when prompted.

Step 3: Install and Run PYNQ-HelloWorld
---------------------------------------

Install the required dependencies in your Python virtual environment:

.. code-block:: bash

   pip install jupyterlab matplotlib pillow wheel

Install the PYNQ-HelloWorld overlay. Set the ``BOARD`` environment variable
before installation so that PYNQ-Utils knows which board you are targeting:

**Windows:**

.. code-block:: bash

   # PowerShell:
   $env:BOARD="ZCU104"; pip install --no-build-isolation pynq-helloworld

   # Command Prompt:
   set BOARD=ZCU104 && pip install --no-build-isolation pynq-helloworld

**Linux/macOS:**

.. code-block:: bash

   BOARD=ZCU104 pip install --no-build-isolation pynq-helloworld

Download the notebooks and overlay files:

.. code-block:: bash

   pynq get-notebooks pynq-helloworld -d ZCU104

The ``-d`` argument tells ``pynq get-notebooks`` which board package to use.

Start Jupyter Lab:

.. code-block:: bash

   jupyter lab

   # On some shells it may be necessary to use:
   python -m jupyterlab

Connecting to the Board
~~~~~~~~~~~~~~~~~~~~~~~

Before importing ``pynq``, set ``PYNQ_REMOTE_DEVICES`` to the board address:

.. code-block:: python

   import os
   os.environ['PYNQ_REMOTE_DEVICES'] = "192.168.2.99"  # default static IP

   from pynq import allocate, Overlay

   overlay = Overlay("resizer.bit")

Modifying the Notebook for PYNQ.remote
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

When you open the ``resizer_pl.ipynb`` notebook, add the lines above to the
imports cell before ``from pynq import allocate, Overlay``.

Once this change is made, you should be able to run through the entire notebook
and resize images completely remotely using PYNQ.remote.
