# Copyright (C) 2026 Advanced Micro Devices, Inc.
# SPDX-License-Identifier: BSD-3-Clause

import gc
import os
from pathlib import Path

import grpc
import numpy as np
import pytest


RELEASE_METHODS = {
    "gpio": "release",
    "buffer": "freebuffer",
    "mmio": "close",
}


def remote_ip():
    remote_env = os.environ.get("PYNQ_REMOTE_DEVICES", "")
    if not remote_env:
        pytest.skip("PYNQ_REMOTE_DEVICES environment variable not set")
    return remote_env.split(",")[0].strip()


def require_overlay_path():
    overlay_path = Path(__file__).with_name("resizer.bit")
    if not overlay_path.exists():
        pytest.skip(f"Overlay not found: {overlay_path}")
    return overlay_path


def reset_pynq_device_probe(Device):
    for attr in ("_active_device", "_devices"):
        if hasattr(Device, attr):
            delattr(Device, attr)


def probe_remote_device():
    """Create a remote device through normal PYNQ package discovery."""

    os.environ["PYNQ_REMOTE_DEVICES"] = remote_ip()

    # Importing from pynq runs the package setup that registers remote devices
    # when PYNQ_REMOTE_DEVICES is set.
    from pynq import Device
    from pynq.pl_server.remote_device import RemoteDevice

    reset_pynq_device_probe(Device)
    remote_devices = [d for d in Device.devices if isinstance(d, RemoteDevice)]
    if not remote_devices:
        pytest.skip("No remote PYNQ devices discovered")
    return remote_devices[0]


def assert_rpc_error(excinfo, expected_code, expected_detail):
    assert excinfo.value.code() == expected_code
    assert expected_detail in excinfo.value.details()


def assert_rpc_error_not_found(excinfo, expected_detail):
    assert_rpc_error(excinfo, grpc.StatusCode.NOT_FOUND, expected_detail)


def assert_mmio_read_fails(device, mmio_id, expected_detail):
    from pynq.remote import mmio_pb2

    with pytest.raises(grpc.RpcError) as excinfo:
        device._stub["mmio"].read(
            mmio_pb2.ReadRequest(
                mmio_id=mmio_id,
                offset=0,
                length=4,
                word_order="little",
            )
        )
    assert_rpc_error_not_found(excinfo, expected_detail)


def assert_buffer_address_fails(device, buffer_id, expected_detail):
    from pynq.remote import buffer_pb2

    with pytest.raises(grpc.RpcError) as excinfo:
        device._stub["buffer"].physical_address(
            buffer_pb2.AddressRequest(buffer_id=buffer_id)
        )
    assert_rpc_error_not_found(excinfo, expected_detail)


def assert_gpio_read_fails(device, gpio_id, expected_detail):
    from pynq.remote import gpio_pb2

    with pytest.raises(grpc.RpcError) as excinfo:
        device._stub["gpio"].read(gpio_pb2.GpioReadRequest(gpio_id=gpio_id))
    assert_rpc_error_not_found(excinfo, expected_detail)


def assert_mmio_not_found(device, mmio_id):
    assert_mmio_read_fails(device, mmio_id, "MMIO Object not found")


def assert_buffer_not_found(device, buffer_id):
    assert_buffer_address_fails(device, buffer_id, "Buffer Object not found")


def assert_gpio_not_found(device, gpio_id):
    assert_gpio_read_fails(device, gpio_id, "GPIO Object not found")


def assert_repeated_release_succeeds(device, resources):
    from pynq.remote import buffer_pb2, gpio_pb2, mmio_pb2

    mmio_response = device._stub["mmio"].release_mmio(
        mmio_pb2.ReleaseMmioRequest(mmio_id=resources["mmio_id"])
    )
    assert mmio_response.status is True

    device._stub["buffer"].freebuffer(
        buffer_pb2.FreeBufferRequest(buffer_id=resources["buffer_id"])
    )

    if resources.get("gpio_id") is not None:
        device._stub["gpio"].unexport(
            gpio_pb2.GpioUnexportRequest(gpio_id=resources["gpio_id"])
        )


def assert_stale_mmio_object(mmio):
    with pytest.raises(grpc.RpcError) as excinfo:
        mmio.read(0)
    assert_rpc_error_not_found(excinfo, "MMIO Object not found")


def assert_stale_buffer_object(buffer):
    with pytest.raises(grpc.RpcError) as excinfo:
        buffer.physical_address
    assert_rpc_error_not_found(excinfo, "Buffer Object not found")


def assert_buffer_view_does_not_release_buffer(buffer):
    view = buffer[:4]
    del view
    gc.collect()
    assert buffer.physical_address is not None


def assert_stale_gpio_object(gpio):
    with pytest.raises(grpc.RpcError) as excinfo:
        gpio.read()
    assert_rpc_error_not_found(excinfo, "GPIO Object not found")


def load_overlay(device):
    from pynq import Overlay

    return Overlay(str(require_overlay_path()), device=device)


def create_gpio(device):
    from pynq import GPIO

    base_path = GPIO.get_gpio_base_path(device=device)
    npins = GPIO.get_gpio_npins(device=device)
    if not (base_path and npins):
        return None, None, None

    gpio_pin = GPIO.get_gpio_pin(0, device=device)
    gpio_path = f"/sys/class/gpio/gpio{gpio_pin}"
    if device.exists_file(gpio_path).exists:
        return None, gpio_pin, gpio_path

    gpio = GPIO(gpio_pin, "in", device=device)
    gpio.read()
    return gpio, gpio_pin, gpio_path


def remote_mmio_id(mmio):
    """Return the server handle hidden inside a PYNQ MMIO object."""
    remote_map = getattr(mmio, "_remote_map", None)
    if remote_map is None:
        raise AssertionError("Expected a PYNQ MMIO backed by a remote MMIO map")
    return remote_map.mmio_id


def create_overlay_backed_cleanup_resources(device, overlay=None):
    """Create cleanup resources using normal overlay-backed PYNQ APIs."""
    if overlay is None:
        overlay = load_overlay(device)
    if overlay.device is not device:
        raise AssertionError("Overlay-backed cleanup resources need a matching device")

    resizer = overlay.resize_accel_0
    resizer.read(0)
    mmio = resizer.mmio

    buffer = device.allocate(shape=(16,), dtype=np.uint32, cacheable=1)
    buffer[:] = np.arange(16, dtype=np.uint32)
    buffer.flush()

    gpio, gpio_pin, gpio_path = create_gpio(device)

    return {
        "overlay": overlay,
        "ip": resizer,
        "base_addr": mmio.base_addr,
        "mmio": mmio,
        "mmio_id": remote_mmio_id(mmio),
        "buffer": buffer,
        "buffer_id": buffer.buffer_id,
        "gpio": gpio,
        "gpio_id": getattr(gpio, "_gpio_id", None),
        "gpio_pin": gpio_pin,
        "gpio_path": gpio_path,
    }


def create_no_overlay_cleanup_resources(device, old_resources):
    """Create cleanup resources without loading an overlay.

    This is used when a test deliberately wants to avoid overlay download itself performing cleanup
    example when verifying atexit cleanup from saved handle IDs.
    """
    from pynq import GPIO, MMIO

    mmio = MMIO(old_resources["base_addr"], 0x1000, device=device)
    mmio.read(0)

    buffer = device.allocate(shape=(16,), dtype="u4", cacheable=1)
    buffer.physical_address

    gpio = None
    if old_resources.get("gpio_pin") is not None:
        gpio = GPIO(old_resources["gpio_pin"], "in", device=device)
        gpio.read()

    return {
        "mmio": mmio,
        "mmio_id": remote_mmio_id(mmio),
        "buffer": buffer,
        "buffer_id": buffer.buffer_id,
        "gpio": gpio,
        "gpio_id": getattr(gpio, "_gpio_id", None),
        "gpio_pin": old_resources.get("gpio_pin"),
        "gpio_path": old_resources.get("gpio_path"),
    }


def release_cleanup_resources(resources):
    for key, method in RELEASE_METHODS.items():
        obj = resources.get(key)
        if obj is None:
            continue
        try:
            getattr(obj, method)()
        except Exception:
            pass
    gc.collect()


def close_remote_device(device):
    if device is None:
        return
    try:
        device.close()
    except Exception:
        pass


def assert_resource_ids_stale(device, resources, check_gpio_unexport=True):
    assert_mmio_not_found(device, resources["mmio_id"])
    assert_buffer_not_found(device, resources["buffer_id"])
    if resources.get("gpio_id") is not None:
        assert_gpio_not_found(device, resources["gpio_id"])
        if check_gpio_unexport:
            assert device.exists_file(resources["gpio_path"]).exists is False


def assert_resource_objects_stale(resources):
    assert_stale_mmio_object(resources["mmio"])
    assert_stale_buffer_object(resources["buffer"])
    if resources.get("gpio") is not None:
        assert_stale_gpio_object(resources["gpio"])


def assert_fresh_resources_do_not_alias(old_resources, fresh_resources):
    assert fresh_resources["mmio_id"] != old_resources["mmio_id"]
    assert fresh_resources["buffer_id"] != old_resources["buffer_id"]

    if old_resources.get("gpio_id") is not None and fresh_resources.get("gpio_id"):
        assert fresh_resources["gpio_id"] != old_resources["gpio_id"]
