.. _pynq-libraries-debugbridge:

DebugBridge
===========

The *DebugBridge* class provides register descriptor and 
a *Xilinx Virtual Cable* (XVC) server on Debug Bridge IP 
in *AXI to BSCAN* and *AXI to JTAG* configurations.

The XVC server in this class bridges between Vivado hardware 
servers and the Debug Hub through Ethernet. Vivado then will 
operate the Debug Bridge as a virtual JTAG adapter.

When instantiating a Debug Bridge IP in the overlay
in *AXI to BSCAN* configuration, the debug hub for debugging
IPs will be connected to the Debug Bridge by default. 
Under this configuration, the XVC connection enables conventional 
debugging IPs, including ILAs and VIOs, to work with overlays.
The XVC connection also allows remote debugging without physically 
attaching a JTAG adapter.

Another use case is to control a Debug Bridge IP in *AXI to JTAG* 
configuration. In this config, the Debug Bridge runs as 
a remote JTAG adapter for another AMD-Xilinx FPGA with its JTAG pins
connected to the Debug Bridge in the PYNQ host.

This class provides a Python implementation of the XVC server v1.0 
for ease of use and integration with PYNQ overlays. More details about
XVC could be found in the `Product Page <https://www.xilinx.com/products/intellectual-property/xvc.html>`_ 
and the `Official Wiki <https://xilinx-wiki.atlassian.net/wiki/spaces/A/pages/644579329/Xilinx+Virtual+Cable>`_.

Use ``start_xvc_server()`` and ``stop_xvc_server()`` methods to setup and kill the XVC server.

.. code-block:: Python

    start_xvc_server(bufferLen=4096, serverAddress="0.0.0.0",
                     serverPort=2542, reconnect=True, verbose=True)

Create and start an XVC server listening to the specified address and port.
The server will be running in a separate thread.
Each Debug Bridge allows one and only one hardware server to connect at once.

* ``bufferLen`` is the length of data buffer for XVC shift commands in bytes
* ``serverAddress`` is the address the XVC server listens to
* ``serverPort`` is the port the XVC server listens to
* ``reconnect`` when True allows listening to the next connection when the previous one is disconnected
* ``verbose`` when True prints the connection status of the XVC server

.. code-block:: Python

    stop_xvc_server()

Stop the XVC server and break active connections.

.. warning::
    Stop the XVC server with ``stop_xvc_server()`` before 
    downloading any overlay.
    
    The XVC server cannot detect overlay replacement. Downloading 
    another overlay with an XVC server running will cause access to an
    uninitialized PL, eventually halt the PS.
