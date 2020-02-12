.. _pynq-python-packaging:

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
The most straightforward way of including non-python files is to add a
`MANIFEST.in`_ to the project.

In addition PYNQ provides two mechanisms that can be used aid deployments of
notebooks and large bitstreams - in particular xclbin files which can exceed
100 MBs each.

Registering PYNQ Notebooks
--------------------------

If you have notebooks in your package you can register your notebooks with the
``pynq get-notebooks`` command line tool by creating a ``pynq.notebooks`` entry
point linking to the part of your package. The key part of the entry point
determines the name of the folder that will be created in the notebooks folder
and all of the files in the corresponding package will be copied into it. Any
``.link`` files described below will also be resolved for the currently active
device.

Link File Processing
--------------------

In place of xclbin files for Alveo cards your repository can instead contain
xclbin.link files which provide locations where xclbin files can be downloaded
for particular shells. For more details on the link format see the pynq.util
documentation. xclbin.link files alongside notebooks will be resolved when the
``pynq get-notebooks`` command is run. If you would prefer to have the xclbin
files downloaded at package install time we provide a ``download_overlays``
setuptools command that you can call as part of your installation or the
``pynq.utils.build_py`` command which can be used in-place of the regular
``build_py`` command to perform the downloading automatically.

By default the ``download_overlays`` command will only download xclbin files
for the boards installed installed in the machine. This can be overridden with
the ``--download-all`` option.

Example Setup Script
--------------------

An example of using pip's **setup.py** file which delivers xclbin files and
notebooks using the PYNQ mechanisms is show below.

.. code-block :: python

   from setuptools import setup, find_packages
   from pynq.utils import build_py
   import new_overlay

   setup(
      name = "new_overlay",
      version = new_overlay.__version__,
      url = 'https://github.com/your_github/new_overlay',
      license = 'All rights reserved.',
      author = "Your Name",
      author_email = "your@email.com",
      packages = find_packages(),
      inlcude_package_data=True,
      install_requires=[
          'pynq'
      ],
      setup_requires=[
          'pynq'
      ],
      entry_points={
          'pynq.notebooks': [
              'new-overlay = new_overlay.notebooks'
          ]
      },
      cmdclass={'build_py': build_py},
      description = "New custom overlay"
   )

A corresponding **MANIFEST.in** to add the notebooks and bitstreams files would
look like

.. code-block :: python

   recursive-include new_overlay/notebooks *
   recursive-include new_overlay *.bit *.hwh *.tcl

If you want to have users be able to install your package without first
installing PYNQ you will also need to create a *pyproject.toml* file as
specified in `PEP 518`_. This is used to specify that PYNQ needs to be
installed prior to the setup script running so that ``pynq.utils.build_py`` is
available for importing. The ``setuptools`` and ``wheel`` are required by
the build system so we'll add those to the list as well.

.. code-block :: toml

    [build-system]
    requires = ["setuptools", "wheel", "pynq>=2.5.1"]

Rebuilding PYNQ
---------------

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

.. _Manifest.in: https://packaging.python.org/guides/using-manifest-in/
.. _PEP 518: https://www.python.org/dev/peps/pep-0518/
