.. _alveo-getting-started:

***************************
Alveo Getting Started Guide
***************************

Prerequisites
=============

  * A version of the `Xilinx Runtime <https://github.com/Xilinx/XRT>`_ (XRT) 
    above or equal ``2.3`` installed in the system. Previous versions of XRT 
    might still work, but are not explicitly supported. Moreover, the  
    functionalities offered by the Embedded Runtime Library (ERT) will not work 
    with versions of XRT below ``2.3``.
  * Any XRT-supported version of either RedHat/CentOS or Ubuntu as Operating 
    System
  * Python and PIP must be installed. The minimum Python version is ``3.5.2``, 
    although the recommended minimum version is ``3.6``

Install PYNQ
============

Simply install ``pynq`` through PIP

.. code-block:: bash
    
    pip install pynq

In case needed, please read the :ref:`alveo-extended-setup` section for more 
detailed instructions.

Get the Introductory Examples
=============================

Install the ``pynq-alveo-examples`` package using PIP

.. code-block:: bash
    
    pip install pynq-alveo-examples

Once that is done, run the ``get-notebooks`` command in your shell session

.. code-block:: bash
    
    pynq get-notebooks

This will deliver all the available notebooks in a ``pynq-notebooks`` folder in 
your current working directory.

You can now move to the newly created ``pynq-notebooks`` folder and run Jupyter 
there

.. code-block:: bash
    
    cd pynq-notebooks
    jupyter notebook

.. note:: When retrieving the notebooks using the ``pynq get-notebooks`` 
    command, overlays might be downloaded from the web and might be available 
    only for specific cards/shells. The ``get-notebooks`` command has a few 
    optional parameters that can be used to customize the notebooks delivery.
    Please run ``pynq get-notebooks -h`` to see them. Refer to the 
    :ref:`pynq-cli` section for more detailed information.

.. _alveo-extended-setup:

Extended Setup Instructions
===========================

Sourcing XRT
------------

The first thing you will have to do **before every session**, is source the XRT 
setup script. To do so, open up a bash shell and type:

.. code-block:: bash
    
    source /opt/xilinx/xrt/setup.sh

The path ``/opt/xilinx/xrt`` is the predefined install path for XRT and should 
not be changed. Therefore, the setup script will always be located there.

.. note:: In case you try to use PYNQ without sourcing XRT, you will get a 
    warning asking if XRT was correctly sourced. 


Install Conda
-------------

To get PYNQ, we recommend to install and use 
`Conda <https://docs.conda.io/en/latest/>`_. In particular, we recommend to 
install `Anaconda <https://www.anaconda.com/>`_ as it already includes most of 
the required packages.

To install conda, you can follow either the official 
`conda installation guide <https://docs.conda.io/projects/conda/en/latest/user-guide/install>`_, 
or look at the 
`anaconda instructions <https://docs.anaconda.com/anaconda/install/>`_.

For instance, to install the latest ``Anaconda`` distribution you can do

.. code-block:: bash
    
    wget https://repo.anaconda.com/archive/Anaconda3-2019.10-Linux-x86_64.sh
    bash Anaconda3-2019.10-Linux-x86_64.sh

After you have installed it make sure conda is in your ``PATH``, and in case 
is not just source the conda activation script

.. code-block:: bash
    
    source <your-conda-install-path>/bin/activate


Using a Conda Environment
-------------------------
In case you want to use a `conda environment <https://conda.io/projects/conda/en/latest/user-guide/getting-started.html#managing-python>`_ instead of the base installation, 
follow these simple steps to get everything you need:

  1. Save the content of this 
  `GIST <https://gist.github.com/PeterOgden/4916e82c3e4bff77a9ce11c7e77bfdb8>`_ 
  as ``environment.yml``

  2. Create the ``pynq-env`` environment using the above configuration

      .. code-block:: bash

         conda env create -f environment.yml

  3. Activate the newly created environment

      .. code-block:: bash

         conda activate pynq-env

The provided 
`environment.yml <https://gist.github.com/PeterOgden/4916e82c3e4bff77a9ce11c7e77bfdb8>`_
can also be useful to re-create an environment which is already tested and 
confirmed to be working, in case you are having issues.

Install Jupyter
---------------

By default, installing ``pynq`` will not install ``jupyter``. In case you want 
it, you can install it using PIP

.. code-block:: bash
    
    pip install jupyter

Or install the ``pynq-alveo-examples`` package as previously shown. This package 
will install Jupyter as a dependency, alongside the other packages required to 
run the included example notebooks.

.. note:: When installing jupyter with a version of Python less than ``3.6``, 
    you will have to make sure to have a compatible version of ``ipython`` 
    installed. Therefore, in this case after installing ``jupyter``, 
    force-install ``ipython`` with an appropriate version. The recommended is 
    version ``7.9``, and you can ensure this is the version installed by 
    running ``pip install --upgrade ipython==7.9``.
