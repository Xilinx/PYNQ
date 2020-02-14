Network connection
==================

Once your board is setup, you need to connect to it to start using Jupyter notebook.

Ethernet
--------

If available, you should connect your board to a network or router with Internet
access. This will allow you to update your board and easily install new packages.

Connect to a Computer
^^^^^^^^^^^^^^^^^^^^^

You will need to have an Ethernet port available on your computer, and you will
need to have permissions to configure your network interface. With a direct
connection, you will be able to use PYNQ, but unless you can bridge the Ethernet
connection to the board to an Internet connection on your computer, your board
will not have Internet access. You will be unable to update or load new packages
without Internet access.

Connect directly to a computer (Static IP):

  1. :ref:`assign-your-computer-a-static-IP`
  2. Connect the board to your computer's Ethernet port
  3. Browse to http://192.168.2.99
  
Connect to a Network Router
^^^^^^^^^^^^^^^^^^^^^^^^^^^

If you connect to a router, or a network with a DHCP server, your board will
automatically get an IP address. You must make sure you have permission to
connect a device to your network, otherwise the board may not connect properly.

Connect to a Router/Network (DHCP):

  1. Connect the Ethernet port on your board to a router/switch
  2. Connect your computer to Ethernet or WiFi on the router/switch
  3. Browse to http://<board IP address>
  4. Optional: see *Change the Hostname* below
  5. Optional: see *Configure Proxy Settings* below
