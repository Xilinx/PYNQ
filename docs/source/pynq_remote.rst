.. _pynq_remote:

PYNQ.remote 
===========

.. note::
      PYNQ.remote is currently in **beta**. Active development is ongoing, and some PYNQ features may have limited support. The API is subject to change in future releases. For more information on currently supported functionality and our development roadmap, see the :ref:`roadmap`.

.. toctree::
   :maxdepth: 1
   :caption: Contents

   pynq_remote/quickstart
   pynq_remote/image_build
   pynq_remote/remote_device
   pynq_remote/cppindex
   pynq_remote/roadmap

PYNQ.remote is an extension to the PYNQ framework that enables remote control of AMD's FPGA-based devices. By moving the Python API to the host and communicating with the target device via gRPC, PYNQ.remote brings powerful new deployment, integration, and scalability features to PYNQ users, while preserving the familiar PYNQ user experience.

**Key Features**

* Offload the Python API to your host machine, reducing on-target resource requirements.
* Target-side C++ implementation (`PYNQ.cpp`) for boosting on-device performance.
* Lightweight Petalinux images: shrink SD card images from ~7GB to under 200MB (small enough for a RAM disk).
* PYNQ API compatibility: classic PYNQ code and Jupyter notebooks run remotely, with minimal or no changes.
* Extend with custom remote APIs using Protobuf definitions.

**Who Should Use PYNQ.remote?**

* Developers who want to deploy PYNQ-based applications with a minimal software footprint on the target.
* Users needing hybrid workflows, such as host-based AI acceleration, design tool integration, or cloud offload.
* Anyone wanting to scale across multiple devices, or integrate with host-side tools and workflows.

**Getting Started**

To get started with PYNQ.remote, follow the quickstart guide in :ref:`quickstart`. This will walk you through setting up your environment, deploying the remote image, and running your first remote application.