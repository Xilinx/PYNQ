![alt tag](https://github.com/Xilinx/PYNQ/blob/master/images/logo.png)

PYNQ is an open-source project from Xilinx that makes it easy to design embedded systems with Zynq All Programmable Systems on Chips (APSoCs). Using the Python language and libraries, designers can exploit the benefits of programmable logic and microprocessors in Zynq to build more capable and exciting embedded systems.
PYNQ users can now create high performance embedded applications with
-	parallel hardware execution
-	high frame-rate video processing
-	hardware accelerated algorithms
-	real-time signal processing
-	high bandwidth IO
-	low latency control

See the [PYNQ webpage](www.pynq.io) for an overview of the project, and find [the PYNQ documentation on ReadTheDocs](http://pynq.readthedocs.io) to get started using PYNQ. 

## Repository details

The project currently supports the PYNQ-Z1 board. 

### Precompiled Image


You [Download the precompiled image for the PYNQ-Z1 board](https://files.digilent.com/Products/PYNQ/pynq_z1_image_2016_09_14.zip) which can be written to a Micro SD card and used to boot the board. 

### Quick start

See the [PYNQ Quickstart guide](http://pynq.readthedocs.io/en/latest/2_getting_started.html) for details on writing the image to an SD card, and getting started with the PYNQ-Z1 board.

### Modify the Python

All Python code for the PYNQ package can be found in the *python* folder. This folder can be found on the board after the board boots with the precompiled image. 

You can clone this repository, edit the Python code and copy it directly to the corresponding folder on the board. (You may need to reboot the board to load the changes.)

### Xilinx files and new overlays

All board related files including Vivado and SDK software projects, bitstreams, and example notebooks, can be found in the Pynq-Z1 folder.

You can rebuild the base overlay by running *make* in ./Pynq-Z1/vivado/base. This will generate a bitstream in ./Pynq-Z1/bitstream. You can also find the project tcl file here. You can use the base overlay as a starting point for creating a new overlay. If you create a new overlay, you should also save the tcl and bitstream to this directory, and copy both files to ./bitstream on the board.

### Contribute

Fork this repository to your own github account using the 'fork' button above

Clone (Download) the fork to a local computer using 'git clone' 

You can add a new Vivado project, bitstream, SDK project, or notebook to the corresponding folder in ./Pynq-Z1

Create a new directory, and add all your project files with the appropriate license clearly stated

Add a README.md file 

Use git add-->git commit-->git push to add changes to your fork 

Then submit a pull request by clicking the 'pull request' button on YOUR github repo.

[Guide to git](http://git.huit.harvard.edu/guide/)

### Support

Please ask questions on the [PYNQ support forum](https://groups.google.com/forum/#!forum/pynq_project)
