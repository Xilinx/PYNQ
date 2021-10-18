.. _writing-the-sd-card:

************************
Writing an SD Card Image
************************

Windows
=======

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
==========

On Mac OS, you can use dd, or the graphical tool ImageWriter to write to your
Micro SD card.

* First open a terminal and unzip the image:

   .. code-block:: console

      unzip pynq_z1_image_2016_09_14.zip -d ./
      
ImageWriter
-----------

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
------------

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
=====

dd
--

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

`sudo dd bs=4M if=pynq_image.img of=/dev/sdd`

Please note that block size set to 4M will work most of the time; if not, please
try 1M, although this will take considerably longer.

The dd command does not give any information of its progress and so may appear
to have frozen; it could take a few minutes to finish writing to the card.

Instead of dd you can use `dcfldd`; it will give a progress report about how
much has been written.
