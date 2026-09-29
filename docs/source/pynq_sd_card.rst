.. _pynq-sd-card:

******************
PYNQ SD Card image
******************

This page explains how SD card images can be built for PYNQ embedded
platforms.

Note: the PYNQ images for supported boards are provided as precompiled 
`downloadable SD card images <https://www.pynq.io/boards.html>`_ and do 
not need rebuilt.  The SD card build flow is
only required to modify SD cards' contents or target a new board.

Specifically, the SD card build flow creates ``BOOT.BIN``, the U-Boot
bootloader, the Linux device tree blob, the Linux kernel and the
PYNQ-Linux root filesystem.

The source files for the PYNQ image flow build can be found here:

.. code-block:: console
    
   <PYNQ repository>/sdbuild


Prepare the Building Environment
================================

The image build runs in a Docker container based on the following Ubuntu
release:

================  ==================
Supported OS      Code name
================  ==================   
Ubuntu 24.04       Noble
================  ==================

Use Docker to prepare the build environment
-------------------------------------------
Docker manages the image build dependencies and environment. AMD tools remain
on the host and are mounted into the container.

  1. Install Docker on your host OS by following the 
     `official Docker installation instructions <https://docs.docker.com/engine/install/>`_.

  2. Install the required AMD tools on the host:
     
     * **Vivado** and **Vitis**, version 2025.2 (Petalinux is no longer required)
     * Ensure your host OS is supported by the AMD tools (see 
       `UG973 <https://docs.amd.com/r/2025.2-English/ug973-vivado-release-notes-install-license/Supported-Operating-Systems>`_)

     .. note::
        AMD tools must be installed on the host system, not inside the Docker container.

  3. Clone the PYNQ repository and build the Docker image:

     .. code-block:: console
    
        git clone --recursive https://github.com/Xilinx/PYNQ.git PYNQ
        cd PYNQ/sdbuild
        docker build \
          --build-arg USERNAME=$(whoami) \
          --build-arg USER_UID=$(id -u) \
          --build-arg USER_GID=$(id -g) \
          -t pynqdock:latest .

     The ``--build-arg`` values ensure that files created inside the container 
     will be owned by your user on the host system, avoiding permission issues.

  4. From the top of the PYNQ repository, set the paths to the AMD tools and
     licence, then run the container:

     .. code-block:: console

        export XILINX_TOOLS=/tools/Xilinx/2025.2
        export XILINXD_LICENSE_FILE="$HOME/.Xilinx"

        docker run --init --rm \
          --network host \
          -e XILINX_TOOLS -e XILINXD_LICENSE_FILE \
          -v "$XILINX_TOOLS:$XILINX_TOOLS:ro" \
          -v "$XILINXD_LICENSE_FILE:$XILINXD_LICENSE_FILE" \
          -v "$PWD:/workspace" \
          --privileged \
          pynqdock:latest \
          bash -lc 'cd /workspace/sdbuild && make BOARDS=ZCU104 REBUILD_PYNQ_SDIST=1 REBUILD_PYNQ_ROOTFS=1'

     Set ``BOARDS=VCK190`` to build a VCK190 image. Multiple board names can be
     supplied at once.

Building the Image
==================

The build flow expects a prebuilt board-agnostic root filesystem and PYNQ source
distribution unless they are rebuilt from source. Place prebuilt files in the
``sdbuild/prebuilt`` folder:

.. code-block:: console

   cp pynq_rootfs.aarch64.tar.gz <PYNQ repository>/sdbuild/prebuilt/
   cp pynq-<version>.tar.gz <PYNQ repository>/sdbuild/prebuilt/pynq_sdist.tar.gz

To build one of the supported images using the prebuilt files:

.. code-block:: console

   cd <PYNQ repository>/sdbuild/
   make BOARDS=ZCU104
   make BOARDS=VCK190

To build the PYNQ source distribution and root filesystem from source:

.. code-block:: console

   make BOARDS=ZCU104 REBUILD_PYNQ_SDIST=1 REBUILD_PYNQ_ROOTFS=1

The image is written to ``sdbuild/output/<BOARD>-4.0.0.img`` and its boot
artefacts are written to ``sdbuild/output/boot/<BOARD>/``.

Rebuilding the prebuilt board-agnostic image
--------------------------------------------
ZCU104 and VCK190 use the ``aarch64`` root filesystem. Reusing the prebuilt
root filesystem skips the board-agnostic stage.

You can force a root filesystem build by setting the ``REBUILD_PYNQ_ROOTFS`` variable
when invoking make:

.. code-block:: console
    
   cd <PYNQ repository>/sdbuild/
   make REBUILD_PYNQ_ROOTFS=1 BOARDS=<board>

Rebuilding the PYNQ source distribution tarball
-----------------------------------------------
Reuse the prebuilt PYNQ source distribution package unless the package or
included overlays have changed.

You can force a PYNQ source distribution rebuild by setting the ``REBUILD_PYNQ_SDIST`` variable
when invoking make

.. code-block:: console
    
   cd <PYNQ repository>/sdbuild/
   make REBUILD_PYNQ_SDIST=1 BOARDS=<board>

Cleaning image build output
---------------------------

To remove the build and output directories while retaining the EDF cache:

.. code-block:: console
    
   cd <PYNQ repository>/sdbuild/
   make clean

The first EDF build creates an ``sdbuild/edf-cache`` directory of approximately
30 GB. Set ``EDF_CACHE=/path/to/edf-cache`` to share it between checkouts or
store it on another filesystem.


Retargeting to a Different Board
================================

Additional boards can be supplied through an external board directory. Each
board is a directory containing a ``<BOARD>.spec`` file and an ``edf.env`` file.
Those two are the only required files; everything else is added as the board
needs it. The external directory is treated like the
``<PYNQ repository>/boards`` directory.

Board directory layout
----------------------

.. code-block:: console

   Myboard/
   ├── Myboard.spec          # required: make variables for the board
   ├── edf.env               # required: boot artefact configuration
   ├── edf_bsp/              # optional
   │   ├── board.dtsi        # optional: device tree nodes for the board
   │   ├── kernel.cfg        # optional: kernel config fragment
   │   └── u-boot/           # optional: u-boot patches and config fragments
   ├── base/                 # required if BITSTREAM_<BOARD> is set: overlay
   │                         # sources and a Makefile that builds them
   ├── notebooks/            # optional: notebooks, delivered to the image
   └── packages/             # optional: extra packages for the root filesystem

The directory name is the board name. It must match the ``.spec`` file name and
the ``<BOARD>`` suffix of the variables inside it, and it becomes the ``BOARD``
environment variable in the image.

Elements of the specification file
----------------------------------

The specification file should be named ``<BOARD>.spec``, where BOARD is the name
of the board directory. All paths in it are relative to the board directory.

=========================== ============ ======================================
Variable                                 Meaning
=========================== ============ ======================================
``ARCH_<BOARD>``            required     ``aarch64``
``BITSTREAM_<BOARD>``       optional     Overlay loaded at boot, for example
                                         ``base/base.bit`` or ``base/base.pdi``.
                                         Leave unset for a board with no boot
                                         overlay
``FPGA_MANAGER_<BOARD>``    optional     ``1`` to program the PL through the
                                         FPGA manager. Defaults to ``1``, and
                                         selects which zocl device tree nodes
                                         are used
``STAGE4_PACKAGES_<BOARD>`` optional     Packages installed into the board's
                                         root filesystem. Without ``pynq`` here
                                         the image has no PYNQ in it
``REMOTE_PACKAGES_<BOARD>`` optional     Extra packages for a PYNQ.remote root
                                         filesystem
=========================== ============ ======================================

.. code-block:: makefile

   ARCH_Myboard := aarch64
   BITSTREAM_Myboard := base/base.bit
   FPGA_MANAGER_Myboard := 1
   STAGE4_PACKAGES_Myboard := xrt pynq ethernet selftest

Boot artefacts: ``edf.env``
---------------------------

``BOOT.BIN``, the kernel ``Image``, ``system.dtb``, the kernel modules and
``zocl.ko`` are built with AMD's EDF (Yocto/bitbake) flow. ``edf.env`` selects
the Yocto machine to build them for.

========================== ============ =======================================
Key                                     Meaning
========================== ============ =======================================
``EDF_BOOT_MACHINE``       required     Machine used for ``BOOT.BIN`` and the
                                        device tree
``EDF_MODE``               optional     ``prebuilt`` to use a machine from
                                        AMD's layers, ``custom`` to generate
                                        one from an XSA. Defaults to
                                        ``prebuilt``
``EDF_LINUX_MACHINE``      optional     Machine used for the kernel. Defaults
                                        to ``EDF_BOOT_MACHINE``
``EDF_MANIFEST_TAG``       optional     EDF manifest tag to sync. Defaults to
                                        the tag used by the build scripts
``BSP_XSA_PATH``           custom mode  The XSA to generate the machine from.
                                        Without it, ``base/base.xsa`` is used
                                        if present
``EDF_BOARD_DTS``          optional     Custom mode only: board DTS to pass to
                                        ``sdtgen``. Omit to use the generic SoC
                                        device tree and put everything
                                        board-specific in ``board.dtsi``
``EDF_DDR_HIGH_BANK_REG``  optional     ``reg`` value trimming the high DDR
                                        bank to the board's real size
========================== ============ =======================================

Use prebuilt mode when AMD's layers already contain a machine for the board, as
for the ZCU104:

.. code-block:: shell

   EDF_MANIFEST_TAG=amd-edf-rel-v25.11.1
   EDF_MODE=prebuilt
   EDF_BOOT_MACHINE=zynqmp-zcu104-sdt-full
   EDF_LINUX_MACHINE=zynqmp-zcu104-sdt-full

Use custom mode when the boot image has to match a design built here, as on
Versal, where ``BOOT.BIN`` carries the golden reference design that runtime
overlays are segmented children of. The build runs ``sdtgen`` on
``BSP_XSA_PATH`` to produce a system device tree, then ``gen-machine-conf`` to
turn that into a machine layer, so Vivado must be available. The VCK190:

.. code-block:: shell

   EDF_MANIFEST_TAG=amd-edf-rel-v25.11.1
   EDF_MODE=custom
   EDF_BOOT_MACHINE=versal-vck190-pynq-seg
   EDF_LINUX_MACHINE=amd-cortexa72-common
   EDF_BOARD_DTS=versal-vck190-reva
   BSP_XSA_PATH=golden/golden.xsa

In custom mode ``EDF_BOOT_MACHINE`` must not match a machine name in AMD's
layers, or bitbake resolves theirs and ignores the generated one.

Kernel, device tree and U-Boot: ``edf_bsp``
-------------------------------------------

All three are optional, and a board that needs none of them can omit
``edf_bsp`` entirely.

 1. ``board.dtsi`` is appended to the machine's device tree. Board-specific
    nodes belong here: memory, PHYs, I2C devices, pin settings.
 2. ``kernel.cfg`` is added to the kernel's sources as a config fragment when
    present, and merged into its ``.config``.
 3. ``u-boot/`` is added to U-Boot's sources when present. ``.patch`` and
    ``.diff`` files are applied, and ``.cfg`` fragments are merged into U-Boot's
    ``.config``.

Editing ``board.dtsi`` invalidates the device tree's shared state, so the change
is picked up on the next build.

Board-specific packages
-----------------------

A ``packages`` directory can be included in the board directory with the same
layout as the ``<PYNQ repository>/sdbuild/packages`` directory. A directory
under it becomes installable by naming it in ``STAGE4_PACKAGES_<BOARD>``, and
packages from the standard sdbuild library can be named there too. A package
consists of up to four optional files: a ``Makefile`` for work done on the host,
``pre.sh`` and ``post.sh`` which run outside the target root filesystem and are
passed its path, and ``qemu.sh`` which runs inside it under QEMU. Scripts should
write temporary files to ``$BUILD_ROOT``.

Leveraging ``boot.py`` to modify SD card boot behavior
------------------------------------------------------

Starting from the v2.6.0 release, PYNQ SD card images include a ``boot.py`` 
file in the boot partition that runs automatically after the board has been 
booted.  Whatever is inside this file runs during boot and can be modified 
any time for a custom next-boot behavior (e.g. changing the host name, 
connecting the board to WiFi, etc.). 

This file can be accessed using a SD Card reader on your host machine or 
from a running PYNQ board - if you are live on the board inside Linux, the 
file is located in the ``/boot`` folder.  Note that  ``/boot`` is the 
boot partition of the board and no other files should be modified.

If you see some existing code running inside the boot.py file, it probably came
from a PYNQ sdbuild package that modified that file.  To see an example of an
sdbuild package writing the boot.py file see the ZCU104's ``boot_leds`` package
in ``<PYNQ repository>/boards/ZCU104/packages/boot_leds``, which simply flashes
the boards LEDs to signify Linux has booted on the board.

Using the PYNQ package
----------------------

The ``pynq`` package will treat your board directory the same as any of the
officially supported boards. This means, in particular, that:

 1. A ``notebooks`` folder, if it exists, will be copied into the
    ``jupyter_notebooks`` folder in the image. Notebooks here will overwrite any of
    the default ones.
 2. Any directory containing a ``.bit`` or ``.pdi`` file will be treated as an overlay and
    copied into the overlays folder of the PYNQ installation. Any notebooks will
    likewise by installed in an overlay-specific subdirectory.


Building from a board repository
================================

To build from a third-party board repository, pass the ``BOARDDIR`` variable to the
sdbuild makefile.

.. code-block:: console
    
   cd <PYNQ repository>/sdbuild/
   make BOARDDIR=${BOARD_REPO}

The board repo should be provided as an absolute path. The ``BOARDDIR`` variable
can be combined with the ``BOARDS`` variable if the repository contains multiple
boards and only a subset should be built.
