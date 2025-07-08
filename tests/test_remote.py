# Copyright (C) 2025 Advanced Micro Devices, Inc.
# SPDX-License-Identifier: BSD-3-Clause


import os
import pytest
import numpy as np

# Setup PYNQ environment variable - REQUIRED for PYNQ.remote to work
os.environ["PYNQ_REMOTE_DEVICES"] = "192.168.0.238"

@pytest.mark.remote
def test_remote():
    """Test basic PYNQ.remote functionality.
    
    Tests overlay loading, buffer allocation, DMA transfers, and data integrity
    using the resizer accelerator. Requires PYNQ_REMOTE_DEVICES to be set.
    """
    
    # Verify the environment variable is set
    if not os.environ.get("PYNQ_REMOTE_DEVICES"):
        pytest.skip("PYNQ_REMOTE_DEVICES environment variable not set - required for remote PYNQ")
     
    # Get the path to the overlay file in the tests directory
    test_dir = os.path.dirname(os.path.abspath(__file__))
    overlay_path = os.path.join(test_dir, "resizer.bit")
    if not os.path.exists(overlay_path):
        pytest.skip(f"Overlay not found: {overlay_path}")   

    try:
        from pynq import allocate, Overlay
        from pynq.pl_server.device import Device
        from pynq.pl_server.remote_device import RemoteDevice
    except ImportError as e:
        pytest.skip(f"Required PYNQ modules not found: {e}")

    # Verify that at least one RemoteDevice was discovered
    devices = Device.devices
    remote_devices = [d for d in devices if isinstance(d, RemoteDevice)]
    if not remote_devices:
        pytest.skip("No PYNQ devices discovered - check PYNQ_REMOTE_DEVICES and network connectivity")


    resize_design = Overlay(overlay_path)
    dma = resize_design.axi_dma_0
    resizer = resize_design.resize_accel_0
    
    size = 500
    fake_img = np.random.randint(0, 256, (size, size, 3), dtype=np.uint8)
    
    # Allocate input/output buffers
    in_buffer = allocate(shape=(size, size, 3), dtype=np.uint8, cacheable=1)
    out_buffer = allocate(shape=(size, size, 3), dtype=np.uint8, cacheable=1)
    in_buffer[:] = fake_img

    # Configure hardware
    resizer.register_map.src_rows = size
    resizer.register_map.src_cols = size
    resizer.register_map.dst_rows = size
    resizer.register_map.dst_cols = size

    # DMA transfer and accelerator start
    dma.sendchannel.transfer(in_buffer)
    dma.recvchannel.transfer(out_buffer)
    resizer.write(0x00, 0x81)  # Start
    dma.sendchannel.wait()
    dma.recvchannel.wait()

    # Check input and output buffers match exactly
    assert np.array_equal(in_buffer[:], out_buffer[:])

    # Clean up
    del in_buffer
    del out_buffer

if __name__ == "__main__":
    test_remote()