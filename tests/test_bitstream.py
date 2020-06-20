import contextlib
import os
import pynq
import pytest

from .mock_devices import MockDownloadableDevice
from .helpers import create_file, working_directory, create_d_structure
from .helpers import file_contents


BITSTREAM_FILE = "testbitstream.bit"
BITSTREAM_DATA = "A bitstream file"

DTBO_FILE = "testbitstream.dtbo"
DTBO_DATA = "A DTBO file"

DEVICE_NAMES = [
    "device_name_1",
    "device_name_2"
]

@contextlib.contextmanager
def pynq_path(path):
    oldpath = pynq.bitstream.PYNQ_PATH
    pynq.bitstream.PYNQ_PATH = path
    yield
    pynq.bitstream.PYNQ_PATH = oldpath


@pytest.fixture
def device():
    device = MockDownloadableDevice('testcase')
    yield device
    device.close()


@pytest.fixture(params=DEVICE_NAMES)
def named_device(request):
    device = MockDownloadableDevice('testcase-named')
    device.name = request.param
    yield device
    device.close()
  

def test_relative(tmpdir, device):
    create_file(os.path.join(tmpdir, BITSTREAM_FILE), BITSTREAM_DATA)
    with working_directory(tmpdir):
        bs = pynq.Bitstream(BITSTREAM_FILE, device=device)
        assert bs.bitfile_name == os.path.join(tmpdir, BITSTREAM_FILE)


def test_absolute(tmpdir, device):
    create_file(os.path.join(tmpdir, BITSTREAM_FILE), BITSTREAM_DATA)
    bs = pynq.Bitstream(os.path.join(tmpdir, BITSTREAM_FILE), device=device)
    assert bs.bitfile_name == os.path.join(tmpdir, BITSTREAM_FILE)


D_DATA = {n: "Data: " + n for n in DEVICE_NAMES}

def test_relative_d(tmpdir, named_device):
    create_d_structure(tmpdir, BITSTREAM_FILE, D_DATA)
    with working_directory(tmpdir):
        bs = pynq.Bitstream(BITSTREAM_FILE, device=named_device)
    contents = file_contents(bs.bitfile_name)
    assert contents == "Data: " + named_device.name


def test_absolute_d(tmpdir, named_device):
    create_d_structure(tmpdir, BITSTREAM_FILE, D_DATA)
    bs = pynq.Bitstream(os.path.join(tmpdir, BITSTREAM_FILE), device=named_device)
    contents = file_contents(bs.bitfile_name)
    assert contents == "Data: " + named_device.name


def test_nonstring_name(device):
    with pytest.raises(TypeError) as excinfo:
        bs = pynq.Bitstream(12, device=device)
    assert str(excinfo.value) == "Bitstream name has to be a string."


def test_default_device(tmpdir, device):
    pynq.Device.active_device = device
    create_file(os.path.join(tmpdir, BITSTREAM_FILE), BITSTREAM_DATA)
    bs = pynq.Bitstream(os.path.join(tmpdir, BITSTREAM_FILE))
    assert bs.device == device
    pynq.Device.active_device = None


def test_missing_bitstream(tmpdir, device):
    with pytest.raises(IOError):
        pynq.Bitstream(os.path.join(tmpdir, BITSTREAM_FILE), device=device)


def test_pynq_overlay(tmpdir, device):
    pynqdir = os.path.join(tmpdir, 'pynq')
    os.mkdir(pynqdir)
    os.mkdir(os.path.join(pynqdir, 'overlays'))
    overlay_path = os.path.join(pynqdir, 'overlays',
                                os.path.splitext(BITSTREAM_FILE)[0])
    os.mkdir(overlay_path)
    create_file(os.path.join(overlay_path, BITSTREAM_FILE), BITSTREAM_DATA)
    with pynq_path(pynqdir):
        bs = pynq.Bitstream(BITSTREAM_FILE, device=device)
    assert bs.bitfile_name == os.path.join(overlay_path, BITSTREAM_FILE)

def test_missing_dtbo(tmpdir, device):
    create_file(os.path.join(tmpdir, BITSTREAM_FILE), BITSTREAM_DATA)
    with pytest.raises(IOError):
        pynq.Bitstream(os.path.join(tmpdir, BITSTREAM_FILE), 
                       dtbo=DTBO_FILE, device=device)


