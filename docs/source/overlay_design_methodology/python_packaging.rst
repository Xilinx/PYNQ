Python Packaging
================

PYNQ uses pip - the Python Packaging Authority's recommended Python Package
Installer to install and deliver custom installations of PYNQ. pip's flexible
package delivery model has many useful features.

Packaging ``pynq`` for Distribution
-----------------------------------

Packaging the pynq Python project that pip can use is hugely beneficial, but
requires carful thought and project architecture. There are many useful
references that provide up-to-date information. For more information about how
the pynq library is packaged see the following links:

* `Open Sourcing a Python Project The Right
  way <https://jeffknupp.com/blog/2013/08/16/open-sourcing-a-python-project-the-right-way>`_

* `How to Package Your Python Code
  <https://python-packaging.readthedocs.io/en/latest/index.html>`_

Delivering Non-Python Files
---------------------------

One extremely useful feature that pip provides is the ability to deliver
non-python files. In the PYNQ project this is useful for delivering FPGA
binaries (.bit), overlay TCL source files (.tcl), PYNQ MicroBlaze binaries
(.bin), and Jupyter Notebooks (.ipynb), along side the pynq Python libaries.

From a Terminal on the PYNQ board, installing the pynq Python libraries is
as simple as running:

.. code-block :: console

   sudo pip3.6 install --upgrade git+https://github.com/Xilinx/PYNQ.git

After pip finishes installation, the board must be rebooted.

An example of using pip's **setup.py** file to provide non-python content is
shown below:

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
      install_requires=[
          'pynq',
      ],
      dependency_links=['http://github.com/xilinx/PYNQ'],
      description = "New custom overlay for PYNQ-Z1"
   )

The ``package_data`` argument specifies which files will be installed as part of
the package.

Using ``pynq`` as a Dependency
------------------------------

One of the most useful features of pip is the abililty to *depend* on a project,
instead of forking or modifying it.

When designing overlays, the best practice for re-using pynq code is to
create a Python project as described above and add pynq as a dependency. A
good example of this is the `BNN-PYNQ project
<https://github.com/Xilinx/BNN-PYNQ>`_.

The BNN-PYNQ project is an Overlay that *depends* on pynq but does not
modify it. The developers list pynq as a dependency in the pip configuration
files, which installs pynq (if it isn't already). After installation, the
BNN-PYNQ files are added to the installation: notebooks, overlays, and drivers
are installed alongside pynq without modifying or breaking the previous
source code.

Needless to say, we highly recommend *depending* on pynq instead of *forking
and modifying* pynq. An example of depending on pynq is shown in the code
segment from the previous section.


