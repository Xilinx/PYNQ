Connect to Jupyter  
===============================

* Open a web browser and go to `http://pynq:9090 <http://pynq:9090>`_ (network) `http://192.168.2.99:9090 <http://192.168.2.99:9090>`_ (direct connection)
* The username is **xilinx** and the password is also **xilinx**
   
   .. image:: ../images/portal_homepage.jpg
      :height: 600px
      :scale: 75%
      :align: center


The default hostname is **pynq** and the default static IP address is ``192.168.2.99``. If you changed the hostname or static IP of the board, you will need to change the address you browse to. 
   
The first time you connect, it may take a few seconds for your computer to resolve the hostname/IP address. 

Using PYNQ
==========================

   
Example notebooks
----------------------------

A Jupyter notebook can be saved as html webpages. Some of this documentation has been generated directly from Jupyter notebooks. 

You can view the documentation as a webpage, or if you have a board running PYNQ, you can view and run the notebook documentation interactively. The documentation available as notebooks can be found in the *Getting_Started* folder in the Jupyter home area. 
 
.. image:: ../images/getting_started_notebooks.jpg
   :height: 600px
   :scale: 75%
   :align: center
   

There are also a number of example notebooks available showing how to use various peripherals with the board. 

.. image:: ../images/example_notebooks.jpg
   :height: 600px
   :scale: 75%
   :align: center

The example notebooks have been divided into categories

* base: related to the base overlay for the current board
* common: examples that are not board specific
* logictools: related to the logictools overlay
   
When you open a notebook and make any changes, or execute cells, the notebook document will be modified. It is recommended that you "Save a copy" when you open a new notebook. If you want to restore the original versions, you can download all the example notebooks from the `PYNQ GitHub page <https://www.github.com/xilinx/pynq>`_ .    
   
Accessing files on the board
----------------------------
`Samba <https://www.samba.org/>`_, a file sharing service, is running on the board. The home area on the board can be accessed as a network drive, and you can transfer files to and from the board. 

In Windows, to access the PYNQ home area you can go to:

``\\pynq\xilinx`` 

or 

``\\192.168.2.99\xilinx``  

Or in Linux: 

``smb://pynq/xilinx`` 

or 

``smb://192.168.2.99/xilinx``

Remember to change the hostname/IP address if necessary.

The Samba username:password is ``xilinx:xilinx``

.. image:: ../images/samba_share.JPG
   :height: 600px
   :scale: 75%
   :align: center
   
   
Change hostname
----------------------

If you are on a network where other pynq boards may be connected, you should change your hostname immediately. This is a common requirement in a work or university environment. You can change the hostname from a terminal. You can use the USB cable to connect a terminal A terminal is also available in the Jupyter environment and can be used from an internet browser. 

To access the Jupyter terminal, in the Jupyter portal home area, select **New >> terminal**.

   .. image:: ../images/dashboard_files_tab_new.JPG
      :height: 300px
      :align: center
       
This will open a terminal inside the browser as root. 

Edit the existing entry in the Linux hostname file to change the hostname of the board. The ``vi`` editor can be used to edit this file:

.. code-block:: console

   vi /etc/hostname

Type *i* to enter edit (insert) mode, change the hostname, and type *:wq* to save and exit. The board must be restarted for the changes to be applied. 

.. code-block:: console

      shutdown -r now

Note that as you are logged in as root, sudo is not required. If you connect a terminal from the USB connection, you will be logged in as the *xilinx* user and sudo must be added to these commands. 

When the board reboots, reconnect using the new hostname. 

If you can't connect to your board, see the step below to open a terminal using the micro USB cable. 


Connect to the PYNQ-Z1 board with a terminal connection over USB
----------------------------------------------------------------

If you can't access the terminal from Jupyter, you can connect the micro-USB cable from your computer to the board and open a terminal. You can use the terminal to check the network connection of the board. You will need to have terminal emulator software installed on your computer. `PuTTY <http://www.putty.org/>`_ is one application that can be used, and is available for free on Windows. To open a terminal, you will need to know the COM port for the board. 

On Windows, you can find this in the Windows *Device Manager* in the control panel. 

   * Open the Device Manager, expand *Ports*
   * Find the COM port for the *USB Serial Port*.  e.g. COM5

Once you have the COM port, open PuTTY and use the following settings:

   * Select serial
   * Enter the COM port number
   * Enter the baud rate 
   * Click *Open*

Hit *Enter* in the terminal window to make sure you can see the command prompt:

.. code-block:: console

   xilinnx@pynq:/home/xilinx#


Full terminal Settings:

   * 115200 baud
   * 8 data bits
   * 1 stop bit
   * No Parity
   * No Flow Control

You can then run the same commands listed above to change the hostname, or configure a proxy. 

You can also check the hostname of the board by running the *hostname* command:

   .. code-block:: console
   
      hostname

You can also check the IP address of the board using *ifconfig*:

.. code-block:: console

   ifconfig

Configure proxy
--------------------

If your board is connected to a network that uses a proxy, you need to set the proxy variables on the board. Open a terminal as above and enter the following where you should replace "my_http_proxy:8080" and "my_https_proxy:8080" with your settings.  

   .. code-block:: console
   
      set http_proxy=my_http_proxy:8080
      set https_proxy=my_https_proxy:8080


      



Troubleshooting
==========================

If you are having problems, please see the `Frequently asked questions <../faqs.html>`_ or go the `PYNQ support forum <http://www.pynq.io/support.html>`_
