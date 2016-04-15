The ``Pynq`` (Python on Zynq) Platform
==============================================

The section describes the ``pynq`` (**Py**\thon on **Zy**\nq) platform - specifically the operating system support and preloaded Python ``pynq`` package. 

The Pynq platform itself is a preloaded SDCard that boots into Ubuntu Server 14.04.  Python3 is loaded with Jupyter notebook support and the needed Python package, also named pynq.  With the pynq package, users can access programmable logic overlays without ever leaving Python.  

You can explore the project code on GitHub, or you can navigate to the Python pynq package on your Zybo board at /home/xpp/pynq. 

The board also has a Samba share which allows you map pynq as a network drive. In Windows, using Windows Explorer, navigate to or map `\\\\pynq\\xpp`
You can browse to the directory in a similar way using other operating systems.

Python ``pynq`` Package Structure
---------
A package in Python is a folder which contains multiple Pthon moduels (".py" files) and a ``__init__.py`` file. 

``__init__.py`` makes Python treat the directory as a self-containing package. The initialization file can also execute the initialization code for the package. For instance, in ``__init__.py``, the ``__all__`` variable can be used to define the subpackages or modules that will be imported by default when this package is imported.

Pynq contains four _user_ subpackages: ``board``, ``pmods``, ``audio``, and ``video``; a ``tests`` subpackage is for testing the user subpackages. Please refer to the `offical python documentation <https://docs.python.org/3.5/tutorial/modules.html#packages>`_  for additional information.

board
-----
This folder contains the ``onboard`` subpackage, i.e. libraries for peripherals available on Zybo: Buttons, Switches, LEDs. In this case, `board` contains the modules: ``button``, ``led``, and ``switch``, which expose the corresponding lasses and their wrapper functions. 

Pmods (and Grove Peripherals)
-----------------------------
This folder contains peripheral packages which includes the following PMod modules ``OLED``, ``TMP2``, ``ALS`` ``LED8``, ``ADC``, and ``DAC``.  

The following Grove peripherals are also supported: ``Grove ADC``, ``Grove PIR``, ``Grove OLED``, ``Grove Buzzer``, ``Grove Light Sensor``, ``Grove LED BAR``, ``Grove Temperature Sensor``. In addition, ``Pmodio``, ``PmodIic`` and ``DevMode`` are developer classes allowing direct low level access to I/O controllers.

There is also an additional module named ``_iop.py``; this module acts like a wrapper to allow all the PMODs' classes to interface with the Microblaze objects.  The ``_IOP`` class prevents multiple device instantiations on the same PMOD. At the same time, ``_IOP`` keeps track of the status of all the PMODs. 

.. note:: ``_iop.py`` is an internal module, not intended for the end users. In Python, there is no concept of _public_ and _private_; we use ``_`` as a prefix to indicate internal definitions, variables, functions, and packages.


``__init__.py`` is used to raise the scope of all the classes at the package level. The following can be used to import everything in ``pynq.pmods``:

.. code-block:: python

   import pynq.pmods

Alternatively, users can also import each class individually:

.. code-block:: python

   from pynq.pmods import ADC

or

.. code-block:: python

   from pynq.pmods.adc import ADC

But the latter is verbose and not recommended.

tests
^^^^^
This folder includes a tests package for use with all other pynq subpackages. 

NOTE: The ``tests` folders in ``board``, ``pmods``, and others rely on the functions implemented in the ``test`` folders of the pynq package. This common practice in Python where each subpackage has its own ``tests``.  This practice can keep the source code modular and *self-contained*.

Package contents
================
To find a list of modules, and to find documentation for each module, see the [Pynq Package ](../build/html/modules.html)

Usage
=====

Refer to `Section 3. Programing ZYBO in Python <../build/html/3.-Programing-ZYBO-in-Python.html>`_ for more information on how to use Pynq.

To use pynq, import the whole package: 

.. code-block:: python

  import pynq
 
or

.. code-block:: python

   from pynq import *

Note the content of ``__init__.py`` in the ``pynq`` folder:

.. code-block:: python

   __all__ = ['board', 'pmods', 'audio', 'video']

This list shows the subpackages that will be loaded when using `import *``. While it may seem convenient to import everything, it is good practice to only import the required packages.

To access the _onboard_ packages, type:

.. code-block:: python

   from pynq import board

or

.. code-block:: python

   import pynq.board

or, to import specific packages:

.. code-block:: python

   from pynq.board import Button, LED


To access the PMod overlay objects, type:

.. code-block:: python

   from pynq import pmods

or

.. code-block:: python

   import pynq.pmods

or, for a single object

.. code-block:: python

   from pynq.pmods import ADC, DAC



