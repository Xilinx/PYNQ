---
layout: default
title: PYNQ supported boards and PYNQ pre-built images
description: 
---

# Development Boards

PYNQ supports Zynq based boards (Zynq, Zynq Ultrascale+, Zynq RFSoC), Kria SOMs, Xilinx Alveo accelerator boards and AWS-F1 instances.

See the PYNQ Alveo Getting Started guide for details on installing PYNQ for use with Alveo and AWS-F1.

## Downloadable PYNQ images

If you have a Zynq board, you need a PYNQ SD card image to get started. You can download a pre-compiled PYNQ image from the table below. If an image is not available for your board, you can build your own SD card image (see details below).



| Board | SD card image | Previous versions | Documentation | Board webpage | 
| - | - | - | - | - | 
| PYNQ-Z2 | [v3.0.1](https://bit.ly/pynqz2_v3_0_1) | v2.7  v2.6 | [PYNQ setup guide](https://pynq.readthedocs.io/en/latest/getting_started/other_boards.html) | [TUL Pynq-Z2](https://www.tulembedded.com/FPGA/ProductsPYNQ-Z2.html) | 
| PYNQ-Z1 | [v3.0.1](https://bit.ly/pynqz1_v3_0_1) | v2.7  v2.6 | [PYNQ setup guide](https://pynq.readthedocs.io/en/latest/getting_started/pynq_z1_setup.html) | [Digilent Pynq-Z1](https://store.digilentinc.com/pynq-z1-python-productivity-for-zynq-7000-arm-fpga-soc/) | 
| PYNQ-ZU | [v3.0.1](https://bit.ly/pynqzu_v3_0_1) | v2.7  v2.6 | [GitHub project page](https://github.com/Xilinx/PYNQ-ZU) | [TUL PYNQ-ZU](https://www.tulembedded.com/FPGA/ProductsPYNQ-ZU.html) |
| Kria KV260* | [Ubuntu 22.04](https://www.xilinx.com/products/som/kria/kv260-vision-starter-kit/kv260-getting-started-ubuntu/setting-up-the-sd-card-image.html) | | [Kria PYNQ setup](https://github.com/Xilinx/Kria-PYNQ) | [Xilinx Kria KV260](https://www.xilinx.com/products/som/kria/kv260-vision-starter-kit.html) |
| Kria KR260* | [Ubuntu 22.04](https://www.xilinx.com/products/som/kria/kr260-robotics-starter-kit/kr260-getting-started/setting-up-the-sd-card-image.html) | | [Kria PYNQ setup](https://github.com/Xilinx/Kria-PYNQ) | [Xilinx Kria KR260](https://www.xilinx.com/products/som/kria/kr260-robotics-starter-kit.html) |
| ZCU104 | [v3.0.1](https://bit.ly/zcu104_v3_0_1) | v2.7  v2.6 | [PYNQ setup guide](https://pynq.readthedocs.io/en/latest/getting_started/zcu104_setup.html) | [Xilinx ZCU104](https://www.xilinx.com/products/boards-and-kits/zcu104.html) |
| RFSoC 2x2 | [v3.0.1](https://bit.ly/rfsoc2x2_v3_0_1) | v2.7  v2.6 | [RFSoC-PYNQ](https://xilinx.github.io/RFSoC2x2-PYNQ/) | [XUP RFSoC 2x2](https://www.xilinx.com/support/university/xup-boards/RFSoC2x2.html) |
| RFSoC 4x2 | [v3.0.1](https://bit.ly/rfsoc4x2_v3_0_1) | [v2.7](https://bit.ly/rfsoc4x2_v2_7) | [RFSoC-PYNQ](https://www.rfsoc-pynq.io/) | [XUP RFSoC 4x2](https://www.xilinx.com/support/university/xup-boards/RFSoC4x2.html) |
| ZCU111 | [v3.0.1](https://bit.ly/zcu111_v3_0_1) | v2.7  v2.6 | [RFSoC-PYNQ](https://www.rfsoc-pynq.io/) | [Xilinx ZCU111](https://www.xilinx.com/products/boards-and-kits/zcu111.html) |
| ZCU208 | [v3.0.1](https://bit.ly/zcu208_v3_0_1) |  | [RFSoC-PYNQ](https://www.rfsoc-pynq.io/) | [Xilinx ZCU208](https://www.xilinx.com/products/boards-and-kits/zcu208.html) |
| Ultra96V2 | [v3.0.1](https://bit.ly/ultra96v2_v3_0_1) | v2.7  v2.6 | [Avnet PYNQ webpage](http://avnet.me/ultra96_pynq_docs) | [Avnet Ultra96V2](https://www.avnet.com/wps/portal/us/products/new-product-introductions/npi/aes-ultra96-v2/) |
| Ultra96 (legacy) | [v3.0.1](https://bit.ly/ultra96v1_v3_0_1) | v2.7  v2.6 | See Ultra96V2 | See Ultra96V2 |
| ZUBoard 1CG | [v3.0.1](https://bit.ly/zuboard_v3_0_1) | | [GitHub project page](https://github.com/Avnet/ZUBoard_1CG-PYNQ/) | [Avnet ZUBoard 1CG](https://www.avnet.com/wps/portal/us/products/avnet-boards/avnet-board-families/zuboard-1cg/zuboard-1cg) |
| TySOM-3-ZU7EV | [v3.0.1](https://bit.ly/Tysom3_v3_0_1) | [v2.7](https://bit.ly/tysom3_v2_7) | [GitHub project page](https://github.com/aldec/TySOM-PYNQ) | [Aldec TySOM-3-ZU7EV](https://www.aldec.com/en/products/emulation/tysom_boards) |
| TySOM-3A-ZU19EG | [v3.0.1](https://bit.ly/Tysom3a_v3_0_1) | [v2.7](https://bit.ly/tysom3a_v2_7) | [GitHub project page](https://github.com/aldec/TySOM-PYNQ) | [Aldec TySOM-3A-ZU19EG](https://www.aldec.com/en/products/emulation/tysom_boards) |

<br>

*For the Kria KV260 and KR260, follow the links above for guide for getting started with the Ubuntu image, and then follow the Kria PYNQ setup instructions to install PYNQ.

# Build a PYNQ image

The following binary files can be used to build PYNQ for a custom board. See the [PYNQ image build guide](http://pynq.readthedocs.io/en/latest/pynq_sd_card.html) for details on building the PYNQ image.

Prebuilt board-agnostic  _root filesystem_, and prebuilt  _source distribution_  binaries:

-   [PYNQ rootfs aarch64 v3.0.1](https://bit.ly/pynq_aarch64_v3_0_1)
-   [PYNQ rootfs arm v3.0.1](https://bit.ly/pynq_arm_v3_1)

-   [Prebuilt PYNQ source distribution binary v3.0.1](https://bit.ly/pynq_sdist_v3_0_1)

Previous versions:

-   [PYNQ rootfs aarch64 v2.7](https://bit.ly/pynq_aarch64_2_7)
-   [PYNQ rootfs arm v2.7](https://bit.ly/pynq_arm_2_7)

-   [Prebuilt PYNQ source distribution binary v2.7](https://bit.ly/pynq_binary_v2_7)



# Recommended getting started board

![PYNQ-Z2 board](./assets/images/pynqz2.png#left)


The [PYNQ-Z2 board from TUL](http://www.tulembedded.com/FPGA/ProductsPYNQ-Z2.html) is the recommended board for getting started with PYNQ. The PYNQ-Z2 is a low-cost Zynq 7000 development board suitable for beginner and more advanced projects. It has many features and interfaces that are useful for trying out the capabilities of the PYNQ framework.


| PYNQ-Z2    |                                       |
| ---------- | ------------------------------------- |
| Device     | Zynq Z7020                            |
| Memory     | 512MB DDR3                            |
| Storage    | MicroSD                               |
| Video      | HDMI In & Out ports                   |
| Audio      | ADAU1761 codec with HP + Mic, Line in |
| Network    | 10/100/1000 Ethernet                  |
| Expansion  | USB host (PS)                         |
| GPIO       | 1x Arduino Header                     |
|            | 2x Pmod\*                             |
|            | 1x RaspberryPi header\*               |
| Other I/O  | 6x user LEDs                          |
|            | 4x Pushbuttons                        |
|            | 2x Dip switches                       |
| Dimensions | 3.44” x 5.51” (87mm x 140mm)          |
| Webpage    | TUL PYNQ-Z2 webpage                   |

*PYNQ-Z2 RaspberryPi header shares 8 pins with 1 Pmod