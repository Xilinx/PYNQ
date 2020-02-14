.. _pynq-cli:

PYNQ Command Line Interface
===========================

PYNQ provides a *Command Line Interface (CLI)* that is used to offer some basic 
functionalities directly within a shell. 

Usage
-----

The way it works is pretty simple: when you are in a shell session, you can type

.. code:: bash
    
    pynq subcommand

to execute whatever the selected *subcommand* is designed
to do. 

By itself, the ``pynq`` root command is just a dispatcher: under the hood, 
when you type ``pynq subcommand`` it looks for an available executable named 
``pynq-subcommand`` and runs it. 

Therefore, to add new functionalities to the PYNQ CLI, it is sufficient to make 
a new executable available that follow this naming structure. For example, to 
manage instances of a device server, the ``pynq-server`` executable is created,
and it will be called by typing ``pynq server`` in the command line.

Printing the Help Message
-------------------------

You can get the associated *help* message by typing

.. code:: bash
    
    pynq --help

This will print the help message with the available options, as well a list of
the available subcommands.

Printing the Version
--------------------

To get the installed PYNQ version, you can type

.. code:: bash
    
    pynq --version

This will also print out the hash of the commit ID from the 
`PYNQ GitHub <https://github.com/Xilinx/PYNQ>`_ repository, that might be 
useful for diagnosing issues and bug reporting.

Available subcommands
---------------------

Device Server Management
^^^^^^^^^^^^^^^^^^^^^^^^
The ``pynq server`` command is used to manage instances of device servers. You 
can either ``start`` or ``stop`` the server by typing the intended command as 
follows

.. code:: bash
    
    pynq server start

And you can also get a help message by typing 

.. code:: bash
    
    pynq server --help

.. note:: As of now, we recommend not to use the ``pynq server`` subcommand on 
    Zynq and Zynq Ultrascale+ devices, as the device server in these cases is 
    already managed by a system service provided in the PYNQ SD card image.

Get the Available Notebooks
^^^^^^^^^^^^^^^^^^^^^^^^^^^
The ``pynq get-notebooks`` command is responsible for the delivery of notebooks.

.. code:: bash
    
    pynq get-notebooks

This command will create a ``pynq-notebooks`` folder in your current working 
directory that will include notebooks and, possibly, associated overlays. 
The command will scan the environment for available notebooks coming from  
packages that have registered for discovery. You can read more about this 
mechanism in the :ref:`pynq-python-packaging` section.

You may want to provide a specific path where to deliver the notebooks instead. 
You can achieve this by passing the ``--path`` option

.. code:: bash
    
    pynq get-notebooks --path <your-path>

By default, typing ``get-notebooks`` without any option will deliver all the 
available notebooks and prompt the user for confirmation, listing what notebooks 
are detected and will be delivered. You can override this behavior by passing 
the special keyword ``all`` to the command. This will deliver all the notebooks 
directly, without asking for confirmation

.. code:: bash
    
    pynq get-notebooks all

You can also chose to get only a number of selected notebooks by typing the name 
of the notebooks you want

.. code:: bash
    
    pynq get-notebooks nb1 [nb2 ...]

You can get a list of the available notebooks by using the ``--list`` option

.. code:: bash
    
    pynq get-notebooks --list

When running ``pynq get-notebooks`` overlays are potentially downloaded 
automatically from the network based on the target device. Therefore, there is 
the possibility that some overlays will not be available for your device, and 
you will have to synthesize the manually from source. In case the overlays 
associated with certain notebooks are not found for your device, these notebooks 
will not be delivered. If, however, you want to get the notebooks anyway,  
ignoring the automatic overlays lookup, you can pass the ``--ignore-overlays`` 
option. 

.. code:: bash
    
    pynq get-notebooks --ignore-overlays

Moreover, you can manually specify a target device by passing the ``--device`` 
option

.. code:: bash
    
    pynq get-notebooks --device DEVICE

Or be presented with a list of detected devices to chose from using the 
``--interactive`` option instead.

.. code:: bash
    
    pynq get-notebooks --interactive

The default behavior in case neither of these two options is passed, is to use 
the default device (i.e. ``pynq.Device.active_device``) for overlays lookup.

After the command has finished, 
you can run the notebooks examples by typing:

.. code:: bash
    
    cd pynq-notebooks
    jupyter notebook


The ``get-notebooks`` command has a number of additional options that can
be listed by printing the help message:

.. code:: bash

    pynq examples --help

Please refer to the help message for more info about these options.
