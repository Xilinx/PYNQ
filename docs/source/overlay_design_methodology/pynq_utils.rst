PYNQ Utils Module
=================

The PYNQ utils module includes helper functions for installing and testing
packages that use PYNQ.

Downloading Overlays with Setuptools
------------------------------------

To avoid needing to put large bitstreams in source code repositories or on PyPI
PYNQ supports the use of *link files*. A link file is a file with the extension
``.link`` and contains a JSON dictionary of shell or board name matched against
the URL where the overlay can be downloaded, and the MD5 checksum of the file

.. code-block :: javascript

    {
        "xilinx_u200_xdma_201830_2": { 
            "url": "https://link.to/u200.xclbin",
            "md5sum": "da1e100gh8e7becb810976e37875de38"
        }
        "xilinx_u250_xdma_201830_2": {
            "url": "https://link.to/u250.xclbin",
            "md5sum": "1df38cf582c4c5d0c8e3ca38be8f1eb3"
        }
    }

In case the resource to be downloaded is *global* the *url* and *md5sum*
entries should be at the top-level of the JSON dictionary. In this case, no 
device-based resolution will be performed.

.. code-block :: javascript

    {
        "url": "https://link.to/resource.extension",
        "md5sum": "1df38cf582c4c5d0c8e3ca38be8f1eb3"
    }

PYNQ provides a ``download_overlays`` setuptools command which will process any
link files in your repository and download overlays and resources for your
board and place them alongside the link files. To run the the download command
automatically at build time the utils module provides a ``build_py`` command 
class that can be used in place of the normal ``build_py`` phase. For more 
details on how to include this command in your setup.py see the
:ref:`pynq-python-packaging` section for an example. Refer also to the 
`official Python documentation <https://docs.python.org/3.6/distutils/extending.html>`_
and the `setuptools documentation <https://setuptools.readthedocs.io/en/latest/setuptools.html#extending-and-reusing-setuptools>`_ for more info on extending
and reusing setuptools.

To download the overlays from your own setuptools pass the same functionality
is exposed through the ``download_overlays`` function. For more information see
the module documentation available at :ref:`pynq-utils`.

Installing Notebooks Programmatically
--------------------------------------

The utils module contains the implementation behind the ``pynq get-notebooks`` 
CLI command. Most commonly this should be called from the command line but the 
functionality is also available through the ``deliver_notebooks`` function. In 
delivering the notebooks any link files in the source directory will be 
evaluated if necessary. For the full details on the function and its arguments 
again refer to the :ref:`pynq-utils` documentation.

Testing Notebooks
-----------------

We have exposed infrastructure for testings notebooks that can be used as part
of an automated test setup. The ``run_notebook`` function launches an instance
of Jupyter, executes all of the cells in the notebook and then returns an
object containing the results of the cells. The Python objects for each cell
can by retrieved using the ``_*`` notation - the same as the IPython
environment. Note that objects which can't be serialized are returned as a
string containing the result of the ``repr`` function.

Notebooks are run in isolated environments so that any files created do not
pollute the package. Prior to starting Jupyter the entirety of the
``notebook_path`` directory is copied to a temporary location with the notebook
executed from there. For this reason the notebook name should always be given
as a relative path to the ``notebook_path``.

If you wish to inspect the output of the cells directly - e.g. to ensure that
rich display for an object is working correctly - the result object as an
``outputs`` property which contains the raw output from each cell in the
notebook format.

The following is a simple example of using the ``run_notebook`` function as
part of a suite of pytests.

.. code-block :: python

    from pynq.utils import run_notebook
    from os import path

    NOTEBOOK_PATH = path.join(path.dirname(__file__), 'notebooks')

    def test_notebook_1():
        result = run_notebook('notebook_1.ipynb', NOTEBOOK_PATH)
        assert result._3 == True # Cell three checks array equality
        assert result._5 == 42
