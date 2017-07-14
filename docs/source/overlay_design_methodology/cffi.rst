CFFI
==========

In some instances, the performance of Python classes to manage data transfer to an overlay may not be sufficient. Usually this would be determined by implementing the driver in Python, and profiling to determine performance. 

A higher performance library can be developed in a lower level language (e.g. C/C++) and optimized for an overlay. The driver functions in the library can be called from Python using CFFI (C Foreign Function Interface).

CFFI provides a simple way to interface with C code from Python. The CFFI package is preinstalled in the PYNQ image. It supports four modes, API and ABI, each with "in-line" or "out-of-line compilation". *Inline* ABI (Application Binary Interface) compatibility mode allows dynamic loading and running of functions from executable modules, and API mode allows building of C extension modules. 


The following example taken from http://docs.python-guide.org/en/latest/scenarios/clibs/ shows the ABI inline mode, calling the C function ``strlen()`` in from Python 

C function prototype:

.. code-block:: c

   size_t strlen(const char*);

The C function prototype is passed to ``cdef()``, and can be called using ``clib``.
   
.. code-block:: python

   from cffi import FFI
   ffi = FFI()
   ffi.cdef("size_t strlen(const char*);")
   clib = ffi.dlopen(None)
   length = clib.strlen(b"String to be evaluated.")
   print("{}".format(length))

C functions inside a shared library can be called from Python using the C Foreign Function Interface (CFFI). The shared library can be compiled online using the CFFI from Python, or it can be compiled offline. 

For more information on CFFI and shared libraries refer to:

http://cffi.readthedocs.io/en/latest/overview.html

http://www.tldp.org/HOWTO/Program-Library-HOWTO/shared-libraries.html
