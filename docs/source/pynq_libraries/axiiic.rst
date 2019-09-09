.. _pynq-libraries-axiiic:

AxiIIC
======

The AxiIIC class provides methods to read from , and write to an AXI IIC
controller IP.


The ``send()`` and ``receive()`` methods are used to read and write data.

.. code-block:: Python

    send(address, data, length, option=0)

* address is the address of the IIC peripheral
* data is an array of bytes to be sent to the IP
* length is the number of bytes to be transferred
* option allows an IIC *repeated start* 

.. code-block:: Python

    receive(address, data, length, option=0)

* address is the address of the IIC peripheral
* data is an array of bytes to receive data from the IP
* length is the number of bytes to be received
* option allows an IIC *repeated start* 

More information about the AxiIIC module and the API for reading, writing
and waiting can be found in the :ref:`pynq-lib-iic` sections.
