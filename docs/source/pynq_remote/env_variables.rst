.. _env_variables:

Setting Environment Variables
==============================

PYNQ.remote uses the ``PYNQ_REMOTE_DEVICES`` environment variable to identify and configure remote devices. Windows, Linux, and macOS all use different methods to set environment variables. This document aims to provide a brief overview of how to set this variable across different platforms. For more details, refer to the documentation for your specific operating system.

Setting an Environment Variable in Python
=========================================

You can set environment variables in Python using the ``os`` module. This is useful if you want to set the variable programmatically before importing the ``pynq`` package. This is the preferred method, as it works across all operating systems and does not require any additional setup in your shell.

.. code-block:: python

    import os
    os.environ['PYNQ_REMOTE_DEVICES'] = "192.168.2.99"

Setting an Environment Variable in Linux and macOS
==================================================

In Linux and macOS shells, you can set environment variables using the `export` command. Make sure there are no spaces around the `=` sign.

.. code-block:: bash

    export PYNQ_REMOTE_DEVICES="192.168.2.99"

The code above sets the environment variable for the current shell session. If you use a new terminal or restart your computer you will need to set it again. 

This can be made easier in one of two ways. First, you can add the command to a shell file local to your working directory, such as `.env`. Each time you start a new terminal session, you can ``source`` this file to set the environment variable:

.. code-block:: bash

    source .env

Alternatively, you can add the command to your shell's configuration file (e.g., `.bashrc`, `.bash_profile`, `.zshrc`), which will set the variable automatically each time you open a new terminal session:

To check if the variable is set, you can use the `echo` command:

.. code-block:: bash

    echo $PYNQ_REMOTE_DEVICES


Setting an Environment Variable in Windows
==========================================

In Windows, there are several ways to set environment variables, depending on which shell you are using. For Command Prompt (cmd.exe), you can use the `set` command:

.. code-block:: powershell

    set PYNQ_REMOTE_DEVICES=192.168.2.99

For Powershell, you can use the ``$env:`` syntax:

.. code-block:: powershell

    $env:PYNQ_REMOTE_DEVICES="192.168.2.99"

Setting an Environment Variable in a Python Virtual Environment
===============================================================

If you are using a Python virtual environment, you can set the environment variable in the `activate` script of your virtual environment. This way, the variable will be set automatically each time you activate the virtual environment.

For example, if you are using a virtual environment named `venv`, you can add the code above in the following directories:

* For Linux/macOS: Add the code above to the `venv/bin/activate` 
* For Windows: If using Command Prompt, add the code to `venv/Scripts/activate.bat`
* For Windows: If using PowerShell, add the following line to `venv/Scripts/Activate.ps1`