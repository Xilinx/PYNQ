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

* `Packaging Python Projects
  <https://packaging.python.org/tutorials/packaging-projects/>`_


Delivering Non-Python Files
---------------------------

One extremely useful feature that pip provides is the ability to deliver
non-python files. In the PYNQ project this is useful for delivering FPGA
binaries (.bit), overlay metadata files (.hwh), PYNQ MicroBlaze binaries
(.bin), and Jupyter Notebooks (.ipynb), along side the pynq Python libraries.

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

Starting from image v2.5, the official PYNQ Github repository will not 
version-control the following files anymore:

* overlay files (e.g., `base.bit`, `base.hwh`), 

* bsp folders(e.g., `bsp_iop_pmod`)

* MicroBlaze binaries (e.g., `pmod_adc.bin`)

We refrain from keeping tracking of these large files; instead, we rely on the 
SD build flow to update them automatically in each build. Some side-effects
are shown below:

* Users should expect longer SD image building time when users are 
  building the image for the first time. Subsequent builds are much faster. 

* Users will no longer be able to pip install directly from the official 
  PYNQ Github repository.

To get those files manually, users can simply run the `build.sh` located 
at the root of the PYNQ repository (make sure you have the correct version of
Xilinx tools beforehand).

Once you have all the files, including the files mentioned above, you can
package the entire Github repository into a source distribution package.
To do that, run

.. code-block :: console

   python3 setup.py sdist

After this, you will find a tarball in the folder `dist`; for example,
`pynq-<release.version>.tar.gz`. This is a source distribution so you can
bring it to other boards and install it. From a terminal on a board, 
installing the pynq Python library is as simple as running:

.. code-block :: console

   export BOARD=<Board>
   export PYNQ_JUPYTER_NOTEBOOKS=<Jupyter-Notebook-Location> 
   pip3 install pynq-<release.version>.tar.gz

After pip finishes installation, the board must be rebooted. If you are on
a board with a PYNQ image (OS: pynqlinux), you are done at this point. 
If you are not on a PYNQ image (other OS), the above `pip3 install`
is only for the pynq Python library installation; you also need
2 additional services to be started for pynq to be fully-functional.

* PL server service. (Check 
  <PYNQ-repo>/sdbuild/packages/pynq for more information).

* Jupyter notebook service. (Check 
  <PYNQ-repo>/sdbuild/packages/jupyter/start_jupyter.sh as an example).

Using ``pynq`` as a Dependency
------------------------------

One of the most useful features of pip is the ability to *depend* on a project,
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


