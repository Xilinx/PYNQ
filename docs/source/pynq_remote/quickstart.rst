.. _quickstart:

Quick Start
===========

This page shows how to get started with PYNQ.remote. We use the ZCU104 and the
`PYNQ-HelloWorld <https://github.com/Xilinx/PYNQ-HelloWorld>`_ overlay as an
example, but the steps are similar for other supported AMD adaptive SoCs and
overlays. The steps are provided for Windows, Linux, and macOS operating systems.
Use the commands that match your machine to set up and use PYNQ.remote.

Prerequisites
-------------

* Host machine running Linux, Windows, or macOS
* Supported AMD adaptive SoC with network access
* Network connection between host and target

Step 1: Install uv
------------------

We use the ``uv`` tool to manage Python versions, projects, and packages in an
isolated environment. This stops project-specific dependencies from clashing
with your system. Dependencies for your project are recorded in a
``pyproject.toml`` file.

The ``uv`` tool can be installed using the following command:

**Linux/macOS:**

.. code-block:: bash

   curl -LsSf https://astral.sh/uv/install.sh | sh

**Windows (PowerShell):**

.. code-block:: powershell

   powershell -ExecutionPolicy ByPass -c "irm https://astral.sh/uv/install.ps1 | iex"


Step 2: Create a Project
------------------------

Running ``uv init --bare`` sets up a project containing a minimal
``pyproject.toml``. Additionally, passing ``--python "==3.11.*"`` specifies
that the project uses Python 3.11. Run the following command to create the
project:

**Linux/macOS and Windows (PowerShell):**

.. code-block:: bash

   uv init remote-project --bare --python "==3.11.*"
   cd remote-project

Step 3: Install PYNQ and Dependencies
-------------------------------------

Before you install any dependencies into the ``uv`` environment, PYNQ's
installer needs to be instructed to build in *remote mode*. To do this, set the
``PYNQ_REMOTE`` environment variable before installing PYNQ.

**Linux/macOS:**

.. code-block:: bash

   export PYNQ_REMOTE=1

**Windows (PowerShell):**

.. code-block:: powershell

   $env:PYNQ_REMOTE = "1"

PYNQ can then be installed, **followed by** any other dependencies required
for your project. The first command below installs the most recent version of
PYNQ from GitHub. ``uv add`` installs packages into the project environment and
records each of them in the ``pyproject.toml``.

**Linux/macOS and Windows (PowerShell):**

.. code-block:: bash

   uv add "pynq @ git+https://github.com/Xilinx/PYNQ.git"
   uv add "setuptools<78" "pycparser<3" "numpy<2" scipy ipywidgets plotly anywidget matplotlib pillow ipython jupyterlab voila

Step 4: Install PYNQ-HelloWorld
-------------------------------

Before installing the PYNQ-HelloWorld overlay, set the ``BOARD`` environment
variable so that PYNQ-Utils knows which board you are targeting.

**Linux/macOS:**

.. code-block:: bash

   export BOARD=ZCU104

**Windows (PowerShell):**

.. code-block:: powershell

   $env:BOARD = "ZCU104"

PYNQ-HelloWorld is then ready to be installed:

**Linux/macOS and Windows (PowerShell):**

.. code-block:: bash

   uv pip install --no-build-isolation pynq-helloworld
   uv run pynq get-notebooks pynq-helloworld -d ZCU104

Step 5: Running JupyterLab
--------------------------

Before running any overlays, the IP address assigned to your board must be stored in an
environment variable called ``PYNQ_REMOTE_DEVICES``. This can be configured directly in a
Linux/macOS or PowerShell terminal, or in Python using the ``os`` module **before**
running ``import pynq``. Running ``uv run jupyter-lab`` starts the Jupyter session, allowing
you to interact with the board using PYNQ.remote.

**Linux/macOS:**

.. code-block:: bash

   export PYNQ_REMOTE_DEVICES=192.168.2.99
   uv run jupyter-lab

**Windows (PowerShell):**

.. code-block:: powershell

   $env:PYNQ_REMOTE_DEVICES = "192.168.2.99"
   uv run jupyter-lab

Navigate to the ``pynq-notebooks/pynq-helloworld`` directory and explore the
``resizer_pl.ipynb`` notebook.