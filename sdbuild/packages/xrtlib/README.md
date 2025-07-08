# XRT On Target Build Documentation for PYNQ

## Table of Contents
- [Introduction](#introduction)
- [Prerequisites](#prerequisites)
  - [System Requirements](#system-requirements)
  - [Software Requirements](#software-requirements)
- [Installing XRT on target device](#installing-xrt-on-target-device)

---

## Introduction

This document provides step-by-step instructions to build the Xilinx Runtime (XRT) on a target device, install PyXRT, and create XRT Debian packages.

---

## Prerequisites
- **Note:** All required tools are included in the PYNQ 3.1 image.

### System Requirements
- A target device with ARM32 or ARM64 architecture (e.g., RFSoC4x2).
- PYNQ Image.
- Minimum 16 GB of free disk space (tested with a 128GB SD card).

### Software Requirements
- GNU Make
- CMake
- GCC/G++ for ARM
- Python 3.10 (can force rebuild for different versions of python.)
- Git
- Debian packaging tools (e.g., `dpkg`, `debhelper`)

---

## Installing XRT on target device

The version of XRT that will be installed is 2.17.0.
The `qemu.sh` script automates the process of building & installing XRT for your PYNQ device.

Script usage: 
```bash
chmod +x qemu.sh
./qemu.sh [--force-rebuild]
```

By default, the script will download the relevant debian package and pyxrt.so. 

If you include the force rebuild option, The XRT source will be downloaded and build from scratch natively against the installed version of python3 on the PATH. 

XRT and pyxrt.so (The python pybind11 bindings for XRT) will be installed for use with PYNQ. The debian will be built and can be found in the root directory, '/'

---
