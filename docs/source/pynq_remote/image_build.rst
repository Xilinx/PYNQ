

Remote Image Build Guide
========================

Unlike Classic PYNQ, there are no pre-built PYNQ.remote SD card images available, so you'll need to build your own. This can be done in one of two ways:

#. **Using the Docker-based build flow**: This is the recommended method for most users, as it simplifies the build process and ensures a consistent environment.
#. **Integrating the PYNQ metalayer into a custom Petalinux build**: This is for advanced users who want to customize their Petalinux projects with PYNQ features

**Prerequisites:**

- AMD Tools: `Vivado, Vitis, and Petalinux version 2024.1 <https://www.xilinx.com/support/download/index.html/content/xilinx/en/downloadNav/vivado-design-tools/2024-1.html>`_
- `Docker installation <https://docs.docker.com/engine/install/>`_
- Supported Linux distribution (see `UG973 <https://docs.amd.com/r/2024.1-English/ug973-vivado-release-notes-install-license/Supported-Operating-Systems>`_)

**Using the Docker-base build flow:**

#. Clone the PYNQ repository:

   .. code-block:: bash

        git clone --recursive https://github.com/Xilinx/PYNQ.git

#. Follow the Docker-based build instructions in the `sdbuild/README.md <https://github.com/Xilinx/PYNQ/blob/master/sdbuild/README.md>`_ file to set up the build environment.

#. Build the remote image for your target board:

   .. code-block:: bash

        # Inside the Docker container
        cd PYNQ/sdbuild
        make pynqremote BOARDS=<board_name>

   Replace ``<board_name>`` with your target board (e.g., ``ZCU104``, ``Pynq-Z2``).

#. Flash the generated image from ``sdbuild/output/`` to an SD card and boot your device (See :doc:`../appendix/sdcard` for more details).

#. After booting, the ``pynq-remote`` server will start automatically, allowing you to connect to the device (see :doc:`quickstart` for more details).

**Alternative: Using PYNQ Metalayer in Custom Petalinux Build**

Advanced users can integrate the `meta-pynq` metalayer into their own Petalinux projects. Refer to the `Petalinux Tools Reference Guide (UG1144) <https://docs.amd.com/r/2024.1-English/ug1144-petalinux-tools-reference-guide>`_ for detailed instructions.
