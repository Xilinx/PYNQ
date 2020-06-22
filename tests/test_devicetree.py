import os
import pynq
import pytest

from pyfakefs.fake_filesystem import FakeDirectory

class DtboDirectory(FakeDirectory):
    def __init__(self, *args, update=True, **kwargs):
        self._update = update
        super().__init__(*args, **kwargs)

    def add_entry(self, path_object):
        if not isinstance(path_object, FakeDirectory):
            raise OSError(1, "Operation not permitted")
        super().add_entry(path_object)
        self.filesystem.create_file(os.path.join(path_object.path, 'status'),
                                    contents='unapplied\n')
        self.filesystem.create_file(os.path.join(path_object.path, 'dtbo'),
                                    side_effect=self._add_dtbo)
      
    def _add_dtbo(self, fd):
        if self._update:
            dtbo_dir = os.path.dirname(fd.path)
            with open(os.path.join(dtbo_dir, 'status'), 'w') as f:
                f.write('applied\n')


def _init_dtbo_fs(fs, update=True):
    dtbo_dir = DtboDirectory('overlays', filesystem=fs, update=update)
    fs.create_dir('/sys/kernel/config/device-tree')
    fs.add_object('/sys/kernel/config/device-tree/', dtbo_dir)


def test_fake_dtbo_dir(fs):
    _init_dtbo_fs(fs)
    assert os.path.exists('/sys/kernel/config/device-tree/overlays')
    os.mkdir('/sys/kernel/config/device-tree/overlays/my_dtbo')
    assert os.path.exists('/sys/kernel/config/device-tree/overlays/my_dtbo')
    assert os.path.exists('/sys/kernel/config/device-tree/overlays/my_dtbo/dtbo')
    assert os.path.exists('/sys/kernel/config/device-tree/overlays/my_dtbo/status')
    with open('/sys/kernel/config/device-tree/overlays/my_dtbo/dtbo', 'w') as f:
        f.write('A DTBO file')
    with open('/sys/kernel/config/device-tree/overlays/my_dtbo/status', 'r') as f:
        assert f.read() == 'applied\n'

DTBO_DATA = 'A DTBO File'


def test_device_tree_applies(fs):
    _init_dtbo_fs(fs, True)
    fs.create_file('/home/xilinx/test.dtbo', contents=DTBO_DATA)    
    dtbo = pynq.devicetree.DeviceTreeSegment('/home/xilinx/test.dtbo')
    assert dtbo.is_dtbo_applied() == False
    dtbo.insert()
    assert dtbo.is_dtbo_applied() == True
    with open('/sys/kernel/config/device-tree/overlays/test/dtbo', 'r') as f:
        assert f.read() == DTBO_DATA
    # We need to ensure the directory is empty prior to removal
    os.unlink('/sys/kernel/config/device-tree/overlays/test/dtbo')
    os.unlink('/sys/kernel/config/device-tree/overlays/test/status')
    dtbo.remove()
    assert dtbo.is_dtbo_applied() == False
 

def test_device_tree_no_apply(fs):
    _init_dtbo_fs(fs, False)
    fs.create_file('/home/xilinx/test.dtbo', contents=DTBO_DATA)    
    dtbo = pynq.devicetree.DeviceTreeSegment('/home/xilinx/test.dtbo')
    assert dtbo.is_dtbo_applied() == False
    with pytest.raises(RuntimeError):
        dtbo.insert()


def test_file_missing(fs):
    _init_dtbo_fs(fs, False)
    with pytest.raises(IOError):
        dtbo = pynq.devicetree.DeviceTreeSegment('/home/xilinx/test.dtbo')


def test_double_remove(fs):
    _init_dtbo_fs(fs, True)
    fs.create_file('/home/xilinx/test.dtbo', contents=DTBO_DATA)    
    dtbo = pynq.devicetree.DeviceTreeSegment('/home/xilinx/test.dtbo')
    dtbo.insert()
    # Verify empty directory
    os.unlink('/sys/kernel/config/device-tree/overlays/test/dtbo')
    os.unlink('/sys/kernel/config/device-tree/overlays/test/status')
    dtbo.remove()
    dtbo.remove()

