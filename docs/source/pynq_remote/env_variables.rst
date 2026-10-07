.. _env_variables:

Setting Environment Variables
=============================

PYNQ.remote uses two environment variables on the host.

``PYNQ_REMOTE``
   Set to ``1`` when installing the ``pynq`` package. This selects the
   remote client install path and skips native board binaries and overlays.

``PYNQ_REMOTE_DEVICES``
   Set before ``import pynq`` to identify target boards. The value is a
   comma-separated list of IP addresses. When multiple addresses are listed,
   each becomes a separate ``RemoteDevice`` instance.

Installing PYNQ for PYNQ.remote
-------------------------------

The commands below use the ``uv`` environment manager tool to install PYNQ, as described
in :ref:`quickstart`. However, ``pip install`` may also be used.

**Linux/macOS:**

.. code-block:: bash
    
    export PYNQ_REMOTE=1
    uv add "pynq @ git+https://github.com/Xilinx/PYNQ.git"

**Windows (PowerShell):**

.. code-block:: powershell

   $env:PYNQ_REMOTE = "1"
   uv add "pynq @ git+https://github.com/Xilinx/PYNQ.git"

Setting ``PYNQ_REMOTE_DEVICES`` at runtime
------------------------------------------

Python Runtime Device Selection
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

You can set environment variables in Python using the ``os`` module. This works
across all operating systems and does not require shell configuration. Set the
variable before importing ``pynq``.

.. code-block:: python
    
    import os
    os.environ['PYNQ_REMOTE_DEVICES'] = "192.168.2.99"  # IP assigned to your board
    
    from pynq import Overlay
    
    ol = Overlay("my_design.xsa")

Shell Device Selection
~~~~~~~~~~~~~~~~~~~~~~

Alternatively, the environment may be configured in your shell. Variables apply
to the current shell session only.

**Linux/macOS:**

.. code-block:: bash
    
    export PYNQ_REMOTE_DEVICES="192.168.2.99"

**Windows (Command Prompt):**

.. code-block:: bat
    
    set PYNQ_REMOTE_DEVICES=192.168.2.99

**Windows (PowerShell):**

.. code-block:: powershell
    
    $env:PYNQ_REMOTE_DEVICES="192.168.2.99"

Python virtual environments
~~~~~~~~~~~~~~~~~~~~~~~~~~~

To set ``PYNQ_REMOTE_DEVICES`` automatically when a virtual environment is
activated, add the appropriate line to the environment's activate script:

* Linux/macOS: ``.venv/bin/activate``
* Windows Command Prompt: ``.venv/Scripts/activate.bat``
* Windows PowerShell: ``.venv/Scripts/Activate.ps1``