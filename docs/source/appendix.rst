********
Appendix
********

Technology Backgrounder
=======================

Overlays and Design Re-use
--------------------------

The 'magic' of mapping an application to an APSoC, without designing custom
hardware, is achieved by using *FPGA overlays*. FPGA overlays are FPGA designs
that are both highly configurable and highly optimized for a given domain.  The
availability of a suitable overlay removes the need for a software designer to
develop a new bitstream. Software and system designers can customize the
functionality of an existing overlay *in software* once the API for the overlay
bitstream is available.

An FPGA overlay is a domain-specific FPGA design that has been created to be
highly configurable so that it can be used in as many different applications as
possible.  It has been crafted to maximize post-bitstream programmability which
is exposed via its API.  The API provides a new entry-point for
application-focused software and systems engineers to exploit APSoCs in their
solutions.  With an API they only have to write software to program configure
the functions of an overlay for their applications.

By analogy with the Linux kernel and device drivers, FPGA overlays are designed
by relatively few engineers so that they can be re-used by many others. In this
way, a relatively small number of overlay designers can support a much larger
community of APSoC designers.  Overlays exist to promote re-use. Like kernels
and device drivers, these hardware-level artefacts are not static, but evolve
and improve over time.

Characteristics of Good Overlays
--------------------------------

Creating one FPGA design and its corresponding API to serve the needs of many
applications in a given domain is what defines a successful overlay.  This,
one-to-many relationship between the overlay and its users, is different from
the more common one-to-one mapping between a bitstream and its application.

Consider the example of an overlay created for controlling drones.  Instead of
creating a design that is optimized for controlling just a single type of drone,
the hardware architects recognize the many common requirements shared by
different drone controllers. They create a design for controlling drones that is
a flexible enough to be used with several different drones.  In effect, they
create a drone-control overlay.  They expose, to the users of their bitstream,
an API through which the users can determine in software the parameters critical
to their application.  For example, a drone control overlay might support up to
eight, pulse-width-modulated (PWM) motor control circuits.  The software
programmer can determine how many of the control circuits to enable and how to
tune the individual motor control parameters to the needs of his particular
drone.

The design of a good overlay shares many common elements with the design of a
class in object-oriented software.  Determining the fundamental data structure,
the private methods and the public interface are common requirements.  The
quality of the class is determined both by its overall usefulness and the
coherency of the API it exposes.  Well-engineered classes and overlays are
inherently useful and are easy to learn and deploy.

Pynq adopts a holistic approach by considering equally the design of the
overlays, the APIs exported by the overlays, and how well these APIs interact
with new and existing Python design patterns and idioms to simplify and improve
the APSoC design process.  One of the key challenges is to identify and refine
good abstractions.  The goal is to find abstractions that improve design
coherency by exposing commonality, even among loosely-related tasks.  As new
overlays and APIs are published, we expect that the open-source software
community will further improve and extend them in new and unexpected ways.

Note that FPGA overlays are not a novel concept.  They have been studied for
over a decade and many academic papers have been published on the topic.

The Case for Productivity-layer Languages
-----------------------------------------

Successive generations of All Programmable Systems on Chip embed more processors
and greater processing power. As larger applications are integrated into APSoCs,
the embedded code increases also. Embedded code that is speed or size critical,
will continue to be written in C/C++.  These 'efficiency-layer or systems
languages' are needed to write fast, low-level drivers, for example. However,
the proportion of embedded code that is neither speed-critical or size-critical,
is increasing more rapidly. We refer to this broad class of code as *embedded
applications code*.

Programming embedded applications code in higher-level, 'productivity-layer
languages' makes good sense.  It simply extends the generally-accepted
best-practice of always programming at the highest possible level of
abstraction.  Python is currently a premier productivity-layer language.  It is
now available in different variants for a range of embedded systems, hence its
adoption in Pynq.  Pynq runs CPython on Linux on the ARM® processors in Zynq®
devices.  To further increase productivity and portability, Pynq uses the
Jupyter Notebook, an open-source web framework to rapidly develop systems,
document their behavior and disseminate the results.

.. _writing-the-sd-card:
   
Writing the SD Card Image
=========================

Windows
-------

* Insert the Micro SD card into your SD card reader and check which drive letter
  was assigned. You can find this by opening Computer/My Computer in Windows
  Explorer.
* Download the `Win32DiskImager utility from the Sourceforge Project page
  <https://sourceforge.net/projects/win32diskimager/>`_
* Extract the *Win32DiskImager* executable from the zip file and run the
  Win32DiskImager utility as administrator. (Right-click on the file, and select
  Run as administrator.)
* Select the PYNQ-Z1 image file (.img).
* Select the drive letter of the SD card. Be careful to select the correct
  drive. If you select the wrong drive you can overwrite data on that
  drive. This could be another USB stick, or memory card connected to your
  computer, or your computer's hard disk.
* Click **Write** and wait for the write to complete.

MAC / OS X
----------

On Mac OS, you can use dd, or the graphical tool ImageWriter to write to your
Micro SD card.

* First open a terminal and unzip the image:

   .. code-block:: console

      unzip pynq_z1_image_2016_09_14.zip -d ./
      
ImageWriter
^^^^^^^^^^^

Note the Micro SD card must be formatted as FAT32.
      
* Insert the Micro SD card into your SD card reader 
* From the Apple menu, choose "About This Mac", then click on "More info..."; if
  you are using Mac OS X 10.8.x Mountain Lion or newer, then click on "System
  Report".
* Click on "USB" (or "Card Reader" if using a built-in SD card reader) then
  search for your SD card in the upper-right section of the window. Click on it,
  then search for the BSD name in the lower-right section; it will look
  something like **diskn** where n is a number (for example, disk4). Make sure
  you take a note of this number.
* Unmount the partition so that you will be allowed to overwrite the disk. To do
  this, open Disk Utility and unmount it; do not eject it, or you will have to
  reconnect it. Note that on Mac OS X 10.8.x Mountain Lion, "Verify Disk"
  (before unmounting) will display the BSD name as `/dev/disk1s1` or similar,
  allowing you to skip the previous two steps.
* From the terminal, run the following command:

   .. code-block:: console
   
      sudo dd bs=1m if=path_of_your_image.img of=/dev/rdiskn

Remember to replace n with the number that you noted before!

If this command fails, try using disk instead of rdisk:

   .. code-block:: console
   
      sudo dd bs=1m if=path_of_your_image.img of=/dev/diskn

Wait for the card to be written. This may take some time. 

Command Line
^^^^^^^^^^^^

* Open a terminal, then run:
   
   .. code-block:: console
   
      diskutil list

* Identify the disk (not partition) of your SD card e.g. disk4, not disk4s1.
* Unmount your SD card by using the disk identifier, to prepare for copying data
  to it:

   .. code-block:: console
      
      diskutil unmountDisk /dev/disk<disk# from diskutil>

   where disk is your BSD name e.g. `diskutil unmountDisk /dev/disk4`

* Copy the data to your SD card:

   .. code-block:: console
   
      sudo dd bs=1m if=image.img of=/dev/rdisk<disk# from diskutil>

   where disk is your BSD name e.g. sudo dd bs=1m
   if=pynq_z1_image_2016_09_07.img of=/dev/rdisk4

This may result in a dd: invalid number '1m' error if you have GNU coreutils
installed. In that case, you need to use a block size of 1M in the bs= section,
as follows:

   .. code-block:: console
      
      sudo dd bs=1M if=image.img of=/dev/rdisk<disk# from diskutil>

Wait for the card to be written. This may take some time. You can check the
progress by sending a SIGINFO signal (press Ctrl+T).

If this command still fails, try using disk instead of rdisk, for example:

   .. code-block:: console
      
      sudo dd bs=1m if=pynq_z1_image_2016_09_07.img of=/dev/disk4


Linux
-----

dd
^^

Please note the dd tool can overwrite any partition on your machine. Please be
careful when specifying the drive in the instructions below. If you select the
wrong drive, you could lose data from, or delete your primary Linux partition.

* Run `df -h` to see what devices are currently mounted.

* Insert the Micro SD card into your SD card reader 

* Run df -h again. 

The new device that has appeared is your Micro SD card. The left column gives
the device name; it will be listed as something like /dev/mmcblk0p1 or
/dev/sdd1. The last part (p1 or 1 respectively) is the partition number but you
want to write to the whole SD card, not just one partition. You need to remove
that part from the name. e.g. Use /dev/mmcblk0 or /dev/sdd as the device name
for the whole SD card.

Now that you've noted what the device name is, you need to unmount it so that
files can't be read or written to the SD card while you are copying over the SD
image.

* Run `umount /dev/sdd1`, replacing sdd1 with whatever your SD card's device
  name is (including the partition number).

If your SD card shows up more than once in the output of df due to having multiple partitions on the SD card, you should unmount all of these partitions.

* In the terminal, write the image to the card with the command below, making
  sure you replace the input file if= argument with the path to your .img file,
  and the /dev/sdd in the output file of= argument with the right device
  name. This is very important, as you will lose all data on the hard drive if
  you provide the wrong device name. Make sure the device name is the name of
  the whole Micro SD card as described above, not just a partition of it; for
  example, sdd, not sdds1, and mmcblk0, not mmcblk0p1.

`sudo dd bs=4M if=pynq_z1_image_2016_09_07.img of=/dev/sdd`

Please note that block size set to 4M will work most of the time; if not, please
try 1M, although this will take considerably longer.

The dd command does not give any information of its progress and so may appear
to have frozen; it could take a few minutes to finish writing to the card.

Instead of dd you can use `dcfldd`; it will give a progress report about how
much has been written.

.. _assign-your-computer-a-static-ip:

Assign your computer a static IP address
========================================

Instructions may vary slightly depending on the version of operating system you
have. You can also search on google for instructions on how to change your
network settings.

You need to set the IP address of your laptop/pc to be in the same range as the
board. e.g. if the board is 192.168.2.99, the laptop/PC can be 192.168.2.x where
x is 0-255 (excluding 99, as this is already taken by the board).

You should record your original settings, in case you need to revert to them
when finished using PYNQ.

Windows
-------

* Go to Control Panel -> Network and Internet -> Network Connections
* Find your Ethernet network interface, usually `Local Area Connection`
* Double click on the network interface to open it, and click on *Properties*
* Select Internet Protocol Version 4 (TCP/IPv4) and click *Properties*
* Select *Use the following IP address*
* Set the Ip address to 192.168.2.1 (or any other address in the same range as
  the board)
* Set the subnet mask to 255.255.255.0 and click **OK**

Mac OS
------

* Open *System Preferences* then open *Network*
* Click on the connection you want to set manually, usually `Ethernet`
* From the Configure IPv4 drop down choose Manually
* Set the IP address to 192.168.2.1 (or any other address in the same range as
  the board)
* Set the subnet mask to 255.255.255.0 and click **OK**

The other settings can be left blank.

Linux
-----

* Edit this file (replace gedit with your preferred text editor):

   sudo gedit /etc/network/interfaces

The file usually looks like this:

   .. code-block:: console
   

      auto lo eth0
      iface lo inet loopback
      iface eth0 inet dynamic


* Make the following change to set the eth0 interface to the static IP address
  192.168.2.1

   .. code-block:: console
   
      iface eth0 inet static
         address 192.168.2.1
         netmask 255.255.255.0
   
Your file should look like this:

   .. code-block:: console
   

      auto lo eth0
      iface lo inet loopback
      iface eth0 inet static
	      address 192.168.2.1
	      netmask 255.255.255.0
   
