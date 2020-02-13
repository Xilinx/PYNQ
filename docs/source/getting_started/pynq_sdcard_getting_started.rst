Connecting to Jupyter Notebook
------------------------------

Once your board is setup, to connect to Jupyter Notebooks open a web browser and navigate to:

  * http://192.168.2.99 If your board is connected to a computer via a static IP address


If your board is configured correctly you will be presented with a login
screen. The username is **xilinx** and the password is also **xilinx**.

After logging in, you will see the following screen:

.. image:: ../images/portal_homepage.jpg
    :height: 600px
    :scale: 75%
    :align: center

The default hostname is **pynq** and the default static IP address is
**192.168.2.99**. If you changed the static IP of the board, you
will need to change the address you browse to.

The first time you connect, it may take a few seconds for your computer to
resolve the hostname/IP address.

Example Notebooks
=================

PYNQ uses the Jupyter Notebook environment to provide examples and documentation.
Using your browser you can view and run the notebook documentation interactively.

The Getting_Started folder in the Jupyter home area includes some introductory 
Jupyter notebooks. 
 
.. image:: ../images/getting_started_notebooks.jpg
    :height: 600px
    :scale: 75%
    :align: center

The example notebooks have been divided into categories

  * common: examples that are not overlay specific

Depending on your board, and the PYNQ image you are using, other folders may be
available with examples related to Overlays. E.g. The *base* directory will 
have examples related to the base overlay. If you install any additional 
overlays, a folder with example notebooks will usually be copied here.

When you open a notebook and make any changes, or execute cells, the notebook
document will be modified. It is recommended that you "Save a copy" when you
open a new notebook. If you want to restore the original versions, you can
download all the example notebooks from `GitHub
<https://www.github.com/xilinx/pynq>`_.


Configuring PYNQ
----------------

Accessing Files on The Board
============================

`Samba <https://www.samba.org/>`_, a file sharing service, is running on the
board. This allows you to access the Pynq home area as a network drive, to
transfer files to and from the board.

.. note:: In the examples below change the hostname or IP address to match your
          board settings.

To access the Pynq home area in Windows Explorer type one of the following in
the navigation bar.

.. code-block:: console
    
   \\192.168.2.99\xilinx        # If connected to a Computer with a Static IP

When prompted, the username is **xilinx** and the password is **xilinx**. The
following screen should appear:

.. image:: ../images/samba_share.JPG
    :align: center

To access the home area in Ubuntu, open a file broswer, click Go -> Enter
Location and type one of the following in the box:

.. code-block:: console
    
  smb://192.168.2.99/xilinx        # If connected to a Computer with a Static IP

When prompted, the username is **xilinx** and the password is **xilinx**  


Change the Hostname
===================

If you are on a network where other PYNQ boards may be connected, you should
change your hostname immediately. This is a common requirement in a work or
university environment. You can change the hostname from a terminal. You can use
the USB cable to connect a terminal. A terminal is also available in the Jupyter
environment and can be used from an internet browser.

To access the Jupyter terminal, in the Jupyter portal home area, select **New >>
Terminal**.

.. image:: ../images/dashboard_files_tab_new.JPG
    :height: 300px
    :align: center
       
This will open a terminal inside the browser as root.

Use the preloaded pynq_hostname.sh script to change your board's hostname.

.. code-block:: console
    
    pynq_hostname.sh <NEW HOSTNAME>

The board must be restarted for the changes to be applied.

.. code-block:: console
    
    shutdown -r now

Note that as you are logged in as root, sudo is not required. If you connect a
terminal from the USB connection, you will be logged in as the *xilinx* user and
sudo must be added to these commands.

When the board reboots, reconnect using the new hostname. 

If you can't connect to your board, see the step below to open a terminal using
the micro USB cable.


Configure Proxy Settings
========================

If your board is connected to a network that uses a proxy, you need to set the
proxy variables on the board. Open a terminal as above and enter the following
where you should replace "my_http_proxy:8080" and "my_https_proxy:8080" with
your settings.

.. code-block:: console
    
    set http_proxy=my_http_proxy:8080
    set https_proxy=my_https_proxy:8080

Troubleshooting
---------------

.. include:: terminal.rst

If you are having problems, please see the Troubleshooting section in
:ref:`faqs` or go the `PYNQ support forum <https://discuss.pynq.io>`_
