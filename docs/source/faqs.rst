.. _faqs:

*********************************
Frequently Asked Questions (FAQs)
*********************************

Troubleshooting
===============

I can't connect to my board
---------------------------
  
1. Check the board is powered on and that the bitstream has been
   loaded (Most boards have a "DONE" LED to indicate this)

2. Your board and PC/laptop must be on the same network, or have a direct
   network connection. Check that you can *ping* the board (hostname, or IP
   address) from a command prompt or terminal on your host PC:
   
   .. code-block:: console
   
      ping pynq

   or 

   .. code-block:: console
   
      ping 192.168.2.99
      
      
   (The default IP address of the board is : 192.168.2.99)
   
3. Log on to the board through a terminal, and check the system is
   running, i.e. that the Linux shell is accessible. See below for details on
   logging on with a terminal.

4. If you can't ping the board, or the host PC, check your network settings.
         
   * You must ensure your PC/laptop and board have IP addresses in the same range. 
     If your network cables are connected directly to your PC/laptop and board, 
     you may need to set a static IP address for your PC/laptop manually. See
     :ref:`assign-your-computer-a-static-ip`.
         
   * If you have a proxy setup, you may need to add a rule to bypass the board
     hostname/ip address.
      
   * If you are using a docking station, when your laptop is docked, the
     Ethernet port on the PC may be disabled.
   
My Pynq-Z1/Z2 board is not powering on (No Red LED)
---------------------------------------------------

The board can be powered by USB cable, or power adapter (7 - 15V V 2.1mm
centre-positive barrel jack). Make sure Jumper JP5 is set to USB or REG (for
power adapter). If powering the board via USB, make sure the USB port is fully
powered. Laptops in low power mode may reduce the available power to a USB port.

The bitstream is not loading (No Green LED)
-------------------------------------------

* Check the Micro-SD card is inserted correctly (the socket is spring loaded, so
  push it in until you feel it click into place).
* Check jumper JP4 is set to SD (board boots from Micro SD card).
* Connect a terminal and verify that the Linux boot starts.

If the Linux boot does not start, or fails, you may need to (re)flash the PYNQ
image to the Micro SD card.

The hostname of the board is not resolving/not found
----------------------------------------------------

It may take the hostname (pynq) some time to resolve on your network. If you
know the IP address of the board, it may be faster to use the IP address to
navigate to the Jupyter portal instead of the hostname.

For example, in your browser, go to http://192.168.2.99:9090 if the board is
using the static IP address 192.168.2.99.

You can find the IP by first connecting a terminal to the board, then running 
the following command in Linux command line:

   .. code-block:: console
   
      ifconfig

Check the settings for *eth0* and look for an IP address.

I don't have an Ethernet port on my PC/Laptop
---------------------------------------------

If you don't have an Ethernet port, you can get a USB to Ethernet adapter.

If you have a wireless router with Ethernet ports (LAN), you can connect your
board to an Ethernet port on your router, and connect to it from your PC
using WiFi. (You may need to change settings on your Router to enable the
Wireless network to communicate with your LAN - check your equipment
documentation for details.)
   
You can also connect a WiFi dongle to the board, and set up the board to connect
to the wireless network. Your host PC can then connect to the same wireless
network to connect to the board.

How can I enable wireless access point?
---------------------------------------

If the board has a supported built-in wireless module, and the PYNQ image has the 
*wpa_ap* package installed, you can try start the WiFi access point as follows.
Note that *wpa_ap.service* is disabled by default.

To check if the WiFi access point service is available:

   .. code-block:: console

      systemctl list-unit-files | grep wpa_ap.service

To start the service immediately:

   .. code-block:: console

      sudo systemctl start wpa_ap.service

To enable the service for each boot:

   .. code-block:: console

      sudo systemctl enable wpa_ap.service

Similarly, you can use *stop* or *disable* to revert the above commands.

How do I setup my computer to connect to the board?
---------------------------------------------------

If you are connecting your board to your network (i.e. you have plugged the
Ethernet cable into the board, and the other end into a network switch, or home
router), then you should not need to setup anything on your computer. Usually,
both your computer, and board will be assigned an IP address automatically, and
they will be able to communicate with each other.

If you connect your board directly to your computer with an Ethernet cable, then
you need to make sure that they have IP addresses in the same range. The board
will assign itself a static IP address (by default 192.168.2.99), and you will
need to assign a static IP address in the same range to the computer.  This
allows your computer and board to communicate to each other over the Ethernet
cable.

See :ref:`assign-your-computer-a-static-ip`.

I can't connect to the Jupyter portal!
--------------------------------------

If your board is powered on, and you see the Red and Green LEDs, but still 
can't connect to the Jupyter Portal, or see the Samba shared drive, 
then you need to verify your IP addresses.

By default, the board has DHCP enabled. If you plug the board into a home
router, or network switch connected to your network, it should be allocated an
IP address automatically. If not, it should fall back to a static IP address of
`192.168.2.99`.

If you plug the Ethernet cable directly to your computer, you will need to
configure your network card to have an IP in the same address
range, e.g. `192.168.2.1`.

VPN
^^^

If your PC/laptop is connected to a VPN, and your board is not on the same VPN
network, this will block access to local IP addresses. You need to disable the
VPN, or set it to bypass the board address.

Proxy
^^^^^

If your board is connected to a network that uses a proxy, you need to set the
proxy variables on the board

   .. code-block:: console
   
      set http_proxy=my_http_proxy:8080
      set https_proxy=my_https_proxy:8080

Board/Jupyter settings
======================

How do I modify the board settings?
-----------------------------------

Linux is installed on the board. Connect to the board using a terminal, and
change the settings as you would for any other Linux machine.
   
How do I find the IP address of the board?
------------------------------------------

Connect to the board using a terminal (see above) and type:

   .. code-block:: console
   
      hostname -I

This will help you find the IP address for the eth0 Ethernet adapter or 
the WiFi dongle.
   
How do I set/change the static IP address on the board?
-------------------------------------------------------

You can usually modify ``/etc/network/interfaces.d/eth0``.
For example, on Pynq-Z1/Z2, the default address shown there is

   .. code-block:: console

      address 192.168.2.99

How do I find my hostname?
--------------------------

Connect to the board using a terminal and run:

   .. code-block:: console
   
      hostname
   
How do I change the hostname?
-----------------------------

If you have multiple boards on the same network, you should give them different
host names.  You can change the hostname by using a script on PYNQ image:

   .. code-block:: console

      sudo pynq_hostname.sh <your_new_board_name>

What is the user account and password?
--------------------------------------

The username for all Linux, Jupyter and Samba logins is ``xilinx``. 
The password is ``xilinx``. For vagrant Ubuntu VM, both the username and 
password are ``vagrant``.

How do I enable/disable the Jupyter notebook password?
------------------------------------------------------

The Jupyter configuration file can be found at 

   .. code-block:: console
   
      /root/.jupyter/jupyter_notebook_config.py

You can add or comment out the c.NotebookApp.password to bypass the password
authentication when connecting to the Jupyter Portal.

   .. code-block:: console

      c.NotebookApp.password =u'sha1:6c2164fc2b22:ed55ecf07fc0f985ab46561483c0e888e8964ae6'


How do I change the Jupyter notebook password
---------------------------------------------

A hashed password is saved in the Jupyter Notebook configuration file.

   .. code-block:: console

      /root/.jupyter/jupyter_notebook_config.py

You can create a hashed password using the function ``IPython.lib.passwd()``:

   .. code-block:: python
   
      from IPython.lib import passwd
      password = passwd("secret")
      6c2164fc2b22:ed55ecf07fc0f985ab46561483c0e888e8964ae6


You can then add or modify the line in the `jupyter_notebook_config.py` file

   .. code-block:: console

      c.NotebookApp.password =u'sha1:6c2164fc2b22:ed55ecf07fc0f985ab46561483c0e888e8964ae6'
     

General Questions
=================

Does PYNQ support Python 2.7?
-----------------------------

The PYNQ image is based on Ubuntu which includes Python 2.7 in the root file 
system. The Python package *pynq*, however, is based on Python 3.6; 
this python package is not compatible with Python 2.7.

Where can I find the overlay bitstreams?
----------------------------------------
In order to keep a reasonable Github repository size, starting from image v2.5,
we no longer store bitstreams in our Github repository. 
Instead, we provide a simple script allowing users to build the bitstreams 
by themselves. This script
(`build.sh`) is located at the root of the PYNQ repository. To run this
script, make sure you have Vivado and Vitis installed on your Ubuntu machine, 
and run:

   .. code-block:: console

      ./build.sh

If you are using our SD build flow, this step will be run automatically.

Where can I find the MicroBlaze bin files?
------------------------------------------
In order to keep a reasonable Github repository size, starting from image v2.5,
we no longer store compiled MicroBlaze binaries in our Github repository. 
Instead, we provide a simple script allowing users to build the binaries 
by themselves. This script
(`build.sh`) is located at the root of the PYNQ repository. To run this
script, make sure you have Vivado and Vitis installed on your Ubuntu machine,
and run:

   .. code-block:: console

      ./build.sh

If you are using our SD build flow, this step will be run automatically.

How do I write the Micro SD card image?
---------------------------------------

You can find instructions in :ref:`writing-the-sd-card`.

What type of Micro SD card do I need?
-------------------------------------

We recommend you use a card at least 8GB in size and at least class 4 speed
rating.


How do I connect to the board using a terminal on Windows?
----------------------------------------------------------

To do this, you need to connect to the board using a terminal:

Connect a Micro USB cable to the board and your computer, and use a terminal
emulator (puTTY, TeraTerm etc) to connect to the board.
   
   Terminal Settings: 
   
   * 115200 baud
   * 8 data bits
   * 1 stop bit
   * No Parity
   * No Flow Control
   
How do I connect to the board using a terminal on Mac OS/Linux?
---------------------------------------------------------------

Open a Terminal window on MacOS or an XTerm (or your favorite terminal program) on Linux.

Issue the following command to view current serial devices.

   .. code-block:: console

      ls /dev/cu.usb*

Connect a Micro USB cable to the board and your computer.

Issue the following command again to identify the device.

   .. code-block:: console

      ls /dev/cu.usb*

Identify the change of items in the list, and issue the following command:

   .. code-block:: console

      screen /dev/<device> 115200 -L

For example, if the difference was *cu.usbmodem0004*, the command would be:

   .. code-block:: console

      screen /dev/cu.usbmodem0004 115200 -L
