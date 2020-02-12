PYNQ Utils Module
=================

The PYNQ utils module includes helper functions for installing and testing
packages that use PYNQ.

Downloading Overlays with Setuptools
------------------------------------

To avoid needing to put large bitstreams in source code repositories or on PyPI
PYNQ supports the use of *link files*. A link file is a file with the extension
``.link`` and contains a JSON dictionary of shell or board name to URL where
the overlay can be downloaded.

.. code-block :: javascript

    {
        "xilinx_u200_xdma_201830_2": "https://link.to/u200.xclbin",
        "xilinx_u250_xdma_201830_2": "https://link.to/u250.xclbin"
    }

PYNQ provides a ``download_overlays`` setuptools command which will process any
link files in your repository and download the overlays for your board and
place them alongside the link files. To run the the download command
automatically at build time you can replace the utils module provides a
``build_py`` command class that can be used in place of the normal ``build_py``
phase. For more details on how to include this command in your setup.py see the
:ref:`pynq-python-packaging` section for an example.

To download the overlays from your own setuptools pass the same functionality
is exposed through the ``download_overlays`` function. For more information see
the module documentation available at :ref:`pynq-utils`.

Installing Notebooks Programatically
------------------------------------

The utils packages contains the implementation behind the ``pynq
get-notebooks`` CLI command. Most commonly this should be called from the
command line but the functionality is also available through the
``deliver_notebooks`` function. In delivering the notebooks any link files in
the source directory will be evaluated if necessary. For the full details on
the function and its arguments again refer to the :ref:`pynq-utils`
documentation.

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
