import importlib
import pynq._3rdparty.xrt
import ctypes
import os

class FakeXrt:
    def __init__(self, path):
        self.path = path

    def xclProbe(self):
        return 0

    def __getattr__(self, key):
        return FakeXrt(self.path + '.' + key)


def test_xrt_none(monkeypatch, recwarn):
    monkeypatch.delenv('XILINX_XRT', raising=False)
    monkeypatch.setattr(ctypes, 'CDLL', FakeXrt)
    xrt = importlib.reload(pynq._3rdparty.xrt)
    assert xrt.XRT_SUPPORTED == False
    assert len(recwarn) == 0


def test_xrt_hw_emu(monkeypatch, recwarn):
    monkeypatch.setenv('XILINX_XRT', '/path/to/xrt')
    monkeypatch.setenv('XCL_EMULATION_MODE', 'hw_emu')
    monkeypatch.setattr(ctypes, 'CDLL', FakeXrt)
    xrt = importlib.reload(pynq._3rdparty.xrt)
    assert xrt.XRT_SUPPORTED == True
    assert xrt.XRT_EMULATION == True
    assert xrt.libc.path == '/path/to/xrt/lib/libxrt_hwemu.so'
    assert len(recwarn) == 0


def test_xrt_sw_emu(monkeypatch, recwarn):
    monkeypatch.setenv('XILINX_XRT', '/path/to/xrt')
    monkeypatch.setenv('XCL_EMULATION_MODE', 'sw_emu')
    monkeypatch.setattr(ctypes, 'CDLL', FakeXrt)
    xrt = importlib.reload(pynq._3rdparty.xrt)
    assert xrt.XRT_SUPPORTED == False
    assert len(recwarn) == 1


def test_xrt_wrong_emu(monkeypatch, recwarn):
    monkeypatch.setenv('XILINX_XRT', '/path/to/xrt')
    monkeypatch.setenv('XCL_EMULATION_MODE', 'wrong_emu')
    monkeypatch.setattr(ctypes, 'CDLL', FakeXrt)
    xrt = importlib.reload(pynq._3rdparty.xrt)
    assert xrt.XRT_SUPPORTED == False
    assert len(recwarn) == 1


def test_xrt_normal(monkeypatch, recwarn):
    monkeypatch.setenv('XILINX_XRT', '/path/to/xrt')
    monkeypatch.delenv('XCL_EMULATION_MODE', raising=False)
    monkeypatch.setattr(ctypes, 'CDLL', FakeXrt)
    xrt = importlib.reload(pynq._3rdparty.xrt)
    assert xrt.XRT_SUPPORTED == True
    assert xrt.XRT_EMULATION == False
    assert xrt.libc.path == '/path/to/xrt/lib/libxrt_core.so'
    assert len(recwarn) == 0


def test_xrt_version(monkeypatch, tmp_path):
    with open(tmp_path / 'xbutil', 'w') as f:
        f.write("""#!/bin/bash
echo '{"runtime": {"build": {"version": "2.5.3"}}}'
""")
    os.chmod(tmp_path / 'xbutil', 0o777)
    monkeypatch.setenv('PATH', str(tmp_path) + ':' + os.environ['PATH'])
    monkeypatch.setenv('XILINX_XRT', '/path/to/xrt')
    monkeypatch.delenv('XCL_EMULATION_MODE', raising=False)
    monkeypatch.setattr(ctypes, 'CDLL', FakeXrt)
    import pynq.pl_server.xrt_device
    xrt = importlib.reload(pynq._3rdparty.xrt)
    xrt_device = importlib.reload(pynq.pl_server.xrt_device)
    assert xrt_device._xrt_version == (2, 5, 3)


def test_xrt_version_fail(monkeypatch, tmp_path):
    with open(tmp_path / 'xbutil', 'w') as f:
        f.write("""#!/bin/bash
exit 1
""")
    os.chmod(tmp_path / 'xbutil', 0o777)
    monkeypatch.setenv('PATH', str(tmp_path) + ':' + os.environ['PATH'])
    monkeypatch.setenv('XILINX_XRT', '/path/to/xrt')
    monkeypatch.delenv('XCL_EMULATION_MODE', raising=False)
    monkeypatch.setattr(ctypes, 'CDLL', FakeXrt)
    import pynq.pl_server.xrt_device
    xrt = importlib.reload(pynq._3rdparty.xrt)
    xrt_device = importlib.reload(pynq.pl_server.xrt_device)
    assert xrt_device._xrt_version == (0, 0, 0)


def test_xrt_version_unsupported(monkeypatch, tmp_path):
    with open(tmp_path / 'xbutil', 'w') as f:
        f.write("""#!/bin/bash
echo '{"runtime": {"build": {"version": "2.5.3"}}}'
""")
    os.chmod(tmp_path / 'xbutil', 0o777)
    monkeypatch.setenv('PATH', str(tmp_path) + ':' + os.environ['PATH'])
    monkeypatch.delenv('XILINX_XRT', raising=False)
    monkeypatch.setattr(ctypes, 'CDLL', FakeXrt)
    import pynq.pl_server.xrt_device
    xrt = importlib.reload(pynq._3rdparty.xrt)
    xrt_device = importlib.reload(pynq.pl_server.xrt_device)
    assert xrt_device._xrt_version == (0, 0, 0)
