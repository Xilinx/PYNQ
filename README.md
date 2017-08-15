![alt tag](./logo.png)

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

See the <a href="http://pynq.readthedocs.io/en/latest/getting_started.html" target="_blank">Quickstart guide</a> for details on writing the image to an SD card, and getting started with the PYNQ-Z1 board.

## Python Source Code

All Python code for the `pynq` package can be found in the `/pynq` folder. This folder can be found on the board after the board boots with the precompiled image.

You can clone this repository, edit the Python source code and copy it directly to the corresponding folder on the board. (You may need to reboot the board to load the changes.)

SDK software projects and Python-C source codes are also stored along with the Python source code. After installing the `pynq` package, the compiled target files will be saved automatically into the `pynq` package.

## Board Files and Overlays

All board related files including Vivado projects, bitstreams, and example notebooks, can be found in the `/boards` folder.

You can rebuild the overlay by running *make* in the corresponding overlay folder (e.g. `/boards/Pynq-Z1/base`). This will generate a bitstream in the overlay folder. You can also find the project tcl file here. 

You can use the base overlay as a starting point for creating a new overlay. If you create a new overlay, you should make sure
both the bitstream file `<overlay_name>.bit` and the tcl file `<overlay_name>.tcl` are inside `/pynq/overlays/<overlay_name>` folder.

## Contribute

Contributions to this repository are welcomed. To submit a project for inclusion:

1. Fork this repository to your own github account using the *fork* button above.

2. Clone (download) the fork to a local computer using *git clone*.

3. You can modify the Vivado project, bitstream, SDK project, Python source code, or notebook in the corresponding folders.

5. Modify the documentation if necessary.

6. Use *git add*-->*git commit*-->*git push* to add changes to your fork.

7. Then submit a pull request by clicking the *pull request* button on your github repo.

Check the <a href="http://git.huit.harvard.edu/guide/" target="_blank">guide to git</a> for more information.

## Support

Please ask questions on the <a href="https://groups.google.com/forum/#!forum/pynq_project" target="_blank">PYNQ support forum</a>.
