.. _pynq-remote-troubleshooting:

Troubleshooting
===============

Finding the board IP address
----------------------------

Remote images configure both a static address of ``192.168.2.99`` and DHCP.
If your host is on the ``192.168.2.0/24`` network, use that address.

Otherwise, use the DHCP address from your router's client list. To read the
addresses on the board itself, connect over USB serial and run:

.. code-block:: bash

   ip addr

Use ``ip addr`` rather than ``ifconfig``; the latter may not list every address
on the interfaces.

The first time you connect over USB serial, log in as ``amd-edf`` and set a
password when prompted.

On-target self-test
-------------------

PYNQ.remote images install an on-target checker:

.. code-block:: bash

   pynq-remote-selftest

This verifies the ``pynq-remote`` service, the gRPC server, XRT/zocl, the FPGA
manager, networking, and board identity.

Host-side self-test
-------------------

After installing PYNQ on the host with ``PYNQ_REMOTE=1``, run:

.. code-block:: bash

   pynq-remote-selftest --ip <board-ip>
   pynq-remote-selftest --ip <board-ip> --list
   pynq-remote-selftest --ip <board-ip> --bitstream base.xsa

This exercises the host-to-board gRPC connection, buffer transfers, and overlay
download from the host.
