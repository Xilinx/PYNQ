.. _env_variables:

Setting Environment Variables
=============================

PYNQ.remote uses two environment variables on the host.

``PYNQ_REMOTE``
   Set to ``1`` when installing the ``pynq`` package with pip. This selects the
   remote client install path and skips native board binaries and overlays.

``PYNQ_REMOTE_DEVICES``
   Set before ``import pynq`` to identify target boards. The value is a
   comma-separated list of IP addresses. When multiple addresses are listed,
   each becomes a separate ``RemoteDevice`` instance.

Installing for PYNQ.remote
--------------------------

**Linux/macOS:**

.. code-block:: bash

   PYNQ_REMOTE=1 pip install pynq

**Windows (PowerShell):**

.. code-block:: powershell

   $env:PYNQ_REMOTE="1"; pip install pynq

Runtime device selection
------------------------

Setting ``PYNQ_REMOTE_DEVICES`` at runtime
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

You can set environment variables in Python using the ``os`` module. This works
across all operating systems and does not require shell configuration. Set the
variable before importing ``pynq``.

.. code-block:: python

    import os
    os.environ['PYNQ_REMOTE_DEVICES'] = "192.168.2.99"

Linux and macOS shells
~~~~~~~~~~~~~~~~~~~~~~

.. code-block:: bash

    export PYNQ_REMOTE_DEVICES="192.168.2.99"

The variable applies to the current shell session only.

Windows
~~~~~~~

Command Prompt:

.. code-block:: powershell

    set PYNQ_REMOTE_DEVICES=192.168.2.99

PowerShell:

.. code-block:: powershell

    $env:PYNQ_REMOTE_DEVICES="192.168.2.99"

Python virtual environments
~~~~~~~~~~~~~~~~~~~~~~~~~~~

To set ``PYNQ_REMOTE_DEVICES`` automatically when a virtual environment is
activated, add the appropriate line to the environment's activate script:

* Linux/macOS: ``venv/bin/activate``
* Windows Command Prompt: ``venv/Scripts/activate.bat``
* Windows PowerShell: ``venv/Scripts/Activate.ps1``
