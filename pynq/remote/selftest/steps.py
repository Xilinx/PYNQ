"""Ordered host-side remote selftest modules."""

from pynq.remote.selftest.tests import (
    buffer_roundtrip,
    connect,
    connectivity,
    file_roundtrip,
    host_packages,
    mmio_gpio,
    overlay_download,
    overlay_rfdc,
    preflight,
)

# (step label, module). Order matters: later tests use ctx.dev / ctx.overlay.
STEPS = (
    ("[1] Host environment (venv / pynq / numpy / grpc)", preflight),
    ("[2] Connectivity (TCP reach + gRPC channel-ready)", connectivity),
    ("[3] Connect + identity", connect),
    ("[4] Host support packages for this board", host_packages),
    ("[5] File round-trip (write host->target, read target->host)", file_roundtrip),
    (
        "[6] Buffer round-trip (allocate, sync_to_device, sync_from_device)",
        buffer_roundtrip,
    ),
    ("[7] Overlay download (host->target) + PL program", overlay_download),
    (
        "[8] MMIO round-trip on an AXI GPIO (host->target write, target->host read)",
        mmio_gpio,
    ),
    ("[9] RFdc MMIO + driver (when present in overlay)", overlay_rfdc),
)
