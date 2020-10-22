![pynq_logo](https://github.com/Xilinx/PYNQ/raw/master/logo.png)

![python](https://github.com/Xilinx/PYNQ/workflows/Python/badge.svg)

PYNQ is an open-source project from Xilinx that makes it easy to design embedded systems with Zynq All Programmable Systems on Chips (APSoCs). Using the Python language and libraries, designers can exploit the benefits of programmable logic and microprocessors in Zynq to build more capable and exciting embedded systems.
PYNQ users can now create high performance embedded applications with
-	parallel hardware execution
-	high frame-rate video processing
-	hardware accelerated algorithms
-	real-time signal processing
-	high bandwidth IO
-	low latency control

See the <a href="http://www.pynq.io/" target="_blank">PYNQ webpage</a> for an overview of the project, and find <a href="http://pynq.readthedocs.io" target="_blank">documentation on ReadTheDocs</a> to get started. 

## Precompiled Image

The project currently supports <a href="http://www.pynq.io/board.html" target="_blank">multiple boards</a>. 

You can download a precompiled image, write the image to a micro SD card, and boot the board from the micro SD card. 

## Quick Start

See the <a href="http://pynq.readthedocs.io/en/latest/getting_started.html" target="_blank">Quickstart guide</a> for details on writing the image to an SD card, and getting started with a PYNQ-enabled board.

## Python Source Code

All Python code for the `pynq` package can be found in the `/pynq` folder. This folder can be found on the board after the board boots with the precompiled image.

To update your PYNQ SD card to the latest `pynq` package, you can run the following command from a terminal connected to your board:

```console
sudo pip3 install --upgrade --upgrade-strategy only-if-needed pynq
```

The `--upgrade-strategy only-if-needed` option will upgrade dependencies only in case they do not satisfy the requirements, which will speed-up the installation process and also avoid possible upgrade errors.

SDK software projects and Python-C source codes are also stored along with the Python source code. After installing the `pynq` package, the compiled target files will be saved automatically into the `pynq` package.

## Board Files and Overlays

All board related files including Vivado projects, bitstreams, and example notebooks, can be found in the `/boards` folder.

In Linux, you can rebuild the overlay by running *make* in the corresponding overlay folder (e.g. `/boards/Pynq-Z1/base`). In Windows, you need to source the appropriate tcl files in the corresponding overlay folder.

## Alveo support

Starting from PYNQ version `2.5.1`, Alveo support has also been introduced. It is now possible to use PYNQ to tap into the potential of hardware acceleration in the data center space.

To get PYNQ on an Alveo-enabled system, simply install it through PIP:

```console
pip install pynq
```

For Alveo cards, PYNQ currently requires a <a href="https://github.com/Xilinx/XRT" target="_blank">Xilinx Runtime (XRT)</a> version above or equal to `2.3` to be installed in the system. In terms of Operating System, any XRT-supported version of either RedHat/CentOS or Ubuntu can be used.

For more information, please see the Alveo <a href="https://pynq.readthedocs.io/en/latest/getting_started/alveo_getting_started.html" target="_blank">getting started guide</a>.

## Contribute

Contributions to this repository are welcomed. Please refer to <a href="https://github.com/Xilinx/PYNQ/blob/master/CONTRIBUTING.md" target="_blank">CONTRIBUTING.md</a> 
for how to improve PYNQ.

## Support

Please ask questions on the <a href="https://discuss.pynq.io" target="_blank">PYNQ support forum</a>.

## Licenses

**PYNQ** License: [BSD 3-Clause License](https://github.com/Xilinx/PYNQ/blob/master/LICENSE)

**Xilinx Embedded SW** License: [Multiple License File](https://github.com/Xilinx/embeddedsw/blob/master/license.txt)

**Digilent IP** License: [MIT License](https://github.com/Xilinx/PYNQ/blob/master/THIRD_PARTY_LIC)

## SDBuild Open Source Components

**License and Copyrights Info** [TAR/GZIP](http://bit.ly/pynq_v2_6_license)

**Open Components Source Code** [TAR/GZIP](http://bit.ly/pynq_v2_6_components)
