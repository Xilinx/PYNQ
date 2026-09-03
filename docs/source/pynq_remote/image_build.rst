

Remote Image Build Guide
========================

Unlike Classic PYNQ, there are no pre-built PYNQ.remote SD card images available, so you'll need to build your own. This can be done in one of two ways:

#. **Using the Docker-based build flow**: This is the recommended method for most users, as it simplifies the build process and ensures a consistent environment.
#. **Integrating the PYNQ metalayer into a custom EDF build**: This is for advanced users who want to customize their Yocto projects with PYNQ features.

**Prerequisites:**

- Host machine capable of running the Ubuntu 24.04 (Noble) Docker container
- AMD tools: Vivado and Vitis version 2025.2
- `Docker installation <https://docs.docker.com/engine/install/>`_

**Using the Docker-based build flow:**

#. Clone the PYNQ repository:

   .. code-block:: bash

        git clone --recursive https://github.com/Xilinx/PYNQ.git

#. Set up the build environment by following :ref:`pynq-sd-card`. This includes
   setting ``XILINX_TOOLS`` and ``XILINXD_LICENSE_FILE`` before starting the
   container.

#. Build the remote image for your target board:

   .. code-block:: bash

        # Inside the Docker container
        cd PYNQ/sdbuild
        make pynqremote BOARDS=<board_name>

   Replace ``<board_name>`` with your target board (``ZCU104`` or ``VCK190``).
   The remote image target does not require the prebuilt classic PYNQ root
   filesystem or source distribution.

#. Flash the generated ``sdbuild/output/<BOARD>-4.0.0-remote.img`` image to an
   SD card and boot your device (See :doc:`../appendix/sdcard` for more
   details).

#. After booting, the ``pynq-remote`` server will start automatically, allowing you to connect to the device (see :doc:`quickstart` for more details).

**Alternative: Using PYNQ Metalayer in Custom EDF Build**

Advanced users can integrate the ``meta-pynq`` metalayer into their own Yocto
projects built on AMD's EDF (Extensible Device Framework). The layer lives at
``sdbuild/boot/meta-pynq/`` and declares Scarthgap compatibility.
