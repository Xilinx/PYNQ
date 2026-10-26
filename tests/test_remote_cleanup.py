# Copyright (C) 2026 Advanced Micro Devices, Inc.
# SPDX-License-Identifier: BSD-3-Clause

"""Automated PYNQ.remote cleanup tests.

These tests exercise single-client cleanup behavior for remote MMIO, buffers,
GPIO, global cleanup, constructor auto-cleanup, atexit cleanup, and full overlay
download cleanup. They require a current ``pynq-remote`` server image.
"""

import json
import os
import subprocess
import sys
import textwrap

import pytest

from .remote_helpers import (
    assert_buffer_view_does_not_release_buffer,
    assert_fresh_resources_do_not_alias,
    assert_repeated_release_succeeds,
    assert_resource_ids_stale,
    assert_resource_objects_stale,
    close_remote_device,
    create_no_overlay_cleanup_resources,
    create_overlay_backed_cleanup_resources,
    load_overlay,
    probe_remote_device,
    release_cleanup_resources,
    remote_ip,
    require_overlay_path,
)


pytestmark = pytest.mark.remote


def test_remote_cleanup_individual_release():
    """Per-object close/free/release invalidates MMIO, buffer, and GPIO handles."""
    device = None
    resources = {}
    try:
        device = probe_remote_device()
        overlay = load_overlay(device)
        resources = create_overlay_backed_cleanup_resources(device, overlay=overlay)
        assert_buffer_view_does_not_release_buffer(resources["buffer"])

        release_cleanup_resources(resources)
        assert_resource_ids_stale(device, resources)
        assert_repeated_release_succeeds(device, resources)
    finally:
        close_remote_device(device)


def test_remote_cleanup_explicit_device_cleanup():
    """``device.cleanup()`` globally invalidates stale handles while ensuring no aliasing"""
    device = None
    resources = {}
    fresh_resources = {}
    try:
        device = probe_remote_device()
        overlay = load_overlay(device)
        resources = create_overlay_backed_cleanup_resources(device, overlay=overlay)

        response = device.cleanup()
        assert response.status is True

        assert_resource_objects_stale(resources)
        assert_resource_ids_stale(device, resources)
        assert_repeated_release_succeeds(device, resources)

        fresh_overlay = load_overlay(device)
        fresh_resources = create_overlay_backed_cleanup_resources(
            device,
            overlay=fresh_overlay,
        )
        assert_fresh_resources_do_not_alias(resources, fresh_resources)
        assert_resource_ids_stale(device, resources, check_gpio_unexport=False)
    finally:
        release_cleanup_resources(fresh_resources)
        release_cleanup_resources(resources)
        close_remote_device(device)


def test_remote_cleanup_constructor_auto_cleanup():
    """A new auto-cleaning client clears resources left by a previous client."""
    from pynq.pl_server.remote_device import RemoteDevice

    old_device = None
    cleanup_device = None
    old_resources = {}
    fresh_resources = {}
    try:
        old_device = RemoteDevice(ip_addr=remote_ip(), auto_cleanup=False)
        overlay = load_overlay(old_device)
        old_resources = create_overlay_backed_cleanup_resources(
            old_device,
            overlay=overlay,
        )

        assert old_resources["ip"].read(0) is not None
        assert old_resources["buffer"].physical_address is not None
        if old_resources.get("gpio") is not None:
            assert old_resources["gpio"].read() in (0, 1)

        cleanup_device = probe_remote_device()

        assert_resource_objects_stale(old_resources)
        assert_resource_ids_stale(cleanup_device, old_resources)

        fresh_overlay = load_overlay(cleanup_device)
        fresh_resources = create_overlay_backed_cleanup_resources(
            cleanup_device,
            overlay=fresh_overlay,
        )
        assert_fresh_resources_do_not_alias(old_resources, fresh_resources)
        assert_resource_ids_stale(
            cleanup_device,
            old_resources,
            check_gpio_unexport=False,
        )
    finally:
        release_cleanup_resources(fresh_resources)
        release_cleanup_resources(old_resources)
        close_remote_device(cleanup_device)
        close_remote_device(old_device)


def test_remote_cleanup_atexit(tmp_path):
    """Interpreter shutdown runs ``RemoteDevice`` atexit cleanup."""
    state_path = tmp_path / "remote_cleanup_atexit_state.json"
    overlay_path = require_overlay_path()
    ip_addr = remote_ip()
    env = os.environ.copy()
    env.setdefault("PYNQ_REMOTE_DEVICES", ip_addr)

    child_code = textwrap.dedent(
        f"""
        import json
        import os
        from pathlib import Path

        remote_ip = "{ip_addr}"
        os.environ["PYNQ_REMOTE_DEVICES"] = remote_ip

        from pynq import Overlay
        from tests.remote_helpers import (
            create_overlay_backed_cleanup_resources,
            probe_remote_device,
        )

        state_path = Path({str(state_path)!r})
        overlay_path = Path({str(overlay_path)!r})

        device = probe_remote_device()
        overlay = Overlay(str(overlay_path), device=device)
        resources = create_overlay_backed_cleanup_resources(device, overlay=overlay)

        state_path.write_text(json.dumps({{
            "base_addr": resources["base_addr"],
            "mmio_id": resources["mmio_id"],
            "buffer_id": resources["buffer_id"],
            "gpio_id": resources["gpio_id"],
            "gpio_pin": resources["gpio_pin"],
            "gpio_path": resources["gpio_path"],
        }}))

        # Keep objects alive until interpreter shutdown so RemoteDevice.close()
        # is the mechanism that releases them.
        LIVE = (device, resources)
        """
    )

    result = subprocess.run(
        [sys.executable, "-c", child_code],
        cwd=overlay_path.parents[1],
        env=env,
        text=True,
        capture_output=True,
        check=False,
    )
    assert result.returncode == 0, result.stderr
    assert state_path.exists(), result.stdout + result.stderr

    old_resources = json.loads(state_path.read_text())

    from pynq.pl_server.remote_device import RemoteDevice

    verify_device = None
    fresh_resources = {}
    try:
        verify_device = RemoteDevice(ip_addr=ip_addr, auto_cleanup=False)
        assert_resource_ids_stale(verify_device, old_resources)

        fresh_resources = create_no_overlay_cleanup_resources(
            verify_device,
            old_resources,
        )
        assert_fresh_resources_do_not_alias(old_resources, fresh_resources)
        assert_resource_ids_stale(
            verify_device,
            old_resources,
            check_gpio_unexport=False,
        )
    finally:
        release_cleanup_resources(fresh_resources)
        if verify_device is not None:
            try:
                verify_device.cleanup()
            except Exception:
                pass
        close_remote_device(verify_device)


def test_remote_cleanup_overlay_download():
    """A full overlay download cleans stale resources before creating new ones."""
    device = None
    old_resources = {}
    fresh_resources = {}
    try:
        device = probe_remote_device()
        first_overlay = load_overlay(device)
        old_resources = create_overlay_backed_cleanup_resources(
            device,
            overlay=first_overlay,
        )

        second_overlay = load_overlay(device)

        assert_resource_objects_stale(old_resources)
        assert_resource_ids_stale(device, old_resources)

        fresh_resources = create_overlay_backed_cleanup_resources(
            device,
            overlay=second_overlay,
        )
        assert_fresh_resources_do_not_alias(old_resources, fresh_resources)
        assert_resource_ids_stale(device, old_resources, check_gpio_unexport=False)
    finally:
        release_cleanup_resources(fresh_resources)
        release_cleanup_resources(old_resources)
        close_remote_device(device)
