Microblaze RPC
==============

The PYNQ Microblaze infrastructure is built on top of a remote procedure
call (RPC) layer which is responsible for forwarding function calls from
the Python environment to the Microblaze and handling all data transfer.

Supported Function Signatures
-----------------------------

The RPC layer supports a subset of the C programming language for
interface functions, although any functions may be used internally
within the Microblaze program. Any function which does not conform to
these requirements will be ignored. The limitations are:

1. No ``struct`` or ``union`` for either parameters or return types.

2. No returning of pointer types

3. No pointers to pointers

Data Transfer
-------------

All return values are passed back to Python through copying. The
transfer of function arguments depends on the type used. For a given
non-void primitive the following semantics:

* Non-pointer types are copied from PYNQ to the microblaze
* Const pointer types are copied from Python to the Microblaze
* Non-const pointer types are copied from Python to the Microblaze and
  then copied back after completion of the function.

The timeline of the execution of the function can be seen below:

.. image::../images/ipmb_data_transfer.png

The Python ``struct`` module is used to convert the Python type passed
to the function into the appropriately sized integer or floating point
value for the Microblaze. Out of range values will result in an
exception being raised and the Microblaze function not running. Arrays
of types are treated similarly with the ``struct`` module used to
perform the conversion from an array of Python types to the C array. For
non-const arrays, the array is updated in place so that the return
values are available to the caller. The only exception to these
conversion rules are ``char`` and ``const char`` pointers which are
optimised for Python ``bytearray`` and ``bytes`` types. Note that
calling a function with a non-const ``char*`` argument with a ``bytes``
object will result in an error because ``bytes`` objects are read-only.
This will caught prior to the Microblaze function being called.

Long-running Functions
----------------------

For non-void return functions, the Python functions are synchronous and
will wait for the C function to finish prior to returning to the caller.
For functions that return void then the function is called
asynchronously and the Python function will return immediately. This
entails long-running, independent functions to run on the Microblaze
without blocking the Python thread. While the function is running, no
other functions can be called unless the long-running process frequently
calls ``yield`` (from ``yield.h``) to allow the RPC runtime to service
requests. Please note - there is no multi-threading available inside the
Microblaze so attempting to run two long-running processes
simultaneously will result in only one executing regardless of the use
of ``yield``.

Typedefs
--------

The RPC engine fully supports typedefs and provides an additional
mechanism to allow for C functions to appear more like Python classes.
The RPC layer recognises the idiom where the name of a typedef is used
as the prefix for a set of function names. Taking an example from the
PYNQ Microblaze library, the ``i2c`` typedef has corresponding functions
``i2c_read`` and ``i2c_write`` which take an ``i2c`` type as the first
parameter. With this idiom the RPC creates a new class called ``i2c``
which has ``read`` and ``write`` methods. Any C functions returning an
``i2c`` typedef now return an instance of this class. For this
conversion to be done, the following three properties must hold:

1. The typedef is of a primitive type

2. There is at least one function returning the typedef

3. There is at least one function named according to the pattern
