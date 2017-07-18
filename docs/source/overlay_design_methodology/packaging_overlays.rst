
Packaging overlays
====================

An overlay, tcl, and Python can be placed anywhere in the filesystem, but this is not good practice. 

The default location for the base PYNQ overlay and tcl is : 
   
   ``<GitHub Repository>/boards/<board name>/bitstream``

The PYNQ Python can be found here:

   ``<GitHub Repository>/python/pynq``

You can fork PYNQ from github, and add Python code to the PYNQ package. However, for custom overlays, you can create your own repository and package it to allow other users to install your overlay using pip.

There are different ways to package a project for installation with pip. One example is provided below. 

See pip install for more details, and more packaging options.
https://pip.pypa.io/en/stable/reference/pip_install

Example
--------

The following example assume an overlay that exists in the root of a GitHub repository.

Assume the repository has the following structure:
   
   * notebooks/
      * new_overlay.ipynb
   * new_overlay/
      * new_overlay.bit
      * new_overlay.tcl
      * __init.py
      * new_overlay.py
   * readme.md
   * license   
   
   
Add a setup.py to the root of your repository. This file will imports the necessary packages, and specifies some setup instructions for your package including the package name, version, url, and files to include. 

The setuptools package can be used to install your package. 

Example setup.py : 

.. code-block :: python

   from setuptools import setup, find_packages
   import subprocess
   import sys
   import shutil
   import new_overlay

   setup(
       name = "new_overlay",
       version = new_overlay.__version__,
       url = 'https://github.com/your_github/new_overlay',
       license = 'All rights reserved.',
       author = "Your Name",
       author_email = "your@email.com",
       packages = ['new_overlay'],
       package_data = {
       '' : ['*.bit','*.tcl','*.py','*.so'],
       },
       description = "New custom overlay for PYNQ-Z1"
   )

**package_data** specifies which files will be installed as part of the package.
   
   
From a terminal, the new package can be installed by running:

.. code-block :: console

   sudo pip install --upgrade 'git+https://github.com/your_github/new_overlay'
   
   
   

