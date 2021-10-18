.. _assign-a-static-ip-address:

**************************
Assign a static IP address
**************************


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
   
