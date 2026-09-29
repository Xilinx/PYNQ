.. _pynq-remote-package:

pynq.remote Package
===================

The ``pynq.remote`` package provides the host-side gRPC client modules for
PYNQ.remote. Install it by setting ``PYNQ_REMOTE=1`` when installing the
``pynq`` package. See :ref:`pynq_remote` for setup and usage.

When ``PYNQ_REMOTE_DEVICES`` is set before ``import pynq``, the top-level
``pynq`` package registers ``pynq.remote.xrfdc`` and ``pynq.remote.xrfclk`` as
the ``xrfdc`` and ``xrfclk`` modules so that RFSoC notebooks run over the
remote connection without changes. Board control uses
:mod:`pynq.pl_server.remote_device`.

.. toctree::
    :hidden:

    pynq.remote/pynq.remote.xrfdc
    pynq.remote/pynq.remote.xrfclk
