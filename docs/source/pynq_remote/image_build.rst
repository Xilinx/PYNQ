

Remote Image Build Guide
========================

Unlike classic PYNQ, there are no pre-built PYNQ.remote SD card images
available, so you need to build your own. This can be done in one of two ways:

#. **Using the Docker-based build flow**: This is the recommended method for
   most users, as it simplifies the build process and ensures a consistent
   environment.
#. **Integrating the PYNQ metalayer into a custom EDF build**: This is for
   advanced users who want to customize their Yocto projects with PYNQ
   features.

**Prerequisites:**

- Host machine capable of running the Ubuntu 24.04 (Noble) Docker container
- AMD tools: Vivado and Vitis version 2025.2
- `Docker installation <https://docs.docker.com/engine/install/>`_

Using the Docker-based build flow
---------------------------------

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

   Boards that are not in the PYNQ repository, such as the RFSoC 4x2 used by
   RFSoC-PYNQ, are built by passing ``BOARDDIR`` with the board repository
   path. See :ref:`pynq-sd-card` for the board directory layout.

#. Flash the generated ``sdbuild/output/<BOARD>-4.0.0-remote.img`` image to an
   SD card and boot your device (see :doc:`../appendix/sdcard`).

#. After booting, the ``pynq-remote`` server starts automatically. Use
   ``ip addr`` on the board to find its address, then follow :doc:`quickstart`.

Image size
----------

Remote root filesystems are much smaller than classic PYNQ images. For example,
an RFSoC 4x2 remote image is around 238 MB. The final SD card image also
includes boot artefacts built by EDF.

Alternative: PYNQ metalayer in a custom EDF build
-------------------------------------------------

Advanced users can integrate the ``meta-pynq`` metalayer into their own Yocto
projects built on AMD's EDF (Extensible Device Framework). The layer lives at
``sdbuild/boot/meta-pynq/`` and declares Scarthgap compatibility. The remote
root filesystem is produced by ``sdbuild/scripts/build_edf_remote_rootfs.sh``.
