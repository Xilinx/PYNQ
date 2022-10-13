# Copyright (C) 2022 Xilinx, Inc

# SPDX-License-Identifier: BSD-3-Clause

import ctypes
import importlib
import os
import pathlib

import pynq._3rdparty.xrt
import pytest


class FakeXrt:
    def __init__(self, path):
        self.path = path

    def xclProbe(self):
        return 0

    def __getattr__(self, key):
        return FakeXrt(self.path + "." + key)


def test_xrt_none(monkeypatch, recwarn):
    monkeypatch.delenv("XILINX_XRT", raising=False)
    monkeypatch.setattr(ctypes, "CDLL", FakeXrt)
    xrt = importlib.reload(pynq._3rdparty.xrt)
    assert xrt.XRT_SUPPORTED == False
    assert len(recwarn) == 0


def test_xrt_hw_emu(monkeypatch, recwarn):
    monkeypatch.setenv("XILINX_XRT", "/path/to/xrt")
    monkeypatch.setenv("XCL_EMULATION_MODE", "hw_emu")
    monkeypatch.setattr(ctypes, "CDLL", FakeXrt)
    xrt = importlib.reload(pynq._3rdparty.xrt)
    assert xrt.XRT_SUPPORTED == True
    assert xrt.XRT_EMULATION == True
    assert xrt.libc.path == "/path/to/xrt/lib/libxrt_hwemu.so"
    assert len(recwarn) == 0


def test_xrt_sw_emu(monkeypatch, recwarn):
    monkeypatch.setenv("XILINX_XRT", "/path/to/xrt")
    monkeypatch.setenv("XCL_EMULATION_MODE", "sw_emu")
    monkeypatch.setattr(ctypes, "CDLL", FakeXrt)
    xrt = importlib.reload(pynq._3rdparty.xrt)
    assert xrt.XRT_SUPPORTED == False
    assert len(recwarn) == 1


def test_xrt_wrong_emu(monkeypatch, recwarn):
    monkeypatch.setenv("XILINX_XRT", "/path/to/xrt")
    monkeypatch.setenv("XCL_EMULATION_MODE", "wrong_emu")
    monkeypatch.setattr(ctypes, "CDLL", FakeXrt)
    xrt = importlib.reload(pynq._3rdparty.xrt)
    assert xrt.XRT_SUPPORTED == False
    assert len(recwarn) == 1


def test_xrt_normal(monkeypatch, recwarn):
    monkeypatch.setenv("XILINX_XRT", "/path/to/xrt")
    monkeypatch.delenv("XCL_EMULATION_MODE", raising=False)
    monkeypatch.setattr(ctypes, "CDLL", FakeXrt)
    xrt = importlib.reload(pynq._3rdparty.xrt)
    assert xrt.XRT_SUPPORTED == True
    assert xrt.XRT_EMULATION == False
    assert xrt.libc.path == "/path/to/xrt/lib/libxrt_core.so"
    assert len(recwarn) == 0


#def test_xrt_version_x86(monkeypatch, tmp_path):
#    monkeypatch.setenv("XILINX_XRT", str(tmp_path))
#    with open(tmp_path / "version.json", "w") as f:
#        f.write("""{\n  "BUILD_VERSION" : "2.12.447"\n}\n\n""")
#    monkeypatch.delenv("XCL_EMULATION_MODE", raising=False)
#    monkeypatch.setattr(ctypes, "CDLL", FakeXrt)
#    import pynq.pl_server.xrt_device
#
#    xrt = importlib.reload(pynq._3rdparty.xrt)
#    xrt_device = importlib.reload(pynq.pl_server.xrt_device)
#    assert xrt_device._get_xrt_version_x86() == (2, 12, 447)


def test_xrt_version_embedded(monkeypatch, tmp_path):
    with open(tmp_path / 'xbutil', 'w') as f:
        f.write("""#!/bin/bash
echo 'Version              : 2.13.0'
""")
    os.chmod(tmp_path / 'xbutil', 0o777)
    monkeypatch.setenv('PATH', str(tmp_path) + ':' + os.environ['PATH'])
    monkeypatch.setenv('XILINX_XRT', '/path/to/xrt')
    monkeypatch.delenv('XCL_EMULATION_MODE', raising=False)
    monkeypatch.setattr(ctypes, 'CDLL', FakeXrt)
    import pynq.pl_server.xrt_device
    xrt = importlib.reload(pynq._3rdparty.xrt)
    xrt_device = importlib.reload(pynq.pl_server.xrt_device)
    assert xrt_device._xrt_version == (2, 13, 0)

#def test_xrt_version_fail_x86(monkeypatch, tmp_path):
#    monkeypatch.setenv("XILINX_XRT", str(tmp_path))
#    import pynq.pl_server.xrt_device
#
#    monkeypatch.delenv("XCL_EMULATION_MODE", raising=False)
#    monkeypatch.setattr(ctypes, "CDLL", FakeXrt)
#    with pytest.warns(UserWarning, match="Unable to determine XRT version"):
#        xrt = importlib.reload(pynq._3rdparty.xrt)
#        xrt_device = importlib.reload(pynq.pl_server.xrt_device)
#    assert xrt_device._xrt_version == (0, 0, 0)


def test_xrt_version_unsupported(monkeypatch, tmp_path):
    monkeypatch.setenv("XILINX_XRT", str(tmp_path))
    with open(tmp_path / "version.json", "w") as f:
        f.write("""{\n  "BUILD_VERSION" : "2.12.447"\n}\n\n""")
    monkeypatch.setenv("PATH", str(tmp_path) + ":" + os.environ["PATH"])
    monkeypatch.delenv("XILINX_XRT", raising=False)
    import pynq.pl_server.xrt_device

    xrt = importlib.reload(pynq._3rdparty.xrt)
    xrt_device = importlib.reload(pynq.pl_server.xrt_device)
    assert xrt_device._xrt_version == (0, 0, 0)
