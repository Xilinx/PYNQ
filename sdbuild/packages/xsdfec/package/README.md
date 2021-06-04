# `xsdfec` Package

This is a package implementing the drivers for RF Soft-Decision Forward Error
Correction (SD-FEC) integrated block IP. This IP supports Low Density Parity
Check (LDPC) decoding and encoding and Turbo code decoding. The LDPC codes
used are highly configurable, and the specific code used can be specified on
a codeword-by-codeword basis. More information about this IP can be found 
[online](https://www.xilinx.com/products/intellectual-property/sd-fec.html).

## Usage

The HWH file PYNQ framework has been using includes a lot of information
about all of the available code parameters. This includes nested lists, etc.
So we use [parser combinators](https://en.wikipedia.org/wiki/Parsec_(parser))
to keep this managable.

In our driver code, to round up the HWH parsing, we have defined the name,
C type, and parser combinator for each field we're interested in.

Now we can build python structs from the HWH parameters, but we need to
convert the types and field names to match the `XSdFecLdpcParameters`
C struct. Be very careful about garbage collection here! If we do not store a
reference to the inner C arrays, they will be garbage collected and make the
LDPC codes incorrect! We solve this with a
weakref dict; you can check
[details](https://cffi.readthedocs.io/en/latest/using.html#working-with-pointers-structures-and-arrays) about the CFFI ownership model.

Once all the above has been taken care of, we load the compiled `.so`
version of the driver and define some helper functions to marshall data 
to/from the driver. We want a couple of things
here:
1. A wrapper to call C functions with C-style arguments
2. A pair of functions to wrap and unwrap python objects as C-style values

This job is done by the `_safe_wrapper()`, `_pack_value()`, and
`_unpack_value` methods. With these helpers in place, we can start defining
the SD FEC driver itself. For initialisation, we parse parameters from the HWH
file to populate an `XSdFec_Config` struct and pass this to the 
`XSdFecCfgInitialize` function. We also parse code parameter tables from the
HWH file and keep them for later. The following C function prototypes have 
been wrapped up by Python API:

```c
XSdFecSetTurboParams(InstancePtr, ParamsPtr)
XSdFecAddLdpcParams(InstancePtr, 
	CodeId, SCOffset, LAOffset, QCOffset, ParamsPtr)
XSdFecShareTableSize(ParamsPtr, SCSizePtr, LASizePtr, QCSizePtr)
XSdFecInterruptClassifier(InstancePtr)
```

As well as the 4 main functions above, there are also getters
and setters for individual registers. We expose them in a data-driven way.
For each register we need to know 3 things:

1. Register name
2. Register data type
3. Register access control (RW/RO/WO)

We define a big list of all of this info for each register then write
a generic function to attach these properties to the SD FEC driver.

Copyright (C) 2021 Xilinx, Inc

SPDX-License-Identifier: BSD-3-Clause
