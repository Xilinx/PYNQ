C++ API Usage Examples
======================

Load a Bitstream
----------------

To write a bitstream file to the ``/lib/firmware directory``, you can use the `Device` class to write the file directly.

.. code-block:: cpp

    Device dev;
    dev.write_to_file("/lib/firmware/design.bit", bitstream_data);

To load a bitstream onto the FPGA, you can use the `Device` class to set the bitstream attributes and download it.
Ensure that first the bitstream exists in /lib/firmware.

.. code-block:: cpp

    Device dev;
    dev.set_bitstream_attrs("design.bit", false);
    dev.download("design.bit");


Allocate and Use contiguous memory buffer
------------------------------------------

To allocate a contiguous memory buffer that can be used for device operations, you can use the `BufferRemote` class. 
First, you must have an instance of `XrtBufferManager`, initialised with an xrt device obtained from the XRT C++ API.
Then, you can create a `BufferRemote` object with the desired size and type by passing in the relevant `XrtBufferManager`.

This buffer can be used to read/write data directly.

.. code-block:: cpp

    xrt::device device = xrt::device(0);
    XrtBufferManager mgr(device);
    BufferRemote buf(1024, "<float", mgr, true);  // 1024 bytes, float type, cacheable

    float* arr = reinterpret_cast<float*>(buf.virtual_address());
    arr[0] = 3.1415f;
    buf.flush();


MMIO Access
-----------
To perform memory-mapped I/O operations, you can use the `MMIO` class.
Each instance of `MMIO` represents a memory-mapped region, allowing you to read and write values at specific offsets.

.. code-block:: cpp

    MMIO mmio(0xA0000000, 0x1000);  // Base physical address, size 4KB
    mmio.write(0x0, 0x1);           // Write value 1 at offset 0
    uint32_t val = mmio.read(0x0);  // Read from offset 0
