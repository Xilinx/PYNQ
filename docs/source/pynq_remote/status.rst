.. _status:

Current Status
==============

This document outlines the current status of PYNQ.remote.

* **Supported PYNQ Version**: 4.0.0
* **Required Tool Version**: 2025.2
* **Validated Platforms**:
   * `ZCU104 <https://www.amd.com/en/products/adaptive-socs-and-fpgas/evaluation-boards/zcu104.html>`_
   * `VCK190 <https://www.amd.com/en/products/adaptive-socs-and-fpgas/evaluation-boards/vck190.html>`_
   * `AUP-ZU3 <https://www.realdigital.org/hardware/aup-zu3>`_  (coming soon!)
   * Supported `RFSoC-PYNQ <https://www.rfsoc-pynq.io/getting_started.html>`_ platforms.
* **Image build**: EDF/Yocto remote rootfs (see :doc:`image_build`)
* **Supported Features**:
   * :doc:`../pynq_overlays/loading_an_overlay`
   * :doc:`../pynq_libraries/mmio`
   * :doc:`../pynq_libraries/dma`
   * :doc:`../pynq_libraries/allocate`
   * :doc:`../pynq_libraries/psgpio` (``RemoteGPIO``)
   * RFSoC clock and data converter control (RFSoC remote images)
* **Not yet supported**:
   * :doc:`../pynq_libraries/interrupt`
   * Multi-board support