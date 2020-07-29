import asyncio
import functools
import os
import pynq
import pytest

UIO0_files = [
    ('/sys/class/uio/uio0/name', b'fabric'),
    ('/sys/class/uio/uio1/name', 'axi-pmon'),
]
UIO10_files = [
    ('/sys/class/uio/uio0/name', 'axi-pmon'),
    ('/sys/class/uio/uio10/name', 'fabric'),
]
no_UIO_files = [
    ('/sys/class/uio/uio0/name', 'axi-pmon'),
    ('/sys/class/uio/uio1/name', 'axi-pmon'),
]

FS_TESTS = {
   'uio0': (UIO0_files, '/dev/uio0', 0),
   'uio10': (UIO10_files, '/dev/uio10', 10),
   'none': (no_UIO_files, None, None),
}


@pytest.mark.parametrize('testname', FS_TESTS.keys())
def test_find_uio(fs, testname):
    files, expected, index = FS_TESTS[testname]
    for name, contents in files:
        fs.create_file(name, contents=contents)
    assert pynq.uio.get_uio_device('fabric') == expected
    assert pynq.uio.get_uio_index('fabric') == index


class MockEvent:
    def __init__(self, cb=None):
        self._set = False
        self.cb = cb

    def set(self):
        self._set = True
        if self.cb is not None:
            self.cb()

    @property
    def isset(self):
        return self._set


def _uio_subtest_empty(uio, host_fd, client_fd, callback):
    pass


def _uio_subtest_add_event(uio, host_fd, client_fd, callback):
    ev = MockEvent()
    uio.add_event(ev, 0)
    buf = host_fd.read()
    assert buf == bytes([0, 0, 0, 1])


def _uio_subtest_add_events(uio, host_fd, client_fd, callback):
    ev1 = MockEvent()
    ev2 = MockEvent()
    uio.add_event(ev1, 0)
    buf = host_fd.read()
    assert buf == bytes([0, 0, 0, 1])
    uio.add_event(ev2, 0)
    buf = host_fd.read()
    assert buf == b''


def _uio_subtest_callback(uio, host_fd, client_fd, callback):
    ev = MockEvent()
    uio.add_event(ev, 0)
    buf = host_fd.read()
    assert buf == bytes([0, 0, 0, 1])
    host_fd.write(bytes([0, 0, 0, 1]))
    assert not ev.isset
    callback()
    assert ev.isset


def _uio_subtest_callbacks(uio, host_fd, client_fd, callback):
    ev = MockEvent()
    uio.add_event(ev, 0)
    buf = host_fd.read()
    assert buf == bytes([0, 0, 0, 1])
    host_fd.write(bytes([0, 0, 0, 1]))
    assert not ev.isset
    callback()
    assert ev.isset
    ev = MockEvent()
    uio.add_event(ev, 0)
    buf = host_fd.read()
    assert buf == bytes([0, 0, 0, 1])
    host_fd.write(bytes([0, 0, 0, 1]))
    assert not ev.isset
    callback()
    assert ev.isset


def schedule_new(uio):
    ev = MockEvent()
    uio.add_event(ev, 0)


def _uio_subtest_callback_add(uio, host_fd, client_fd, callback):
    ev = MockEvent(functools.partial(schedule_new, uio))
    uio.add_event(ev, 0)
    buf = host_fd.read()
    assert buf == bytes([0, 0, 0, 1])
    host_fd.write(bytes([0, 0, 0, 1]))
    assert not ev.isset
    callback()
    assert ev.isset
    buf = host_fd.read()
    assert buf == bytes([0, 0, 0, 1])
    host_fd.write(bytes([0, 0, 0, 1]))
    callback()


UIO_CONTROLLER_TESTS = {
    'empty': _uio_subtest_empty,
    'one-event': _uio_subtest_add_event,
    'two-events': _uio_subtest_add_events,
    'callback': _uio_subtest_callback,
    'two-callbacks': _uio_subtest_callbacks,
    'callback-add': _uio_subtest_callback_add,
}


@pytest.mark.parametrize('testname', UIO_CONTROLLER_TESTS.keys())
def test_uio_controller(monkeypatch, tmpdir, testname):
    event_loop = asyncio.get_event_loop()
    callback = None
    client_fd = None

    def add_reader(fd, cb):
        nonlocal callback
        nonlocal client_fd
        callback = cb
        client_fd = fd

    def remove_reader(fd):
        nonlocal client_fd
        assert client_fd == fd
        client_fd = None

    dev = os.path.join(tmpdir, 'uio0')
    host_fd = open(dev, 'w+b', buffering=0)

    monkeypatch.setattr(event_loop, 'add_reader', add_reader)
    monkeypatch.setattr(event_loop, 'remove_reader', remove_reader)

    uio_device = pynq.uio.UioController(dev)
    assert callback is not None
    assert client_fd is not None

    UIO_CONTROLLER_TESTS[testname](uio_device, host_fd, client_fd, callback)

    callback = None
    del uio_device
    assert client_fd is None
