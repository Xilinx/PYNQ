import os
import pynq
import pytest

from .mock_devices import MockDownloadableDevice
from .helpers import create_file, working_directory, create_d_structure
from .helpers import file_contents, MockExtension


BITSTREAM_FILE = "testbitstream.bit"
BITSTREAM_DATA = "A bitstream file"

DTBO_FILE = "testbitstream.dtbo"
DTBO_DATA = "A DTBO file"

DEVICE_NAMES = [
    "device_name_1",
    "device_name_2"
]


def set_pynq_path(path, monkeypatch, extra_paths=[]):
    monkeypatch.setattr(pynq.bitstream, '_ExtensionsManager',
                        MockExtension({'pynq.overlays': (path, extra_paths)}))


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
    bs = pynq.Bitstream(os.path.join(tmpdir, BITSTREAM_FILE),
                        device=named_device)
    contents = file_contents(bs.bitfile_name)
    assert contents == "Data: " + named_device.name


def test_missing_d(tmpdir, device):
    create_d_structure(tmpdir, BITSTREAM_FILE, D_DATA)
    device.name = "wrong-device"
    with pytest.raises(IOError):
        pynq.Bitstream(os.path.join(tmpdir, BITSTREAM_FILE),
                       device=device)


def test_nonstring_name(device):
    with pytest.raises(TypeError) as excinfo:
        pynq.Bitstream(12, device=device)
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


def test_pynq_overlay(tmpdir, device, monkeypatch):
    pynqdir = os.path.join(tmpdir, 'pynq')
    os.mkdir(pynqdir)
    os.mkdir(os.path.join(pynqdir, 'overlays'))
    overlay_path = os.path.join(pynqdir, 'overlays',
                                os.path.splitext(BITSTREAM_FILE)[0])
    os.mkdir(overlay_path)
    create_file(os.path.join(overlay_path, BITSTREAM_FILE), BITSTREAM_DATA)
    set_pynq_path(os.path.join(pynqdir, 'overlays'), monkeypatch)
    bs = pynq.Bitstream(BITSTREAM_FILE, device=device)
    assert bs.bitfile_name == os.path.join(overlay_path, BITSTREAM_FILE)


def test_missing_dtbo(tmpdir, device):
    create_file(os.path.join(tmpdir, BITSTREAM_FILE), BITSTREAM_DATA)
    with pytest.raises(IOError):
        pynq.Bitstream(os.path.join(tmpdir, BITSTREAM_FILE),
                       dtbo=DTBO_FILE, device=device)


def test_default_dtbo(tmpdir, device):
    create_file(os.path.join(tmpdir, BITSTREAM_FILE), BITSTREAM_DATA)
    create_file(os.path.join(tmpdir, DTBO_FILE), DTBO_DATA)
    bs = pynq.Bitstream(os.path.join(tmpdir, BITSTREAM_FILE), device=device)
    assert bs.dtbo == os.path.join(tmpdir, DTBO_FILE)


def test_dtbo_cwd_relative(tmpdir, device):
    dtbo_dir = os.path.join(tmpdir, 'dtbo')
    create_file(os.path.join(tmpdir, BITSTREAM_FILE), BITSTREAM_DATA)
    os.mkdir(dtbo_dir)
    create_file(os.path.join(dtbo_dir, 'other.dtbo'), DTBO_DATA)
    with working_directory(dtbo_dir):
        bs = pynq.Bitstream(os.path.join(tmpdir, BITSTREAM_FILE),
                            dtbo='other.dtbo', device=device)
    assert bs.dtbo == os.path.join(dtbo_dir, 'other.dtbo')


def test_dtbo_bs_relative(tmpdir, device):
    create_file(os.path.join(tmpdir, BITSTREAM_FILE), BITSTREAM_DATA)
    create_file(os.path.join(tmpdir, 'other.dtbo'), DTBO_DATA)
    bs = pynq.Bitstream(os.path.join(tmpdir, BITSTREAM_FILE),
                        dtbo='other.dtbo', device=device)
    assert bs.dtbo == os.path.join(tmpdir, 'other.dtbo')


def test_download(tmpdir, device):
    create_file(os.path.join(tmpdir, BITSTREAM_FILE), BITSTREAM_DATA)
    bs = pynq.Bitstream(os.path.join(tmpdir, BITSTREAM_FILE), device=device)
    bs.download()
    assert device.operations == [('download', bs, None)]


def test_dtbo_remove(tmpdir, device):
    create_file(os.path.join(tmpdir, BITSTREAM_FILE), BITSTREAM_DATA)
    dtbo_file = os.path.join(tmpdir, DTBO_FILE)
    create_file(dtbo_file, DTBO_DATA)
    bs = pynq.Bitstream(os.path.join(tmpdir, BITSTREAM_FILE), device=device)
    bs.remove_dtbo()
    assert device.operations == [('remove_device_tree', dtbo_file)]


def test_dtbo_insert_none(tmpdir, device):
    create_file(os.path.join(tmpdir, BITSTREAM_FILE), BITSTREAM_DATA)
    bs = pynq.Bitstream(os.path.join(tmpdir, BITSTREAM_FILE), device=device)
    with pytest.raises(ValueError):
        bs.insert_dtbo()


def test_dtbo_insert_existing(tmpdir, device):
    create_file(os.path.join(tmpdir, BITSTREAM_FILE), BITSTREAM_DATA)
    dtbo_file = os.path.join(tmpdir, DTBO_FILE)
    create_file(dtbo_file, DTBO_DATA)
    bs = pynq.Bitstream(os.path.join(tmpdir, BITSTREAM_FILE), device=device)
    bs.insert_dtbo()
    assert device.operations == [('insert_device_tree', dtbo_file)]


def test_dtbo_insert_missing(tmpdir, device):
    create_file(os.path.join(tmpdir, BITSTREAM_FILE), BITSTREAM_DATA)
    bs = pynq.Bitstream(os.path.join(tmpdir, BITSTREAM_FILE), device=device)
    with pytest.raises(IOError):
        bs.insert_dtbo('missing.dtbo')


def test_dtbo_insert_new(tmpdir, device):
    create_file(os.path.join(tmpdir, BITSTREAM_FILE), BITSTREAM_DATA)
    dtbo_file = os.path.join(tmpdir, 'new.dtbo')
    create_file(dtbo_file, DTBO_DATA)
    bs = pynq.Bitstream(os.path.join(tmpdir, BITSTREAM_FILE), device=device)
    bs.insert_dtbo('new.dtbo')
    assert device.operations == [('insert_device_tree', dtbo_file)]
