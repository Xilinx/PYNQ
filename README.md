![alt tag](https://github.com/Xilinx/PYNQ/blob/master/logo.png)

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

The project currently supports the PYNQ-Z1 board. 

You can <a href="https://files.digilent.com/Products/PYNQ/pynq_z1_image_2017_02_10.zip" target="_blank">download the precompiled image</a>, write the image to a micro SD card, and boot the board from the micro SD card. 

## Quick Start

See the <a href="http://pynq.readthedocs.io/en/latest/1_getting_started.html" target="_blank">Quickstart guide</a> for details on writing the image to an SD card, and getting started with the PYNQ-Z1 board.

## Modify Python

All Python code for the `pynq` package can be found in the `/python` folder. This folder can be found on the board after the board boots with the precompiled image. 

You can clone this repository, edit the Python code and copy it directly to the corresponding folder on the board. (You may need to reboot the board to load the changes.)

## Board Files and Overlays

All board related files including Vivado and SDK software projects, bitstreams, and example notebooks, can be found in the `/Pynq-Z1` folder.

You can rebuild the base overlay by running *make* in `/Pynq-Z1/vivado/base`. This will generate a bitstream in `/Pynq-Z1/bitstream`. You can also find the project tcl file here. You can use the base overlay as a starting point for creating a new overlay. If you create a new overlay, you should also save the tcl and bitstream to this directory, and copy both files to `/bitstream` on the board.

## Contribute

Contributions to this repository are welcomed. To submit a project for inclusion:

1. Fork this repository to your own github account using the *fork* button above.

2. Clone (download) the fork to a local computer using *git clone*.

3. You can modify the Vivado project, bitstream, SDK project, or notebook in the corresponding folder in `/Pynq-Z1`.

5. Modify the documentation if necessary.

6. Use *git add*-->*git commit*-->*git push* to add changes to your fork.

7. Then submit a pull request by clicking the *pull request* button on your github repo.

Check the <a href="http://git.huit.harvard.edu/guide/" target="_blank">guide to git</a> for more information.

## Support

Please ask questions on the <a href="https://groups.google.com/forum/#!forum/pynq_project" target="_blank">PYNQ support forum</a>.
